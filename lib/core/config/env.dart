/// Build-time configuration.
///
/// The API host is chosen at compile time so a shipped build cannot be pointed
/// at a development server by accident.
///
///   Emulator (default):  flutter run
///   Physical handset:    flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/v1
///   Production:          flutter build apk --release --dart-define=ENV=prod
abstract final class Env {
  /// `dev` (default) or `prod`.
  static const _flavour = String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isProduction => _flavour == 'prod';

  /// The live deployed backend.
  static const _prodBaseUrl = 'https://api.fwa-business.site/v1';

  /// The local dev server.
  ///
  /// Defaults to the Android emulator's alias for the host machine: inside an
  /// emulator `127.0.0.1` is the emulator itself, so the dev server on the host
  /// is only reachable as `10.0.2.2`. A physical handset needs the host's LAN
  /// address passed in via --dart-define instead.
  static const _devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/v1',
  );

  /// The AE backend, including the `/v1` prefix every route sits behind.
  static String get apiBaseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;

  /// Rejected above this radius: a fix vaguer than this records a useless
  /// coordinate for a door-to-door visit (CLAUDE.md §8).
  static const maxGpsAccuracyMetres = 100.0;

  /// The Insentif tile shows whole rupiah divided by this, under the caption
  /// "Ratus Ribu Rupiah" (CLAUDE.md §7 rule 8).
  static const incentiveDisplayDivisor = 100000;
}
