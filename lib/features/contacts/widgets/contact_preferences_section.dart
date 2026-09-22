import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';

const List<({String method, IconData icon})> communicationMethods = [
  (method: 'Call', icon: Icons.call_rounded),
  (method: 'WhatsApp', icon: Icons.chat_bubble_outline_rounded),
  (method: 'Message', icon: Icons.message_rounded),
  (method: 'Email', icon: Icons.email_outlined),
];

class ContactPreferencesSection extends StatefulWidget {
  final String normalizedNumber;
  final ContactDetail? detail;
  final AppDatabase db;

  const ContactPreferencesSection({
    super.key,
    required this.normalizedNumber,
    required this.detail,
    required this.db,
  });

  @override
  State<ContactPreferencesSection> createState() =>
      _ContactPreferencesSectionState();
}

class _ContactPreferencesSectionState extends State<ContactPreferencesSection> {
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController =
        TextEditingController(text: widget.detail?.bestTimeToCall ?? '');
  }

  @override
  void didUpdateWidget(ContactPreferencesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail?.bestTimeToCall != widget.detail?.bestTimeToCall) {
      if (_timeController.text != (widget.detail?.bestTimeToCall ?? '')) {
        _timeController.text = widget.detail?.bestTimeToCall ?? '';
      }
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _saveTime(String value) {
    widget.db.setContactFields(
      widget.normalizedNumber,
      ContactDetailsCompanion(bestTimeToCall: Value(value.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERRED METHOD',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: communicationMethods.map((item) {
            final isSelected = widget.detail?.preferredMethod == item.method;
            return GlassChip(
              label: item.method,
              selected: isSelected,
              icon: Icon(
                item.icon,
                size: 15,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              quality: GlassQuality.standard,
              useOwnLayer: false,
              labelStyle: TextStyle(
                color: isSelected ? scheme.primary : scheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.db.setContactFields(
                  widget.normalizedNumber,
                  ContactDetailsCompanion(
                    preferredMethod:
                        Value(isSelected ? null : item.method),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'BEST TIME TO CALL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _timeController,
          placeholder: 'e.g. Evenings after 6 PM, weekends…',
          style: TextStyle(color: scheme.onSurface, fontSize: 14),
          placeholderStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            fontSize: 14,
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.schedule_rounded,
              size: 18,
              color: scheme.primary.withValues(alpha: 0.8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          onSubmitted: _saveTime,
          onChanged: (val) {
            // Also debounce or save when losing focus
          },
        ),
      ],
    );
  }
}
