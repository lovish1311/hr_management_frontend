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
        throw Exception('Failed to load dashboard stats (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  @override
  Future<void> updateLeaveStatus(int id, String status) async {
    final url = Uri.parse('$_baseUrl/api/v1/leaves/$id/status?status=$status');
    try {
      final response = await http.put(
        url,
        headers: AuthStorage.authHeaders,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update leave request status (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
