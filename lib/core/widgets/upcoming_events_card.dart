import 'dart:math';
import 'package:flutter/material.dart';

class UpcomingEventsCard extends StatelessWidget {
  const UpcomingEventsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Soft teal/cyan theme matching the mockup
    final cardBgColor = isDark ? const Color(0xFF00363A) : const Color(0xFFE0F7FA);
    final textColor = isDark ? const Color(0xFFB2EBF2) : const Color(0xFF006064);
    final buttonColor = const Color(0xFF00acc1);
    final onButtonColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Upcoming Culture Events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Rich Custom Painter Illustration representing Cake and Balloons
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: CakeAndBalloonsPainter(isDark: isDark),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Co-worker Birthdays ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  const Text(
                    '👀',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Get the co-worker birthdays this week!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: onButtonColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () {},
            child: const Text(
              'Learn more',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class CakeAndBalloonsPainter extends CustomPainter {
  final bool isDark;

  CakeAndBalloonsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);

    // 1. Draw Balloons on Left and Right
    final leftBalloonCenter = Offset(size.width * 0.25, size.height * 0.35);
    final rightBalloonCenter1 = Offset(size.width * 0.70, size.height * 0.32);
    final rightBalloonCenter2 = Offset(size.width * 0.76, size.height * 0.40);

    _drawBalloon(canvas, leftBalloonCenter, Colors.teal, -0.1);
    _drawBalloon(canvas, rightBalloonCenter1, Colors.redAccent, 0.1);
    _drawBalloon(canvas, rightBalloonCenter2, Colors.lightBlueAccent, 0.25);

    // 2. Draw Birthday Cake in the center
    final cakeWidth = 70.0;
    final cakeHeight = 45.0;

    final cakeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: cakeWidth, height: cakeHeight),
      const Radius.circular(8.0),
    );

    // Cake base shadow/plate
    final platePaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, cakeHeight / 2), width: cakeWidth + 24, height: 8),
      platePaint,
    );

    // Cake body
    final cakePaint = Paint()
      ..color = Colors.orangeAccent.shade100
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cakeRect, cakePaint);

    // Frosting/Topping layers
    final frostingPaint = Paint()
      ..color = Colors.pinkAccent.shade100
      ..style = PaintingStyle.fill;
    final frostingRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - cakeWidth / 2, center.dy - cakeHeight / 2, cakeWidth, 12),
      const Radius.circular(4.0),
    );
    canvas.drawRRect(frostingRect, frostingPaint);

    // Cake decorations (stripes)
    final decorationPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx - cakeWidth / 3, center.dy - cakeHeight / 2 + 18),
      Offset(center.dx - cakeWidth / 3, center.dy + cakeHeight / 2 - 4),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - cakeHeight / 2 + 18),
      Offset(center.dx, center.dy + cakeHeight / 2 - 4),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(center.dx + cakeWidth / 3, center.dy - cakeHeight / 2 + 18),
      Offset(center.dx + cakeWidth / 3, center.dy + cakeHeight / 2 - 4),
      decorationPaint,
    );

    // 3. Draw 3 Candles on Top
    final candleWidth = 4.0;
    final candleHeight = 16.0;

    final candlePaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.fill;

    final flamePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final candlePositions = [
      center.dx - 16,
      center.dx,
      center.dx + 16,
    ];

    for (var xPos in candlePositions) {
      final candleTop = center.dy - cakeHeight / 2 - candleHeight;
      // Draw candle body
      canvas.drawRect(
        Rect.fromLTWH(xPos - candleWidth / 2, candleTop, candleWidth, candleHeight),
        candlePaint,
      );

      // Draw flame
      final flamePath = Path()
        ..moveTo(xPos, candleTop - 6)
        ..quadraticBezierTo(xPos - 3, candleTop - 2, xPos, candleTop)
        ..quadraticBezierTo(xPos + 3, candleTop - 2, xPos, candleTop - 6)
        ..close();
      canvas.drawPath(flamePath, flamePaint);
    }
  }

  void _drawBalloon(Canvas canvas, Offset offset, Color color, double angle) {
    // String
    final stringPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black38
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final stringPath = Path()
      ..moveTo(offset.dx, offset.dy + 15)
      ..quadraticBezierTo(offset.dx + (angle * 20), offset.dy + 40, offset.dx - (angle * 5), offset.dy + 65);
    canvas.drawPath(stringPath, stringPaint);

    // Balloon body
    final balloonPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    
    // Draw oval balloon
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 28, height: 36),
      balloonPaint,
    );

    // Balloon knot (small triangle at the bottom)
    final knotPath = Path()
      ..moveTo(0, 18)
      ..lineTo(-3, 22)
      ..lineTo(3, 22)
      ..close();
    canvas.drawPath(knotPath, balloonPaint);

    // Highlight reflection
    final highlightPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, -6), width: 6, height: 10),
      highlightPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
