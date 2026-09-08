import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/year_index.dart';

class TimelineWaveNavigator extends StatefulWidget {
  final List<YearIndexEntry> yearIndex;
  final void Function(int itemIndex) onCommit;

  const TimelineWaveNavigator({
    super.key,
    required this.yearIndex,
    required this.onCommit,
  });

  @override
  State<TimelineWaveNavigator> createState() => _TimelineWaveNavigatorState();
}

class _TimelineWaveNavigatorState extends State<TimelineWaveNavigator>
    with SingleTickerProviderStateMixin {
  static const double _activationZoneWidth = 32;
  static const double _amplitude = 56;
  static const double _spread = 90;
  static const double _smoothingSpeed = 16.0;

  final ValueNotifier<_WaveState> _state = ValueNotifier(const _WaveState());

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  double _targetY = 0;
  double _availableHeight = 0;

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

  int? _nearestYearIndexFor(double y) {
    if (widget.yearIndex.isEmpty || _availableHeight <= 0) return null;
    final slot = _availableHeight / widget.yearIndex.length;
    return (y / slot).floor().clamp(0, widget.yearIndex.length - 1);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    final current = _state.value;
    final t = 1 - exp(-_smoothingSpeed * dt);
    final newDisplayY = current.displayY + (_targetY - current.displayY) * t;
    final newSelected = _nearestYearIndexFor(newDisplayY);

    if ((newDisplayY - current.displayY).abs() > 0.05 ||
        newSelected != current.selectedYearIndex) {
      _state.value = current.copyWith(
        displayY: newDisplayY,
        selectedYearIndex: newSelected,
      );
    }
  }

  void _onPanStart(DragStartDetails details, double availableHeight) {
    _availableHeight = availableHeight;
    _targetY = details.localPosition.dy;
    _lastElapsed = Duration.zero;
    _state.value = _WaveState(
      active: true,
      displayY: details.localPosition.dy,
      selectedYearIndex: _nearestYearIndexFor(details.localPosition.dy),
    );
    _ticker.start();
  }

  void _onPanUpdate(DragUpdateDetails details, double availableHeight) {
    _availableHeight = availableHeight;
    _targetY = details.localPosition.dy;
  }

  void _endDrag() {
    _ticker.stop();
    final selected = _state.value.selectedYearIndex;
    _state.value = const _WaveState();

    if (selected != null &&
        selected >= 0 &&
        selected < widget.yearIndex.length) {
      widget.onCommit(widget.yearIndex[selected].itemIndex);
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
          width: 140,
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
                        size: Size(140, height),
                        painter: _WavePainter(
                          state: state,
                          years: widget.yearIndex,
                          amplitude: _amplitude,
                          spread: _spread,
                          availableHeight: height,
                          color: Theme.of(context).colorScheme.primary,
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
  final int? selectedYearIndex;

  const _WaveState({
    this.active = false,
    this.displayY = 0,
    this.selectedYearIndex,
  });

  _WaveState copyWith({double? displayY, int? selectedYearIndex}) {
    return _WaveState(
      active: true,
      displayY: displayY ?? this.displayY,
      selectedYearIndex: selectedYearIndex ?? this.selectedYearIndex,
    );
  }
}

class _WavePainter extends CustomPainter {
  final _WaveState state;
  final List<YearIndexEntry> years;
  final double amplitude;
  final double spread;
  final double availableHeight;
  final Color color;

  _WavePainter({
    required this.state,
    required this.years,
    required this.amplitude,
    required this.spread,
    required this.availableHeight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!state.active || years.isEmpty) return;

    final slot = availableHeight / years.length;
    final peakY = state.displayY;

    for (int i = 0; i < years.length; i++) {
      final labelY = slot * i + slot / 2;
      final isSelected = i == state.selectedYearIndex;

      final normalizedDistance = (labelY - peakY) / spread;
      final falloff = exp(-(normalizedDistance * normalizedDistance));
      final displacement = amplitude * falloff;

      final edgeX = size.width;
      final labelX = edgeX - displacement - 20;

      final opacity = isSelected ? 1.0 : (0.35 + 0.55 * falloff);
      final scale = isSelected ? 1.15 : (0.85 + 0.2 * falloff);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${years[i].year}',
          style: TextStyle(
            color: color.withOpacity(opacity),
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

      if (isSelected) {
        canvas.drawCircle(
          Offset(labelX + 8, labelY),
          4,
          Paint()..color = color,
        );
      }
    }

    final linePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < years.length; i++) {
      final labelY = slot * i + slot / 2;
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
