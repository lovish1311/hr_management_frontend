import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:hr_management/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:hr_management/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Dependency Injection provider for [DashboardRepository]
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl();
});

/// Immutable State Model for Dashboard metrics, leave approvals, and UI state
class DashboardState {
  final bool isLoading;
  final bool isActionLoading;
  final DashboardStats? stats;
  final List<LeaveRequest> pendingLeaves;
  final String? errorMessage;
  final String? actionErrorMessage;

  const DashboardState({
    this.isLoading = true,
    this.isActionLoading = false,
    this.stats,
    this.pendingLeaves = const [],
    this.errorMessage,
    this.actionErrorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    DashboardStats? stats,
    List<LeaveRequest>? pendingLeaves,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      stats: stats ?? this.stats,
      pendingLeaves: pendingLeaves ?? this.pendingLeaves,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionErrorMessage ? null : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }
}

/// Notifier managing dashboard metrics, reactive refresh triggers, and leave approvals
class DashboardNotifier extends Notifier<DashboardState> {
  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  @override
  DashboardState build() {
    // 1. Reactive hook: listen to permission revisions (e.g. role escalation or WebSocket updates)
    void onPermissionsChanged() {
      loadDashboard(silent: true);
    }

    AuthStorage.permissionRevision.addListener(onPermissionsChanged);
    ref.onDispose(() {
      AuthStorage.permissionRevision.removeListener(onPermissionsChanged);
    });

    // 2. Initial fetch
    Future.microtask(() => loadDashboard());

    return const DashboardState(isLoading: true);
  }

  /// Fetches dashboard summary and pending leave requests from the repository.
  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      );
    }

    try {
      final stats = await _repository.getDashboardStats();
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        stats: stats,
        pendingLeaves: List.from(stats.pendingLeaves),
        clearErrorMessage: true,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Updates status of a leave request (e.g. APPROVED or REJECTED).
  ///
  /// Optionally executes [onBeforeRemove] to coordinate with UI exit animations.
  Future<bool> updateLeaveStatus({
    required int leaveId,
    required String status,
    void Function()? onBeforeRemove,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearActionErrorMessage: true,
    );

    try {
      // 1. Submit update to backend API
      await _repository.updateLeaveStatus(leaveId, status);

      // 2. Invoke UI hook (e.g. AnimatedList removal transition)
      onBeforeRemove?.call();

      // 3. Allow exit animation to complete smoothly
      await Future.delayed(const Duration(milliseconds: 350));
      if (!ref.mounted) return true;

      // 4. Background sync with fresh KPI stats
      final freshStats = await _repository.getDashboardStats();
      if (!ref.mounted) return true;
      state = state.copyWith(
        stats: freshStats,
        pendingLeaves: List.from(freshStats.pendingLeaves),
        isActionLoading: false,
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Global Riverpod Provider for Dashboard State Management
final dashboardProvider = NotifierProvider.autoDispose<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
