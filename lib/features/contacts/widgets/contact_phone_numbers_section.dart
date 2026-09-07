import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
    await CallLauncher.message(number);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number),
                if (label != null)
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 20),
            onPressed: () => _call(number),
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined, size: 20),
            onPressed: () => _message(number),
          ),
        ],
      ),
    );
  }
}
