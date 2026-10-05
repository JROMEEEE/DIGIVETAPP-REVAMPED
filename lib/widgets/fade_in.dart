import 'package:flutter/material.dart';

/// Fades and lifts its child in shortly after it first appears; [index]
/// staggers a column of sections. Skipped when the system asks for reduced
/// animation.
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, this.index = 0, required this.child});

  final int index;
  final Widget child;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 90 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
