import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/services/permission_socket_service.dart';
import 'package:hr_management/features/auth/data/auth_api_service.dart';

/// Immutable State Model for Authentication and Login Page
class LoginState {
  final bool isLoading;
  final bool isProductionMode;
  final bool obscurePassword;
  final bool rememberMe;
  final String? errorMessage;
  final AccountStatus? accountStatus;
  final bool isCheckingStatus;

  const LoginState({
    this.isLoading = false,
    this.isProductionMode = false,
    this.obscurePassword = true,
    this.rememberMe = true,
    this.errorMessage,
    this.accountStatus,
    this.isCheckingStatus = false,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isProductionMode,
    bool? obscurePassword,
    bool? rememberMe,
    String? errorMessage,
    bool clearErrorMessage = false,
    AccountStatus? accountStatus,
    bool clearAccountStatus = false,
    bool? isCheckingStatus,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isProductionMode: isProductionMode ?? this.isProductionMode,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      accountStatus: clearAccountStatus ? null : (accountStatus ?? this.accountStatus),
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
    );
  }
}

/// Notifier that manages all business logic, asynchronous authentication,
/// debounced account verification, and preference storage for LoginPage.
class LoginNotifier extends Notifier<LoginState> {
  Timer? _debounceTimer;

  @override
  LoginState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    _loadPreferences();
    return const LoginState();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isProd = prefs.getBool('is_production_login_mode') ?? false;
      state = state.copyWith(isProductionMode: isProd);
    } catch (_) {}
  }

  Future<void> toggleMode(bool isProduction) async {
    _debounceTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_production_login_mode', isProduction);
    } catch (_) {}

    state = state.copyWith(
      isProductionMode: isProduction,
      clearErrorMessage: true,
      clearAccountStatus: true,
      isCheckingStatus: false,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearErrorMessage: true);
    }
  }

  /// Debounced 350ms verification of account lifecycle status (ACTIVE, PENDING_ACTIVATION, DEACTIVATED, NOT_FOUND)
  void onEmailChanged(String rawEmail) {
    _debounceTimer?.cancel();
    final email = rawEmail.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      if (state.accountStatus != null || state.isCheckingStatus) {
        state = state.copyWith(
          clearAccountStatus: true,
          isCheckingStatus: false,
        );
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      checkAccountStatus(email);
    });
  }

  Future<void> checkAccountStatus(String email) async {
    state = state.copyWith(isCheckingStatus: true);
    try {
      final status = await AuthApiService.getAccountStatus(email);
      state = state.copyWith(
        accountStatus: status,
        isCheckingStatus: false,
      );
    } catch (_) {
      state = state.copyWith(isCheckingStatus: false);
    }
  }

  /// Executes authentication request and initializes global session storage and WebSocket listeners.
  /// Returns response map on success, or throws [AuthException] / [Exception] on failure.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
    );

    final cleanEmail = email.trim();
    try {
      final response = await AuthApiService.login(
        email: cleanEmail,
        password: password,
      );

      if (response['token'] != null) {
        final rawAuths = response['authorities'] as List<dynamic>?;
        final authorities = rawAuths?.map((e) => e.toString()).toList();
        await AuthStorage.setAuth(
          token: response['token'],
          email: response['email'],
          role: response['role'],
          systemRole: response['systemRole'],
          designation: response['designation'],
          employeeId: response['employeeId'] != null ? (response['employeeId'] as num).toInt() : null,
          authorities: authorities,
        );
        PermissionSocketService.instance.init();
      }

      state = state.copyWith(isLoading: false);
      return response;
    } on AuthException catch (e) {
      if (e.isPendingActivation) {
        state = state.copyWith(
          isLoading: false,
          clearErrorMessage: true,
          accountStatus: AccountStatus(
            email: cleanEmail,
            status: 'PENDING_ACTIVATION',
            isActivated: false,
            message: e.message,
          ),
        );
      } else if (e.isDeactivated) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
          accountStatus: AccountStatus(
            email: cleanEmail,
            status: 'DEACTIVATED',
            isActivated: true,
            message: e.message,
          ),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
        );
      }
      rethrow;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Called after successful first-time account activation to update the status reactively
  void setAccountActivated(String email) {
    AuthApiService.clearStatusCache(email);
    state = state.copyWith(
      clearErrorMessage: true,
      accountStatus: AccountStatus(
        email: email,
        status: 'ACTIVE',
        isActivated: true,
        message: 'Account is active.',
      ),
    );
  }
}

/// Global Riverpod Provider for Authentication & Login State
final loginProvider = NotifierProvider.autoDispose<LoginNotifier, LoginState>(LoginNotifier.new);
