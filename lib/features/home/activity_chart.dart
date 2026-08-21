import 'package:flutter/material.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/brand.dart';
import '../../data/models/models.dart';

/// The Home bar chart: one magenta bar per day against a lighter target bar
/// behind it.
///
/// Hand-drawn rather than pulled from a charting package — it is a fixed,
/// seven-ish bar chart with no interaction, which is not worth a dependency.
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.days, this.height = 190});

  final List<DailyActivity> days;
  final double height;

  /// Height of the plot area, leaving room for the date row beneath it.
  static const _labelRowHeight = 22.0;

  /// Rounds the axis up to a multiple of three so the four gridlines land on
  /// whole numbers — the mockup's 0 / 10 / 20 / 30.
  int get _maxY {
    var peak = 0;
    for (final d in days) {
      if (d.activations > peak) peak = d.activations;
      if (d.target > peak) peak = d.target;
    }
    if (peak <= 0) return 3;
    return ((peak + 2) ~/ 3) * 3;
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
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
                          for (final d in days)
                            Expanded(
                              child: _Bar(
                                actualHeight:
                                    _scale(d.activations, maxY, plotHeight),
                                targetHeight:
                                    _scale(d.target, maxY, plotHeight),
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
                    for (final d in days)
                      Expanded(
                        child: Text(
                          Dates.chartDay(d.date),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Brand.charcoal,
                            fontSize: 10.5,
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
  const _Bar({required this.actualHeight, required this.targetHeight});

  final double actualHeight;
  final double targetHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Grey benchmark, drawn wider and behind.
        _bar(targetHeight, 22, Brand.chartTarget),
        // Magenta actual, in front.
        _bar(actualHeight, 13, Brand.magenta),
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
