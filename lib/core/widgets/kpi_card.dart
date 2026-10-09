import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

/// Semantic type enum for KPI cards.
/// Determines which theme color is used for the gradient.
enum KpiCardType { primary, success, warning }

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? trendText;
  final bool isTrendPositive;
  final KpiCardType cardType;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.trendText,
    this.isTrendPositive = true,
    this.cardType = KpiCardType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    // Pick gradient based on semantic card type (from colorsForApp.txt)
    final List<Color> gradient;
    switch (cardType) {
      case KpiCardType.success:
        gradient = [t.success, Color.lerp(t.success, Colors.black, 0.25)!];
      case KpiCardType.warning:
        gradient = [t.warning, Color.lerp(t.warning, Colors.black, 0.25)!];
      case KpiCardType.primary:
        gradient = [t.primary, t.primaryDark];
    }

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 185;
          final padding = isCompact
              ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)
              : const EdgeInsets.all(20.0);
          final iconContainerPadding = isCompact ? const EdgeInsets.all(7.0) : const EdgeInsets.all(10.0);
          final iconSize = isCompact ? 18.0 : 24.0;
          final spacing = isCompact ? 10.0 : 16.0;
          final valueFontSize = isCompact ? 22.0 : 30.0;
          final titleFontSize = isCompact ? 11.5 : 13.0;

          return Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: isCompact ? 10 : 16,
                  offset: Offset(0, isCompact ? 4 : 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: iconContainerPadding,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      ),
                      child: Icon(icon, color: Colors.white, size: iconSize),
                    ),
                    if (trendText != null)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 8,
                            vertical: isCompact ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isTrendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: isCompact ? 12 : 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  trendText!,
                                  style: TextStyle(
                                    fontSize: isCompact ? 9.5 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: spacing),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}