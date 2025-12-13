import 'package:flutter/material.dart';

class SelectionBoxPainter extends CustomPainter {
  final Offset? start;
  final Offset? end;

  SelectionBoxPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;

    final rect = Rect.fromPoints(start!, end!);

    // 1. Draw the semi-transparent blue fill
    final paintFill = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paintFill);

    // 2. Draw the solid blue border
    final paintStroke = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paintStroke);
  }

  @override
  bool shouldRepaint(covariant SelectionBoxPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}
