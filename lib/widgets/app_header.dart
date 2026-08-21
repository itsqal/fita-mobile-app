import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// The solid magenta band at the top of every screen except Log-In.
///
/// Each subtitle in the mockups emphasises one span in bold — "Monitor
/// **aktivitas** kamu disini!" — so it is supplied in three parts rather than as
/// one string, keeping the copy verbatim (§6) without markup parsing.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitlePrefix,
    required this.subtitleBold,
    required this.subtitleSuffix,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitlePrefix;
  final String subtitleBold;
  final String subtitleSuffix;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Brand.magenta,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 22,
        left: Insets.page,
        right: Insets.page,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: InkResponse(
                onTap: onBack,
                radius: 22,
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 24),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: subtitlePrefix),
                      TextSpan(
                        text: subtitleBold,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: subtitleSuffix),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
