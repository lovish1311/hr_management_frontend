import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../../data/models/draw_guess_models.dart';
import '../../data/services/draw_guess_api_service.dart';
import '../../data/services/draw_guess_socket_service.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/drawing_toolbar_widget.dart';
import '../widgets/draw_guess_timer_widget.dart';
import '../widgets/draw_guess_hint_widget.dart';
import '../widgets/draw_guess_chat_panel.dart';
import '../widgets/draw_guess_scoreboard_widget.dart';
import '../widgets/word_selection_dialog.dart';
import '../widgets/round_result_dialog.dart';
import '../widgets/final_results_dialog.dart';
import 'draw_guess_leaderboard_screen.dart';

class DrawGuessGameRoomPage extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const DrawGuessGameRoomPage({
    super.key,
    required this.roomCode,
    this.isHost = false,
  });

  @override
  State<DrawGuessGameRoomPage> createState() => _DrawGuessGameRoomPageState();
}

class _DrawGuessGameRoomPageState extends State<DrawGuessGameRoomPage> {
  final DrawGuessSocketService _socketService = DrawGuessSocketService();
  StreamSubscription? _socketSubscription;

  DrawGuessRoom? _room;
  bool _isLoading = true;
  String? _errorMessage;

  // Real-time Canvas & Game States
  final List<DrawStroke> _strokes = [];
  final List<ChatMessageItem> _messages = [];

  Color _selectedColor = const Color(0xFF0F172A);
  double _selectedBrushSize = 4.0;
  StrokeType _selectedTool = StrokeType.draw;

  int _remainingSeconds = 0;
  int _totalSeconds = 80;
  int _currentRound = 1;
  int _maxRounds = 3;
  int? _activeDrawerId;
  String? _hintPattern;
  String? _secretWord;
  int _wordLength = 0;
  String _category = 'GENERAL';
  Map<int, int>? _lastRoundDeltas;

  bool _isWordSelectionOpen = false;
  bool _isRoundResultOpen = false;
  bool _isFinalResultOpen = false;
  bool _isStartingGame = false;

  bool get _isDrawer {
    final currentEmpId = AuthStorage.employeeId;
    return currentEmpId != null && currentEmpId == _activeDrawerId;
  }

