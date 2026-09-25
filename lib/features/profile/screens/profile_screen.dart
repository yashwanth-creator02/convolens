import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/dome_glass_button.dart';
import '../../../shared/widgets/route_reveal_fade.dart';
import '../../history/repository/attachment_storage.dart';
import '../models/profile_field_def.dart';
import '../widgets/profile_qr_sheet.dart';
import 'profile_full_info_screen.dart';

// Revision notes:
//  • Hero photo is now full-width (32 % screen height, rounded rect, clipBehavior),
//    matching the ContactHeader layout. Gradient scrim + name / phone at bottom-left.
//  • Long-press on the hero triggers a Cupertino action sheet: "Take Photo" or
//    "Choose from Gallery". Regular tap does nothing.
//  • Profile screen only shows Basic and Contact sections. All other sections are
//    accessible via the "Full Info" tile that pushes ProfileFullInfoScreen.
//  • The "Edit Details" GlassButton has been removed from the hero — the edit
//    button lives in the bottom tab bar (main_shell.dart, case 3 trailingButton).
//  • Pull-to-open QR, blur on secondary route, DomeGlassButton — all unchanged.
class ProfileScreen extends StatefulWidget {
  final AppDatabase db;
  final GlassLargeTitleController titleController;

  const ProfileScreen({
    super.key,
    required this.db,
    required this.titleController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _pullThreshold = 100.0;
  static const double _pullOvertravel = 120.0;
  static const double _domeLift = 18.0;

  double _pullUpDistance = 0;
  double _pullProgress = 0;
  bool _pullPassedHalfway = false;
  bool _sheetIsOpen = false;
  bool _showBottomPeek = false;

  GlassMorphAnchor? _shareAnchor;

  // ── Photo actions ────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    final savedPath = await AttachmentStorage.saveProfilePhoto(
      result.files.single.path!,
    );
    await widget.db.setProfilePhotoPath(savedPath);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo == null) return;

      final savedPath = await AttachmentStorage.saveProfilePhoto(
        photo.path,
      );

