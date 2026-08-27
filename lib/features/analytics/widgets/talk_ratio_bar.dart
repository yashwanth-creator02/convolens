import 'package:flutter/material.dart';

class TalkRatioBar extends StatelessWidget {
  final Map<int, int> callTypeCounts;

  const TalkRatioBar({super.key, required this.callTypeCounts});

  @override
  Widget build(BuildContext context) {
    final outgoing = callTypeCounts[2] ?? 0;
    final incoming = callTypeCounts[1] ?? 0;

    final total = outgoing + incoming;

    if (total == 0) {
      return const Text('No calls yet.', style: TextStyle(color: Colors.grey));
    }

    final youFraction = outgoing / total;
    final youFlex = (youFraction * 100).round().clamp(1, 99);
    final themFlex = 100 - youFlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: youFlex,
                child: Container(
                  height: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                flex: themFlex,
                child: Container(height: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You initiated '
          '${(youFraction * 100).round()}% • '
          'They initiated '
          '${(100 - youFraction * 100).round()}%',
        ),
      ],
    );
  }
}
