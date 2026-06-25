import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _SaefraLogoPainter(),
        ),
        const SizedBox(height: 12),
        Text(
          'saefra.run',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _SaefraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5,
      4.5,
      false,
      paint,
    );

    final innerPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center.translate(-8, 4), radius: radius * 0.65),
      0.8,
      3.5,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
