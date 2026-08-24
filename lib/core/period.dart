/// The relative window every list and report endpoint accepts.
///
/// The mockups show a `7 Hari Terakhir` chip beside a `Filter` control but never
/// show what Filter opens — CLAUDE.md §11.1 lists this as unresolved. Until it
/// is settled, the chip reflects the API's own `period` enum, which is the only
/// filtering the contract actually offers.
enum Period {
  d7('7d', '7 Hari Terakhir'),
  mtd('mtd', 'Bulan Ini'),
  ytd('ytd', 'Tahun Ini');

  const Period(this.wire, this.label);

  /// The `period` query value.
  final String wire;

  /// What the chip displays.
  final String label;

  /// How the Home chart buckets this window's daily series.
  ///
  /// A month of days — let alone a year — cannot each get their own bar without
  /// the x-axis collapsing into stacked, unreadable labels, so `mtd` rolls the
  /// days up into weeks (W1–W5) and `ytd` into months (Jan–Des). `d7` is short
  /// enough to keep one bar per day.
  ChartGrouping get grouping => switch (this) {
        d7 => ChartGrouping.daily,
        mtd => ChartGrouping.weekly,
        ytd => ChartGrouping.monthly,
      };
}

/// How the Home chart rolls the daily API series up into bars — see
/// [Period.grouping].
enum ChartGrouping { daily, weekly, monthly }
