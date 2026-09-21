import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/database/app_database.dart';

/// Displays a list of call attachments plus an inline mic recorder styled with
/// audio waveforms flanking the microphone (matching the waveform mic visual),
/// supporting capturing voice memos directly without modal dialogs.
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
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Dynamic waveform bars for active recording state
  late AnimationController _waveController;
  final _waveRng = math.Random();
  final List<double> _leftDynamicHeights = List.generate(14, (_) => 0.35);
  final List<double> _rightDynamicHeights = List.generate(14, (_) => 0.35);

  // Static normalized waveform heights matching the reference audio wave image
  // (fluctuating wave with distinct peaks, flanking the center mic)
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
      duration: const Duration(milliseconds: 110),
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
        for (var i = 0; i < _leftDynamicHeights.length; i++) {
          _leftDynamicHeights[i] = 0.2 + _waveRng.nextDouble() * 0.8;
          _rightDynamicHeights[i] = 0.2 + _waveRng.nextDouble() * 0.8;
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

    if (mounted) {
      setState(() => _isSaving = false);
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

        // ── Secondary action: Attach file ────────────────────────────────────
        if (!_isRecording && !_isSaving) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.attach_file_rounded, size: 15),
              label: const Text('Attach file'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaveformMic({
    required ColorScheme scheme,
    required bool isRecording,
  }) {
    const accentColor = Colors.purpleAccent;
    final leftHeights = isRecording ? _leftDynamicHeights : _leftStaticHeights;
    final rightHeights =
        isRecording ? _rightDynamicHeights : _rightStaticHeights;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRecording ? _stopRecording : _startRecording,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isRecording
                ? accentColor.withValues(alpha: 0.08)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecording
                  ? accentColor.withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.28),
              width: isRecording ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── The exact waveform with central mic from the attachment ────
              SizedBox(
                height: 38,
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
                            height: (38 * h).clamp(5.0, 38.0),
                            decoration: BoxDecoration(
                              color: isRecording
                                  ? accentColor.withValues(alpha: 0.9)
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
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isRecording
                              ? accentColor.withValues(alpha: 0.2)
                              : scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isRecording
                                ? accentColor.withValues(alpha: 0.5)
                                : scheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          size: 24,
                          color: isRecording ? accentColor : scheme.primary,
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
                            height: (38 * h).clamp(5.0, 38.0),
                            decoration: BoxDecoration(
                              color: isRecording
                                  ? accentColor.withValues(alpha: 0.9)
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

              // Status line below waveform
              const SizedBox(height: 6),
              if (isRecording)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtElapsed(_elapsed),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tap anywhere to stop & save',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Tap to record voice note',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
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
