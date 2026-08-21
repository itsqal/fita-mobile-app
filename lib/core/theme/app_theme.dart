import 'package:flutter/material.dart';

import 'brand.dart';

/// Radii and spacing read off the mockups. Kept together so the whole app moves
/// as one when a value is tuned.
abstract final class Radii {
  static const field = 8.0;
  static const card = 12.0;
  static const badge = 999.0;
  static const pillButton = 999.0;
}

abstract final class Insets {
  /// Horizontal page margin used by every screen.
  static const page = 20.0;
  static const gutter = 12.0;
}

/// The single typeface for the app.
///
/// The mockups are set in a geometric sans (Poppins family). Until the licensed
/// font files are bundled this resolves to the platform default, which is the
/// one visible difference from the mockups — see the note in the build log.
const String? kFontFamily = null;

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: kFontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Brand.magenta,
      primary: Brand.magenta,
      secondary: Brand.amber,
      surface: Brand.surface,
    ),
    scaffoldBackgroundColor: Brand.surfaceMuted,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Brand.charcoal,
      displayColor: Brand.ink,
    ),

    // Amber primary action — `Kirim`, `Klik Disini`, `GET GPS`, `Masuk`.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Brand.amberDisabled;
          if (states.contains(WidgetState.pressed)) return Brand.amberDark;
          return Brand.amber;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.field)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Brand.surface,
      hintStyle: const TextStyle(color: Brand.textMuted, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: _fieldBorder(Brand.border),
      enabledBorder: _fieldBorder(Brand.border),
      focusedBorder: _fieldBorder(Brand.magenta, width: 1.5),
      disabledBorder: _fieldBorder(Brand.border),
      errorBorder: _fieldBorder(Brand.danger),
      focusedErrorBorder: _fieldBorder(Brand.danger, width: 1.5),
    ),

    cardTheme: CardThemeData(
      color: Brand.surface,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),

    // The amber selection circle in the Date Picker mockup.
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: Brand.surface,
      todayForegroundColor: WidgetStatePropertyAll(Brand.magenta),
      dayForegroundColor: WidgetStatePropertyAll(Brand.ink),
    ),

    dividerTheme: const DividerThemeData(
      color: Brand.border,
      thickness: 1,
      space: 1,
    ),
  );
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.field),
    borderSide: BorderSide(color: color, width: width),
  );
}
