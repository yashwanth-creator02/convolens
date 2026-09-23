import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/dome_glass_button.dart';
import '../../../shared/widgets/route_reveal_fade.dart';
import '../../history/repository/attachment_storage.dart';
import '../models/profile_field_def.dart';
import '../widgets/profile_qr_sheet.dart';
import 'edit_profile_screen.dart';

// Changes in this revision:
//  1. The \"Share Contact\" tab is now a DomeGlassButton (top-half-of-an-
//     ellipse shape) flush against the bottom edge, instead of a floating
//     pill — see dome_shape.dart.
//  2. The pull-up-to-open gesture has real hysteresis: it resets if the
//     scroll view leaves the bottom edge mid-drag, clamps overtravel, and
//     gives two-stage haptic feedback (a tick at the halfway point, an
//     impact on commit) instead of firing blind at a single number.
//  3. While the QR sheet is being presented, the whole screen blurs and the
//     tab fades out in lockstep with the *actual* route transition
//     (ModalRoute.secondaryAnimation) rather than a discrete open/closed
//     flag, so it stays smooth even if the sheet's presentation is an
//     interactive, pausable drag.
//  4. RouteRevealFade (see route_reveal_fade.dart) is the reusable piece of
//     (3) — wrap any trailing app-bar buttons in your parent shell with the
//     same widget to have them vanish in sync too.
//  5. The sheet itself is now GlassModalSheet.show() instead of
//     showCupertinoSheet — medium/large detents, native drag handle. It's
//     still pushed via showGeneralDialog with useRootNavigator: false (its
//     default), so it lands on the same Navigator as this screen and
//     ModalRoute.of(context).secondaryAnimation in build() below keeps
//     tracking it exactly as it did before. Don't add useRootNavigator: true
//     to the call in _openQrSheet or that stops being true. Note also that
//     GlassModalSheet.show()'s builder only hands back a BuildContext (no
//     ScrollController), unlike showCupertinoSheet's scrollableBuilder — see
//     profile_qr_sheet.dart for the corresponding change.
//  6. The dome button is wrapped in a GlassMorphTrigger, and _openQrSheet
//     passes its anchor as morphFrom — so opening the sheet, whether by tap
//     or by completing the pull gesture, plays the iOS 26 liquid-morph
//     presentation out of the button instead of a plain slide-up.
//  7. Fixed the pull gesture never firing: it was gated on
//     OverscrollNotification, which only ClampingScrollPhysics dispatches.
//     BouncingScrollPhysics (used below) never rejects a move, so it never
//     fires one — the pull distance now comes from
//     metrics.pixels - metrics.maxScrollExtent instead, which is the actual
//     rubber-band overshoot and does update continuously under bouncing
//     physics.
//  8. Redesign (Liquid Glass): profile view now uses a GlassContainer hero
//     card showing avatar/name/phone + an "Edit Details" glass button,
//     followed by GlassGroupedSection per profile category (Basic, Contact,
//     Professional, Address, Online, Additional) with GlassListTile rows and
//     category-tinted icon pills — consistent with Settings & History screens.
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
  // Pull-to-open-QR tuning. Threshold is the overscroll distance (px) that
  // counts as a deliberate pull; overtravel caps how far past that we still
  // track, purely so a lingering finger past the threshold can't push
  // _pullProgress anywhere but "fully committed".
  static const double _pullThreshold = 100.0;
  static const double _pullOvertravel = 120.0;
  static const double _domeLift = 18.0;

  double _pullUpDistance = 0;
  double _pullProgress = 0; // 0..1, drives the tab's lift while dragging
  bool _pullPassedHalfway = false;
  bool _sheetIsOpen = false;
  bool _showBottomPeek = false;

  // Captured from GlassMorphTrigger's builder each build (see bottomTab in
  // build() below) so _openQrSheet can hand it to GlassModalSheet.show() as
  // morphFrom, regardless of whether that call came from a tap or from the
  // pull gesture completing.
  GlassMorphAnchor? _shareAnchor;

  Future<void> _changePhoto(BuildContext context) async {
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

  void _resetPull() {
    if (_pullUpDistance == 0 && _pullProgress == 0 && !_pullPassedHalfway) {
      return; // nothing to do — avoid a pointless setState every scroll tick
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

    // BouncingScrollPhysics (used below) never rejects a move the way
    // ClampingScrollPhysics does — it has no boundary condition to enforce —
    // so it never dispatches an OverscrollNotification mid-drag; that
    // notification only ever fires under Android-style clamping physics.
    // Under bouncing physics, dragging past the bottom just pushes `pixels`
    // straight past `maxScrollExtent` (that gap IS the rubber-band), so that
    // overshoot is what we track directly instead.
    final overshoot = metrics.pixels - metrics.maxScrollExtent;

    if (overshoot <= 0) {
      // Not overscrolled (or scrolled back within range mid-gesture) —
      // cancel any partial pull instead of letting it carry over into the
      // next time the finger reaches the edge in the same drag.
      _resetPull();
      return false;
    }

    _pullUpDistance = clampDouble(overshoot, 0.0, _pullOvertravel);
    final progress = clampDouble(_pullUpDistance / _pullThreshold, 0.0, 1.0);

    if (progress >= 0.5 && !_pullPassedHalfway) {
      _pullPassedHalfway = true;
      HapticFeedback.selectionClick(); // light tick: "you're halfway there"
    }

    if (progress != _pullProgress) {
      setState(() => _pullProgress = progress);
    }

    if (_pullUpDistance >= _pullThreshold) {
      HapticFeedback.mediumImpact(); // committed: letting go opens it
      _pullUpDistance = 0;
      _pullPassedHalfway = false;
      _pullProgress = 0;
      _openQrSheet();
    }

    // No separate ScrollEndNotification case needed: once the finger lifts,
    // the bounce-back simulation keeps firing ScrollUpdateNotifications as
    // `pixels` eases back toward `maxScrollExtent`, so `overshoot` decays
    // toward 0 on its own and the branch above resets the pull naturally —
    // the dome tab settles in sync with the actual physics instead of
    // snapping back on a fixed timer.
    return false;
  }

  Future<void> _openQrSheet() async {
    if (_sheetIsOpen) return;
    setState(() {
      _sheetIsOpen = true;
      _pullProgress = 0;
    });

    // morphFrom makes both the direct tap AND the pull-up-to-open gesture
    // present as the iOS 26 liquid morph — the dome button empties, a glass
    // droplet detaches from it and inflates as it travels, and lands as the
    // sheet. Both paths call this same method, so a completed pull reads as
    // "the button got dragged up and grew into the sheet" exactly like a
    // tap would, instead of the two feeling like different interactions.
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
    return Row(
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

  /// Icon for a profile field based on its type / key.
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
    // Text fields: use key-based icons for well-known keys.
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
      case 'Professional':
        return Icons.work_outline_rounded;
      case 'Address':
        return Icons.location_on_outlined;
      case 'Online':
        return Icons.language_rounded;
      case 'Additional':
        return Icons.notes_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                [
                  valueFor('firstName'),
                  valueFor('lastName'),
                ].whereType<String>().join(' ');
            final primaryPhone = valueFor('primaryPhone');
            final jobTitle = valueFor('jobTitle');
            final company = valueFor('company');

            // secondaryAnimation runs 0->1 while the QR sheet is being
            // pushed on top of this route, and — with an interactive
            // Cupertino sheet drag — can sit anywhere in between, or
            // reverse, while the user is mid-gesture. Keying the blur/fade
            // off this instead of _sheetIsOpen keeps everything in lockstep
            // with whatever the transition is actually doing, including a
            // cancelled drag that reverses back to 0.
            final secondaryAnimation = ModalRoute.of(
              context,
            )?.secondaryAnimation;

            // ── Hero card ─────────────────────────────────────────────────
            final heroCard = GlassContainer(
              quality: GlassQuality.standard,
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with camera-edit overlay
                    GestureDetector(
                      onTap: () => _changePhoto(context),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.3),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: scheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              backgroundImage: hasPhoto
                                  ? FileImage(File(photoPath))
                                  : null,
                              child: !hasPhoto
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 38,
                                      color: scheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name / subtitle block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty
                                ? displayName
                                : 'Add your name',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (jobTitle != null || company != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              [jobTitle, company]
                                  .whereType<String>()
                                  .join(' · '),
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                ),
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
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          GlassButton(
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(db: widget.db),
                              ),
                            ),
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                            ),
                            label: 'Edit Details',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            // ── Field sections ─────────────────────────────────────────────
            final sectionWidgets = profileSectionOrder.expand((section) {
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

            // ── Empty state (no fields filled yet) ─────────────────────────
            final emptyState = sectionWidgets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 48,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
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
                            'Tap "Edit Details" above to get started',
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
                        heroCard,
                        const SizedBox(height: 20),
                        emptyState,
                        ...sectionWidgets,
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
                  offset: _showBottomPeek ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: RouteRevealFade(
                    // Plain field assignment in the builder, not setState —
                    // it only needs to be captured for _openQrSheet to read
                    // later, not to trigger a rebuild by itself.
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
              // No enclosing route to key off of (e.g. previewing this
              // widget in isolation) — skip the blur rather than guess.
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
