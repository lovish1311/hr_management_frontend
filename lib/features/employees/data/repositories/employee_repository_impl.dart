import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  @override
  Future<List<Employee>> getEmployees({String? departmentFilter}) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees');
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          return [];
        }
        final list = decoded.map((jsonItem) => Employee.fromJson(jsonItem as Map<String, dynamic>)).toList();
        
        if (departmentFilter == null || departmentFilter == 'All') {
          return list;
        }
        return list.where((e) => e.department.toLowerCase() == departmentFilter.toLowerCase()).toList();
      } else {
        throw Exception('Failed to load employees (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/$id');
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        return Employee.fromJson(decoded);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load employee details (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
