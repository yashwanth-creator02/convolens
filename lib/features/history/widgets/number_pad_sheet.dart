import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/services/contact_cache.dart';
import '../../../core/services/numpad_preferences.dart';
import '../../../core/utils/call_launcher.dart';

/// Opens the liquid glass number pad bottom sheet.
///
/// Returns the dialed number string if the user taps "Search", or null if dismissed.
Future<String?> showNumberPadSheet(BuildContext context) {
  // Ensure preferences are initialized
  NumpadPreferences.init();

  return GlassSheet.show<String>(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: false,
    isScrollable: false,
    enableDrag: true,
    interactionScale: 1.0,
    enableSaturationGlow: false,
    enableInteractionGlow: false,
    suppressInteractionOnChildren: true,
    topBorderRadius: 28,
    bottomBorderRadius: 0,
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    builder: (context) => const _NumberPadSheet(),
  );
}

class _NumberPadSheet extends StatefulWidget {
  const _NumberPadSheet();

  @override
  State<_NumberPadSheet> createState() => _NumberPadSheetState();
}

class _NumberPadSheetState extends State<_NumberPadSheet> {
  String _digits = '';
  bool _oneHanded = NumpadPreferences.oneHandedMode;
  bool _alignRight = NumpadPreferences.alignRight;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await NumpadPreferences.init();
    if (mounted) {
      setState(() {
        _oneHanded = NumpadPreferences.oneHandedMode;
        _alignRight = NumpadPreferences.alignRight;
      });
    }
  }

  void _toggleOneHanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _oneHanded = !_oneHanded;
    });
    NumpadPreferences.setOneHandedMode(_oneHanded);
  }

  void _toggleAlignment() {
    HapticFeedback.selectionClick();
    setState(() {
      _alignRight = !_alignRight;
    });
    NumpadPreferences.setAlignRight(_alignRight);
  }

  void _addDigit(String digit) {
    HapticFeedback.lightImpact();
    setState(() => _digits += digit);
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _clearAll() {
    if (_digits.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _digits = '');
  }

  Future<void> _callDigits() async {
    if (_digits.isEmpty) return;
    HapticFeedback.mediumImpact();
    final success = await CallLauncher.call(_digits);
    if (mounted) Navigator.pop(context);
    if (!success && mounted) {
      GlassToast.show(
        context,
        message: 'Could not place call.',
        type: GlassToastType.error,
        position: GlassToastPosition.bottom,
      );
    }
  }

  Contact? get _matchedContact {
    if (_digits.length < 3) return null;
    return ContactCache.findContact(number: _digits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final matched = _matchedContact;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // High opacity solid-frosted backdrop to prevent list content bleeding through
    final sheetBgColor = scheme.surface.withValues(alpha: isDark ? 0.95 : 0.97);

    // Dynamic sizing based on one-handed mode
    final double buttonSize = _oneHanded ? 46.0 : 54.0;
    final double callButtonSize = _oneHanded ? 48.0 : 56.0;
    final double digitFontSize = _oneHanded ? 18.0 : 21.0;
    final double lettersFontSize = _oneHanded ? 7.5 : 8.5;
    final double rowSpacing = _oneHanded ? 2.2 : 3.2;

    final Widget numpadCore = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Matched Contact Preview ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: matched != null ? 32 : 8,
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          child: matched != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (matched.photo != null) ...[
                        CircleAvatar(
                          radius: 8,
                          backgroundImage: MemoryImage(matched.photo!),
                        ),
                        const SizedBox(width: 5),
                      ] else ...[
                        Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          matched.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ── Digits Display ──
        SizedBox(
          height: _oneHanded ? 34 : 38,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _digits.isEmpty ? 'Enter a number' : _digits,
                style: TextStyle(
                  fontSize: _digits.isEmpty
                      ? (_oneHanded ? 16 : 18)
                      : (_oneHanded ? 22 : 26),
                  fontWeight:
                      _digits.isEmpty ? FontWeight.w400 : FontWeight.w700,
                  letterSpacing: _digits.isEmpty ? 0.3 : 1.5,
                  color: _digits.isEmpty
                      ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: _oneHanded ? 8 : 12),

        // ── Keypad Grid ──
        _KeypadGrid(
          buttonSize: buttonSize,
          digitFontSize: digitFontSize,
          lettersFontSize: lettersFontSize,
          verticalSpacing: rowSpacing,
          onDigit: _addDigit,
          onLongPressZero: () {
            HapticFeedback.mediumImpact();
            setState(() => _digits += '+');
          },
          scheme: scheme,
          isDark: isDark,
        ),
        SizedBox(height: _oneHanded ? 10 : 14),

        // ── Action Controls Bar ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Search in History
            SizedBox(
              width: _oneHanded ? 64 : 74,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _digits.isNotEmpty ? 1.0 : 0.4,
                child: GlassButton(
                  onTap: _digits.isEmpty
                      ? () {}
                      : () => Navigator.pop(context, _digits),
                  icon: Icon(Icons.search_rounded, size: _oneHanded ? 16 : 17),
                  label: 'Search',
                  quality: GlassQuality.standard,
                ),
              ),
            ),

            // Call Button (Prominent Floating Dial Button)
            GestureDetector(
              onTap: _digits.isEmpty ? null : _callDigits,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: callButtonSize,
                height: callButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _digits.isNotEmpty
                        ? [
                            const Color(0xFF34C759),
                            const Color(0xFF28A745),
                          ]
                        : [
                            scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          ],
                  ),
                  boxShadow: _digits.isNotEmpty
                      ? [
                          BoxShadow(
                            color: const Color(0xFF34C759).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: _digits.isNotEmpty
                        ? Colors.white.withValues(alpha: 0.3)
                        : scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.call_rounded,
                  color: _digits.isNotEmpty
                      ? Colors.white
                      : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: _oneHanded ? 22 : 25,
                ),
              ),
            ),

            // Backspace Button (Tap = delete 1, Long-press = clear all)
            SizedBox(
              width: _oneHanded ? 64 : 74,
              child: Center(
                child: _digits.isNotEmpty
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _backspace,
                          onLongPress: _clearAll,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.backspace_outlined,
                              size: _oneHanded ? 20 : 22,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(height: _oneHanded ? 40 : 44),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Header Row with Drag Pill & Top Right One-Hand Mode Button ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Spacer for balanced alignment
                  const SizedBox(width: 50, height: 28),

                  // Drag Pill
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Top Right: One-Hand Mode Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleOneHanded,
                      borderRadius: BorderRadius.circular(16),
                      child: Tooltip(
                        message: _oneHanded
                            ? 'Switch to Full Mode'
                            : 'Switch to One-Hand Mode',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _oneHanded
                                ? scheme.primary.withValues(alpha: 0.16)
                                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _oneHanded
                                  ? scheme.primary.withValues(alpha: 0.5)
                                  : scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _oneHanded
                                    ? Icons.fullscreen_rounded
                                    : Icons.pan_tool_alt_rounded,
                                size: 14,
                                color: _oneHanded
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _oneHanded ? 'Full' : '1-Hand',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _oneHanded
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── One-Handed vs Full Mode Layout ──
              if (_oneHanded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // If aligned to right: Side controls on Left
                    if (_alignRight) ...[
                      _SideControlBar(
                        onFlipSide: _toggleAlignment,
                        onExpand: _toggleOneHanded,
                        flipIcon: Icons.chevron_left_rounded,
                        flipTooltip: 'Move to Left',
                        scheme: scheme,
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Compact Numpad
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: numpadCore,
                      ),
                    ),

                    // If aligned to left: Side controls on Right
                    if (!_alignRight) ...[
                      const SizedBox(width: 10),
                      _SideControlBar(
                        onFlipSide: _toggleAlignment,
                        onExpand: _toggleOneHanded,
                        flipIcon: Icons.chevron_right_rounded,
                        flipTooltip: 'Move to Right',
                        scheme: scheme,
                      ),
                    ],
                  ],
                )
              else
                numpadCore,
            ],
          ),
        ),
      ),
    );
  }
}