  Timer? _localTicker;
  Timer? _lobbyPollTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _connectSocket();
    _startLobbyPollTimer();
  }

  void _startLobbyPollTimer() {
    _lobbyPollTimer?.cancel();
    _lobbyPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _room?.state == DrawGuessGameState.lobby) {
        _refreshRoomQuietly();
      }
    });
  }

  Future<void> _refreshRoomQuietly() async {
    try {
      final room = await DrawGuessApiService.getRoomDetails(widget.roomCode);
      if (mounted) {
        setState(() {
          _room = room;
          _currentRound = room.currentRound;
          _maxRounds = room.maxRounds;
          _activeDrawerId = room.activeDrawerEmployeeId;
          _category = room.category;
          _totalSeconds = room.drawTimeSeconds;
          _remainingSeconds = room.remainingSeconds;
          _hintPattern = room.currentHint;
        });
      }
    } catch (e) {
      debugPrint('Quiet room refresh error: $e');
    }
  }

  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);
    try {
      final room = await DrawGuessApiService.getRoomDetails(widget.roomCode);
      if (mounted) {
        setState(() {
          _room = room;
          _currentRound = room.currentRound;
          _maxRounds = room.maxRounds;
          _activeDrawerId = room.activeDrawerEmployeeId;
          _category = room.category;
          _totalSeconds = room.drawTimeSeconds;
          _remainingSeconds = room.remainingSeconds;
          _hintPattern = room.currentHint;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _connectSocket() {
    _socketService.connect(widget.roomCode);
    _socketSubscription = _socketService.onEvent.listen(_handleSocketEvent);
  }

  void _handlePlayerListUpdate(Map<String, dynamic> event) {
    if (!mounted) return;

    final rawPlayers = event['players'] as List<dynamic>?;
    if (rawPlayers != null && _room != null) {
      final updatedList = rawPlayers
          .map((p) => DrawGuessPlayer.fromJson(p as Map<String, dynamic>))
          .toList();
      setState(() {
        _room = DrawGuessRoom(
          id: _room!.id,
          roomCode: _room!.roomCode,
          roomName: _room!.roomName,
          hostEmployeeId: _room!.hostEmployeeId,
          hostName: _room!.hostName,
          state: _room!.state,
          maxRounds: _room!.maxRounds,
          drawTimeSeconds: _room!.drawTimeSeconds,
          wordChoiceCount: _room!.wordChoiceCount,
          category: _room!.category,
          customWordsOnly: _room!.customWordsOnly,
          currentRound: _room!.currentRound,
          currentTurnIndex: _room!.currentTurnIndex,
          activeDrawerEmployeeId: _room!.activeDrawerEmployeeId,
          currentHint: _room!.currentHint,
          remainingSeconds: _room!.remainingSeconds,
          players: updatedList,
          createdAt: _room!.createdAt,
        );
      });
    } else if (event['player'] != null && _room != null) {
      final newPlayer = DrawGuessPlayer.fromJson(event['player'] as Map<String, dynamic>);
      List<DrawGuessPlayer> updatedList = List.from(_room!.players);
      final idx = updatedList.indexWhere((p) => p.employeeId == newPlayer.employeeId);
      if (idx >= 0) {
        updatedList[idx] = newPlayer;
      } else {
        updatedList.add(newPlayer);
      }
      setState(() {
        _room = DrawGuessRoom(
          id: _room!.id,
          roomCode: _room!.roomCode,
          roomName: _room!.roomName,
          hostEmployeeId: _room!.hostEmployeeId,
          hostName: _room!.hostName,
          state: _room!.state,
          maxRounds: _room!.maxRounds,
          drawTimeSeconds: _room!.drawTimeSeconds,
          wordChoiceCount: _room!.wordChoiceCount,
          category: _room!.category,
          customWordsOnly: _room!.customWordsOnly,
          currentRound: _room!.currentRound,
          currentTurnIndex: _room!.currentTurnIndex,
          activeDrawerEmployeeId: _room!.activeDrawerEmployeeId,
          currentHint: _room!.currentHint,
          remainingSeconds: _room!.remainingSeconds,
          players: updatedList,
          createdAt: _room!.createdAt,
        );
      });
    }

    _refreshRoomQuietly();
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == null) return;

    switch (type.toUpperCase()) {
      case 'PLAYER_JOINED':
      case 'PLAYER_RECONNECTED':
      case 'PLAYER_DISCONNECTED':
        _handlePlayerListUpdate(event);
        break;

      case 'GAME_STARTING':
        setState(() {
          _isStartingGame = false;
          _room = _room != null
              ? DrawGuessRoom(
                  id: _room!.id,
                  roomCode: _room!.roomCode,
                  roomName: _room!.roomName,
                  hostEmployeeId: _room!.hostEmployeeId,
                  hostName: _room!.hostName,
                  state: DrawGuessGameState.starting,
                  maxRounds: _room!.maxRounds,
                  drawTimeSeconds: _room!.drawTimeSeconds,
                  category: _room!.category,
                  players: _room!.players,
                )
              : null;
        });
        break;

      case 'DRAWER_CHOOSING_WORD':
        setState(() {
          _isStartingGame = false;
          _activeDrawerId = event['drawerId'] as int?;
          _secretWord = null;
          _hintPattern = null;
          _strokes.clear();
          _remainingSeconds = event['selectionTimeSeconds'] as int? ?? 15;
          if (_room != null) {
            _room = DrawGuessRoom(
              id: _room!.id,
              roomCode: _room!.roomCode,
              roomName: _room!.roomName,
              hostEmployeeId: _room!.hostEmployeeId,
              hostName: _room!.hostName,
              state: DrawGuessGameState.wordSelection,
              maxRounds: _room!.maxRounds,
              drawTimeSeconds: _room!.drawTimeSeconds,
              wordChoiceCount: _room!.wordChoiceCount,
              category: _room!.category,
              customWordsOnly: _room!.customWordsOnly,
              currentRound: event['currentRound'] as int? ?? _room!.currentRound,
              currentTurnIndex: _room!.currentTurnIndex,
              activeDrawerEmployeeId: _activeDrawerId,
              currentHint: null,
              remainingSeconds: _remainingSeconds,
              players: _room!.players,
              createdAt: _room!.createdAt,
            );
          }
        });
        _startLocalTimer();
        break;

      case 'WORD_OPTIONS':
        final optionsList = (event['options'] as List<dynamic>?)
                ?.map((o) => WordOption.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [];
        _showWordSelectionModal(optionsList);
        break;

      case 'DRAWING_STARTED':
        if (_isWordSelectionOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _isWordSelectionOpen = false;
        }
        if (_isRoundResultOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _isRoundResultOpen = false;
        }
        setState(() {
          _activeDrawerId = event['drawerId'] as int?;
          _wordLength = event['wordLength'] as int? ?? 0;
          _hintPattern = event['hintPattern'] as String?;
          _remainingSeconds = event['drawTimeSeconds'] as int? ?? _totalSeconds;
          _currentRound = event['currentRound'] as int? ?? _currentRound;
          _maxRounds = event['maxRounds'] as int? ?? _maxRounds;
          _strokes.clear();
          if (_room != null) {
            _room = DrawGuessRoom(
              id: _room!.id,
              roomCode: _room!.roomCode,
              roomName: _room!.roomName,
              hostEmployeeId: _room!.hostEmployeeId,
              hostName: _room!.hostName,
              state: DrawGuessGameState.drawing,
              maxRounds: _maxRounds,
              drawTimeSeconds: _room!.drawTimeSeconds,
              wordChoiceCount: _room!.wordChoiceCount,
              category: _room!.category,
              customWordsOnly: _room!.customWordsOnly,
              currentRound: _currentRound,
              currentTurnIndex: _room!.currentTurnIndex,
              activeDrawerEmployeeId: _activeDrawerId,
              currentHint: _hintPattern,
              remainingSeconds: _remainingSeconds,
              players: _room!.players,
              createdAt: _room!.createdAt,
            );
          }
        });
        _startLocalTimer();
        break;

      case 'SECRET_WORD_REVEAL':
        setState(() {
          _secretWord = event['word'] as String?;
        });
        break;

      case 'STROKE':
        final strokeData = event['stroke'] as Map<String, dynamic>?;
        if (strokeData != null) {
          if (_isDrawer) {
            // Already painted and stored locally on drawer side; ignore echoed broadcast
            break;
          }
          final stroke = DrawStroke.fromJson(strokeData);
          setState(() {
            _strokes.add(stroke);
          });
        }
        break;

      case 'CLEAR_CANVAS':
        setState(() {
          _strokes.clear();
        });
        break;

      case 'UNDO_STROKE':
        final undoneStrokeId = event['strokeId'] as String?;
        setState(() {
          if (undoneStrokeId != null && undoneStrokeId.isNotEmpty) {
            _strokes.removeWhere((s) => s.strokeId == undoneStrokeId);
          } else if (_strokes.isNotEmpty) {
            final lastId = _strokes.last.strokeId;
            if (lastId != null && lastId.isNotEmpty) {
              _strokes.removeWhere((s) => s.strokeId == lastId);
            } else {
              _strokes.removeLast();
            }
          }
        });
        break;

      case 'HINT_REVEALED':
        setState(() {
          _hintPattern = event['hintPattern'] as String?;
        });
        break;

      case 'GUESS_CORRECT':
        final guesserEmpId = event['employeeId'] as int? ?? 0;
        _addChatMessage(
          employeeId: guesserEmpId,
          senderName: event['employeeName'] as String? ?? 'Player',
          message: event['message'] as String? ?? 'Guessed the word!',
          isCorrectGuess: true,
        );
        // Mark player solved locally WITHOUT mutating cumulative score mid-round!
        if (_room != null) {
          final updatedPlayers = _room!.players.map((p) {
            if (p.employeeId == guesserEmpId) {
              return DrawGuessPlayer(
                id: p.id,
                roomCode: p.roomCode,
                employeeId: p.employeeId,
                employeeName: p.employeeName,
                avatarUrl: p.avatarUrl,
                score: p.score, // Remains frozen!
                turnScore: event['pointsAwarded'] as int? ?? p.turnScore,
                hasGuessedCorrectly: true,
                isDrawer: p.isDrawer,
                isHost: p.isHost,
                isConnected: p.isConnected,
                turnOrder: p.turnOrder,
                rank: p.rank,
              );
            }
            return p;
          }).toList();
          setState(() {
            _room = DrawGuessRoom(
              id: _room!.id,
              roomCode: _room!.roomCode,
              roomName: _room!.roomName,
              hostEmployeeId: _room!.hostEmployeeId,
              hostName: _room!.hostName,
              state: _room!.state,
              maxRounds: _room!.maxRounds,
              drawTimeSeconds: _room!.drawTimeSeconds,
              wordChoiceCount: _room!.wordChoiceCount,
              category: _room!.category,
              customWordsOnly: _room!.customWordsOnly,
              currentRound: _room!.currentRound,
              currentTurnIndex: _room!.currentTurnIndex,
              activeDrawerEmployeeId: _room!.activeDrawerEmployeeId,
              currentHint: _room!.currentHint,
              remainingSeconds: _remainingSeconds,
              players: updatedPlayers,
              createdAt: _room!.createdAt,
            );
          });
        }
        break;

      case 'CLOSE_GUESS':
        _addChatMessage(
          employeeId: AuthStorage.employeeId ?? 0,
          senderName: 'System',
          message: event['message'] as String? ?? 'Close guess!',
          isCloseGuess: true,
        );
        break;

      case 'GUESS_ATTEMPT':
        _addChatMessage(
          employeeId: event['employeeId'] as int? ?? 0,
          senderName: event['employeeName'] as String? ?? 'Player',
          message: event['guess'] as String? ?? '',
        );
        break;

      case 'CHAT_MESSAGE':
        _addChatMessage(
          employeeId: event['employeeId'] as int? ?? 0,
          senderName: event['senderName'] as String? ?? 'Player',
          message: event['message'] as String? ?? '',
        );
        break;

      case 'DRAWER_DISCONNECTED':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event['message'] as String? ?? 'Drawer disconnected! Advancing turn...'),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 4),
          ),
        );
        break;

      case 'HOST_MIGRATED':
        final newHostName = event['newHostName'] as String? ?? 'Another player';
        final newHostId = event['newHostId'] as int?;
        setState(() {
          if (_room != null) {
            _room = DrawGuessRoom(
              id: _room!.id,
              roomCode: _room!.roomCode,
              roomName: _room!.roomName,
              hostEmployeeId: newHostId ?? _room!.hostEmployeeId,
              hostName: newHostName,
              state: _room!.state,
              maxRounds: _room!.maxRounds,
              drawTimeSeconds: _room!.drawTimeSeconds,
              category: _room!.category,
              players: _room!.players,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Host disconnected. $newHostName is now the host!'),
            backgroundColor: const Color(0xFF6366F1),
            duration: const Duration(seconds: 3),
          ),
        );
        break;

      case 'ROUND_ENDED':
        _localTicker?.cancel();
        final resultData = event['result'] as Map<String, dynamic>?;
        RoundResult? roundResult;
        if (resultData != null) {
          roundResult = RoundResult.fromJson(resultData);
          _showRoundResultModal(roundResult);
        }

        if (roundResult != null) {
          final deltas = <int, int>{};
          for (final d in roundResult.scoreDeltas) {
            deltas[d.employeeId] = d.pointsEarned;
          }
          _lastRoundDeltas = deltas;
        }

        final rawPlayers = event['players'] as List<dynamic>?;
        if (rawPlayers != null && _room != null) {
          final updatedPlayers = rawPlayers
              .map((p) => DrawGuessPlayer.fromJson(p as Map<String, dynamic>))
              .toList();
          setState(() {
            _room = DrawGuessRoom(
              id: _room!.id,
              roomCode: _room!.roomCode,
              roomName: _room!.roomName,
              hostEmployeeId: _room!.hostEmployeeId,
              hostName: _room!.hostName,
              state: DrawGuessGameState.roundResult,
              maxRounds: _room!.maxRounds,
              drawTimeSeconds: _room!.drawTimeSeconds,
              wordChoiceCount: _room!.wordChoiceCount,
              category: _room!.category,
              customWordsOnly: _room!.customWordsOnly,
              currentRound: _room!.currentRound,
              currentTurnIndex: _room!.currentTurnIndex,
              activeDrawerEmployeeId: _room!.activeDrawerEmployeeId,
              currentHint: _room!.currentHint,
              remainingSeconds: _remainingSeconds,
              players: updatedPlayers,
              createdAt: _room!.createdAt,
            );
          });
        }
        break;

      case 'FINAL_RESULTS':
        _localTicker?.cancel();
        final finalData = event['result'] as Map<String, dynamic>?;
        if (finalData != null) {
          final result = FinalGameResult.fromJson(finalData);
          _showFinalResultModal(result);
        }
        break;
    }
  }

  void _startLocalTimer() {
    _localTicker?.cancel();
    _localTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _localTicker?.cancel();
          // Watchdog: If state is drawing or wordSelection and timer reached 0,
          // refresh room state after 2s if ROUND_ENDED hasn't arrived
          if (_room?.state == DrawGuessGameState.drawing ||
              _room?.state == DrawGuessGameState.wordSelection) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted &&
                  (_room?.state == DrawGuessGameState.drawing ||
                   _room?.state == DrawGuessGameState.wordSelection)) {
                _refreshRoomQuietly();
              }
            });
          }
        }
      });
    });
  }

  void _addChatMessage({
    required int employeeId,
    required String senderName,
    required String message,
    bool isCorrectGuess = false,
    bool isCloseGuess = false,
  }) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessageItem(
        employeeId: employeeId,
        senderName: senderName,
        message: message,
        isCorrectGuess: isCorrectGuess,
        isCloseGuess: isCloseGuess,
      ));
    });
  }

  void _showWordSelectionModal(List<WordOption> options) {
    if (_isWordSelectionOpen || !mounted) return;
    _isWordSelectionOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WordSelectionDialog(
        options: options,
        onWordSelected: (word) {
          _socketService.sendSelectWord(word);
          Navigator.of(ctx).pop();
          _isWordSelectionOpen = false;
        },
      ),
    ).then((_) => _isWordSelectionOpen = false);
  }

  void _showRoundResultModal(RoundResult result) {
    if (_isRoundResultOpen || !mounted) return;
    _isRoundResultOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RoundResultDialog(result: result),
    ).then((_) => _isRoundResultOpen = false);
  }

  void _showFinalResultModal(FinalGameResult result) {
    if (_isFinalResultOpen || !mounted) return;
    _isFinalResultOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FinalResultsDialog(
        result: result,
        onLeave: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    ).then((_) => _isFinalResultOpen = false);
  }

  void _openFullLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => DrawGuessLeaderboardScreen(
          players: _room?.players ?? [],
          activeDrawerId: _activeDrawerId,
          roomCode: widget.roomCode,
          currentRound: _currentRound,
          maxRounds: _maxRounds,
          currentTurnIndex: _room?.currentTurnIndex ?? 1,
          lastRoundDeltas: _lastRoundDeltas,
        ),
      ),
    );
  }

  void _handleStrokeCompleted(DrawStroke stroke) {
    setState(() {
      _strokes.add(stroke);
    });
    _socketService.sendStroke(stroke);
  }

  void _handleClearCanvas() {
    setState(() {
      _strokes.clear();
    });
    _socketService.sendClear();
  }

  void _handleUndoStroke() {
    if (_strokes.isNotEmpty) {
      final lastId = _strokes.last.strokeId;
      setState(() {
        if (lastId != null && lastId.isNotEmpty) {
          _strokes.removeWhere((s) => s.strokeId == lastId);
        } else {
          _strokes.removeLast();
        }
      });
      _socketService.sendUndo();
    }
  }

  void _handleSendGuess(String guess) {
    _socketService.sendGuess(guess);
  }

  void _handleStartGame() {
    if (_isStartingGame) return;
    setState(() {
      _isStartingGame = true;
    });
    _socketService.sendStartGame();
  }

  @override
  void dispose() {
    _lobbyPollTimer?.cancel();
    _localTicker?.cancel();
    _socketSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadInitialState, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final currentEmpId = AuthStorage.employeeId;
    final isDrawer = currentEmpId != null && currentEmpId == _activeDrawerId;
    final isLobby = _room?.state == DrawGuessGameState.lobby;

    final myPlayer = _room?.players.firstWhere(
      (p) => p.employeeId == currentEmpId,
      orElse: () => DrawGuessPlayer(id: 0, roomCode: widget.roomCode, employeeId: 0, employeeName: ''),
    );
    final hasGuessedCorrectly = myPlayer?.hasGuessedCorrectly ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildGameHeader(context, isDrawer),
      body: isLobby
          ? _buildLobbyWaitingRoom(context)
          : _buildActiveGameBoard(context, isDrawer, hasGuessedCorrectly),
    );
  }

  PreferredSizeWidget _buildGameHeader(BuildContext context, bool isDrawer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Room Code Chip
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Room code ${widget.roomCode} copied to clipboard!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text(
                    widget.roomCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Round Badge
          if (_room?.state != DrawGuessGameState.lobby)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Round $_currentRound/$_maxRounds',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (_room?.state != DrawGuessGameState.lobby) ...[
          if (_room?.state == DrawGuessGameState.wordSelection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  Text(
                    'Choosing (${_remainingSeconds}s)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            DrawGuessTimerWidget(
              remainingSeconds: _remainingSeconds,
              totalSeconds: _totalSeconds,
            ),
          ],
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final myEmpId = AuthStorage.employeeId;
              final myPlayer = (_room?.players ?? []).cast<DrawGuessPlayer?>().firstWhere(
                    (p) => p?.employeeId == myEmpId,
                    orElse: () => null,
                  );
              final rankStr = (myPlayer != null && myPlayer.rank > 0)
                  ? '#${myPlayer.rank}'
                  : 'Scores';
              return InkWell(
                onTap: _openFullLeaderboard,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.leaderboard_rounded, size: 15, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Text(
                        rankStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildLobbyWaitingRoom(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final players = _room?.players ?? [];
    final currentEmpId = AuthStorage.employeeId;
    final isHost = currentEmpId != null && currentEmpId == _room?.hostEmployeeId;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.sports_esports_rounded, color: Color(0xFF6366F1), size: 48),
              const SizedBox(height: 12),
              Text(
                _room?.roomName ?? 'Draw & Guess Lobby',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Waiting for players to join with code: ${widget.roomCode}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Player Grid
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'JOINED PLAYERS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: players.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p.isHost ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF6366F1),
                          child: Text(
                            p.employeeName.isNotEmpty ? p.employeeName[0] : 'P',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (p.isHost) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('HOST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Start Game Action
              if (isHost)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (players.length >= 2 && !_isStartingGame) ? _handleStartGame : null,
                        icon: _isStartingGame
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          _isStartingGame ? 'Starting Game...' : 'Start Game',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          disabledForegroundColor: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    if (players.length < 2) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Minimum 2 players required to start the game',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Waiting for host to start the game...',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF59E0B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGameBoard(BuildContext context, bool isDrawer, bool hasGuessedCorrectly) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 850;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // Hint Bar
              DrawGuessHintWidget(
                hintPattern: _hintPattern,
                wordLength: _wordLength,
                category: _category,
                isDrawer: isDrawer,
                secretWord: _secretWord,
              ),
              const SizedBox(height: 8),

              // Main Workspace (Canvas + Sidebar)
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left: Small Side Ranking Board (skribbl style)
                          SizedBox(
                            width: 155,
                            child: DrawGuessScoreboardWidget(
                              players: _room?.players ?? [],
                              activeDrawerId: _activeDrawerId,
                              onOpenFullLeaderboard: _openFullLeaderboard,
                              isCompact: false,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Center: Canvas & Toolbar
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: DrawingCanvasWidget(
                                    isDrawer: isDrawer,
                                    selectedColor: _selectedColor,
                                    selectedBrushSize: _selectedBrushSize,
                                    selectedTool: _selectedTool,
                                    strokes: _strokes,
                                    onStrokeCompleted: _handleStrokeCompleted,
                                  ),
                                ),
                                if (isDrawer) ...[
                                  const SizedBox(height: 8),
                                  DrawingToolbarWidget(
                                    selectedColor: _selectedColor,
                                    selectedBrushSize: _selectedBrushSize,
                                    selectedTool: _selectedTool,
                                    onColorChanged: (c) => setState(() => _selectedColor = c),
                                    onBrushSizeChanged: (s) => setState(() => _selectedBrushSize = s),
                                    onToolChanged: (t) => setState(() => _selectedTool = t),
                                    onUndo: _handleUndoStroke,
                                    onClear: _handleClearCanvas,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Right: Squeezed Chat & Guess Feed
                          SizedBox(
                            width: 270,
                            child: DrawGuessChatPanel(
                              messages: _messages,
                              isDrawer: isDrawer,
                              hasGuessedCorrectly: hasGuessedCorrectly,
                              onSendGuess: _handleSendGuess,
                              isCompact: false,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Main Canvas & Side Ranking Board Row
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Small Side Ranking Board (skribbl style) - responsive, slightly broader & vertically centered
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: constraints.maxWidth > 600 ? 140 : (constraints.maxWidth > 400 ? 125 : 108),
                                    child: DrawGuessScoreboardWidget(
                                      players: _room?.players ?? [],
                                      activeDrawerId: _activeDrawerId,
                                      onOpenFullLeaderboard: _openFullLeaderboard,
                                      isCompact: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Canvas + Toolbar
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: DrawingCanvasWidget(
                                          isDrawer: isDrawer,
                                          selectedColor: _selectedColor,
                                          selectedBrushSize: _selectedBrushSize,
                                          selectedTool: _selectedTool,
                                          strokes: _strokes,
                                          onStrokeCompleted: _handleStrokeCompleted,
                                        ),
                                      ),
                                      if (isDrawer) ...[
                                        const SizedBox(height: 6),
                                        DrawingToolbarWidget(
                                          selectedColor: _selectedColor,
                                          selectedBrushSize: _selectedBrushSize,
                                          selectedTool: _selectedTool,
                                          onColorChanged: (c) => setState(() => _selectedColor = c),
                                          onBrushSizeChanged: (s) => setState(() => _selectedBrushSize = s),
                                          onToolChanged: (t) => setState(() => _selectedTool = t),
                                          onUndo: _handleUndoStroke,
                                          onClear: _handleClearCanvas,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Squeezed Chat & Guess Feed
                          SizedBox(
                            height: 145,
                            child: DrawGuessChatPanel(
                              messages: _messages,
                              isDrawer: isDrawer,
                              hasGuessedCorrectly: hasGuessedCorrectly,
                              onSendGuess: _handleSendGuess,
                              isCompact: true,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
