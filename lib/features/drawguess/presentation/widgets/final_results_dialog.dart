import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class FinalResultsDialog extends StatelessWidget {
  final FinalGameResult result;
  final VoidCallback onLeave;

  const FinalResultsDialog({
    super.key,
    required this.result,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final podium = result.leaderboard.take(3).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 48),
            const SizedBox(height: 8),
            const Text(
              'GAME OVER — FINAL PODIUM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),

            // Podium Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (podium.length > 1) _buildPodiumStep(context, podium[1], 2, 80, const Color(0xFF94A3B8)),
                if (podium.isNotEmpty) _buildPodiumStep(context, podium[0], 1, 110, const Color(0xFFF59E0B)),
                if (podium.length > 2) _buildPodiumStep(context, podium[2], 3, 60, const Color(0xFFB45309)),
              ],
            ),
            const SizedBox(height: 24),

            // Full Leaderboard
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: result.leaderboard.length,
                separatorBuilder: (context, index) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final p = result.leaderboard[index];
                  return Row(
                    children: [
                      Text(
                        '#${p.rank}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${p.totalScore} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Game Zone', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumStep(BuildContext context, PodiumPlayer player, int rank, double height, Color crownColor) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: rank == 1 ? 22 : 18,
            backgroundColor: crownColor.withValues(alpha: 0.2),
            child: Text(
              player.employeeName.isNotEmpty ? player.employeeName[0].toUpperCase() : 'P',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 16 : 13,
                color: crownColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              player.employeeName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${player.totalScore}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: crownColor),
          ),
          const SizedBox(height: 6),
          Container(
            width: 70,
            height: height,
            decoration: BoxDecoration(
              color: crownColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: crownColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: crownColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
