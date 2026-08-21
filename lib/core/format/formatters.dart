import 'package:intl/intl.dart';

import '../config/env.dart';

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
  static final _apiDate = DateFormat('yyyy-MM-dd');

  /// `11 Agustus 2026` — the list screens and Activation Date.
  static String listDate(DateTime d) => _listDate.format(d.toLocal());

  /// `21/08/2026` — the Tanggal Pergi field.
  static String fieldDate(DateTime d) => _fieldDate.format(d.toLocal());

  /// `20/05` — the Home chart's x-axis.
  static String chartDay(DateTime d) => _chartDay.format(d.toLocal());

  /// `2026-08-21` — the wire format for `visitDate`.
  static String apiDate(DateTime d) => _apiDate.format(d);

  /// Renders `-` for a null Activation Date, which is the normal state until
  /// the Gross Add feed confirms (CLAUDE.md §7 rule 7).
  static String listDateOrDash(DateTime? d) => d == null ? '-' : listDate(d);
}

/// Money rendering.
abstract final class Money {
  /// The Insentif tile: whole rupiah in, hundreds-of-thousands out.
  ///
  /// 24 200 000 renders as `242` beneath the caption "Ratus Ribu Rupiah".
  /// The scaling is presentation-only — never send a scaled value back.
  static String incentiveTile(int rupiah) {
    return (rupiah ~/ Env.incentiveDisplayDivisor).toString();
  }
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
