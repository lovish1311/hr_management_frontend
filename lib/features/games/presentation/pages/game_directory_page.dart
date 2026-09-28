import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/features/games/data/models/game_models.dart';
import 'package:hr_management/features/games/data/services/game_api_service.dart';

class GameDirectoryPage extends StatefulWidget {
  const GameDirectoryPage({super.key});

  @override
  State<GameDirectoryPage> createState() => _GameDirectoryPageState();
}

class _GameDirectoryPageState extends State<GameDirectoryPage> {
  List<CompanyGame> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final games = await GameApiService.getAllGames();
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleGameStatus(CompanyGame game, bool newValue) async {
    final oldState = game.isEnabled;
    // Optimistic UI update
    setState(() {
      final idx = _games.indexWhere((g) => g.gameKey == game.gameKey);
      if (idx != -1) {
        _games[idx] = game.copyWith(isEnabled: newValue);
      }
    });

    try {
      final updated = await GameApiService.toggleGameStatus(game.gameKey, newValue);
      if (mounted) {
        setState(() {
          final idx = _games.indexWhere((g) => g.gameKey == game.gameKey);
          if (idx != -1) {
            _games[idx] = updated;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${game.title} is now ${newValue ? 'Enabled' : 'Disabled'}'),
            backgroundColor: newValue ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          final idx = _games.indexWhere((g) => g.gameKey == game.gameKey);
          if (idx != -1) {
            _games[idx] = game.copyWith(isEnabled: oldState);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update game status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToGame(CompanyGame game) {
    if (game.gameKey.toUpperCase() == 'TAMBOLA') {
      Navigator.pushNamed(context, '/tambola');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game.title} is launching soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdmin = AuthStorage.isHr || AuthStorage.isSuperAdmin;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const HrDrawer(),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_esports_rounded, color: Color(0xFFF59E0B), size: 24),
              SizedBox(width: 10),
              Text(
                'GAME ZONE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadGames(),
            tooltip: 'Refresh Game Zone',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadGames(silent: true),
        color: const Color(0xFFF59E0B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF312E81).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF0F172A), size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              '⚡ ENTERPRISE SOCIAL & TEAM BONDING',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Company Game Lounge 🎉',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAdmin
                                ? 'Manage enterprise games, configure role access, and monitor live game sessions.'
                                : 'Join live games with colleagues, win exciting prizes, and boost team spirits!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Game Catalog Header
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Text(
                          'AVAILABLE GAMES (${_games.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF38BDF8)),
                            SizedBox(width: 4),
                            Text(
                              'ADMIN GOVERNANCE ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Games List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadGames, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_games.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Text('No games available right now.'),
                )
              else
                ..._games.map((game) => _buildGameCard(game, isDark, isAdmin)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(CompanyGame game, bool isDark, bool isAdmin) {
    final isEnabled = game.isEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled
              ? (isDark ? const Color(0xFF312E81) : const Color(0xFFE2E8F0))
              : Colors.grey.withValues(alpha: 0.3),
          width: isEnabled ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game Top Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4338CA)]
                      : [const Color(0xFF334155), const Color(0xFF475569)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Builder(
                builder: (context) {
                  final isNarrow = MediaQuery.of(context).size.width < 500;
                  final iconBox = Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isEnabled
                          ? const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isEnabled ? null : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🎟️', style: TextStyle(fontSize: 24)),
                  );

                  final titleCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            game.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isEnabled ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                ),
                              ),
                              child: Text(
                                isEnabled ? 'ACTIVE' : 'DISABLED',
                                style: TextStyle(
                                  color: isEnabled ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.category} • ${game.minPlayers}-${game.maxPlayers} Players',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );

                  if (isNarrow && isAdmin) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            iconBox,
                            const SizedBox(width: 14),
                            Expanded(child: titleCol),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isEnabled ? 'Status: Enabled' : 'Status: Disabled',
                                style: TextStyle(
                                  color: isEnabled ? const Color(0xFF34D399) : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch(
                              value: isEnabled,
                              activeThumbColor: const Color(0xFF10B981),
                              activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade700,
                              onChanged: (val) => _toggleGameStatus(game, val),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      iconBox,
                      const SizedBox(width: 16),
                      Expanded(child: titleCol),
                      if (isAdmin) ...[
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isEnabled ? 'Enabled' : 'Disabled',
                              style: TextStyle(
                                color: isEnabled ? const Color(0xFF34D399) : Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Switch(
                              value: isEnabled,
                              activeThumbColor: const Color(0xFF10B981),
                              activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade700,
                              onChanged: (val) => _toggleGameStatus(game, val),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    game.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildFeatureTag('🎯 90-Ball Calling', isDark),
                      _buildFeatureTag('🎟️ Interactive Daubing', isDark),
                      _buildFeatureTag('⚡ Real-time WebSocket', isDark),
                      _buildFeatureTag('🏆 4 Winning Houses', isDark),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons
                  if (isAdmin) ...[
                    // Admin View: Manage & Host
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'OPEN TAMBOLA HUB (HOST / MONITOR)',
                                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _navigateToGame(game),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Employee View: Play Now or Disabled
                    Row(
                      children: [
                        Expanded(
                          child: isEnabled
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'PLAY TAMBOLA NOW',
                                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 4,
                                  ),
                                  onPressed: () => _navigateToGame(game),
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'GAME CURRENTLY DISABLED',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    foregroundColor: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Access restricted: This game is currently disabled by Admin.',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }
}
