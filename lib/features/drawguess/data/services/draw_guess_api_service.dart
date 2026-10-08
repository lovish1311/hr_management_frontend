import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../models/draw_guess_models.dart';

class DrawGuessApiService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/games/draw-and-guess';

  static Future<DrawGuessRoom> createRoom({
    String? roomName,
    int maxRounds = 3,
    int drawTimeSeconds = 80,
    int wordChoiceCount = 3,
    String category = 'GENERAL',
    bool customWordsOnly = false,
  }) async {
    final url = Uri.parse('$_baseUrl/rooms');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({
        if (roomName != null && roomName.isNotEmpty) 'roomName': roomName,
        'maxRounds': maxRounds,
        'drawTimeSeconds': drawTimeSeconds,
        'wordChoiceCount': wordChoiceCount,
        'category': category,
        'customWordsOnly': customWordsOnly,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DrawGuessRoom.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to create Draw & Guess room');
    }
  }

  static Future<DrawGuessRoom> joinRoom(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/join');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({'roomCode': cleanCode}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DrawGuessRoom.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to join Draw & Guess room');
    }
  }

  static Future<DrawGuessRoom> getRoomDetails(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/$cleanCode');
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return DrawGuessRoom.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get room details');
    }
  }

  static Future<Map<String, dynamic>> getGameState(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/$cleanCode/state');
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _handleError(response);
      throw Exception('Failed to get game state');
    }
  }

  static Future<void> startGame(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/$cleanCode/start');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  static Future<void> restartGame(
    String roomCode, {
    int? maxRounds,
    int? drawTimeSeconds,
    int? wordChoiceCount,
    String? category,
    bool? customWordsOnly,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/$cleanCode/restart');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({
        if (maxRounds != null) 'maxRounds': maxRounds,
        if (drawTimeSeconds != null) 'drawTimeSeconds': drawTimeSeconds,
        if (wordChoiceCount != null) 'wordChoiceCount': wordChoiceCount,
        if (category != null && category.isNotEmpty) 'category': category,
        if (customWordsOnly != null) 'customWordsOnly': customWordsOnly,
      }),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  static Future<void> selectWord(String roomCode, String word) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/$cleanCode/select-word');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({'word': word}),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  static Future<GuessResult> submitGuess(String roomCode, String guess) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('$_baseUrl/rooms/$cleanCode/guess');
    final response = await http.post(
      url,
      headers: AuthStorage.authHeaders,
      body: jsonEncode({'guess': guess}),
    );

    if (response.statusCode == 200) {
      return GuessResult.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to submit guess');
    }
  }

  static Future<List<String>> getCategories() async {
    final url = Uri.parse('$_baseUrl/categories');
    final response = await http.get(
      url,
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => e.toString()).toList();
    } else {
      return ['GENERAL', 'TECH', 'HR_OFFICE', 'ANIMALS', 'NATURE', 'FOOD', 'OBJECTS'];
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
