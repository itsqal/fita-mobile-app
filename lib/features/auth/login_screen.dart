import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/brand.dart';
import 'session_controller.dart';

/// **Log-In** — the entry screen.
///
/// Deliberately unlike the rest of the app: no magenta header band, magenta
/// field labels rather than charcoal, and a pill-shaped button. That is how the
/// mockup draws it.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aeCode = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _aeCode.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<SessionController>().signIn(_aeCode.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      backgroundColor: Brand.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.page,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: SvgPicture.asset(
                    'assets/svg/logo/hifiair-lockup-color.svg',
                    // §5 sets 140 as the floor at which the indosat wordmark
                    // stays legible; the mockup draws it slightly smaller.
                    width: 140,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'FITA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Brand.magenta,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'FWA Interface Transaction Apps',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Brand.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 44),
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    color: Brand.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Silahkan Login terlebih dahulu',
                  style: TextStyle(color: Brand.charcoal, fontSize: 15),
                ),
                const SizedBox(height: 28),
                const _FieldLabel('ID AE'),
                TextFormField(
                  controller: _aeCode,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'AE Code'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'ID AE wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Kata Sandi',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Brand.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Kata sandi wajib diisi.'
                      : null,
                ),
                if (session.error != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(session.error!),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: session.busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    child: session.busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Masuk'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Login labels are magenta — unlike every other form in the app.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Brand.magenta,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Brand.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.field),
        border: Border.all(color: Brand.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Brand.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Brand.danger, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
