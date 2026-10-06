import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../models/game_models.dart';

class GameApiService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/games';

  static List<CompanyGame> get defaultGames => [
    CompanyGame(
      gameKey: 'TAMBOLA',
      title: 'Tambola Housie',
      description: 'Classic Indian 90-ball multiplayer Housie with live sync caller board, smart ticket daubing, and real-time prize claims.',
      category: 'Multiplayer Social',
      iconName: 'confirmation_number_rounded',
      gradientStart: '#312E81',
      gradientEnd: '#4338CA',
      isEnabled: true,
      allowedRoles: 'ROLE_EMPLOYEE,ROLE_HR_ADMIN,ROLE_SUPER_ADMIN',
      minPlayers: 2,
      maxPlayers: 100,
    ),
    CompanyGame(
      gameKey: 'DRAW_AND_GUESS',
      title: 'Draw & Guess',
      description: 'Real-time multiplayer drawing and guessing game. Compete with teammates, sketch words, and guess fast for high scores.',
      category: 'Multiplayer Drawing',
      iconName: 'brush_rounded',
      gradientStart: '#0D9488',
      gradientEnd: '#14B8A6',
      isEnabled: true,
      allowedRoles: 'ROLE_EMPLOYEE,ROLE_HR_ADMIN,ROLE_SUPER_ADMIN,ROLE_HR,ROLE_MANAGER',
      minPlayers: 2,
      maxPlayers: 20,
    ),
  ];

  static Future<List<CompanyGame>> getAllGames() async {
    try {
      final url = Uri.parse(_baseUrl);
      final response = await http.get(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final games = list.map((g) => CompanyGame.fromJson(g as Map<String, dynamic>)).toList();
        if (games.isNotEmpty) return games;
      }
    } catch (_) {
      // Graceful offline/auth fallback
    }
    return defaultGames;
  }

  static Future<CompanyGame> toggleGameStatus(String gameKey, bool isEnabled) async {
    try {
      final url = Uri.parse('$_baseUrl/$gameKey/status?isEnabled=$isEnabled');
      final response = await http.patch(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        return CompanyGame.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    final fallback = defaultGames.firstWhere(
      (g) => g.gameKey == gameKey,
      orElse: () => defaultGames.first,
    );
    return fallback.copyWith(isEnabled: isEnabled);
  }

  static Future<CompanyGame> updateGameAccess(String gameKey, String allowedRoles) async {
    final url = Uri.parse('$_baseUrl/$gameKey/access?allowedRoles=$allowedRoles');
    final response = await http.patch(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return CompanyGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to update game access');
    }
  }

  static void _handleError(http.Response response) {
    String message = 'HTTP ${response.statusCode}';
    try {
      final data = jsonDecode(response.body);
      message = data['message'] ?? data[
          'error'] ?? message;
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }
    throw Exception(message);
  }
}
