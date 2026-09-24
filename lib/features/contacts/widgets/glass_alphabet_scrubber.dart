import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassAlphabetScrubber extends StatefulWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterSelected;

  const GlassAlphabetScrubber({
    super.key,
    required this.letters,
    required this.onLetterSelected,
  });

  @override
  State<GlassAlphabetScrubber> createState() => _GlassAlphabetScrubberState();
}

class _GlassAlphabetScrubberState extends State<GlassAlphabetScrubber> {
  final GlobalKey _columnKey = GlobalKey();

  String? _activeLetter;
  double _activeY = 0;
  bool _isInteracting = false;
  double? _touchStartX;
  bool _hasScrolledForCurrentTouch = false;
  Timer? _dismissTimer;

  static const double _columnWidth = 26.0;
  static const double _maxBulge = 32.0;
  static const double _letterHeight = 18.0;

  void _handlePointerDown(Offset globalPos) {
    _dismissTimer?.cancel();
    _touchStartX = globalPos.dx;
    _hasScrolledForCurrentTouch = false;

    setState(() {
      _isInteracting = true;
    });
    _handleTouch(globalPos, commitScroll: false);
  }

  void _handlePointerMove(Offset globalPos) {
    _dismissTimer?.cancel();
    if (!_isInteracting) {
      setState(() {
        _isInteracting = true;
      });
    }

    // Detect if finger "moves in" (slides inward to the left towards list by > 12px)
    bool movedIn = false;
    if (_touchStartX != null && (_touchStartX! - globalPos.dx) > 12.0) {
      movedIn = true;
    }

    _handleTouch(globalPos, commitScroll: movedIn);
  }

  void _handlePointerUp() {
    // "when i leave the strip": commit scroll on finger release
    if (!_hasScrolledForCurrentTouch && _activeLetter != null) {
      _hasScrolledForCurrentTouch = true;
      widget.onLetterSelected(_activeLetter!);
    }

    // Keep wave and bubble briefly visible on release so it gracefully blooms and dissolves
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _isInteracting = false;
          _activeLetter = null;
          _touchStartX = null;
        });
      }
    });
  }

  void _handleTouch(Offset globalPos, {required bool commitScroll}) {
    if (widget.letters.isEmpty) return;

    final renderBox =
        _columnKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final height = renderBox.size.height;
    if (height <= 0) return;

    final localPos = renderBox.globalToLocal(globalPos);
    final clampedY = localPos.dy.clamp(0.0, height - 0.1);
    final step = height / widget.letters.length;
    final index = (clampedY / step).floor().clamp(0, widget.letters.length - 1);
    final letter = widget.letters[index];

    // Center wave exactly on the touched letter's center for pixel-perfect alignment
    final letterCenterY = (index + 0.5) * step;

    final isNewLetter = _activeLetter != letter;

    setState(() {
      _activeLetter = letter;
      _activeY = letterCenterY;
    });

    if (isNewLetter) {
      HapticFeedback.selectionClick();
    }

    if (commitScroll && !_hasScrolledForCurrentTouch) {
      _hasScrolledForCurrentTouch = true;
      widget.onLetterSelected(letter);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final totalLettersHeight = widget.letters.length * _letterHeight;
    final waveSpread = _letterHeight * 3.2;

    // Expanded strip with comfortable letter spacing (22px per letter).
    // Hit area strictly matches 26px width x totalLettersHeight.
    return SizedBox(
      width: _columnWidth,
      height: totalLettersHeight,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _handlePointerDown(event.position),
        onPointerMove: (event) => _handlePointerMove(event.position),
        onPointerUp: (_) => _handlePointerUp(),
        onPointerCancel: (_) => _handlePointerUp(),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            // Dynamic fluid wave crest - ONLY appears when interacting around the touch point.
            // Completely OPEN: no outline border, no tall bounding pill capsule.
            if (_isInteracting)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: CustomPaint(
                  size: Size(_columnWidth + _maxBulge, totalLettersHeight),
                  painter: _OpenWavePainter(
                    touchY: _activeY,
                    isInteracting: _isInteracting,
                    waveSpread: waveSpread,
                    maxBulge: _maxBulge,
                    fillColor: scheme.primary.withValues(alpha: 0.14),
                  ),
                ),
              ),

            // Open Letters column with expanded vertical spacing (22px) and fluid wave displacement
            Container(
              key: _columnKey,
              width: _columnWidth,
              height: totalLettersHeight,
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.letters.length, (i) {
                  final letter = widget.letters[i];
                  final isCurrent = _activeLetter == letter;

                  double bulge = 0.0;
                  double scale = 1.0;

                  if (_isInteracting) {
                    final letterCenterY = (i + 0.5) * _letterHeight;
                    final dist = (letterCenterY - _activeY).abs();
                    if (dist < waveSpread) {
                      final factor = cos((dist / waveSpread) * (pi / 2));
                      final factorSq = factor * factor;
                      bulge = factorSq * _maxBulge;
                      scale = 1.0 + (factorSq * 0.65);
                    }
                  }

                  return Transform.translate(
                    offset: Offset(-bulge, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: _columnWidth,
                        height: _letterHeight,
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: isCurrent ? 11 : 9,
                              fontWeight: isCurrent
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isCurrent
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant
                                      .withValues(alpha: _isInteracting ? 0.95 : 0.75),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Floating Magnifier Bubble Callout centered vertically with active letter
            if (_isInteracting && _activeLetter != null)
              Positioned(
                right: _columnWidth + _maxBulge + 8,
                top: (_activeY - 26).clamp(0.0, totalLettersHeight - 52),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _activeLetter!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic fluid wave crest: paints an open organic wave along the right edge
/// ONLY around the active finger position. Never binds or encloses the strip
/// in an outline border or full-length capsule.
class _OpenWavePainter extends CustomPainter {
  final double touchY;
  final bool isInteracting;
  final double waveSpread;
  final double maxBulge;
  final Color fillColor;

  _OpenWavePainter({
    required this.touchY,
    required this.isInteracting,
    required this.waveSpread,
    required this.maxBulge,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isInteracting) return;

    final rightX = size.width;
    final topY = (touchY - waveSpread).clamp(0.0, size.height);
    final bottomY = (touchY + waveSpread).clamp(0.0, size.height);

    if (bottomY <= topY) return;

    final path = Path();
    path.moveTo(rightX, topY);

    // Sample cosine wave bulge curving smoothly outward to the left
    const int samples = 24;
    final dy = (bottomY - topY) / samples;

    for (int i = 0; i <= samples; i++) {
      final y = topY + (i * dy);
      final dist = (y - touchY).abs();
      double bulge = 0.0;
      if (dist < waveSpread) {
        final factor = cos((dist / waveSpread) * (pi / 2));
        bulge = factor * factor * maxBulge;
      }
      path.lineTo(rightX - bulge, y);
    }

    path.lineTo(rightX, bottomY);
    path.close();

    // Pure soft fill, completely open with NO stroke/outline border
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OpenWavePainter oldDelegate) {
    return oldDelegate.touchY != touchY ||
        oldDelegate.isInteracting != isInteracting ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.maxBulge != maxBulge ||
        oldDelegate.waveSpread != waveSpread;
  }
}
