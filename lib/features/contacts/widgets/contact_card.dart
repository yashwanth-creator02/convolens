import 'package:flutter/material.dart';

import '../models/contact_summary.dart';
import '../utils/format_last_contacted.dart';

class ContactCard extends StatelessWidget {
  final ContactSummary contact;
  final VoidCallback? onTap;

  const ContactCard({super.key, required this.contact, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastCallAt = contact.lastCallAt;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: contact.deviceContact?.thumbnail != null
            ? MemoryImage(contact.deviceContact!.thumbnail!)
            : null,
        child: contact.deviceContact?.thumbnail == null
            ? Text(_getInitials(contact.displayName))
            : null,
      ),
      title: Text(
        contact.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        lastCallAt != null
            ? '${contact.callCount} '
                  'call${contact.callCount == 1 ? '' : 's'}'
                  ' • ${formatLastContacted(lastCallAt)}'
            : 'No calls yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: contact.displayNumber.isNotEmpty
          ? const Icon(Icons.chevron_right)
          : null,
      onTap: onTap,
    );
  }

  String _getInitials(String name) {
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
}
