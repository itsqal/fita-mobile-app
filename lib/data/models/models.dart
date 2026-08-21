/// Domain models, one per schema in openapi.yaml.
///
/// Only fields the AE app actually uses are parsed. Nothing here is invented:
/// if a screen needs something absent from the contract, that is a question for
/// the backend, not a field to synthesise client-side (CLAUDE.md §7).
library;

DateTime? _dt(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v.toString());

class AccountExecutive {
  const AccountExecutive({
    required this.aeId,
    required this.aeCode,
    required this.fullName,
    this.regionName,
  });

  final String aeId;

  /// Shown in the read-only "ID AE" field. Display-only — never sent (§7 rule 1).
  final String aeCode;
  final String fullName;
  final String? regionName;

  factory AccountExecutive.fromJson(Map<String, dynamic> j) => AccountExecutive(
        aeId: (j['aeId'] ?? '').toString(),
        aeCode: (j['aeCode'] ?? '').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        regionName: (j['region'] as Map?)?['regionName']?.toString(),
      );
}

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.profile,
    required this.mustChangePassword,
  });

  final String accessToken;
  final String refreshToken;
  final AccountExecutive profile;

  /// True on first login with an HQ-issued password. No screen exists for this
  /// yet — see the note in the build log.
  final bool mustChangePassword;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        accessToken: (j['accessToken'] ?? '').toString(),
        refreshToken: (j['refreshToken'] ?? '').toString(),
        profile: AccountExecutive.fromJson(
          ((j['profile'] as Map?) ?? const {}).cast<String, dynamic>(),
        ),
        mustChangePassword: j['mustChangePassword'] == true,
      );
}

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    this.verified = false,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracyM;

  /// Server-side verdict — drives the green "Terverifikasi" pill.
  final bool verified;
  final bool isMocked;

  /// The `Long Lat` field's text form.
  String get display =>
      '${longitude.toStringAsFixed(7)}, ${latitude.toStringAsFixed(7)}';

  static GeoPoint? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final lat = (j['latitude'] as num?)?.toDouble();
    final lon = (j['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return GeoPoint(
      latitude: lat,
      longitude: lon,
      accuracyM: (j['accuracyM'] as num?)?.toDouble(),
      verified: j['verified'] == true,
      isMocked: j['isMocked'] == true,
    );
  }
}

/// Wire values for `CustomerStatus`.
abstract final class CustomerStatusWire {
  static const edukasi = 'EDUKASI';
  static const hotLeads = 'HOT_LEADS';
  static const purchase = 'PURCHASE';

  /// Dropdown order, exactly as the Status Customer mockup lists it.
  static const all = [edukasi, hotLeads, purchase];
}

class Customer {
  const Customer({
    required this.customerId,
    required this.fullName,
    required this.phoneNumber,
    required this.status,
    this.address,
    this.visitDate,
    this.geo,
    this.hasActivation = false,
  });

  final int customerId;
  final String fullName;
  final String phoneNumber;
  final String status;
  final String? address;
  final DateTime? visitDate;
  final GeoPoint? geo;
  final bool hasActivation;

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        customerId: (j['customerId'] as num?)?.toInt() ?? 0,
        fullName: (j['fullName'] ?? '').toString(),
        phoneNumber: (j['phoneNumber'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        address: j['address']?.toString(),
        visitDate: _date(j['visitDate']),
        geo: GeoPoint.fromJson((j['geo'] as Map?)?.cast<String, dynamic>()),
        hasActivation: j['hasActivation'] == true,
      );
}

/// One option in the activation form's "ID Customer" dropdown.
class CustomerOption {
  const CustomerOption({
    required this.customerId,
    required this.fullName,
    required this.label,
  });

  final int customerId;
  final String fullName;

  /// Server-rendered `{id} - {nama}`; used verbatim so the app and the backend
  /// never disagree about the format.
  final String label;

