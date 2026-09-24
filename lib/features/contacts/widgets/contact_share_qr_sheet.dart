import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/toast/toast_service.dart';
import '../../profile/utils/vcard_builder.dart';

/// Shows an interactive liquid glass bottom sheet with the contact's QR code (vCard)
/// and a copy button on the top right corner.
Future<void> showContactShareQrSheet(
  BuildContext context, {
  required String displayName,
  required String phoneNumber,
  Contact? deviceContact,
}) {
  HapticFeedback.selectionClick();
  return GlassSheet.show(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: true,
    isScrollable: false,
    enableDrag: true,
    topBorderRadius: 24,
    bottomBorderRadius: 0,
    margin: EdgeInsets.zero,
    builder: (context) => ContactShareQrSheet(
      displayName: displayName,
      phoneNumber: phoneNumber,
      deviceContact: deviceContact,
    ),
  );
}

class ContactShareQrSheet extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final Contact? deviceContact;

  const ContactShareQrSheet({
    super.key,
    required this.displayName,
    required this.phoneNumber,
    this.deviceContact,
  });

  String _buildVCardData() {
    final values = <String, String>{
      'displayName': displayName,
      'primaryPhone': phoneNumber,
    };

    if (deviceContact != null) {
      if (deviceContact!.name.first.isNotEmpty) {
        values['firstName'] = deviceContact!.name.first;
      }
      if (deviceContact!.name.last.isNotEmpty) {
        values['lastName'] = deviceContact!.name.last;
      }
      if (deviceContact!.emails.isNotEmpty) {
        values['email'] = deviceContact!.emails.first.address;
      }
      if (deviceContact!.organizations.isNotEmpty) {
        values['company'] = deviceContact!.organizations.first.company;
        values['jobTitle'] = deviceContact!.organizations.first.title;
      }
    }

    return buildVCard(values);
  }

  void _copyContactInfo(BuildContext context) {
    final info = displayName.isNotEmpty && displayName != phoneNumber
        ? '$displayName\n$phoneNumber'
        : phoneNumber;

    Clipboard.setData(ClipboardData(text: info));
    HapticFeedback.lightImpact();
    ToastService.success(context, 'Contact details copied');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vcard = _buildVCardData();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Row: Title and Copy Button on the top right corner
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Share Contact',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                // Copy button on the top right corner
                GlassIconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  size: 40,
                  quality: GlassQuality.standard,
                  onPressed: () => _copyContactInfo(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // High-contrast QR Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: vcard,
                size: 200,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 18),

            // Contact Name
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),

            // Phone Number
            if (phoneNumber.isNotEmpty && phoneNumber != displayName) ...[
              const SizedBox(height: 4),
              Text(
                phoneNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Helper text
            Text(
              'Scan with any camera or scanner to add contact',
              textAlign: TextAlign.center,
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
}
