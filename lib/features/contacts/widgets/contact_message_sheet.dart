import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/utils/call_launcher.dart';

/// Shows an interactive liquid glass bottom sheet popup window
/// with a text area and options to send via WhatsApp or the default Messages app,
/// matching the exact UI of [TagSelectionGlassSheet].
Future<void> showMessageComposeSheet(
  BuildContext context, {
  required String displayName,
  required String phoneNumber,
}) {
  const quickTemplates = [
    'Can I call you back?',
    'I am on my way.',
    'Please call me when free.',
    'Got it, thanks!',
    'Running 5 minutes late.',
  ];

  return GlassSheet.show(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: true,
    isScrollable: false,
    enableDrag: false,
    interactionScale: 1.0,
    enableSaturationGlow: false,
    enableInteractionGlow: false,
    suppressInteractionOnChildren: true,
    topBorderRadius: 24,
    bottomBorderRadius: 0,
    margin: EdgeInsets.zero,
    builder: (context) => _MessageComposeGlassSheet(
      displayName: displayName,
      phoneNumber: phoneNumber,
      quickTemplates: quickTemplates,
    ),
  );
}

class _MessageComposeGlassSheet extends StatefulWidget {
  final String displayName;
  final String phoneNumber;
  final List<String> quickTemplates;

  const _MessageComposeGlassSheet({
    required this.displayName,
    required this.phoneNumber,
    required this.quickTemplates,
  });

  @override
  State<_MessageComposeGlassSheet> createState() =>
      _MessageComposeGlassSheetState();
}

class _MessageComposeGlassSheetState extends State<_MessageComposeGlassSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Message ${widget.displayName}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Message text input area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Type a message…',
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2, right: 2),
                                child: Icon(
                                  Icons.cancel,
                                  size: 16,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : null,
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              // Quick templates matching GlassChips
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'QUICK TEMPLATES'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.quickTemplates.map((template) {
                          return GlassChip(
                            label: template,
                            selected: false,
                            labelStyle: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _controller.text = template;
                              _controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length),
                              );
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons for WhatsApp and Messages
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () async {
                                final text = _controller.text.trim();
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                                await CallLauncher.openWhatsAppChat(
                                  widget.phoneNumber,
                                  text: text.isNotEmpty ? text : null,
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text(
                                'WhatsApp',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                              ),
                              onPressed: () async {
                                final text = _controller.text.trim();
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                                if (text.isNotEmpty) {
                                  await CallLauncher.messageWithText(
                                    widget.phoneNumber,
                                    text,
                                  );
                                } else {
                                  await CallLauncher.message(widget.phoneNumber);
                                }
                              },
                              icon: const Icon(Icons.sms_outlined, size: 18),
                              label: const Text(
                                'Messages',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
