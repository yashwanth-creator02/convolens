import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactHeader extends StatelessWidget {
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;

  const ContactHeader({
    super.key,
    required this.displayName,
    required this.displayNumber,
    this.deviceContact,
    required this.isFavorite,
    this.onFavoritePressed,
  });

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: displayNumber);
    await launchUrl(uri);
  }

  Future<void> _message() async {
    final uri = Uri(scheme: 'sms', path: displayNumber);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final organization = deviceContact?.organizations.isNotEmpty == true
        ? deviceContact!.organizations.first
        : null;
    final email = deviceContact?.emails.isNotEmpty == true
        ? deviceContact!.emails.first.address
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(child: _buildContactInfo(organization, email)),
            _buildFavoriteButton(),
          ],
        ),
        if (displayNumber.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _call,
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Call'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _message,
                icon: const Icon(Icons.message_outlined, size: 18),
                label: const Text('Message'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    final thumbnail = deviceContact?.thumbnail;

    return CircleAvatar(
      radius: 28,
      backgroundImage: thumbnail != null ? MemoryImage(thumbnail) : null,
      child: thumbnail == null
          ? Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 22),
            )
          : null,
    );
  }

  Widget _buildContactInfo(Organization? organization, String? email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        if (displayNumber.isNotEmpty)
          Text(displayNumber, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (organization != null &&
            (organization.company.isNotEmpty || organization.title.isNotEmpty))
          Text(
            [
              organization.title,
              organization.company,
            ].where((s) => s.isNotEmpty).join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        if (email != null && email.isNotEmpty)
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Colors.grey,
        size: 28,
      ),
      onPressed: onFavoritePressed,
    );
  }
}
