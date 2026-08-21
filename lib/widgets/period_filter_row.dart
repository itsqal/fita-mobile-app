import 'package:flutter/material.dart';

import '../core/period.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// The `7 Hari Terakhir` / `Filter` row that sits above the chart on Home and
/// above every list.
class PeriodFilterRow extends StatelessWidget {
  const PeriodFilterRow({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final Period period;
  final ValueChanged<Period> onChanged;

  Future<void> _openFilter(BuildContext context) async {
    final chosen = await showModalBottomSheet<Period>(
      context: context,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Brand.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final p in Period.values)
              ListTile(
                title: Text(
                  p.label,
                  style: TextStyle(
                    color: p == period ? Brand.magenta : Brand.ink,
                    fontWeight:
                        p == period ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: p == period
                    ? const Icon(Icons.check, color: Brand.magenta, size: 20)
                    : null,
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != period) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period.label,
            style: const TextStyle(color: Brand.textMuted, fontSize: 13.5),
          ),
          InkWell(
            onTap: () => _openFilter(context),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: Brand.magenta, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: Brand.magenta,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
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
}
