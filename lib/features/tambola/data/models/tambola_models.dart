class TambolaGame {
  final int id;
  final String roomCode;
  final String title;
  final String status; // WAITING, RUNNING, PAUSED, COMPLETED, CANCELLED
  final int? autoDrawIntervalSeconds;
  final int totalNumbersDrawn;
  final int? lastDrawnNumber;
  final int createdById;
  final String createdByName;
  final DateTime? createdAt;
  final int playerCount;
  final bool isHost;

  TambolaGame({
    required this.id,
    required this.roomCode,
    required this.title,
    required this.status,
    this.autoDrawIntervalSeconds,
    this.totalNumbersDrawn = 0,
    this.lastDrawnNumber,
    required this.createdById,
    required this.createdByName,
    this.createdAt,
    this.playerCount = 0,
    this.isHost = false,
  });

  factory TambolaGame.fromJson(Map<String, dynamic> json) {
    return TambolaGame(
      id: json['id'] as int? ?? 0,
      roomCode: json['roomCode'] as String? ?? '',
      title: json['title'] as String? ?? 'Tambola Game',
      status: (json['status'] as String? ?? 'WAITING').toUpperCase(),
      autoDrawIntervalSeconds: json['autoDrawIntervalSeconds'] as int?,
      totalNumbersDrawn: json['totalNumbersDrawn'] as int? ?? 0,
      lastDrawnNumber: json['lastDrawnNumber'] as int?,
      createdById: json['createdById'] as int? ?? 0,
      createdByName: json['createdByName'] as String? ?? 'Host',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      playerCount: json['playerCount'] as int? ?? 0,
      isHost: (json['isHost'] ?? json['host']) as bool? ?? false,
    );
  }
}

class TambolaTicket {
  final int ticketId;
  final int gameId;
  final int employeeId;
  final List<List<int>> grid; // 3x9 grid
  final List<int> row1;
  final List<int> row2;
  final List<int> row3;
  final List<int> allNumbers;

  TambolaTicket({
    required this.ticketId,
    required this.gameId,
    required this.employeeId,
    required this.grid,
    required this.row1,
    required this.row2,
    required this.row3,
    required this.allNumbers,
  });

  factory TambolaTicket.fromJson(Map<String, dynamic> json) {
    final rawGrid = json['grid'] as List<dynamic>? ?? [];
    final grid = rawGrid.map((r) => (r is List ? r : []).map((c) => (c is num ? c.toInt() : (int.tryParse(c?.toString() ?? '') ?? 0))).toList()).toList();

    List<int> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => (e is num ? e.toInt() : (int.tryParse(e?.toString() ?? '') ?? 0))).toList();
      }
      return [];
    }

    return TambolaTicket(
      ticketId: json['ticketId'] as int? ?? 0,
      gameId: json['gameId'] as int? ?? 0,
      employeeId: json['employeeId'] as int? ?? 0,
      grid: grid,
      row1: parseList(json['row1']),
      row2: parseList(json['row2']),
      row3: parseList(json['row3']),
      allNumbers: parseList(json['allNumbers']),
    );
  }
}

class TambolaPlayer {
  final int playerId;
  final int employeeId;
  final String employeeName;
  final DateTime? joinedAt;

  TambolaPlayer({
    required this.playerId,
    required this.employeeId,
    required this.employeeName,
    this.joinedAt,
  });

  factory TambolaPlayer.fromJson(Map<String, dynamic> json) {
    return TambolaPlayer(
      playerId: json['playerId'] as int? ?? 0,
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? 'Player',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'].toString()) : null,
    );
  }
}

class TambolaDraw {
  final int drawOrder;
  final int number;
  final DateTime? drawnAt;

  TambolaDraw({
    required this.drawOrder,
    required this.number,
    this.drawnAt,
  });

