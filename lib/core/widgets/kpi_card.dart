import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? backgroundColor;
  final List<Color>? gradient;
  final String? trendText;
  final bool isTrendPositive;
  final Color? iconColor;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.backgroundColor,
    this.gradient,
    this.trendText,
    this.isTrendPositive = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGradient = gradient != null && gradient!.isNotEmpty;

    final primaryTextColor = isGradient
        ? Colors.white
        : (theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface);
    final secondaryTextColor = isGradient
        ? Colors.white.withValues(alpha: 0.85)
        : (theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: isGradient ? null : (backgroundColor ?? theme.colorScheme.surface),
          gradient: isGradient
              ? LinearGradient(
                  colors: gradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20.0),
          border: isGradient
              ? null
              : Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
          boxShadow: [
            BoxShadow(
              color: isGradient
                  ? gradient!.first.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: isGradient ? 16 : 12,
              offset: const Offset(0, 6),
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
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isGradient
                        ? Colors.white.withValues(alpha: 0.2)
                        : (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isGradient ? Colors.white : (iconColor ?? theme.colorScheme.primary),
                    size: 24,
                  ),
                ),
                if (trendText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGradient
                          ? Colors.white.withValues(alpha: 0.2)
                          : (isTrendPositive
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTrendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14,
                          color: isGradient
                              ? Colors.white
                              : (isTrendPositive ? const Color(0xFF047857) : const Color(0xFFB91C1C)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendText!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isGradient
                                ? Colors.white
                                : (isTrendPositive ? const Color(0xFF047857) : const Color(0xFFB91C1C)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}