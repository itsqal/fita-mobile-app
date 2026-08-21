import 'package:uuid/uuid.dart';

import '../core/api/api_client.dart';
import '../core/format/formatters.dart';
import 'models/models.dart';

/// Every call the AE app makes, one method per row of CLAUDE.md §7's
/// screen-to-endpoint table. Screens talk to this, never to [ApiClient].
class AeRepository {
  AeRepository(this._api);

  final ApiClient _api;
  static const _uuid = Uuid();

  // --- Auth -----------------------------------------------------------------

  Future<AuthResult> login({
    required String aeCode,
    required String password,
    String? deviceLabel,
  }) async {
    final json = await _api.post(
      '/auth/login',
      skipAuth: true,
      body: {
        'aeCode': aeCode,
        'password': password,
        'deviceLabel': ?deviceLabel,
      },
    );
    return AuthResult.fromJson(json);
  }

  Future<AccountExecutive> me() async =>
      AccountExecutive.fromJson(await _api.get('/me'));

  Future<void> logout() async {
    await _api.post('/auth/logout');
  }

  // --- Reports --------------------------------------------------------------

  Future<ReportSummary> reportSummary({String period = '7d'}) async {
    final json = await _api.get('/reports/summary', query: {'period': period});
    final data = (json['data'] as Map?)?.cast<String, dynamic>();
    return data == null ? ReportSummary.empty : ReportSummary.fromJson(data);
  }

  Future<List<DailyActivity>> dailyActivity({String period = '7d'}) async {
    final json =
        await _api.get('/reports/daily-activity', query: {'period': period});
    return ((json['data'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => DailyActivity.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  // --- Customers ------------------------------------------------------------

  Future<Paginated<Customer>> customers({
    String period = '7d',
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _api.get('/customers', query: {
      'period': period,
      'status': ?status,
      'page': page,
      'perPage': perPage,
    });
    return Paginated.fromJson(json, Customer.fromJson);
  }

  /// Daftar Hot Leads is the customer list filtered to one status.
  Future<Paginated<Customer>> hotLeads({
    String period = '7d',
    int page = 1,
  }) =>
      customers(period: period, status: CustomerStatusWire.hotLeads, page: page);

  /// Registers a prospect. `aeId` is never sent — the server takes it from the
  /// token (§7 rule 1).
  ///
  /// [idempotencyKey] must be generated once when the AE taps Kirim and reused
  /// on every retry of that same submission (§7 rule 5).
  Future<Customer> createCustomer({
    required DateTime visitDate,
    required String fullName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
    required String status,
    double? geoAccuracyM,
    bool isMocked = false,
    String? idempotencyKey,
  }) async {
    final json = await _api.post(
      '/customers',
      idempotencyKey: idempotencyKey ?? newIdempotencyKey(),
      body: {
        'visitDate': Dates.apiDate(visitDate),
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'geoAccuracyM': ?geoAccuracyM,
        'isMocked': isMocked,
        'status': status,
        'deviceTime': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return Customer.fromJson(json);
  }

  Future<List<CustomerOption>> customerLookup({
    String? q,
    bool excludeActivated = true,
    int limit = 50,
  }) async {
    final json = await _api.get('/customers/lookup', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      'excludeActivated': excludeActivated,
      'limit': limit,
    });
    return ((json['data'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => CustomerOption.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  // --- Inventory / activations ---------------------------------------------

  /// Resolves a scanned barcode. [msisdn] must already be in `62` form.
  Future<InventoryItem> lookupMsisdn(String msisdn) async =>
      InventoryItem.fromJson(await _api.get('/inventory/msisdn/$msisdn'));

  Future<Paginated<Activation>> activations({
    String period = '7d',
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _api.get('/activations', query: {
      'period': period,
      'page': page,
      'perPage': perPage,
    });
    return Paginated.fromJson(json, Activation.fromJson);
  }

  /// Submits an activation. IMEI and modem type are deliberately absent — the
  /// server resolves them from the MSISDN (§7 rule 2).
  Future<Activation> createActivation({
    required int customerId,
    required String msisdn,
    required double latitude,
    required double longitude,
    double? geoAccuracyM,
    bool isMocked = false,
    String? idempotencyKey,
  }) async {
    final json = await _api.post(
      '/activations',
      idempotencyKey: idempotencyKey ?? newIdempotencyKey(),
      body: {
        'customerId': customerId,
        'msisdn': msisdn,
        'latitude': latitude,
        'longitude': longitude,
        'geoAccuracyM': ?geoAccuracyM,
        'isMocked': isMocked,
        'deviceTime': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return Activation.fromJson(json);
  }

  static String newIdempotencyKey() => _uuid.v4();
}
