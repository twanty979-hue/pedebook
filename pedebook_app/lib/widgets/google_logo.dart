import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Google Blue (#4285F4)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(cx, cy - radius * 0.2)
      ..lineTo(w * 0.96, cy - radius * 0.2)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -0.2,
        1.7,
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Google Green (#34A853)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        1.2,
        1.3,
        false,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Google Yellow (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        2.5,
        1.2,
        false,
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Google Red (#EA4335)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        3.7,
        1.6,
        false,
      )
      ..close();
    canvas.drawPath(redPath, paint);

    // Inner White Cutout to make it a 'G'
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), radius * 0.58, paint);

    // Clear the right mouth opening of G
    final mouthRect = Rect.fromLTRB(cx, cy - radius * 0.2, w * 1.05, cy + radius * 0.4);
    canvas.drawRect(mouthRect, paint);

    // Blue horizontal bar in G
    paint.color = const Color(0xFF4285F4);
    final barRect = Rect.fromLTRB(cx * 0.9, cy - radius * 0.2, w * 0.98, cy + radius * 0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(2)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

