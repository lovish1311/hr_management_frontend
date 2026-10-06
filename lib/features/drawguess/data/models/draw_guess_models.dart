import 'package:flutter/material.dart';

enum DrawGuessGameState {
  lobby,
  starting,
  wordSelection,
  drawing,
  roundResult,
  finalResults,
  completed,
  cancelled;

  static DrawGuessGameState fromString(String? state) {
    switch (state?.toUpperCase()) {
      case 'STARTING':
        return DrawGuessGameState.starting;
      case 'WORD_SELECTION':
        return DrawGuessGameState.wordSelection;
      case 'DRAWING':
        return DrawGuessGameState.drawing;
      case 'ROUND_RESULT':
        return DrawGuessGameState.roundResult;
      case 'FINAL_RESULTS':
        return DrawGuessGameState.finalResults;
      case 'COMPLETED':
        return DrawGuessGameState.completed;
      case 'CANCELLED':
        return DrawGuessGameState.cancelled;
      case 'LOBBY':
      default:
        return DrawGuessGameState.lobby;
    }
  }

  String toDisplayString() {
    switch (this) {
      case DrawGuessGameState.lobby:
        return 'Waiting in Lobby';
      case DrawGuessGameState.starting:
        return 'Game Starting...';
      case DrawGuessGameState.wordSelection:
        return 'Word Selection';
      case DrawGuessGameState.drawing:
        return 'Drawing Turn';
      case DrawGuessGameState.roundResult:
        return 'Round Results';
      case DrawGuessGameState.finalResults:
        return 'Final Results';
      case DrawGuessGameState.completed:
        return 'Game Completed';
      case DrawGuessGameState.cancelled:
        return 'Game Cancelled';
    }
  }
}

enum StrokeType {
  draw,
  erase,
  clear,
  undo,
  fill;

  static StrokeType fromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'ERASE':
        return StrokeType.erase;
      case 'CLEAR':
        return StrokeType.clear;
      case 'UNDO':
        return StrokeType.undo;
      case 'FILL':
        return StrokeType.fill;
      case 'DRAW':
      default:
        return StrokeType.draw;
    }
  }
}

class DrawPoint {
  final double x;
  final double y;

