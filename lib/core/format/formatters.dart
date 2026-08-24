import 'package:intl/intl.dart';

/// Date rendering.
///
/// Indonesian month names throughout — `11 Agustus 2026`. The English months in
/// two of the list mockups were a mockup slip, resolved in favour of §6's rule
/// that the user-facing language is Indonesian.
abstract final class Dates {
  static const _locale = 'id_ID';

  static final _listDate = DateFormat('d MMMM yyyy', _locale);
  static final _fieldDate = DateFormat('dd/MM/yyyy', _locale);
  static final _chartDay = DateFormat('dd/MM', _locale);
  static final _chartMonth = DateFormat('MMM', _locale);
  static final _apiDate = DateFormat('yyyy-MM-dd');

  /// `11 Agustus 2026` — the list screens and Activation Date.
  static String listDate(DateTime d) => _listDate.format(d.toLocal());

  /// `21/08/2026` — the Tanggal Pergi field.
  static String fieldDate(DateTime d) => _fieldDate.format(d.toLocal());

  /// `20/05` — the Home chart's x-axis when grouped by day.
  static String chartDay(DateTime d) => _chartDay.format(d.toLocal());

  /// `Agu` — the Home chart's x-axis when grouped by month (Tahun Ini).
  static String chartMonth(DateTime d) => _chartMonth.format(d.toLocal());

  /// `2026-08-21` — the wire format for `visitDate`.
  static String apiDate(DateTime d) => _apiDate.format(d);

  /// Renders `-` for a null Activation Date, which is the normal state until
  /// the Gross Add feed confirms (CLAUDE.md §7 rule 7).
  static String listDateOrDash(DateTime? d) => d == null ? '-' : listDate(d);
}

/// Money rendering.
abstract final class Money {
  static final _rupiah = NumberFormat.decimalPattern('id_ID');

  /// The Insentif balance, e-wallet style: whole rupiah in, `Rp135.000` out.
  ///
  /// Shown in full rather than scaled — the older `242` + "Ratus Ribu Rupiah"
  /// tile made an AE do the arithmetic. Formatting is presentation-only; the
  /// value on the wire is always whole rupiah and is never sent back scaled.
  static String rupiah(int amount) => _rupiah.format(amount);
}

/// Customer status rendering.
///
/// The API speaks `EDUKASI` / `HOT_LEADS` / `PURCHASE`; the list mockups show
/// `Edukasi`, `Hot Leads`, `Purchase`.
abstract final class StatusLabels {
  static const _byWire = {
    'EDUKASI': 'Edukasi',
    'HOT_LEADS': 'Hot Leads',
    'PURCHASE': 'Purchase',
  };

  static String customer(String wire) => _byWire[wire] ?? wire;
}
