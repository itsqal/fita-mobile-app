import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/detail_rows_card.dart';
import '../../widgets/form_fields.dart';
import 'scanner_screen.dart';

/// One scanned, eligible unit waiting to be activated.
class ScannedDevice {
  ScannedDevice(this.item);

  final InventoryItem item;

  /// Created on the first submit and reused on every retry of this MSISDN, so a
  /// dropped response cannot become a duplicate activation (§7 rule 5).
  String? idempotencyKey;

  /// Why the last submit for this MSISDN failed, shown under its card.
  String? error;
}

/// The multi-MSISDN list behind both Input New Customer (Purchase) and
/// Aktivasi Pelanggan.
///
/// The API activates one MSISDN per request, so a list is submitted as a series
/// of `POST /activations`. That is not atomic: some can succeed while others
/// fail. Successful units leave the list; failed ones stay with their reason so
/// the next Kirim retries only those.
class MsisdnScanController extends ChangeNotifier {
  MsisdnScanController(this._repo);

  final AeRepository _repo;
  bool _disposed = false;

  final List<ScannedDevice> _devices = [];
  List<ScannedDevice> get devices => List.unmodifiable(_devices);
  bool get isEmpty => _devices.isEmpty;

  /// The number currently being checked, or the one just rejected.
  String _lastScanned = '';
  String get lastScanned => _lastScanned;

  bool _lookupBusy = false;
  bool get lookupBusy => _lookupBusy;

  /// Why the last scan was not added to the list.
  String? _message;
  String? get message => _message;

  /// Resolves a scanned MSISDN and adds it when the AE may activate it.
  Future<void> add(String msisdn) async {
    if (_devices.any((d) => d.item.msisdn == msisdn)) {
      _lastScanned = msisdn;
      _message = 'Nomor ini sudah ada di daftar.';
      notifyListeners();
      return;
    }

    _lastScanned = msisdn;
    _lookupBusy = true;
    _message = null;
    notifyListeners();

    try {
      final item = await _repo.lookupMsisdn(msisdn);
      if (item.eligible) {
        _devices.add(ScannedDevice(item));
        _lastScanned = '';
      } else {
        // Gate on eligibility before submit, not after (§7 rule 4).
        _message = IneligibleReason.describe(item.reason);
      }
    } on ApiException catch (e) {
      _message = switch (e.code) {
        'NOT_FOUND' => 'Nomor ini tidak terdaftar sebagai nomor FWA.',
        ApiException.offlineCode =>
          'Tidak ada koneksi. Nomor tidak dapat diperiksa.',
        _ => e.message,
      };
    } finally {
      _lookupBusy = false;
      notifyListeners();
    }
  }

  // The screen can close while a lookup or activation is still in flight.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void remove(ScannedDevice device) {
    _devices.remove(device);
    notifyListeners();
  }

  void clear() {
    _devices.clear();
    _lastScanned = '';
    _message = null;
    notifyListeners();
  }

  /// Activates every unit in the list against [customerId]. Returns how many
  /// failed; those stay in the list for a retry.
  Future<int> activateAll({
    required int customerId,
    required LocationFix fix,
  }) async {
    var failed = 0;
    for (final device in List.of(_devices)) {
      device.idempotencyKey ??= AeRepository.newIdempotencyKey();
      try {
        await _repo.createActivation(
          customerId: customerId,
          msisdn: device.item.msisdn,
          latitude: fix.latitude,
          longitude: fix.longitude,
          geoAccuracyM: fix.accuracyM,
          isMocked: fix.isMocked,
          idempotencyKey: device.idempotencyKey,
        );
        _devices.remove(device);
      } on ApiException catch (e) {
        failed++;
        // Branch on the code, never the message (§7 rule 6).
        device.error = switch (e.code) {
          'MSISDN_ALREADY_ACTIVATED' => 'Nomor ini sudah pernah diaktivasi.',
          'MSISDN_NOT_ALLOCATED' => 'Nomor ini bukan alokasi stok kamu.',
          'CUSTOMER_NOT_OWNED' => 'Customer ini bukan milik kamu.',
          ApiException.offlineCode =>
            'Tidak ada koneksi. Kirim ulang saat jaringan kembali.',
          _ => e.message,
        };
      }
      notifyListeners();
    }
    return failed;
  }
}

/// The `Scan MSISDN` field, its scan button, and a card per scanned unit.
class MsisdnScanSection extends StatelessWidget {
  const MsisdnScanSection({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final MsisdnScanController controller;

  /// False while a submission is running, so the list cannot change under it.
  final bool enabled;

  Future<void> _scan(BuildContext context) async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (scanned == null) return;
    await controller.add(scanned);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final busy = controller.lookupBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('Scan MSISDN'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(controller.lastScanned),
                    initialValue: controller.lastScanned,
                    readOnly: true,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 54,
                  width: 60,
                  child: ElevatedButton(
                    onPressed: busy || !enabled ? null : () => _scan(context),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    child: busy
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
            if (controller.message != null) ...[
              const SizedBox(height: 6),
              Text(
                controller.message!,
                style: const TextStyle(color: Brand.danger, fontSize: 13),
              ),
            ],
            for (final device in controller.devices) ...[
              const SizedBox(height: 14),
              _DeviceCard(
                device: device,
                onRemove: enabled ? () => controller.remove(device) : null,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onRemove});

  final ScannedDevice device;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final item = device.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRowsCard(
          rows: [
            ('MSISDN', item.msisdn),
            ('IMEI', item.imei ?? '-'),
            ('Tipe Modem', item.deviceModelCode ?? '-'),
          ],
          hasError: device.error != null,
          trailing: onRemove == null
              ? null
              : IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close,
                      color: Brand.textMuted, size: 18),
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                ),
        ),
        if (device.error != null) ...[
          const SizedBox(height: 6),
          Text(
            device.error!,
            style: const TextStyle(color: Brand.danger, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