  const DrawPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    return DrawPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DrawStroke {
  final String roomCode;
  final StrokeType strokeType;
  final Color color;
  final double brushSize;
  final List<DrawPoint> points;
  final int timestamp;

  DrawStroke({
    required this.roomCode,
    this.strokeType = StrokeType.draw,
    this.color = const Color(0xFF000000),
    this.brushSize = 4.0,
    required this.points,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'strokeType': strokeType.name.toUpperCase(),
        'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
        'brushSize': brushSize,
        'points': points.map((p) => p.toJson()).toList(),
        'timestamp': timestamp,
      };

  factory DrawStroke.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF000000);
    final colorStr = json['color'] as String?;
    if (colorStr != null && colorStr.isNotEmpty) {
      try {
        final hex = colorStr.replaceAll('#', '');
        if (hex.length == 6) {
          parsedColor = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          parsedColor = Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    final pointsList = (json['points'] as List<dynamic>?)
            ?.map((p) => DrawPoint.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return DrawStroke(
      roomCode: json['roomCode'] as String? ?? '',
      strokeType: StrokeType.fromString(json['strokeType'] as String?),
      color: parsedColor,
      brushSize: (json['brushSize'] as num?)?.toDouble() ?? 4.0,
      points: pointsList,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}

class DrawGuessRoom {
  final int id;
  final String roomCode;
  final String roomName;
  final int hostEmployeeId;
  final String hostName;
  final DrawGuessGameState state;
  final int maxRounds;
  final int drawTimeSeconds;
  final int wordChoiceCount;
  final String category;
  final bool customWordsOnly;
  final int currentRound;
  final int currentTurnIndex;
  final int? activeDrawerEmployeeId;
  final String? currentHint;
  final int remainingSeconds;
  final List<DrawGuessPlayer> players;
  final DateTime? createdAt;

  DrawGuessRoom({
    required this.id,
    required this.roomCode,
    required this.roomName,
    required this.hostEmployeeId,
    required this.hostName,
    required this.state,
    this.maxRounds = 3,
    this.drawTimeSeconds = 80,
    this.wordChoiceCount = 3,
    this.category = 'GENERAL',
    this.customWordsOnly = false,
    this.currentRound = 1,
    this.currentTurnIndex = 0,
    this.activeDrawerEmployeeId,
    this.currentHint,
    this.remainingSeconds = 0,
    this.players = const [],
    this.createdAt,
  });

  factory DrawGuessRoom.fromJson(Map<String, dynamic> json) {
    final playersList = (json['players'] as List<dynamic>?)
            ?.map((p) => DrawGuessPlayer.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return DrawGuessRoom(
      id: json['id'] as int? ?? 0,
      roomCode: json['roomCode'] as String? ?? '',
      roomName: json['roomName'] as String? ?? 'Draw Room',
      hostEmployeeId: json['hostEmployeeId'] as int? ?? 0,
      hostName: json['hostName'] as String? ?? 'Host',
      state: DrawGuessGameState.fromString(json['state'] as String?),
      maxRounds: json['maxRounds'] as int? ?? 3,
      drawTimeSeconds: json['drawTimeSeconds'] as int? ?? 80,
      wordChoiceCount: json['wordChoiceCount'] as int? ?? 3,
      category: json['category'] as String? ?? 'GENERAL',
      customWordsOnly: json['customWordsOnly'] as bool? ?? false,
      currentRound: json['currentRound'] as int? ?? 1,
      currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
      activeDrawerEmployeeId: json['activeDrawerEmployeeId'] as int?,
      currentHint: json['currentHint'] as String?,
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
      players: playersList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class DrawGuessPlayer {
  final int id;
  final String roomCode;
  final int employeeId;
  final String employeeName;
  final String? avatarUrl;
  final int score;
  final int turnScore;
  final bool hasGuessedCorrectly;
  final bool isDrawer;
  final bool isHost;
  final bool isConnected;
  final int turnOrder;

  DrawGuessPlayer({
    required this.id,
    required this.roomCode,
    required this.employeeId,
    required this.employeeName,
    this.avatarUrl,
    this.score = 0,
    this.turnScore = 0,
    this.hasGuessedCorrectly = false,
    this.isDrawer = false,
    this.isHost = false,
    this.isConnected = true,
    this.turnOrder = 0,
  });

  factory DrawGuessPlayer.fromJson(Map<String, dynamic> json) {
    return DrawGuessPlayer(
      id: json['id'] as int? ?? 0,
      roomCode: json['roomCode'] as String? ?? '',
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? 'Player',
      avatarUrl: json['avatarUrl'] as String?,
      score: json['score'] as int? ?? 0,
      turnScore: json['turnScore'] as int? ?? 0,
      hasGuessedCorrectly: json['hasGuessedCorrectly'] as bool? ?? false,
      isDrawer: json['isDrawer'] as bool? ?? false,
      isHost: json['isHost'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
      turnOrder: json['turnOrder'] as int? ?? 0,
    );
  }
}

class WordOption {
  final String word;
  final String category;
  final String difficulty;
  final String? hint;

  const WordOption({
    required this.word,
    required this.category,
    required this.difficulty,
    this.hint,
  });

  factory WordOption.fromJson(Map<String, dynamic> json) {
    return WordOption(
      word: json['word'] as String? ?? '',
      category: json['category'] as String? ?? 'GENERAL',
      difficulty: json['difficulty'] as String? ?? 'MEDIUM',
      hint: json['hint'] as String?,
    );
  }
}

class GuessResult {
  final String roomCode;
  final int? employeeId;
  final String? employeeName;
  final String guess;
  final bool isCorrect;
  final bool isClose;
  final int pointsAwarded;
  final int totalScore;
  final String? message;

  GuessResult({
    required this.roomCode,
    this.employeeId,
    this.employeeName,
    required this.guess,
    this.isCorrect = false,
    this.isClose = false,
    this.pointsAwarded = 0,
    this.totalScore = 0,
    this.message,
  });

  factory GuessResult.fromJson(Map<String, dynamic> json) {
    return GuessResult(
      roomCode: json['roomCode'] as String? ?? '',
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      guess: json['guess'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      isClose: json['isClose'] as bool? ?? false,
      pointsAwarded: json['pointsAwarded'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

class RoundResult {
  final String roomCode;
  final int roundNumber;
  final int turnNumber;
  final int drawerEmployeeId;
  final String drawerName;
  final String word;
  final int drawerScoreAwarded;
  final List<PlayerScoreDelta> scoreDeltas;
  final int nextTurnInSeconds;

  RoundResult({
    required this.roomCode,
    required this.roundNumber,
    required this.turnNumber,
    required this.drawerEmployeeId,
    required this.drawerName,
    required this.word,
    this.drawerScoreAwarded = 0,
    this.scoreDeltas = const [],
    this.nextTurnInSeconds = 6,
  });

  factory RoundResult.fromJson(Map<String, dynamic> json) {
    final deltas = (json['scoreDeltas'] as List<dynamic>?)
            ?.map((d) => PlayerScoreDelta.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];

    return RoundResult(
      roomCode: json['roomCode'] as String? ?? '',
      roundNumber: json['roundNumber'] as int? ?? 1,
      turnNumber: json['turnNumber'] as int? ?? 1,
      drawerEmployeeId: json['drawerEmployeeId'] as int? ?? 0,
      drawerName: json['drawerName'] as String? ?? 'Drawer',
      word: json['word'] as String? ?? '',
      drawerScoreAwarded: json['drawerScoreAwarded'] as int? ?? 0,
      scoreDeltas: deltas,
      nextTurnInSeconds: json['nextTurnInSeconds'] as int? ?? 6,
    );
  }
}

class PlayerScoreDelta {
  final int employeeId;
  final String employeeName;
  final int pointsEarned;
  final int totalScore;
  final bool guessedCorrectly;

  PlayerScoreDelta({
    required this.employeeId,
    required this.employeeName,
    required this.pointsEarned,
    required this.totalScore,
    required this.guessedCorrectly,
  });

  factory PlayerScoreDelta.fromJson(Map<String, dynamic> json) {
    return PlayerScoreDelta(
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? 'Player',
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      guessedCorrectly: json['guessedCorrectly'] as bool? ?? false,
    );
  }
}

class FinalGameResult {
  final String roomCode;
  final int totalRounds;
  final List<PodiumPlayer> leaderboard;

  FinalGameResult({
    required this.roomCode,
    required this.totalRounds,
    required this.leaderboard,
  });

  factory FinalGameResult.fromJson(Map<String, dynamic> json) {
    final list = (json['leaderboard'] as List<dynamic>?)
            ?.map((p) => PodiumPlayer.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return FinalGameResult(
      roomCode: json['roomCode'] as String? ?? '',
      totalRounds: json['totalRounds'] as int? ?? 3,
      leaderboard: list,
    );
  }
}

class PodiumPlayer {
  final int rank;
  final int employeeId;
  final String employeeName;
  final String? avatarUrl;
  final int totalScore;

  PodiumPlayer({
    required this.rank,
    required this.employeeId,
    required this.employeeName,
    this.avatarUrl,
    required this.totalScore,
  });

  factory PodiumPlayer.fromJson(Map<String, dynamic> json) {
    return PodiumPlayer(
      rank: json['rank'] as int? ?? 1,
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? 'Player',
      avatarUrl: json['avatarUrl'] as String?,
      totalScore: json['totalScore'] as int? ?? 0,
    );
  }
}

class ChatMessageItem {
  final int employeeId;
  final String senderName;
  final String message;
  final bool isCorrectGuess;
  final bool isCloseGuess;
  final bool isSystemMessage;
  final int timestamp;

  ChatMessageItem({
    required this.employeeId,
    required this.senderName,
    required this.message,
    this.isCorrectGuess = false,
    this.isCloseGuess = false,
    this.isSystemMessage = false,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
}
