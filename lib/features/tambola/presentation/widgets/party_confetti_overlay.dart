import 'dart:math';
import 'package:flutter/material.dart';

class PartyConfettiOverlay extends StatefulWidget {
  final VoidCallback? onFinished;

  const PartyConfettiOverlay({super.key, this.onFinished});

  @override
  State<PartyConfettiOverlay> createState() => _PartyConfettiOverlayState();
}

class _PartyConfettiOverlayState extends State<PartyConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _initParticles();

    _controller.forward().then((_) {
      if (mounted && widget.onFinished != null) {
        widget.onFinished!();
      }
    });
  }

  void _initParticles() {
    final colors = [
      const Color(0xFFF59E0B), // Amber Gold
      const Color(0xFFEF4444), // Crimson
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
      const Color(0xFFFFD700), // Pure Gold
    ];

    // Generate 90 flying paper confetti particles from dual cannons (left and right bottom/center)
    for (int i = 0; i < 90; i++) {
      final isLeftCannon = i % 2 == 0;
      // Origin: bottom corners or lower mid
      final originX = isLeftCannon ? 0.15 + _random.nextDouble() * 0.15 : 0.70 + _random.nextDouble() * 0.15;
      final originY = 0.85 + _random.nextDouble() * 0.1;

      // Initial velocities
      final angle = isLeftCannon
          ? (-pi * 0.45 + (_random.nextDouble() - 0.5) * 0.6) // Launch up-right
          : (-pi * 0.55 + (_random.nextDouble() - 0.5) * 0.6); // Launch up-left
      final speed = 700 + _random.nextDouble() * 600;

      _particles.add(
        _ConfettiParticle(
          color: colors[_random.nextInt(colors.length)],
          originX: originX,
          originY: originY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          width: 8 + _random.nextDouble() * 8,
          height: 5 + _random.nextDouble() * 10,
          rotationSpeed: (_random.nextDouble() - 0.5) * 12,
          rotationXSpeed: (_random.nextDouble() - 0.5) * 10,
          swayFrequency: 2 + _random.nextDouble() * 4,
          swayAmplitude: 20 + _random.nextDouble() * 40,
          isCircle: _random.nextDouble() < 0.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double originX;
  final double originY;
  final double vx;
  final double vy;
  final double width;
  final double height;
  final double rotationSpeed;
  final double rotationXSpeed;
  final double swayFrequency;
  final double swayAmplitude;
  final bool isCircle;

  _ConfettiParticle({
    required this.color,
    required this.originX,
    required this.originY,
    required this.vx,
    required this.vy,
    required this.width,
    required this.height,
    required this.rotationSpeed,
    required this.rotationXSpeed,
    required this.swayFrequency,
    required this.swayAmplitude,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 4.0; // 4-second timeline
    final opacity = (1.0 - (progress - 0.7).clamp(0.0, 0.3) / 0.3).clamp(0.0, 1.0);

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Physics: Position = Origin + v*t + 0.5*g*t^2 + sway
      final startX = p.originX * size.width;
      final startY = p.originY * size.height;

      // Gravity acceleration
      const gravity = 550.0;
      final x = startX + p.vx * t + sin(t * p.swayFrequency) * p.swayAmplitude;
      final y = startY + p.vy * t + 0.5 * gravity * t * t;

      // Fade & flip calculation
      paint.color = p.color.withValues(alpha: opacity * 0.95);

      final rotationZ = p.rotationSpeed * t;
      final scaleY = cos(p.rotationXSpeed * t).abs().clamp(0.1, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotationZ);
      canvas.scale(1.0, scaleY);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.width / 2, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.width,
          height: p.height,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
        canvas.drawRRect(rrect, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
