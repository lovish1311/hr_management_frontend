import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class CanvasRasterEngine {
  // High-definition 4:3 raster canvas: 1000x750 provides retina-sharp rendering
  // matching or exceeding device pixel density for crisp, zero-blur fills.
  static const int width = 1000;
  static const int height = 750;

  // Layer 1: Fill colors only (RGBA uint32). Non-filled pixels are 0x00000000 (transparent).
  final Uint32List _fillsBuffer = Uint32List(width * height);

  // Layer 2: Boundary mask for stroke walls (1 = wall, 0 = open area).
  final Uint8List _strokesMask = Uint8List(width * height);

  // Reusable BFS queue for flood fill
  final Int32List _queue = Int32List(width * height);

  CanvasRasterEngine() {
    clear();
  }

  void clear() {
    _fillsBuffer.fillRange(0, _fillsBuffer.length, 0); // 100% transparent
    _strokesMask.fillRange(0, _strokesMask.length, 0); // No walls
  }

  static int colorToRgbaUint32(Color c) {
    final r = (c.r * 255).round().clamp(0, 255);
    final g = (c.g * 255).round().clamp(0, 255);
    final b = (c.b * 255).round().clamp(0, 255);
    // Little-endian memory layout for RGBA8888: byte 0=R, 1=G, 2=B, 3=A
    return r | (g << 8) | (b << 16) | (0xFF << 24);
  }

  void _drawWallDisk(int cx, int cy, int radius) {
    final r = radius <= 0 ? 1 : radius;
    final r2 = r * r;
    final minX = (cx - r).clamp(0, width - 1);
    final maxX = (cx + r).clamp(0, width - 1);
    final minY = (cy - r).clamp(0, height - 1);
    final maxY = (cy + r).clamp(0, height - 1);

    for (int y = minY; y <= maxY; y++) {
      final dy2 = (y - cy) * (y - cy);
      final rowOffset = y * width;
      for (int x = minX; x <= maxX; x++) {
        if ((x - cx) * (x - cx) + dy2 <= r2) {
          _strokesMask[rowOffset + x] = 1;
        }
      }
    }
  }

  void _eraseDisk(int cx, int cy, int radius) {
    final r = radius <= 0 ? 1 : radius;
    final r2 = r * r;
    final minX = (cx - r).clamp(0, width - 1);
    final maxX = (cx + r).clamp(0, width - 1);
    final minY = (cy - r).clamp(0, height - 1);
    final maxY = (cy + r).clamp(0, height - 1);

    for (int y = minY; y <= maxY; y++) {
      final dy2 = (y - cy) * (y - cy);
      final rowOffset = y * width;
      for (int x = minX; x <= maxX; x++) {
        if ((x - cx) * (x - cx) + dy2 <= r2) {
          final idx = rowOffset + x;
          _strokesMask[idx] = 0;
          _fillsBuffer[idx] = 0; // Clear filled color under eraser
        }
      }
    }
  }

  void _drawLine(int x0, int y0, int x1, int y1, int radius, bool isErase) {
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final steps = max(dx, dy);

    if (steps == 0) {
      if (isErase) {
        _eraseDisk(x0, y0, radius);
      } else {
        _drawWallDisk(x0, y0, radius);
      }
      return;
    }

    // Step with stride to ensure seamless overlap while maximizing speed
    final stride = max(1, (radius * 0.75).round());
    final xInc = (x1 - x0) / steps;
    final yInc = (y1 - y0) / steps;

    double currX = x0.toDouble();
    double currY = y0.toDouble();

    for (int i = 0; i <= steps; i += stride) {
      final px = currX.round();
      final py = currY.round();
      if (isErase) {
        _eraseDisk(px, py, radius);
      } else {
        _drawWallDisk(px, py, radius);
      }
      currX += xInc * stride;
      currY += yInc * stride;
    }

    // Ensure ending point is stamped
    if (isErase) {
      _eraseDisk(x1, y1, radius);
    } else {
      _drawWallDisk(x1, y1, radius);
    }
  }

  void floodFill(int startX, int startY, int fillColor) {
    if (startX < 0 || startX >= width || startY < 0 || startY >= height) return;

    int sx = startX;
    int sy = startY;

    // If tapped directly on a stroke line wall, find the nearest non-wall neighbor
    if (_strokesMask[sy * width + sx] == 1) {
      int foundX = -1;
      int foundY = -1;
      for (int dist = 1; dist <= 3 && foundX == -1; dist++) {
        for (int dy = -dist; dy <= dist && foundX == -1; dy++) {
          for (int dx = -dist; dx <= dist; dx++) {
            final nx = sx + dx;
            final ny = sy + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              if (_strokesMask[ny * width + nx] == 0) {
                foundX = nx;
                foundY = ny;
                break;
              }
            }
          }
        }
      }
      if (foundX == -1) return; // Completely surrounded by solid boundary
      sx = foundX;
      sy = foundY;
    }

    final startIdx = sy * width + sx;
    final targetColor = _fillsBuffer[startIdx];
    if (targetColor == fillColor) return;

    int head = 0;
    int tail = 0;

    _queue[tail++] = (sy << 16) | sx;
    _fillsBuffer[startIdx] = fillColor;

    while (head < tail) {
      final val = _queue[head++];
      final cy = val >> 16;
      final cx = val & 0xFFFF;

      // Up
      if (cy > 0) {
        final idx = (cy - 1) * width + cx;
        if (_strokesMask[idx] == 0 && _fillsBuffer[idx] == targetColor) {
          _fillsBuffer[idx] = fillColor;
          _queue[tail++] = ((cy - 1) << 16) | cx;
        }
      }
      // Down
      if (cy < height - 1) {
        final idx = (cy + 1) * width + cx;
        if (_strokesMask[idx] == 0 && _fillsBuffer[idx] == targetColor) {
          _fillsBuffer[idx] = fillColor;
          _queue[tail++] = ((cy + 1) << 16) | cx;
        }
      }
      // Left
      if (cx > 0) {
        final idx = cy * width + (cx - 1);
        if (_strokesMask[idx] == 0 && _fillsBuffer[idx] == targetColor) {
          _fillsBuffer[idx] = fillColor;
          _queue[tail++] = (cy << 16) | (cx - 1);
        }
      }
      // Right
      if (cx < width - 1) {
        final idx = cy * width + (cx + 1);
        if (_strokesMask[idx] == 0 && _fillsBuffer[idx] == targetColor) {
          _fillsBuffer[idx] = fillColor;
          _queue[tail++] = (cy << 16) | (cx + 1);
        }
      }
    }
  }

  void applyStroke(DrawStroke stroke) {
    switch (stroke.strokeType) {
      case StrokeType.clear:
        clear();
        break;

      case StrokeType.fill:
        if (stroke.points.isNotEmpty) {
          final p = stroke.points.first;
          final sx = (p.x * width).round().clamp(0, width - 1);
          final sy = (p.y * height).round().clamp(0, height - 1);
          final fillCol = colorToRgbaUint32(stroke.color);
          floodFill(sx, sy, fillCol);
        }
        break;

      case StrokeType.draw:
      case StrokeType.erase:
        if (stroke.points.isEmpty) break;
        final isErase = stroke.strokeType == StrokeType.erase;
        // In 1000x750 space, scale stroke radius slightly inset (0.75x) so fill
        // reaches under the vector stroke edge, leaving zero white hairline gaps
        final radius = (stroke.brushSize * 0.75).clamp(1.0, 24.0).round();

        if (stroke.points.length == 1) {
          final p = stroke.points.first;
          final px = (p.x * width).round();
          final py = (p.y * height).round();
          if (isErase) {
            _eraseDisk(px, py, radius);
          } else {
            _drawWallDisk(px, py, radius);
          }
        } else {
          for (int i = 1; i < stroke.points.length; i++) {
            final p0 = stroke.points[i - 1];
            final p1 = stroke.points[i];
            _drawLine(
              (p0.x * width).round(),
              (p0.y * height).round(),
              (p1.x * width).round(),
              (p1.y * height).round(),
              radius,
              isErase,
            );
          }
        }
        break;

      default:
        break;
    }
  }

  void renderAllStrokes(List<DrawStroke> strokes, void Function(ui.Image image) onImageReady) {
    clear();
    for (final stroke in strokes) {
      applyStroke(stroke);
    }
    // Only exports the filled color regions with transparency everywhere else.
    // Vector lines are drawn natively on top for pristine skia/impeller GPU sharpness.
    ui.decodeImageFromPixels(
      _fillsBuffer.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      onImageReady,
    );
  }
}
