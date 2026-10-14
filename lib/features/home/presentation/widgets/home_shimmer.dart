import 'package:flutter/material.dart';

/// Lightweight shimmer pulse container that requires zero external packages.
class HomeShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const HomeShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  State<HomeShimmerBox> createState() => _HomeShimmerBoxState();
}

class _HomeShimmerBoxState extends State<HomeShimmerBox> with SingleTickerProviderStateMixin {
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(baseColor, highlightColor, _controller.value) ?? baseColor,
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for the Sun Clock Shift card
class HomeSunClockSkeleton extends StatelessWidget {
  const HomeSunClockSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          HomeShimmerBox(width: double.infinity, height: 42, borderRadius: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                HomeShimmerBox(width: 68, height: 68, borderRadius: 34),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeShimmerBox(width: 180, height: 16, borderRadius: 6),
                      SizedBox(height: 8),
                      HomeShimmerBox(width: 120, height: 12, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for Payslip overview card
class HomePayslipSkeleton extends StatelessWidget {
  const HomePayslipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HomeShimmerBox(width: 100, height: 20, borderRadius: 6),
              HomeShimmerBox(width: 80, height: 14, borderRadius: 6),
            ],
          ),
          SizedBox(height: 16),
          HomeShimmerBox(width: double.infinity, height: 72, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for Upcoming Holidays card
class HomeHolidaysSkeleton extends StatelessWidget {
  const HomeHolidaysSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          HomeShimmerBox(width: 44, height: 44, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeShimmerBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                HomeShimmerBox(width: 90, height: 11, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
