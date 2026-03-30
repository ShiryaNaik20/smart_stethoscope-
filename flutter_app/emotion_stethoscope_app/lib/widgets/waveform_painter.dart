import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> samples;

  WaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF8F8F8),
    );

    final double midY = size.height / 2;

    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 0.8,
    );

    if (samples.isEmpty) return;

    // Find peak of raw int16 values
    double peak = 0;
    for (final s in samples) {
      if (s.abs() > peak) peak = s.abs();
    }
    if (peak < 1) return;

    // Auto-scale so peak always fills 85% of display
    final double gain = (midY * 0.85) / peak;

    final paint = Paint()
      ..color = Colors.red.shade600
      ..strokeWidth = 2.0;

    final double scaleX = size.width / samples.length;

    for (int i = 0; i < samples.length - 1; i++) {
      final double x1 = i * scaleX;
      final double y1 =
          (midY - samples[i] * gain).clamp(0.0, size.height);
      final double x2 = (i + 1) * scaleX;
      final double y2 =
          (midY - samples[i + 1] * gain).clamp(0.0, size.height);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter old) => true;
}