/// The relative window every list and report endpoint accepts.
///
/// The mockups show a `7 Hari Terakhir` chip beside a `Filter` control but never
/// show what Filter opens — CLAUDE.md §11.1 lists this as unresolved. Until it
/// is settled, the chip reflects the API's own `period` enum, which is the only
/// filtering the contract actually offers.
enum Period {
  d7('7d', '7 Hari Terakhir'),
  d30('30d', '30 Hari Terakhir'),
  mtd('mtd', 'Bulan Ini'),
  ytd('ytd', 'Tahun Ini');

  const Period(this.wire, this.label);

  /// The `period` query value.
  final String wire;

  /// What the chip displays.
  final String label;
}