  factory CustomerOption.fromJson(Map<String, dynamic> j) => CustomerOption(
        customerId: (j['customerId'] as num?)?.toInt() ?? 0,
        fullName: (j['fullName'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
      );
}

/// Why an MSISDN cannot be activated. Rendered in plain Indonesian rather than
/// letting the submission fail server-side (§7 rule 4).
abstract final class IneligibleReason {
  static const notAllocated = 'NOT_ALLOCATED_TO_YOU';
  static const alreadyActivated = 'ALREADY_ACTIVATED';
  static const blocked = 'BLOCKED';
  static const returned = 'RETURNED';

  static String describe(String? code) => switch (code) {
        notAllocated => 'Nomor ini bukan alokasi stok kamu.',
        alreadyActivated => 'Nomor ini sudah pernah diaktivasi.',
        blocked => 'Nomor ini diblokir.',
        returned => 'Nomor ini sudah dikembalikan ke gudang.',
        _ => 'Nomor ini tidak dapat diaktivasi.',
      };
}

class InventoryItem {
  const InventoryItem({
    required this.msisdn,
    required this.eligible,
    this.imei,
    this.deviceModelCode,
    this.reason,
  });

  final String msisdn;

  /// The flag the submit button is gated on (§7 rule 4).
  final bool eligible;

  /// Display-only. Resolved by the server; never typed or guessed (§7 rule 2).
  final String? imei;
  final String? deviceModelCode;
  final String? reason;

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        msisdn: (j['msisdn'] ?? '').toString(),
        eligible: j['eligible'] == true,
        imei: j['imei']?.toString(),
        deviceModelCode:
            (j['deviceModel'] as Map?)?['modelCode']?.toString() ??
                j['deviceModelCode']?.toString(),
        reason: j['reason']?.toString(),
      );
}

abstract final class ActivationStatusWire {
  static const notActivated = 'NOT_ACTIVATED';
  static const activated = 'ACTIVATED';
  static const failed = 'FAILED';
  static const cancelled = 'CANCELLED';
}

class Activation {
  const Activation({
    required this.activationId,
    required this.msisdn,
    required this.status,
    this.customerId,
    this.customerName,
    this.imei,
    this.deviceModelCode,
    this.geo,
    this.activationDate,
  });

  final int activationId;
  final String msisdn;
  final String status;
  final int? customerId;
  final String? customerName;
  final String? imei;
  final String? deviceModelCode;
  final GeoPoint? geo;

  /// Null until the Gross Add feed confirms. Renders as `-` (§7 rule 7).
  final DateTime? activationDate;

  /// Green badge when the SIM is live, red otherwise.
  bool get isActivated => status == ActivationStatusWire.activated;

  /// The `ID Customer` row on the Daftar Aktivasi card.
  String get customerLabel => customerId == null
      ? '-'
      : '$customerId${customerName == null ? '' : ' - $customerName'}';

  factory Activation.fromJson(Map<String, dynamic> j) {
    final cust = (j['customer'] as Map?)?.cast<String, dynamic>();
    return Activation(
      activationId: (j['activationId'] as num?)?.toInt() ?? 0,
      msisdn: (j['msisdn'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      customerId: (cust?['customerId'] as num?)?.toInt(),
      customerName: cust?['fullName']?.toString(),
      imei: j['imei']?.toString(),
      deviceModelCode: j['deviceModelCode']?.toString(),
      geo: GeoPoint.fromJson((j['geo'] as Map?)?.cast<String, dynamic>()),
      activationDate: _dt(j['activationDate']),
    );
  }
}

class ReportSummary {
  const ReportSummary({
    required this.totalActivations,
    required this.newCustomers,
    required this.hotLeads,
    required this.incentiveIdr,
  });

  final int totalActivations;
  final int newCustomers;
  final int hotLeads;

  /// Whole rupiah. Scaled for display only, in the presentation layer.
  final int incentiveIdr;

  static const empty = ReportSummary(
    totalActivations: 0,
    newCustomers: 0,
    hotLeads: 0,
    incentiveIdr: 0,
  );

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
        totalActivations: (j['totalActivations'] as num?)?.toInt() ?? 0,
        newCustomers: (j['newCustomers'] as num?)?.toInt() ?? 0,
        hotLeads: (j['hotLeads'] as num?)?.toInt() ?? 0,
        incentiveIdr: (j['incentiveIdr'] as num?)?.toInt() ?? 0,
      );
}

class DailyActivity {
  const DailyActivity({
    required this.date,
    required this.activations,
    required this.target,
  });

  final DateTime date;

  /// The magenta bar.
  final int activations;

  /// The grey benchmark bar behind it.
  final int target;

  factory DailyActivity.fromJson(Map<String, dynamic> j) => DailyActivity(
        date: _date(j['date']) ?? DateTime.now(),
        activations: (j['activations'] as num?)?.toInt() ?? 0,
        target: (j['target'] as num?)?.toInt() ?? 0,
      );
}

/// Pagination envelope shared by every list endpoint.
class Paginated<T> {
  const Paginated({required this.items, required this.page, required this.totalPages});

  final List<T> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory Paginated.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = (j['data'] as List?) ?? const [];
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Paginated(
      items: raw
          .whereType<Map>()
          .map((e) => parse(e.cast<String, dynamic>()))
          .toList(),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
