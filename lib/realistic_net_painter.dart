// realistic_net_painter.dart

import 'package:flutter/material.dart';

class RealisticNetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    int strings = 7;
    int segments = 8;

    // Draw diagonal strings (left to right)
    for (int i = 0; i < strings; i++) {
      for (int j = 0; j < segments; j++) {
        double t1 = j / segments;
        double t2 = (j + 1) / segments;

        double x1 = _taperedX(i, strings, t1, size.width);
        double x2 = _taperedX(i + 1, strings, t2, size.width);

        double y1 = t1 * size.height;
        double y2 = t2 * size.height;

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }

    // Draw diagonal strings (right to left)
    for (int i = 0; i < strings; i++) {
      for (int j = 0; j < segments; j++) {
        double t1 = j / segments;
        double t2 = (j + 1) / segments;

        double x1 = _taperedX(i + 1, strings, t1, size.width);
        double x2 = _taperedX(i, strings, t2, size.width);

        double y1 = t1 * size.height;
        double y2 = t2 * size.height;

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }
  }

  /// This helps taper the net inward at the bottom for cone effect
  double _taperedX(int i, int total, double t, double width) {
    double x = (i / total) * width;
    double taperFactor = 1 - (t * 0.5); // adjust 0.5 for more/less taper
    return (x - width / 2) * taperFactor + width / 2;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
