import 'package:flutter/material.dart';

class DrawGuessTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const DrawGuessTimerWidget({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 80,
  });

  @override
  Widget build(BuildContext context) {
        final progress = totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    final color = remainingSeconds > 25
        ? const Color(0xFF10B981) // Emerald Green
        : (remainingSeconds > 10 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)); // Amber / Red

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${remainingSeconds}s',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
