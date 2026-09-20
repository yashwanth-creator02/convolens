import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/database/app_database.dart';

/// Displays a call recording inline player if [recording] is non-null,
/// or a subtle import prompt when no recording is linked.
class CallRecordingSection extends StatefulWidget {
  final CallAttachment? recording;
  final VoidCallback onImport;
  final VoidCallback onDelete;

  const CallRecordingSection({
    super.key,
    required this.recording,
    required this.onImport,
    required this.onDelete,
  });

  @override
  State<CallRecordingSection> createState() => _CallRecordingSectionState();
}

class _CallRecordingSectionState extends State<CallRecordingSection> {
  AudioPlayer? _player;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.recording != null) {
      _initPlayer();
    }
  }

  @override
  void didUpdateWidget(CallRecordingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPath = oldWidget.recording?.filePath;
    final newPath = widget.recording?.filePath;
    if (oldPath != newPath) {
      _player?.dispose();
      _player = null;
      if (newPath != null) {
        _initPlayer();
      }
    }
  }

  Future<void> _initPlayer() async {
    setState(() => _loading = true);
    final player = AudioPlayer();
    try {
      await player.setFilePath(widget.recording!.filePath);
      if (mounted) {
        setState(() {
          _player = player;
          _loading = false;
        });
      } else {
        player.dispose();
      }
    } catch (_) {
      player.dispose();
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // ── Empty state ──────────────────────────────────────────────────────────
    if (widget.recording == null) {
      return InkWell(
        onTap: widget.onImport,
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
              Icon(
                Icons.fiber_smart_record_rounded,
                size: 20,
                color: Colors.redAccent.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Import a call recording from device…',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13.5,
                  ),
                ),
              ),
              Icon(
                Icons.upload_file_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    // ── Loading ──────────────────────────────────────────────────────────────
    if (_loading || _player == null) {
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

    // ── Player ───────────────────────────────────────────────────────────────
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
          // Waveform / seek bar row
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = player.duration ?? Duration.zero;
              final maxMs =
                  total.inMilliseconds.clamp(1, double.maxFinite.toInt()).toDouble();
              final posMs =
                  position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

              return Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: recordingColor,
                      inactiveTrackColor: recordingColor.withValues(alpha: 0.2),
                      thumbColor: recordingColor,
                      overlayColor: recordingColor.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: posMs,
                      max: maxMs,
                      onChanged: (v) =>
                          player.seek(Duration(milliseconds: v.toInt())),
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
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _fmt(total),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
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

          // Controls row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
            child: Row(
              children: [
                // File name
                Expanded(
                  child: Text(
                    widget.recording!.originalFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Play / Pause
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
                          // Restart if at end
                          if ((player.duration != null) &&
                              player.position >= player.duration!) {
                            player.seek(Duration.zero);
                          }
                          player.play();
                        }
                      },
                    );
                  },
                ),

                // Delete
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error.withValues(alpha: 0.8),
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
