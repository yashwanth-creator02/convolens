import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';

class ContactTagsSection extends StatelessWidget {
  final List<Tag> tags;
  final VoidCallback onAdd;
  final void Function(Tag tag) onRemove;

  const ContactTagsSection({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (tags.isEmpty) {
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tags added',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to categorize this contact with tags',
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: tags.map((tag) {
        return GlassChip(
          label: tag.name,
          icon: Icon(
            Icons.tag,
            size: 14,
            color: scheme.primary.withValues(alpha: 0.9),
          ),
          onTap: onAdd,
          onDeleted: () => onRemove(tag),
          deleteIcon: Icon(
            CupertinoIcons.xmark_circle_fill,
            size: 16,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          quality: GlassQuality.standard,
          useOwnLayer: false,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          labelStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}
