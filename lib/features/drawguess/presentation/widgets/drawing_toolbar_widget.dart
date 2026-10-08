import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';
import 'draw_guess_color_picker_dialog.dart';

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

  static const Color _blackColor = Color(0xFF0F172A);
  static const Color _whiteColor = Color(0xFFFFFFFF);
  static const List<double> _sizes = [2.0, 4.0, 8.0, 16.0];

  bool get _isCustomColor {
    return selectedColor.toARGB32() != _blackColor.toARGB32() &&
        selectedColor.toARGB32() != _whiteColor.toARGB32();
  }

  void _openColorPicker(BuildContext context) async {
    final pickedColor = await DrawGuessColorPickerDialog.show(context, selectedColor);
    if (pickedColor != null) {
      onColorChanged(pickedColor);
    }
  }

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Actions: Undo & Clear
          _buildActionButton(
            context: context,
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onTap: onUndo,
          ),
          const SizedBox(width: 5),
          _buildActionButton(
            context: context,
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete All',
            color: const Color(0xFFEF4444),
            onTap: onClear,
          ),
          const SizedBox(width: 7),

          // Divider
          Container(height: 24, width: 1, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(width: 7),

          // 2. Tools: Draw Pen & Fill Bucket
          _buildToolButton(
            context: context,
            icon: Icons.edit_rounded,
            tooltip: 'Draw Pen',
            isSelected: selectedTool == StrokeType.draw,
            onTap: () => onToolChanged?.call(StrokeType.draw),
          ),
          const SizedBox(width: 5),
          _buildToolButton(
            context: context,
            icon: Icons.format_color_fill_rounded,
            tooltip: 'Fill Color Bucket',
            isSelected: selectedTool == StrokeType.fill,
            onTap: () => onToolChanged?.call(StrokeType.fill),
          ),
          const SizedBox(width: 7),

          // Divider
          Container(height: 24, width: 1, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(width: 7),

          // 3. Brush Sizes
          ..._sizes.map((size) {
            final isSelected = selectedBrushSize == size;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: '${size.toInt()}px brush',
                child: InkWell(
                  onTap: () {
                    onBrushSizeChanged(size);
                    if (selectedTool != StrokeType.draw) {
                      onToolChanged?.call(StrokeType.draw);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 30,
                    height: 30,
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
                        width: size.clamp(3.0, 14.0),
                        height: size.clamp(3.0, 14.0),
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 7),
          // Divider
          Container(height: 24, width: 1, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(width: 7),

          // 4. Color Options: ONLY 3 Options (Black, White, Custom Rainbow Circle)
          // Option A: Black
          _buildColorOption(
            context: context,
            color: _blackColor,
            tooltip: 'Black',
            isSelected: selectedColor.toARGB32() == _blackColor.toARGB32(),
            onTap: () => onColorChanged(_blackColor),
          ),
          const SizedBox(width: 5),

          // Option B: White
          _buildColorOption(
            context: context,
            color: _whiteColor,
            tooltip: 'White',
            isSelected: selectedColor.toARGB32() == _whiteColor.toARGB32(),
            hasBorder: true,
            onTap: () => onColorChanged(_whiteColor),
          ),
          const SizedBox(width: 5),

          // Option C: Custom Rainbow Circle
          Tooltip(
            message: 'Custom Color (Color Wheel)',
            child: InkWell(
              onTap: () => _openColorPicker(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _isCustomColor
                      ? Border.all(color: const Color(0xFF6366F1), width: 2.2)
                      : Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), width: 1),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                  child: _isCustomColor
                      ? Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required BuildContext context,
    required Color color,
    required String tooltip,
    required bool isSelected,
    bool hasBorder = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 30,
          height: 30,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: const Color(0xFF6366F1), width: 2.2)
                : (hasBorder
                    ? Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), width: 1)
                    : null),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: hasBorder && !isSelected
                  ? Border.all(color: const Color(0xFF94A3B8), width: 0.5)
                  : null,
            ),
          ),
        ),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
