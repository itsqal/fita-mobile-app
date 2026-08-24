import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// A headline counter — `Total Aktivasi`, `Insentif`, `New Customer`,
/// `Hot Leads`.
///
/// [valueWidget] replaces the plain numeral for tiles that render something
/// richer — the Insentif tile passes an [IncentiveAmount]. [caption] carries an
/// optional smaller line beneath the value.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.caption,
  }) : assert(value != null || valueWidget != null,
            'a tile needs either a value or a valueWidget');

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? caption;

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Brand.charcoal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          valueWidget ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value!,
                  style: const TextStyle(
                    color: Brand.magenta,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Brand.textMuted, fontSize: 9.5),
            ),
          ],
        ],
      ),
    );
  }
}
