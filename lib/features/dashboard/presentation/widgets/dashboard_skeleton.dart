import 'package:flutter/material.dart';

/// Lightweight shimmer box for dashboard placeholders
class DashboardShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const DashboardShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  State<DashboardShimmerBox> createState() => _DashboardShimmerBoxState();
}

class _DashboardShimmerBoxState extends State<DashboardShimmerBox> with SingleTickerProviderStateMixin {
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

/// Skeleton for Dashboard header, KPI cards, and quick actions
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNarrow = MediaQuery.of(context).size.width < 650;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner Skeleton
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardShimmerBox(width: 120, height: 18, borderRadius: 6),
                SizedBox(height: 12),
                DashboardShimmerBox(width: 220, height: 26, borderRadius: 8),
                SizedBox(height: 8),
                DashboardShimmerBox(width: 300, height: 14, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI Cards Skeleton (2-column on mobile)
          if (isNarrow) ...[
            const Row(
              children: [
                Expanded(child: DashboardShimmerBox(width: double.infinity, height: 100, borderRadius: 16)),
                SizedBox(width: 10),
                Expanded(child: DashboardShimmerBox(width: double.infinity, height: 100, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 10),
            const DashboardShimmerBox(width: double.infinity, height: 90, borderRadius: 16),
          ] else ...[
            const Row(
              children: [
                Expanded(child: DashboardShimmerBox(width: double.infinity, height: 110, borderRadius: 16)),
                SizedBox(width: 14),
                Expanded(child: DashboardShimmerBox(width: double.infinity, height: 110, borderRadius: 16)),
                SizedBox(width: 14),
                Expanded(child: DashboardShimmerBox(width: double.infinity, height: 110, borderRadius: 16)),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Quick Actions Skeleton
          const DashboardShimmerBox(width: 150, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: DashboardShimmerBox(width: double.infinity, height: 60, borderRadius: 12)),
              SizedBox(width: 10),
              Expanded(child: DashboardShimmerBox(width: double.infinity, height: 60, borderRadius: 12)),
            ],
          ),
          const SizedBox(height: 20),

          // Pending Leave Approvals Skeleton
          const DashboardShimmerBox(width: 200, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          const DashboardShimmerBox(width: double.infinity, height: 72, borderRadius: 14),
          const SizedBox(height: 10),
          const DashboardShimmerBox(width: double.infinity, height: 72, borderRadius: 14),
        ],
      ),
    );
  }
}
