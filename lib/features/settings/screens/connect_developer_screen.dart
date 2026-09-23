import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/native/device_channel.dart';
import '../../../core/toast/toast_service.dart';

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

  void _resetTemplate() {
    HapticFeedback.selectionClick();
    setState(() {
      _subjectController.text = _selectedTemplate.subject;
      _bodyController.text = _selectedTemplate.body;
    });
    ToastService.info(context, 'Reset to template defaults.');
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

  Widget _buildHarmonizedCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: scheme.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Connect with Developer'),
        largeTitleController: _titleController,
        actions: [
          GlassBarItem.menu(
            icon: const Icon(Icons.more_horiz),
            id: 'developer_menu',
            label: 'More',
            menuAlignment: GlassMenuAlignment.topRight,
            menuWidth: 160,
            menuItems: [
              GlassMenuItem(
                title: 'Copy',
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                titleStyle: TextStyle(
                  decoration: TextDecoration.none,
                  color: scheme.onSurface,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                onTap: () => _copyToClipboard(showToast: true),
              ),
              GlassMenuItem(
                title: 'Reset',
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                titleStyle: TextStyle(
                  decoration: TextDecoration.none,
                  color: scheme.onSurface,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                onTap: _resetTemplate,
              ),
            ],
          ),
        ],
      ),
      body: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _titleController.scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(
                  text: 'Connect with Developer',
                  controller: _titleController,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. Destination Text (Plain text, no container) ──
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
                                    text:
                                        ConnectDeveloperScreen.developerEmail,
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

                      // ── 2. Horizontal Scrolling Templates Bar ─────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
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

                      // ── 3. Subject Section (Unified Card) ────────────
                      _buildHarmonizedCard(
                        context: context,
                        title: 'Subject',
                        icon: Icons.subject_rounded,
                        child: TextField(
                          controller: _subjectController,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Enter subject…',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      // ── 4. Message Body Section (Unified Card) ───────
                      _buildHarmonizedCard(
                        context: context,
                        title: 'Message Body',
                        icon: Icons.edit_note_rounded,
                        child: TextField(
                          controller: _bodyController,
                          maxLines: 10,
                          minLines: 5,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Compose your message…',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),

            // ── Small Floating Send Button in Bottom Right Corner ─
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              right: 20,
              child: GlassButton(
                onTap: _sendEmail,
                icon: const Icon(Icons.send_rounded, size: 25),
                label: 'Send',
                quality: GlassQuality.standard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
