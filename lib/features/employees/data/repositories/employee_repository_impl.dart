import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/network/api_client.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {

  String get _baseUrl => ApiConfig.baseUrl;

  // In-memory cache for UI state reactivity
  static List<Employee>? _cachedEmployees;

  void _updateLocalCache(Employee employee) {
    if (_cachedEmployees == null) {
      _cachedEmployees = [employee];
      return;
    }
    final index = _cachedEmployees!.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _cachedEmployees![index] = employee;
    } else {
      _cachedEmployees!.insert(0, employee);
    }
  }

  @override
  Future<List<Employee>> getEmployees({String? departmentFilter}) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees');
    List<Employee> list = [];

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final fromApi = decoded
              .map((jsonItem) => Employee.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
          _cachedEmployees = fromApi;
          list = fromApi;
        } else {
          list = _cachedEmployees ?? [];
        }
      } else {
        list = _cachedEmployees ?? [];
      }
    } catch (e) {
      debugPrint('Employees API connect error, using cache/fallback: $e');
      list = _cachedEmployees ?? _getMockEmployeeList();
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
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final emp = Employee.fromJson(decoded);
          _updateLocalCache(emp);
          return emp;
        }
      } else if (response.statusCode == 404) {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching employee by id ($id): $e');
    }

    // Fallback to cache ONLY if network fails
    if (_cachedEmployees != null) {
      final match = _cachedEmployees!.where((e) => e.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees');
    try {
      final res = await ApiClient.post(
        url,
        body: json.encode({
          'firstName': employee.firstName,
          'lastName': employee.lastName,
          'email': employee.email,
          'phoneNumber': employee.phone,
          'department': employee.department,
          'designation': employee.designation,
          'role': employee.role,
          'status': employee.status,
          'address': employee.address,
          'emergencyContactName': employee.emergencyContactName,
          'emergencyContactPhone': employee.emergencyContactPhone,
          'employmentType': employee.employmentType,
          if (employee.dateOfBirth.isNotEmpty) 'dateOfBirth': employee.dateOfBirth,
          if (employee.joiningDate.isNotEmpty) 'joiningDate': employee.joiningDate,
          'isAttendanceTracked': employee.isAttendanceTracked,
          'departmentCategory': employee.departmentCategory,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = json.decode(res.body);
        final created = Employee.fromJson(decoded as Map<String, dynamic>);
        _updateLocalCache(created);
        return created;
      }
    } catch (e) {
      debugPrint('Create employee API error: $e');
    }

    final newId = employee.id.isNotEmpty ? employee.id : (DateTime.now().millisecondsSinceEpoch % 100000).toString();
    final assignedCode = employee.employeeCode.isNotEmpty ? employee.employeeCode : 'EMP-$newId';
    final created = employee.copyWith(
      id: newId,
      employeeCode: assignedCode,
    );
    _updateLocalCache(created);
    return created;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/${employee.id}');
    try {
      final res = await ApiClient.put(
        url,
        body: json.encode({
          'firstName': employee.firstName,
          'lastName': employee.lastName,
          'email': employee.email,
          'phoneNumber': employee.phone,
          'department': employee.department,
          'designation': employee.designation,
          'role': employee.role,
          'status': employee.status,
          'address': employee.address,
          'emergencyContactName': employee.emergencyContactName,
          'emergencyContactPhone': employee.emergencyContactPhone,
          'employmentType': employee.employmentType,
          if (employee.dateOfBirth.isNotEmpty) 'dateOfBirth': employee.dateOfBirth,
          if (employee.joiningDate.isNotEmpty) 'joiningDate': employee.joiningDate,
          'isAttendanceTracked': employee.isAttendanceTracked,
          'departmentCategory': employee.departmentCategory,
          if (employee.lateArrivalAllowedUntil != null) 'lateArrivalAllowedUntil': employee.lateArrivalAllowedUntil,
          if (employee.earlyOutAllowedAfter != null) 'earlyOutAllowedAfter': employee.earlyOutAllowedAfter,
        }),
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final updated = Employee.fromJson(decoded as Map<String, dynamic>);
        _updateLocalCache(updated);
        return updated;
      }
    } catch (e) {
      debugPrint('Update employee API error: $e');
    }

    _updateLocalCache(employee);
    return employee;
  }

  @override
  Future<bool> toggleEmployeeStatus(String id, String newStatus) async {
    final emp = await getEmployeeById(id);
    if (emp == null) return false;
    final isProbation = (newStatus.toUpperCase() == 'PROBATION');
    final isNotice = (newStatus.toUpperCase() == 'NOTICE' || newStatus.toUpperCase() == 'NOTICE_PERIOD');
    final updated = emp.copyWith(
      status: newStatus.toUpperCase(),
      isProbation: isProbation ? true : emp.isProbation,
      isNoticePeriod: isNotice ? true : (newStatus.toUpperCase() == 'ACTIVE' ? false : emp.isNoticePeriod),
    );
    await updateEmployee(updated);
    return true;
  }

  @override
  Future<bool> assignManager(String employeeId, String managerId) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/$employeeId/manager');
    try {
      final res = await ApiClient.patch(
        url,
        body: json.encode({'managerId': int.tryParse(managerId)}),
      );
      if (res.statusCode == 200) {
        await getEmployeeById(employeeId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Assign manager API error: $e');
      return false;
    }
  }

  @override
  Future<bool> updatePermissions(String employeeId, {bool? isAttendanceTracked, String? lateArrivalAllowedUntil, String? earlyOutAllowedAfter}) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/$employeeId/permissions');
    try {
      final res = await ApiClient.patch(
        url,
        body: json.encode({
          if (isAttendanceTracked != null) 'isAttendanceTracked': isAttendanceTracked,
          if (lateArrivalAllowedUntil != null) 'lateArrivalAllowedUntil': lateArrivalAllowedUntil,
          if (earlyOutAllowedAfter != null) 'earlyOutAllowedAfter': earlyOutAllowedAfter,
        }),
      );
      if (res.statusCode == 200) {
        await getEmployeeById(employeeId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update permissions API error: $e');
      return false;
    }
  }

  @override
  Future<bool> elevateRoleAndAuthorities(
    String employeeId, {
    required String role,
    String? systemRole,
    required List<String> authorities,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/employees/$employeeId/elevate');
    try {
      final payload = <String, dynamic>{
        'role': role,
        'authorities': authorities,
      };
      if (systemRole != null && systemRole.isNotEmpty) {
        payload['systemRole'] = systemRole;
      }
      final res = await ApiClient.put(
        url,
        body: json.encode(payload),
      );
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic>) {
          _updateLocalCache(Employee.fromJson(decoded));
        } else {
          await getEmployeeById(employeeId);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Elevate role and authorities API error: $e');
      return false;
    }
  }

  @override
  Future<List<Employee>> searchEmployeesPaginated({String? query, int page = 0, int size = 50}) async {
    final queryStr = query != null && query.isNotEmpty ? 'query=${Uri.encodeComponent(query)}&' : '';
    final url = Uri.parse('$_baseUrl/api/v1/employees/search?${queryStr}page=$page&size=$size');
    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['content'] is List) {
          final List content = decoded['content'];
          return content.map((jsonItem) => Employee.fromJson(jsonItem as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Paginated search API error: $e');
    }

    // Local fallback/mock pagination
    final mockList = _cachedEmployees ?? _getMockEmployeeList();
    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      final filtered = mockList.where((e) =>
        e.name.toLowerCase().contains(lower) ||
        e.email.toLowerCase().contains(lower) ||
        e.role.toLowerCase().contains(lower)
      ).toList();
      return filtered;
    }

    final start = page * size;
    if (start >= mockList.length) return [];
    final end = (start + size).clamp(0, mockList.length);
    return mockList.sublist(start, end);
  }

  List<Employee> _getMockEmployeeList() {
    return [
      Employee(id: '1', employeeCode: 'EMP-001', name: 'Super Admin', role: 'SUPER_ADMIN', department: 'Executive', designation: 'System Admin', status: 'ACTIVE', email: 'admin@company.com', phone: '+91 98123 00001', managerName: 'System', isAttendanceTracked: false, dateOfBirth: '1985-01-10', emergencyContactName: 'Admin Contact', emergencyContactPhone: '+91 98000 00001'),
      Employee(id: '2', employeeCode: 'EMP-002', name: 'Aadisha Dhullar', role: 'HR', department: 'Human Resources', designation: 'HR Lead', status: 'ACTIVE', email: 'hr@company.com', phone: '+91 98123 00002', managerName: 'Super Admin', isAttendanceTracked: false, dateOfBirth: '1994-06-18', emergencyContactName: 'Dhullar Family', emergencyContactPhone: '+91 98000 00002'),
      Employee(id: '3', employeeCode: 'EMP-101', name: 'Harsh Kaushal', role: 'MANAGER', department: 'Engineering', designation: 'Engineering Lead', status: 'ACTIVE', email: 'harsh.kaushal@company.com', phone: '+91 98123 00101', managerName: 'Super Admin', isAttendanceTracked: false, dateOfBirth: '1989-03-25', emergencyContactName: 'Kaushal Contact', emergencyContactPhone: '+91 98000 00101'),
      Employee(id: '4', employeeCode: 'EMP-102', name: 'Naveen Chandra Tiwari', role: 'MANAGER', department: 'Product', designation: 'Product Manager', status: 'ACTIVE', email: 'naveen.tiwari@company.com', phone: '+91 98123 00102', managerName: 'Super Admin', isAttendanceTracked: false, dateOfBirth: '1988-11-12', emergencyContactName: 'Tiwari Contact', emergencyContactPhone: '+91 98000 00102'),
      Employee(id: '5', employeeCode: 'EMP-103', name: 'Ankesh Verma', role: 'MANAGER', department: 'Sales & Marketing', designation: 'Sales Director', status: 'ACTIVE', email: 'ankesh.verma@company.com', phone: '+91 98123 00103', managerName: 'Super Admin', isAttendanceTracked: false, dateOfBirth: '1990-07-08', emergencyContactName: 'Verma Contact', emergencyContactPhone: '+91 98000 00103'),
      Employee(id: '6', employeeCode: 'EMP-201', name: 'Ishu Saini', role: 'EMPLOYEE', department: 'Engineering', designation: 'Senior Software Developer', status: 'ACTIVE', email: 'ishu.saini@company.com', phone: '+91 98123 45201', managerName: 'Harsh Kaushal', isAttendanceTracked: true, dateOfBirth: '1997-04-12', emergencyContactName: 'Saini Contact', emergencyContactPhone: '+91 98000 45201'),
      Employee(id: '7', employeeCode: 'EMP-202', name: 'Lovish Kumar', role: 'EMPLOYEE', department: 'Engineering', designation: 'Senior Software Developer', status: 'ACTIVE', email: 'lovish@company.com', phone: '+91 98123 45202', managerName: 'Harsh Kaushal', isAttendanceTracked: true, dateOfBirth: '1996-08-19', emergencyContactName: 'Kumar Contact', emergencyContactPhone: '+91 98000 45202'),
      Employee(id: '8', employeeCode: 'EMP-203', name: 'Abhishek Gaur', role: 'EMPLOYEE', department: 'Engineering', designation: 'Frontend Developer', status: 'ACTIVE', email: 'abhishek.g@company.com', phone: '+91 98123 45203', managerName: 'Harsh Kaushal', isAttendanceTracked: true, dateOfBirth: '1998-02-14', emergencyContactName: 'Gaur Contact', emergencyContactPhone: '+91 98000 45203'),
      Employee(id: '9', employeeCode: 'EMP-204', name: 'Abhinav Singh', role: 'EMPLOYEE', department: 'Engineering', designation: 'Backend Developer', status: 'ACTIVE', email: 'abhinav@company.com', phone: '+91 98123 45204', managerName: 'Harsh Kaushal', isAttendanceTracked: true, dateOfBirth: '1997-11-05', emergencyContactName: 'Singh Contact', emergencyContactPhone: '+91 98000 45204'),
      Employee(id: '10', employeeCode: 'EMP-205', name: 'Gurkirat Singh', role: 'EMPLOYEE', department: 'Engineering', designation: 'Tech Lead', status: 'ACTIVE', email: 'gurkirat@company.com', phone: '+91 98123 45205', managerName: 'Harsh Kaushal', isAttendanceTracked: true, dateOfBirth: '1995-09-30', emergencyContactName: 'Singh Contact', emergencyContactPhone: '+91 98000 45205'),
      Employee(id: '11', employeeCode: 'EMP-206', name: 'Ashish Chaudhari', role: 'EMPLOYEE', department: 'Engineering', designation: 'QA Engineer', status: 'ACTIVE', email: 'ashish@company.com', phone: '+91 98123 45206', managerName: 'Harsh Kaushal', isAttendanceTracked: true, dateOfBirth: '1999-01-22', emergencyContactName: 'Chaudhari Contact', emergencyContactPhone: '+91 98000 45206'),
      // Example Employee in Probation
      Employee(
        id: '12', 
        employeeCode: 'EMP-207', 
        name: 'Aman Dhiman', 
        role: 'EMPLOYEE', 
        department: 'Engineering', 
        designation: 'Junior Software Developer', 
        status: 'PROBATION', 
        email: 'aman@company.com', 
        phone: '+91 98123 45207', 
        managerName: 'Harsh Kaushal', 
        isAttendanceTracked: true, 
        dateOfBirth: '2000-06-15', 
        emergencyContactName: 'Dhiman Contact', 
        emergencyContactPhone: '+91 98000 45207',
        isProbation: true,
        probationStartDate: '2026-07-01',
        probationDurationMonths: 3,
        probationEndDate: '2026-10-01',
      ),
      // Another Employee in Probation (joined after 15th)
      Employee(
        id: '13', 
        employeeCode: 'EMP-208', 
        name: 'Aniket Sharma', 
        role: 'EMPLOYEE', 
        department: 'Engineering', 
        designation: 'Software Engineer', 
        status: 'PROBATION', 
        email: 'aniket@company.com', 
        phone: '+91 98123 45208', 
        managerName: 'Harsh Kaushal', 
        isAttendanceTracked: true, 
        dateOfBirth: '1998-10-18', 
        emergencyContactName: 'Sharma Contact', 
        emergencyContactPhone: '+91 98000 45208',
        isProbation: true,
        probationStartDate: '2026-08-20',
        probationDurationMonths: 2,
        probationEndDate: '2026-10-20',
      ),
      // Example Employee serving Notice Period
      Employee(
        id: '14', 
        employeeCode: 'EMP-209', 
        name: 'Abhishek Yadav', 
        role: 'EMPLOYEE', 
        department: 'Product', 
        designation: 'Product Analyst', 
        status: 'NOTICE_PERIOD', 
        email: 'abhishek.yadav@company.com', 
        phone: '+91 98123 45209', 
        managerName: 'Naveen Chandra Tiwari', 
        isAttendanceTracked: true, 
        dateOfBirth: '1996-03-29', 
        emergencyContactName: 'Yadav Contact', 
        emergencyContactPhone: '+91 98000 45209',
        isNoticePeriod: true,
        noticeStartDate: '2026-09-01',
        noticeDurationDays: 60,
        noticeEndDate: '2026-10-31',
      ),
      Employee(id: '15', employeeCode: 'EMP-210', name: 'Nikhilesh Thakur', role: 'EMPLOYEE', department: 'Product', designation: 'Senior Product Analyst', status: 'ACTIVE', email: 'nikhilesh@company.com', phone: '+91 98123 45210', managerName: 'Naveen Chandra Tiwari', isAttendanceTracked: true, dateOfBirth: '1995-12-04', emergencyContactName: 'Thakur Contact', emergencyContactPhone: '+91 98000 45210'),
      Employee(id: '16', employeeCode: 'EMP-211', name: 'Kuldeep Singh', role: 'EMPLOYEE', department: 'Product', designation: 'Technical Writer', status: 'ACTIVE', email: 'kuldeep@company.com', phone: '+91 98123 45211', managerName: 'Naveen Chandra Tiwari', isAttendanceTracked: true, dateOfBirth: '1994-07-21', emergencyContactName: 'Singh Contact', emergencyContactPhone: '+91 98000 45211'),
      Employee(id: '17', employeeCode: 'EMP-212', name: 'Abhishek Thakur', role: 'EMPLOYEE', department: 'Product', designation: 'Business Analyst', status: 'ACTIVE', email: 'abhishek.thakur@company.com', phone: '+91 98123 45212', managerName: 'Naveen Chandra Tiwari', isAttendanceTracked: true, dateOfBirth: '1997-05-09', emergencyContactName: 'Thakur Contact', emergencyContactPhone: '+91 98000 45212'),
      Employee(id: '18', employeeCode: 'EMP-213', name: 'Parav Taneja', role: 'EMPLOYEE', department: 'Product', designation: 'QA Engineer', status: 'ACTIVE', email: 'parav@company.com', phone: '+91 98123 45213', managerName: 'Naveen Chandra Tiwari', isAttendanceTracked: true, dateOfBirth: '1999-09-17', emergencyContactName: 'Taneja Contact', emergencyContactPhone: '+91 98000 45213'),
      Employee(id: '19', employeeCode: 'EMP-214', name: 'Anshu Sharma', role: 'EMPLOYEE', department: 'Marketing', designation: 'Content Writer', status: 'ACTIVE', email: 'anshu@company.com', phone: '+91 98123 45214', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1998-08-25', emergencyContactName: 'Sharma Contact', emergencyContactPhone: '+91 98000 45214'),
      Employee(id: '20', employeeCode: 'EMP-215', name: 'Nisha Verma', role: 'EMPLOYEE', department: 'Marketing', designation: 'Digital Marketing Specialist', status: 'ACTIVE', email: 'nisha@company.com', phone: '+91 98123 45215', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1997-02-11', emergencyContactName: 'Verma Contact', emergencyContactPhone: '+91 98000 45215'),
      Employee(id: '21', employeeCode: 'EMP-216', name: 'Mehak Gupta', role: 'EMPLOYEE', department: 'Design', designation: 'UI/UX Designer', status: 'ACTIVE', email: 'mehak@company.com', phone: '+91 98123 45216', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1996-10-31', emergencyContactName: 'Gupta Contact', emergencyContactPhone: '+91 98000 45216'),
      Employee(id: '22', employeeCode: 'EMP-217', name: 'Harleen Kaur', role: 'EMPLOYEE', department: 'Design', designation: 'Graphic Designer', status: 'ACTIVE', email: 'harleen@company.com', phone: '+91 98123 45217', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1998-04-05', emergencyContactName: 'Kaur Contact', emergencyContactPhone: '+91 98000 45217'),
      Employee(id: '23', employeeCode: 'EMP-218', name: 'Jyoti Rani', role: 'EMPLOYEE', department: 'Operations', designation: 'Operations Executive', status: 'ACTIVE', email: 'jyoti@company.com', phone: '+91 98123 45218', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1995-01-19', emergencyContactName: 'Rani Contact', emergencyContactPhone: '+91 98000 45218'),
      Employee(id: '24', employeeCode: 'EMP-219', name: 'Sadham Hussain', role: 'EMPLOYEE', department: 'Sales', designation: 'BDE', status: 'ACTIVE', email: 'sadham@company.com', phone: '+91 98123 45219', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1997-06-30', emergencyContactName: 'Hussain Contact', emergencyContactPhone: '+91 98000 45219'),
      Employee(id: '25', employeeCode: 'EMP-220', name: 'Vishali Devi', role: 'EMPLOYEE', department: 'Sales', designation: 'BDM', status: 'ACTIVE', email: 'vishali@company.com', phone: '+91 98123 45220', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1996-12-14', emergencyContactName: 'Devi Contact', emergencyContactPhone: '+91 98000 45220'),
      Employee(id: '26', employeeCode: 'EMP-221', name: 'Anjali Kumari', role: 'EMPLOYEE', department: 'Design', designation: 'Motion Artist', status: 'ACTIVE', email: 'anjali@company.com', phone: '+91 98123 45221', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1998-07-28', emergencyContactName: 'Kumari Contact', emergencyContactPhone: '+91 98000 45221'),
      Employee(id: '27', employeeCode: 'EMP-222', name: 'Chanda Rani', role: 'EMPLOYEE', department: 'Design', designation: 'UI/UX Designer', status: 'ACTIVE', email: 'chanda@company.com', phone: '+91 98123 45222', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1997-03-03', emergencyContactName: 'Rani Contact', emergencyContactPhone: '+91 98000 45222'),
      Employee(id: '28', employeeCode: 'EMP-223', name: 'Palak Sharma', role: 'EMPLOYEE', department: 'Marketing', designation: 'SEO Analyst', status: 'ACTIVE', email: 'palak@company.com', phone: '+91 98123 45223', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1999-05-16', emergencyContactName: 'Sharma Contact', emergencyContactPhone: '+91 98000 45223'),
      Employee(id: '29', employeeCode: 'EMP-224', name: 'Nuri Naz', role: 'EMPLOYEE', department: 'Sales', designation: 'BDE', status: 'ACTIVE', email: 'nuri@company.com', phone: '+91 98123 45224', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1998-11-20', emergencyContactName: 'Naz Contact', emergencyContactPhone: '+91 98000 45224'),
      Employee(id: '30', employeeCode: 'EMP-225', name: 'Mehak Dhillon', role: 'EMPLOYEE', department: 'Design', designation: 'Graphic Designer', status: 'ACTIVE', email: 'mehak.dhillon@company.com', phone: '+91 98123 45225', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1997-09-08', emergencyContactName: 'Dhillon Contact', emergencyContactPhone: '+91 98000 45225'),
      Employee(id: '31', employeeCode: 'EMP-226', name: 'Pradeep Negi', role: 'EMPLOYEE', department: 'Sales', designation: 'Sales Executive', status: 'ACTIVE', email: 'pradeep@company.com', phone: '+91 98123 45226', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1996-02-24', emergencyContactName: 'Negi Contact', emergencyContactPhone: '+91 98000 45226'),
      Employee(id: '32', employeeCode: 'EMP-227', name: 'Sakshi Sharma', role: 'EMPLOYEE', department: 'Marketing', designation: 'Content Writer', status: 'ACTIVE', email: 'sakshi@company.com', phone: '+91 98123 45227', managerName: 'Ankesh Verma', isAttendanceTracked: true, dateOfBirth: '1998-10-02', emergencyContactName: 'Sharma Contact', emergencyContactPhone: '+91 98000 45227'),
      // Example Deactivated / Inactive Employee
      Employee(
        id: '33', 
        employeeCode: 'EMP-228', 
        name: 'Sahil Billowria', 
        role: 'EMPLOYEE', 
        department: 'Sales', 
        designation: 'BDE', 
        status: 'INACTIVE', 
        email: 'sahil@company.com', 
        phone: '+91 98123 45228', 
        managerName: 'Ankesh Verma', 
        isAttendanceTracked: false, 
        dateOfBirth: '1997-07-13', 
        emergencyContactName: 'Billowria Contact', 
        emergencyContactPhone: '+91 98000 45228',
      ),
    ];
  }
}
