import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../utils/link_platform_icons.dart';

class ContactLinksSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactLinksSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  static void showAddLinkSheet(
    BuildContext context, {
    required AppDatabase db,
    required String normalizedNumber,
    ContactLink? linkToEdit,
  }) {
    GlassSheet.show(
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
      builder: (context) => _AddOrEditLinkGlassSheet(
        db: db,
        normalizedNumber: normalizedNumber,
        linkToEdit: linkToEdit,
      ),
    );
  }

  String _getPlatformLabel(String platform) {
    switch (platform.toLowerCase()) {
      case 'x':
        return 'X (Twitter)';
      case 'company_website':
        return 'Company';
      case 'youtube':
        return 'YouTube';
      case 'whatsapp':
        return 'WhatsApp';
      case 'linkedin':
        return 'LinkedIn';
      case 'github':
        return 'GitHub';
      default:
        return platform.isEmpty
            ? 'Link'
            : platform[0].toUpperCase() + platform.substring(1);
    }
  }

  Color _getPlatformColor(String platform, ColorScheme scheme) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'github':
        return scheme.onSurface;
      case 'x':
        return scheme.onSurface;
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'email':
        return Colors.orangeAccent;
      case 'website':
      case 'portfolio':
      case 'company_website':
      default:
        return scheme.primary;
    }
  }

  Future<void> _launch(BuildContext context, String rawUrl) async {
    var url = rawUrl.trim();
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('tel:')) {
      if (url.contains('@') && !url.contains('/')) {
        url = 'mailto:$url';
      } else {
        url = 'https://$url';
      }
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ToastService.error(context, 'Could not open link: $rawUrl');
      }
    } else if (context.mounted) {
      ToastService.error(context, 'Invalid URL: $rawUrl');
    }
  }

  Future<void> _showLinkOptions(BuildContext context, ContactLink link) async {
    final scheme = Theme.of(context).colorScheme;
    final platformColor = _getPlatformColor(link.platform, scheme);

    final action = await GlassModalSheet.show<String>(
      context: context,
      quality: GlassQuality.standard,
      detents: const {GlassSheetDetent.medium},
      initialState: GlassSheetState.half,
      builder: (context) => GlassPage(
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: platformColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            linkPlatformIcons[link.platform] ?? Icons.link,
                            size: 20,
                            color: platformColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPlatformLabel(link.platform),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                link.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassOptionTile(
                    context,
                    icon: Icons.open_in_new_rounded,
                    iconColor: scheme.primary,
                    title: 'Open link',
                    onTap: () => Navigator.pop(context, 'open'),
                  ),
                  const SizedBox(height: 6),
                  _buildGlassOptionTile(
                    context,
                    icon: Icons.copy_rounded,
                    iconColor: scheme.onSurfaceVariant,
                    title: 'Copy URL',
                    onTap: () => Navigator.pop(context, 'copy'),
                  ),
                  const SizedBox(height: 6),
                  _buildGlassOptionTile(
                    context,
                    icon: Icons.edit_outlined,
                    iconColor: scheme.onSurfaceVariant,
                    title: 'Edit link',
                    onTap: () => Navigator.pop(context, 'edit'),
                  ),
                  const SizedBox(height: 6),
                  _buildGlassOptionTile(
                    context,
                    icon: Icons.delete_outline_rounded,
                    iconColor: scheme.error,
                    title: 'Delete link',
                    textColor: scheme.error,
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'open':
        await _launch(context, link.url);
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: link.url));
        if (context.mounted) {
          ToastService.success(context, 'Link copied to clipboard.');
        }
        break;
      case 'edit':
        showAddLinkSheet(
          context,
          db: db,
          normalizedNumber: normalizedNumber,
          linkToEdit: link,
        );
        break;
      case 'delete':
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'Delete Link?',
          message:
              'This will remove "${_getPlatformLabel(link.platform)}" from this contact.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (confirmed) {
          await db.deleteContactLink(link.id);
          if (context.mounted) {
            ToastService.success(context, 'Link removed.');
          }
        }
        break;
    }
  }

  Widget _buildGlassOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<ContactLink>>(
      stream: db.watchLinksForContact(normalizedNumber),
      builder: (context, snapshot) {
        final links = snapshot.data ?? [];

        if (links.isEmpty) {
          return InkWell(
            onTap: () => showAddLinkSheet(
              context,
              db: db,
              normalizedNumber: normalizedNumber,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No links added',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add websites, profiles, or social links',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: links.map((link) {
            final platformColor = _getPlatformColor(link.platform, scheme);
            final platformIcon =
                linkPlatformIcons[link.platform] ?? Icons.link_rounded;
            final platformLabel = _getPlatformLabel(link.platform);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launch(context, link.url),
                  onLongPress: () => _showLinkOptions(context, link),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: platformColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: platformColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            platformIcon,
                            size: 18,
                            color: platformColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                platformLabel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                link.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Copy link',
                          visualDensity: VisualDensity.compact,
                          color: scheme.onSurfaceVariant,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: link.url));
                            ToastService.success(context, 'Copied link.');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 17),
                          tooltip: 'Open link',
                          visualDensity: VisualDensity.compact,
                          color: scheme.primary,
                          onPressed: () => _launch(context, link.url),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AddOrEditLinkGlassSheet extends StatefulWidget {
  final AppDatabase db;
  final String normalizedNumber;
  final ContactLink? linkToEdit;

  const _AddOrEditLinkGlassSheet({
    required this.db,
    required this.normalizedNumber,
    this.linkToEdit,
  });

  @override
  State<_AddOrEditLinkGlassSheet> createState() =>
      _AddOrEditLinkGlassSheetState();
}

class _AddOrEditLinkGlassSheetState extends State<_AddOrEditLinkGlassSheet> {
  late String _selectedPlatform;
  late final TextEditingController _urlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPlatform = widget.linkToEdit?.platform ?? 'website';
    _urlController =
        TextEditingController(text: widget.linkToEdit?.url ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      ToastService.error(context, 'Please enter a URL or address.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      if (widget.linkToEdit != null) {
        await widget.db.updateContactLink(widget.linkToEdit!.id, text);
        if (mounted) {
          ToastService.success(context, 'Link updated.');
        }
      } else {
        await widget.db.addContactLink(
          widget.normalizedNumber,
          _selectedPlatform,
          text,
        );
        if (mounted) {
          ToastService.success(context, 'Link added.');
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Failed to save link.');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing = widget.linkToEdit != null;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Link' : 'Add Link',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save',
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

              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLATFORM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: linkPlatformKeys.map((key) {
                          final isSelected = _selectedPlatform == key;
                          final icon = linkPlatformIcons[key] ?? Icons.link;
                          final label = key == 'x'
                              ? 'X'
                              : key == 'company_website'
                                  ? 'Company'
                                  : key[0].toUpperCase() + key.substring(1);

                          return GlassChip(
                            label: label,
                            selected: isSelected,
                            icon: Icon(
                              icon,
                              size: 14,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedPlatform = key);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'URL OR ADDRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _urlController,
                        placeholder: 'e.g. https://github.com/username',
                        style: TextStyle(color: scheme.onSurface, fontSize: 14),
                        placeholderStyle: TextStyle(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                          fontSize: 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        onSubmitted: (_) => _handleSave(),
                      ),
                      const SizedBox(height: 12),
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
