import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../../data/models/draw_guess_models.dart';

class DrawGuessScoreboardWidget extends StatelessWidget {
  final List<DrawGuessPlayer> players;
  final int? activeDrawerId;
  final VoidCallback? onOpenFullLeaderboard;
  final bool isCompact;

  const DrawGuessScoreboardWidget({
    super.key,
    required this.players,
    this.activeDrawerId,
    this.onOpenFullLeaderboard,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myEmpId = AuthStorage.employeeId;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onOpenFullLeaderboard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 14,
                vertical: isCompact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    size: isCompact ? 15 : 18,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompact ? 'RANKS' : 'PLAYERS',
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (onOpenFullLeaderboard != null && !isCompact) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF6366F1)),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${players.length}',
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Player List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(isCompact ? 6 : 8),
            itemCount: sortedPlayers.length,
            separatorBuilder: (context, index) => SizedBox(height: isCompact ? 4 : 4),
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              final isDrawer = player.employeeId == activeDrawerId;
                final isCurrentUser = player.employeeId == myEmpId;
                final rank = index + 1;

                Color rankColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
                if (rank == 1 && player.score > 0) {
                  rankColor = const Color(0xFFF59E0B);
                } else if (rank == 2 && player.score > 0) {
                  rankColor = const Color(0xFF94A3B8);
                } else if (rank == 3 && player.score > 0) {
                  rankColor = const Color(0xFFB45309);
                }

                return InkWell(
                  onTap: onOpenFullLeaderboard,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 8,
                      vertical: isCompact ? 6 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: player.hasGuessedCorrectly
                          ? const Color(0xFF10B981).withValues(alpha: 0.14)
                          : (isDrawer
                              ? const Color(0xFF6366F1).withValues(alpha: 0.14)
                              : (isCurrentUser
                                  ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC))
                                  : Colors.transparent)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: player.hasGuessedCorrectly
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : (isDrawer
                                ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                                : (isCurrentUser
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                                    : Colors.transparent)),
                      ),
                    ),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#$rank',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: rankColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: const Color(0xFF6366F1),
                                    child: Text(
                                      player.employeeName.isNotEmpty
                                          ? player.employeeName[0].toUpperCase()
                                          : 'P',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isDrawer)
                                    const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF6366F1))
                                  else if (player.hasGuessedCorrectly)
                                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isCurrentUser ? '${player.employeeName} (You)' : player.employeeName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${player.score} pts',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Text(
                                '#$rank',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: rankColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFF6366F1),
                                child: Text(
                                  player.employeeName.isNotEmpty
                                      ? player.employeeName[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isCurrentUser
                                                ? '${player.employeeName} (You)'
                                                : player.employeeName,
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
                                    Text(
                                      '${player.score} pts',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }
