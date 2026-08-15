import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class CallAttachmentsSection extends StatelessWidget {
  final List<CallAttachment> attachments;
  final VoidCallback onAdd;
  final void Function(CallAttachment attachment) onView;
  final void Function(CallAttachment attachment) onDelete;

  const CallAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onAdd,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (attachments.isEmpty)
          const Text(
            'No attachments yet.',
            style: TextStyle(color: Colors.grey),
          )
        else
          Column(
            children: attachments.map((attachment) {
              final isPdf = attachment.fileType == 'pdf';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onView(attachment),
                leading: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: isPdf ? Colors.red : Colors.blue,
                ),
                title: Text(
                  attachment.originalFileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => onDelete(attachment),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
