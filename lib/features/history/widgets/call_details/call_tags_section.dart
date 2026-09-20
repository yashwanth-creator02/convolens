import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/database/app_database.dart';

class CallTagsSection extends StatelessWidget {
  final List<Tag> tags;
  final VoidCallback onAdd;
  final void Function(Tag tag) onRemove;

  const CallTagsSection({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: scheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No tags assigned — tap to add tags…',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13.5,
                  ),
                ),
              ),
              Icon(
                Icons.add_rounded,
                size: 18,
                color: scheme.primary,
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
      children: [
        ...tags.map((tag) {
          return GlassChip(
            label: tag.name,
            icon: Icon(
              Icons.tag,
              size: 14,
              color: scheme.primary.withValues(alpha: 0.9),
            ),
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
        }),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Add Tag',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

