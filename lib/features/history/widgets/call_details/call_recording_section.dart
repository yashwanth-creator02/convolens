import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/call_recording_scanner.dart';

/// Displays a call recording section.
///
/// When [recording] is non-null: shows an inline audio player.
/// When [recording] is null: auto-shows any [autoScanResults] surfaced by the
/// parent, or a "Browse files" manual import button.
class CallRecordingSection extends StatefulWidget {
  final CallAttachment? recording;
  final int callTimestampMs;
  final String? callPhoneNumber;

  /// Pre-scanned results from [CallRecordingScanner] (null = still scanning).
  final List<DeviceRecordingMatch>? autoScanResults;
  final bool isScanning;

  final void Function(String filePath, String fileName) onLink;
  final VoidCallback onImport;
  final VoidCallback onDelete;

  const CallRecordingSection({
    super.key,
    required this.recording,
    required this.callTimestampMs,
    required this.callPhoneNumber,
    required this.onLink,
    required this.onImport,
    required this.onDelete,
    this.autoScanResults,
    this.isScanning = false,
  });

  @override
  State<CallRecordingSection> createState() => _CallRecordingSectionState();
}

class _CallRecordingSectionState extends State<CallRecordingSection> {
  AudioPlayer? _player;
  bool _loadingPlayer = false;

  @override
  void initState() {
    super.initState();
    if (widget.recording != null) _initPlayer();
  }

  @override
  void didUpdateWidget(CallRecordingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPath = oldWidget.recording?.filePath;
    final newPath = widget.recording?.filePath;
    if (oldPath != newPath) {
      _player?.dispose();
      _player = null;
      if (newPath != null) _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    setState(() => _loadingPlayer = true);
    final player = AudioPlayer();
    try {
      await player.setFilePath(widget.recording!.filePath);
      if (mounted) {
        setState(() {
          _player = player;
          _loadingPlayer = false;
        });
      } else {
        player.dispose();
      }
    } catch (_) {
      player.dispose();
      if (mounted) setState(() => _loadingPlayer = false);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }



  String _fmt(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.recording != null) return _buildPlayer(scheme);
    return _buildEmptyState(scheme);
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    // Use results supplied by the parent screen (auto-scanned on open)
    final results = widget.autoScanResults;
    final scanning = widget.isScanning;

    // Still scanning
    if (scanning) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scanning device for call recordings…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Scan done and has matches — show results
    if (results != null && results.isNotEmpty) {
      return _buildScanResults(scheme, results);
    }

    // No matches found or no scan yet — just show browse button
    return _ActionRow(
      icon: Icons.upload_file_rounded,
      iconColor: scheme.primary,
      label: results != null
          ? 'No recording found — Browse files'
          : 'Import a call recording',
      sublabel: results != null
          ? 'No matching file in recording folders'
          : 'Pick a recording from your device',
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: widget.onImport,
    );
  }

  Widget _buildScanResults(ColorScheme scheme, List<DeviceRecordingMatch> results) {
    // Show scan results list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: Colors.greenAccent.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              '${results.length} recording${results.length == 1 ? '' : 's'} found',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onImport,
              icon: const Icon(Icons.folder_open_rounded, size: 14),
              label: const Text('Browse'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...results.take(4).map(
              (match) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ScanResultRow(
                  match: match,
                  onLink: () => widget.onLink(match.filePath, match.fileName),
                ),
              ),
            ),
        if (results.length > 4) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onImport,
              icon: const Icon(Icons.folder_open_rounded, size: 14),
              label: const Text('Browse all files'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayer(ColorScheme scheme) {
    if (_loadingPlayer || _player == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final player = _player!;
    const recordingColor = Colors.redAccent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: recordingColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recordingColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = player.duration ?? Duration.zero;
              final maxMs = total.inMilliseconds
                  .clamp(1, double.maxFinite.toInt())
                  .toDouble();
              final posMs =
                  position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

              return Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: recordingColor,
                      inactiveTrackColor:
                          recordingColor.withValues(alpha: 0.2),
                      thumbColor: recordingColor,
                      overlayColor: recordingColor.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: posMs,
                      max: maxMs,
                      onChanged: (v) => player
                          .seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(position),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _fmt(total),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.recording!.originalFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_rounded
                            : Icons.play_circle_rounded,
                        size: 36,
                        color: recordingColor,
                      ),
                      onPressed: () {
                        if (playing) {
                          player.pause();
                        } else {
                          if (player.duration != null &&
                              player.position >= player.duration!) {
                            player.seek(Duration.zero);
                          }
                          player.play();
                        }
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.8),
                  ),
                  tooltip: 'Remove Recording',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ScanResultRow extends StatelessWidget {
  final DeviceRecordingMatch match;
  final VoidCallback onLink;

  const _ScanResultRow({required this.match, required this.onLink});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final delta = match.secondsDelta;
    final deltaLabel = delta < 60
        ? '${delta}s away'
        : '${(delta / 60).round()}m away';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fiber_smart_record_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      deltaLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (match.phoneNumberMatched) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '# matched',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.greenAccent.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onLink,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text(
              'Link',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
