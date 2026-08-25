import 'dart:math';

import 'package:flutter/material.dart';

import '../../contacts/models/contact_summary.dart';
import 'relationship_web_painter.dart';

class RelationshipWeb extends StatelessWidget {
  final List<ContactSummary> contacts;
  final void Function(ContactSummary) onContactTap;

  const RelationshipWeb(
      {super.key, required this.contacts, required this.onContactTap});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Not enough call data yet.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final topContacts = contacts.take(8).toList();
    final maxCount = topContacts.first.callCount.clamp(1, 999999);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final center = Offset(size / 2, size / 2);
        final radius = (size / 2) - 40;

        final positions = List.generate(topContacts.length, (i) {
          final angle = (2 * pi * i / topContacts.length) - (pi / 2);
          return center + Offset(radius * cos(angle), radius * sin(angle));
        });

        final strengths = topContacts
            .map((c) => c.callCount / maxCount)
            .map((v) => v.toDouble())
            .toList();

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: RelationshipWebPainter(
                  center: center,
                  nodePositions: positions,
                  strengths: strengths,
                  lineColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              Positioned(
                left: center.dx - 24,
                top: center.dy - 24,
                child: const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
              ),
              ...List.generate(topContacts.length, (i) {
                final contact = topContacts[i];
                final pos = positions[i];
                final nodeRadius = 16 + (strengths[i] * 8);

                return Positioned(
                  left: pos.dx - nodeRadius,
                  top: pos.dy - nodeRadius,
                  child: GestureDetector(
                    onTap: () => onContactTap(contact),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: nodeRadius,
                          backgroundImage: contact.deviceContact?.thumbnail !=
                              null
                              ? MemoryImage(contact.deviceContact!.thumbnail!)
                              : null,
                          child: contact.deviceContact?.thumbnail == null
                              ? Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 12),
                          )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}