import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/services/contact_cache.dart';
import '../../../core/utils/call_launcher.dart';

/// Opens the liquid glass number pad bottom sheet.
///
/// Returns the dialed number string if the user taps "Search", or null if dismissed.
Future<String?> showNumberPadSheet(BuildContext context) {
  return GlassSheet.show<String>(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: true,
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
    final matched = _matchedContact;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Matched Contact Preview (if dialing an existing contact) ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: matched != null ? 36 : 14,
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            child: matched != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            radius: 9,
                            backgroundImage: MemoryImage(matched.photo!),
                          ),
                          const SizedBox(width: 6),
                        ] else ...[
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            matched.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
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

          // ── Digits Display ──────────────────────────────────────────
          SizedBox(
            height: 44,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _digits.isEmpty ? 'Enter a number' : _digits,
                  style: TextStyle(
                    fontSize: _digits.isEmpty ? 20 : 30,
                    fontWeight: _digits.isEmpty ? FontWeight.w400 : FontWeight.w700,
                    letterSpacing: _digits.isEmpty ? 0.5 : 2.0,
                    color: _digits.isEmpty
                        ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Keypad Grid ──────────────────────────────────────────────
          _KeypadGrid(
            onDigit: _addDigit,
            onLongPressZero: () {
              HapticFeedback.mediumImpact();
              setState(() => _digits += '+');
            },
            scheme: scheme,
          ),
          const SizedBox(height: 18),

          // ── Action Controls Bar ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search in History
              SizedBox(
                width: 76,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _digits.isNotEmpty ? 1.0 : 0.4,
                  child: GlassButton(
                    onTap: _digits.isEmpty
                        ? () {}
                        : () => Navigator.pop(context, _digits),
                    icon: const Icon(Icons.search_rounded, size: 18),
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
                  width: 66,
                  height: 66,
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
                              scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            ],
                    ),
                    boxShadow: _digits.isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(0xFF34C759).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                    border: Border.all(
                      color: _digits.isNotEmpty
                          ? Colors.white.withValues(alpha: 0.25)
                          : scheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.call_rounded,
                    color: _digits.isNotEmpty
                        ? Colors.white
                        : scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    size: 28,
                  ),
                ),
              ),

              // Backspace Button (Tap = delete 1, Long-press = clear all)
              SizedBox(
                width: 76,
                child: Center(
                  child: _digits.isNotEmpty
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _backspace,
                            onLongPress: _clearAll,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.backspace_outlined,
                                size: 24,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadGrid extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onLongPressZero;
  final ColorScheme scheme;

  const _KeypadGrid({
    required this.onDigit,
    required this.onLongPressZero,
    required this.scheme,
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
            padding: const EdgeInsets.symmetric(vertical: 4.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final item in row)
                  _DialKeyButton(
                    digit: item.digit,
                    letters: item.letters,
                    onTap: () => onDigit(item.digit),
                    onLongPress:
                        item.digit == '0' ? onLongPressZero : null,
                    scheme: scheme,
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
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ColorScheme scheme;

  const _DialKeyButton({
    required this.digit,
    required this.letters,
    required this.onTap,
    this.onLongPress,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(32),
        splashColor: scheme.primary.withValues(alpha: 0.15),
        highlightColor: scheme.primary.withValues(alpha: 0.08),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontSize: digit == '*' || digit == '#' ? 26 : 24,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: scheme.onSurface,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    height: 1.1,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
