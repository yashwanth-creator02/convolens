import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<({String name, Color color})> contactColorSwatches = [
  (name: 'Crimson', color: Color(0xFFE53935)),
  (name: 'Coral', color: Color(0xFFFB8C00)),
  (name: 'Amber', color: Color(0xFFFFB300)),
  (name: 'Emerald', color: Color(0xFF43A047)),
  (name: 'Teal', color: Color(0xFF00897B)),
  (name: 'Cyan', color: Color(0xFF00ACC1)),
  (name: 'Cobalt', color: Color(0xFF1E88E5)),
  (name: 'Indigo', color: Color(0xFF3949AB)),
  (name: 'Violet', color: Color(0xFF8E24AA)),
  (name: 'Rose', color: Color(0xFFD81B60)),
  (name: 'Slate', color: Color(0xFF546E7A)),
];

class ContactColorSection extends StatelessWidget {
  final int? colorValue;
  final ValueChanged<int?> onColorSelected;

  const ContactColorSection({
    super.key,
    required this.colorValue,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Swatches
        ...contactColorSwatches.map((item) {
          final isSelected = colorValue == item.color.toARGB32();
          return Tooltip(
            message: item.name,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onColorSelected(item.color.toARGB32());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? item.color.withValues(alpha: 0.5)
                            : item.color.withValues(alpha: 0.2),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          );
        }),

        // Clear / Default button
        Tooltip(
          message: 'Reset theme color',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.selectionClick();
                onColorSelected(null);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorValue == null
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.4),
                    width: colorValue == null ? 2 : 1,
                  ),
                ),
                child: Icon(
                  Icons.format_color_reset_rounded,
                  size: 18,
                  color: colorValue == null
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
