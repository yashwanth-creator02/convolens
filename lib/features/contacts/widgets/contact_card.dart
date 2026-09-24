import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/widgets/favorite_avatar_ring.dart';
import '../../profile/utils/vcard_builder.dart';
import '../models/contact_summary.dart';

class ContactCard extends StatelessWidget {
  final ContactSummary contact;
  final VoidCallback? onTap;
  final AppDatabase? db;
  final bool isArchived;
  final bool isFavorite;
  final int? colorValue;
  final VoidCallback? onArchive;
  final VoidCallback? onFavorite;
  final Widget Function(BuildContext context, VoidCallback closePopover)?
      avatarPopoverBuilder;

  const ContactCard({
    super.key,
    required this.contact,
    this.onTap,
    this.db,
    this.isArchived = false,
    this.isFavorite = false,
    this.colorValue,
    this.onArchive,
    this.onFavorite,
    this.avatarPopoverBuilder,
  });

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Purple
    [Color(0xFF3B82F6), Color(0xFF06B6D4)], // Blue to Cyan
    [Color(0xFF10B981), Color(0xFF14B8A6)], // Emerald to Teal
    [Color(0xFFF59E0B), Color(0xFFF97316)], // Amber to Orange
    [Color(0xFFEC4899), Color(0xFFF43F5E)], // Pink to Rose
    [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Purple to Fuchsia
    [Color(0xFF14B8A6), Color(0xFF3B82F6)], // Teal to Blue
  ];

  List<Color> _getGradientForName(String name) {
    if (name.isEmpty) return _avatarGradients[0];
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    return _avatarGradients[hash % _avatarGradients.length];
  }

  static String getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _handleArchive(
    BuildContext context,
    VoidCallback closePopover,
  ) async {
    closePopover();
    final newArchived = !isArchived;

    if (db != null) {
      await db!.setContactFields(
        contact.normalizedNumber,
        ContactDetailsCompanion(
          isArchived: drift.Value(newArchived),
        ),
      );
    }

    onArchive?.call();

    if (context.mounted) {
      ToastService.success(
        context,
        newArchived ? 'Contact archived' : 'Contact unarchived',
      );
    }
  }

