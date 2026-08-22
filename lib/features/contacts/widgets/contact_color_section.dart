import 'package:flutter/material.dart';

const List<Color> contactColorSwatches = [
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
  Colors.blueGrey,
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...contactColorSwatches.map((color) {
          final isSelected = colorValue == color.value;
          return GestureDetector(
            onTap: () => onColorSelected(color.value),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () => onColorSelected(null),
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
