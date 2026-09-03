import 'package:hr_management/features/employees/domain/entities/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees({String? departmentFilter});
  Future<Employee?> getEmployeeById(String id);
  Future<bool> assignManager(String employeeId, String managerId);
  Future<bool> updatePermissions(String employeeId, {bool? isAttendanceTracked, String? lateArrivalAllowedUntil, String? earlyOutAllowedAfter});
  Future<List<Employee>> searchEmployeesPaginated({String? query, int page = 0, int size = 50});
}
