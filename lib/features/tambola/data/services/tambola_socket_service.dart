import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hr_management/core/network/api_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TambolaSocketService {
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
    final uri = Uri.parse('${ApiConfig.wsUrl}/ws/tambola?roomCode=$_currentRoomCode');

    debugPrint('Connecting to Tambola WebSocket: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(data.toString());
            _eventController.add(decoded);
          } catch (e) {
            debugPrint('Tambola WebSocket message parse error: $e');
          }
        },
        onError: (err) {
          debugPrint('Tambola WebSocket error: $err');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('Tambola WebSocket connection closed');
          _isConnected = false;
        },
      );

      // Start ping heartbeat every 20 seconds
      _pingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        if (_isConnected && _channel != null) {
          try {
            _channel!.sink.add(jsonEncode({'type': 'PING'}));
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Failed to connect to Tambola WebSocket: $e');
      _isConnected = false;
    }
  }

  void send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
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
