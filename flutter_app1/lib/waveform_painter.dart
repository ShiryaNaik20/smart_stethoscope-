import 'package:flutter/material.dart';
import 'dart:math';

class WaveformPainter extends CustomPainter {
  final List<double> samples;

  WaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (samples.isEmpty) return;

    double midY = size.height / 2;
    double widthPerSample = size.width / samples.length;

    // Dynamic scaling
    double maxAbs = samples.map((e) => e.abs()).reduce(max);
    if (maxAbs == 0) maxAbs = 1;

    for (int i = 0; i < samples.length - 1; i++) {
      double y1 = midY - (samples[i] / maxAbs) * midY * 0.9;
      double y2 = midY - (samples[i + 1] / maxAbs) * midY * 0.9;

      canvas.drawLine(
        Offset(i * widthPerSample, y1),
        Offset((i + 1) * widthPerSample, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
