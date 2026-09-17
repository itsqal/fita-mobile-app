import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_states.dart';
import '../../widgets/detail_rows_card.dart';

/// **Alokasi Modem** — the modems allocated to this AE that are still unsold.
///
/// The mockup's `7 Hari Terakhir` / Filter row is deliberately absent:
/// `/inventory/me` has no date filter or allocation date, so it could not
/// filter anything.
class ModemAllocationScreen extends StatefulWidget {
  const ModemAllocationScreen({super.key});

  @override
  State<ModemAllocationScreen> createState() => _ModemAllocationScreenState();
}

class _ModemAllocationScreenState extends State<ModemAllocationScreen> {
  /// Only stock the AE still holds; activated units are already sold.
  static const _availableStatus = 'ALLOCATED';

  List<InventoryItem>? _items;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context
          .read<AeRepository>()
          .myInventory(status: _availableStatus);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Alokasi Modem',
            subtitlePrefix: 'Lihat ',
            subtitleBold: 'Alokasi Modem',
            subtitleSuffix: ' Milikmu!',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Brand.magenta,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.page,
                  16,
                  Insets.page,
                  28,
                ),
                children: [_body()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState();
    if (_error != null) return ErrorState(error: _error!, onRetry: _load);

    final items = _items ?? const <InventoryItem>[];
    if (items.isEmpty) {
      return const EmptyState(
        message: 'Belum ada modem yang dialokasikan untuk kamu.',
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          DetailRowsCard(
            rows: [
              ('MSISDN', item.msisdn),
              ('IMEI', item.imei ?? '-'),
              ('Tipe Modem', item.deviceModelCode ?? '-'),
              ('Brand', item.brand ?? '-'),
              // Not in the mockup; added on request so AEs can tell 4G and 5G
              // units apart.
              ('Jaringan', item.networkGeneration ?? '-'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
