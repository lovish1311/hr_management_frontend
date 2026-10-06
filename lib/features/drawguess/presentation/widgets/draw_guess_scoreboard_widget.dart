import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class DrawGuessScoreboardWidget extends StatelessWidget {
  final List<DrawGuessPlayer> players;
  final int? activeDrawerId;
  final VoidCallback? onOpenFullLeaderboard;

  const DrawGuessScoreboardWidget({
    super.key,
    required this.players,
    this.activeDrawerId,
    this.onOpenFullLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortedPlayers = List<DrawGuessPlayer>.from(players)
      ..sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return a.turnOrder.compareTo(b.turnOrder);
      });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onOpenFullLeaderboard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  const Text(
                    'PLAYERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (onOpenFullLeaderboard != null)
                    const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF6366F1)),
                  const Spacer(),
                  Text(
                    '${players.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Player List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: sortedPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                final isDrawer = player.employeeId == activeDrawerId;
                final isTop = index == 0 && player.score > 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: player.hasGuessedCorrectly
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (isDrawer
                            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: player.hasGuessedCorrectly
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : (isDrawer
                              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                              : Colors.transparent),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isTop
                              ? const Color(0xFFF59E0B)
                              : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Avatar or Icon
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          player.employeeName.isNotEmpty ? player.employeeName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Name & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    player.employeeName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDrawer) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF6366F1)),
                                ],
                                if (player.hasGuessedCorrectly) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Score Counter
                      Text(
                        '${player.score}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
