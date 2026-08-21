import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format/formatters.dart';
import '../../core/period.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import '../../data/ae_repository.dart';
import '../../data/models/models.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_states.dart';
import '../../widgets/period_filter_row.dart';

/// **Daftar New Customer** and **Daftar Hot Leads**.
///
/// One screen: §4.7 says Hot Leads is structurally identical to New Customer,
/// differing only by the status filter and its header copy.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen.newCustomers({super.key}) : hotLeadsOnly = false;
  const CustomerListScreen.hotLeads({super.key}) : hotLeadsOnly = true;

  final bool hotLeadsOnly;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  Period _period = Period.d7;
  List<Customer>? _items;
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
      final page = widget.hotLeadsOnly
          ? await repo.hotLeads(period: _period.wire)
          : await repo.customers(period: _period.wire);
      if (!mounted) return;
      setState(() {
        _items = page.items;
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

  @override
  Widget build(BuildContext context) {
    final hot = widget.hotLeadsOnly;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: hot ? 'Daftar Hot Leads' : 'Daftar New Customer',
            subtitlePrefix: 'Lihat ',
            subtitleBold: hot ? 'Daftar Hot Leads' : 'New Customer',
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
                  16,
                  Insets.page,
                  28,
                ),
                children: [
                  PeriodFilterRow(period: _period, onChanged: _setPeriod),
                  const SizedBox(height: 8),
                  _body(hot),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(bool hot) {
    if (_loading) return const LoadingState();
    if (_error != null) return ErrorState(error: _error!, onRetry: _load);

    final items = _items ?? const <Customer>[];
    if (items.isEmpty) {
      return EmptyState(
        message: hot
            ? 'Belum ada Hot Leads pada periode ini.'
            : 'Belum ada New Customer pada periode ini.',
      );
    }

    return Column(
      children: [
        for (final c in items) _CustomerRow(customer: c),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Brand.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${customer.customerId}',
                style: const TextStyle(
                  color: Brand.magenta,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                customer.visitDate == null
                    ? '-'
                    : Dates.listDate(customer.visitDate!),
                style: const TextStyle(color: Brand.charcoal, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // The mockups render this second line as `Nama;Nomor;Status`.
          Text(
            '${customer.fullName};${customer.phoneNumber};'
            '${StatusLabels.customer(customer.status)}',
            style: const TextStyle(color: Brand.charcoal, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
