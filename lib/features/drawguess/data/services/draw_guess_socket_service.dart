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
  Timer? _reconnectTimer;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onEvent => _eventController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isReconnecting = false;
  bool get isReconnecting => _isReconnecting;

  bool _isDisposed = false;
  String? _targetRoomCode;
  int _reconnectAttempts = 0;

  void connect(String roomCode) {
    _isDisposed = false;
    _targetRoomCode = roomCode.trim().toUpperCase();
    _reconnectAttempts = 0;
    _establishConnection();
  }

  void _establishConnection() {
    if (_isDisposed || _targetRoomCode == null) return;
    _reconnectTimer?.cancel();
    _cleanupCurrentChannel();

    final token = AuthStorage.token ?? '';
    final uri = Uri.parse(
        '${ApiConfig.wsUrl}/ws/scribbil?roomCode=$_targetRoomCode&token=$token');

    debugPrint('Connecting to Draw & Guess WebSocket: $uri (attempt $_reconnectAttempts)');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

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
          _handleConnectionLost();
        },
        onDone: () {
          debugPrint('Draw & Guess WebSocket connection closed');
          _handleConnectionLost();
        },
      );

      _startPingTimer();
    } catch (e) {
      debugPrint('Failed to connect to Draw & Guess WebSocket: $e');
      _handleConnectionLost();
    }
  }

  void _handleConnectionLost() {
    if (_isDisposed || _targetRoomCode == null) return;
    _isConnected = false;
    _isReconnecting = true;
    _connectionStateController.add(false);

    _cleanupCurrentChannel();

    // Exponential backoff capped at 5 seconds
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts > 3) ? 5 : (_reconnectAttempts * 2);
    debugPrint('Scheduling WebSocket reconnect in ${delaySeconds}s (attempt $_reconnectAttempts)...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed && !_isConnected && _targetRoomCode != null) {
        _establishConnection();
      }
    });
  }

  void _cleanupCurrentChannel() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
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
    _isDisposed = true;
    _targetRoomCode = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanupCurrentChannel();
    _isConnected = false;
    _isReconnecting = false;
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}
