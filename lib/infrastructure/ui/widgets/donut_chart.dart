import 'package:flutter/material.dart';
import 'dart:math';

class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> colors;
  final double thickness;

  const DonutChart({
    super.key,
    required this.data,
    this.colors = const [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal],
    this.thickness = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(data, colors, thickness),
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
        sweepAngle - 0.05, // Pequeño espacio entre segmentos
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
