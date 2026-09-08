import 'dart:math';

import 'package:flutter/material.dart';

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

class _TimelineWaveNavigatorState extends State<TimelineWaveNavigator> {
  static const double _activationZoneWidth = 32;
  static const double _amplitude = 36;
  static const double _spread = 90;

  final ValueNotifier<_WaveState> _state = ValueNotifier(const _WaveState());

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  int _nearestYearIndexFor(double fingerY, double availableHeight) {
    if (widget.yearIndex.isEmpty) return -1;
    final slot = availableHeight / widget.yearIndex.length;
    final raw = (fingerY / slot).floor().clamp(0, widget.yearIndex.length - 1);
    return raw;
  }

  void _onPanStart(DragStartDetails details, double availableHeight) {
    final nearest = _nearestYearIndexFor(
      details.localPosition.dy,
      availableHeight,
    );
    if (nearest == -1) return;
    _state.value = _WaveState(
      active: true,
      fingerY: details.localPosition.dy,
      selectedYearIndex: nearest,
    );
  }

  void _onPanUpdate(DragUpdateDetails details, double availableHeight) {
    if (!_state.value.active) return;
    final nearest = _nearestYearIndexFor(
      details.localPosition.dy,
      availableHeight,
    );
    _state.value = _state.value.copyWith(
      fingerY: details.localPosition.dy,
      selectedYearIndex: nearest,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    final selected = _state.value.selectedYearIndex;
    _state.value = const _WaveState();

    if (selected != null &&
        selected >= 0 &&
        selected < widget.yearIndex.length) {
      widget.onCommit(widget.yearIndex[selected].itemIndex);
    }
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
                  onPanEnd: _onPanEnd,
                  onPanCancel: () => _state.value = const _WaveState(),
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
  final double fingerY;
  final int? selectedYearIndex;

  const _WaveState({
    this.active = false,
    this.fingerY = 0,
    this.selectedYearIndex,
  });

  _WaveState copyWith({double? fingerY, int? selectedYearIndex}) {
    return _WaveState(
      active: true,
      fingerY: fingerY ?? this.fingerY,
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
    final peakY = state.fingerY;

    for (int i = 0; i < years.length; i++) {
      final labelY = slot * i + slot / 2;
      final isSelected = i == state.selectedYearIndex;

      final normalizedDistance = (labelY - peakY) / spread;
      final displacement =
          amplitude * exp(-(normalizedDistance * normalizedDistance));

      final edgeX = size.width;
      final labelX = edgeX - displacement - 20;

      final opacity = isSelected
          ? 1.0
          : (0.35 + 0.55 * exp(-(normalizedDistance * normalizedDistance)));
      final scale = isSelected
          ? 1.15
          : (0.85 + 0.2 * exp(-(normalizedDistance * normalizedDistance)));

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
      final displacement =
          amplitude * exp(-(normalizedDistance * normalizedDistance));
      final x = size.width - displacement;

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
