import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';

class ViewfinderOverlay extends StatelessWidget {
  const ViewfinderOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 288,
        height: 192,
        child: CustomPaint(
          painter: _BracketsPainter(),
        ),
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  const _BracketsPainter();

  static const _bracketSize = 32.0;
  static const _strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    const r = Radius.circular(8);

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, _bracketSize)
        ..arcToPoint(
          const Offset(_bracketSize, 0),
          radius: r,
          clockwise: false,
        ),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - _bracketSize, 0)
        ..arcToPoint(
          Offset(size.width, _bracketSize),
          radius: r,
        ),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(_bracketSize, size.height)
        ..arcToPoint(
          Offset(0, size.height - _bracketSize),
          radius: r,
        ),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - _bracketSize)
        ..arcToPoint(
          Offset(size.width - _bracketSize, size.height),
          radius: r,
          clockwise: false,
        ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
