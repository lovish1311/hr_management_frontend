import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

/// Lightweight shimmer pulse container that requires zero external packages.
class QueryShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const QueryShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  State<QueryShimmerBox> createState() => _QueryShimmerBoxState();
}

class _QueryShimmerBoxState extends State<QueryShimmerBox> with SingleTickerProviderStateMixin {
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

/// Shimmer skeleton for the Live Data Preview & KPI pane
class QueryPreviewSkeleton extends StatelessWidget {
  const QueryPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Metrics Banner Skeleton
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QueryShimmerBox(width: 80, height: 11, borderRadius: 4),
                    SizedBox(height: 6),
                    QueryShimmerBox(width: 60, height: 18, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QueryShimmerBox(width: 90, height: 11, borderRadius: 4),
                    SizedBox(height: 6),
                    QueryShimmerBox(width: 75, height: 18, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QueryShimmerBox(width: 80, height: 11, borderRadius: 4),
                    SizedBox(height: 6),
                    QueryShimmerBox(width: 50, height: 18, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Data Preview Table Skeleton
        Container(
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row Skeleton
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: t.isDarkTheme ? Colors.grey.shade900 : const Color(0xFF1E293B),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            QueryShimmerBox(width: 70, height: 14, borderRadius: 4),
                            SizedBox(width: 24),
                            QueryShimmerBox(width: 100, height: 14, borderRadius: 4),
                            SizedBox(width: 24),
                            QueryShimmerBox(width: 90, height: 14, borderRadius: 4),
                            SizedBox(width: 24),
                            QueryShimmerBox(width: 80, height: 14, borderRadius: 4),
                          ],
                        ),
                      ),
                      // Data Rows Skeleton
                      for (int i = 0; i < 5; i++) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              QueryShimmerBox(width: 60, height: 12, borderRadius: 4),
                              SizedBox(width: 34),
                              QueryShimmerBox(width: 110, height: 12, borderRadius: 4),
                              SizedBox(width: 24),
                              QueryShimmerBox(width: 80, height: 12, borderRadius: 4),
                              SizedBox(width: 34),
                              QueryShimmerBox(width: 70, height: 12, borderRadius: 4),
                            ],
                          ),
                        ),
                        if (i < 4) Divider(height: 1, color: t.border),
                      ],
                    ],
                  ),
                ),
              ),
              // Pagination Footer Skeleton
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: t.cardSoft,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: t.border)),
                ),
                child: const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    QueryShimmerBox(width: 120, height: 12, borderRadius: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QueryShimmerBox(width: 28, height: 28, borderRadius: 6),
                        SizedBox(width: 8),
                        QueryShimmerBox(width: 40, height: 12, borderRadius: 4),
                        SizedBox(width: 8),
                        QueryShimmerBox(width: 28, height: 28, borderRadius: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full page shimmer skeleton for initial metadata catalog load
class QueryBuilderPageSkeleton extends StatelessWidget {
  const QueryBuilderPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header shimmer
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QueryShimmerBox(width: 36, height: 36, borderRadius: 10),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QueryShimmerBox(width: 160, height: 18, borderRadius: 4),
                      SizedBox(height: 6),
                      QueryShimmerBox(width: 220, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QueryShimmerBox(width: 80, height: 36, borderRadius: 8),
                  SizedBox(width: 10),
                  QueryShimmerBox(width: 90, height: 36, borderRadius: 8),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Filter Bar shimmer
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.cardSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: const Row(
                children: [
                  QueryShimmerBox(width: 90, height: 16, borderRadius: 4),
                  SizedBox(width: 16),
                  QueryShimmerBox(width: 100, height: 28, borderRadius: 14),
                  SizedBox(width: 10),
                  QueryShimmerBox(width: 110, height: 28, borderRadius: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Domain cards shimmer
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children: [
                QueryShimmerBox(width: 130, height: 80, borderRadius: 12),
                SizedBox(width: 10),
                QueryShimmerBox(width: 130, height: 80, borderRadius: 12),
                SizedBox(width: 10),
                QueryShimmerBox(width: 130, height: 80, borderRadius: 12),
                SizedBox(width: 10),
                QueryShimmerBox(width: 130, height: 80, borderRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preview section shimmer
          const Expanded(
            child: SingleChildScrollView(
              child: QueryPreviewSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}