      await widget.db.setProfilePhotoPath(savedPath);
    } catch (e) {
      if (!mounted) return;

      ToastService.error(context, 'Could not take photo.');
    }
  }

  void _showPhotoOptions(BuildContext context) {
    HapticFeedback.mediumImpact();

    GlassSheet.show<void>(
      context: context,
      quality: GlassQuality.standard,
      showDragIndicator: true,
      topBorderRadius: 24,
      bottomBorderRadius: 0,
      margin: EdgeInsets.zero,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassIconButton(
                          icon: const Icon(CupertinoIcons.camera),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _takePhoto();
                          },
                          size: 56,
                          quality: GlassQuality.standard,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 36),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassIconButton(
                          icon: const Icon(CupertinoIcons.photo_on_rectangle),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _pickFromGallery();
                          },
                          size: 56,
                          quality: GlassQuality.standard,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Pull-to-open QR ──────────────────────────────────────────────────────

  void _resetPull() {
    if (_pullUpDistance == 0 && _pullProgress == 0 && !_pullPassedHalfway) {
      return;
    }
    _pullUpDistance = 0;
    _pullPassedHalfway = false;
    setState(() => _pullProgress = 0);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final metrics = notification.metrics;

    final isAtBottom = metrics.extentAfter < 60;
    if (isAtBottom != _showBottomPeek) {
      setState(() => _showBottomPeek = isAtBottom);
    }

    if (_sheetIsOpen) {
      _resetPull();
      return false;
    }

    final overshoot = metrics.pixels - metrics.maxScrollExtent;

    if (overshoot <= 0) {
      _resetPull();
      return false;
    }

    _pullUpDistance = clampDouble(overshoot, 0.0, _pullOvertravel);
    final progress = clampDouble(_pullUpDistance / _pullThreshold, 0.0, 1.0);

    if (progress >= 0.5 && !_pullPassedHalfway) {
      _pullPassedHalfway = true;
      HapticFeedback.selectionClick();
    }

    if (progress != _pullProgress) {
      setState(() => _pullProgress = progress);
    }

    if (_pullUpDistance >= _pullThreshold) {
      HapticFeedback.mediumImpact();
      _pullUpDistance = 0;
      _pullPassedHalfway = false;
      _pullProgress = 0;
      _openQrSheet();
    }

    return false;
  }

  Future<void> _openQrSheet() async {
    if (_sheetIsOpen) return;
    setState(() {
      _sheetIsOpen = true;
      _pullProgress = 0;
    });

    await GlassModalSheet.show(
      context: context,
      quality: GlassQuality.standard,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      initialState: GlassSheetState.half,
      morphFrom: _shareAnchor,
      builder: (context) => ProfileQrSheet(db: widget.db),
    );

    if (mounted) {
      setState(() => _sheetIsOpen = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4.5),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileLeading(IconData icon, ColorScheme scheme) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: scheme.primary),
    );
  }

  IconData _iconForField(ProfileFieldDef def) {
    switch (def.type) {
      case FieldInputType.phone:
        return Icons.phone_outlined;
      case FieldInputType.email:
        return Icons.email_outlined;
      case FieldInputType.date:
        return Icons.cake_outlined;
      case FieldInputType.multiline:
        return Icons.notes_rounded;
      case FieldInputType.text:
        break;
    }
    switch (def.key) {
      case 'firstName':
      case 'middleName':
      case 'lastName':
      case 'displayName':
        return Icons.person_outline_rounded;
      case 'pronouns':
        return Icons.record_voice_over_outlined;
      case 'company':
        return Icons.business_outlined;
      case 'jobTitle':
        return Icons.work_outline_rounded;
      case 'department':
        return Icons.corporate_fare_rounded;
      case 'employeeId':
        return Icons.badge_outlined;
      case 'addressLine1':
      case 'addressLine2':
      case 'city':
      case 'state':
      case 'country':
      case 'postalCode':
        return Icons.location_on_outlined;
      case 'website':
        return Icons.language_rounded;
      case 'linkedin':
        return Icons.link_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'instagram':
        return Icons.photo_camera_outlined;
      case 'twitter':
        return Icons.alternate_email_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Basic':
        return Icons.person_outline_rounded;
      case 'Contact':
        return Icons.contact_phone_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.42).clamp(280.0, 360.0);

    return StreamBuilder<ProfileMetaData>(
      stream: widget.db.watchProfileMeta(),
      builder: (context, metaSnapshot) {
        final photoPath = metaSnapshot.data?.photoPath;
        final hasPhoto = photoPath != null && File(photoPath).existsSync();

        return StreamBuilder<Map<String, ProfileFieldEntry>>(
          stream: widget.db.watchProfileFields(),
          builder: (context, fieldsSnapshot) {
            final fields = fieldsSnapshot.data ?? {};

            String? valueFor(String key) {
              final value = fields[key]?.value;
              return (value != null && value.isNotEmpty) ? value : null;
            }

            final displayName =
                valueFor('displayName') ??
                [valueFor('firstName'), valueFor('lastName')]
                    .whereType<String>()
                    .join(' ');
            final primaryPhone = valueFor('primaryPhone');
            final jobTitle = valueFor('jobTitle');
            final company = valueFor('company');
            final initials = _getInitials(displayName);

            final secondaryAnimation =
                ModalRoute.of(context)?.secondaryAnimation;

            // ── Full-width hero photo ──────────────────────────────────────
            final hero = GestureDetector(
              onLongPress: () => _showPhotoOptions(context),
              child: Container(
                height: heroHeight,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Photo or gradient fallback
                    Positioned.fill(
                      child: hasPhoto
                          ? Image.file(
                              File(photoPath),
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.3),
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    scheme.primary.withValues(alpha: 0.7),
                                    Color.lerp(
                                          scheme.primary,
                                          scheme.surface,
                                          0.5,
                                        ) ??
                                        scheme.surface,
                                    scheme.surface,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        Colors.white.withValues(alpha: 0.12),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ),
                    ),

                  ],
                ),
              ),
            );

            // ── Name / subtitle below photo ────────────────────────────────
            final nameBlock = displayName.isNotEmpty || primaryPhone != null ||
                    jobTitle != null || company != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty ? displayName : 'Add your name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (jobTitle != null || company != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            [jobTitle, company].whereType<String>().join(' · '),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (primaryPhone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            primaryPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink();

            // ── Visible sections — Basic + Contact only ────────────────────
            const visibleSections = ['Basic', 'Contact'];

            final sectionWidgets = visibleSections.expand((section) {
              final sectionFields = profileFieldDefs
                  .where((def) => def.section == section)
                  .map((def) => MapEntry(def, valueFor(def.key)))
                  .where((entry) => entry.value != null)
                  .toList();

              if (sectionFields.isEmpty) return const <Widget>[];

              return [
                GlassGroupedSection(
                  margin: const EdgeInsets.only(bottom: 18),
                  shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                  quality: GlassQuality.standard,
                  header: _buildSectionHeader(
                    context,
                    title: section,
                    icon: _sectionIcon(section),
                  ),
                  children: sectionFields.map((entry) {
                    final def = entry.key;
                    final value = entry.value!;
                    return GlassListTile(
                      leading: _buildTileLeading(_iconForField(def), scheme),
                      title: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        def.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ];
            }).toList();

            // ── "Full Info" tile ───────────────────────────────────────────
            final fullInfoTile = GlassGroupedSection(
              margin: const EdgeInsets.only(bottom: 18),
              shape: const LiquidRoundedSuperellipse(borderRadius: 20),
              quality: GlassQuality.standard,
              children: [
                GlassListTile(
                  leading: _buildTileLeading(
                    Icons.article_outlined,
                    scheme,
                  ),
                  title: Text(
                    'Full Info',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Professional, Address, Online & more',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  trailing: GlassListTile.chevron,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => ProfileFullInfoScreen(
                        db: widget.db,
                        fields: fields,
                      ),
                    ),
                  ),
                ),
              ],
            );

            // ── Empty state ───────────────────────────────────────────────
            final hasAnyFields = profileFieldDefs
                .any((def) => valueFor(def.key) != null);

            final emptyState = !hasAnyFields
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 48,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Fill in your details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the edit button below to get started',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();

            final scrollContent = NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: CustomScrollView(
                controller: widget.titleController.scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + kToolbarHeight,
                    ),
                  ),
                  GlassLargeTitle(
                    text: 'Profile',
                    controller: widget.titleController,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        hero,
                        nameBlock,
                        const SizedBox(height: 16),
                        emptyState,
                        ...sectionWidgets,
                        if (hasAnyFields) fullInfoTile,
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            );

            final bottomTab = Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSlide(
                  offset:
                      _showBottomPeek ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: RouteRevealFade(
                    child: GlassMorphTrigger(
                      builder: (context, anchor) {
                        _shareAnchor = anchor;
                        return DomeGlassButton(
                          onTap: _openQrSheet,
                          icon: const Icon(Icons.qr_code),
                          label: 'Share Contact',
                          liftPixels: _pullProgress * _domeLift,
                        );
                      },
                    ),
                  ),
                ),
              ),
            );

            final stack = Stack(children: [scrollContent, bottomTab]);

            if (secondaryAnimation == null) {
              return Material(type: MaterialType.transparency, child: stack);
            }

            return Material(
              type: MaterialType.transparency,
              child: AnimatedBuilder(
                animation: secondaryAnimation,
                child: stack,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(
                    clampDouble(secondaryAnimation.value, 0.0, 1.0),
                  );
                  if (t <= 0) return child!;
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 24 * t,
                      sigmaY: 24 * t,
                      tileMode: TileMode.decal,
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
