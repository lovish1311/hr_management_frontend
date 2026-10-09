import 'package:flutter/material.dart';

/// Base pulsating skeleton block that dynamically adapts to the current theme.
/// Uses a lightweight, hardware-accelerated AnimationController to achieve 60fps
/// without requiring any heavy third-party packages.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = BoxShape.circle;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
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
    final baseColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle ? null : BorderRadius.circular(widget.borderRadius),
            color: baseColor.withValues(alpha: _opacityAnimation.value),
          ),
        );
      },
    );
  }
}

/// Skeleton for Dashboard Page loading state.
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: isMobile ? const EdgeInsets.all(12.0) : const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner Placeholder
          SkeletonBox(
            width: double.infinity,
            height: isMobile ? 120 : 160,
            borderRadius: isMobile ? 18 : 24,
          ),
          const SizedBox(height: 24),

          // Section Title Placeholder
          const SkeletonBox(width: 140, height: 20, borderRadius: 6),
          const SizedBox(height: 14),

          // KPI Grid Placeholder (4 cards)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 1.4 : 1.6,
            ),
            itemBuilder: (context, index) {
              return const SkeletonBox(borderRadius: 16);
            },
          ),
          const SizedBox(height: 24),

          // Pending Leave Section Placeholder
          const SkeletonBox(width: 180, height: 20, borderRadius: 6),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 75, borderRadius: 14),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 75, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Skeleton for Employee Directory Grid loading state.
class EmployeeGridSkeleton extends StatelessWidget {
  const EmployeeGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 480,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 200,
        ),
        itemBuilder: (context, index) {
          return const SkeletonBox(borderRadius: 16);
        },
      ),
    );
  }
}

/// Skeleton for Leave Management Page loading state.
class LeaveManagementSkeletonLoader extends StatelessWidget {
  const LeaveManagementSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quota Balance Summary Cards (Row)
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 110, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 110, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 110, borderRadius: 16)),
            ],
          ),
          SizedBox(height: 28),

          // Tab Bar Placeholder
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 14),
          SizedBox(height: 20),

          // List Items Placeholder
          SkeletonBox(width: double.infinity, height: 85, borderRadius: 14),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 85, borderRadius: 14),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 85, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Skeleton for Attendance & Holiday Calendars.
class CalendarSkeletonLoader extends StatelessWidget {
  const CalendarSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month Selector Header Placeholder
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(width: 160, height: 28, borderRadius: 8),
            SkeletonBox(width: 90, height: 36, borderRadius: 10),
          ],
        ),
        const SizedBox(height: 20),

        // Weekday Row Placeholder
        const SkeletonBox(width: double.infinity, height: 32, borderRadius: 8),
        const SizedBox(height: 10),

        // 7x5 Calendar Grid Placeholder
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 35,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            return const SkeletonBox(borderRadius: 8);
          },
        ),
      ],
    );
  }
}

/// Skeleton for Payslip Page loading state.
class PayslipSkeletonLoader extends StatelessWidget {
  const PayslipSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Bar Placeholder
          SkeletonBox(width: double.infinity, height: 50, borderRadius: 14),
          SizedBox(height: 16),

          // Net Salary Hero Card Placeholder
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 20),
          SizedBox(height: 20),

          // Earnings Table Placeholder
          SkeletonBox(width: 160, height: 22, borderRadius: 6),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 130, borderRadius: 16),
          SizedBox(height: 20),

          // Deductions Table Placeholder
          SkeletonBox(width: 160, height: 22, borderRadius: 6),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 130, borderRadius: 16),
        ],
      ),
    );
  }
}

/// Skeleton for Holiday Calendar Page loading state.
class HolidayCalendarSkeletonLoader extends StatelessWidget {
  const HolidayCalendarSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonBox(width: double.infinity, height: 80, borderRadius: 16),
        SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 80, borderRadius: 16),
        SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 80, borderRadius: 16),
        SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 80, borderRadius: 16),
      ],
    );
  }
}

/// Skeleton for People Directory Page loading state.
class PeopleDirectorySkeletonLoader extends StatelessWidget {
  const PeopleDirectorySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Search & Filter Row Placeholder
          const SkeletonBox(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: 20),

          // People Cards Grid Placeholder
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 180,
            ),
            itemBuilder: (context, index) {
              return const SkeletonBox(borderRadius: 16);
            },
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Employee Profile Page loading state.
class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero Card with Avatar Placeholder
          Row(
            children: [
              SkeletonBox.circle(size: 72),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 22, borderRadius: 6),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 16, borderRadius: 6),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 14, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 28),

          // Tabs Placeholder
          SkeletonBox(width: double.infinity, height: 44, borderRadius: 12),
          SizedBox(height: 20),

          // Profile Detail Cards
          SkeletonBox(width: double.infinity, height: 140, borderRadius: 16),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 140, borderRadius: 16),
        ],
      ),
    );
  }
}
