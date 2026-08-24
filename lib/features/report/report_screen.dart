import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_states.dart';
import '../../widgets/incentive_amount.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/stat_tile.dart';
import '../activation/activation_list_screen.dart';
import '../customers/customer_list_screen.dart';

/// **Report** — four counters and links to the three list screens.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportSummary? _summary;
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
      final s = await context.read<AeRepository>().reportSummary();
      if (!mounted) return;
      setState(() {
        _summary = s;
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

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Report',
            subtitlePrefix: 'Lihat ',
            subtitleBold: 'Riwayat Pencatatan',
            subtitleSuffix: ' Kamu!',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Brand.magenta,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.page,
                  18,
                  Insets.page,
                  28,
                ),
                children: [
                  _tiles(),
                  const SizedBox(height: 20),
                  MenuCard(
                    iconAsset: MenuIcon.newCustomer,
                    title: 'Daftar New Customer',
                    description:
                        'AE dapat melihat daftar New Customer yang telah didaftarkan',
                    onTap: () =>
                        _open(const CustomerListScreen.newCustomers()),
                  ),
                  const SizedBox(height: 14),
                  MenuCard(
                    iconAsset: MenuIcon.customerActivation,
                    title: 'Daftar Aktivasi Pelanggan',
                    description:
                        'AE dapat melihat daftar Aktivasi Pelanggan yang telah dibuat',
                    onTap: () => _open(const ActivationListScreen()),
                  ),
                  const SizedBox(height: 14),
                  MenuCard(
                    iconAsset: MenuIcon.hotLeads,
                    title: 'Daftar Hot Leads',
                    description: 'AE dapat melihat daftar Hot Leads Customer',
                    onTap: () => _open(const CustomerListScreen.hotLeads()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tiles() {
    if (_loading) return const LoadingState(height: 210);
    if (_error != null) {
      return ErrorState(error: _error!, onRetry: _load, height: 210);
    }

    final s = _summary ?? ReportSummary.empty;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Total Aktivasi',
                value: '${s.totalActivations}',
              ),
            ),
            const SizedBox(width: Insets.gutter),
            Expanded(
              child: StatTile(
                label: 'Insentif',
                valueWidget: IncentiveAmount(rupiah: s.incentiveIdr),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.gutter),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'New Customer',
                value: '${s.newCustomers}',
              ),
            ),
            const SizedBox(width: Insets.gutter),
            Expanded(
              child: StatTile(label: 'Hot Leads', value: '${s.hotLeads}'),
            ),
          ],
        ),
      ],
    );
  }
}
