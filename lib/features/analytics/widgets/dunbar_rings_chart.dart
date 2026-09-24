import 'dart:math';
import 'package:flutter/material.dart';

import '../../contacts/models/contact_summary.dart';

class DunbarRingsChart extends StatelessWidget {
  final Map<String, List<ContactSummary>> tiers;
  final void Function(ContactSummary) onContactTap;

  const DunbarRingsChart({
    super.key,
    required this.tiers,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = tiers['inner'] ?? [];
    final close = tiers['close'] ?? [];
    final regular = tiers['regular'] ?? [];
    final dormant = tiers['dormant'] ?? [];

    final hasAny = inner.isNotEmpty || close.isNotEmpty || regular.isNotEmpty;

    if (!hasAny) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Make more calls to populate your relationship tiers.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = min(constraints.maxWidth, 340.0);
            final center = Offset(size / 2, size / 2);

            // Ring radii
            final r1 = size * 0.22; // Inner Circle
            final r2 = size * 0.35; // Close
            final r3 = size * 0.46; // Regular

            // Sample max contacts per ring to keep visual clear
            final displayedInner = inner.take(6).toList();
            final displayedClose = close.take(8).toList();
            final displayedRegular = regular.take(10).toList();

            return RepaintBoundary(
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(size, size),
                      painter: _DunbarRingsPainter(
                        center: center,
                        r1: r1,
                        r2: r2,
                        r3: r3,
                        ringColor: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.25),
                      ),
                    ),

                    // Center "You" node
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    // Ring 1 nodes (Inner Circle)
                    ..._buildOrbitNodes(
                      contacts: displayedInner,
                      center: center,
                      radius: r1,
                      nodeSize: 26,
                      nodeColor: const Color(0xFF10B981),
                      offsetAngle: -pi / 2,
                    ),

                    // Ring 2 nodes (Close)
                    ..._buildOrbitNodes(
                      contacts: displayedClose,
                      center: center,
                      radius: r2,
                      nodeSize: 22,
                      nodeColor: const Color(0xFF06B6D4),
                      offsetAngle: -pi / 4,
                    ),

                    // Ring 3 nodes (Regular)
                    ..._buildOrbitNodes(
                      contacts: displayedRegular,
                      center: center,
                      radius: r3,
                      nodeSize: 18,
                      nodeColor: const Color(0xFF8B5CF6),
                      offsetAngle: 0,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Tier Legend
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _tierBadge(
              label: 'Inner Circle',
              count: inner.length,
              color: const Color(0xFF10B981),
            ),
            _tierBadge(
              label: 'Close',
              count: close.length,
              color: const Color(0xFF06B6D4),
            ),
            _tierBadge(
              label: 'Regular',
              count: regular.length,
              color: const Color(0xFF8B5CF6),
            ),
            _tierBadge(
              label: 'Dormant',
              count: dormant.length,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildOrbitNodes({
    required List<ContactSummary> contacts,
    required Offset center,
    required double radius,
    required double nodeSize,
    required Color nodeColor,
    required double offsetAngle,
  }) {
    if (contacts.isEmpty) return [];

    return List.generate(contacts.length, (i) {
      final angle = offsetAngle + (2 * pi * i / contacts.length);
      final pos = center + Offset(radius * cos(angle), radius * sin(angle));
      final c = contacts[i];

      return Positioned(
        left: pos.dx - (nodeSize / 2),
        top: pos.dy - (nodeSize / 2),
        child: GestureDetector(
          onTap: () => onContactTap(c),
          child: Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor.withValues(alpha: 0.2),
              border: Border.all(color: nodeColor, width: 1.5),
            ),
            child: ClipOval(
              child: c.deviceContact?.thumbnail != null
                  ? Image.memory(
                      c.deviceContact!.thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        c.displayName.isNotEmpty
                            ? c.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: nodeSize * 0.45,
                          fontWeight: FontWeight.bold,
                          color: nodeColor,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _tierBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DunbarRingsPainter extends CustomPainter {
  final Offset center;
  final double r1;
  final double r2;
  final double r3;
  final Color ringColor;

  _DunbarRingsPainter({
    required this.center,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, r1, paint);
    canvas.drawCircle(center, r2, paint);
    canvas.drawCircle(center, r3, paint);
  }

  @override
  bool shouldRepaint(covariant _DunbarRingsPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.r1 != r1 ||
        oldDelegate.r2 != r2 ||
        oldDelegate.r3 != r3 ||
        oldDelegate.ringColor != ringColor;
  }
}
