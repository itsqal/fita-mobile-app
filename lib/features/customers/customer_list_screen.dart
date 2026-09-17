import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/format/formatters.dart';
import '../../core/format/msisdn.dart';
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
        for (final c in items) ...[
          const SizedBox(height: 12),
          _CustomerCard(customer: c),
        ],
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final Customer customer;

  Future<void> _call(BuildContext context) =>
      _open(context, Uri(scheme: 'tel', path: customer.phoneNumber),
          'Tidak dapat membuka aplikasi telepon.');

  Future<void> _whatsapp(BuildContext context) {
    // wa.me needs the international form without '+', e.g. 62822...
    final number = Msisdn.normalise(customer.phoneNumber) ??
        customer.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return _open(context, Uri.parse('https://wa.me/$number'),
        'Tidak dapat membuka WhatsApp.');
  }

  Future<void> _open(BuildContext context, Uri uri, String failure) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(failure), backgroundColor: Brand.ink),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = customer.address?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.fullName,
            style: const TextStyle(
              color: Brand.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _IconLine(icon: Icons.phone_outlined, text: customer.phoneNumber),
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.location_on_outlined,
            text: address.isEmpty ? '-' : address,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  customer.visitDate == null
                      ? '-'
                      : Dates.listDate(customer.visitDate!),
                  style: const TextStyle(
                    color: Brand.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              _RoundAction(
                color: Brand.callTeal,
                tooltip: 'Telepon',
                onTap: () => _call(context),
                child: const Icon(Icons.phone_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              _RoundAction(
                color: Brand.whatsappGreen,
                tooltip: 'WhatsApp',
                onTap: () => _whatsapp(context),
                child: SvgPicture.asset(
                  'assets/svg/icons/ic_whatsapp.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, color: Brand.charcoal, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Brand.charcoal,
              fontSize: 13.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 36, height: 36, child: Center(child: child)),
        ),
      ),
    );
  }
}
