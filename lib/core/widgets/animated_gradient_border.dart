import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final List<Color> borderColors;
  final double borderWidth;
  final double borderRadius;
  final Duration animationDuration;
  final bool isActive;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    required this.borderColors,
    this.borderWidth = 2.5,
    this.borderRadius = 16.0,
    this.animationDuration = const Duration(milliseconds: 2500),
    this.isActive = true,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            colors: widget.borderColors,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            angle: _controller.value * 2 * math.pi,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.all(widget.borderWidth),
        child: widget.child,
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double borderWidth;
  final double borderRadius;
  final double angle;

  _GradientBorderPainter({
    required this.colors,
    required this.borderWidth,
    required this.borderRadius,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = SweepGradient(
        colors: colors.length >= 2
            ? [...colors, colors.first]
            : [Colors.blue, Colors.cyan, Colors.purple, Colors.blue],
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
