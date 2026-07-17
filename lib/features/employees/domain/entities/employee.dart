class Employee {
  final String id;
  final String name;
  final String role;
  final String department;
  final String status;
  final String email;
  final String phone;
  final String managerName;
  final String dateOfBirth;
  final String location;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int attendanceRate;
  final int leaveBalance;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.status,
    required this.email,
    required this.phone,
    required this.managerName,
    required this.dateOfBirth,
    required this.location,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.attendanceRate,
    required this.leaveBalance,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['id'] ?? '').toString(),
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      role: json['role'] ?? '',
      department: json['department'] ?? '',
      status: json['status'] ?? 'Active',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      managerName: json['managerName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      location: json['location'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      attendanceRate: json['attendanceRate'] ?? 100,
      leaveBalance: json['leaveBalance'] ?? 15,
    );
  }
}
