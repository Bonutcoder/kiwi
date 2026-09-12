import 'package:flutter/material.dart';

/// Custom Painter to render the Kiwi Bird line art logo and watermark
class KiwiBirdPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  KiwiBirdPainter({
    required this.color,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 100.0;
    final scaleY = size.height / 80.0;

    // Body Path
    final bodyPath = Path();
    bodyPath.moveTo(60 * scaleX, 55 * scaleY);
    bodyPath.cubicTo(
      38 * scaleX, 65 * scaleY,
      12 * scaleX, 50 * scaleY,
      12 * scaleX, 32 * scaleY,
    );
    bodyPath.cubicTo(
      12 * scaleX, 14 * scaleY,
      36 * scaleX, 6 * scaleY,
      56 * scaleX, 11 * scaleY,
    );
    bodyPath.cubicTo(
      70 * scaleX, 14 * scaleY,
      82 * scaleX, 28 * scaleY,
      75 * scaleX, 46 * scaleY,
    );
    bodyPath.cubicTo(
      70 * scaleX, 53 * scaleY,
      65 * scaleX, 54 * scaleY,
      60 * scaleX, 55 * scaleY,
    );
    canvas.drawPath(bodyPath, paint);

    // Eye Dot
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(58 * scaleX, 20 * scaleY),
      2.0 * scaleX,
      eyePaint,
    );

    // Beak Path
    final beakPath = Path();
    beakPath.moveTo(70 * scaleX, 24 * scaleY);
    beakPath.cubicTo(
      82 * scaleX, 27 * scaleY,
      95 * scaleX, 35 * scaleY,
      105 * scaleX, 49 * scaleY,
    );
    canvas.drawPath(beakPath, paint);

    // Wing arc
    final wingPath = Path();
    wingPath.moveTo(25 * scaleX, 30 * scaleY);
    wingPath.cubicTo(
      22 * scaleX, 39 * scaleY,
      30 * scaleX, 46 * scaleY,
      42 * scaleX, 45 * scaleY,
    );
    canvas.drawPath(wingPath, paint);

    // Feet
    final feetPath = Path();
    feetPath.moveTo(35 * scaleX, 55 * scaleY);
    feetPath.lineTo(32 * scaleX, 67 * scaleY);
    feetPath.moveTo(27 * scaleX, 68 * scaleY);
    feetPath.lineTo(37 * scaleX, 66 * scaleY);

    feetPath.moveTo(48 * scaleX, 53 * scaleY);
    feetPath.lineTo(46 * scaleX, 65 * scaleY);
    feetPath.moveTo(42 * scaleX, 66 * scaleY);
    feetPath.lineTo(52 * scaleX, 64 * scaleY);
    canvas.drawPath(feetPath, paint);
  }

  @override
  bool shouldRepaint(covariant KiwiBirdPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
