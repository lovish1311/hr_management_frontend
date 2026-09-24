import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/tambola_models.dart';
import '../../data/services/tambola_api_service.dart';
import '../../data/services/tambola_socket_service.dart';
import '../widgets/tambola_ticket_widget.dart';
import '../widgets/tambola_board_widget.dart';
import '../widgets/party_confetti_overlay.dart';

class TambolaGameRoomPage extends StatefulWidget {
  final String roomCode;

  const TambolaGameRoomPage({super.key, required this.roomCode});

  @override
  State<TambolaGameRoomPage> createState() => _TambolaGameRoomPageState();
}

class _TambolaGameRoomPageState extends State<TambolaGameRoomPage> with TickerProviderStateMixin {
  final TambolaSocketService _socketService = TambolaSocketService();
  StreamSubscription? _socketSubscription;
  Timer? _pollingTimer;

  TambolaGameState? _gameState;
  bool _isLoading = true;
  String? _errorMessage;

  // Local marked numbers on player ticket
  final Set<int> _markedNumbers = {};

  // Action states
  bool _isClaiming = false;
  bool _isDrawing = false;

  // 4-Second Cooldown Timer for drawing
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // Slot-machine roll effect on number draw
  bool _isRolling = false;
  int? _rollingNumber;
  Timer? _rollingTimer;

  // Shake / Wiggle animation on claim rejection
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String? _shakingPrizeType;

  // Floating in-app winner announcement card
  Map<String, String>? _activeWinnerBanner;

  // Party Bomb Confetti state (Paper flying celebration, NO popup dialogs during active play)
  bool _showConfetti = false;

  // Game Over completion dialog flag
  bool _isGameOverModalShowing = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _loadState();
    _initWebSocket();

