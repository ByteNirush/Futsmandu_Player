import 'package:flutter/material.dart';

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Halfway line
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
    
    // Centre circle
    canvas.drawCircle(Offset(cx, cy), 55, paint);
    
    // Top box
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, 30), width: 200, height: 60), 
      paint,
    );
    
    // Bottom box
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, size.height - 30), width: 200, height: 60), 
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
