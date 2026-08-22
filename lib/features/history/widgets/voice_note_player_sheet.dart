import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

Future<void> showVoiceNotePlayerSheet(BuildContext context, String filePath) {
  return showModalBottomSheet(
    context: context,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq, size: 48),
                  const SizedBox(height: 12),
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = _player.duration ?? Duration.zero;

                      return Column(
                        children: [
                          Slider(
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
                          Text(
                            '${_formatDuration(position)} / ${_formatDuration(total)}',
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
                        iconSize: 48,
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
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
              ),
      ),
    );
  }
}
