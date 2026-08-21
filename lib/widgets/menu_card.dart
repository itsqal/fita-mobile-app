import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// The purpose-drawn menu icons that replace the mockups' emoji placeholders
/// (CLAUDE.md §3). Never substitute anything else for these.
abstract final class MenuIcon {
  static const newCustomer = 'assets/svg/icons/ic_input_new_customer.svg';
  static const hotLeads = 'assets/svg/icons/ic_hot_leads.svg';
  static const customerActivation =
      'assets/svg/icons/ic_customer_activation.svg';
  static const report = 'assets/svg/icons/ic_report.svg';
}

/// A navigation card: icon, magenta title, one-line description, and an amber
/// `Klik Disini` button. Used on Home and Report.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(iconAsset, width: 48, height: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Brand.magenta,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Brand.charcoal,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Klik Disini'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