class _SideControlBar extends StatelessWidget {
  final VoidCallback onFlipSide;
  final VoidCallback onExpand;
  final IconData flipIcon;
  final String flipTooltip;
  final ColorScheme scheme;

  const _SideControlBar({
    required this.onFlipSide,
    required this.onExpand,
    required this.flipIcon,
    required this.flipTooltip,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(flipIcon, size: 24),
          color: scheme.onSurfaceVariant,
          tooltip: flipTooltip,
          onPressed: onFlipSide,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 12),
        IconButton(
          icon: const Icon(Icons.open_in_full_rounded, size: 18),
          color: scheme.onSurfaceVariant,
          tooltip: 'Full Screen',
          onPressed: onExpand,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _KeypadGrid extends StatelessWidget {
  final double buttonSize;
  final double digitFontSize;
  final double lettersFontSize;
  final double verticalSpacing;
  final void Function(String) onDigit;
  final VoidCallback onLongPressZero;
  final ColorScheme scheme;
  final bool isDark;

  const _KeypadGrid({
    required this.buttonSize,
    required this.digitFontSize,
    required this.lettersFontSize,
    required this.verticalSpacing,
    required this.onDigit,
    required this.onLongPressZero,
    required this.scheme,
    required this.isDark,
  });

  static const List<List<({String digit, String letters})>> _layout = [
    [
      (digit: '1', letters: ''),
      (digit: '2', letters: 'ABC'),
      (digit: '3', letters: 'DEF'),
    ],
    [
      (digit: '4', letters: 'GHI'),
      (digit: '5', letters: 'JKL'),
      (digit: '6', letters: 'MNO'),
    ],
    [
      (digit: '7', letters: 'PQRS'),
      (digit: '8', letters: 'TUV'),
      (digit: '9', letters: 'WXYZ'),
    ],
    [
      (digit: '*', letters: ''),
      (digit: '0', letters: '+'),
      (digit: '#', letters: ''),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _layout) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: verticalSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final item in row)
                  _DialKeyButton(
                    digit: item.digit,
                    letters: item.letters,
                    size: buttonSize,
                    digitFontSize: digitFontSize,
                    lettersFontSize: lettersFontSize,
                    onTap: () => onDigit(item.digit),
                    onLongPress: item.digit == '0' ? onLongPressZero : null,
                    scheme: scheme,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DialKeyButton extends StatelessWidget {
  final String digit;
  final String letters;
  final double size;
  final double digitFontSize;
  final double lettersFontSize;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ColorScheme scheme;
  final bool isDark;

  const _DialKeyButton({
    required this.digit,
    required this.letters,
    required this.size,
    required this.digitFontSize,
    required this.lettersFontSize,
    required this.onTap,
    this.onLongPress,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: scheme.primary.withValues(alpha: 0.18),
        highlightColor: scheme.primary.withValues(alpha: 0.1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? scheme.surfaceContainerHigh.withValues(alpha: 0.88)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.92),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontSize: (digit == '*' || digit == '#')
                      ? digitFontSize + 2
                      : digitFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                  color: scheme.onSurface,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    fontSize: lettersFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    height: 1.05,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
