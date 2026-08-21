import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth tokens in the platform keystore.
///
/// Refresh tokens are long-lived credentials for a sales account; they do not
/// belong in shared preferences.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      // 10.3.1 encrypts with its own ciphers by default; the old
      // encryptedSharedPreferences flag is deprecated and ignored, so passing
      // it would be misleading rather than protective.
      //
      // Pinned to 10.x deliberately: 11.x requires compileSdk 37, which the
      // Android SDK only publishes as "android-37.0" — a name the Flutter
      // Gradle plugin cannot resolve.
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  String? _cachedAccess;

  /// Kept in memory so the request interceptor does not hit the keystore on
  /// every call — that adds up on a low-end device.
  String? get accessToken => _cachedAccess;

  Future<void> load() async {
    _cachedAccess = await _storage.read(key: _kAccess);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccess = accessToken;
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    _cachedAccess = accessToken;
    await _storage.write(key: _kAccess, value: accessToken);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<bool> get hasSession async =>
      (await _storage.read(key: _kRefresh)) != null;
}
