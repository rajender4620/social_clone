import 'package:flutter/material.dart';

/// A reusable Pumpkin icon widget that displays our app's custom pumpkin logo
class PumpkinIcon extends StatelessWidget {
  final double size;
  final bool showBackground;
  final Color? backgroundColor;
  final bool showShadow;

  const PumpkinIcon({
    super.key,
    this.size = 60,
    this.showBackground = true,
    this.backgroundColor,
    this.showShadow = false,
  });

  const PumpkinIcon.small({
    super.key,
    this.size = 24,
    this.showBackground = false,
    this.backgroundColor,
    this.showShadow = false,
  });

  const PumpkinIcon.large({
    super.key,
    this.size = 120,
    this.showBackground = true,
    this.backgroundColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground ? BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: showShadow ? [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ) : null,
      child: CustomPaint(
        painter: PumpkinIconPainter(size: size),
        size: Size(size, size),
      ),
    );
  }
}

class PumpkinIconPainter extends CustomPainter {
  final double size;

  PumpkinIconPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final scale = size / 120; // Base design is 120x120

    // Main pumpkin body gradient
    final pumpkinRect = Rect.fromCenter(
      center: center + Offset(0, 5 * scale),
      width: 80 * scale,
      height: 70 * scale,
    );
    
    final pumpkinGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.8,
      colors: [
        const Color(0xFFFF8C42), // Light orange
        const Color(0xFFFF6B35), // Medium orange
        const Color(0xFFE55722), // Dark orange
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    
    paint.shader = pumpkinGradient.createShader(pumpkinRect);

    // Draw main pumpkin body (rounded rectangle)
    final pumpkinPath = Path();
    pumpkinPath.addRRect(
      RRect.fromRectAndRadius(
        pumpkinRect,
        Radius.circular(25 * scale),
      ),
    );
    canvas.drawPath(pumpkinPath, paint);

    // Draw pumpkin ridges
    paint.shader = null;
    paint.color = const Color(0xFFE55722);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5 * scale;

    // Left ridge
    final leftRidge = Path();
    leftRidge.moveTo(center.dx - 20 * scale, center.dy - 15 * scale);
    leftRidge.quadraticBezierTo(
      center.dx - 20 * scale, center.dy - 25 * scale,
      center.dx - 10 * scale, center.dy - 25 * scale,
    );
    leftRidge.lineTo(center.dx - 10 * scale, center.dy + 25 * scale);
    canvas.drawPath(leftRidge, paint);

    // Center ridge
    final centerRidge = Path();
    centerRidge.moveTo(center.dx, center.dy - 15 * scale);
    centerRidge.quadraticBezierTo(
      center.dx, center.dy - 30 * scale,
      center.dx, center.dy - 30 * scale,
    );
    centerRidge.lineTo(center.dx, center.dy + 25 * scale);
    canvas.drawPath(centerRidge, paint);

    // Right ridge
    final rightRidge = Path();
    rightRidge.moveTo(center.dx + 10 * scale, center.dy - 15 * scale);
    rightRidge.quadraticBezierTo(
      center.dx + 10 * scale, center.dy - 25 * scale,
      center.dx + 20 * scale, center.dy - 25 * scale,
    );
    rightRidge.lineTo(center.dx + 20 * scale, center.dy + 25 * scale);
    canvas.drawPath(rightRidge, paint);

    // Draw stem
    paint.style = PaintingStyle.fill;
    final stemGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF4CAF50), // Light green
        const Color(0xFF2E7D32), // Dark green
      ],
    );
    
    final stemRect = Rect.fromCenter(
      center: center + Offset(0, -35 * scale),
      width: 8 * scale,
      height: 12 * scale,
    );
    
    paint.shader = stemGradient.createShader(stemRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        stemRect,
        Radius.circular(4 * scale),
      ),
      paint,
    );

    // Draw leaf
    paint.shader = null;
    paint.color = const Color(0xFF2E7D32);
    final leafPath = Path();
    leafPath.addOval(
      Rect.fromCenter(
        center: center + Offset(6 * scale, -32 * scale),
        width: 8 * scale,
        height: 4 * scale,
      ),
    );
    canvas.drawPath(leafPath, paint);

    // Add highlight for 3D effect
    final highlightGradient = RadialGradient(
      center: const Alignment(-0.4, -0.6),
      radius: 0.6,
      colors: [
        const Color(0xFFFFB74D).withOpacity(0.6),
        const Color(0xFFFFB74D).withOpacity(0.0),
      ],
    );
    
    final highlightRect = Rect.fromCenter(
      center: center + Offset(-15 * scale, -5 * scale),
      width: 30 * scale,
      height: 35 * scale,
    );
    
    paint.shader = highlightGradient.createShader(highlightRect);
    paint.style = PaintingStyle.fill;
    canvas.drawOval(highlightRect, paint);

    // Add small social connection dots
    paint.shader = null;
    paint.style = PaintingStyle.fill;
    
    // Dot 1
    paint.color = const Color(0xFFFF8C42).withOpacity(0.7);
    canvas.drawCircle(
      center + Offset(32 * scale, -20 * scale),
      2 * scale,
      paint,
    );
    
    // Dot 2
    paint.color = const Color(0xFFFF6B35).withOpacity(0.6);
    canvas.drawCircle(
      center + Offset(35 * scale, -5 * scale),
      1.5 * scale,
      paint,
    );
    
    // Dot 3
    paint.color = const Color(0xFFE55722).withOpacity(0.5);
    canvas.drawCircle(
      center + Offset(30 * scale, 8 * scale),
      1 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
