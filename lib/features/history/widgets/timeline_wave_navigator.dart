import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/date_index.dart';
import '../utils/month_index.dart';
import '../utils/year_index.dart';

/// Explicit state enum for the hierarchical wave navigator lifecycle.
enum WaveNavState {
  idle,
  appearing,
  yearActive,
  monthExpanding,
  monthActive,
  dateExpanding,
  dateActive,
  commitReady,
  committing,
  retracting,
}

/// Theme configuration for the wave navigator.
class TimelineWaveTheme {
  final Color yearColor;
  final Color monthColor;
  final Color dateColor;
  final Color commitGlowColor;
  final double baseYearFontSize;
  final double baseMonthFontSize;
  final double baseDateFontSize;

  const TimelineWaveTheme({
    required this.yearColor,
    required this.monthColor,
    required this.dateColor,
    required this.commitGlowColor,
    this.baseYearFontSize = 14.0,
    this.baseMonthFontSize = 12.0,
    this.baseDateFontSize = 11.0,
  });

  factory TimelineWaveTheme.fromContext(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TimelineWaveTheme(
      yearColor: scheme.primary,
      monthColor: scheme.secondary,
      dateColor: scheme.tertiary,
      commitGlowColor: scheme.primary,
    );
  }
}

class TimelineWaveNavigator extends StatefulWidget {
  final List<YearIndexEntry> yearIndex;
  final Map<int, List<MonthIndexEntry>> monthIndex;
  final Map<(int, int), List<DateIndexEntry>> dateIndex;
  final TimelineWaveTheme? theme;
  final void Function(int itemIndex) onCommit;

  const TimelineWaveNavigator({
    super.key,
    required this.yearIndex,
    this.monthIndex = const {},
    this.dateIndex = const {},
    this.theme,
    required this.onCommit,
  });

  @override
  State<TimelineWaveNavigator> createState() => _TimelineWaveNavigatorState();
}

