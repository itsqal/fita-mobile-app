import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/form_fields.dart';
import '../auth/session_controller.dart';
import 'scanner_screen.dart';

/// **Aktivasi Pelanggan** — records a sold unit against a customer.
class ActivationFormScreen extends StatefulWidget {
  const ActivationFormScreen({super.key});

  @override
  State<ActivationFormScreen> createState() => _ActivationFormScreenState();
}

class _ActivationFormScreenState extends State<ActivationFormScreen> {
  final _longLat = TextEditingController();
  final _msisdn = TextEditingController();
  final _location = LocationService();

  List<CustomerOption> _customers = const [];
  bool _customersLoading = true;
  Object? _customersError;

  int? _customerId;
  LocationFix? _fix;
  InventoryItem? _device;
  bool _gpsBusy = false;
  bool _lookupBusy = false;
  String? _lookupMessage;
  bool _submitting = false;
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _longLat.dispose();
    _msisdn.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _customersLoading = true;
      _customersError = null;
    });
    try {
      final list = await context.read<AeRepository>().customerLookup();
      if (!mounted) return;
      setState(() {
        _customers = list;
        _customersLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _customersError = e;
        _customersLoading = false;
      });
    }
  }

  Future<void> _getGps() async {
    setState(() => _gpsBusy = true);
    final result = await _location.getFix();
    if (!mounted) return;
    setState(() => _gpsBusy = false);

    if (result.ok) {
      setState(() {
        _fix = result.fix;
        _longLat.text = result.fix!.display;
      });
      return;
    }

    final failure = result.failure!;
    final needsSettings = failure == LocationFailure.deniedForever ||
        failure == LocationFailure.serviceDisabled;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocationService.describe(failure, accuracyM: result.accuracyM),
        ),
        backgroundColor: Brand.ink,
        duration: const Duration(seconds: 5),
        action: needsSettings
            ? SnackBarAction(
                label: 'Pengaturan',
                textColor: Brand.amber,
                onPressed: () => failure == LocationFailure.serviceDisabled
                    ? _location.openLocationSettings()
                    : _location.openAppSettings(),
              )
            : null,
      ),
    );
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (scanned == null || !mounted) return;
    _msisdn.text = scanned;
    await _lookup(scanned);
  }

  /// Resolves the scanned number to its bundled device and decides whether the
  /// AE may submit at all (§7 rule 4).
  Future<void> _lookup(String msisdn) async {
    setState(() {
      _lookupBusy = true;
      _device = null;
      _lookupMessage = null;
    });

    try {
      final item = await context.read<AeRepository>().lookupMsisdn(msisdn);
      if (!mounted) return;
      setState(() {
        _device = item;
        _lookupBusy = false;
        _lookupMessage =
            item.eligible ? null : IneligibleReason.describe(item.reason);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupBusy = false;
        _lookupMessage = switch (e.code) {
          'NOT_FOUND' => 'Nomor ini tidak terdaftar sebagai nomor FWA.',
          ApiException.offlineCode =>
            'Tidak ada koneksi. Nomor tidak dapat diperiksa.',
          _ => e.message,
        };
      });
    }
  }

  bool get _canSubmit =>
      _customerId != null &&
      _fix != null &&
      _device != null &&
      _device!.eligible &&
      !_submitting;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_canSubmit) return;

    _idempotencyKey ??= AeRepository.newIdempotencyKey();
    setState(() => _submitting = true);

    try {
      await context.read<AeRepository>().createActivation(
            customerId: _customerId!,
            msisdn: _device!.msisdn,
            latitude: _fix!.latitude,
            longitude: _fix!.longitude,
            geoAccuracyM: _fix!.accuracyM,
            isMocked: _fix!.isMocked,
            idempotencyKey: _idempotencyKey,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivasi berhasil dikirim.'),
          backgroundColor: Brand.ink,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = switch (e.code) {
        'MSISDN_ALREADY_ACTIVATED' => 'Nomor ini sudah pernah diaktivasi.',
        'MSISDN_NOT_ALLOCATED' => 'Nomor ini bukan alokasi stok kamu.',
        'CUSTOMER_NOT_OWNED' => 'Customer ini bukan milik kamu.',
        ApiException.offlineCode =>
          'Tidak ada koneksi. Coba lagi saat jaringan kembali.',
        _ => e.message,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Brand.ink),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aeCode = context.watch<SessionController>().aeCode;

    return Scaffold(
      backgroundColor: Brand.surface,
      body: Column(
        children: [
          AppHeader(
            title: 'Aktivasi Pelanggan',
            subtitlePrefix: 'Tambahkan ',
            subtitleBold: 'Aktivasi',
            subtitleSuffix: ' Kamu!',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Insets.page,
                18,
                Insets.page,
                32,
              ),
              children: [
                const FieldLabel('ID AE'),
                DisabledField(value: aeCode),
                const FieldGap(),

                const FieldLabel('ID Customer'),
                _customerDropdown(),
                const FieldGap(),

                const FieldLabel('Long Lat'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _longLat,
                        readOnly: true,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 54,
                      width: 108,
                      child: ElevatedButton(
                        onPressed: _gpsBusy ? null : _getGps,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: _gpsBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('GET GPS'),
                      ),
                    ),
                  ],
                ),
                if (_fix != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Longlat terverifikasi',
                    style: TextStyle(color: Brand.success, fontSize: 13),
                  ),
                ],
                if (_fix != null && _fix!.isMocked) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Lokasi terdeteksi dari aplikasi palsu. Data tetap dikirim '
                    'dan akan ditinjau supervisor.',
                    style: TextStyle(color: Brand.danger, fontSize: 12),
                  ),
                ],
                const FieldGap(),

                const FieldLabel('Scan MSISDN'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _msisdn,
                        readOnly: true,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 54,
                      width: 60,
                      child: ElevatedButton(
                        onPressed: _lookupBusy ? null : _scan,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: _lookupBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            // The asset pack has no barcode icon; the Material
                            // glyph was approved in its place.
                            : const Icon(Icons.barcode_reader,
                                color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
                if (_lookupMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _lookupMessage!,
                    style: const TextStyle(color: Brand.danger, fontSize: 13),
                  ),
                ],
                const FieldGap(),

                const FieldLabel('IMEI'),
                DisabledField(value: _device?.imei ?? ''),
                const FieldGap(),

                const FieldLabel('Tipe Modem'),
                DisabledField(value: _device?.deviceModelCode ?? ''),
                const SizedBox(height: 30),

                Center(
                  child: SizedBox(
                    width: 230,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerDropdown() {
    if (_customersLoading) {
      return const DisabledField(value: '', placeholder: 'Memuat customer...');
    }
    if (_customersError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DisabledField(value: '', placeholder: 'Gagal memuat customer'),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _loadCustomers,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Brand.magenta, fontSize: 13),
            ),
          ),
        ],
      );
    }
    if (_customers.isEmpty) {
      return const DisabledField(
        value: '',
        placeholder: 'Belum ada customer yang bisa diaktivasi',
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _customerId,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Brand.charcoal),
      items: [
        for (final c in _customers)
          DropdownMenuItem(
            value: c.customerId,
            // Server-rendered "{id} - {nama}", used verbatim.
            child: Text(c.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _customerId = v),
    );
  }
}
