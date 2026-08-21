import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/token_store.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';

enum SessionStatus { starting, signedOut, signedIn }

/// Holds who is signed in. The AE code it exposes is what fills the read-only
/// "ID AE" field on both input forms.
class SessionController extends ChangeNotifier {
  SessionController({
    required ApiClient api,
    required AeRepository repo,
    required TokenStore tokens,
  })  // ignore_for_file: prefer_initializing_formals
      : _api = api,
        _repo = repo,
        _tokens = tokens {
    _expirySub = _api.onSessionExpired.listen((_) => _forceSignOut());
  }

  final ApiClient _api;
  final AeRepository _repo;
  final TokenStore _tokens;
  late final StreamSubscription<void> _expirySub;

  SessionStatus _status = SessionStatus.starting;
  SessionStatus get status => _status;

  AccountExecutive? _profile;
  AccountExecutive? get profile => _profile;

  /// "ID AE" — display-only, never sent to the server (§7 rule 1).
  String get aeCode => _profile?.aeCode ?? '';

  /// First name only, for the "Halo, {nama}!" header.
  String get greetingName {
    final full = _profile?.fullName.trim() ?? '';
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first;
  }

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  /// True when the AE logged in with an HQ-issued password.
  ///
  /// No change-password screen has been approved, so this is surfaced for
  /// reporting only and does not block the AE.
  bool mustChangePassword = false;

  /// Restores a previous session on cold start.
  Future<void> bootstrap() async {
    await _tokens.load();
    if (!await _tokens.hasSession) {
      _set(SessionStatus.signedOut);
      return;
    }
    try {
      _profile = await _repo.me();
      _set(SessionStatus.signedIn);
    } on ApiException {
      // An unusable stored session is the same as no session.
      await _tokens.clear();
      _set(SessionStatus.signedOut);
    }
  }

  Future<bool> signIn(String aeCode, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.login(
        aeCode: aeCode.trim(),
        password: password,
        deviceLabel: defaultTargetPlatform.name,
      );
      await _tokens.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _profile = result.profile;
      mustChangePassword = result.mustChangePassword;
      _busy = false;
      _set(SessionStatus.signedIn);
      return true;
    } on ApiException catch (e) {
      // Branch on the code, never the message (§7 rule 6).
      _error = switch (e.code) {
        'INVALID_CREDENTIALS' => 'ID AE atau kata sandi salah.',
        'RATE_LIMITED' ||
        'TOO_MANY_REQUESTS' =>
          'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
        ApiException.offlineCode => 'Tidak ada koneksi. Periksa jaringan kamu.',
        _ => e.message,
      };
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repo.logout();
    } on ApiException {
      // Logging out locally matters more than telling the server about it.
    }
    await _tokens.clear();
    _profile = null;
    _set(SessionStatus.signedOut);
  }

  Future<void> _forceSignOut() async {
    await _tokens.clear();
    _profile = null;
    _set(SessionStatus.signedOut);
  }

  void _set(SessionStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _expirySub.cancel();
    super.dispose();
  }
}
