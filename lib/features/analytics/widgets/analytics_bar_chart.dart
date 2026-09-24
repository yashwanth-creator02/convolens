import 'package:flutter/material.dart';

class AnalyticsBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final Color? barColor;
  final List<Color>? gradientColors;
  final double height;
  final String unit;
  final void Function(int index)? onBarTap;

  const AnalyticsBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor,
    this.gradientColors,
    this.height = 140,
    this.unit = '',
    this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (values.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: Text(
          'No activity data available.',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      );
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal > 0 ? maxVal : 1;

    final primaryCol = barColor ?? scheme.primary;
    final gradient = gradientColors ?? [
      primaryCol,
      primaryCol.withValues(alpha: 0.75),
    ];

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barAreaHeight = constraints.maxHeight - 34;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (index) {
              final val = values[index];
              final fraction = (val / effectiveMax).clamp(0.0, 1.0);
              final fillHeight = (barAreaHeight * fraction).clamp(val > 0 ? 4.0 : 0.0, barAreaHeight);

              return Expanded(
                child: GestureDetector(
                  onTap: onBarTap != null ? () => onBarTap!(index) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              val > 0 ? '$val$unit' : '',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Bar track & fill
                        Container(
                          height: barAreaHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: fillHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: val > 0
                                  ? [
                                      BoxShadow(
                                        color: primaryCol.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // X axis label
                        SizedBox(
                          height: 12,
                          child: Text(
                            index < labels.length ? labels[index] : '',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
