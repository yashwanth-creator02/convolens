import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Opens the custom Liquid Glass Color Picker bottom sheet.
Future<void> showContactColorPicker(
  BuildContext context, {
  required int? initialColorValue,
  required ValueChanged<int?> onColorSelected,
}) {
  HapticFeedback.selectionClick();
  return GlassSheet.show(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: true,
    isScrollable: true,
    enableDrag: true,
    topBorderRadius: 28,
    bottomBorderRadius: 0,
    margin: EdgeInsets.zero,
    builder: (sheetContext) => ContactColorPickerSheet(
      initialColor: initialColorValue != null ? Color(initialColorValue) : null,
      onColorSelected: onColorSelected,
    ),
  );
}

class ContactColorPickerSheet extends StatefulWidget {
  final Color? initialColor;
  final ValueChanged<int?> onColorSelected;

  const ContactColorPickerSheet({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<ContactColorPickerSheet> createState() =>
      _ContactColorPickerSheetState();
}

class _ContactColorPickerSheetState extends State<ContactColorPickerSheet> {
  late double _hue;
  late double _saturation;
  late double _value;
  late final TextEditingController _hexController;

  static const List<Color> _pickerPresets = [
    Color(0xFFEF4444), // Crimson Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
    Color(0xFF10B981), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Sky Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFF64748B), // Slate
    Color(0xFF78716C), // Stone
  ];

  @override
  void initState() {
    super.initState();
    final baseColor = widget.initialColor ?? const Color(0xFF3B82F6);
    final hsv = HSVColor.fromColor(baseColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController = TextEditingController(text: _formatHex(_currentColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
  }

  String _formatHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _onColorChanged() {
    _hexController.text = _formatHex(_currentColor);
  }

  void _applyHexInput(String text) {
    var raw = text.trim().replaceAll('#', '');
    if (raw.length == 6) {
      final val = int.tryParse('FF$raw', radix: 16);
      if (val != null) {
        final c = Color(val);
        final hsv = HSVColor.fromColor(c);
        setState(() {
          _hue = hsv.hue;
          _saturation = hsv.saturation;
          _value = hsv.value;
        });
      }
    }
  }

  void _selectPreset(Color color) {
    HapticFeedback.selectionClick();
    final hsv = HSVColor.fromColor(color);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
      _onColorChanged();
    });
  }

  void _confirmSelection() {
    HapticFeedback.mediumImpact();
    widget.onColorSelected(_currentColor.toARGB32());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _currentColor;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.palette_rounded,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Color',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Personalize contact card & theme',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Current Live Preview Pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatHex(color),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── 2D Saturation & Value Spectrum ─────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const height = 150.0;
              final pureHueColor =
                  HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();

              return GestureDetector(
                onPanDown: (details) {
                  final local = details.localPosition;
                  setState(() {
                    _saturation = (local.dx / width).clamp(0.0, 1.0);
                    _value = (1.0 - (local.dy / height)).clamp(0.0, 1.0);
                    _onColorChanged();
                  });
                },
                onPanUpdate: (details) {
                  final local = details.localPosition;
                  setState(() {
                    _saturation = (local.dx / width).clamp(0.0, 1.0);
                    _value = (1.0 - (local.dy / height)).clamp(0.0, 1.0);
                    _onColorChanged();
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // Base pure hue fill
                      Container(
                        width: width,
                        height: height,
                        color: pureHueColor,
                      ),
                      // Horizontal Saturation gradient: White to Transparent
                      Container(
                        width: width,
                        height: height,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                      // Vertical Value gradient: Transparent to Black
                      Container(
                        width: width,
                        height: height,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                      // Interactive Circular Thumb Indicator
                      Positioned(
                        left: (_saturation * width - 13).clamp(0.0, width - 26),
                        top: ((1.0 - _value) * height - 13)
                            .clamp(0.0, height - 26),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Hue Rainbow Track ──────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const height = 24.0;

              return GestureDetector(
                onPanDown: (details) {
                  setState(() {
                    _hue = ((details.localPosition.dx / width).clamp(0.0, 1.0) *
                            360.0)
                        .clamp(0.0, 360.0);
                    _onColorChanged();
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _hue = ((details.localPosition.dx / width).clamp(0.0, 1.0) *
                            360.0)
                        .clamp(0.0, 360.0);
                    _onColorChanged();
                  });
                },
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF0000),
                              Color(0xFFFFFF00),
                              Color(0xFF00FF00),
                              Color(0xFF00FFFF),
                              Color(0xFF0000FF),
                              Color(0xFFFF00FF),
                              Color(0xFFFF0000),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: ((_hue / 360.0) * width - 12)
                            .clamp(0.0, width - 24),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color:
                                HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Preset Palette Swatches ────────────────────────────────
          Text(
            'Presets',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _pickerPresets.map((preset) {
                final isSelected =
                    preset.toARGB32() == _currentColor.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _selectPreset(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: preset,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: preset.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // ── Hex Input Row & Confirm Action ─────────────────────────
          Row(
            children: [
              // Hex input field
              Expanded(
                flex: 4,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _hexController,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            fontFamily: 'monospace',
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _applyHexInput,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Apply Button
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor:
                          ThemeData.estimateBrightnessForColor(color) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Apply Color',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
