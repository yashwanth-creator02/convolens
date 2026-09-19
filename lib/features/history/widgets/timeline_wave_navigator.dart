import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../utils/year_index.dart';

enum WaveLevel {
  year,
  month,
  date,
}

enum WaveNavState {
  idle,
  materializing,
  abortZone,
  yearActive,
  monthExpanding,
  monthActive,
  dateExpanding,
  dateActive,
  triggerReady,
  triggered,
  retracting,
}

class WaveStyle {
  final Color waveColor;
  final Color textColor;
  final Color highlightColor;
  final double strokeWidth;

  const WaveStyle({
    required this.waveColor,
    required this.textColor,
    required this.highlightColor,
    required this.strokeWidth,
  });
}

class TimelineWaveTheme {
  final WaveStyle yearStyle;
  final WaveStyle monthStyle;
  final WaveStyle dateStyle;
  final Color abortColor;

  const TimelineWaveTheme({
    required this.yearStyle,
    required this.monthStyle,
    required this.dateStyle,
    required this.abortColor,
  });

  factory TimelineWaveTheme.defaultTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TimelineWaveTheme(
      yearStyle: WaveStyle(
        waveColor: const Color(0xFF38BDF8), // Electric Sky Blue
        textColor: isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0369A1),
        highlightColor: const Color(0xFF0284C7),
        strokeWidth: 2.2,
      ),
      monthStyle: WaveStyle(
        waveColor: const Color(0xFF2DD4BF), // Mint Teal
        textColor: isDark ? const Color(0xFFCCFBF1) : const Color(0xFF0F766E),
        highlightColor: const Color(0xFF0D9488),
        strokeWidth: 2.4,
      ),
      dateStyle: WaveStyle(
        waveColor: const Color(0xFFFB7185), // Coral Rose
        textColor: isDark ? const Color(0xFFFFF1F2) : const Color(0xFFBE123C),
        highlightColor: const Color(0xFFE11D48),
        strokeWidth: 2.8,
      ),
      abortColor: const Color(0xFF94A3B8), // Cool Slate
    );
  }
}

class TimelineWaveNavigator extends StatefulWidget {
  final List<YearIndexEntry> yearIndex;
  final List<Object> items;
  final void Function(int itemIndex) onCommit;
  final TimelineWaveTheme? theme;

  const TimelineWaveNavigator({
    super.key,
    required this.items,
    required this.yearIndex,
    required this.onCommit,
    this.theme,
  });

  @override
  State<TimelineWaveNavigator> createState() => _TimelineWaveNavigatorState();
}

