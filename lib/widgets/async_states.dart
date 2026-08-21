import 'package:flutter/material.dart';

import '../core/api/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// The mockups only ever show a populated screen. CLAUDE.md §8 requires the
/// other three states, drawn in the same visual language.

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.height = 220});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: Brand.magenta),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.height = 240});

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Brand.tintMagenta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: Brand.magenta,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Brand.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.height = 240,
  });

  final Object error;
  final VoidCallback onRetry;
  final double height;

  String get _message {
    final e = error;
    if (e is ApiException) {
      if (e.isOffline) {
        return 'Tidak ada koneksi. Periksa jaringan kamu lalu coba lagi.';
      }
      return e.message;
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiException && (error as ApiException).isOffline;

    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                offline ? Icons.wifi_off_rounded : Icons.error_outline,
                color: Brand.danger,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Brand.charcoal, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.field),
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
