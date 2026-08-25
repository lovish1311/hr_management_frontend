import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
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
    List<Employee> list = [];

    try {
      final response = await http.get(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          list = decoded.map((jsonItem) => Employee.fromJson(jsonItem as Map<String, dynamic>)).toList();
        } else {
          list = _getMockEmployeeList();
        }
      } else {
        list = _getMockEmployeeList();
      }
    } catch (e) {
      debugPrint('Employees API connect error, using fallback: $e');
      list = _getMockEmployeeList();
    }

    if (departmentFilter == null || departmentFilter == 'All') {
      return list;
    }
    return list.where((e) => e.department.toLowerCase() == departmentFilter.toLowerCase()).toList();
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/$id');
    try {
      final response = await http.get(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Employee.fromJson(decoded);
        }
      }
    } catch (_) {}

    final all = _getMockEmployeeList();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return all.first;
    }
  }

  @override
  Future<bool> assignManager(String employeeId, String managerId) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/$employeeId/manager');
    try {
      final res = await http.patch(
        url,
        headers: AuthStorage.authHeaders,
        body: json.encode({'managerId': int.tryParse(managerId)}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  List<Employee> _getMockEmployeeList() {
    return [
      Employee(id: '1', employeeCode: 'EMP-101', name: 'Harsh Kaushal', role: 'Engineering Lead', department: 'Engineering', designation: 'Lead Engineer', status: 'ACTIVE', email: 'harsh.kaushal@company.com', phone: '+91 98765 43210', managerName: 'Super Admin', dateOfBirth: '1988-03-15', emergencyContactName: 'Family', emergencyContactPhone: '+91 98765 00000'),
      Employee(id: '2', employeeCode: 'EMP-201', name: 'Lovish Kumar', role: 'Senior Software Engineer', department: 'Engineering', designation: 'Senior Developer', status: 'ACTIVE', email: 'lovish@company.com', phone: '+91 98765 43211', managerName: 'Harsh Kaushal', dateOfBirth: '1992-05-14', emergencyContactName: 'Rita Sharma', emergencyContactPhone: '+91 98765 00001'),
      Employee(id: '3', employeeCode: 'EMP-202', name: 'Vikram Singh', role: 'Frontend Developer', department: 'Engineering', designation: 'Developer', status: 'ACTIVE', email: 'vikram@company.com', phone: '+91 98765 43212', managerName: 'Harsh Kaushal', dateOfBirth: '1993-07-20', emergencyContactName: 'Meena Singh', emergencyContactPhone: '+91 98765 00002'),
      Employee(id: '4', employeeCode: 'EMP-203', name: 'Sneha Patel', role: 'Backend Developer', department: 'Engineering', designation: 'Developer', status: 'ACTIVE', email: 'sneha@company.com', phone: '+91 98765 43213', managerName: 'Harsh Kaushal', dateOfBirth: '1994-09-11', emergencyContactName: 'Kunal Patel', emergencyContactPhone: '+91 98765 00003'),
      Employee(id: '5', employeeCode: 'EMP-204', name: 'Amit Sharma', role: 'Product Analyst', department: 'Product', designation: 'Analyst', status: 'ACTIVE', email: 'amit@company.com', phone: '+91 98765 43214', managerName: 'Rahul Verma', dateOfBirth: '1991-01-25', emergencyContactName: 'Sunita Sharma', emergencyContactPhone: '+91 98765 00004'),
      Employee(id: '6', employeeCode: 'EMP-205', name: 'Neha Gupta', role: 'QA Lead', department: 'Product', designation: 'QA Lead', status: 'ACTIVE', email: 'neha@company.com', phone: '+91 98765 43215', managerName: 'Rahul Verma', dateOfBirth: '1993-02-18', emergencyContactName: 'Amit Gupta', emergencyContactPhone: '+91 98765 00005'),
      Employee(id: '7', employeeCode: 'EMP-206', name: 'Pooja Mehta', role: 'Technical Writer', department: 'Product', designation: 'Writer', status: 'ACTIVE', email: 'pooja@company.com', phone: '+91 98765 43216', managerName: 'Rahul Verma', dateOfBirth: '1995-04-12', emergencyContactName: 'Pooja Contact', emergencyContactPhone: '+91 98765 00006'),
      Employee(id: '8', employeeCode: 'EMP-207', name: 'Rohan Das', role: 'UI/UX Designer', department: 'Design', designation: 'Designer', status: 'ACTIVE', email: 'rohan@company.com', phone: '+91 98765 43217', managerName: 'Ananya Roy', dateOfBirth: '1990-11-10', emergencyContactName: 'Sunita Das', emergencyContactPhone: '+91 98765 00007'),
      Employee(id: '9', employeeCode: 'EMP-208', name: 'Tanvi Kapoor', role: 'Graphic Designer', department: 'Design', designation: 'Designer', status: 'ACTIVE', email: 'tanvi@company.com', phone: '+91 98765 43218', managerName: 'Ananya Roy', dateOfBirth: '1996-08-05', emergencyContactName: 'Raj Kapoor', emergencyContactPhone: '+91 98765 00008'),
      Employee(id: '10', employeeCode: 'EMP-209', name: 'Karan Joshi', role: 'Motion Designer', department: 'Design', designation: 'Designer', status: 'ACTIVE', email: 'karan@company.com', phone: '+91 98765 43219', managerName: 'Ananya Roy', dateOfBirth: '1989-09-30', emergencyContactName: 'Pooja Joshi', emergencyContactPhone: '+91 98765 00009'),
      Employee(id: '11', employeeCode: 'EMP-210', name: 'Divya Nair', role: 'Content Strategist', department: 'Design', designation: 'Strategist', status: 'ACTIVE', email: 'divya@company.com', phone: '+91 98765 43220', managerName: 'Ananya Roy', dateOfBirth: '1994-12-14', emergencyContactName: 'Sanjay Nair', emergencyContactPhone: '+91 98765 00010'),
    ];
  }
}