class _TimelineWaveNavigatorState extends State<TimelineWaveNavigator>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Geometry Thresholds
  // ---------------------------------------------------------------------------
  // Width of the touch activation area along the screen's right edge
  static const double _activationZoneWidth = 48.0;

  // Horizontal depth thresholds (distance pulled inward from the right bezel)
  static const double _abortThreshold = 36.0; // < 36px is the abort/cancel zone
  static const double _yearDepthMax = 95.0; // 36..95px: Year selection
  static const double _monthDepthMax = 160.0; // 95..160px: Month selection
  static const double _dateDepthMax = 220.0; // 160..220px: Date selection
  static const double _triggerDepth = 220.0; // >= 220px: Trigger scrolling instant!

  static const double _spread = 115.0; // Gaussian curve vertical spread
  static const double _smoothingSpeed = 22.0;

  final ValueNotifier<_WaveState> _state = ValueNotifier(const _WaveState());

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  double _startDx = 0;
  double _currentDx = 0;
  double _targetY = 0;
  double _availableHeight = 0;
  bool _isRetracting = false;
  double _retractionProgress = 1.0;
  bool _hasTriggered = false;

  int? _frozenYear;
  int? _frozenMonth;
  int? _lastHapticItem;
  WaveLevel _lastHapticLevel = WaveLevel.year;

  List<MonthIndexEntry> _cachedMonthIndex = const [];
  List<DateIndexEntry> _cachedDateIndex = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _state.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    if (_isRetracting) {
      _retractionProgress -= dt * 5.0;
      if (_retractionProgress <= 0) {
        _isRetracting = false;
        _ticker.stop();
        _state.value = const _WaveState();
        return;
      }
    }

    final current = _state.value;
    final t = 1.0 - exp(-_smoothingSpeed * dt);
    final displayY = current.displayY + (_targetY - current.displayY) * t;

    _updateWaveState(displayY, _currentDx, elapsed.inMilliseconds / 1000.0);
  }

  void _updateWaveState(
    double displayY,
    double currentDx,
    double timeSeconds,
  ) {
    if (_availableHeight <= 0) return;

    // Pull depth: distance finger has traveled inward from start touch (towards middle)
    double rawPullDepth = (_startDx - currentDx).clamp(0.0, 320.0);
    if (_isRetracting) {
      rawPullDepth *= _retractionProgress;
    }

    WaveLevel targetLevel;
    WaveNavState navState;

    if (rawPullDepth < _abortThreshold) {
      targetLevel = WaveLevel.year;
      navState = _isRetracting
          ? WaveNavState.retracting
          : WaveNavState.abortZone;
    } else if (rawPullDepth < _yearDepthMax) {
      targetLevel = WaveLevel.year;
      navState = WaveNavState.yearActive;
    } else if (rawPullDepth < _monthDepthMax) {
      targetLevel = WaveLevel.month;
      navState = (rawPullDepth - _yearDepthMax) < 16.0
          ? WaveNavState.monthExpanding
          : WaveNavState.monthActive;
    } else if (rawPullDepth < _dateDepthMax) {
      targetLevel = WaveLevel.date;
      navState = (rawPullDepth - _monthDepthMax) < 16.0
          ? WaveNavState.dateExpanding
          : WaveNavState.dateActive;
    } else {
      targetLevel = WaveLevel.date;
      navState = WaveNavState.triggerReady;
    }

    if (_isRetracting) {
      navState = WaveNavState.retracting;
    }

    // Level state hierarchy and freezing
    if (targetLevel == WaveLevel.year) {
      _frozenYear = null;
      _frozenMonth = null;
      _cachedMonthIndex = const [];
      _cachedDateIndex = const [];
    } else if (targetLevel == WaveLevel.month) {
      _frozenMonth = null;
      _cachedDateIndex = const [];

      if (_frozenYear == null && widget.yearIndex.isNotEmpty) {
        final yearIdx = _nearestIndexFor(displayY, widget.yearIndex.length);
        if (yearIdx != null &&
            yearIdx >= 0 &&
            yearIdx < widget.yearIndex.length) {
          _frozenYear = widget.yearIndex[yearIdx].year;
        }
      }

      if (_frozenYear != null && _cachedMonthIndex.isEmpty) {
        _cachedMonthIndex = buildMonthIndex(widget.items, _frozenYear!);
      }
    } else if (targetLevel == WaveLevel.date) {
      if (_frozenYear == null && widget.yearIndex.isNotEmpty) {
        final yearIdx = _nearestIndexFor(displayY, widget.yearIndex.length);
        if (yearIdx != null &&
            yearIdx >= 0 &&
            yearIdx < widget.yearIndex.length) {
          _frozenYear = widget.yearIndex[yearIdx].year;
        }
      }

      if (_frozenYear != null) {
        if (_cachedMonthIndex.isEmpty) {
          _cachedMonthIndex = buildMonthIndex(widget.items, _frozenYear!);
        }

        if (_frozenMonth == null && _cachedMonthIndex.isNotEmpty) {
          final monthIdx =
              _nearestIndexFor(displayY, _cachedMonthIndex.length);
          if (monthIdx != null &&
              monthIdx >= 0 &&
              monthIdx < _cachedMonthIndex.length) {
            _frozenMonth = _cachedMonthIndex[monthIdx].month;
          }
        }

        if (_frozenMonth != null && _cachedDateIndex.isEmpty) {
          _cachedDateIndex =
              buildDateIndex(widget.items, _frozenYear!, _frozenMonth!);
        }
      }
    }

    // Active selected item for pop-out
    int? selectedIndex;
    int? currentHapticVal;

    switch (targetLevel) {
      case WaveLevel.year:
        selectedIndex = _nearestIndexFor(displayY, widget.yearIndex.length);
        if (selectedIndex != null && selectedIndex < widget.yearIndex.length) {
          currentHapticVal = widget.yearIndex[selectedIndex].year;
        }
        break;
      case WaveLevel.month:
        selectedIndex = _nearestIndexFor(displayY, _cachedMonthIndex.length);
        if (selectedIndex != null && selectedIndex < _cachedMonthIndex.length) {
          currentHapticVal = _cachedMonthIndex[selectedIndex].month;
        }
        break;
      case WaveLevel.date:
        selectedIndex = _nearestIndexFor(displayY, _cachedDateIndex.length);
        if (selectedIndex != null && selectedIndex < _cachedDateIndex.length) {
          currentHapticVal = _cachedDateIndex[selectedIndex].day;
        }
        break;
    }

    // Haptic feedback on value or level shift
    if (navState != WaveNavState.abortZone && !_isRetracting) {
      if (targetLevel != _lastHapticLevel) {
        _lastHapticLevel = targetLevel;
        HapticFeedback.lightImpact();
      } else if (currentHapticVal != null && currentHapticVal != _lastHapticItem) {
        _lastHapticItem = currentHapticVal;
        HapticFeedback.selectionClick();
      }
    }

    // Inching closer trigger check
    if (navState == WaveNavState.triggerReady && !_hasTriggered && !_isRetracting) {
      _hasTriggered = true;
      HapticFeedback.mediumImpact();
      _commitSelection(targetLevel, selectedIndex);
      _startRetraction();
      return;
    }

    _state.value = _WaveState(
      active: true,
      displayY: displayY,
      pullDepth: rawPullDepth,
      level: targetLevel,
      navState: navState,
      selectedIndex: selectedIndex,
      frozenYear: _frozenYear,
      frozenMonth: _frozenMonth,
      years: widget.yearIndex,
      months: _cachedMonthIndex,
      dates: _cachedDateIndex,
      timeSeconds: timeSeconds,
    );
  }

  int? _nearestIndexFor(double y, int count) {
    if (count <= 0 || _availableHeight <= 0) return null;
    final slot = _availableHeight / count;
    return (y / slot).floor().clamp(0, count - 1);
  }

  void _onPanStart(DragStartDetails details, double availableHeight) {
    _availableHeight = availableHeight;
    _startDx = details.localPosition.dx;
    _currentDx = details.localPosition.dx;
    _targetY = details.localPosition.dy;
    _lastElapsed = Duration.zero;
    _isRetracting = false;
    _retractionProgress = 1.0;
    _hasTriggered = false;
    _frozenYear = null;
    _frozenMonth = null;
    _lastHapticItem = null;
    _cachedMonthIndex = const [];
    _cachedDateIndex = const [];

    HapticFeedback.selectionClick();
    _updateWaveState(details.localPosition.dy, details.localPosition.dx, 0.0);
    _ticker.start();
  }

  void _onPanUpdate(DragUpdateDetails details, double availableHeight) {
    _availableHeight = availableHeight;
    _currentDx = details.localPosition.dx;
    _targetY = details.localPosition.dy;
  }

  void _startRetraction() {
    _isRetracting = true;
    _retractionProgress = 1.0;
  }

  void _endDrag() {
    final currentState = _state.value;

    // Abort if released in the abort zone (near screen edge)
    if (currentState.pullDepth < _abortThreshold) {
      _startRetraction();
      return;
    }

    // If released past the date depth or in commit zone, trigger scrolling jump
    if (!_hasTriggered && currentState.pullDepth >= _yearDepthMax) {
      _commitSelection(currentState.level, currentState.selectedIndex);
      HapticFeedback.mediumImpact();
    }

    _startRetraction();
  }

  void _commitSelection(WaveLevel level, int? selectedIndex) {
    final currentState = _state.value;
    int? itemIndexToCommit;

    switch (level) {
      case WaveLevel.year:
        if (selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < currentState.years.length) {
          itemIndexToCommit = currentState.years[selectedIndex].itemIndex;
        }
        break;
      case WaveLevel.month:
        if (selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < currentState.months.length) {
          itemIndexToCommit = currentState.months[selectedIndex].itemIndex;
        }
        break;
      case WaveLevel.date:
        if (selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < currentState.dates.length) {
          itemIndexToCommit = currentState.dates[selectedIndex].itemIndex;
        }
        break;
    }

    if (itemIndexToCommit != null) {
      widget.onCommit(itemIndexToCommit);
    }
  }

  void _cancelDrag() {
    _startRetraction();
  }

  @override
  Widget build(BuildContext context) {
    final waveTheme = widget.theme ?? TimelineWaveTheme.defaultTheme(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return SizedBox(
          width: 320,
          height: height,
          child: Stack(
            children: [
              // Wave Painter Layer
              RepaintBoundary(
                child: ValueListenableBuilder<_WaveState>(
                  valueListenable: _state,
                  builder: (context, state, _) {
                    return CustomPaint(
                      size: Size(320, height),
                      painter: _LiquidWavePainter(
                        state: state,
                        theme: waveTheme,
                        spread: _spread,
                        availableHeight: height,
                        abortThreshold: _abortThreshold,
                        yearDepthMax: _yearDepthMax,
                        monthDepthMax: _monthDepthMax,
                        triggerDepth: _triggerDepth,
                      ),
                    );
                  },
                ),
              ),

              // Right-edge Touch Activation Detector
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: _activationZoneWidth,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (d) => _onPanStart(d, height),
                  onPanUpdate: (d) => _onPanUpdate(d, height),
                  onPanEnd: (_) => _endDrag(),
                  onPanCancel: _cancelDrag,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// State Model
// -----------------------------------------------------------------------------
class _WaveState {
  final bool active;
  final double displayY;
  final double pullDepth;
  final WaveLevel level;
  final WaveNavState navState;
  final int? selectedIndex;
  final int? frozenYear;
  final int? frozenMonth;
  final List<YearIndexEntry> years;
  final List<MonthIndexEntry> months;
  final List<DateIndexEntry> dates;
  final double timeSeconds;

  const _WaveState({
    this.active = false,
    this.displayY = 0,
    this.pullDepth = 0,
    this.level = WaveLevel.year,
    this.navState = WaveNavState.idle,
    this.selectedIndex,
    this.frozenYear,
    this.frozenMonth,
    this.years = const [],
    this.months = const [],
    this.dates = const [],
    this.timeSeconds = 0,
  });
}

// -----------------------------------------------------------------------------
// Custom Liquid Wave Painter
// -----------------------------------------------------------------------------
class _LiquidWavePainter extends CustomPainter {
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _WaveState state;
  final TimelineWaveTheme theme;
  final double spread;
  final double availableHeight;
  final double abortThreshold;
  final double yearDepthMax;
  final double monthDepthMax;
  final double triggerDepth;

  _LiquidWavePainter({
    required this.state,
    required this.theme,
    required this.spread,
    required this.availableHeight,
    required this.abortThreshold,
    required this.yearDepthMax,
    required this.monthDepthMax,
    required this.triggerDepth,
  });

  String _formatMonth(int month) {
    if (month >= 1 && month <= 12) {
      return _monthNames[month - 1];
    }
    return '$month';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!state.active) return;

    final pullDepth = state.pullDepth;
    final isAbort = state.navState == WaveNavState.abortZone;
    final isTriggered = state.navState == WaveNavState.triggerReady;

    // Amplitude calculation for waves rising from the right bezel (size.width)
    final yearAmp = (pullDepth * 0.75).clamp(12.0, 70.0);
    final monthProgress =
        ((pullDepth - yearDepthMax) / (monthDepthMax - yearDepthMax))
            .clamp(0.0, 1.0);
    final monthAmp = monthProgress * 55.0;

    final dateProgress =
        ((pullDepth - monthDepthMax) / (triggerDepth - monthDepthMax))
            .clamp(0.0, 1.0);
    final dateAmp = dateProgress * 55.0;

    final totalAmp = yearAmp + monthAmp + dateAmp;

    // Determine active wave styling
    WaveStyle activeStyle = theme.yearStyle;
    if (state.level == WaveLevel.month) activeStyle = theme.monthStyle;
    if (state.level == WaveLevel.date) activeStyle = theme.dateStyle;

    // 1. Draw Liquid Wave Body Rising from the Edge
    _drawLiquidWaveMesh(
      canvas,
      size,
      amplitude: totalAmp,
      peakY: state.displayY,
      style: isAbort ? WaveStyle(
        waveColor: theme.abortColor,
        textColor: Colors.white,
        highlightColor: theme.abortColor,
        strokeWidth: 2.0,
      ) : activeStyle,
      isTriggered: isTriggered,
    );

    // 2. Draw Subtle Year Indicators along the Edge Wave
    if (state.years.isNotEmpty && !isAbort) {
      _drawStageMarkers(canvas, size, baseAmp: yearAmp);
    }

    // 3. Draw Selected Item POPPING OUT of the Wave at the Peak
    _drawPoppingItemBadge(
      canvas,
      size,
      peakX: size.width - totalAmp,
      peakY: state.displayY,
      style: isAbort ? WaveStyle(
        waveColor: theme.abortColor,
        textColor: Colors.white,
        highlightColor: theme.abortColor,
        strokeWidth: 2.0,
      ) : activeStyle,
      isAbort: isAbort,
      isTriggered: isTriggered,
    );
  }

  void _drawLiquidWaveMesh(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double peakY,
    required WaveStyle style,
    required bool isTriggered,
  }) {
    const steps = 64;
    final dy = availableHeight / steps;

    final wavePath = Path();
    wavePath.moveTo(size.width, 0);

    for (int i = 0; i <= steps; i++) {
      final y = dy * i;
      final dist = (y - peakY) / spread;
      final bell = exp(-(dist * dist));
      final x = size.width - amplitude * bell;
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    // Fluid liquid gradient
    final Rect fillRect = Rect.fromLTWH(
      size.width - amplitude,
      0,
      amplitude,
      size.height,
    );

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          style.waveColor.withValues(alpha: isTriggered ? 0.35 : 0.12),
          style.waveColor.withValues(alpha: isTriggered ? 0.65 : 0.28),
        ],
      ).createShader(fillRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(wavePath, fillPaint);

    // Outer luminous crest curve
    final crestPath = Path();
    for (int i = 0; i <= steps; i++) {
      final y = dy * i;
      final dist = (y - peakY) / spread;
      final bell = exp(-(dist * dist));
      final x = size.width - amplitude * bell;

      if (i == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }

    final crestPaint = Paint()
      ..color = style.highlightColor.withValues(
        alpha: isTriggered ? 1.0 : 0.85,
      )
      ..strokeWidth = isTriggered ? style.strokeWidth + 1.2 : style.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(crestPath, crestPaint);
  }

  void _drawStageMarkers(
    Canvas canvas,
    Size size, {
    required double baseAmp,
  }) {
    if (state.level == WaveLevel.year) {
      final slot = availableHeight / state.years.length;
      for (int i = 0; i < state.years.length; i++) {
        final y = slot * i + slot / 2;
        final dist = (y - state.displayY).abs();
        if (dist > 30.0) {
          final bell = exp(-pow((y - state.displayY) / spread, 2));
          final x = size.width - (baseAmp * bell) - 10.0;
          final opacity = (0.35 + 0.35 * bell).clamp(0.0, 1.0);

          final tp = TextPainter(
            text: TextSpan(
              text: '${state.years[i].year}',
              style: TextStyle(
                color: theme.yearStyle.textColor.withValues(alpha: opacity),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
        }
      }
    }
  }

  void _drawPoppingItemBadge(
    Canvas canvas,
    Size size, {
    required double peakX,
    required double peakY,
    required WaveStyle style,
    required bool isAbort,
    required bool isTriggered,
  }) {
    String badgeText = '';
    String subText = '';

    if (isAbort) {
      badgeText = 'Release to Cancel';
      subText = 'Return to edge';
    } else if (isTriggered) {
      badgeText = 'Jumping!';
      subText = 'Release';
    } else {
      switch (state.level) {
        case WaveLevel.year:
          if (state.selectedIndex != null &&
              state.selectedIndex! < state.years.length) {
            badgeText = '${state.years[state.selectedIndex!].year}';
            subText = 'Pull left for Month';
          }
          break;
        case WaveLevel.month:
          if (state.selectedIndex != null &&
              state.selectedIndex! < state.months.length) {
            final m = state.months[state.selectedIndex!].month;
            badgeText = '${_formatMonth(m)} ${state.frozenYear ?? ''}';
            subText = 'Pull left for Day';
          }
          break;
        case WaveLevel.date:
          if (state.selectedIndex != null &&
              state.selectedIndex! < state.dates.length) {
            final d = state.dates[state.selectedIndex!].day;
            final m = state.frozenMonth ?? 1;
            badgeText = '$d ${_formatMonth(m)} ${state.frozenYear ?? ''}';
            subText = 'Pull left to jump';
          }
          break;
      }
    }

    if (badgeText.isEmpty) return;

    // Layout typography
    final titlePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final subPainter = TextPainter(
      text: TextSpan(
        text: subText,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 16.0;
    const paddingV = 8.0;
    final badgeWidth =
        max(titlePainter.width, subPainter.width) + paddingH * 2 + 14.0;
    final badgeHeight = titlePainter.height + subPainter.height + paddingV * 2 + 2.0;

    // Pop out position: elevated floating capsule projecting leftward from the crest peak
    final badgeCenterX = peakX - badgeWidth / 2 - 14.0;
    final badgeCenterY = peakY.clamp(
      badgeHeight / 2 + 16.0,
      availableHeight - badgeHeight / 2 - 16.0,
    );

    final badgeRect = Rect.fromCenter(
      center: Offset(badgeCenterX, badgeCenterY),
      width: badgeWidth,
      height: badgeHeight,
    );
    final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(16));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect.shift(const Offset(0, 4)), shadowPaint);

    // Glowing pop-out background
    final badgeBgPaint = Paint()
      ..color = isAbort
          ? const Color(0xFF475569)
          : isTriggered
              ? const Color(0xFF059669)
              : style.highlightColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, badgeBgPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(rrect, borderPaint);

    // Connecting liquid stem from wave crest to popped-out badge
    final stemPaint = Paint()
      ..color = style.highlightColor.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(peakX, peakY),
      Offset(badgeRect.right, badgeCenterY),
      stemPaint,
    );

    // Peak dot
    canvas.drawCircle(
      Offset(peakX, peakY),
      4.5,
      Paint()..color = Colors.white,
    );

    // Text layout inside the popped-out badge
    titlePainter.paint(
      canvas,
      Offset(
        badgeCenterX - titlePainter.width / 2 + 4.0,
        badgeCenterY - (titlePainter.height + subPainter.height) / 2,
      ),
    );

    subPainter.paint(
      canvas,
      Offset(
        badgeCenterX - subPainter.width / 2 + 4.0,
        badgeCenterY + (titlePainter.height - subPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
