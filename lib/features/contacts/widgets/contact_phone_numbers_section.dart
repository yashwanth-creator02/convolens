import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/toast/toast_service.dart';
import '../../../core/utils/call_launcher.dart';
import 'contact_message_sheet.dart';

class ContactPhoneNumbersSection extends StatelessWidget {
  final Contact? deviceContact;
  final String fallbackNumber;

  const ContactPhoneNumbersSection({
    super.key,
    this.deviceContact,
    required this.fallbackNumber,
  });

  Future<void> _call(String number) async {
    await CallLauncher.call(number);
  }

  Future<void> _message(BuildContext context, String number) async {
    final launched = await CallLauncher.openWhatsAppChat(number);
    if (!launched && context.mounted) {
      ToastService.info(context, 'Could not open WhatsApp for $number');
    }
  }

  void _openMessageCompose(BuildContext context, String number) {
    showMessageComposeSheet(
      context,
      displayName: deviceContact?.displayName.isNotEmpty == true
          ? deviceContact!.displayName
          : number,
      phoneNumber: number,
    );
  }

  String _labelFor(Phone phone) {
    if (phone.customLabel.isNotEmpty) return phone.customLabel;
    final name = phone.label.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final phones = deviceContact?.phones ?? const <Phone>[];

    if (phones.isEmpty) {
      if (fallbackNumber.isEmpty) return const SizedBox.shrink();
      return _buildNumberRow(context, fallbackNumber, null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: phones
          .map(
            (phone) => _buildNumberRow(context, phone.number, _labelFor(phone)),
          )
          .toList(),
    );
  }

  Widget _buildNumberRow(BuildContext context, String number, String? label) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
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
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy $number',
                icon: const Icon(Icons.copy_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                color: scheme.onSurfaceVariant,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: number));
                  ToastService.success(context, '$number copied');
                },
              ),
              const SizedBox(width: 4),
              Material(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _call(number),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.call_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _message(context, number),
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    _openMessageCompose(context, number);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: Color(0xFF25D366),
                    ),
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