  factory TambolaDraw.fromJson(Map<String, dynamic> json) {
    return TambolaDraw(
      drawOrder: json['drawOrder'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      drawnAt: json['drawnAt'] != null ? DateTime.tryParse(json['drawnAt'].toString()) : null,
    );
  }
}

class TambolaWinner {
  final int id;
  final int employeeId;
  final String employeeName;
  final String prizeType; // FIRST_HOUSE, SECOND_HOUSE, THIRD_HOUSE, FULL_HOUSE
  final int prizeRank;
  final int? claimNumber;
  final String? winningDetails;
  final DateTime? claimedAt;

  TambolaWinner({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.prizeType,
    this.prizeRank = 1,
    this.claimNumber,
    this.winningDetails,
    this.claimedAt,
  });

  factory TambolaWinner.fromJson(Map<String, dynamic> json) {
    return TambolaWinner(
      id: json['id'] as int? ?? 0,
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? '',
      prizeType: (json['prizeType'] as String? ?? '').toUpperCase(),
      prizeRank: json['prizeRank'] as int? ?? 1,
      claimNumber: json['claimNumber'] as int?,
      winningDetails: json['winningDetails'] as String?,
      claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'].toString()) : null,
    );
  }
}

class TambolaClaimResult {
  final bool success;
  final String message;
  final String prizeType;
  final int? winnerEmployeeId;
  final String? winnerEmployeeName;
  final int prizeRank;
  final int? claimNumber;
  final DateTime? claimedAt;

  TambolaClaimResult({
    required this.success,
    required this.message,
    required this.prizeType,
    this.winnerEmployeeId,
    this.winnerEmployeeName,
    this.prizeRank = 1,
    this.claimNumber,
    this.claimedAt,
  });

  factory TambolaClaimResult.fromJson(Map<String, dynamic> json) {
    return TambolaClaimResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      prizeType: json['prizeType'] as String? ?? '',
      winnerEmployeeId: json['winnerEmployeeId'] as int?,
      winnerEmployeeName: json['winnerEmployeeName'] as String?,
      prizeRank: json['prizeRank'] as int? ?? 1,
      claimNumber: json['claimNumber'] as int?,
      claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'].toString()) : null,
    );
  }
}

class TambolaGameState {
  final TambolaGame game;
  final List<TambolaPlayer> players;
  final List<TambolaDraw> draws;
  final List<TambolaWinner> winners;
  final TambolaTicket? myTicket;
  final bool isHost;

  TambolaGameState({
    required this.game,
    required this.players,
    required this.draws,
    required this.winners,
    this.myTicket,
    this.isHost = false,
  });

  factory TambolaGameState.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'] as List<dynamic>? ?? [];
    final rawDraws = json['draws'] as List<dynamic>? ?? [];
    final rawWinners = json['winners'] as List<dynamic>? ?? [];

    return TambolaGameState(
      game: TambolaGame.fromJson(json['game'] as Map<String, dynamic>? ?? {}),
      players: rawPlayers.map((p) => TambolaPlayer.fromJson(p as Map<String, dynamic>)).toList(),
      draws: rawDraws.map((d) => TambolaDraw.fromJson(d as Map<String, dynamic>)).toList(),
      winners: rawWinners.map((w) => TambolaWinner.fromJson(w as Map<String, dynamic>)).toList(),
      myTicket: json['myTicket'] != null ? TambolaTicket.fromJson(json['myTicket'] as Map<String, dynamic>) : null,
      isHost: (json['isHost'] ?? json['host'] ?? (json['game'] != null ? (json['game']['isHost'] ?? json['game']['host']) : null)) as bool? ?? false,
    );
  }

  Set<int> get drawnNumbersSet => draws.map((d) => d.number).toSet();

  bool isPrizeClaimed(String prizeType) {
    final p = prizeType.toUpperCase();
    return winners.any((w) => w.prizeType == p);
  }

  TambolaWinner? getWinnerForPrize(String prizeType) {
    final p = prizeType.toUpperCase();
    try {
      return winners.firstWhere((w) => w.prizeType == p);
    } catch (_) {
      return null;
    }
  }
}