    // Fallback periodic sync every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadState(silent: true);
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _rollingTimer?.cancel();
    _pollingTimer?.cancel();
    _socketSubscription?.cancel();
    _socketService.dispose();
    _tabController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadState({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final state = await TambolaApiService.getGameState(widget.roomCode);
      if (mounted) {
        setState(() {
          _gameState = state;
          _isLoading = false;
          _errorMessage = null;
        });

        // Check if all houses are claimed or status is COMPLETED
        if (state.game.status == 'COMPLETED' || state.winners.length >= 4) {
          _showGameOverModal();
        }
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

  void _initWebSocket() {
    _socketService.connect(widget.roomCode);
    _socketSubscription = _socketService.onEvent.listen((event) {
      if (!mounted) return;
      final type = (event['type'] as String? ?? '').toUpperCase();

      switch (type) {
        case 'CONNECTED':
          debugPrint('Connected to Tambola room: ${event['roomCode']}');
          break;

        case 'PLAYER_JOINED':
          final name = event['employeeName'] ?? 'A player';
          _showToast('$name joined the game!');
          _loadState(silent: true);
          break;

        case 'GAME_STARTED':
          _showToast('Game has started! Good luck!');
          _loadState(silent: true);
          break;

        case 'NUMBER_DRAWN':
          final num = event['number'] as int? ?? 0;
          // Trigger rolling render feature for real-time draw reveal (NO TOAST!)
          _startRollingAnimation();
          _stopRollingAnimation(targetNumber: num);
          _loadState(silent: true);
          break;

        case 'PRIZE_CLAIMED':
          final prize = event['prizeType']?.toString() ?? 'Prize';
          final winner = event['winnerName']?.toString() ?? 'Someone';
          setState(() {
            _activeWinnerBanner = {
              'winner': winner,
              'prize': prize,
            };
          });
          _showWinnerCelebration(winner, prize);
          _loadState(silent: true);
          break;

        case 'GAME_PAUSED':
          _showToast('Game Paused by host');
          _loadState(silent: true);
          break;

        case 'GAME_RESUMED':
          _showToast('Game Resumed!');
          _loadState(silent: true);
          break;

        case 'GAME_COMPLETED':
        case 'GAME_ENDED':
          _showToast('Game Finished! All Houses have been claimed!');
          _loadState(silent: true).then((_) {
            _showGameOverModal();
          });
          break;

        case 'GAME_RESTARTED':
          if (_isGameOverModalShowing && Navigator.canPop(context)) {
            Navigator.pop(context);
            _isGameOverModalShowing = false;
          }
          setState(() {
            _markedNumbers.clear();
            _activeWinnerBanner = null;
          });
          _showToast('Game has been restarted by host!');
          _loadState(silent: true);
          break;
      }
    });
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _startRollingAnimation() {
    _rollingTimer?.cancel();
    setState(() {
      _isRolling = true;
    });

    final random = Random();
    _rollingTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (mounted) {
        setState(() {
          _rollingNumber = random.nextInt(90) + 1;
        });
      }
    });
  }

  void _stopRollingAnimation({required int targetNumber}) {
    Future.delayed(const Duration(milliseconds: 900), () {
      _rollingTimer?.cancel();
      if (mounted) {
        setState(() {
          _isRolling = false;
          _rollingNumber = targetNumber;
        });
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _cancelRollingAnimation() {
    _rollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isRolling = false;
        _rollingNumber = null;
      });
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = 4;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
        } else {
          _cooldownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  // Party bomb / paper confetti celebration (flying paper particles without popup dialog)
  void _showWinnerCelebration(String winnerName, String prizeType) {
    setState(() {
      _showConfetti = true;
      _activeWinnerBanner = {
        'winner': winnerName,
        'prize': prizeType,
      };
    });
    HapticFeedback.heavyImpact();
  }

  // Game Over Dialog: Appears when all houses are claimed
  void _showGameOverModal() {
    if (_isGameOverModalShowing || !mounted || _gameState == null) return;
    _isGameOverModalShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF0F172A), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All houses have been claimed 🎉',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
              const SizedBox(height: 18),

              // Winners Summary Table
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildWinnerSummaryRow('First House', _getWinnerName('FIRST_HOUSE')),
                    const Divider(height: 12, color: Colors.white12),
                    _buildWinnerSummaryRow('Second House', _getWinnerName('SECOND_HOUSE')),
                    const Divider(height: 12, color: Colors.white12),
                    _buildWinnerSummaryRow('Third House', _getWinnerName('THIRD_HOUSE')),
                    const Divider(height: 12, color: Colors.white12),
                    _buildWinnerSummaryRow('Full House', _getWinnerName('FULL_HOUSE')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Exit & Restart
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: const Text('Exit Game'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _isGameOverModalShowing = false;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Restart Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _isGameOverModalShowing = false;
                        await _handleRestartGame();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) => _isGameOverModalShowing = false);
  }

  String _getWinnerName(String prizeType) {
    final winner = _gameState?.getWinnerForPrize(prizeType);
    return winner?.employeeName ?? 'Unclaimed';
  }

  Widget _buildWinnerSummaryRow(String prizeTitle, String winnerName) {
    final isClaimed = winnerName != 'Unclaimed';
    return Row(
      children: [
        Text(
          prizeTitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          winnerName,
          style: TextStyle(
            color: isClaimed ? const Color(0xFF10B981) : Colors.grey,
            fontSize: 12,
            fontWeight: isClaimed ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Only numbers that have already come / been drawn can be marked!
  void _toggleNumber(int number) {
    if (_markedNumbers.contains(number)) {
      setState(() {
        _markedNumbers.remove(number);
      });
      HapticFeedback.selectionClick();
      return;
    }

    final drawnNumbers = _gameState?.drawnNumbersSet ?? {};
    if (!drawnNumbers.contains(number)) {
      // Number never came yet! Do not allow marking.
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _markedNumbers.add(number);
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _handleClaim(String prizeType) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final result = await TambolaApiService.claimPrize(widget.roomCode, prizeType);
      if (mounted) {
        setState(() => _isClaiming = false);
        _showWinnerCelebration(result.winnerEmployeeName ?? 'You', prizeType);
        _loadState(silent: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClaiming = false;
          _shakingPrizeType = prizeType;
        });
        // Haptic feedback rejection
        HapticFeedback.vibrate();
        HapticFeedback.heavyImpact();
        // Shake / Wiggle card animation
        _shakeController.forward(from: 0.0).then((_) {
          if (mounted) {
            setState(() => _shakingPrizeType = null);
          }
        });
      }
    }
  }

  Future<void> _handleDrawNumber() async {
    if (_isDrawing || _isRolling || _cooldownSeconds > 0) return;
    setState(() => _isDrawing = true);
    _startRollingAnimation();
    _startCooldown();

    try {
      final drawRes = await TambolaApiService.drawNumber(widget.roomCode);
      _stopRollingAnimation(targetNumber: drawRes.number);
      if (mounted) {
        setState(() => _isDrawing = false);
        _loadState(silent: true);
      }
    } catch (e) {
      _cancelRollingAnimation();
      if (mounted) {
        setState(() => _isDrawing = false);
        _showToast(e.toString().replaceAll('Exception:', '').trim());
      }
    }
  }

  Future<void> _handleStartGame() async {
    try {
      await TambolaApiService.startGame(widget.roomCode);
      _loadState(silent: true);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString());
    }
  }

  Future<void> _handlePauseResume(bool isPaused) async {
    try {
      if (isPaused) {
        await TambolaApiService.resumeGame(widget.roomCode);
      } else {
        await TambolaApiService.pauseGame(widget.roomCode);
      }
      _loadState(silent: true);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString());
    }
  }

  Future<void> _handleRestartGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Text('Restart Game?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to restart the game? This will reset all drawn numbers and deal new tickets to all players.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await TambolaApiService.restartGame(widget.roomCode);
      setState(() {
        _markedNumbers.clear();
        _activeWinnerBanner = null;
      });
      _loadState(silent: true);
      _showToast('Game has been restarted!');
    } catch (e) {
      if (mounted) {
        _showToast(e.toString().replaceAll('Exception:', '').trim());
      }
    }
  }

  Future<void> _handleEndGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Game?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to finish and close this game?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Game'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TambolaApiService.endGame(widget.roomCode);
        _loadState(silent: true);
      } catch (e) {
        if (!mounted) return;
        _showToast(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
      );
    }

    if (_errorMessage != null || _gameState == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Tambola Game Room')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'Game could not be loaded', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadState, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final game = _gameState!.game;
    final isHost = _gameState!.isHost;
    final drawnNumbers = _gameState!.drawnNumbersSet;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: _buildAppBar(game),
      body: Stack(
        children: [
          Column(
            children: [
              // Floating in-app winner card
              if (_activeWinnerBanner != null) _buildInAppWinnerCard(),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTabletOrDesktop = constraints.maxWidth >= 850;

                    if (isTabletOrDesktop) {
                      return _buildWideLayout(game, isHost, drawnNumbers);
                    } else {
                      return _buildCompactLayout(game, isHost, drawnNumbers);
                    }
                  },
                ),
              ),
            ],
          ),

          // Party Bomb Confetti Celebration Overlay (Flying paper particles)
          if (_showConfetti)
            PartyConfettiOverlay(
              onFinished: () {
                if (mounted) {
                  setState(() => _showConfetti = false);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInAppWinnerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 PRIZE CLAIMED!',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${_activeWinnerBanner!['winner']} has claimed ${_activeWinnerBanner!['prize']}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            onPressed: () => setState(() => _activeWinnerBanner = null),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TambolaGame game) {
    Color statusColor;
    switch (game.status) {
      case 'RUNNING':
        statusColor = const Color(0xFF10B981);
        break;
      case 'PAUSED':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF64748B);
        break;
      default:
        statusColor = const Color(0xFF3B82F6);
        break;
    }

    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: game.roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room code copied to clipboard!')),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game.roomCode,
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, color: Color(0xFFFBBF24), size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              game.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                game.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${game.playerCount}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // The Big Shining Animated Number Card (30% larger than board box with slot-machine rolling animation)
  Widget _buildShiningNumberCard(TambolaGame game) {
    final hasNumber = game.lastDrawnNumber != null || _isRolling;
    final displayNumber = _isRolling
        ? (_rollingNumber?.toString() ?? '--')
        : (game.lastDrawnNumber?.toString() ?? '--');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isRolling
              ? [const Color(0xFF0F172A), const Color(0xFF0369A1), const Color(0xFF0284C7)]
              : [const Color(0xFF0F172A), const Color(0xFF1E1B4B), const Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRolling
              ? const Color(0xFF38BDF8)
              : (hasNumber ? const Color(0xFFF59E0B) : Colors.white12),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isRolling ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B))
                .withValues(alpha: hasNumber ? 0.35 : 0.08),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 30% larger box with glowing boundary and rounded corners
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text(
                  displayNumber,
                  key: ValueKey<String>(displayNumber),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Calling Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _isRolling ? Icons.refresh_rounded : Icons.auto_awesome,
                      color: _isRolling ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isRolling ? 'DRAWING NUMBER...' : 'CURRENT CALLED NUMBER',
                      style: TextStyle(
                        color: _isRolling ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isRolling
                      ? 'Reel spinning...'
                      : (game.lastDrawnNumber != null
                          ? 'Number ${game.lastDrawnNumber} called!'
                          : 'Waiting for draw'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${game.totalNumbersDrawn} of 90 numbers called',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(TambolaGame game, bool isHost, Set<int> drawnNumbers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Host Controls + Shining Number Card + Ticket + Claims
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isHost) ...[
                  _buildHostToolbar(game),
                  const SizedBox(height: 14),
                ],

                // Shining Number Card
                _buildShiningNumberCard(game),
                const SizedBox(height: 14),

                // Ticket Section (No hints)
                if (_gameState!.myTicket != null) ...[
                  TambolaTicketWidget(
                    ticket: _gameState!.myTicket!,
                    drawnNumbers: drawnNumbers,
                    markedNumbers: _markedNumbers,
                    onNumberToggled: _toggleNumber,
                  ),
                  const SizedBox(height: 14),
                ],

                // 2x2 Grid Colorful Gradient Claim House Center
                _buildPrizeCenter(game),
              ],
            ),
          ),
        ),

        // Right Column: 1-90 Caller Board + Players & Winners
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TambolaBoardWidget(
                  drawnNumbers: drawnNumbers,
                  latestNumber: game.lastDrawnNumber,
                ),
                const SizedBox(height: 14),
                _buildWinnersCard(),
                const SizedBox(height: 14),
                _buildPlayersCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(TambolaGame game, bool isHost, Set<int> drawnNumbers) {
    return Column(
      children: [
        if (isHost)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildHostToolbar(game),
          ),

        // Shining Number Card placed prominently at the top
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _buildShiningNumberCard(game),
        ),

        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF59E0B),
          tabs: const [
            Tab(icon: Icon(Icons.confirmation_number_outlined), text: 'My Ticket'),
            Tab(icon: Icon(Icons.grid_on_rounded), text: '90-Board'),
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Winners & Info'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Ticket + 2x2 Claim House Card
              SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (_gameState!.myTicket != null)
                      TambolaTicketWidget(
                        ticket: _gameState!.myTicket!,
                        drawnNumbers: drawnNumbers,
                        markedNumbers: _markedNumbers,
                        onNumberToggled: _toggleNumber,
                      ),
                    const SizedBox(height: 14),
                    _buildPrizeCenter(game),
                  ],
                ),
              ),

              // Tab 2: 90 Board
              SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: TambolaBoardWidget(
                  drawnNumbers: drawnNumbers,
                  latestNumber: game.lastDrawnNumber,
                ),
              ),

              // Tab 3: Winners & Players
              SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildWinnersCard(),
                    const SizedBox(height: 14),
                    _buildPlayersCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHostToolbar(TambolaGame game) {
    final isRunning = game.status == 'RUNNING';
    final isWaiting = game.status == 'WAITING';
    final isPaused = game.status == 'PAUSED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              const Text(
                'HOST CONTROLS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (isPaused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFFBBF24), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PAUSED',
                        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isWaiting)
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleStartGame,
                ),

