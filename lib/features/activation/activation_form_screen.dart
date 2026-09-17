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
import 'msisdn_scan_list.dart';

/// **Aktivasi Pelanggan** — records a sold unit against a customer.
class ActivationFormScreen extends StatefulWidget {
  const ActivationFormScreen({super.key});

  @override
  State<ActivationFormScreen> createState() => _ActivationFormScreenState();
}

class _ActivationFormScreenState extends State<ActivationFormScreen> {
  final _longLat = TextEditingController();
  final _location = LocationService();
  late final MsisdnScanController _scans;

  List<CustomerOption> _customers = const [];
  bool _customersLoading = true;
  Object? _customersError;

  int? _customerId;
  LocationFix? _fix;
  bool _gpsBusy = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scans = MsisdnScanController(context.read<AeRepository>())
      ..addListener(_onScansChanged);
    _loadCustomers();
  }

  // Kirim's enabled state depends on whether the list is empty.
  void _onScansChanged() => setState(() {});

  @override
  void dispose() {
    _longLat.dispose();
    _scans
      ..removeListener(_onScansChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _customersLoading = true;
      _customersError = null;
    });
    try {
      // A customer may hold several activations, so ones already activated
      // must stay selectable.
      final list = await context
          .read<AeRepository>()
          .customerLookup(excludeActivated: false);
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

  bool get _canSubmit =>
      _customerId != null && _fix != null && !_scans.isEmpty && !_submitting;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_canSubmit) return;

    final total = _scans.devices.length;
    setState(() => _submitting = true);
    final failed = await _scans.activateAll(
      customerId: _customerId!,
      fix: _fix!,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (failed == 0) {
      _toast('Aktivasi berhasil dikirim.');
      Navigator.of(context).pop(true);
      return;
    }
    // Successful units have left the list; the failed ones stay for a retry.
    _toast('${total - failed} dari $total aktivasi berhasil. '
        'Periksa nomor yang gagal lalu kirim ulang.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Brand.ink),
    );
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

                MsisdnScanSection(
                  controller: _scans,
                  enabled: !_submitting,
                ),
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
