import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class DrawingToolbarWidget extends StatelessWidget {
  final Color selectedColor;
  final double selectedBrushSize;
  final StrokeType selectedTool;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<StrokeType>? onToolChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  const DrawingToolbarWidget({
    super.key,
    required this.selectedColor,
    required this.selectedBrushSize,
    this.selectedTool = StrokeType.draw,
    required this.onColorChanged,
    required this.onBrushSizeChanged,
    this.onToolChanged,
    required this.onUndo,
    required this.onClear,
  });

  static const List<Color> _palette = [
    Color(0xFF0F172A), // Black / Charcoal
    Color(0xFF64748B), // Slate Gray
    Color(0xFFDC2626), // Red
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Amber
    Color(0xFF059669), // Emerald Green
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF4F46E5), // Indigo
    Color(0xFF9333EA), // Purple
    Color(0xFFDB2777), // Pink
    Color(0xFF78350F), // Brown
  ];

  static const List<double> _sizes = [2.0, 4.0, 8.0, 16.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fixed In Front (Left): Undo & Delete All
          _buildActionButton(
            context: context,
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onTap: onUndo,
          ),
          const SizedBox(width: 6),
          _buildActionButton(
            context: context,
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete All',
            color: const Color(0xFFEF4444),
            onTap: onClear,
          ),
          const SizedBox(width: 8),

          // Divider between actions and brush options
          Container(height: 24, width: 1, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(width: 8),

          // Scrollable Section: Brush Sizes and Color Palette
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brush Sizes
                  ..._sizes.map((size) {
                    final isSelected = selectedBrushSize == size;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          onBrushSizeChanged(size);
                          onToolChanged?.call(StrokeType.draw);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: Container(
                              width: size.clamp(4.0, 16.0),
                              height: size.clamp(4.0, 16.0),
                              decoration: BoxDecoration(
                                color: selectedColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(width: 6),
                  Container(height: 24, width: 1, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  const SizedBox(width: 6),

                  // Palette Colors
                  ..._palette.map((color) {
                    final isSelected = selectedColor == color;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          onColorChanged(color);
                          onToolChanged?.call(StrokeType.draw);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 28,
                          height: 28,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: const Color(0xFF6366F1), width: 2.5)
                                : Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1), width: 1),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
