import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../models/tambola_models.dart';

class TambolaApiService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/tambola';

  static Future<TambolaGame> createGame({String? title, int? autoDrawInterval}) async {
    final url = Uri.parse('$_baseUrl/create');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({
        if (title != null && title.isNotEmpty) 'title': title,
        if (autoDrawInterval != null) 'autoDrawIntervalSeconds': autoDrawInterval,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TambolaGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to create game');
    }
  }

  static Future<TambolaTicket> joinGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/join/$cleanCode');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TambolaTicket.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to join game');
    }
  }

  static Future<List<TambolaGame>> getActiveGames() async {
    final url = Uri.parse('$_baseUrl/games');
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((g) => TambolaGame.fromJson(g as Map<String, dynamic>)).toList();
    } else {
      _handleError(response);
      return [];
    }
  }

  static Future<TambolaGameState> getGameState(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/state');
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return TambolaGameState.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get game state');
    }
  }

  static Future<TambolaTicket?> getTicket(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/ticket');
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return TambolaTicket.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      _handleError(response);
      return null;
    }
  }

  static Future<TambolaGame> startGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/start');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return TambolaGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to start game');
    }
  }

  static Future<TambolaDraw> drawNumber(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/draw');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return TambolaDraw.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to draw number');
    }
  }

  static Future<TambolaClaimResult> claimPrize(String roomCode, String prizeType) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/claim');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({'prizeType': prizeType}),
    );

    if (response.statusCode == 200) {
      return TambolaClaimResult.fromJson(jsonDecode(response.body));
    } else {
      String message = 'Claim failed';
      try {
        final err = jsonDecode(response.body);
        message = err['message'] ?? err['error'] ?? message;
      } catch (_) {
        if (response.body.isNotEmpty) message = response.body;
      }

      if (response.statusCode == 409) {
        throw Exception('Prize already claimed: $message');
      } else if (response.statusCode == 400) {
        throw Exception('Bogus claim: $message');
      } else {
        throw Exception(message);
      }
    }
  }

  static Future<TambolaGame> pauseGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/pause');
    final response = await http.post(url, headers: AuthStorage.authHeaders);
    if (response.statusCode == 200) {
      return TambolaGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to pause game');
    }
  }

  static Future<TambolaGame> resumeGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/resume');
    final response = await http.post(url, headers: AuthStorage.authHeaders);
    if (response.statusCode == 200) {
      return TambolaGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to resume game');
    }
  }

  static Future<TambolaGame> endGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/end');
    final response = await http.post(url, headers: AuthStorage.authHeaders);
    if (response.statusCode == 200) {
      return TambolaGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to end game');
    }
  }

  static Future<TambolaGame> restartGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/game/$cleanCode/restart');
    final response = await http.post(url, headers: AuthStorage.authHeaders);
    if (response.statusCode == 200) {
      return TambolaGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to restart game');
    }
  }

  static void _handleError(http.Response response) {
    String message = 'HTTP ${response.statusCode}';
    try {
      final data = jsonDecode(response.body);
      message = data['message'] ?? data['error'] ?? message;
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }
    throw Exception(message);
  }
}
