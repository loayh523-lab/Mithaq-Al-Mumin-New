import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Compact, resolution-independent brand mark for the Mithaq Al-Mumin app.
class MithaqBrandMark extends StatelessWidget {
  const MithaqBrandMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF165744), Color(0xFF071713), Color(0xFF0D2B21)],
          ),
          border: Border.all(color: const Color(0xFFD9B66D), width: size * .018),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF020806).withValues(alpha: .28),
              blurRadius: size * .12,
              offset: Offset(0, size * .04),
            ),
          ],
        ),
        child: CustomPaint(
          painter: const _MithaqMarkPainter(),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _MithaqMarkPainter extends CustomPainter {
  const _MithaqMarkPainter();

  static const _gold = Color(0xFFD9B66D);
  static const _lightGold = Color(0xFFF5D99A);
  static const _green = Color(0xFF0C3025);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2);
    canvas.scale(scale);

    final archPaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerArch = Path()
      ..moveTo(18, 78)
      ..lineTo(18, 61)
      ..cubicTo(19, 43, 34, 23, 50, 13)
      ..cubicTo(66, 23, 81, 43, 82, 61)
      ..lineTo(82, 78);
    canvas.drawPath(outerArch, archPaint);

    final innerArch = Path()
      ..moveTo(29, 76)
      ..lineTo(29, 61)
      ..cubicTo(31, 47, 41, 34, 50, 28)
      ..cubicTo(59, 34, 69, 47, 71, 61)
      ..lineTo(71, 76);
    canvas.drawPath(
      innerArch,
      Paint()
        ..color = _lightGold.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round,
    );

    final dome = Path()
      ..moveTo(36, 73)
      ..cubicTo(37, 61, 42, 53, 50, 46)
      ..cubicTo(58, 53, 63, 61, 64, 73)
      ..cubicTo(60, 79, 40, 79, 36, 73)
      ..close();
    canvas.drawPath(dome, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_lightGold, _gold, Color(0xFF8D6A32)],
    ).createShader(const Rect.fromLTWH(34, 45, 32, 35)));

    canvas.drawLine(
      const Offset(50, 48),
      const Offset(50, 72),
      Paint()
        ..color = const Color(0xFFFFE8B5).withValues(alpha: .5)
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      Path()
        ..moveTo(29, 78)
        ..quadraticBezierTo(50, 84, 71, 78),
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    final crescent = Path()
      ..moveTo(54, 17)
      ..cubicTo(48, 17, 46, 25, 51, 28)
      ..cubicTo(55, 30, 59, 27, 60, 24)
      ..cubicTo(56, 27, 51, 25, 51, 21)
      ..cubicTo(51, 19, 52, 18, 54, 17)
      ..close();
    canvas.drawPath(crescent, Paint()..color = _lightGold);
    canvas.drawCircle(
      const Offset(50, 30),
      1.8,
      Paint()..color = _gold,
    );

    // A quiet baseline keeps the mark grounded at small launcher sizes.
    canvas.drawLine(
      const Offset(23, 84),
      const Offset(77, 84),
      Paint()
        ..color = _gold.withValues(alpha: .32)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MithaqMarkPainter oldDelegate) => false;
}
