import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PermissionRouteTracker extends NavigatorObserver {
  static String? currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      currentRoute = route.settings.name;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      currentRoute = newRoute?.settings.name;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      currentRoute = previousRoute?.settings.name;
    }
  }
}

class PermissionSocketService {
  PermissionSocketService._();
  static final PermissionSocketService instance = PermissionSocketService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  int? _connectedEmployeeId;

  void init() {
    final empId = AuthStorage.employeeId;
    if (empId != null) {
      connect(empId);
    }
  }

  void connect(int employeeId) {
    if (_isConnected && _connectedEmployeeId == employeeId) return;
    disconnect();

    _connectedEmployeeId = employeeId;
    final uri = Uri.parse('${ApiConfig.wsUrl}/ws/permissions?employeeId=$employeeId');
    debugPrint('Connecting to Permission WebSocket: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> event = jsonDecode(data.toString());
            _handleEvent(event);
          } catch (e) {
            debugPrint('Permission WebSocket parse error: $e');
          }
        },
        onError: (err) {
          debugPrint('Permission WebSocket error: $err');
          _onDisconnected();
        },
        onDone: () {
          debugPrint('Permission WebSocket closed');
          _onDisconnected();
        },
      );

      // Heartbeat ping every 20 seconds
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_isConnected && _channel != null) {
          try {
            _channel!.sink.add(jsonEncode({'type': 'PING'}));
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Failed to connect Permission WebSocket: $e');
      _onDisconnected();
    }
  }

  Future<void> _handleEvent(Map<String, dynamic> event) async {
    final type = event['type']?.toString().toUpperCase();
    if (type == 'PERMISSIONS_UPDATED') {
      debugPrint('⚡ Real-time permission update received via WebSocket: $event');

      final wasPayrollManager = AuthStorage.canManagePayroll;
      final wasAdmin = AuthStorage.isAdmin;
      final wasHr = AuthStorage.isHr;

      final String? newRole = event['role']?.toString();
      final String? newSystemRole = event['systemRole']?.toString();
      final List<dynamic>? rawAuths = event['authorities'] as List<dynamic>?;
      final List<String>? newAuths = rawAuths?.map((a) => a.toString()).toList();

      // Atomically update local cache and trigger UI rebuilds
      await AuthStorage.updatePermissionsDirect(
        role: newRole,
        systemRole: newSystemRole,
        authorities: newAuths,
      );

      final lostPayroll = wasPayrollManager && !AuthStorage.canManagePayroll;
      final lostAdmin = wasAdmin && !AuthStorage.isAdmin;
      final lostHr = wasHr && !AuthStorage.isHr;

      final currentRoute = PermissionRouteTracker.currentRoute ?? '';

      // Check if user is currently inside a restricted screen
      final isInsidePayrollScreen = currentRoute == '/payroll_process' ||
          currentRoute == '/payroll_inputs' ||
          currentRoute == '/salary_structure';

      final isInsideAdminScreen = currentRoute == '/employees' ||
          currentRoute == '/hr_leave_settings' ||
          currentRoute == '/holiday_management';

      final shouldKickOut = (lostPayroll && isInsidePayrollScreen) ||
          ((lostAdmin || lostHr) && isInsideAdminScreen);

      if (shouldKickOut) {
        debugPrint('🚫 Current route $currentRoute revoked. Redirecting to home dashboard...');
        final nav = navigatorKey.currentState;
        if (nav != null) {
          nav.pushNamedAndRemoveUntil('/', (route) => false);

          // Give a subtle delay so dashboard mounts before showing feedback
          Future.delayed(const Duration(milliseconds: 300), () {
            final context = navigatorKey.currentContext;
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.security_update_warning_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lostPayroll
                              ? 'Your Payroll permissions were updated by an administrator. You have been redirected to the dashboard.'
                              : 'Your administrative access was updated. You have been redirected to the dashboard.',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFE11D48),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          });
        }
      }
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    // Reconnect after 3 seconds if employee is still logged in
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      final empId = AuthStorage.employeeId;
      if (empId != null && empId == _connectedEmployeeId) {
        connect(empId);
      }
    });
  }

  void disconnect() {
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connectedEmployeeId = null;
  }
}
