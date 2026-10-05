class MonthlyPayrollInputEntity {
  final int? id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final double fixedGross;

  final String payrollMonth;
  final int payrollYear;
  final double lopDays;
  final double overtimeHours;
  final double adHocBonus;
  final double adHocDeduction;
  final bool isLocked;
  final String? notes;

  const MonthlyPayrollInputEntity({
    this.id,
    required this.employeeId,
    this.employeeName = '',
    this.employeeCode = '',
    this.department = '',
    this.fixedGross = 0.0,
    required this.payrollMonth,
    required this.payrollYear,
    this.lopDays = 0.0,
    this.overtimeHours = 0.0,
    this.adHocBonus = 0.0,
    this.adHocDeduction = 0.0,
    this.isLocked = false,
    this.notes,
  });

  factory MonthlyPayrollInputEntity.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return MonthlyPayrollInputEntity(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
      employeeName: json['employeeName']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      fixedGross: parse(json['fixedGross']),
      payrollMonth: json['payrollMonth']?.toString() ?? 'OCTOBER',
      payrollYear: (json['payrollYear'] as num?)?.toInt() ?? 2026,
      lopDays: parse(json['lopDays']),
      overtimeHours: parse(json['overtimeHours']),
      adHocBonus: parse(json['adHocBonus']),
      adHocDeduction: parse(json['adHocDeduction']),
      isLocked: json['isLocked'] == true,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'payrollMonth': payrollMonth,
      'payrollYear': payrollYear,
      'lopDays': lopDays,
      'overtimeHours': overtimeHours,
      'adHocBonus': adHocBonus,
      'adHocDeduction': adHocDeduction,
      'isLocked': isLocked,
      if (notes != null) 'notes': notes,
    };
  }

  MonthlyPayrollInputEntity copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    double? fixedGross,
    String? payrollMonth,
    int? payrollYear,
    double? lopDays,
    double? overtimeHours,
    double? adHocBonus,
    double? adHocDeduction,
    bool? isLocked,
    String? notes,
  }) {
    return MonthlyPayrollInputEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      fixedGross: fixedGross ?? this.fixedGross,
      payrollMonth: payrollMonth ?? this.payrollMonth,
      payrollYear: payrollYear ?? this.payrollYear,
      lopDays: lopDays ?? this.lopDays,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      adHocBonus: adHocBonus ?? this.adHocBonus,
      adHocDeduction: adHocDeduction ?? this.adHocDeduction,
      isLocked: isLocked ?? this.isLocked,
      notes: notes ?? this.notes,
    );
  }
}
