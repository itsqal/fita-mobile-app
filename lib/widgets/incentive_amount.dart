import 'package:flutter/material.dart';

import '../core/format/formatters.dart';
import '../core/theme/brand.dart';

/// The **Insentif** figure, e-wallet style: a lighter `Rp` sitting against the
/// full amount in bold — `Rp135.000` — instead of the old scaled `242` under a
/// "Ratus Ribu Rupiah" caption.
///
/// The tile it sits in is only half the page wide, so the type size steps down
/// as the amount grows and a [FittedBox] guarantees the rest: a nine-digit
/// incentive shrinks to fit rather than overflowing or wrapping.
class IncentiveAmount extends StatelessWidget {
  const IncentiveAmount({super.key, required this.rupiah});

  /// Whole rupiah, straight off the wire.
  final int rupiah;

  @override
  Widget build(BuildContext context) {
    final text = Money.rupiah(rupiah);

    // Step down by magnitude first so a large number stays crisp rather than
    // being squashed by FittedBox alone.
    final size = switch (text.length) {
      <= 7 => 30.0, // up to 999.999
      <= 9 => 26.0, // millions
      <= 11 => 21.0, // tens of millions
      _ => 18.0,
    };

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Rp',
              style: TextStyle(
                color: Brand.magenta,
                fontSize: size * 0.62,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                color: Brand.magenta,
                fontSize: size,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.1),
      ),
    );
  }
}
