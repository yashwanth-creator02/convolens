import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/database/app_database.dart';

/// Displays a list of call attachments plus an inline mic recorder for
/// capturing voice memos directly (no dialog).  Supports multiple recordings.
///
/// Voice attachments use [fileType] = `'voice'`.
class CallAttachmentsSection extends StatefulWidget {
  final List<CallAttachment> attachments;
  final VoidCallback onAdd;
  final void Function(CallAttachment attachment) onView;
  final void Function(CallAttachment attachment) onDelete;

  /// Called when an inline voice recording is completed.
  /// [filePath] is the absolute path of the recorded file.
  final Future<void> Function(String filePath) onVoiceRecorded;

  const CallAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onAdd,
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

  // Animated waveform bars
  late AnimationController _waveController;
  final _waveRng = math.Random();
  final List<double> _barHeights = List.generate(20, (_) => 0.3);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(_updateBars);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _updateBars() {
    if (_isRecording && mounted) {
      setState(() {
        for (var i = 0; i < _barHeights.length; i++) {
          _barHeights[i] =
              0.2 + _waveRng.nextDouble() * 0.8;
        }
      });
      _waveController.forward(from: 0);
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/voice_note_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _elapsed = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });

    _waveController.forward(from: 0);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _waveController.stop();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isSaving = true;
    });

    if (path != null && File(path).existsSync()) {
      await widget.onVoiceRecorded(path);
    }

    setState(() => _isSaving = false);
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
        // ── Existing attachments ──────────────────────────────────────────────
        if (widget.attachments.isEmpty && !_isRecording && !_isSaving)
          _buildEmptyState(scheme),

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

        // ── Inline recording wave ─────────────────────────────────────────────
        if (_isRecording) _buildWaveRecorder(scheme),
        if (_isSaving) _buildSavingIndicator(scheme),

        // ── Footer row: mic + attach ──────────────────────────────────────────
        if (!_isRecording && !_isSaving) ...[
          if (widget.attachments.isNotEmpty) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Mic button — tap to record inline
              _MicButton(
                onPressed: _startRecording,
              ),
              const SizedBox(width: 8),
              // Attach files button
              TextButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: const Text('Attach'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              Icons.mic_none_rounded,
              size: 20,
              color: Colors.purpleAccent.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap the mic to record a voice note, or attach a file…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveRecorder(ColorScheme scheme) {
    const waveColor = Colors.purpleAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: waveColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: waveColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Waveform bars
          Expanded(
            child: SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _barHeights.map((h) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 3,
                    height: 36 * h,
                    decoration: BoxDecoration(
                      color: waveColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Timer
          Text(
            _fmtElapsed(_elapsed),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: waveColor,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          // Stop button
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: waveColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_rounded,
                size: 20,
                color: waveColor,
              ),
            ),
          ),
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

// ── Mic button ────────────────────────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _MicButton({required this.onPressed});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            Icons.mic_rounded,
            size: 18,
            color: Colors.purpleAccent,
          ),
        ),
      ),
    );
  }
}
