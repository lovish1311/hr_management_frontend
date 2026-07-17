import 'package:hr_management/features/employees/domain/entities/employee.dart';

class DummyEmployeeRepository {
  static final List<Employee> _employees = [
    Employee(
      id: '0031',
      name: 'Sarah Jenkins',
      role: 'UI/UX Designer',
      department: 'Design',
      status: 'Active',
      email: 'sarah.j@teamjoy.co',
      phone: '+1-555-0101',
      managerName: 'Alex Smith',
      dateOfBirth: 'Aug 15, 1988',
      location: 'San Francisco, USA',
      emergencyContactName: 'Mark Jenkins',
      emergencyContactPhone: '+1-555-0901',
      attendanceRate: 98,
      leaveBalance: 12,
    ),
    Employee(
      id: '0032',
      name: 'Marcus Doe',
      role: 'Frontend Developer',
      department: 'Engineering',
      status: 'Active',
      email: 'marcus.d@teamjoy.co',
      phone: '+1-555-0102',
      managerName: 'Sarah Jenkins',
      dateOfBirth: 'Nov 02, 1992',
      location: 'Austin, USA',
      emergencyContactName: 'Jane Doe',
      emergencyContactPhone: '+1-555-0902',
      attendanceRate: 95,
      leaveBalance: 15,
    ),
    Employee(
      id: '0034',
      name: 'Alisha Sharma',
      role: 'Senior Developer',
      department: 'Engineering',
      status: 'Active',
      email: 'alisha.s@teamjoy.co',
      phone: '+1-555-0123',
      managerName: 'Sarah Jenkins',
      dateOfBirth: 'July 12, 1990',
      location: 'New York, USA',
      emergencyContactName: 'David Sharma',
      emergencyContactPhone: '+1-555-0987',
      attendanceRate: 96,
      leaveBalance: 14,
    ),
    Employee(
      id: '0035',
      name: 'Robert Chen',
      role: 'Product Manager',
      department: 'Manager',
      status: 'Active',
      email: 'robert.c@teamjoy.co',
      phone: '+1-555-0105',
      managerName: 'Alex Smith',
      dateOfBirth: 'Feb 20, 1985',
      location: 'Seattle, USA',
      emergencyContactName: 'Lisa Chen',
      emergencyContactPhone: '+1-555-0905',
      attendanceRate: 99,
      leaveBalance: 10,
    ),
    Employee(
      id: '0036',
      name: 'Maria Garcia',
      role: 'HR Specialist',
      department: 'HR',
      status: 'Active',
      email: 'maria.g@teamjoy.co',
      phone: '+1-555-0106',
      managerName: 'Alex Smith',
      dateOfBirth: 'Mar 10, 1991',
      location: 'Miami, USA',
      emergencyContactName: 'Carlos Garcia',
      emergencyContactPhone: '+1-555-0906',
      attendanceRate: 97,
      leaveBalance: 18,
    ),
    Employee(
      id: '0037',
      name: 'David Lee',
      role: 'Marketing Associate',
      department: 'Marketing',
      status: 'Active',
      email: 'david.l@teamjoy.co',
      phone: '+1-555-0107',
      managerName: 'Robert Chen',
      dateOfBirth: 'Sep 05, 1994',
      location: 'Chicago, USA',
      emergencyContactName: 'Susan Lee',
      emergencyContactPhone: '+1-555-0907',
      attendanceRate: 94,
      leaveBalance: 20,
    ),
    Employee(
      id: '0038',
      name: 'Emily White',
      role: 'Financial Analyst',
      department: 'Finance',
      status: 'Active',
      email: 'emily.w@teamjoy.co',
      phone: '+1-555-0108',
      managerName: 'Alex Smith',
      dateOfBirth: 'Dec 18, 1989',
      location: 'Boston, USA',
      emergencyContactName: 'James White',
      emergencyContactPhone: '+1-555-0908',
      attendanceRate: 98,
      leaveBalance: 11,
    ),
  ];

  Future<List<Employee>> getEmployees({String? departmentFilter}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (departmentFilter == null || departmentFilter == 'All') {
      return _employees;
    }
    return _employees.where((e) => e.department == departmentFilter).toList();
  }

  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
