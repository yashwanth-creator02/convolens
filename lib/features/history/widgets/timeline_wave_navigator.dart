import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/year_index.dart';

enum WaveLevel { year, month, date }

class TimelineWaveNavigator extends StatefulWidget {
  final List<YearIndexEntry> yearIndex;
  final List<Object> items;
  final void Function(int itemIndex) onCommit;

  const TimelineWaveNavigator({
    super.key,
    required this.items,
    required this.yearIndex,
    required this.onCommit,
  });

  @override
  State<TimelineWaveNavigator> createState() => _TimelineWaveNavigatorState();
}

class _TimelineWaveNavigatorState extends State<TimelineWaveNavigator>
    with SingleTickerProviderStateMixin {
  static const double _activationZoneWidth = 52;
  static const double _abortThreshold = 12.0;
  static const double _yearMaxDepth = 60.0;
  static const double _monthMaxDepth = 130.0;
  static const double _baseAmplitude = 56.0;
  static const double _spread = 90.0;
  static const double _smoothingSpeed = 16.0;

  final ValueNotifier<_WaveState> _state = ValueNotifier(const _WaveState());

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  double _startDx = 0;
  double _currentDx = 0;
  double _targetY = 0;
  double _availableHeight = 0;

  int? _frozenYear;
  int? _frozenMonth;
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

    final current = _state.value;
    final t = 1 - exp(-_smoothingSpeed * dt);
    final newDisplayY = current.displayY + (_targetY - current.displayY) * t;

    _updateWaveState(newDisplayY, _currentDx);
  }

  void _updateWaveState(double displayY, double currentDx) {
    final pullDepth = (_startDx - currentDx).clamp(0.0, double.infinity);

    WaveLevel targetLevel;
    if (pullDepth < _yearMaxDepth) {
      targetLevel = WaveLevel.year;
    } else if (pullDepth < _monthMaxDepth) {
      targetLevel = WaveLevel.month;
    } else {
      targetLevel = WaveLevel.date;
    }

    if (targetLevel == WaveLevel.year) {
      _frozenYear = null;
      _frozenMonth = null;
      _cachedMonthIndex = const [];
      _cachedDateIndex = const [];
    } else if (targetLevel == WaveLevel.month) {
      _frozenMonth = null;
      _cachedDateIndex = const [];

      if (_frozenYear == null) {
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
      }
    } else if (targetLevel == WaveLevel.date) {
      if (_frozenYear == null) {
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
          final monthIdx = _nearestIndexFor(displayY, _cachedMonthIndex.length);
          if (monthIdx != null &&
              monthIdx >= 0 &&
              monthIdx < _cachedMonthIndex.length) {
            _frozenMonth = _cachedMonthIndex[monthIdx].month;
          }
        }

        if (_frozenMonth != null) {
          if (_cachedDateIndex.isEmpty) {
            _cachedDateIndex = buildDateIndex(
              widget.items,
              _frozenYear!,
              _frozenMonth!,
            );
          }
        }
      }
    }

    int? selectedIndex;
    switch (targetLevel) {
      case WaveLevel.year:
        selectedIndex = _nearestIndexFor(displayY, widget.yearIndex.length);
        break;
      case WaveLevel.month:
        selectedIndex = _nearestIndexFor(displayY, _cachedMonthIndex.length);
        break;
      case WaveLevel.date:
        selectedIndex = _nearestIndexFor(displayY, _cachedDateIndex.length);
        break;
    }

    _state.value = _WaveState(
      active: true,
      displayY: displayY,
      pullDepth: pullDepth,
      level: targetLevel,
      selectedIndex: selectedIndex,
      frozenYear: _frozenYear,
      frozenMonth: _frozenMonth,
      years: widget.yearIndex,
      months: _cachedMonthIndex,
      dates: _cachedDateIndex,
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
    _frozenYear = null;
    _frozenMonth = null;
    _cachedMonthIndex = const [];
    _cachedDateIndex = const [];

    _updateWaveState(details.localPosition.dy, details.localPosition.dx);
    _ticker.start();
  }

  void _onPanUpdate(DragUpdateDetails details, double availableHeight) {
    _availableHeight = availableHeight;
    _currentDx = details.localPosition.dx;
    _targetY = details.localPosition.dy;
  }

  void _endDrag() {
    _ticker.stop();
    final currentState = _state.value;
    _state.value = const _WaveState();

    if (currentState.pullDepth < _abortThreshold) {
      return;
    }

    int? itemIndexToCommit;
    switch (currentState.level) {
      case WaveLevel.year:
        if (currentState.selectedIndex != null &&
            currentState.selectedIndex! >= 0 &&
            currentState.selectedIndex! < currentState.years.length) {
          itemIndexToCommit =
              currentState.years[currentState.selectedIndex!].itemIndex;
        }
        break;
      case WaveLevel.month:
        if (currentState.selectedIndex != null &&
            currentState.selectedIndex! >= 0 &&
            currentState.selectedIndex! < currentState.months.length) {
          itemIndexToCommit =
              currentState.months[currentState.selectedIndex!].itemIndex;
        }
        break;
      case WaveLevel.date:
        if (currentState.selectedIndex != null &&
            currentState.selectedIndex! >= 0 &&
            currentState.selectedIndex! < currentState.dates.length) {
          itemIndexToCommit =
              currentState.dates[currentState.selectedIndex!].itemIndex;
        }
        break;
    }

    if (itemIndexToCommit != null) {
      widget.onCommit(itemIndexToCommit);
    }
  }

  void _cancelDrag() {
    _ticker.stop();
    _state.value = const _WaveState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return SizedBox(
          width: 220,
          height: height,
          child: Stack(
            children: [
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
              RepaintBoundary(
                child: ValueListenableBuilder<_WaveState>(
                  valueListenable: _state,
                  builder: (context, state, _) {
                    return IgnorePointer(
                      child: CustomPaint(
                        size: Size(220, height),
                        painter: _WavePainter(
                          state: state,
                          baseAmplitude: _baseAmplitude,
                          spread: _spread,
                          availableHeight: height,
                          color: Theme.of(context).colorScheme.primary,
                          abortThreshold: _abortThreshold,
                          yearMaxDepth: _yearMaxDepth,
                          monthMaxDepth: _monthMaxDepth,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveState {
  final bool active;
  final double displayY;
  final double pullDepth;
  final WaveLevel level;
  final int? selectedIndex;
  final int? frozenYear;
  final int? frozenMonth;
  final List<YearIndexEntry> years;
  final List<MonthIndexEntry> months;
  final List<DateIndexEntry> dates;

  const _WaveState({
    this.active = false,
    this.displayY = 0,
    this.pullDepth = 0,
    this.level = WaveLevel.year,
    this.selectedIndex,
    this.frozenYear,
    this.frozenMonth,
    this.years = const [],
    this.months = const [],
    this.dates = const [],
  });
}

class _WavePainter extends CustomPainter {
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
  final double baseAmplitude;
  final double spread;
  final double availableHeight;
  final Color color;
  final double abortThreshold;
  final double yearMaxDepth;
  final double monthMaxDepth;

  _WavePainter({
    required this.state,
    required this.baseAmplitude,
    required this.spread,
    required this.availableHeight,
    required this.color,
    required this.abortThreshold,
    required this.yearMaxDepth,
    required this.monthMaxDepth,
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
    final abortProgress = (pullDepth / abortThreshold).clamp(0.0, 1.0);
    if (abortProgress <= 0) return;

    final monthBlend = ((pullDepth - (yearMaxDepth - 10)) / 20.0).clamp(
      0.0,
      1.0,
    );
    final dateBlend = ((pullDepth - (monthMaxDepth - 10)) / 20.0).clamp(
      0.0,
      1.0,
    );

    final yearOpacity = (1.0 - monthBlend) * abortProgress;
    final monthOpacity = monthBlend * (1.0 - dateBlend) * abortProgress;
    final dateOpacity = dateBlend * abortProgress;

    final amplitude =
        (baseAmplitude + (pullDepth - abortThreshold) * 0.35).clamp(
          0.0,
          size.width - 40,
        ) *
        abortProgress;

    if (yearOpacity > 0 && state.years.isNotEmpty) {
      _paintLabels<YearIndexEntry>(
        canvas,
        size,
        items: state.years,
        labelText: (e) => '${e.year}',
        selectedIndex: state.level == WaveLevel.year
            ? state.selectedIndex
            : null,
        levelOpacity: yearOpacity,
        amplitude: amplitude,
      );
    }

    if (monthOpacity > 0 && state.months.isNotEmpty) {
      _paintLabels<MonthIndexEntry>(
        canvas,
        size,
        items: state.months,
        labelText: (e) => _formatMonth(e.month),
        selectedIndex: state.level == WaveLevel.month
            ? state.selectedIndex
            : null,
        levelOpacity: monthOpacity,
        amplitude: amplitude,
      );
    }

    if (dateOpacity > 0 && state.dates.isNotEmpty) {
      _paintLabels<DateIndexEntry>(
        canvas,
        size,
        items: state.dates,
        labelText: (e) => '${e.day}',
        selectedIndex: state.level == WaveLevel.date
            ? state.selectedIndex
            : null,
        levelOpacity: dateOpacity,
        amplitude: amplitude,
      );
    }

    _paintWaveLine(canvas, size, amplitude: amplitude, opacity: abortProgress);
  }

  void _paintLabels<T>(
    Canvas canvas,
    Size size, {
    required List<T> items,
    required String Function(T item) labelText,
    required int? selectedIndex,
    required double levelOpacity,
    required double amplitude,
  }) {
    final slot = availableHeight / items.length;
    final peakY = state.displayY;

    for (int i = 0; i < items.length; i++) {
      final labelY = slot * i + slot / 2;
      final isSelected = i == selectedIndex;

      final normalizedDistance = (labelY - peakY) / spread;
      final falloff = exp(-(normalizedDistance * normalizedDistance));
      final displacement = amplitude * falloff;

      final edgeX = size.width;
      final labelX = edgeX - displacement - 20;

      final itemOpacity =
          (isSelected ? 1.0 : (0.35 + 0.55 * falloff)) * levelOpacity;
      final scale = isSelected ? 1.15 : (0.85 + 0.2 * falloff);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText(items[i]),
          style: TextStyle(
            color: color.withValues(alpha: itemOpacity.clamp(0.0, 1.0)),
            fontSize: 14 * scale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width, labelY - textPainter.height / 2),
      );

      if (isSelected && levelOpacity > 0.4) {
        canvas.drawCircle(
          Offset(labelX + 8, labelY),
          4,
          Paint()
            ..color = color.withValues(alpha: levelOpacity.clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _paintWaveLine(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double opacity,
  }) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: (0.3 * opacity).clamp(0.0, 1.0))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final peakY = state.displayY;
    final path = Path();
    const steps = 60;
    final dy = availableHeight / steps;

    for (int i = 0; i <= steps; i++) {
      final labelY = dy * i;
      final normalizedDistance = (labelY - peakY) / spread;
      final x =
          size.width -
          amplitude * exp(-(normalizedDistance * normalizedDistance));

      if (i == 0) {
        path.moveTo(x, labelY);
      } else {
        path.lineTo(x, labelY);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
