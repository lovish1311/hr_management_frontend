import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class DrawGuessLeaderboardScreen extends StatelessWidget {
  final List<DrawGuessPlayer> players;
  final int? activeDrawerId;
  final String roomCode;
  final int currentRound;
  final int maxRounds;
  final int currentTurnIndex;
  final Map<int, int>? lastRoundDeltas; // employeeId -> pointsEarned

  const DrawGuessLeaderboardScreen({
    super.key,
    required this.players,
    this.activeDrawerId,
    required this.roomCode,
    this.currentRound = 1,
    this.maxRounds = 3,
    this.currentTurnIndex = 1,
    this.lastRoundDeltas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Stable sort: score DESC, then turnOrder ASC
    final sortedPlayers = List<DrawGuessPlayer>.from(players)
      ..sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return a.turnOrder.compareTo(b.turnOrder);
      });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaderboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Room $roomCode • Round $currentRound of $maxRounds',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  '${players.length} Players',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top 3 Podium
              if (sortedPlayers.isNotEmpty)
                _buildPodiumSection(context, sortedPlayers),
              const SizedBox(height: 24),

              // Section Header
              Row(
                children: [
                  const Icon(Icons.format_list_numbered_rounded, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Text(
                    'FULL RANKINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Points only commit on round end',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Player List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedPlayers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = sortedPlayers[index];
                  final isDrawer = player.employeeId == activeDrawerId;
                  final delta = lastRoundDeltas?[player.employeeId];

                  return _buildPlayerRankCard(
                    context: context,
                    player: player,
                    rank: index + 1,
                    isDrawer: isDrawer,
                    delta: delta,
                    isDark: isDark,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection(BuildContext context, List<DrawGuessPlayer> sorted) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final first = sorted.isNotEmpty ? sorted[0] : null;
    final second = sorted.length > 1 ? sorted[1] : null;
    final third = sorted.length > 2 ? sorted[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          if (second != null)
            _buildPodiumColumn(
              context: context,
              player: second,
              rank: 2,
              medalColor: const Color(0xFF94A3B8),
              pillarHeight: 85,
              crownIcon: Icons.military_tech_rounded,
            )
          else
            const SizedBox(width: 80),

          // 1st Place (Gold)
          if (first != null)
            _buildPodiumColumn(
              context: context,
              player: first,
              rank: 1,
              medalColor: const Color(0xFFF59E0B),
              pillarHeight: 115,
              crownIcon: Icons.emoji_events_rounded,
            ),

          // 3rd Place (Bronze)
          if (third != null)
            _buildPodiumColumn(
              context: context,
              player: third,
              rank: 3,
              medalColor: const Color(0xFFD97706),
              pillarHeight: 65,
              crownIcon: Icons.workspace_premium_rounded,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required BuildContext context,
    required DrawGuessPlayer player,
    required int rank,
    required Color medalColor,
    required double pillarHeight,
    required IconData crownIcon,
  }) {
    final isDrawer = player.employeeId == activeDrawerId;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal Icon
          Icon(crownIcon, size: rank == 1 ? 28 : 22, color: medalColor),
          const SizedBox(height: 4),

          // Avatar with Rank Badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: medalColor, width: rank == 1 ? 2.5 : 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: medalColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: rank == 1 ? 26 : 22,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    player.employeeName.isNotEmpty ? player.employeeName[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: rank == 1 ? 18 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: medalColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Player Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  player.employeeName,
                  style: TextStyle(
                    fontSize: rank == 1 ? 13 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDrawer) ...[
                const SizedBox(width: 4),
                const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF6366F1)),
              ],
            ],
          ),
          const SizedBox(height: 2),

          // Score
          Text(
            '${player.score} pts',
            style: TextStyle(
              fontSize: rank == 1 ? 14 : 12,
              fontWeight: FontWeight.w800,
              color: medalColor,
            ),
          ),
          const SizedBox(height: 8),

          // Podium Pedestal Block
          Container(
            height: pillarHeight,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  medalColor.withValues(alpha: 0.25),
                  medalColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: medalColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: rank == 1 ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: medalColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRankCard({
    required BuildContext context,
    required DrawGuessPlayer player,
    required int rank,
    required bool isDrawer,
    required int? delta,
    required bool isDark,
  }) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFF59E0B);
    } else if (rank == 2) {
      rankColor = const Color(0xFF94A3B8);
    } else if (rank == 3) {
      rankColor = const Color(0xFFD97706);
    } else {
      rankColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: player.hasGuessedCorrectly
            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08)
            : (isDrawer
                ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.08)
                : (isDark ? const Color(0xFF1E293B) : Colors.white)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: player.hasGuessedCorrectly
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDrawer
                  ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0))),
          width: isDrawer || player.hasGuessedCorrectly ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  player.employeeName.isNotEmpty ? player.employeeName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (!player.isConnected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Name and Status Chips
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (isDrawer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✏ ', style: TextStyle(fontSize: 10)),
                            Text(
                              'Drawing',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                            ),
                          ],
                        ),
                      ),
                    if (player.hasGuessedCorrectly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 3),
                            Text(
                              'Solved',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    if (!player.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Offline',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Scores & Delta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6366F1),
                ),
              ),
              if (delta != null && delta > 0)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+$delta pts',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