class _TimelineWaveNavigatorState extends State<TimelineWaveNavigator>
    with SingleTickerProviderStateMixin {
  static const double _activationZoneWidth = 40.0;
  static const double _navigatorWidth = 220.0;
  static const double _amplitude = 36.0;
  static const double _spread = 85.0;

  // Depth zones (tunable)
  static const double _zoneYearOnly = 40.0;
  static const double _zoneMonth = 110.0;
  static const double _zoneDate = 180.0;
  static const double _zoneCommit = 180.0; // Crossing this triggers commitReady

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Targets set by pan gestures
  double _targetY = 0.0;
  double _targetDepthDx = 0.0;
  bool _isDragging = false;

  // Retraction animation state
  bool _isRetracting = false;
  double _retractProgress = 0.0; // 0.0 -> 1.0

  final ValueNotifier<_WaveState> _state = ValueNotifier(const _WaveState());

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

  void _startTickingIfNeeded() {
    if (!_ticker.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(
      0.001,
      0.05,
    );
    _lastElapsed = elapsed;

    final current = _state.value;

    // Retraction logic
    if (_isRetracting) {
      _retractProgress += dt * 5.0; // ~200ms retraction
      if (_retractProgress >= 1.0) {
        _isRetracting = false;
        _retractProgress = 0.0;
        _ticker.stop();
        _state.value = const _WaveState();
        return;
      }
    }

    final double retractScale = _isRetracting
        ? (1.0 - _retractProgress).clamp(0.0, 1.0)
        : 1.0;

    // Smooth interpolations towards targets
    final double newDisplayY =
        current.displayY + (_targetY - current.displayY) * (1 - exp(-20 * dt));
    final double newDepthDx =
        current.displayDepthDx +
        (_targetDepthDx - current.displayDepthDx) * (1 - exp(-20 * dt));

    // Calculate raw expansion targets based on depth
    final double targetMonthExp = _isDragging
        ? ((newDepthDx - _zoneYearOnly) / (_zoneMonth - _zoneYearOnly)).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    final double targetDateExp = _isDragging
        ? ((newDepthDx - _zoneMonth) / (_zoneDate - _zoneMonth)).clamp(0.0, 1.0)
        : 0.0;

    final double newMonthExp =
        current.displayMonthExpansion +
        (targetMonthExp - current.displayMonthExpansion) * (1 - exp(-16 * dt));

    final double newDateExp =
        current.displayDateExpansion +
        (targetDateExp - current.displayDateExpansion) * (1 - exp(-16 * dt));

    final double newPulsePhase = current.pulsePhase + dt * 5.0;

    // Determine current WaveNavState
    WaveNavState phase;
    if (_isRetracting) {
      phase = WaveNavState.retracting;
    } else if (!_isDragging) {
      phase = WaveNavState.idle;
    } else if (newDepthDx >= _zoneCommit) {
      phase = WaveNavState.commitReady;
    } else if (newDateExp > 0.8) {
      phase = WaveNavState.dateActive;
    } else if (newDateExp > 0.05) {
      phase = WaveNavState.dateExpanding;
    } else if (newMonthExp > 0.8) {
      phase = WaveNavState.monthActive;
    } else if (newMonthExp > 0.05) {
      phase = WaveNavState.monthExpanding;
    } else {
      phase = WaveNavState.yearActive;
    }

    // Resolve selection indices
    final double availableHeight = current.availableHeight;
    final int? yearIdx = _nearestYearIndexFor(newDisplayY, availableHeight);

    int? monthIdx;
    if (yearIdx != null &&
        yearIdx >= 0 &&
        yearIdx < widget.yearIndex.length &&
        newMonthExp > 0.02) {
      final year = widget.yearIndex[yearIdx].year;
      final months = widget.monthIndex[year] ?? [];
      if (months.isNotEmpty) {
        final yearY = _getYearLabelY(yearIdx, availableHeight);
        monthIdx = _nearestMonthIndexFor(
          newDisplayY,
          yearY,
          months.length,
          newMonthExp,
        );
      }
    }

    int? dateIdx;
    if (yearIdx != null &&
        monthIdx != null &&
        yearIdx >= 0 &&
        yearIdx < widget.yearIndex.length &&
        newDateExp > 0.02) {
      final year = widget.yearIndex[yearIdx].year;
      final months = widget.monthIndex[year] ?? [];
      if (monthIdx >= 0 && monthIdx < months.length) {
        final month = months[monthIdx].month;
        final dates = widget.dateIndex[(year, month)] ?? [];
        if (dates.isNotEmpty) {
          final yearY = _getYearLabelY(yearIdx, availableHeight);
          final monthY = _getMonthLabelY(
            monthIdx,
            months.length,
            yearY,
            newMonthExp,
          );
          dateIdx = _nearestDateIndexFor(
            newDisplayY,
            monthY,
            dates.length,
            newDateExp,
          );
        }
      }
    }

    _state.value = _WaveState(
      active: _isDragging || _isRetracting,
      phase: phase,
      displayY: newDisplayY,
      displayDepthDx: newDepthDx,
      displayMonthExpansion: newMonthExp,
      displayDateExpansion: newDateExp,
      selectedYearIndex: yearIdx,
      selectedMonthIndex: monthIdx,
      selectedDateIndex: dateIdx,
      availableHeight: availableHeight,
      retractScale: retractScale,
      pulsePhase: newPulsePhase,
    );
  }

  int? _nearestYearIndexFor(double fingerY, double height) {
    if (widget.yearIndex.isEmpty || height <= 0) return null;
    final slot = height / widget.yearIndex.length;
    return (fingerY / slot).floor().clamp(0, widget.yearIndex.length - 1);
  }

  double _getYearLabelY(int index, double height) {
    final slot = height / widget.yearIndex.length;
    return slot * index + slot / 2;
  }

  int _nearestMonthIndexFor(
    double fingerY,
    double yearY,
    int count,
    double monthExp,
  ) {
    int bestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < count; i++) {
      final mY = _getMonthLabelY(i, count, yearY, monthExp);
      final dist = (mY - fingerY).abs();
      if (dist < minDistance) {
        minDistance = dist;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  double _getMonthLabelY(
    int index,
    int totalMonths,
    double yearY,
    double monthExp,
  ) {
    const slot = 28.0;
    final centerOffset = (index - (totalMonths - 1) / 2.0) * slot * monthExp;
    return yearY + centerOffset;
  }

  int _nearestDateIndexFor(
    double fingerY,
    double monthY,
    int count,
    double dateExp,
  ) {
    int bestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < count; i++) {
      final dY = _getDateLabelY(i, count, monthY, dateExp);
      final dist = (dY - fingerY).abs();
      if (dist < minDistance) {
        minDistance = dist;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  double _getDateLabelY(
    int index,
    int totalDates,
    double monthY,
    double dateExp,
  ) {
    const slot = 22.0;
    final centerOffset = (index - (totalDates - 1) / 2.0) * slot * dateExp;
    return monthY + centerOffset;
  }

  void _onPanStart(DragStartDetails details, double height) {
    if (widget.yearIndex.isEmpty) return;
    _isDragging = true;
    _isRetracting = false;
    _retractProgress = 0.0;
    _targetY = details.localPosition.dy;
    _targetDepthDx = max(0, _navigatorWidth - details.localPosition.dx);

    _state.value = _state.value.copyWith(availableHeight: height);
    _startTickingIfNeeded();
  }

  void _onPanUpdate(DragUpdateDetails details, double height) {
    if (!_isDragging) return;
    _targetY = details.localPosition.dy;
    _targetDepthDx = max(0, _navigatorWidth - details.localPosition.dx);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final current = _state.value;

    // Check if commit threshold reached
    if (current.phase == WaveNavState.commitReady ||
        current.displayDepthDx >= _zoneCommit) {
      final resolvedTargetIndex = _resolveTargetIndex(current);
      if (resolvedTargetIndex != null) {
        widget.onCommit(resolvedTargetIndex);
      }
    }

    // Start retracting animation
    _isRetracting = true;
    _retractProgress = 0.0;
    _targetDepthDx = 0.0;
  }

  void _onPanCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _isRetracting = true;
    _retractProgress = 0.0;
    _targetDepthDx = 0.0;
  }

  int? _resolveTargetIndex(_WaveState state) {
    final yIdx = state.selectedYearIndex;
    if (yIdx == null || yIdx < 0 || yIdx >= widget.yearIndex.length) {
      return null;
    }

    final year = widget.yearIndex[yIdx].year;
    final months = widget.monthIndex[year] ?? [];
    final mIdx = state.selectedMonthIndex;

    // If date expansion is active and valid date selected
    if (state.displayDateExpansion > 0.4 &&
        mIdx != null &&
        mIdx >= 0 &&
        mIdx < months.length) {
      final month = months[mIdx].month;
      final dates = widget.dateIndex[(year, month)] ?? [];
      final dIdx = state.selectedDateIndex;
      if (dIdx != null && dIdx >= 0 && dIdx < dates.length) {
        return dates[dIdx].itemIndex;
      }
    }

    // If month expansion is active and valid month selected
    if (state.displayMonthExpansion > 0.4 &&
        mIdx != null &&
        mIdx >= 0 &&
        mIdx < months.length) {
      return months[mIdx].itemIndex;
    }

    // Fallback to year level
    return widget.yearIndex[yIdx].itemIndex;
  }

  String _buildSemanticsLabel(_WaveState state) {
    if (!state.active || state.selectedYearIndex == null) {
      return 'Timeline wave navigator. Inactive.';
    }

    final year = widget.yearIndex[state.selectedYearIndex!].year;
    final StringBuffer sb = StringBuffer('Timeline wave navigator. Year $year');

    final months = widget.monthIndex[year] ?? [];
    if (state.selectedMonthIndex != null &&
        state.selectedMonthIndex! < months.length) {
      final monthEntry = months[state.selectedMonthIndex!];
      sb.write(', ${monthEntry.monthName}');

      final dates = widget.dateIndex[(year, monthEntry.month)] ?? [];
      if (state.selectedDateIndex != null &&
          state.selectedDateIndex! < dates.length) {
        final dateEntry = dates[state.selectedDateIndex!];
        sb.write(' ${dateEntry.day}');
      }
    }

    if (state.phase == WaveNavState.commitReady) {
      sb.write('. Release to jump.');
    }

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.yearIndex.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = widget.theme ?? TimelineWaveTheme.fromContext(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return ValueListenableBuilder<_WaveState>(
          valueListenable: _state,
          builder: (context, state, _) {
            return Semantics(
              label: _buildSemanticsLabel(state),
              liveRegion: true,
              child: SizedBox(
                width: _navigatorWidth,
                height: height,
                child: Stack(
                  children: [
                    // Activation gesture detector on the right side
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: state.active
                          ? _navigatorWidth
                          : _activationZoneWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (d) => _onPanStart(d, height),
                        onPanUpdate: (d) => _onPanUpdate(d, height),
                        onPanEnd: _onPanEnd,
                        onPanCancel: _onPanCancel,
                      ),
                    ),
                    RepaintBoundary(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: Size(_navigatorWidth, height),
                          painter: _WavePainter(
                            state: state,
                            years: widget.yearIndex,
                            monthIndex: widget.monthIndex,
                            dateIndex: widget.dateIndex,
                            amplitude: _amplitude,
                            spread: _spread,
                            availableHeight: height,
                            theme: theme,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WaveState {
  final bool active;
  final WaveNavState phase;
  final double displayY;
  final double displayDepthDx;
  final double displayMonthExpansion;
  final double displayDateExpansion;
  final int? selectedYearIndex;
  final int? selectedMonthIndex;
  final int? selectedDateIndex;
  final double availableHeight;
  final double retractScale;
  final double pulsePhase;

  const _WaveState({
    this.active = false,
    this.phase = WaveNavState.idle,
    this.displayY = 0.0,
    this.displayDepthDx = 0.0,
    this.displayMonthExpansion = 0.0,
    this.displayDateExpansion = 0.0,
    this.selectedYearIndex,
    this.selectedMonthIndex,
    this.selectedDateIndex,
    this.availableHeight = 0.0,
    this.retractScale = 1.0,
    this.pulsePhase = 0.0,
  });

  _WaveState copyWith({double? availableHeight}) {
    return _WaveState(
      active: active,
      phase: phase,
      displayY: displayY,
      displayDepthDx: displayDepthDx,
      displayMonthExpansion: displayMonthExpansion,
      displayDateExpansion: displayDateExpansion,
      selectedYearIndex: selectedYearIndex,
      selectedMonthIndex: selectedMonthIndex,
      selectedDateIndex: selectedDateIndex,
      availableHeight: availableHeight ?? this.availableHeight,
      retractScale: retractScale,
      pulsePhase: pulsePhase,
    );
  }
}

class _WavePainter extends CustomPainter {
  final _WaveState state;
  final List<YearIndexEntry> years;
  final Map<int, List<MonthIndexEntry>> monthIndex;
  final Map<(int, int), List<DateIndexEntry>> dateIndex;
  final double amplitude;
  final double spread;
  final double availableHeight;
  final TimelineWaveTheme theme;

  _WavePainter({
    required this.state,
    required this.years,
    required this.monthIndex,
    required this.dateIndex,
    required this.amplitude,
    required this.spread,
    required this.availableHeight,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!state.active || years.isEmpty) return;

    final slot = availableHeight / years.length;
    final peakY = state.displayY;

    // Year opacities & scale compress when Month / Date layers expand
    final yearBaseOpacity =
        (1.0 -
                0.35 * state.displayMonthExpansion -
                0.25 * state.displayDateExpansion)
            .clamp(0.2, 1.0);

    double selectedYearX = size.width;
    double selectedYearY = peakY;

    // 1. Draw Year Wave
    final yearPath = Path();
    for (int i = 0; i < years.length; i++) {
      final labelY = slot * i + slot / 2;
      final isSelected = i == state.selectedYearIndex;

      final normDist = (labelY - peakY) / spread;
      final displacement =
          amplitude * exp(-(normDist * normDist)) * state.retractScale;

      final labelX = size.width - displacement;

      if (i == 0) {
        yearPath.moveTo(labelX, labelY);
      } else {
        yearPath.lineTo(labelX, labelY);
      }

      if (isSelected) {
        selectedYearX = labelX;
        selectedYearY = labelY;
      }

      final opacity =
          (isSelected ? 1.0 : (0.35 + 0.55 * exp(-(normDist * normDist)))) *
          yearBaseOpacity;
      final fontScale = isSelected
          ? 1.15
          : (0.85 + 0.2 * exp(-(normDist * normDist)));

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${years[i].year}',
          style: TextStyle(
            color: theme.yearColor.withValues(alpha: opacity),
            fontSize: theme.baseYearFontSize * fontScale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          labelX - textPainter.width - 18,
          labelY - textPainter.height / 2,
        ),
      );

      if (isSelected) {
        canvas.drawCircle(
          Offset(labelX - 8, labelY),
          4,
          Paint()..color = theme.yearColor.withValues(alpha: yearBaseOpacity),
        );
      }
    }

    final yearLinePaint = Paint()
      ..color = theme.yearColor.withValues(alpha: 0.3 * yearBaseOpacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(yearPath, yearLinePaint);

    // 2. Draw Month Wave (Nested off Selected Year peak)
    double selectedMonthX = selectedYearX;
    double selectedMonthY = selectedYearY;

    if (state.displayMonthExpansion > 0.01 && state.selectedYearIndex != null) {
      final year = years[state.selectedYearIndex!].year;
      final months = monthIndex[year] ?? [];

      if (months.isNotEmpty) {
        final monthBaseOpacity =
            (state.displayMonthExpansion *
                    (1.0 - 0.3 * state.displayDateExpansion))
                .clamp(0.0, 1.0);

        final monthPath = Path();
        const monthSlot = 28.0;

        for (int m = 0; m < months.length; m++) {
          final isSelected = m == state.selectedMonthIndex;

          final labelY =
              selectedYearY +
              (m - (months.length - 1) / 2.0) *
                  monthSlot *
                  state.displayMonthExpansion;

          final normDist = (labelY - peakY) / (spread * 0.7);
          final displacement =
              (amplitude * 0.85) *
              state.displayMonthExpansion *
              exp(-(normDist * normDist)) *
              state.retractScale;

          final labelX =
              selectedYearX - displacement - 20 * state.displayMonthExpansion;

          if (m == 0) {
            monthPath.moveTo(labelX, labelY);
          } else {
            monthPath.lineTo(labelX, labelY);
          }

          if (isSelected) {
            selectedMonthX = labelX;
            selectedMonthY = labelY;
          }

          // Neighborhood rendering check
          if ((labelY - peakY).abs() < spread * 1.5) {
            final opacity =
                (isSelected ? 1.0 : (0.4 + 0.5 * exp(-(normDist * normDist)))) *
                monthBaseOpacity;
            final fontScale = isSelected
                ? 1.12
                : (0.88 + 0.15 * exp(-(normDist * normDist)));

            final textPainter = TextPainter(
              text: TextSpan(
                text: months[m].monthName,
                style: TextStyle(
                  color: theme.monthColor.withValues(alpha: opacity),
                  fontSize: theme.baseMonthFontSize * fontScale,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            textPainter.paint(
              canvas,
              Offset(
                labelX - textPainter.width - 14,
                labelY - textPainter.height / 2,
              ),
            );

            if (isSelected && monthBaseOpacity > 0.1) {
              canvas.drawCircle(
                Offset(labelX - 6, labelY),
                3.5,
                Paint()
                  ..color = theme.monthColor.withValues(
                    alpha: monthBaseOpacity,
                  ),
              );
            }
          }
        }

        final monthLinePaint = Paint()
          ..color = theme.monthColor.withValues(alpha: 0.35 * monthBaseOpacity)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;
        canvas.drawPath(monthPath, monthLinePaint);
      }
    }

    // 3. Draw Date Wave (Nested off Selected Month peak)
    double selectedDateX = selectedMonthX;
    double selectedDateY = selectedMonthY;

    if (state.displayDateExpansion > 0.01 &&
        state.selectedYearIndex != null &&
        state.selectedMonthIndex != null) {
      final year = years[state.selectedYearIndex!].year;
      final months = monthIndex[year] ?? [];

      if (state.selectedMonthIndex! < months.length) {
        final month = months[state.selectedMonthIndex!].month;
        final dates = dateIndex[(year, month)] ?? [];

        if (dates.isNotEmpty) {
          final dateBaseOpacity = state.displayDateExpansion.clamp(0.0, 1.0);
          final datePath = Path();
          const dateSlot = 22.0;

          for (int d = 0; d < dates.length; d++) {
            final isSelected = d == state.selectedDateIndex;

            final labelY =
                selectedMonthY +
                (d - (dates.length - 1) / 2.0) *
                    dateSlot *
                    state.displayDateExpansion;

            final normDist = (labelY - peakY) / (spread * 0.5);
            final displacement =
                (amplitude * 0.7) *
                state.displayDateExpansion *
                exp(-(normDist * normDist)) *
                state.retractScale;

            final labelX =
                selectedMonthX - displacement - 15 * state.displayDateExpansion;

            if (d == 0) {
              datePath.moveTo(labelX, labelY);
            } else {
              datePath.lineTo(labelX, labelY);
            }

            if (isSelected) {
              selectedDateX = labelX;
              selectedDateY = labelY;
            }

            // Neighborhood rendering optimization
            if ((labelY - peakY).abs() < spread * 1.5) {
              final opacity =
                  (isSelected
                      ? 1.0
                      : (0.45 + 0.45 * exp(-(normDist * normDist)))) *
                  dateBaseOpacity;
              final fontScale = isSelected
                  ? 1.1
                  : (0.9 + 0.1 * exp(-(normDist * normDist)));

              final textPainter = TextPainter(
                text: TextSpan(
                  text: dates[d].dayString,
                  style: TextStyle(
                    color: theme.dateColor.withValues(alpha: opacity),
                    fontSize: theme.baseDateFontSize * fontScale,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                textDirection: TextDirection.ltr,
              )..layout();

              textPainter.paint(
                canvas,
                Offset(
                  labelX - textPainter.width - 12,
                  labelY - textPainter.height / 2,
                ),
              );

              if (isSelected && dateBaseOpacity > 0.1) {
                canvas.drawCircle(
                  Offset(labelX - 5, labelY),
                  3.0,
                  Paint()
                    ..color = theme.dateColor.withValues(
                      alpha: dateBaseOpacity,
                    ),
                );
              }
            }
          }

          final dateLinePaint = Paint()
            ..color = theme.dateColor.withValues(alpha: 0.4 * dateBaseOpacity)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke;
          canvas.drawPath(datePath, dateLinePaint);
        }
      }
    }

    // 4. Draw Commit Pulse Visual when in commitReady zone
    if (state.phase == WaveNavState.commitReady) {
      double commitX = selectedYearX;
      double commitY = selectedYearY;
      Color targetColor = theme.yearColor;

      if (state.displayDateExpansion > 0.5) {
        commitX = selectedDateX;
        commitY = selectedDateY;
        targetColor = theme.dateColor;
      } else if (state.displayMonthExpansion > 0.5) {
        commitX = selectedMonthX;
        commitY = selectedMonthY;
        targetColor = theme.monthColor;
      }

      final pulseVal = sin(state.pulsePhase);
      final radius = 12.0 + 4.0 * pulseVal;
      final glowOpacity = (0.2 + 0.25 * pulseVal).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(commitX - 6, commitY),
        radius,
        Paint()..color = targetColor.withValues(alpha: glowOpacity),
      );

      canvas.drawCircle(
        Offset(commitX - 6, commitY),
        5.0,
        Paint()..color = theme.commitGlowColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
