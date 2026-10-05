import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The "protection dial": a ring showing how much of a pet's protection
/// window is left. It sweeps in from empty the first time it appears.
class ProtectionRing extends StatelessWidget {
  const ProtectionRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.size,
    this.stroke = 6,
    this.child,
  });

  final double fraction; // 0..1
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : fraction, end: fraction),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value, color, stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.stroke);
  final double fraction;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.16);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.stroke != stroke;
}
