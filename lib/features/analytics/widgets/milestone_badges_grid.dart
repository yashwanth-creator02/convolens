import 'package:flutter/material.dart';

import '../models/analytics_summary.dart';

class MilestoneBadgesGrid extends StatelessWidget {
  final AnalyticsSummary summary;

  const MilestoneBadgesGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final badges = [
      _BadgeData(
        title: 'Century Club',
        description: 'Log 100 total phone calls',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFF3B82F6),
        isUnlocked: summary.totalCalls >= 100,
        progress: (summary.totalCalls / 100).clamp(0.0, 1.0),
        progressText: '${summary.totalCalls}/100 calls',
      ),
      _BadgeData(
        title: 'Marathon Talker',
        description: 'Complete a single 30+ min call',
        icon: Icons.timer_outlined,
        color: const Color(0xFFF59E0B),
        isUnlocked: summary.longestCallSeconds >= 1800,
        progress: (summary.longestCallSeconds / 1800).clamp(0.0, 1.0),
        progressText: '${(summary.longestCallSeconds / 60).round()}/30 min',
      ),
      _BadgeData(
        title: 'Consistency Star',
        description: 'Achieve a 7-day calling streak',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        isUnlocked: summary.longestStreak >= 7,
        progress: (summary.longestStreak / 7).clamp(0.0, 1.0),
        progressText: '${summary.longestStreak}/7 days',
      ),
      _BadgeData(
        title: 'Broad Network',
        description: 'Connect with 20+ unique people',
        icon: Icons.hub_rounded,
        color: const Color(0xFF10B981),
        isUnlocked: summary.totalContacts >= 20,
        progress: (summary.totalContacts / 20).clamp(0.0, 1.0),
        progressText: '${summary.totalContacts}/20 people',
      ),
      _BadgeData(
        title: 'Deep Listener',
        description: 'Accumulate 10+ hours total talk time',
        icon: Icons.hearing_rounded,
        color: const Color(0xFF8B5CF6),
        isUnlocked: summary.totalTalkSeconds >= 36000,
        progress: (summary.totalTalkSeconds / 36000).clamp(0.0, 1.0),
        progressText: '${(summary.totalTalkSeconds / 3600).round()}/10 hours',
      ),
      _BadgeData(
        title: 'Loyal Companion',
        description: 'Reach 20+ calls with a single contact',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFEC4899),
        isUnlocked: (summary.mostContacted.firstOrNull?.callCount ?? 0) >= 20,
        progress: ((summary.mostContacted.firstOrNull?.callCount ?? 0) / 20).clamp(0.0, 1.0),
        progressText: '${summary.mostContacted.firstOrNull?.callCount ?? 0}/20 calls',
      ),
    ];

    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header summary pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements Unlocked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unlockedCount of ${badges.length} Unlocked',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2-column grid of achievement badges
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges.map((b) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildBadgeCard(context, b),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BuildContext context, _BadgeData badge) {
    final scheme = Theme.of(context).colorScheme;
    final color = badge.isUnlocked ? badge.color : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.isUnlocked
            ? color.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isUnlocked
              ? color.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? color.withValues(alpha: 0.16)
                      : Colors.grey.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.icon,
                  size: 16,
                  color: color,
                ),
              ),
              if (badge.isUnlocked)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                )
              else
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: badge.isUnlocked ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: badge.progress,
              minHeight: 5,
              backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.progressText,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String progressText;

  const _BadgeData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
    required this.progressText,
  });
}
