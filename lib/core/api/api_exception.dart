/// A failure carrying the server's stable `error.code`.
///
/// CLAUDE.md §7 rule 6: branch on the code, never on the message. Messages are
/// free to change wording; codes are contract.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldIssues = const {},
  });

  /// e.g. `MSISDN_NOT_ALLOCATED`, `INVALID_CREDENTIALS`, `INVALID_DATE_RANGE`.
  final String code;

  /// Server-supplied text. Safe to show, but never branch on it.
  final String message;

  final int? statusCode;

  /// From `error.details[]` — field name to issue.
  final Map<String, String> fieldIssues;

  /// The client could not reach the server at all. Submissions that fail this
  /// way belong in the outbox rather than in front of the user as an error.
  bool get isOffline => code == offlineCode;

  static const offlineCode = 'NETWORK_UNAVAILABLE';

  factory ApiException.offline() => ApiException(
        code: offlineCode,
        message: 'Tidak ada koneksi. Data akan dikirim ulang otomatis.',
      );

  factory ApiException.fromResponse(int? status, Object? body) {
    if (body is Map && body['error'] is Map) {
      final err = (body['error'] as Map).cast<String, dynamic>();
      final issues = <String, String>{};
      final details = err['details'];
      if (details is List) {
        for (final d in details) {
          if (d is Map && d['field'] != null) {
            issues[d['field'].toString()] = (d['issue'] ?? '').toString();
          }
        }
      }
      return ApiException(
        code: (err['code'] ?? 'UNKNOWN').toString(),
        message: (err['message'] ?? 'Terjadi kesalahan.').toString(),
        statusCode: status,
        fieldIssues: issues,
      );
    }
    return ApiException(
      code: 'UNKNOWN',
      message: 'Terjadi kesalahan pada server.',
      statusCode: status,
    );
  }

  @override
  String toString() => 'ApiException($code, status=$statusCode): $message';
}
