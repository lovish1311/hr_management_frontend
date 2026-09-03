import 'package:flutter/material.dart';

class UpcomingEventsCard extends StatelessWidget {
  const UpcomingEventsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradientColors = isDark
        ? [const Color(0xFF0F2B3C), const Color(0xFF0D3B4C)]
        : [const Color(0xFFE0F2FE), const Color(0xFFE0F7FA)];

    final primaryTextColor = isDark ? const Color(0xFFF0F9FF) : const Color(0xFF0369A1);
    final secondaryTextColor = isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0284C7);

    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark ? const Color(0xFF1E40AF).withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Culture & Events',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'THIS WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
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
                      color: primaryTextColor,
                    ),
                  ),
                  const Text('🎉', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Celebrate 3 team birthdays & work anniversaries this week!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.celebration_rounded, size: 18),
              label: const Text(
                'View Celebrations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
    const cakeWidth = 70.0;
    const cakeHeight = 45.0;

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
    const candleWidth = 4.0;
    const candleHeight = 16.0;

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
      ..color = color.withValues(alpha: 0.85)
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
