import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format/formatters.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/form_fields.dart';
import '../activation/msisdn_scan_list.dart';
import '../auth/session_controller.dart';

/// **Input New Customer** — registers a prospect the AE just met.
class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _longLat = TextEditingController();
  final _location = LocationService();
  late final MsisdnScanController _scans;

  DateTime? _visitDate;
  String? _status;
  LocationFix? _fix;
  bool _gpsBusy = false;
  bool _submitting = false;

  /// Generated once per submission attempt and reused across retries, so a
  /// dropped response cannot create a duplicate (§7 rule 5).
  String? _idempotencyKey;

  /// Set once the customer is saved. A Purchase whose activations partly fail
  /// is retried without creating the customer a second time.
  int? _savedCustomerId;

  final _random = Random();

  /// Stands in for reverse geocoding, which the app has no API for yet.
  static const _placeholderAddresses = [
    'Jl. Sudirman Kav. 45, RT 003/RW 002, Kelurahan Karet Semanggi, Kecamatan Setiabudi, Jakarta Selatan, DKI Jakarta 12930',
    'Jl. Kemang Raya No. 88, RT 007/RW 004, Kelurahan Bangka, Kecamatan Mampang Prapatan, Jakarta Selatan, DKI Jakarta 12730',
    'Jl. Gajah Mada No. 123, RT 002/RW 001, Kelurahan Petojo Utara, Kecamatan Gambir, Jakarta Pusat, DKI Jakarta 10130',
    'Jl. Kelapa Gading Boulevard No. 56, RT 010/RW 006, Kelurahan Kelapa Gading Barat, Kecamatan Kelapa Gading, Jakarta Utara, DKI Jakarta 14240',
    'Jl. Panjang No. 200, RT 005/RW 003, Kelurahan Kedoya Utara, Kecamatan Kebon Jeruk, Jakarta Barat, DKI Jakarta 11520',
  ];

  @override
  void initState() {
    super.initState();
    _scans = MsisdnScanController(context.read<AeRepository>())
      ..addListener(_onScansChanged);
  }

  // Kirim's enabled state depends on whether the list is empty.
  void _onScansChanged() => setState(() {});

  bool get _isPurchase => _status == CustomerStatusWire.purchase;

  @override
  void dispose() {
    _scans
      ..removeListener(_onScansChanged)
      ..dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _longLat.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? now,
      // A visit cannot be in the future, and back-dating past a season is a
      // typo rather than an intent.
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _visitDate = picked);
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
        // Only fill an empty field, so a second GET GPS never wipes what the
        // AE typed or corrected.
        if (_address.text.trim().isEmpty) {
          _address.text = _placeholderAddresses[
              _random.nextInt(_placeholderAddresses.length)];
        }
      });
      return;
    }

    final failure = result.failure!;
    _showGpsProblem(failure, result.accuracyM);
  }

  void _showGpsProblem(LocationFailure failure, double? accuracyM) {
    final message = LocationService.describe(failure, accuracyM: accuracyM);
    final needsSettings = failure == LocationFailure.deniedForever ||
        failure == LocationFailure.serviceDisabled;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_visitDate == null) {
      _toast('Tanggal Pergi wajib diisi.');
      return;
    }
    if (_fix == null) {
      _toast('Ambil titik lokasi dengan tombol GET GPS terlebih dahulu.');
      return;
    }
    if (_status == null) {
      _toast('Status Customer wajib dipilih.');
      return;
    }

    if (_isPurchase && _scans.isEmpty) {
      _toast('Scan minimal satu MSISDN untuk status Purchase.');
      return;
    }

    setState(() => _submitting = true);

    if (_savedCustomerId == null) {
      _idempotencyKey ??= AeRepository.newIdempotencyKey();
      try {
        final customer = await context.read<AeRepository>().createCustomer(
              visitDate: _visitDate!,
              fullName: _name.text.trim(),
              phoneNumber: _phone.text.trim(),
              address: _address.text.trim(),
              latitude: _fix!.latitude,
              longitude: _fix!.longitude,
              geoAccuracyM: _fix!.accuracyM,
              isMocked: _fix!.isMocked,
              status: _status!,
              idempotencyKey: _idempotencyKey,
            );
        _savedCustomerId = customer.customerId;
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _submitting = false);
        // Branch on the code, never the message (§7 rule 6).
        final message = switch (e.code) {
          'DUPLICATE_PHONE_NUMBER' || 'CUSTOMER_ALREADY_EXISTS' =>
            'Nomor handphone ini sudah pernah kamu daftarkan.',
          ApiException.offlineCode =>
            'Tidak ada koneksi. Coba lagi saat jaringan kembali.',
          _ => e.message,
        };
        _toast(message);
        return;
      }
    }

    if (_isPurchase) {
      final total = _scans.devices.length;
      final failed = await _scans.activateAll(
        customerId: _savedCustomerId!,
        fix: _fix!,
      );
      if (!mounted) return;
      if (failed > 0) {
        setState(() => _submitting = false);
        _toast('Customer tersimpan, tetapi $failed dari $total aktivasi '
            'gagal. Periksa nomor yang gagal lalu kirim ulang.');
        return;
      }
    }

    if (!mounted) return;
    _toast('Customer berhasil ditambahkan.');
    Navigator.of(context).pop(true);
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
            title: 'Input New Customer',
            subtitlePrefix: 'Tambahkan ',
            subtitleBold: 'Customer',
            subtitleSuffix: ' Kamu Disini!',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
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

                  const FieldLabel('Tanggal Pergi'),
                  _DateField(
                    value: _visitDate,
                    onTap: _pickDate,
                  ),
                  const FieldGap(),

                  const FieldLabel('Nama Customer'),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama Customer wajib diisi.'
                        : null,
                  ),
                  const FieldGap(),

                  const FieldLabel('Nomor Handphone Customer'),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                    validator: _validatePhone,
                  ),
                  const FieldGap(),

                  const FieldLabel('Long Lat'),
                  _LongLatRow(
                    controller: _longLat,
                    busy: _gpsBusy,
                    onPressed: _getGps,
                  ),
                  if (_fix != null && _fix!.isMocked) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Lokasi terdeteksi dari aplikasi palsu. Data tetap dikirim '
                      'dan akan ditinjau supervisor.',
                      style: TextStyle(color: Brand.danger, fontSize: 12),
                    ),
                  ],
                  const FieldGap(),

                  // Below Long Lat so GET GPS runs first and can fill it.
                  const FieldLabel('Alamat Customer'),
                  TextFormField(
                    controller: _address,
                    maxLines: 3,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Alamat Customer wajib diisi.'
                        : null,
                  ),
                  const FieldGap(),

                  const FieldLabel('Status Customer'),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Brand.charcoal),
                    items: [
                      for (final s in CustomerStatusWire.all)
                        DropdownMenuItem(
                          value: s,
                          child: Text(StatusLabels.customer(s)),
                        ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (v) {
                            setState(() => _status = v);
                            // Hidden scans must not be submitted.
                            if (v != CustomerStatusWire.purchase) {
                              _scans.clear();
                            }
                          },
                    validator: (v) =>
                        v == null ? 'Status Customer wajib dipilih.' : null,
                  ),
                  if (_isPurchase) ...[
                    const FieldGap(),
                    MsisdnScanSection(
                      controller: _scans,
                      enabled: !_submitting,
                    ),
                  ],
                  const SizedBox(height: 30),

                  Center(
                    child: SizedBox(
                      width: 230,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _submitting || (_isPurchase && _scans.isEmpty)
                            ? null
                            : _submit,
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
          ),
        ],
      ),
    );
  }

  String? _validatePhone(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Nomor Handphone wajib diisi.';
    // Mirrors the contract's CustomerCreate pattern: ^(62|0)[0-9]{8,13}$
    if (!RegExp(r'^(62|0)[0-9]{8,13}$').hasMatch(value)) {
      return 'Nomor tidak valid. Contoh: 082234567890.';
    }
    return null;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.field),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value == null ? '' : Dates.fieldDate(value!),
              style: const TextStyle(color: Brand.charcoal, fontSize: 15),
            ),
            const Icon(Icons.calendar_month, color: Brand.amber, size: 22),
          ],
        ),
      ),
    );
  }
}

class _LongLatRow extends StatelessWidget {
  const _LongLatRow({
    required this.controller,
    required this.busy,
    required this.onPressed,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            // Filled by GET GPS; typing a coordinate by hand defeats the
            // accuracy gate.
            readOnly: true,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 54,
          width: 108,
          child: ElevatedButton(
            onPressed: busy ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: busy
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
    );
  }
}
