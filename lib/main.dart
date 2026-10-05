import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/reminder_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DigivetApp());
  // Not awaited: the app must start even if Firebase is slow or unavailable.
  PushService.instance.init();
  ReminderService.instance.init();
}

class DigivetApp extends StatelessWidget {
  const DigivetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIGIVET',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: PushService.instance.messengerKey,
      theme: buildTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Picks the root screen from the session state: splash while checking the
/// saved session, the owner home when signed in, the welcome screen otherwise.
/// Signing out (or the server ending the session) drops back to the welcome
/// screen from anywhere.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final screen = switch (AuthService.instance.status) {
          AuthStatus.checking => const SplashScreen(),
          AuthStatus.signedIn => const HomeShell(),
          AuthStatus.signedOut => const LandingScreen(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(AuthService.instance.status),
            child: screen,
          ),
        );
      },
    );
  }
}
