class PayrollRecordEntity {
  final String id; // UUID string
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String designation;
  final String department;
  final String bankAccountNumber;

  final String payrollMonth;
  final int payrollYear;

  final int totalDaysInMonth;
  final double paidDays;
  final double lopDays;
  final double overtimeHours;

  final double masterFixedGross;
  final double calculatedBasic;
  final double calculatedHra;
  final double calculatedConveyance;
  final double calculatedMedical;
  final double calculatedSpecial;
  final double overtimeAmount;
  final double adHocBonus;

  final double calculatedPf;
  final double calculatedEsi;
  final double calculatedPt;
  final double lopDeductionAmount;
  final double adHocDeduction;

  final double totalGrossPay;
  final double totalDeductions;
  final double netPay;

  final String status; // DRAFT, VERIFIED, PUBLISHED
  final String? processedAt;
  final String? publishedAt;

  const PayrollRecordEntity({
    required this.id,
    required this.employeeId,
    this.employeeName = '',
    this.employeeCode = '',
    this.designation = '',
    this.department = '',
    this.bankAccountNumber = '',
    required this.payrollMonth,
    required this.payrollYear,
    this.totalDaysInMonth = 30,
    this.paidDays = 30.0,
    this.lopDays = 0.0,
    this.overtimeHours = 0.0,
    this.masterFixedGross = 0.0,
    this.calculatedBasic = 0.0,
    this.calculatedHra = 0.0,
    this.calculatedConveyance = 0.0,
    this.calculatedMedical = 0.0,
    this.calculatedSpecial = 0.0,
    this.overtimeAmount = 0.0,
    this.adHocBonus = 0.0,
    this.calculatedPf = 0.0,
    this.calculatedEsi = 0.0,
    this.calculatedPt = 200.0,
    this.lopDeductionAmount = 0.0,
    this.adHocDeduction = 0.0,
    this.totalGrossPay = 0.0,
    this.totalDeductions = 0.0,
    this.netPay = 0.0,
    this.status = 'DRAFT',
    this.processedAt,
    this.publishedAt,
  });

  factory PayrollRecordEntity.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PayrollRecordEntity(
      id: json['id']?.toString() ?? '',
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
      employeeName: json['employeeName']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
      payrollMonth: json['payrollMonth']?.toString() ?? 'OCTOBER',
      payrollYear: (json['payrollYear'] as num?)?.toInt() ?? 2026,
      totalDaysInMonth: (json['totalDaysInMonth'] as num?)?.toInt() ?? 30,
      paidDays: parse(json['paidDays']),
      lopDays: parse(json['lopDays']),
      overtimeHours: parse(json['overtimeHours']),
      masterFixedGross: parse(json['masterFixedGross']),
      calculatedBasic: parse(json['calculatedBasic']),
      calculatedHra: parse(json['calculatedHra']),
      calculatedConveyance: parse(json['calculatedConveyance']),
      calculatedMedical: parse(json['calculatedMedical']),
      calculatedSpecial: parse(json['calculatedSpecial']),
      overtimeAmount: parse(json['overtimeAmount']),
      adHocBonus: parse(json['adHocBonus']),
      calculatedPf: parse(json['calculatedPf']),
      calculatedEsi: parse(json['calculatedEsi']),
      calculatedPt: parse(json['calculatedPt']),
      lopDeductionAmount: parse(json['lopDeductionAmount']),
      adHocDeduction: parse(json['adHocDeduction']),
      totalGrossPay: parse(json['totalGrossPay']),
      totalDeductions: parse(json['totalDeductions']),
      netPay: parse(json['netPay']),
      status: json['status']?.toString() ?? 'DRAFT',
      processedAt: json['processedAt']?.toString(),
      publishedAt: json['publishedAt']?.toString(),
    );
  }

  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
  bool get isVerified => status.toUpperCase() == 'VERIFIED';
  bool get isDraft => status.toUpperCase() == 'DRAFT';
}
