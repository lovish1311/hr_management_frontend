import 'package:hr_management/core/network/api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/attendance/domain/entities/attendance_calendar_day.dart';
import 'package:hr_management/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  String get _baseUrl => ApiConfig.baseUrl;

  @override
  Future<List<AttendanceCalendarDay>> getMonthlyCalendarSummary({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/attendance/calendar-summary?employeeId=$employeeId&year=$year&month=$month');
    try {
      final response = await http.get(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => AttendanceCalendarDay.fromJson(item)).toList();
      } else {
        debugPrint('Attendance calendar endpoint status ${response.statusCode}: ${response.body}');
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('Authentication session expired or unauthorized (${response.statusCode}). Please sign in again.');
        }
        throw Exception('Failed to load attendance calendar (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to fetch attendance calendar summary from backend: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> importBiometricExcel({
    required List<int> fileBytes,
    required String fileName,
    required DateTime targetDate,
  }) async {
    final dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse('$_baseUrl/api/v1/attendance/import-biometric?targetDate=$dateStr');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthStorage.authHeaders);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Import biometric status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to import biometric excel file: $e');
    }
    return null;
  }


}
