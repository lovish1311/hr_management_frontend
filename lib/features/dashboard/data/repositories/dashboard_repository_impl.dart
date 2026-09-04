import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:hr_management/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  @override
  Future<DashboardStats> getDashboardStats() async {
    final url = Uri.parse('$_baseUrl/api/v1/dashboard');
    try {
      final response = await http.get(
        url,
        headers: AuthStorage.authHeaders,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return DashboardStats.fromJson(data);
      } else {
        debugPrint('Dashboard stats endpoint returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to connect to backend dashboard endpoint: $e');
    }

    // Return 0 / empty list if offline or error occurs
    return DashboardStats(
      totalEmployees: 0,
      presentToday: 0,
      onLeaveToday: 0,
      pendingLeaves: [],
    );
  }

  @override
  Future<void> updateLeaveStatus(int id, String status) async {
    final url = Uri.parse('$_baseUrl/api/v1/leaves/$id/status');
    final approverId = AuthStorage.employeeId ?? 1;
    final body = json.encode({
      'status': status,
      'rejectionReason': status == 'REJECTED' ? 'Rejected by Admin' : '',
      'approverId': approverId.toString(),
    });
    try {
      final response = await http.put(
        url,
        headers: AuthStorage.authHeaders,
        body: body,
      );
      if (response.statusCode == 200) {
        debugPrint('Successfully updated leave ID $id status to $status');
        return;
      } else {
        debugPrint('Failed to update leave status. Server returned ${response.statusCode}: ${response.body}');
        throw Exception('Server error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating leave status via backend API: $e');
      rethrow;
    }
  }
}
