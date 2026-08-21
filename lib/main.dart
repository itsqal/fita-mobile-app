import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/token_store.dart';
import 'core/theme/app_theme.dart';
import 'data/ae_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Indonesian month names are used throughout; without this DateFormat has no
  // symbols for id_ID and throws on first use.
  await initializeDateFormatting('id_ID');

  final tokens = TokenStore();
  final api = ApiClient(tokens: tokens);
  final repo = AeRepository(api);

  runApp(FitaApp(api: api, repo: repo, tokens: tokens));
}

class FitaApp extends StatelessWidget {
  const FitaApp({
    super.key,
    required this.api,
    required this.repo,
    required this.tokens,
  });

  final ApiClient api;
  final AeRepository repo;
  final TokenStore tokens;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AeRepository>.value(value: repo),
        ChangeNotifierProvider(
          create: (_) =>
              SessionController(api: api, repo: repo, tokens: tokens)
                ..bootstrap(),
        ),
      ],
      child: MaterialApp(
        title: 'FITA',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Root(),
      ),
    );
  }
}

/// Shows Login or Home depending on whether a session could be restored.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final status = context.select<SessionController, SessionStatus>(
      (s) => s.status,
    );

    return switch (status) {
      SessionStatus.starting => const _Splash(),
      SessionStatus.signedOut => const LoginScreen(),
      SessionStatus.signedIn => const HomeScreen(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