  Future<void> _handleFavorite(
    BuildContext context,
    VoidCallback closePopover, [
    bool? currentFavorite,
  ]) async {
    closePopover();
    final effectiveFav = currentFavorite ?? isFavorite;
    final newFavorite = !effectiveFav;

    if (db != null) {
      await db!.toggleContactFavorite(contact.normalizedNumber, newFavorite);
    }

    onFavorite?.call();

    if (context.mounted) {
      ToastService.success(
        context,
        newFavorite ? 'Added to favorites' : 'Removed from favorites',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (db == null || contact.normalizedNumber.isEmpty) {
      return _buildCard(
        context,
        colorValue: colorValue,
        isFavorite: isFavorite,
      );
    }

    return StreamBuilder<ContactDetail?>(
      stream: db!.watchContactDetails(contact.normalizedNumber),
      builder: (context, snapshot) {
        final hasEmitted = snapshot.connectionState != ConnectionState.waiting;
        final detail = snapshot.data;
        return _buildCard(
          context,
          colorValue: hasEmitted ? detail?.colorValue : colorValue,
          isFavorite: hasEmitted
              ? (detail?.isFavorite ?? isFavorite)
              : isFavorite,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    int? colorValue,
    required bool isFavorite,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hasThumb = contact.deviceContact?.thumbnail != null;

    final titleText = contact.displayName.trim().isNotEmpty
        ? contact.displayName.trim()
        : (contact.displayNumber.trim().isNotEmpty
            ? contact.displayNumber.trim()
            : 'Unknown');

    final gradient = _getGradientForName(titleText);
    final cardColor = colorValue != null ? Color(colorValue) : null;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cardColor?.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: cardColor != null
                    ? Border.all(
                        color: cardColor.withValues(alpha: 0.32),
                        width: 1.2,
                      )
                    : null,
                boxShadow: cardColor != null
                    ? [
                        BoxShadow(
                          color: cardColor.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar with GlassPopover
                  GlassPopover(
                    popoverWidth: 295,
                    popoverBorderRadius: 24.0,
                    quality: GlassQuality.standard,
                    triggerBuilder: (popoverCtx, togglePopover) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          togglePopover();
                        },
                        child: FavoriteAvatarRing(
                          isFavorite: isFavorite,
                          scheme: scheme,
                          ringPadding: 2.0,
                          starSize: 9.0,
                          child: Container(
                            width: isFavorite ? 38 : 42,
                            height: isFavorite ? 38 : 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: !hasThumb
                                  ? (cardColor != null
                                      ? LinearGradient(
                                          colors: [
                                            cardColor,
                                            Color.lerp(
                                              cardColor,
                                              Colors.black,
                                              0.25,
                                            )!,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ))
                                  : null,
                              border: Border.all(
                                color: isFavorite
                                    ? Colors.transparent
                                    : (cardColor != null
                                        ? cardColor.withValues(alpha: 0.45)
                                        : scheme.outlineVariant
                                            .withValues(alpha: 0.25)),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: hasThumb
                                  ? Image.memory(
                                      contact.deviceContact!.thumbnail!,
                                      fit: BoxFit.cover,
                                      width: isFavorite ? 38 : 42,
                                      height: isFavorite ? 38 : 42,
                                    )
                                  : Center(
                                      child: Text(
                                        getInitials(titleText),
                                        style: TextStyle(
                                          fontSize: isFavorite ? 13 : 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                    contentBuilder: (popoverCtx, closePopover) {
                      if (avatarPopoverBuilder != null) {
                        return avatarPopoverBuilder!(popoverCtx, closePopover);
                      }
                      return _ContactCardPopoverContent(
                        contact: contact,
                        titleText: titleText,
                        gradient: cardColor != null
                            ? [
                                cardColor,
                                Color.lerp(cardColor, Colors.black, 0.25)!,
                              ]
                            : gradient,
                        scheme: scheme,
                        colorValue: colorValue,
                        isArchived: isArchived,
                        isFavorite: isFavorite,
                        closePopover: closePopover,
                        onArchive: () => _handleArchive(context, closePopover),
                        onFavorite: () => _handleFavorite(
                          context,
                          closePopover,
                          isFavorite,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),

                  // Contact Name or Number
                  Expanded(
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),

                  // Subtle Arrow Indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: cardColor != null
                        ? cardColor.withValues(alpha: 0.75)
                        : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _ContactCardPopoverContent extends StatefulWidget {
  final ContactSummary contact;
  final String titleText;
  final List<Color> gradient;
  final ColorScheme scheme;
  final int? colorValue;
  final bool isArchived;
  final bool isFavorite;
  final VoidCallback closePopover;
  final VoidCallback onArchive;
  final VoidCallback onFavorite;

  const _ContactCardPopoverContent({
    required this.contact,
    required this.titleText,
    required this.gradient,
    required this.scheme,
    this.colorValue,
    required this.isArchived,
    required this.isFavorite,
    required this.closePopover,
    required this.onArchive,
    required this.onFavorite,
  });

  @override
  State<_ContactCardPopoverContent> createState() =>
      _ContactCardPopoverContentState();
}

class _ContactCardPopoverContentState
    extends State<_ContactCardPopoverContent> {
  static final Map<String, Uint8List> _fullPhotoCache = {};
  Uint8List? _fullPhoto;

  @override
  void initState() {
    super.initState();
    _loadFullPhoto();
  }

  void _loadFullPhoto() {
    final contact = widget.contact;
    final contactId = contact.deviceContactId ?? contact.deviceContact?.id;
    final cacheKey = (contactId != null && contactId.isNotEmpty)
        ? contactId
        : contact.normalizedNumber;

    if (cacheKey.isNotEmpty && _fullPhotoCache.containsKey(cacheKey)) {
      _fullPhoto = _fullPhotoCache[cacheKey];
      return;
    }

    final cached = ContactCache.findContact(
      number: contact.normalizedNumber,
      name: contact.displayName,
    );

    if (cached?.photo != null && cached!.photo!.isNotEmpty) {
      _fullPhoto = cached.photo;
      if (cacheKey.isNotEmpty) {
        _fullPhotoCache[cacheKey] = cached.photo!;
      }
      return;
    }

    if (contact.deviceContact?.photo != null &&
        contact.deviceContact!.photo!.isNotEmpty) {
      _fullPhoto = contact.deviceContact!.photo;
      if (cacheKey.isNotEmpty) {
        _fullPhotoCache[cacheKey] = _fullPhoto!;
      }
      return;
    }

    final targetId = contactId ?? cached?.id;
    if (targetId != null && targetId.isNotEmpty) {
      _fetchDeviceContactFullPhoto(targetId, cacheKey);
    }
  }

  Future<void> _fetchDeviceContactFullPhoto(
    String id,
    String cacheKey,
  ) async {
    try {
      final full = await FlutterContacts.getContact(
        id,
        withPhoto: true,
        withThumbnail: true,
      );
      if (full != null && full.photo != null && full.photo!.isNotEmpty) {
        _fullPhotoCache[cacheKey] = full.photo!;
        ContactCache.updateContact(full);
        if (mounted) {
          setState(() {
            _fullPhoto = full.photo;
          });
        }
      }
    } catch (_) {}
  }

  Widget _buildPhotoHero(Uint8List photoBytes) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 310,
        minHeight: 180,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient blurred backdrop so letterboxing matches photo colors smoothly
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.memory(
                  photoBytes,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const SizedBox(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
            // Uncropped, full quality, razor-sharp entire picture
            Image.memory(
              photoBytes,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (ctx, err, stack) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsHero() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        ContactCard.getInitials(widget.titleText),
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoAndActionsRow() {
    final hasNumber = widget.contact.displayNumber.trim().isNotEmpty;
    final hasName = widget.contact.displayName.trim().isNotEmpty;
    final cardColor = widget.colorValue != null ? Color(widget.colorValue!) : null;

    return Container(
      decoration: BoxDecoration(
        color: cardColor?.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Name and Phone Number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: widget.scheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                if (hasNumber && hasName) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.displayNumber.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right side: Action Buttons on the same row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Favorite Action
              _buildQuickActionButton(
                icon: widget.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                label: widget.isFavorite ? 'Saved' : 'Favorite',
                color: const Color(0xFFFBBF24),
                enabled: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onFavorite();
                },
                scheme: widget.scheme,
              ),
              const SizedBox(width: 6),

              // 2. Archive Action
              _buildQuickActionButton(
                icon: widget.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                label: widget.isArchived ? 'Restore' : 'Archive',
                color: const Color(0xFFF59E0B),
                enabled: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onArchive();
                },
                scheme: widget.scheme,
              ),
              const SizedBox(width: 6),

              // 3. Share Action (Triggers nested GlassPopover with QR Code)
              GlassPopover(
                popoverWidth: 260,
                popoverBorderRadius: 20.0,
                quality: GlassQuality.standard,
                triggerBuilder: (shareCtx, toggleSharePopover) {
                  return _buildQuickActionButton(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Share',
                    color: const Color(0xFF6366F1),
                    enabled: true,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      toggleSharePopover();
                    },
                    scheme: widget.scheme,
                  );
                },
                contentBuilder: (shareCtx, closeSharePopover) {
                  return _buildQrPopoverContent(
                    shareCtx,
                    closeSharePopover,
                    widget.titleText,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildQrPopoverContent(
    BuildContext context,
    VoidCallback closeSharePopover,
    String titleText,
  ) {
    final phone = widget.contact.displayNumber.isNotEmpty
        ? widget.contact.displayNumber
        : widget.contact.normalizedNumber;

    final vcard = buildVCard({
      'displayName': titleText,
      'primaryPhone': phone,
    });

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Share Contact',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // High-contrast QR Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: QrImageView(
              data: vcard,
              size: 170,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              phone,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Scan with any camera to add',
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 16.5,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cached = ContactCache.findContact(
      number: widget.contact.normalizedNumber,
      name: widget.contact.displayName,
    );
    final photoBytes = _fullPhoto ??
        widget.contact.deviceContact?.photo ??
        cached?.photo ??
        widget.contact.deviceContact?.thumbnail ??
        cached?.thumbnail;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photoBytes != null && photoBytes.isNotEmpty)
            _buildPhotoHero(photoBytes)
          else
            _buildInitialsHero(),
          _buildInfoAndActionsRow(),
        ],
      ),
    );
  }
}
