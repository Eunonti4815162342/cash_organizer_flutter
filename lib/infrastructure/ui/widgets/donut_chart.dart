import 'package:flutter/material.dart';
import 'dart:math';

class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color>? colors; // Ahora opcional para usar los de la paleta global
  final double thickness;

  const DonutChart({
    super.key,
    required this.data,
    this.colors,
    this.thickness = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // Paleta por defecto extendida si no se proporcionan colores
    final List<Color> chartColors = colors ?? [
      const Color(0xFF009FFB), const Color(0xFF27AE60), const Color(0xFFF2994A),
      const Color(0xFFEB5757), const Color(0xFF9B51E0), const Color(0xFF2D9CDB),
      const Color(0xFFF2C94C), const Color(0xFF219653), const Color(0xFF2F80ED),
      const Color(0xFF56CCF2), const Color(0xFFBB6BD9), const Color(0xFF6FCF97),
    ];

    return CustomPaint(
      painter: _DonutPainter(data, chartColors, thickness),
      child: const SizedBox(width: double.infinity, height: double.infinity),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> colors;
  final double thickness;

  _DonutPainter(this.data, this.colors, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - thickness / 2;
    final total = data.values.fold(0.0, (sum, val) => sum + val.abs());

    if (total == 0) return;

    double startAngle = -pi / 2;
    int i = 0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    data.forEach((key, value) {
      final sweepAngle = (value.abs() / total) * 2 * pi;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05, 
        false,
        paint,
      );

      startAngle += sweepAngle;
      i++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
