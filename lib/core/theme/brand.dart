import 'package:flutter/material.dart';

/// The HiFi AIR brand palette.
///
/// Every colour the app draws comes from here. Screen code must never carry a
/// raw hex literal — see CLAUDE.md §5.
abstract final class Brand {
  // --- Approved palette (CLAUDE.md §5) -------------------------------------
  static const magenta = Color(0xFFC80078);
  static const amber = Color(0xFFF5AF00);
  static const charcoal = Color(0xFF464A4D);
  static const ink = Color(0xFF2A2E31);
  static const tintMagenta = Color(0xFFFBE5F1);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC80078), Color(0xFFDD5A12), Color(0xFFF5AF00)],
    stops: [0.0, 0.56, 1.0],
  );

  // --- Pressed / disabled states -------------------------------------------
  // §5 expects "a tint or shade for pressed and disabled states". These are
  // shades of the approved colours, not new brand colours.
  static const magentaDark = Color(0xFFA30062);
  static const amberDark = Color(0xFFD29600);
  static const amberDisabled = Color(0xFFF6D67F);

  // --- Neutrals read off the mockups ---------------------------------------
  /// Page background behind cards on Home, the lists and Report.
  static const surfaceMuted = Color(0xFFF7F7F7);

  /// Card and input fill.
  static const surface = Color(0xFFFFFFFF);

  /// Fill of a disabled input — "ID AE", "IMEI", "Tipe Modem".
  static const fieldDisabled = Color(0xFFEFEFEF);

  /// Input outline in its resting state.
  static const border = Color(0xFFDDDDDD);

  /// Field labels, secondary list lines, chart axis text.
  static const textMuted = Color(0xFF7A7F83);

  /// The grey benchmark bar behind each pink bar on the Home chart.
  static const chartTarget = Color(0xFFE3E3E3);

  // --- Status colours -------------------------------------------------------
  // NOT part of the §5 palette: the mockups show a green "Activated" /
  // "Terverifikasi" pill and a red "Not Activated" badge, and §5 has no colour
  // for either. Named here so they stay consistent and reviewable in one place.
  static const success = Color(0xFF2FBF5B);
  static const danger = Color(0xFFEF3B4E);
}
