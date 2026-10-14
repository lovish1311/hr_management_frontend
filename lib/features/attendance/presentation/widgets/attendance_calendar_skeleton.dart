import 'package:flutter/material.dart';

/// Lightweight skeleton placeholder for the monthly attendance calendar grid
class AttendanceCalendarSkeleton extends StatefulWidget {
  const AttendanceCalendarSkeleton({super.key});

  @override
  State<AttendanceCalendarSkeleton> createState() => _AttendanceCalendarSkeletonState();
}

class _AttendanceCalendarSkeletonState extends State<AttendanceCalendarSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 500;
        final isUltraNarrow = availableWidth < 360;
        final gridSpacing = isUltraNarrow ? 3.0 : (isNarrow ? 4.0 : 6.0);
        final colWidth = (availableWidth - (gridSpacing * 6)) / 7.0;
        final cellHeight = ((isNarrow ? (colWidth * 1.05) : (colWidth * 1.15))).clamp(38.0, 72.0);

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final currentColor = Color.lerp(baseColor, highlightColor, _controller.value) ?? baseColor;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellHeight,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
              ),
              itemCount: 35, // 5 weeks of placeholder day cells
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
