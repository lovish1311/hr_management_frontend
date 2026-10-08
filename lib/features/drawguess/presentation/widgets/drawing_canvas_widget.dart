import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';
import 'canvas_raster_engine.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final bool isDrawer;
  final Color selectedColor;
  final double selectedBrushSize;
  final StrokeType selectedTool;
  final List<DrawStroke> strokes;
  final int canvasResetEpoch;
  final Function(DrawStroke stroke)? onStrokeCompleted;

  const DrawingCanvasWidget({
    super.key,
    required this.isDrawer,
    this.selectedColor = const Color(0xFF0F172A),
    this.selectedBrushSize = 4.0,
    this.selectedTool = StrokeType.draw,
    required this.strokes,
    this.canvasResetEpoch = 0,
    this.onStrokeCompleted,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  final CanvasRasterEngine _rasterEngine = CanvasRasterEngine();
  ui.Image? _bakedImage;

  final List<DrawPoint> _currentPoints = [];
  int _lastStreamTimestamp = 0;
  int _streamStartIndex = 0;
  String? _currentStrokeId;

  int _rasterRenderToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.strokes.any((s) => s.strokeType == StrokeType.fill)) {
      _rebuildRasterForFills();
    }
  }

  @override
  void didUpdateWidget(covariant DrawingCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When canvas reset epoch advances or strokes are cleared, immediately wipe state
    if (widget.canvasResetEpoch != oldWidget.canvasResetEpoch || widget.strokes.isEmpty) {
      _rasterRenderToken++;
      _bakedImage = null;
      _rasterEngine.clear();
      _currentPoints.clear();
      final hasFill = widget.strokes.any((s) => s.strokeType == StrokeType.fill);
      if (hasFill) {
        _rebuildRasterForFills();
      }
      return;
    }

    // If there is any fill stroke, ensure raster is up to date
    final hasFill = widget.strokes.any((s) => s.strokeType == StrokeType.fill);
    final hadFill = oldWidget.strokes.any((s) => s.strokeType == StrokeType.fill);

    if (!hasFill) {
      if (hadFill || _bakedImage != null) {
        _rasterRenderToken++;
        _bakedImage = null;
        _rasterEngine.clear();
      }
    } else if (!hadFill || widget.strokes.length != oldWidget.strokes.length) {
      _rebuildRasterForFills();
    }
  }

  void _rebuildRasterForFills() {
    final currentToken = ++_rasterRenderToken;
    _rasterEngine.renderAllStrokes(widget.strokes, (img) {
      if (mounted && _rasterRenderToken == currentToken) {
        final stillHasFill = widget.strokes.any((s) => s.strokeType == StrokeType.fill);
        if (stillHasFill) {
          setState(() {
            _bakedImage = img;
          });
        }
      }
    });
  }

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (!widget.isDrawer) return;

    final normX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final normY = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);

    // If Fill tool is active: emit a fill stroke immediately on tap/touch!
    if (widget.selectedTool == StrokeType.fill) {
      final fillStroke = DrawStroke(
        strokeId: DateTime.now().microsecondsSinceEpoch.toString(),
        roomCode: '',
        strokeType: StrokeType.fill,
        color: widget.selectedColor,
        brushSize: 1.0,
        points: [DrawPoint(x: normX, y: normY)],
      );
      widget.onStrokeCompleted?.call(fillStroke);
      return;
    }

    _currentStrokeId = DateTime.now().microsecondsSinceEpoch.toString();
    _lastStreamTimestamp = DateTime.now().millisecondsSinceEpoch;
    _streamStartIndex = 0;

    setState(() {
      _currentPoints.clear();
      _currentPoints.add(DrawPoint(x: normX, y: normY));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!widget.isDrawer || widget.selectedTool == StrokeType.fill) return;

    final normX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final normY = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);

    setState(() {
      _currentPoints.add(DrawPoint(x: normX, y: normY));
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    // Stream segments every 35ms (~28 fps) if at least 2 points exist
    if (now - _lastStreamTimestamp >= 35 && _currentPoints.length - _streamStartIndex >= 2) {
      _lastStreamTimestamp = now;
      final segmentPoints = _currentPoints.sublist(_streamStartIndex);
      final color = widget.selectedTool == StrokeType.erase
          ? const Color(0xFFFFFFFF)
          : widget.selectedColor;

      final segmentStroke = DrawStroke(
        strokeId: _currentStrokeId,
        roomCode: '',
        strokeType: widget.selectedTool,
        color: color,
        brushSize: widget.selectedBrushSize,
        points: List.from(segmentPoints),
      );

      widget.onStrokeCompleted?.call(segmentStroke);
      _streamStartIndex = _currentPoints.length - 1; // overlap by 1 point for continuous curve
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isDrawer || widget.selectedTool == StrokeType.fill || _currentPoints.isEmpty) return;

    if (_streamStartIndex < _currentPoints.length - 1) {
      final remaining = _currentPoints.sublist(_streamStartIndex);
      final color = widget.selectedTool == StrokeType.erase
          ? const Color(0xFFFFFFFF)
          : widget.selectedColor;

      final finalStroke = DrawStroke(
        strokeId: _currentStrokeId,
        roomCode: '',
        strokeType: widget.selectedTool,
        color: color,
        brushSize: widget.selectedBrushSize,
        points: List.from(remaining),
      );
      widget.onStrokeCompleted?.call(finalStroke);
    } else if (_currentPoints.length == 1 && _streamStartIndex == 0) {
      // Single tap dot
      final color = widget.selectedTool == StrokeType.erase
          ? const Color(0xFFFFFFFF)
          : widget.selectedColor;
      final dotStroke = DrawStroke(
        strokeId: _currentStrokeId,
        roomCode: '',
        strokeType: widget.selectedTool,
        color: color,
        brushSize: widget.selectedBrushSize,
        points: List.from(_currentPoints),
      );
      widget.onStrokeCompleted?.call(dotStroke);
    }

    setState(() {
      _currentPoints.clear();
      _streamStartIndex = 0;
      _currentStrokeId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: AspectRatio(
        aspectRatio: 4 / 3, // Standard 4:3 canvas matching 400x300 raster engine
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
                    bakedImage: _bakedImage,
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
  final ui.Image? bakedImage;
  final List<DrawStroke> strokes;
  final List<DrawPoint> currentPoints;
  final Color currentColor;
  final double currentBrushSize;
  final StrokeType currentTool;

  _CanvasCustomPainter({
    required this.bakedImage,
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentBrushSize,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Clean crisp white canvas background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Paint baked fills (if bucket fill used) with high bicubic filter quality
    if (bakedImage != null) {
      final src = Rect.fromLTWH(0, 0, bakedImage!.width.toDouble(), bakedImage!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      final fillPaint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(bakedImage!, src, dst, fillPaint);
    }

    // 2. ALWAYS paint completed vector strokes!
    // Instant GPU-accelerated rendering on every frame as soon as strokes arrive
    for (final stroke in strokes) {
      if (stroke.points.isEmpty || stroke.strokeType == StrokeType.fill) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSize
        ..style = PaintingStyle.stroke;

      _renderPoints(canvas, stroke.points, size, paint);
    }

    // 2. Draw current active stroke with vector path for instant 60fps responsiveness
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
    if (points.isEmpty) return;
    if (points.length == 1) {
      final p = Offset(points[0].x * size.width, points[0].y * size.height);
      canvas.drawCircle(p, paint.strokeWidth / 2, Paint()..color = paint.color..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    final first = Offset(points[0].x * size.width, points[0].y * size.height);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final p = Offset(points[i].x * size.width, points[i].y * size.height);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasCustomPainter oldDelegate) => true;
}
