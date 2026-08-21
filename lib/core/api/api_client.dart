import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// The one way the app talks to the AE backend.
///
/// Responsibilities that must not leak into screens:
///  * attaching the bearer token (the AE identity is the token — §7 rule 1)
///  * refreshing it once on a 401 and replaying the original request
///  * turning every failure into an [ApiException] carrying `error.code`
// The token store is held in a private field, which cannot be filled by an
// initializing formal without exposing it as a public parameter name.
// ignore_for_file: prefer_initializing_formals
class ApiClient {
  ApiClient({required TokenStore tokens, Dio? dio})
      : _tokens = tokens,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = Env.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 15)
      // Generous: a field connection is slow, not absent.
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30)
      ..contentType = Headers.jsonContentType
      // Non-2xx is handled below rather than thrown as a transport error.
      ..validateStatus = (_) => true;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.accessToken;
          if (token != null && options.extra['skipAuth'] != true) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokens;

  /// Fired when the session cannot be recovered, so the app can return to Login.
  final _sessionExpired = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  Future<void> dispose() async {
    await _sessionExpired.close();
    _dio.close();
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    String? idempotencyKey,
    bool skipAuth = false,
  }) {
    // §7 rule 5: every create carries a key so a dropped response cannot become
    // a duplicate activation — and a duplicate incentive payment.
    final headers = <String, dynamic>{
      'Idempotency-Key': ?idempotencyKey,
    };
    return _send(
      () => _dio.post(
        path,
        data: body,
        options: Options(headers: headers, extra: {'skipAuth': skipAuth}),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() call, {
    bool allowRefresh = true,
  }) async {
    Response<dynamic> res;
    try {
      res = await call();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException.offline();
      }
      throw ApiException(
        code: 'TRANSPORT_ERROR',
        message: e.message ?? 'Gagal menghubungi server.',
      );
    }

    final status = res.statusCode ?? 0;

    if (status == 401 && allowRefresh) {
      final refreshed = await _refresh();
      if (refreshed) return _send(call, allowRefresh: false);
      _sessionExpired.add(null);
    }

    if (status >= 200 && status < 300) {
      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
      // Every 2xx in the contract returns a JSON object.
      return <String, dynamic>{'data': data};
    }

    throw ApiException.fromResponse(status, res.data);
  }

  /// Exchanges the refresh token for a new access token. Returns false when the
  /// session is genuinely finished, which is the caller's cue to log out.
  Future<bool> _refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) return false;

      final data = (res.data as Map).cast<String, dynamic>();
      final access = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (access == null) return false;

      if (newRefresh != null) {
        await _tokens.save(accessToken: access, refreshToken: newRefresh);
      } else {
        await _tokens.saveAccessToken(access);
      }
      return true;
    } on DioException {
      return false;
    }
  }

  /// Drops null values so an unset filter is simply absent from the query.
  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }
}
