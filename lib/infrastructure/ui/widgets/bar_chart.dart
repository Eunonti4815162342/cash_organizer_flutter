import 'package:flutter/material.dart';
import 'dart:math';

class CustomBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Color barColor;
  final double barWidth;

  const CustomBarChart({
    super.key,
    required this.data,
    this.barColor = const Color(0xFF009FFB),
    this.barWidth = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(data, barColor, barWidth),
      child: const SizedBox(width: double.infinity, height: double.infinity),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color barColor;
  final double barWidth;

  _BarChartPainter(this.data, this.barColor, this.barWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final maxVal = data.values.map((e) => e.abs()).reduce(max);
    final chartHeight = size.height - 20; // Espacio para etiquetas abajo
    final spacing = (size.width - (data.length * barWidth)) / (data.length + 1);

    int i = 0;
    data.forEach((key, value) {
      final x = spacing + (i * (barWidth + spacing));
      final h = (value.abs() / (maxVal == 0 ? 1 : maxVal)) * chartHeight;
      final y = size.height - h;

      // Dibujar barra con bordes redondeados arriba
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      
      canvas.drawRRect(rect, paint);

      // Dibujar etiqueta truncada
      final textPainter = TextPainter(
        text: TextSpan(
          text: key.length > 8 ? '${key.substring(0, 5)}..' : key,
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(canvas, Offset(x + (barWidth / 2) - (textPainter.width / 2), size.height + 4));

      i++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
