import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/draw_guess_models.dart';

class DrawGuessSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onEvent => _eventController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentRoomCode;

  void connect(String roomCode) {
    if (_isConnected && _currentRoomCode == roomCode) return;
    disconnect();

    _currentRoomCode = roomCode.trim().toUpperCase();
    final token = AuthStorage.token ?? '';
    final uri = Uri.parse(
        '${ApiConfig.wsUrl}/ws/scribbil?roomCode=$_currentRoomCode&token=$token');

    debugPrint('Connecting to Draw & Guess WebSocket: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(data.toString());
            _eventController.add(decoded);
          } catch (e) {
            debugPrint('Draw & Guess WebSocket message parse error: $e');
          }
        },
        onError: (err) {
          debugPrint('Draw & Guess WebSocket error: $err');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('Draw & Guess WebSocket connection closed');
          _isConnected = false;
        },
      );

      _startPingTimer();
    } catch (e) {
      debugPrint('Failed to connect to Draw & Guess WebSocket: $e');
      _isConnected = false;
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'PING'}));
        } catch (_) {}
      }
    });
  }

  void sendStroke(DrawStroke stroke) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'STROKE',
        'stroke': stroke.toJson(),
      }));
    } catch (e) {
      debugPrint('Failed to send stroke: $e');
    }
  }

  void sendClear() {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'CLEAR'}));
    } catch (e) {
      debugPrint('Failed to send clear: $e');
    }
  }

  void sendUndo() {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'UNDO'}));
    } catch (e) {
      debugPrint('Failed to send undo: $e');
    }
  }

  void sendGuess(String guess) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'GUESS',
        'guess': guess.trim(),
      }));
    } catch (e) {
      debugPrint('Failed to send guess: $e');
    }
  }

  void sendSelectWord(String word) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'SELECT_WORD',
        'word': word,
      }));
    } catch (e) {
      debugPrint('Failed to send select word: $e');
    }
  }

  void sendStartGame() {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'START_GAME'}));
    } catch (e) {
      debugPrint('Failed to send start game: $e');
    }
  }

  void sendChatMessage(String message) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'CHAT',
        'message': message.trim(),
      }));
    } catch (e) {
      debugPrint('Failed to send chat message: $e');
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    _currentRoomCode = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
