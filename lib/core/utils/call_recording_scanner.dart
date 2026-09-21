import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Result of a scan for a call recording on the device.
class DeviceRecordingMatch {
  /// Absolute path to the audio file on device storage.
  final String filePath;

  /// The filename (basename) of the recording.
  final String fileName;

  /// How close the file's modification time is to the call's timestamp (in
  /// seconds). Lower = better match.
  final int secondsDelta;

  /// `true` if the call's phone number was found inside the file name.
  final bool phoneNumberMatched;

  const DeviceRecordingMatch({
    required this.filePath,
    required this.fileName,
    required this.secondsDelta,
    required this.phoneNumberMatched,
  });

  /// Confidence score: lower is better. Phone-match halves the score.
  double get score {
    final base = secondsDelta.toDouble();
    return phoneNumberMatched ? base / 2 : base;
  }
}

/// Utility that locates Android call recordings on device storage and attempts
/// to match them to a specific call log entry.
///
/// OEM-specific recording directories covered:
///   • Stock Android 11+  → `Recordings/Call/`
///   • Xiaomi / MIUI      → `MIUI/sound_recorder/call_rec/`
///   • Samsung (old)      → `Call recordings/`
///   • OnePlus / OxygenOS → `CallRecord/`
///   • Various OEMs       → `PhoneRecord/`, `Record/Call/`, `Sounds/`
abstract final class CallRecordingScanner {
  /// Audio extensions we treat as potential call recordings.
  static const _audioExtensions = {
    'm4a', 'mp3', 'aac', 'wav', 'ogg', 'opus', 'amr', '3gp', 'mp4',
  };

  /// Well-known OEM call recording directory paths under external storage root.
  static const _knownSubPaths = [
    'Recordings/Call',
    'MIUI/sound_recorder/call_rec',
    'Call recordings',
    'CallRecord',
    'PhoneRecord',
    'Record/Call',
    'Sounds',
    'call_rec',
  ];

  /// Request audio-media permission if needed (Android 13+ uses
  /// [Permission.audio]; older uses [Permission.storage]).
  static Future<bool> requestPermission() async {
    // Android 13+ (READ_MEDIA_AUDIO)
    var status = await Permission.audio.status;
    if (status.isGranted) return true;
    status = await Permission.audio.request();
    if (status.isGranted) return true;

    // Fallback for Android < 13 (READ_EXTERNAL_STORAGE)
    status = await Permission.storage.status;
    if (status.isGranted) return true;
    status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Scans all known recording directories and returns files that plausibly
  /// belong to [callTimestampMs] ± [windowSeconds] (default ±300 s = 5 min).
  ///
  /// Pass [phoneNumber] to improve matching accuracy.
  static Future<List<DeviceRecordingMatch>> findMatchesForCall({
    required int callTimestampMs,
    String? phoneNumber,
    int windowSeconds = 300,
  }) async {
    final callTime =
        DateTime.fromMillisecondsSinceEpoch(callTimestampMs);

    // External storage root (Android always mounts at /storage/emulated/0)
    const storageRoot = '/storage/emulated/0';

    final normalizedNumber = _normalize(phoneNumber ?? '');
    final matches = <DeviceRecordingMatch>[];

    for (final sub in _knownSubPaths) {
      final dir = Directory('$storageRoot/$sub');
      if (!dir.existsSync()) continue;

      try {
        await for (final entity in dir.list(recursive: false)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          final ext = name.split('.').last.toLowerCase();
          if (!_audioExtensions.contains(ext)) continue;

          // Use file's last-modified time as a proxy for recording time
          final stat = entity.statSync();
          final fileTime = stat.modified;
          final delta = (fileTime.difference(callTime).inSeconds).abs();

          if (delta > windowSeconds) continue;

          final phoneInName = normalizedNumber.isNotEmpty &&
              name.replaceAll(RegExp(r'\D'), '').contains(normalizedNumber);

          matches.add(DeviceRecordingMatch(
            filePath: entity.path,
            fileName: name,
            secondsDelta: delta,
            phoneNumberMatched: phoneInName,
          ));
        }
      } catch (_) {
        // Skip directories we can't read (permission denied etc.)
      }
    }

    // Sort: phone matches first, then by timestamp proximity
    matches.sort((a, b) => a.score.compareTo(b.score));
    return matches;
  }

  /// Strips all non-digit characters and drops leading country-code zeros
  /// so `+91 98765-43210` and `9876543210` both normalise to `9876543210`.
  static String _normalize(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    // Keep last 10 digits (handles +91 prefix etc.)
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }
}
