import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> showVoiceNotePlayerSheet(BuildContext context, String filePath) {
  return GlassModalSheet.show(
    context: context,
    quality: GlassQuality.standard,
    detents: const {GlassSheetDetent.medium},
    initialState: GlassSheetState.half,
    builder: (context) => VoiceNotePlayerSheet(filePath: filePath),
  );
}

class VoiceNotePlayerSheet extends StatefulWidget {
  final String filePath;

  const VoiceNotePlayerSheet({super.key, required this.filePath});

  @override
  State<VoiceNotePlayerSheet> createState() => _VoiceNotePlayerSheetState();
}

class _VoiceNotePlayerSheetState extends State<VoiceNotePlayerSheet> {
  final _player = AudioPlayer();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _player.setFilePath(widget.filePath);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 40,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Voice Note',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = _player.duration ?? Duration.zero;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: scheme.primary,
                              thumbColor: scheme.primary,
                              inactiveTrackColor: scheme.surfaceContainerHighest,
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble().clamp(
                                0,
                                total.inMilliseconds.toDouble().clamp(
                                  1,
                                  double.infinity,
                                ),
                              ),
                              max: total.inMilliseconds.toDouble().clamp(
                                1,
                                double.infinity,
                              ),
                              onChanged: (value) {
                                _player.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(total),
                                  style: TextStyle(
                                    fontSize: 12,
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
                  const SizedBox(height: 12),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;

                      return IconButton(
                        iconSize: 52,
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: scheme.primary,
                        ),
                        onPressed: () {
                          if (playing) {
                            _player.pause();
                          } else {
                            _player.play();
                          }
                        },
                      );
                    },
                  ),
                ],
              ],
        ),
      ),
    );
  }
}
