import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/toast/toast_service.dart';

/// A [GlassSheet]-based reminder picker.
///
/// Shows quick-select chips for common time offsets, a custom option,
/// and a [GlassTextField] for an optional reminder label.
/// Returns via [onSet] with the chosen [DateTime] and optional label string.
class ReminderGlassSheet extends StatefulWidget {
  /// Called when the user confirms a reminder. [label] may be null/empty.
  final void Function(DateTime scheduledTime, String? label) onSet;

  const ReminderGlassSheet({super.key, required this.onSet});

  /// Displays the reminder picker in a [GlassSheet].
  static Future<void> show({
    required BuildContext context,
    required void Function(DateTime scheduledTime, String? label) onSet,
  }) {
    return GlassSheet.show(
      context: context,
      quality: GlassQuality.standard,
      showDragIndicator: true,
      isScrollable: false,
      enableDrag: false,
      interactionScale: 1.0,
      enableSaturationGlow: false,
      enableInteractionGlow: false,
      suppressInteractionOnChildren: true,
      topBorderRadius: 24,
      bottomBorderRadius: 0,
      margin: EdgeInsets.zero,
      builder: (context) => ReminderGlassSheet(onSet: onSet),
    );
  }

  @override
  State<ReminderGlassSheet> createState() => _ReminderGlassSheetState();
}

class _ReminderGlassSheetState extends State<ReminderGlassSheet> {
  late final TextEditingController _labelController;

  /// `null` means "Custom — picked via date/time pickers"
  DateTime? _selectedTime;

  /// Preset index: 0=Today(+1h), 1=Tomorrow(9am), 2=In2Days, 3=NextWeek, 4=Custom
  int? _presetIndex;

  bool _isSetting = false;

  static const _presets = [
    ('In 1 hour', null),
    ('Tomorrow 9 AM', null),
    ('In 2 days', null),
    ('Next week', null),
    ('Custom…', null),
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  DateTime _computePreset(int index) {
    final now = DateTime.now();
    switch (index) {
      case 0: // In 1 hour
        return now.add(const Duration(hours: 1));
      case 1: // Tomorrow 9 AM
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      case 2: // In 2 days at 9 AM
        final twoDays = now.add(const Duration(days: 2));
        return DateTime(twoDays.year, twoDays.month, twoDays.day, 9);
      case 3: // Next week at 9 AM
        final nextWeek = now.add(const Duration(days: 7));
        return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9);
      default:
        return now.add(const Duration(hours: 1));
    }
  }

  Future<void> _handlePresetTap(int index) async {
    if (index == 4) {
      // Custom — open date + time pickers
      final now = DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (pickedDate == null || !mounted) return;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime == null || !mounted) return;

      final custom = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      setState(() {
        _presetIndex = 4;
        _selectedTime = custom;
      });
    } else {
      setState(() {
        _presetIndex = index;
        _selectedTime = _computePreset(index);
      });
    }
  }

  Future<void> _confirm() async {
    final time = _selectedTime;
    if (time == null) return;

    if (time.isBefore(DateTime.now())) {
      ToastService.warning(context, 'Please pick a time in the future.');
      return;
    }

    setState(() => _isSetting = true);
    final label = _labelController.text.trim().isEmpty
        ? null
        : _labelController.text.trim();
    widget.onSet(time, label);
    if (mounted) Navigator.of(context).pop();
  }

  String _formatPreviewTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(dt.year, dt.month, dt.day);
    final diff = reminderDay.difference(today).inDays;

    final hour24 = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final timeStr = '$hour12:$minute $period';

    if (diff == 0) return 'Today at $timeStr';
    if (diff == 1) return 'Tomorrow at $timeStr';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomPad),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_add_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set a Reminder',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── Quick preset chips ───────────────────────────────────────
              Text(
                'When?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_presets.length, (i) {
                  final selected = _presetIndex == i;
                  return GlassChip(
                    label: _presets[i].$1,
                    selected: selected,
                    onTap: () => _handlePresetTap(i),
                  );
                }),
              ),

              // ── Selected time preview ────────────────────────────────────
              if (_selectedTime != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPreviewTime(_selectedTime!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Label field ──────────────────────────────────────────────
              GlassTextArea(
                controller: _labelController,
                placeholder: 'Reminder note (optional)\u2026',
                minLines: 1,
                maxLines: 2,
                quality: GlassQuality.standard,
                useOwnLayer: false,
                shape: const LiquidRoundedRectangle(borderRadius: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
                placeholderStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // ── Set button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_selectedTime == null || _isSetting)
                      ? null
                      : _confirm,
                  icon: _isSetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.alarm_on_rounded, size: 18),
                  label: const Text('Set Reminder'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
