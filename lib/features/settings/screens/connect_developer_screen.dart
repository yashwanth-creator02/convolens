import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/native/device_channel.dart';
import '../../../core/toast/toast_service.dart';
import '../widgets/settings_glass_card.dart';

/// Predefined email templates to help users quickly connect with the developer.
enum EmailTemplateType {
  feedback(
    title: 'Feedback',
    icon: Icons.chat_bubble_outline_rounded,
    subject: '[ConvoLens] Feedback & Suggestions',
    body: '''Hi Leo,

Here is my feedback about ConvoLens:
[Share what you love, what feels clunky, or ideas to make it even better]

---
App: ConvoLens v1.0.0
Platform: Android''',
  ),
  bugReport(
    title: 'Bug Report',
    icon: Icons.bug_report_outlined,
    subject: '[ConvoLens] Bug Report',
    body: '''Problem Description:
[Briefly describe the bug or issue you encountered]

Steps to Reproduce:
1.
2.
3.

Expected Behavior:
[What should have happened]

Actual Behavior:
[What actually happened]

---
App: ConvoLens v1.0.0
Platform: Android''',
  ),
  featureRequest(
    title: 'Feature Request',
    icon: Icons.lightbulb_outline_rounded,
    subject: '[ConvoLens] Feature Request',
    body: '''Feature Idea:
[Describe the feature or workflow you would love to see]

Why this is useful:
[How would this help you manage calls, notes, or contacts better?]

---
App: ConvoLens v1.0.0
Platform: Android''',
  ),
  question(
    title: 'Question',
    icon: Icons.help_outline_rounded,
    subject: '[ConvoLens] Inquiry',
    body: '''Hi Leo,

I have a question regarding ConvoLens:
[Type your question or inquiry here]

---
App: ConvoLens v1.0.0
Platform: Android''',
  ),
  blank(
    title: 'Blank',
    icon: Icons.edit_note_rounded,
    subject: '[ConvoLens] Message',
    body: '''Hi Leo,

[Write your message here]

---
App: ConvoLens v1.0.0
Platform: Android''',
  );

  final String title;
  final IconData icon;
  final String subject;
  final String body;

  const EmailTemplateType({
    required this.title,
    required this.icon,
    required this.subject,
    required this.body,
  });
}

class ConnectDeveloperScreen extends StatefulWidget {
  const ConnectDeveloperScreen({super.key});

  static const String developerEmail = 'leo.two.dev@gmail.com';

  @override
  State<ConnectDeveloperScreen> createState() => _ConnectDeveloperScreenState();
}

class _ConnectDeveloperScreenState extends State<ConnectDeveloperScreen> {
  final _titleController = GlassLargeTitleController();
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;

  EmailTemplateType _selectedTemplate = EmailTemplateType.feedback;

  @override
  void initState() {
    super.initState();
    _subjectController =
        TextEditingController(text: _selectedTemplate.subject);
    _bodyController = TextEditingController(text: _selectedTemplate.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(EmailTemplateType template) {
    if (_selectedTemplate == template) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTemplate = template;
      _subjectController.text = template.subject;
      _bodyController.text = template.body;
    });
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendEmail() async {
    HapticFeedback.mediumImpact();

    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    // 1. Open native system email app picker (chooser)
    bool openedChooser = false;
    try {
      openedChooser = await DeviceChannel.openEmailChooser(
        to: ConnectDeveloperScreen.developerEmail,
        subject: subject,
        body: body,
        chooserTitle: 'Choose Email App',
      );
    } catch (_) {
      openedChooser = false;
    }

    if (openedChooser) return;

    // 2. Fallback to url_launcher mailto URI
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: ConnectDeveloperScreen.developerEmail,
      query: _encodeQueryParameters(<String, String>{
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      }),
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _copyToClipboard(showToast: false);
        ToastService.info(
          context,
          'No email app detected. Details copied to clipboard.',
        );
      }
    } catch (e) {
      if (mounted) {
        _copyToClipboard(showToast: false);
        ToastService.info(
          context,
          'Could not launch email app. Details copied to clipboard.',
        );
      }
    }
  }

  void _copyToClipboard({bool showToast = true}) {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    final buffer = StringBuffer();
    buffer.writeln('To: ${ConnectDeveloperScreen.developerEmail}');
    if (subject.isNotEmpty) buffer.writeln('Subject: $subject');
    buffer.writeln();
    buffer.write(body);

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (showToast && mounted) {
      HapticFeedback.selectionClick();
      ToastService.success(context, 'Email details copied to clipboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Connect with Developer'),
        largeTitleController: _titleController,
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),
            GlassLargeTitle(
              text: 'Connect with Developer',
              controller: _titleController,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Destination Text (Plain text, no container) ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          'To: ',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          ConnectDeveloperScreen.developerEmail,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Copy Email Address',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(
                                text: ConnectDeveloperScreen.developerEmail,
                              ),
                            );
                            HapticFeedback.selectionClick();
                            ToastService.success(
                              context,
                              'Email address copied.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Horizontal Scrolling Templates Bar ───────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: EmailTemplateType.values.map((template) {
                          final isSelected =
                              _selectedTemplate == template;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GlassChip(
                              label: template.title,
                              selected: isSelected,
                              onTap: () => _onTemplateSelected(template),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // ── Subject Field ────────────────────────────────
                  SettingsGlassCard(
                    title: 'Subject',
                    icon: Icons.subject_rounded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: _subjectController,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Email Subject…',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontSize: 13.5,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Message Body Field ───────────────────────────
                  SettingsGlassCard(
                    title: 'Message Body',
                    icon: Icons.edit_note_rounded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _bodyController,
                          maxLines: 10,
                          minLines: 5,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Compose your message…',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Action Buttons ───────────────────────────────
                  FilledButton.icon(
                    onPressed: _sendEmail,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Send Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(showToast: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text(
                      'Copy Email Details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
