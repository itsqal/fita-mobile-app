import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import 'activity_series.dart';

/// The Home bar chart: one magenta bar per bucket against a lighter target bar
/// behind it.
///
/// Hand-drawn rather than pulled from a charting package — it is a fixed,
/// non-interactive bar chart, which is not worth a dependency. It draws whatever
/// [buildActivitySeries] hands it: seven days, four-or-five weeks, or up to
/// twelve months. Bar and label sizes step down as the buckets get more numerous
/// so a twelve-month axis stays readable instead of smearing together.
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.bars, this.height = 190});

  final List<ChartBar> bars;
  final double height;

  /// Height of the plot area, leaving room for the label row beneath it.
  static const _labelRowHeight = 22.0;

  /// Rounds the axis up to a multiple of three so the four gridlines land on
  /// whole numbers.
  int get _maxY {
    var peak = 0;
    for (final b in bars) {
      if (b.actual > peak) peak = b.actual;
      if (b.target > peak) peak = b.target;
    }
    if (peak <= 0) return 3;
    return ((peak + 2) ~/ 3) * 3;
  }

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Belum ada aktivitas pada periode ini.',
            style: TextStyle(color: Brand.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final maxY = _maxY;
    final plotHeight = height - _labelRowHeight;
    final ticks = [maxY, maxY * 2 ~/ 3, maxY ~/ 3, 0];

    // Seven daily bars can be generous; twelve monthly ones need to slim down,
    // labels included, or the axis crowds.
    final n = bars.length;
    final (targetWidth, actualWidth, labelSize) = switch (n) {
      <= 7 => (22.0, 13.0, 10.5),
      <= 9 => (18.0, 11.0, 10.0),
      _ => (13.0, 8.0, 9.0),
    };

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y axis labels, each sitting on the gridline it names.
          SizedBox(
            width: 26,
            height: plotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final t in ticks)
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: Text(
                      '$t',
                      style: const TextStyle(
                        color: Brand.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: plotHeight,
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < ticks.length; i++)
                            Container(height: 1, color: Brand.border),
                        ],
                      ),
                      Row(
                        // stretch, so every column gets the full plot height —
                        // bars are measured from the baseline, not from wherever
                        // their own content happens to end.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final b in bars)
                            Expanded(
                              child: _Bar(
                                actualHeight:
                                    _scale(b.actual, maxY, plotHeight),
                                targetHeight:
                                    _scale(b.target, maxY, plotHeight),
                                targetWidth: targetWidth,
                                actualWidth: actualWidth,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final b in bars)
                      Expanded(
                        // Never let a label wrap or overflow into its neighbour:
                        // it shrinks to fit its own column instead.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            b.label,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Brand.charcoal,
                              fontSize: labelSize,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double _scale(int value, int maxY, double plotHeight) {
    if (maxY <= 0 || value <= 0) return 0;
    return (value / maxY) * plotHeight;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.actualHeight,
    required this.targetHeight,
    required this.targetWidth,
    required this.actualWidth,
  });

  final double actualHeight;
  final double targetHeight;
  final double targetWidth;
  final double actualWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Grey benchmark, drawn wider and behind.
        _bar(targetHeight, targetWidth, Brand.chartTarget),
        // Magenta actual, in front.
        _bar(actualHeight, actualWidth, Brand.magenta),
      ],
    );
  }

  Widget _bar(double h, double w, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(w / 2),
      ),
    );
  }
}
