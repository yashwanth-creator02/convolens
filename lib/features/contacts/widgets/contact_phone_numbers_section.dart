import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/toast/toast_service.dart';
import '../../../core/utils/call_launcher.dart';

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

  Future<void> _message(String number) async {
    final launched = await CallLauncher.openWhatsAppChat(number);
    if (!launched) {
      await CallLauncher.message(number);
    }
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: number));
            ToastService.info(context, '$number copied');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        number,
                        style: const TextStyle(
                          fontSize: 15,
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
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Call $number',
                  icon: Icon(Icons.call_rounded,
                      size: 20, color: scheme.primary),
                  onPressed: () => _call(number),
                ),
                IconButton(
                  tooltip: 'Message $number',
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 19, color: Color(0xFF25D366)),
                  onPressed: () => _message(number),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
