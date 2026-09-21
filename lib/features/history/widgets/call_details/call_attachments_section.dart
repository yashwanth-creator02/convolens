import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/toast/toast_service.dart';

/// Displays a list of call attachments plus an inline mic recorder styled with
/// audio waveforms flanking the microphone (matching the waveform mic visual).
class CallAttachmentsSection extends StatefulWidget {
  final List<CallAttachment> attachments;
  final void Function(CallAttachment attachment) onView;
  final void Function(CallAttachment attachment) onDelete;

  /// Called when an inline voice recording is completed.
  /// [filePath] is the absolute path of the recorded file.
  final Future<void> Function(String filePath) onVoiceRecorded;

  const CallAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onView,
    required this.onDelete,
    required this.onVoiceRecorded,
  });

  @override
  State<CallAttachmentsSection> createState() => _CallAttachmentsSectionState();
}

class _CallAttachmentsSectionState extends State<CallAttachmentsSection>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSaving = false;
  String? _recordingPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Waveform animation
  late AnimationController _waveController;
  final _waveRng = math.Random();
  final List<double> _leftDynamicHeights = List.generate(14, (_) => 0.35);
  final List<double> _rightDynamicHeights = List.generate(14, (_) => 0.35);

  // Mic pulse animation for active recording
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  // Static normalized waveform heights matching the reference attachment image
  static const List<double> _leftStaticHeights = [
    0.25, 0.38, 0.30, 0.55, 0.45, 0.72, 0.35, 0.98, 0.88, 0.38, 0.75, 0.60, 0.30, 0.48,
  ];
  static const List<double> _rightStaticHeights = [
    0.48, 0.30, 0.60, 0.75, 0.38, 0.88, 0.98, 0.35, 0.72, 0.45, 0.55, 0.30, 0.38, 0.25,
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateBars() {
    if (_isRecording && mounted) {
      setState(() {
        for (var i = 0; i < _leftDynamicHeights.length; i++) {
          _leftDynamicHeights[i] = 0.2 + _waveRng.nextDouble() * 0.8;
          _rightDynamicHeights[i] = 0.2 + _waveRng.nextDouble() * 0.8;
        }
      });
      _waveController.forward(from: 0);
    }
  }

  Future<void> _startRecording() async {
    try {
      // 1. Request microphone permission via permission_handler for Android runtime prompt
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          ToastService.error(
            context,
            'Microphone permission is required to record voice notes.',
          );
        }
        return;
      }

      // 2. Also check recorder internal permission check
      final hasRecordPermission = await _recorder.hasPermission();
      if (!hasRecordPermission) {
        if (mounted) {
          ToastService.error(context, 'Microphone permission denied.');
        }
        return;
      }

      // 3. Prepare storage directory
      final dir = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${dir.path}/voice_notes');
      if (!notesDir.existsSync()) {
        notesDir.createSync(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${notesDir.path}/voice_note_$timestamp.m4a';

      // 4. Start recording with default platform config
      await _recorder.start(
        const RecordConfig(),
        path: path,
      );

      // 5. Update UI to active state immediately
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _elapsed = Duration.zero;
        });

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
        });

        _waveController.forward(from: 0);
        _pulseController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Could not start recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _waveController.stop();
    _pulseController.stop();
    HapticFeedback.mediumImpact();

    try {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isSaving = true;
        });
      }

      final recordedPath = path ?? _recordingPath;
      if (recordedPath != null && File(recordedPath).existsSync()) {
        await widget.onVoiceRecorded(recordedPath);
        if (mounted) {
          ToastService.success(context, 'Voice note saved.');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Failed to save voice note: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _waveController.stop();
    _pulseController.stop();
    HapticFeedback.lightImpact();

    try {
      final path = await _recorder.stop();
      final recordedPath = path ?? _recordingPath;
      if (recordedPath != null) {
        final f = File(recordedPath);
        if (f.existsSync()) f.deleteSync();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isRecording = false;
        _elapsed = Duration.zero;
      });
      ToastService.info(context, 'Recording discarded.');
    }
  }

  String _fmtElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Existing attachments list ─────────────────────────────────────────
        ...widget.attachments.map((attachment) {
          final isVoice = attachment.fileType == 'voice';
          final isPdf = attachment.fileType == 'pdf';

          final IconData iconData;
          final Color iconColor;
          final String title;

          if (isVoice) {
            iconData = Icons.graphic_eq_rounded;
            iconColor = Colors.purpleAccent;
            title = 'Voice Note';
          } else if (isPdf) {
            iconData = Icons.picture_as_pdf_rounded;
            iconColor = Colors.redAccent;
            title = attachment.originalFileName;
          } else {
            iconData = Icons.image_rounded;
            iconColor = Colors.blueAccent;
            title = attachment.originalFileName;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onView(attachment),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(iconData, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (isVoice)
                              Text(
                                'Tap to play',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: scheme.error.withValues(alpha: 0.8),
                        ),
                        tooltip: 'Remove',
                        onPressed: () => widget.onDelete(attachment),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        if (widget.attachments.isNotEmpty) const SizedBox(height: 4),

        // ── Saving indicator ──────────────────────────────────────────────────
        if (_isSaving)
          _buildSavingIndicator(scheme)
        else
          // ── Waveform mic button (matches attachment reference) ───────────────
          _buildWaveformMic(
            scheme: scheme,
            isRecording: _isRecording,
          ),
      ],
    );
  }

  Widget _buildWaveformMic({
    required ColorScheme scheme,
    required bool isRecording,
  }) {
    const recordingColor = Colors.redAccent;

    final leftHeights = isRecording ? _leftDynamicHeights : _leftStaticHeights;
    final rightHeights =
        isRecording ? _rightDynamicHeights : _rightStaticHeights;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isRecording ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: isRecording
            ? recordingColor.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecording
              ? recordingColor.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.28),
          width: isRecording ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Active recording top bar (only visible during recording) ────────
          if (isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: recordingColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'RECORDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: recordingColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: recordingColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fmtElapsed(_elapsed),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: recordingColor,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ── The waveform with central mic from the reference attachment ─────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isRecording ? _stopRecording : _startRecording,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  // Left waveform bars
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: leftHeights.map((h) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          width: 3.0,
                          height: (40 * h).clamp(5.0, 40.0),
                          decoration: BoxDecoration(
                            color: isRecording
                                ? recordingColor.withValues(alpha: 0.9)
                                : scheme.onSurface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Center microphone icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: isRecording
                        ? ScaleTransition(
                            scale: _pulseScale,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: recordingColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: recordingColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                size: 24,
                                color: recordingColor,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.mic_rounded,
                              size: 24,
                              color: scheme.primary,
                            ),
                          ),
                  ),

                  // Right waveform bars
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: rightHeights.map((h) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          width: 3.0,
                          height: (40 * h).clamp(5.0, 40.0),
                          decoration: BoxDecoration(
                            color: isRecording
                                ? recordingColor.withValues(alpha: 0.9)
                                : scheme.onSurface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom status / controls ──────────────────────────────────────
          const SizedBox(height: 8),
          if (isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Discard button
                OutlinedButton.icon(
                  onPressed: _cancelRecording,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: scheme.error,
                  ),
                  label: Text(
                    'Discard',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Stop & Save button
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(
                    Icons.stop_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Stop & Save',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recordingColor,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _startRecording,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap mic to record voice note',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingIndicator(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Saving voice note…',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
