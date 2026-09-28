import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../models/holiday_model.dart';

class HolidayService {
  static String get _baseUrl => "${ApiConfig.baseUrl}/api/v1/holidays";
  static String get _leaveUrl => "${ApiConfig.baseUrl}/api/v1/leaves";

  // ==========================================
  // EMPLOYEE: Calendar & Apply
  // ==========================================

  static Future<EmployeeHolidayCalendarModel> getEmployeeHolidayCalendar(
      int year, {int? employeeId}) async {
    final empId = employeeId ?? AuthStorage.employeeId;
    final queryParams = {'year': year.toString()};
    if (empId != null) {
      queryParams['employeeId'] = empId.toString();
    }
    final uri = Uri.parse('$_baseUrl/calendar').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: AuthStorage.authHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return EmployeeHolidayCalendarModel.fromJson(data);
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to load holiday calendar (Status: ${response.statusCode})");
    }
  }

  static Future<void> applyForRestrictedHoliday({
    required HolidayModel holiday,
    String? reason,
  }) async {
    final empId = AuthStorage.employeeId;
    if (empId == null) {
      throw Exception("Employee ID is missing from user session");
    }

    final dateStr =
        "${holiday.date.year.toString().padLeft(4, '0')}-${holiday.date.month.toString().padLeft(2, '0')}-${holiday.date.day.toString().padLeft(2, '0')}";

    final body = json.encode({
      'employeeId': empId,
      'startDate': dateStr,
      'endDate': dateStr,
      'leaveType': 'RESTRICTED_HOLIDAY',
      'reason': (reason != null && reason.trim().isNotEmpty)
          ? reason.trim()
          : 'Restricted Holiday application for ${holiday.name}',
    });

    final response = await http.post(
      Uri.parse('$_leaveUrl/apply'),
      headers: AuthStorage.authHeaders,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to apply for Restricted Holiday (Status: ${response.statusCode})");
    }
  }

  // ==========================================
  // ADMIN: Lists Management
  // ==========================================

  static Future<List<HolidayListModel>> getHolidayLists(int year) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/lists?year=$year'),
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => HolidayListModel.fromJson(json)).toList();
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to load holiday lists (Status: ${response.statusCode})");
    }
  }

  static Future<HolidayListModel> getHolidayListDetails(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/lists/$id'),
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HolidayListModel.fromJson(data);
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to load holiday list details");
    }
  }

  static Future<HolidayListModel> createHolidayList({
    required String name,
    required int year,
    String? description,
    String applicableGroup = 'ALL',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/lists'),
      headers: AuthStorage.authHeaders,
      body: json.encode({
        'name': name.trim(),
        'year': year,
        'description': description,
        'applicableGroup': applicableGroup,
        'active': true,
        'published': false,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return HolidayListModel.fromJson(data);
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to create holiday list");
    }
  }

  static Future<HolidayListModel> updateHolidayList({
    required int id,
    String? name,
    String? description,
    bool? active,
    String? applicableGroup,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/lists/$id'),
      headers: AuthStorage.authHeaders,
      body: json.encode({
        if (name != null) 'name': name.trim(),
        if (description != null) 'description': description,
        if (active != null) 'active': active,
        if (applicableGroup != null) 'applicableGroup': applicableGroup,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HolidayListModel.fromJson(data);
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to update holiday list");
    }
  }

  static Future<void> togglePublishHolidayList(int id, bool published) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/lists/$id/publish'),
      headers: AuthStorage.authHeaders,
      body: json.encode({'published': published}),
    );

    if (response.statusCode != 200) {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to toggle publish status");
    }
  }

  static Future<void> deleteHolidayList(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/lists/$id'),
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to delete holiday list");
    }
  }

  // ==========================================
  // ADMIN: Holiday Entries Management
  // ==========================================

  static Future<HolidayModel> addHoliday({
    required int holidayListId,
    required String name,
    required DateTime date,
    required String type,
    String? description,
  }) async {
    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse('$_baseUrl/lists/$holidayListId/holidays'),
      headers: AuthStorage.authHeaders,
      body: json.encode({
        'name': name.trim(),
        'date': dateStr,
        'type': type.toUpperCase(),
        'description': description,
        'active': true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return HolidayModel.fromJson(data);
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to add holiday");
    }
  }

  static Future<HolidayModel> updateHoliday({
    required int id,
    String? name,
    DateTime? date,
    String? type,
    String? description,
    bool? active,
  }) async {
    String? dateStr;
    if (date != null) {
      dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: AuthStorage.authHeaders,
      body: json.encode({
        if (name != null) 'name': name.trim(),
        if (dateStr != null) 'date': dateStr,
        if (type != null) 'type': type.toUpperCase(),
        if (description != null) 'description': description,
        if (active != null) 'active': active,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HolidayModel.fromJson(data);
    } else {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to update holiday");
    }
  }

  static Future<void> deleteHoliday(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: AuthStorage.authHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg.isNotEmpty ? msg : "Failed to delete holiday");
    }
  }

  static String _parseErrorMessage(String responseBody) {
    try {
      final jsonMap = json.decode(responseBody);
      if (jsonMap is Map) {
        if (jsonMap.containsKey('message')) return jsonMap['message'].toString();
        if (jsonMap.containsKey('error')) return jsonMap['error'].toString();
      }
    } catch (_) {}
    return responseBody;
  }
}
