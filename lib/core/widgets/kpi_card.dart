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
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 16,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (trendText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTrendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendText!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}