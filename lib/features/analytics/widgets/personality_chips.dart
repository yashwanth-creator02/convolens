import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class PersonalityChips extends StatelessWidget {
  final List<String> labels;

  const PersonalityChips({
    super.key,
    required this.labels,
  });

  static const _traitMetadata = {
    'Morning Caller': (
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
      desc: 'Most of your conversations occur between 6 AM and 12 PM.',
    ),
    'Afternoon Caller': (
      icon: Icons.wb_cloudy_rounded,
      color: Color(0xFF06B6D4),
      desc: 'Your peak calling time is during midday and afternoon hours.',
    ),
    'Evening Caller': (
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF6366F1),
      desc: 'You wind down your day by catching up with people in the evening.',
    ),
    'Night Owl': (
      icon: Icons.bedtime_rounded,
      color: Color(0xFF8B5CF6),
      desc: 'Late-night hours (after 9 PM) are when you make or receive most calls.',
    ),
    'Weekend Warrior': (
      icon: Icons.weekend_rounded,
      color: Color(0xFFEC4899),
      desc: 'Over a third of your calls happen during Saturdays and Sundays.',
    ),
    'Weekday Pro': (
      icon: Icons.work_outline_rounded,
      color: Color(0xFF3B82F6),
      desc: 'Your calling activity is predominantly concentrated on work days.',
    ),
    'Deep Talker': (
      icon: Icons.forum_rounded,
      color: Color(0xFF10B981),
      desc: 'Your calls average over 8 minutes, favoring meaningful, in-depth dialogues.',
    ),
    'Quick Check-in': (
      icon: Icons.bolt_rounded,
      color: Color(0xFFEAB308),
      desc: 'You prefer quick, focused conversations under 90 seconds.',
    ),
    'Consistent': (
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEF4444),
      desc: 'You maintain a steady daily streak of reaching out to someone.',
    ),
    'Streak Builder': (
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFF97316),
      desc: 'You have shown long periods of unbroken daily connection.',
    ),
    'Balanced Caller': (
      icon: Icons.tune_rounded,
      color: Color(0xFF14B8A6),
      desc: 'Your call patterns are evenly distributed across times and days.',
    ),
    'Fresh Start': (
      icon: Icons.eco_rounded,
      color: Color(0xFF22C55E),
      desc: 'Start making calls to unlock your personalized communication profile.',
    ),
  };

  void _showTraitDetail(BuildContext context, String trait) {
    final meta = _traitMetadata[trait] ?? (
      icon: Icons.star_rounded,
      color: Theme.of(context).colorScheme.primary,
      desc: 'Inferred from your calling habits.',
    );

    GlassSheet.show(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, size: 36, color: meta.color),
            ),
            const SizedBox(height: 14),
            Text(
              trait,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              meta.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final meta = _traitMetadata[label] ?? (
          icon: Icons.auto_awesome_rounded,
          color: Theme.of(context).colorScheme.primary,
          desc: '',
        );

        return InkWell(
          onTap: () => _showTraitDetail(context, label),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: meta.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(meta.icon, size: 14, color: meta.color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: meta.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
