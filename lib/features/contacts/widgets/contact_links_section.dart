import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../utils/link_platform_icons.dart';

class ContactLinksSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactLinksSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  Future<void> _addLink(BuildContext context) async {
    String? selectedPlatform;
    final urlController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: linkPlatformKeys.map((key) {
                  return ChoiceChip(
                    label: Icon(linkPlatformIcons[key], size: 18),
                    selected: selectedPlatform == key,
                    onSelected: (_) => setState(() => selectedPlatform = key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Link or address',
                  hintText: 'https://…',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  selectedPlatform == null || urlController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedPlatform != null) {
      await db.addContactLink(
        normalizedNumber,
        selectedPlatform!,
        urlController.text.trim(),
      );
    }
  }

  Future<void> _handleLongPress(BuildContext context, ContactLink link) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy link'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: link.url));
        break;
      case 'edit':
        final controller = TextEditingController(text: link.url);
        final newUrl = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Link'),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (newUrl != null && newUrl.isNotEmpty) {
          await db.updateContactLink(link.id, newUrl);
        }
        break;
      case 'delete':
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'Delete Link?',
          message: 'This will remove this link from the contact.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (confirmed) await db.deleteContactLink(link.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContactLink>>(
      stream: db.watchLinksForContact(normalizedNumber),
      builder: (context, snapshot) {
        final links = snapshot.data ?? [];

        return Row(
          children: [
            ...links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () async {
                    final uri = Uri.tryParse(link.url);
                    if (uri != null) await launchUrl(uri);
                  },
                  onLongPress: () => _handleLongPress(context, link),
                  child: Icon(
                    linkPlatformIcons[link.platform] ?? Icons.link,
                    size: 26,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              onPressed: () => _addLink(context),
            ),
          ],
        );
      },
    );
  }
}
