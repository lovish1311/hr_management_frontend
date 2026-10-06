class Employee {
  final String id;
  final String employeeCode;
  final String name;
  final String firstName;
  final String lastName;
  final String role;
  final String systemRole;
  final String department;
  final String designation;
  final String status; // ACTIVE, PROBATION, NOTICE_PERIOD, INACTIVE, TERMINATED
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
  final List<String> authorities;

  bool get isSuperAdmin =>
      systemRole == 'SUPER_ADMIN' || role.toUpperCase().contains('SUPER_ADMIN');
  bool get isAdmin =>
      isSuperAdmin || systemRole == 'ADMIN' || authorities.contains('ROLE_ADMIN');
  bool get isHr => isAdmin || role.toUpperCase() == 'HR';
  bool get isManager => isAdmin || isHr || role.toUpperCase() == 'MANAGER';
  bool get isPayrollManager => isAdmin || authorities.contains('PAYROLL_MANAGE');
  bool get isGlobalLeaveApprover => isAdmin || authorities.contains('LEAVE_APPROVE_ALL');

  // Probation State
  final bool isProbation;
  final String? probationStartDate;
  final int? probationDurationMonths;
  final String? probationEndDate;

  // Notice Period State
  final bool isNoticePeriod;
  final String? noticeStartDate;
  final int? noticeDurationDays;
  final String? noticeEndDate;

  Employee({
    required this.id,
    this.employeeCode = '',
    required this.name,
    this.firstName = '',
    this.lastName = '',
    required this.role,
    this.systemRole = 'NONE',
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
    this.isProbation = false,
    this.probationStartDate,
    this.probationDurationMonths,
    this.probationEndDate,
    this.isNoticePeriod = false,
    this.noticeStartDate,
    this.noticeDurationDays,
    this.noticeEndDate,
    this.authorities = const [],
  });

  Employee copyWith({
    String? id,
    String? employeeCode,
    String? name,
    String? firstName,
    String? lastName,
    String? role,
    String? systemRole,
    String? department,
    String? designation,
    String? status,
    String? email,
    String? phone,
    String? managerName,
    String? managerId,
    String? dateOfBirth,
    String? joiningDate,
    String? employmentType,
    String? address,
    String? location,
    String? emergencyContactName,
    String? emergencyContactPhone,
    int? leaveBalance,
    int? attendanceRate,
    bool? isAttendanceTracked,
    String? departmentCategory,
    String? lateArrivalAllowedUntil,
    String? earlyOutAllowedAfter,
    String? todayAttendanceStatus,
    bool? isProbation,
    String? probationStartDate,
    int? probationDurationMonths,
    String? probationEndDate,
    bool? isNoticePeriod,
    String? noticeStartDate,
    int? noticeDurationDays,
    String? noticeEndDate,
    List<String>? authorities,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      systemRole: systemRole ?? this.systemRole,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      status: status ?? this.status,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      managerName: managerName ?? this.managerName,
      managerId: managerId ?? this.managerId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      joiningDate: joiningDate ?? this.joiningDate,
      employmentType: employmentType ?? this.employmentType,
      address: address ?? this.address,
      location: location ?? this.location,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      isAttendanceTracked: isAttendanceTracked ?? this.isAttendanceTracked,
      departmentCategory: departmentCategory ?? this.departmentCategory,
      lateArrivalAllowedUntil: lateArrivalAllowedUntil ?? this.lateArrivalAllowedUntil,
      earlyOutAllowedAfter: earlyOutAllowedAfter ?? this.earlyOutAllowedAfter,
      todayAttendanceStatus: todayAttendanceStatus ?? this.todayAttendanceStatus,
      isProbation: isProbation ?? this.isProbation,
      probationStartDate: probationStartDate ?? this.probationStartDate,
      probationDurationMonths: probationDurationMonths ?? this.probationDurationMonths,
      probationEndDate: probationEndDate ?? this.probationEndDate,
      isNoticePeriod: isNoticePeriod ?? this.isNoticePeriod,
      noticeStartDate: noticeStartDate ?? this.noticeStartDate,
      noticeDurationDays: noticeDurationDays ?? this.noticeDurationDays,
      noticeEndDate: noticeEndDate ?? this.noticeEndDate,
      authorities: authorities ?? this.authorities,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final fn = json['firstName'] ?? '';
    final ln = json['lastName'] ?? '';
    final fullName = '$fn $ln'.trim();

    final rawStatus = (json['status'] ?? 'ACTIVE').toString().toUpperCase();
    final bool parsedProbation = json['isProbation'] ?? (rawStatus == 'PROBATION');
    final bool parsedNotice = json['isNoticePeriod'] ?? (rawStatus == 'NOTICE' || rawStatus == 'NOTICE_PERIOD');

    final rawSystemRole = (json['systemRole'] ??
            ((json['role'] ?? '').toString().toUpperCase() == 'SUPER_ADMIN'
                ? 'SUPER_ADMIN'
                : 'NONE'))
        .toString()
        .toUpperCase();

    return Employee(
      id: (json['id'] ?? '').toString(),
      employeeCode: json['employeeCode'] ?? 'EMP-${json['id'] ?? ''}',
      name: fullName.isNotEmpty ? fullName : (json['name'] ?? 'Unnamed Employee'),
      firstName: fn,
      lastName: ln,
      role: json['role'] ?? 'EMPLOYEE',
      systemRole: rawSystemRole,
      department: json['department'] ?? 'General',
      designation: json['designation'] ?? json['role'] ?? 'Team Member',
      status: rawStatus,
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
      isProbation: parsedProbation,
      probationStartDate: json['probationStartDate']?.toString(),
      probationDurationMonths: json['probationDurationMonths'] != null ? (json['probationDurationMonths'] as num).toInt() : null,
      probationEndDate: json['probationEndDate']?.toString(),
      isNoticePeriod: parsedNotice,
      noticeStartDate: json['noticeStartDate']?.toString(),
      noticeDurationDays: json['noticeDurationDays'] != null ? (json['noticeDurationDays'] as num).toInt() : null,
      noticeEndDate: json['noticeEndDate']?.toString(),
      authorities: (json['authorities'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          const [],
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
