import 'package:flutter/material.dart';
import 'dart:math';

class CustomBarChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color>? colors; // Lista de colores para cada barra
  final double barWidth;

  const CustomBarChart({
    super.key,
    required this.data,
    this.colors,
    this.barWidth = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> chartColors = colors ?? [
      const Color(0xFF009FFB), const Color(0xFF27AE60), const Color(0xFFF2994A),
      const Color(0xFFEB5757), const Color(0xFF9B51E0), const Color(0xFF2D9CDB),
    ];

    return CustomPaint(
      painter: _BarChartPainter(data, chartColors, barWidth),
      child: const SizedBox(width: double.infinity, height: double.infinity),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> colors;
  final double barWidth;

  _BarChartPainter(this.data, this.colors, this.barWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;

    final maxVal = data.values.map((e) => e.abs()).reduce(max);
    final chartHeight = size.height - 20; 
    final spacing = (size.width - (data.length * barWidth)) / (data.length + 1);

    int i = 0;
    data.forEach((key, value) {
      final x = spacing + (i * (barWidth + spacing));
      final h = (value.abs() / (maxVal == 0 ? 1 : maxVal)) * chartHeight;
      final y = size.height - h;

      paint.color = colors[i % colors.length];

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      
      canvas.drawRRect(rect, paint);

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
