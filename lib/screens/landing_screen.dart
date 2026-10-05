import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/sample_dashboard.dart';
import 'landing_sheets.dart';
import 'login_screen.dart';
import 'pet_code_screen.dart';

/// The app's welcome screen: one screen that fits the phone (no scrolling),
/// buttons pinned at the bottom, everything else a tap away in bottom sheets.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  final _pages = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _intro.dispose();
    _pages.dispose();
    super.dispose();
  }

  // Fade + rise for one band of the screen, staggered over the intro.
  Widget _reveal(double from, double to, Widget child) {
    final curve = CurvedAnimation(
      parent: _intro,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  void _go(Widget Function() screen) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => screen(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
          child: child,
        ),
      ),
    );
  }

  Widget _petCodeScreen() => const PetCodeScreen();
  Widget _loginScreen() => LoginScreen(onPetCode: () => _go(_petCodeScreen));

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(height: pad.top + 28),
              _reveal(0.0, 0.45, const _Brand()),
              Expanded(
                child: _reveal(
                  0.2,
                  0.7,
                  Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pages,
                          clipBehavior: Clip.none,
                          onPageChanged: (i) => setState(() => _page = i),
                          children: const [
                            _CardPage(child: SampleDashboard()),
                            _CardPage(
                              child: _InfoCard(
                                asset: 'assets/images/pet_cat.png',
                                title: 'Never miss a booster',
                                body:
                                    'See how many days your pet is protected and when the next dose is due.',
                              ),
                            ),
                            _CardPage(
                              child: _InfoCard(
                                asset: 'assets/images/pet_dog.png',
                                title: 'Fix mistakes in a tap',
                                body:
                                    'Send a correction request and the office reviews it.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Dots(count: 3, index: _page),
                    ],
                  ),
                ),
              ),
              _reveal(
                0.5,
                1.0,
                _BottomBar(
                  onStart: () => _go(_loginScreen),
                  onCode: () => _go(_petCodeScreen),
                  onLearn: () => showHowItWorksSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Logo, wordmark and tagline.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Brand.gold500, width: 3),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/digivet_logo.png',
              cacheWidth: 200,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'DIGIVET',
          style: TextStyle(
            fontFamily: Brand.serif,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Brand.maroon900,
            letterSpacing: 1,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Your pet’s vaccination records,\nalways within reach.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Brand.inkSoft,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// One carousel page: the card scales down on short screens instead of scrolling.
class _CardPage extends StatelessWidget {
  const _CardPage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: 340, child: child),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.asset,
    required this.title,
    required this.body,
  });
  final String asset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 20),
      decoration: BoxDecoration(
        color: Brand.maroon700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: Brand.serif,
                          fontSize: 24,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(asset, width: 110, cacheWidth: 330),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? Brand.maroon700 : Brand.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onStart,
    required this.onCode,
    required this.onLearn,
  });
  final VoidCallback onStart;
  final VoidCallback onCode;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.maroon700,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onStart,
              child: const Text('Get started'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.maroon700,
                side: const BorderSide(color: Brand.maroon700, width: 1.5),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onCode,
              child: const Text('I have a Pet Code'),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Brand.inkSoft),
            onPressed: onLearn,
            child: const Text('How it works', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
