class Employee {
  final String id;
  final String employeeCode;
  final String name;
  final String firstName;
  final String lastName;
  final String role;
  final String department;
  final String designation;
  final String status;
  final String email;
  final String phone;
  final String managerName;
  final String? managerId;
  final String dateOfBirth;
  final String joiningDate;
  final String employmentType;
  final String address;
  final String location;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int leaveBalance;
  final int attendanceRate;
  final bool isAttendanceTracked;
  final String departmentCategory;
  final String? lateArrivalAllowedUntil;
  final String? earlyOutAllowedAfter;
  final String todayAttendanceStatus;

  Employee({
    required this.id,
    this.employeeCode = '',
    required this.name,
    this.firstName = '',
    this.lastName = '',
    required this.role,
    required this.department,
    this.designation = '',
    required this.status,
    required this.email,
    required this.phone,
    required this.managerName,
    this.managerId,
    required this.dateOfBirth,
    this.joiningDate = '',
    this.employmentType = 'FULL_TIME',
    this.address = '',
    this.location = 'Headquarters',
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.leaveBalance = 14,
    this.attendanceRate = 96,
    this.isAttendanceTracked = true,
    this.departmentCategory = 'General',
    this.lateArrivalAllowedUntil,
    this.earlyOutAllowedAfter,
    this.todayAttendanceStatus = 'ABSENT',
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final fn = json['firstName'] ?? '';
    final ln = json['lastName'] ?? '';
    final fullName = '$fn $ln'.trim();

    return Employee(
      id: (json['id'] ?? '').toString(),
      employeeCode: json['employeeCode'] ?? 'EMP-${json['id'] ?? ''}',
      name: fullName.isNotEmpty ? fullName : (json['name'] ?? 'Unnamed Employee'),
      firstName: fn,
      lastName: ln,
      role: json['role'] ?? 'EMPLOYEE',
      department: json['department'] ?? 'General',
      designation: json['designation'] ?? json['role'] ?? 'Team Member',
      status: json['status'] ?? 'ACTIVE',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? json['phone'] ?? '',
      managerName: json['managerName'] ?? 'Unassigned',
      managerId: json['managerId']?.toString(),
      dateOfBirth: json['dateOfBirth'] ?? '',
      joiningDate: json['joiningDate'] ?? '',
      employmentType: json['employmentType'] ?? 'FULL_TIME',
      address: json['address'] ?? '',
      location: json['location'] ?? ((json['address'] != null && json['address'].toString().trim().isNotEmpty) ? json['address'].toString() : 'Headquarters'),
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      leaveBalance: json['leaveBalance'] != null ? (json['leaveBalance'] as num).toInt() : 14,
      attendanceRate: json['attendanceRate'] != null ? (json['attendanceRate'] as num).toInt() : 96,
      isAttendanceTracked: json['isAttendanceTracked'] ?? (json['role'] != 'MANAGER' && json['role'] != 'HR' && json['role'] != 'SUPER_ADMIN'),
      departmentCategory: json['departmentCategory'] ?? json['department'] ?? 'General',
      lateArrivalAllowedUntil: json['lateArrivalAllowedUntil']?.toString(),
      earlyOutAllowedAfter: json['earlyOutAllowedAfter']?.toString(),
      todayAttendanceStatus: json['todayAttendanceStatus'] ?? ((json['isAttendanceTracked'] == false) ? 'EXEMPT' : 'ABSENT'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

