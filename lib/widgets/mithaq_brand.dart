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

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2);
    canvas.scale(scale);

    final framePaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // An elegant mihrab frame contains the shrine silhouette without
    // competing with the central golden dome.
    final outerArch = Path()
      ..moveTo(18, 80)
      ..lineTo(18, 61)
      ..cubicTo(19, 42, 35, 22, 50, 13)
      ..cubicTo(65, 22, 81, 42, 82, 61)
      ..lineTo(82, 80);
    canvas.drawPath(outerArch, framePaint);

    final innerArch = Path()
      ..moveTo(25, 78)
      ..lineTo(25, 62)
      ..cubicTo(27, 45, 39, 31, 50, 24)
      ..cubicTo(61, 31, 73, 45, 75, 62)
      ..lineTo(75, 78);
    canvas.drawPath(
      innerArch,
      Paint()
        ..color = _lightGold.withValues(alpha: .48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Twin minarets: simple, readable silhouettes that remain distinguishable
    // when the same emblem is shown in a small app-bar size.
    final minaretPaint = Paint()..color = _gold;
    final leftMinaret = Path()
      ..moveTo(20, 80)
      ..lineTo(20, 49)
      ..lineTo(23, 49)
      ..lineTo(23, 42)
      ..lineTo(21, 42)
      ..lineTo(27, 34)
      ..lineTo(33, 42)
      ..lineTo(31, 42)
      ..lineTo(31, 49)
      ..lineTo(34, 49)
      ..lineTo(34, 80)
      ..close();
    canvas.drawPath(leftMinaret, minaretPaint);

    final rightMinaret = Path()
      ..moveTo(66, 80)
      ..lineTo(66, 49)
      ..lineTo(69, 49)
      ..lineTo(69, 42)
      ..lineTo(67, 42)
      ..lineTo(73, 34)
      ..lineTo(79, 42)
      ..lineTo(77, 42)
      ..lineTo(77, 49)
      ..lineTo(80, 49)
      ..lineTo(80, 80)
      ..close();
    canvas.drawPath(rightMinaret, minaretPaint);

    final balconyPaint = Paint()
      ..color = _lightGold
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(19, 50), const Offset(35, 50), balconyPaint);
    canvas.drawLine(const Offset(65, 50), const Offset(81, 50), balconyPaint);

    // Lower sanctuary and three door arches.
    final facade = Path()
      ..moveTo(29, 62)
      ..quadraticBezierTo(50, 68, 71, 62)
      ..lineTo(71, 80)
      ..lineTo(29, 80)
      ..close();
    canvas.drawPath(facade, Paint()..color = const Color(0xFFB38A45));

    final doorPaint = Paint()..color = const Color(0xFF0D2B21);
    for (final x in [37.0, 47.0, 57.0]) {
      final door = Path()
        ..moveTo(x, 80)
        ..lineTo(x, 73)
        ..cubicTo(x, 68, x + 6, 68, x + 6, 73)
        ..lineTo(x + 6, 80)
        ..close();
      canvas.drawPath(door, doorPaint);
    }

    // The dome is the focal point: broad, rounded, and filled with a restrained
    // gold gradient rather than the pointed outline of a generic arch.
    final dome = Path()
      ..moveTo(32, 64)
      ..cubicTo(33, 50, 41, 36, 50, 27)
      ..cubicTo(59, 36, 67, 50, 68, 64)
      ..cubicTo(63, 70, 37, 70, 32, 64)
      ..close();
    canvas.drawPath(
      dome,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lightGold, _gold, Color(0xFF8D6A32)],
        ).createShader(const Rect.fromLTWH(31, 26, 38, 44)),
    );
    canvas.drawLine(
      const Offset(50, 31),
      const Offset(50, 64),
      Paint()
        ..color = const Color(0xFFFFE8B5).withValues(alpha: .42)
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      const Offset(32, 65),
      const Offset(68, 65),
      Paint()
        ..color = _lightGold
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // A small crescent marks the crown; it is intentionally understated.
    final crescent = Path()
      ..moveTo(54, 16)
      ..cubicTo(48, 17, 47, 24, 51, 28)
      ..cubicTo(55, 31, 61, 27, 62, 23)
      ..cubicTo(58, 27, 53, 25, 52, 22)
      ..cubicTo(52, 19, 53, 17, 54, 16)
      ..close();
    canvas.drawPath(crescent, Paint()..color = _lightGold);

    canvas.drawPath(
      Path()
        ..moveTo(27, 84)
        ..quadraticBezierTo(50, 90, 73, 84),
      Paint()
        ..color = _gold.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MithaqMarkPainter oldDelegate) => false;
}
