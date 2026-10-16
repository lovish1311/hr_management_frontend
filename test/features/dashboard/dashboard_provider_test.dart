import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/core/widgets/kpi_card.dart';
import 'package:hr_management/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:hr_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hr_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hr_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../helpers/test_app_wrapper.dart';

class MockDashboardRepository implements DashboardRepository {
  DashboardStats statsToReturn;
  bool shouldThrow = false;
  final List<Map<String, dynamic>> updateLeaveCalls = [];

  MockDashboardRepository({DashboardStats? initialStats})
      : statsToReturn = initialStats ??
            DashboardStats(
              totalEmployees: 25,
              presentToday: 22,
              onLeaveToday: 3,
              pendingLeaves: [
                LeaveRequest(
                  id: 101,
                  employeeName: 'Rahul Sharma',
                  startDate: '2026-10-20',
                  endDate: '2026-10-22',
                  reason: 'Family Event',
                ),
                LeaveRequest(
                  id: 102,
                  employeeName: 'Priya Patel',
                  startDate: '2026-10-25',
                  endDate: '2026-10-26',
                  reason: 'Medical checkup',
                ),
              ],
            );

  @override
  Future<DashboardStats> getDashboardStats() async {
    if (shouldThrow) {
      throw Exception('Server unreachable');
    }
    return statsToReturn;
  }

  @override
  Future<void> updateLeaveStatus(int id, String status) async {
    if (shouldThrow) {
      throw Exception('Failed to update leave');
    }
    updateLeaveCalls.add({'id': id, 'status': status});
    // Remove the leave from mock stats so subsequent getDashboardStats reflects the change
    statsToReturn = statsToReturn.copyWith(
      pendingLeaves: statsToReturn.pendingLeaves.where((l) => l.id != id).toList(),
      onLeaveToday: status == 'APPROVED' ? statsToReturn.onLeaveToday + 1 : statsToReturn.onLeaveToday,
    );
  }
}

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Dashboard Riverpod Provider Unit Tests', () {
    test('DashboardNotifier initializes, loads stats, and updates state', () async {
      final mockRepo = MockDashboardRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(dashboardProvider, (_, __) {});

      // Initially starts loading
      expect(container.read(dashboardProvider).isLoading, isTrue);

      // Await microtask and load
      await container.read(dashboardProvider.notifier).loadDashboard();

      final state = container.read(dashboardProvider);
      expect(state.isLoading, isFalse);
      expect(state.stats?.totalEmployees, 25);
      expect(state.stats?.presentToday, 22);
      expect(state.stats?.onLeaveToday, 3);
      expect(state.pendingLeaves.length, 2);
      expect(state.pendingLeaves.first.employeeName, 'Rahul Sharma');
      expect(state.errorMessage, isNull);
    });

    test('DashboardNotifier handles repository error gracefully with retry', () async {
      final mockRepo = MockDashboardRepository()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(dashboardProvider, (_, __) {});

      await container.read(dashboardProvider.notifier).loadDashboard();

      final errorState = container.read(dashboardProvider);
      expect(errorState.isLoading, isFalse);
      expect(errorState.errorMessage, contains('Server unreachable'));

      // Retry when server recovers
      mockRepo.shouldThrow = false;
      await container.read(dashboardProvider.notifier).loadDashboard();

      final recoveredState = container.read(dashboardProvider);
      expect(recoveredState.isLoading, isFalse);
      expect(recoveredState.errorMessage, isNull);
      expect(recoveredState.stats?.totalEmployees, 25);
    });

    test('updateLeaveStatus successfully approves leave and updates metrics', () async {
      final mockRepo = MockDashboardRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(dashboardProvider, (_, __) {});

      await container.read(dashboardProvider.notifier).loadDashboard();
      expect(container.read(dashboardProvider).pendingLeaves.length, 2);

      bool hookCalled = false;
      final result = await container.read(dashboardProvider.notifier).updateLeaveStatus(
        leaveId: 101,
        status: 'APPROVED',
        onBeforeRemove: () {
          hookCalled = true;
        },
      );

      expect(result, isTrue);
      expect(hookCalled, isTrue);
      expect(mockRepo.updateLeaveCalls.length, 1);
      expect(mockRepo.updateLeaveCalls.first['id'], 101);
      expect(mockRepo.updateLeaveCalls.first['status'], 'APPROVED');

      final updatedState = container.read(dashboardProvider);
      expect(updatedState.isActionLoading, isFalse);
      expect(updatedState.pendingLeaves.length, 1);
      expect(updatedState.pendingLeaves.first.id, 102);
      expect(updatedState.stats?.onLeaveToday, 4);
    });

    test('updateLeaveStatus captures error and resets isActionLoading when API fails', () async {
      final mockRepo = MockDashboardRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(dashboardProvider, (_, __) {});

      await container.read(dashboardProvider.notifier).loadDashboard();

      mockRepo.shouldThrow = true;
      final result = await container.read(dashboardProvider.notifier).updateLeaveStatus(
        leaveId: 101,
        status: 'REJECTED',
      );

      expect(result, isFalse);
      final state = container.read(dashboardProvider);
      expect(state.isActionLoading, isFalse);
      expect(state.actionErrorMessage, contains('Failed to update leave'));
      expect(state.pendingLeaves.length, 2); // preserved on error
    });
  });

  group('DashboardPage Riverpod Widget Integration Tests', () {
    testWidgets('Renders KPI cards, pending leave approvals, and quick actions', (tester) async {
      final mockRepo = MockDashboardRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: TestAppWrapper.wrapWidget(
            const DashboardPage(),
            size: const Size(1200, 900),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check greeting & header
      expect(find.textContaining('Good '), findsOneWidget);
      expect(find.text('Total Employees'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('Present Today'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('On Leave Today'), findsOneWidget);
      expect(find.widgetWithText(KpiCard, 'On Leave Today'), findsOneWidget);

      // Check quick actions
      expect(find.text('Add Employee'), findsOneWidget);
      expect(find.text('Mark log today'), findsOneWidget);
      expect(find.text('Time off request'), findsOneWidget);

      // Check pending leave approvals
      expect(find.text('Pending Leave Approvals'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Priya Patel'), findsOneWidget);
    });

    testWidgets('Approve action triggers repository update and animates tile', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockDashboardRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: TestAppWrapper.wrapWidget(
            const DashboardPage(),
            size: const Size(1200, 1600),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find approve button on the first tile
      final approveButtons = find.widgetWithText(ElevatedButton, 'Approve');
      expect(approveButtons, findsWidgets);

      await tester.ensureVisible(approveButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(approveButtons.first);
      await tester.pump(); // Start action loading spinner
      await tester.pump(const Duration(milliseconds: 400)); // Finish 350ms delay & animation
      await tester.pumpAndSettle();

      expect(mockRepo.updateLeaveCalls.length, 1);
      expect(mockRepo.updateLeaveCalls.first['id'], 101);
      expect(mockRepo.updateLeaveCalls.first['status'], 'APPROVED');

      // Rahul Sharma should be removed, Priya Patel remains
      expect(find.text('Rahul Sharma'), findsNothing);
      expect(find.text('Priya Patel'), findsOneWidget);
    });
  });
}
