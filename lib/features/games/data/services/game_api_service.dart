import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../models/game_models.dart';

class GameApiService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/games';

  static Future<List<CompanyGame>> getAllGames() async {
    final url = Uri.parse(_baseUrl);
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((g) => CompanyGame.fromJson(g as Map<String, dynamic>)).toList();
    } else {
      _handleError(response);
      return [];
    }
  }

  static Future<CompanyGame> toggleGameStatus(String gameKey, bool isEnabled) async {
    final url = Uri.parse('$_baseUrl/$gameKey/status?isEnabled=$isEnabled');
    final response = await http.patch(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return CompanyGame.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to update game status');
    }
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
      message = data['message'] ?? data['error'] ?? message;
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }
    throw Exception(message);
  }
}
