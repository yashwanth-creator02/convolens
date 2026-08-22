import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

Future<String?> showVoiceRecorderDialog(
  BuildContext context,
  String destinationPath,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => VoiceRecorderDialog(destinationPath: destinationPath),
  );
}

class VoiceRecorderDialog extends StatefulWidget {
  final String destinationPath;

  const VoiceRecorderDialog({super.key, required this.destinationPath});

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) Navigator.pop(context);
      return;
    }

    await _recorder.start(const RecordConfig(), path: widget.destinationPath);

    setState(() => _isRecording = true);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopAndSave() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    if (mounted) Navigator.pop(context, path);
  }

  Future<void> _cancelRecording() async {
    _ticker?.cancel();
    await _recorder.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recording Voice Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            size: 48,
            color: _isRecording ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(_formatDuration(_elapsed), style: const TextStyle(fontSize: 24)),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancelRecording, child: const Text('Cancel')),
        TextButton(onPressed: _stopAndSave, child: const Text('Stop & Save')),
      ],
    );
  }
}
