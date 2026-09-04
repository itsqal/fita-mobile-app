import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/period.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_states.dart';
import '../../widgets/incentive_amount.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/period_filter_row.dart';
import '../../widgets/stat_tile.dart';
import '../activation/activation_form_screen.dart';
import '../auth/session_controller.dart';
import '../customers/customer_form_screen.dart';
import '../report/report_screen.dart';
import 'activity_chart.dart';
import 'activity_series.dart';

/// **Halo, {nama}!** — the dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Period _period = Period.d7;

  ReportSummary? _summary;
  List<DailyActivity>? _days;
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
    final repo = context.read<AeRepository>();
    try {
      final results = await Future.wait([
        repo.reportSummary(period: _period.wire),
        repo.dailyActivity(period: _period.wire),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as ReportSummary;
        _days = results[1] as List<DailyActivity>;
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

  void _setPeriod(Period p) {
    setState(() => _period = p);
    _load();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    // A new customer or activation changes the counters behind this screen.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Halo, ${session.greetingName}!',
            subtitlePrefix: 'Monitor ',
            subtitleBold: 'aktivitas',
            subtitleSuffix: ' kamu disini!',
            trailing: IconButton(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
              tooltip: 'Keluar',
            ),
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
                children: [
                  PeriodFilterRow(period: _period, onChanged: _setPeriod),
                  const SizedBox(height: 16),
                  _body(),
                  const SizedBox(height: 20),
                  MenuCard(
                    iconAsset: MenuIcon.newCustomer,
                    title: 'New Customer',
                    description: 'Catat prospek baru langsung dari lapangan',
                    onTap: () => _open(const CustomerFormScreen()),
                  ),
                  const SizedBox(height: 14),
                  MenuCard(
                    iconAsset: MenuIcon.customerActivation,
                    title: 'Aktivasi Pelanggan',
                    description: 'Scan MSISDN dan aktifkan unit pelanggan',
                    onTap: () => _open(const ActivationFormScreen()),
                  ),
                  const SizedBox(height: 14),
                  MenuCard(
                    iconAsset: MenuIcon.report,
                    title: 'Report',
                    description: 'Pantau performa dan riwayat aktivitas kamu',
                    onTap: () => _open(const ReportScreen()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState(height: 300);
    if (_error != null) {
      return ErrorState(error: _error!, onRetry: _load);
    }

    final summary = _summary ?? ReportSummary.empty;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Brand.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Grafik Aktivasi',
                  style: TextStyle(
                    color: Brand.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ActivityChart(
                bars: buildActivitySeries(_days ?? const [], _period.grouping),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Total Aktivasi',
                value: '${summary.totalActivations}',
              ),
            ),
            const SizedBox(width: Insets.gutter),
            Expanded(
              child: StatTile(
                label: 'Insentif',
                valueWidget:
                    IncentiveAmount(rupiah: summary.incentiveIdr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Brand.surface,
        title: const Text('Keluar'),
        content: const Text('Kamu yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Brand.charcoal)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar', style: TextStyle(color: Brand.magenta)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<SessionController>().signOut();
    }
  }
}
