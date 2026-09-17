import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// A white card of label/value rows split by a magenta rule — the unit card
/// used by the scanned-MSISDN list and Alokasi Modem.
class DetailRowsCard extends StatelessWidget {
  const DetailRowsCard({
    super.key,
    required this.rows,
    this.trailing,
    this.hasError = false,
  });

  /// Label and value pairs, top to bottom.
  final List<(String, String)> rows;

  /// Optional control at the top-right, e.g. a remove button.
  final Widget? trailing;

  /// Outlines the card in red when its unit failed to submit.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Radii.field),
        border: hasError
            ? Border.all(color: Brand.danger.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 12, trailing == null ? 16 : 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final r in rows) _CellText(r.$1)],
                    ),
                  ),
                  Container(width: 2, color: Brand.magenta),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final r in rows) _CellText(r.$2)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Brand.charcoal, fontSize: 13.5),
      ),
    );
  }
}
