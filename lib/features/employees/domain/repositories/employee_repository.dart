import 'package:hr_management/features/employees/domain/entities/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees({String? departmentFilter});
  Future<Employee?> getEmployeeById(String id);
}
