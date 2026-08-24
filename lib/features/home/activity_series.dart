import '../../core/format/formatters.dart';
import '../../core/period.dart';
import '../../data/models/models.dart';

/// One bar on the Home chart: an x-axis label plus its actual and target values.
///
/// `/reports/daily-activity` always returns a *daily* series. Drawing a bar per
/// day is fine for a week, but a month or a year of them stacks the x-axis into
/// an unreadable smear, so [buildActivitySeries] sums the daily points into the
/// coarser buckets the chart actually draws. The roll-up is presentation-only —
/// nothing here is ever sent back (CLAUDE.md §7).
class ChartBar {
  const ChartBar({
    required this.label,
    required this.actual,
    required this.target,
  });

  /// x-axis caption — `20/05`, `W1`, or `Agu`.
  final String label;

  /// The magenta bar: activations summed across the bucket.
  final int actual;

  /// The grey benchmark bar: target summed across the bucket.
  final int target;
}

/// Buckets the daily API series into the bars [grouping] calls for.
List<ChartBar> buildActivitySeries(
  List<DailyActivity> days,
  ChartGrouping grouping,
) {
  switch (grouping) {
    case ChartGrouping.daily:
      final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
      return [
        for (final d in sorted)
          ChartBar(
            label: Dates.chartDay(d.date),
            actual: d.activations,
            target: d.target,
          ),
      ];
    case ChartGrouping.weekly:
      return _bucket(
        days,
        // Days 1–7 fall in W1, 8–14 in W2, and so on. A 29th–31st tail becomes a
        // short W5, which is real: those days are genuinely a partial week.
        keyOf: (d) => (d.year, d.month, (d.day - 1) ~/ 7),
        labelOf: (d) => 'W${((d.day - 1) ~/ 7) + 1}',
      );
    case ChartGrouping.monthly:
      return _bucket(
        days,
        keyOf: (d) => (d.year, d.month, 0),
        labelOf: Dates.chartMonth,
      );
  }
}

/// Groups [days] by [keyOf] in date order, summing each bucket and labelling it
/// from the first day that lands in it.
List<ChartBar> _bucket(
  List<DailyActivity> days, {
  required (int, int, int) Function(DateTime) keyOf,
  required String Function(DateTime) labelOf,
}) {
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
  final buckets = <(int, int, int), _Acc>{};
  for (final d in sorted) {
    final acc = buckets.putIfAbsent(keyOf(d.date), () => _Acc(labelOf(d.date)));
    acc.actual += d.activations;
    acc.target += d.target;
  }
  return [
    for (final acc in buckets.values)
      ChartBar(label: acc.label, actual: acc.actual, target: acc.target),
  ];
}

class _Acc {
  _Acc(this.label);

  final String label;
  int actual = 0;
  int target = 0;
}
