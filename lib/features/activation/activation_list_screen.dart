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

/// **Daftar Aktivasi** — one card per submitted activation.
class ActivationListScreen extends StatefulWidget {
  const ActivationListScreen({super.key});

  @override
  State<ActivationListScreen> createState() => _ActivationListScreenState();
}

class _ActivationListScreenState extends State<ActivationListScreen> {
  Period _period = Period.d7;
  List<Activation>? _items;
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
      final page =
          await context.read<AeRepository>().activations(period: _period.wire);
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
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Daftar Aktivasi',
            subtitlePrefix: 'Lihat ',
            subtitleBold: 'Daftar Aktivasi Pelanggan',
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
                  const SizedBox(height: 14),
                  _body(),
                ],
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

    final items = _items ?? const <Activation>[];
    if (items.isEmpty) {
      return const EmptyState(
        message: 'Belum ada aktivasi pada periode ini.',
      );
    }

    return Column(
      children: [
        for (final a in items) ...[
          _ActivationCard(activation: a),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ActivationCard extends StatelessWidget {
  const _ActivationCard({required this.activation});

  final Activation activation;

  @override
  Widget build(BuildContext context) {
    final a = activation;

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${a.activationId}',
                style: const TextStyle(
                  color: Brand.magenta,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _StatusBadge(activated: a.isActivated),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Label('ID Customer'),
                      _Label('Longlat'),
                      _Label('MSISDN'),
                      _Label('IMEI'),
                      _Label('Tipe Modem'),
                      _Label('Activation Date'),
                    ],
                  ),
                ),
                // The magenta rule down the left of the detail block.
                Container(width: 2, color: Brand.magenta),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Value(a.customerLabel),
                      SizedBox(
                        height: _rowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: a.geo?.verified == true
                              ? const _VerifiedPill()
                              : const Text(
                                  '-',
                                  style: TextStyle(
                                    color: Brand.charcoal,
                                    fontSize: 13.5,
                                  ),
                                ),
                        ),
                      ),
                      _Value(a.msisdn),
                      _Value(a.imei ?? '-'),
                      _Value(a.deviceModelCode ?? '-'),
                      // Null until the Gross Add feed confirms (§7 rule 7).
                      _Value(Dates.listDateOrDash(a.activationDate)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared row height keeps the label and value columns aligned.
const double _rowHeight = 26;

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(color: Brand.charcoal, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Brand.ink, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Brand.success,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: const Text(
        'Terverifikasi',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.activated});

  final bool activated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: activated ? Brand.success : Brand.danger,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        activated ? 'Activated' : 'Not Activated',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
