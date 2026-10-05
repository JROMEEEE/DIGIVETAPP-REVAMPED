import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Shown while the app asks the server whether the saved session is still
/// valid. If the server can't be reached it says so and offers Retry.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _error = null);
    try {
      await AuthService.instance.checkSession();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Brand.gold500, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/digivet_logo.png',
                      cacheWidth: 240,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'DIGIVET',
                  style: TextStyle(
                    fontFamily: Brand.serif,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Brand.maroon900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 28),
                if (_error == null)
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Brand.maroon700,
                    ),
                  )
                else ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Brand.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.maroon700,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _check,
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
