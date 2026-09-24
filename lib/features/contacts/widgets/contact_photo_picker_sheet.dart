import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/toast/toast_service.dart';

sealed class ContactPhotoResult {
  const ContactPhotoResult();
}

class ContactPhotoBytes extends ContactPhotoResult {
  final Uint8List bytes;
  const ContactPhotoBytes(this.bytes);
}

class ContactPhotoRemoved extends ContactPhotoResult {
  const ContactPhotoRemoved();
}

/// Shows a liquid glass bottom sheet allowing the user to take a new photo with
/// the camera, pick an existing image from the gallery, or remove the current photo.
Future<ContactPhotoResult?> showContactPhotoPickerSheet(
  BuildContext context, {
  required bool hasExistingPhoto,
}) {
  HapticFeedback.selectionClick();

  return GlassSheet.show<ContactPhotoResult>(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: true,
    isScrollable: false,
    topBorderRadius: 28,
    bottomBorderRadius: 0,
    margin: EdgeInsets.zero,
    builder: (sheetContext) => _ContactPhotoPickerSheet(
      hasExistingPhoto: hasExistingPhoto,
    ),
  );
}

class _ContactPhotoPickerSheet extends StatefulWidget {
  final bool hasExistingPhoto;

  const _ContactPhotoPickerSheet({required this.hasExistingPhoto});

  @override
  State<_ContactPhotoPickerSheet> createState() =>
      _ContactPhotoPickerSheetState();
}

class _ContactPhotoPickerSheetState extends State<_ContactPhotoPickerSheet> {
  bool _isPicking = false;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      if (source == ImageSource.camera) {
        final camStatus = await Permission.camera.request();
        if (camStatus.isPermanentlyDenied) {
          if (context.mounted) {
            ToastService.warning(
              context,
              'Camera permission is required to take a photo. Please enable it in Settings.',
            );
          }
          if (mounted) setState(() => _isPicking = false);
          return;
        }
        if (!camStatus.isGranted) {
          if (mounted) setState(() => _isPicking = false);
          return;
        }
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!context.mounted) return;

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (context.mounted) {
          Navigator.of(context).pop(ContactPhotoBytes(bytes));
        }
      } else {
        if (mounted) setState(() => _isPicking = false);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.error(context, 'Failed to pick image: $e');
      }
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removePhoto(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(const ContactPhotoRemoved());
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBackgroundColor,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Contact Photo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if (_isPicking)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Options Container ───────────────────────────────────────────
            GlassContainer(
              quality: GlassQuality.standard,
              useOwnLayer: false,
              shape: const LiquidRoundedSuperellipse(borderRadius: 20),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera
                  _buildOptionTile(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    title: 'Take Photo',
                    subtitle: 'Use camera to take a new picture',
                    iconColor: scheme.primary,
                    iconBackgroundColor:
                        scheme.primary.withValues(alpha: 0.12),
                    onTap: () => _pickImage(context, ImageSource.camera),
                  ),

                  Divider(
                    height: 1,
                    indent: 68,
                    color: scheme.outlineVariant.withValues(alpha: 0.25),
                  ),

                  // Gallery
                  _buildOptionTile(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    title: 'Choose from Gallery',
                    subtitle: 'Select an image from photo library',
                    iconColor: const Color(0xFF8B5CF6),
                    iconBackgroundColor:
                        const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    onTap: () => _pickImage(context, ImageSource.gallery),
                  ),

                  if (widget.hasExistingPhoto) ...[
                    Divider(
                      height: 1,
                      indent: 68,
                      color: scheme.outlineVariant.withValues(alpha: 0.25),
                    ),

                    // Remove
                    _buildOptionTile(
                      context: context,
                      icon: Icons.delete_outline_rounded,
                      title: 'Remove Photo',
                      subtitle: 'Revert to initials avatar',
                      iconColor: scheme.error,
                      iconBackgroundColor:
                          scheme.error.withValues(alpha: 0.12),
                      titleColor: scheme.error,
                      onTap: () => _removePhoto(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Cancel Button ───────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
