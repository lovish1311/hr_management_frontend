import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final bool isDrawer;
  final Color selectedColor;
  final double selectedBrushSize;
  final StrokeType selectedTool;
  final List<DrawStroke> strokes;
  final Function(DrawStroke stroke)? onStrokeCompleted;

  const DrawingCanvasWidget({
    super.key,
    required this.isDrawer,
    this.selectedColor = const Color(0xFF0F172A),
    this.selectedBrushSize = 4.0,
    this.selectedTool = StrokeType.draw,
    required this.strokes,
    this.onStrokeCompleted,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  final List<DrawPoint> _currentPoints = [];

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (!widget.isDrawer) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    // Normalize coordinates to 0.0 - 1.0 space for resolution independence
    final normX = (localPos.dx / renderBox.size.width).clamp(0.0, 1.0);
    final normY = (localPos.dy / renderBox.size.height).clamp(0.0, 1.0);

    setState(() {
      _currentPoints.clear();
      _currentPoints.add(DrawPoint(x: normX, y: normY));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!widget.isDrawer) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    final normX = (localPos.dx / renderBox.size.width).clamp(0.0, 1.0);
    final normY = (localPos.dy / renderBox.size.height).clamp(0.0, 1.0);

    setState(() {
      _currentPoints.add(DrawPoint(x: normX, y: normY));
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isDrawer || _currentPoints.isEmpty) return;

    final color = widget.selectedTool == StrokeType.erase
        ? const Color(0xFFFFFFFF)
        : widget.selectedColor;

    final stroke = DrawStroke(
      roomCode: '',
      strokeType: widget.selectedTool,
      color: color,
      brushSize: widget.selectedBrushSize,
      points: List.from(_currentPoints),
    );

    widget.onStrokeCompleted?.call(stroke);

    setState(() {
      _currentPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                onPanStart: (d) => _handlePanStart(d, constraints),
                onPanUpdate: (d) => _handlePanUpdate(d, constraints),
                onPanEnd: _handlePanEnd,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CanvasCustomPainter(
                    strokes: widget.strokes,
                    currentPoints: _currentPoints,
                    currentColor: widget.selectedTool == StrokeType.erase
                        ? const Color(0xFFFFFFFF)
                        : widget.selectedColor,
                    currentBrushSize: widget.selectedBrushSize,
                    currentTool: widget.selectedTool,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CanvasCustomPainter extends CustomPainter {
  final List<DrawStroke> strokes;
  final List<DrawPoint> currentPoints;
  final Color currentColor;
  final double currentBrushSize;
  final StrokeType currentTool;

  _CanvasCustomPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentBrushSize,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw committed strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSize
        ..style = PaintingStyle.stroke;

      _renderPoints(canvas, stroke.points, size, paint);
    }

    // Draw current active stroke
    if (currentPoints.isNotEmpty) {
      final activePaint = Paint()
        ..color = currentColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = currentBrushSize
        ..style = PaintingStyle.stroke;

      _renderPoints(canvas, currentPoints, size, activePaint);
    }
  }

  void _renderPoints(Canvas canvas, List<DrawPoint> points, Size size, Paint paint) {
    if (points.length == 1) {
      final p = Offset(points[0].x * size.width, points[0].y * size.height);
      canvas.drawCircle(p, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    final first = Offset(points[0].x * size.width, points[0].y * size.height);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final p1 = Offset(points[i - 1].x * size.width, points[i - 1].y * size.height);
      final p2 = Offset(points[i].x * size.width, points[i].y * size.height);
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }

    final last = Offset(points.last.x * size.width, points.last.y * size.height);
    path.lineTo(last.dx, last.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasCustomPainter oldDelegate) => true;
}
