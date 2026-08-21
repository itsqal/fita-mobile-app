import 'package:geolocator/geolocator.dart';

import '../config/env.dart';

/// Why a GPS fix could not be taken. Each maps to a distinct thing the AE can
/// actually do about it.
enum LocationFailure {
  serviceDisabled,
  denied,
  deniedForever,
  inaccurate,
  timeout,
  unknown,
}

class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.isMocked,
  });

  final double latitude;
  final double longitude;
  final double accuracyM;

  /// Reported to the server, never used to reject the AE (CLAUDE.md §8).
  final bool isMocked;

  /// The `Long Lat` field's text.
  String get display =>
      '${longitude.toStringAsFixed(7)}, ${latitude.toStringAsFixed(7)}';
}

class LocationResult {
  const LocationResult.success(this.fix)
      : failure = null,
        accuracyM = null;
  const LocationResult.failure(this.failure, {this.accuracyM}) : fix = null;

  final LocationFix? fix;
  final LocationFailure? failure;

  /// Present on [LocationFailure.inaccurate] so the UI can say how far off it is.
  final double? accuracyM;

  bool get ok => fix != null;
}

/// Wraps geolocator so screens deal in [LocationResult] rather than in
/// permission enums and platform exceptions.
class LocationService {
  /// Takes a fix, refusing anything vaguer than [Env.maxGpsAccuracyMetres].
  ///
  /// A coordinate with a 500 m radius is worse than useless for a door-to-door
  /// visit — it looks like data but cannot be acted on.
  Future<LocationResult> getFix() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(LocationFailure.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult.failure(LocationFailure.denied);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (pos.accuracy > Env.maxGpsAccuracyMetres) {
        return LocationResult.failure(
          LocationFailure.inaccurate,
          accuracyM: pos.accuracy,
        );
      }

      return LocationResult.success(
        LocationFix(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracyM: pos.accuracy,
          isMocked: pos.isMocked,
        ),
      );
    } on LocationServiceDisabledException {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    } catch (_) {
      return const LocationResult.failure(LocationFailure.timeout);
    }
  }

  /// Opens the OS settings page so a permanently-denied permission is not a
  /// dead end (CLAUDE.md §8).
  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Indonesian copy for each failure.
  static String describe(LocationFailure f, {double? accuracyM}) =>
      switch (f) {
        LocationFailure.serviceDisabled =>
          'GPS belum aktif. Aktifkan lokasi di pengaturan HP kamu.',
        LocationFailure.denied =>
          'Izin lokasi diperlukan untuk mengambil titik kunjungan.',
        LocationFailure.deniedForever =>
          'Izin lokasi diblokir. Buka pengaturan untuk mengizinkannya.',
        LocationFailure.inaccurate =>
          'Sinyal GPS masih lemah${accuracyM == null ? '' : ' (±${accuracyM.round()} m)'}. '
              'Tunggu sebentar di tempat terbuka lalu coba lagi.',
        LocationFailure.timeout =>
          'Gagal mendapatkan lokasi. Coba lagi di tempat terbuka.',
        LocationFailure.unknown => 'Gagal mendapatkan lokasi.',
      };
}