              if (isRunning || isPaused) ...[
                // Draw Number Button with 4-second cooldown countdown
                ElevatedButton.icon(
                  icon: (_isDrawing || _isRolling)
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                        )
                      : (_cooldownSeconds > 0
                          ? const Icon(Icons.timer_outlined, size: 18)
                          : const Icon(Icons.casino_rounded, size: 18)),
                  label: Text(
                    _cooldownSeconds > 0
                        ? 'Wait (${_cooldownSeconds}s)'
                        : ((_isDrawing || _isRolling) ? 'Drawing...' : 'Draw Next Number'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cooldownSeconds > 0
                        ? const Color(0xFF64748B)
                        : const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (!isRunning || _isDrawing || _isRolling || _cooldownSeconds > 0)
                      ? null
                      : _handleDrawNumber,
                ),

                // Pause / Resume Button
                OutlinedButton.icon(
                  icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                  label: Text(isPaused ? 'Resume Game' : 'Pause Game'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handlePauseResume(isPaused),
                ),

                // Compact Restart Game Icon Button (Icon only, no text, accidental tap protection)
                Tooltip(
                  message: 'Restart Game',
                  child: InkWell(
                    onTap: _handleRestartGame,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restart_alt_rounded,
                        size: 18,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                ),

                // End Game Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('End Game'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                    side: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleEndGame,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 4 Colorful Gradient Buttons arranged in 2 Rows inside a full card with centered header
  Widget _buildPrizeCenter(TambolaGame game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Center Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                'CLAIM HOUSE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Colorful Gradient Buttons across 2 Rows (evenly spaced horizontally)
          // Row 1: First House & Second House
          Row(
            children: [
              Expanded(
                child: _buildPrizeButton(
                  prizeType: 'FIRST_HOUSE',
                  title: 'First House',
                  subtitle: '5 Top Row',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  game: game,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPrizeButton(
                  prizeType: 'SECOND_HOUSE',
                  title: 'Second House',
                  subtitle: '5 Middle Row',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  game: game,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Third House & Full House
          Row(
            children: [
              Expanded(
                child: _buildPrizeButton(
                  prizeType: 'THIRD_HOUSE',
                  title: 'Third House',
                  subtitle: '5 Bottom Row',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  game: game,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPrizeButton(
                  prizeType: 'FULL_HOUSE',
                  title: 'Full House',
                  subtitle: 'All 15 Numbers',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  game: game,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeButton({
    required String prizeType,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required TambolaGame game,
  }) {
    final winner = _gameState!.getWinnerForPrize(prizeType);
    final isClaimed = winner != null;
    final isRunning = game.status == 'RUNNING';

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        double dx = 0.0;
        final isShakingThis = _shakingPrizeType == prizeType;
        if (isShakingThis) {
          dx = sin(_shakeAnimation.value * pi * 6) * 10.0;
        }

        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: isClaimed
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Won by ${winner.employeeName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (!isRunning || _isClaiming) ? null : () => _handleClaim(prizeType),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isRunning ? gradient : null,
                    color: isRunning ? null : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isRunning
                        ? [
                            BoxShadow(
                              color: gradient.colors.first.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                    border: Border.all(
                      color: (_shakingPrizeType == prizeType)
                          ? const Color(0xFFEF4444)
                          : Colors.white.withValues(alpha: 0.25),
                      width: (_shakingPrizeType == prizeType) ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWinnersCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winners = _gameState!.winners;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text(
                'WINNERS LEADERBOARD',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (winners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No winners yet. Be the first to claim a prize!',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else
            ...winners.map(
              (w) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(w.prizeType, style: const TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (w.claimNumber != null)
                      Text(
                        '#${w.claimNumber}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final players = _gameState!.players;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Text(
                'PLAYERS IN ROOM (${players.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: players.map((p) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: const Color(0xFF38BDF8),
                  child: Text(
                    p.employeeName.isNotEmpty ? p.employeeName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                label: Text(p.employeeName, style: const TextStyle(fontSize: 11)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
