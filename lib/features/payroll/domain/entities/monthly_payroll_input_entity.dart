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
  final double arrearsAmount;
  final String taxRegime;
  final double declared80C;
  final double declared80D;
  final bool isLocked;
  final bool isExempt;
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
    this.arrearsAmount = 0.0,
    this.taxRegime = 'NEW_REGIME',
    this.declared80C = 0.0,
    this.declared80D = 0.0,
    this.isLocked = false,
    this.isExempt = false,
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
      arrearsAmount: parse(json['arrearsAmount']),
      taxRegime: json['taxRegime']?.toString() ?? 'NEW_REGIME',
      declared80C: parse(json['declared80C']),
      declared80D: parse(json['declared80D']),
      isLocked: json['isLocked'] == true,
      isExempt: json['isExempt'] == true,
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
      'arrearsAmount': arrearsAmount,
      'taxRegime': taxRegime,
      'declared80C': declared80C,
      'declared80D': declared80D,
      'isLocked': isLocked,
      'isExempt': isExempt,
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
    double? arrearsAmount,
    String? taxRegime,
    double? declared80C,
    double? declared80D,
    bool? isLocked,
    bool? isExempt,
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
      arrearsAmount: arrearsAmount ?? this.arrearsAmount,
      taxRegime: taxRegime ?? this.taxRegime,
      declared80C: declared80C ?? this.declared80C,
      declared80D: declared80D ?? this.declared80D,
      isLocked: isLocked ?? this.isLocked,
      isExempt: isExempt ?? this.isExempt,
      notes: notes ?? this.notes,
    );
  }
}
