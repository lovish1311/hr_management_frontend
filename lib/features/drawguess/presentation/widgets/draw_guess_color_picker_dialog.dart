import 'dart:math';
import 'package:flutter/material.dart';

class DrawGuessColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const DrawGuessColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  static Future<Color?> show(BuildContext context, Color currentColor) {
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DrawGuessColorPickerDialog(
        initialColor: currentColor,
        onColorSelected: (c) => Navigator.of(context).pop(c),
      ),
    );
  }

  @override
  State<DrawGuessColorPickerDialog> createState() => _DrawGuessColorPickerDialogState();
}

class _DrawGuessColorPickerDialogState extends State<DrawGuessColorPickerDialog> {
  late double _hue; // 0..360
  late double _saturation; // 0..1
  late double _value; // 0..1
  late Color _currentColor;

  static const List<Color> _presets = [
    Color(0xFFDC2626), // Red
    Color(0xFFEA580C), // Orange
    Color(0xFFF59E0B), // Amber / Yellow
    Color(0xFF10B981), // Emerald Green
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF4F46E5), // Indigo
    Color(0xFF9333EA), // Purple
    Color(0xFFDB2777), // Pink
    Color(0xFF78350F), // Brown
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation.clamp(0.0, 1.0);
    _value = hsv.value.clamp(0.05, 1.0);
  }

  void _updateFromHsv() {
    setState(() {
      _currentColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    });
  }

  void _selectPreset(Color c) {
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _currentColor = c;
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.palette_rounded, color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Color Palette',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Presets
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PRESETS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presets.map((preset) {
                final isSelected = _currentColor.toARGB32() == preset.toARGB32();
                return InkWell(
                  onTap: () => _selectPreset(preset),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: preset,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black12,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: preset.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check, size: 14, color: Colors.white),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // HSV Color Wheel (Interactive Round Selector)
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: _ColorWheel(
                  hue: _hue,
                  saturation: _saturation,
                  onColorChanged: (hue, sat) {
                    setState(() {
                      _hue = hue;
                      _saturation = sat;
                      _updateFromHsv();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Brightness / Value Slider
            Row(
              children: [
                Icon(
                  Icons.brightness_medium_rounded,
                  size: 16,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      activeTrackColor: const Color(0xFF6366F1),
                      inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: _value,
                      min: 0.05,
                      max: 1.0,
                      onChanged: (val) {
                        setState(() {
                          _value = val;
                          _updateFromHsv();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selected Color Preview & Apply Button
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onColorSelected(_currentColor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Color',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorWheel extends StatelessWidget {
  final double hue;
  final double saturation;
  final void Function(double hue, double saturation) onColorChanged;

  const _ColorWheel({
    required this.hue,
    required this.saturation,
    required this.onColorChanged,
  });

  void _handleTouch(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final radius = size.width / 2;

    final dist = sqrt(dx * dx + dy * dy);
    final sat = (dist / radius).clamp(0.0, 1.0);

    var angle = atan2(dy, dx) * 180 / pi;
    if (angle < 0) angle += 360;

    onColorChanged(angle, sat);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanDown: (d) => _handleTouch(d.localPosition, size),
          onPanUpdate: (d) => _handleTouch(d.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _ColorWheelPainter(hue: hue, saturation: saturation),
          ),
        );
      },
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;

  _ColorWheelPainter({required this.hue, required this.saturation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Rainbow Sweep Gradient
    const sweepGradient = SweepGradient(
      colors: [
        Color(0xFFFF0000), // Red 0°
        Color(0xFFFFFF00), // Yellow 60°
        Color(0xFF00FF00), // Green 120°
        Color(0xFF00FFFF), // Cyan 180°
        Color(0xFF0000FF), // Blue 240°
        Color(0xFFFF00FF), // Magenta 300°
        Color(0xFFFF0000), // Red 360°
      ],
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // 2. Radial Gradient for Saturation (Center = white/desaturated, Edge = transparent)
    const radialGradient = RadialGradient(
      colors: [
        Colors.white,
        Colors.transparent,
      ],
      stops: [0.0, 1.0],
    );

    final radialPaint = Paint()
      ..shader = radialGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, radialPaint);

    // 3. Wheel border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Selector Handle / Ring
    final rad = hue * pi / 180;
    final dist = saturation * radius;
    final thumbX = center.dx + dist * cos(rad);
    final thumbY = center.dy + dist * sin(rad);
    final thumbCenter = Offset(thumbX, thumbY);

    // Outer shadow ring
    final outerRingPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(thumbCenter, 9, outerRingPaint);

    // White ring
    final innerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(thumbCenter, 9, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.hue != hue || oldDelegate.saturation != saturation;
  }
}
