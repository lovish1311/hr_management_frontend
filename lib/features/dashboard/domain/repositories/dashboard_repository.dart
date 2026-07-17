import 'package:hr_management/features/dashboard/domain/entities/dashboard_stats.dart';

// Package: hr_management

abstract class DashboardRepository {
  Future<DashboardStats> getDashboardStats();
  Future<void> updateLeaveStatus(int id, String status);
}
