class PayrollReconciliationReportEntity {
  final String currentMonth;
  final int currentYear;
  final String previousMonth;
  final int previousYear;

  final int currentHeadcount;
  final int previousHeadcount;
  final int headcountDelta;

  final double currentGrossTotal;
  final double previousGrossTotal;
  final double grossTotalDelta;
  final double grossPercentageDelta;

  final double currentNetTotal;
  final double previousNetTotal;
  final double netTotalDelta;
  final double netPercentageDelta;

  final double currentPfTotal;
  final double currentEsiTotal;
  final double currentPtTotal;
  final double currentTdsTotal;
  final double currentArrearsTotal;

  final List<EmployeePayrollVarianceEntity> employeeVariances;

  const PayrollReconciliationReportEntity({
    required this.currentMonth,
    required this.currentYear,
    required this.previousMonth,
    required this.previousYear,
    required this.currentHeadcount,
    required this.previousHeadcount,
    required this.headcountDelta,
    required this.currentGrossTotal,
    required this.previousGrossTotal,
    required this.grossTotalDelta,
    required this.grossPercentageDelta,
    required this.currentNetTotal,
    required this.previousNetTotal,
    required this.netTotalDelta,
    required this.netPercentageDelta,
    required this.currentPfTotal,
    required this.currentEsiTotal,
    required this.currentPtTotal,
    required this.currentTdsTotal,
    required this.currentArrearsTotal,
    required this.employeeVariances,
  });

  factory PayrollReconciliationReportEntity.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    final rawVariances = json['employeeVariances'] as List<dynamic>? ?? [];
    final variances = rawVariances
        .map((v) => EmployeePayrollVarianceEntity.fromJson(v as Map<String, dynamic>))
        .toList();

    return PayrollReconciliationReportEntity(
      currentMonth: json['currentMonth']?.toString() ?? '',
      currentYear: parseInt(json['currentYear']),
      previousMonth: json['previousMonth']?.toString() ?? '',
      previousYear: parseInt(json['previousYear']),
      currentHeadcount: parseInt(json['currentHeadcount']),
      previousHeadcount: parseInt(json['previousHeadcount']),
      headcountDelta: parseInt(json['headcountDelta']),
      currentGrossTotal: parse(json['currentGrossTotal']),
      previousGrossTotal: parse(json['previousGrossTotal']),
      grossTotalDelta: parse(json['grossTotalDelta']),
      grossPercentageDelta: parse(json['grossPercentageDelta']),
      currentNetTotal: parse(json['currentNetTotal']),
      previousNetTotal: parse(json['previousNetTotal']),
      netTotalDelta: parse(json['netTotalDelta']),
      netPercentageDelta: parse(json['netPercentageDelta']),
      currentPfTotal: parse(json['currentPfTotal']),
      currentEsiTotal: parse(json['currentEsiTotal']),
      currentPtTotal: parse(json['currentPtTotal']),
      currentTdsTotal: parse(json['currentTdsTotal']),
      currentArrearsTotal: parse(json['currentArrearsTotal']),
      employeeVariances: variances,
    );
  }
}

class EmployeePayrollVarianceEntity {
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;

  final double previousGrossPay;
  final double currentGrossPay;
  final double grossDifference;

  final double previousNetPay;
  final double currentNetPay;
  final double netDifference;

  final double previousLopDays;
  final double currentLopDays;

  final double arrearsAmount;
  final double adHocBonus;
  final double calculatedTds;

  final String varianceTag;
  final String varianceReason;

  const EmployeePayrollVarianceEntity({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.previousGrossPay,
    required this.currentGrossPay,
    required this.grossDifference,
    required this.previousNetPay,
    required this.currentNetPay,
    required this.netDifference,
    required this.previousLopDays,
    required this.currentLopDays,
    required this.arrearsAmount,
    required this.adHocBonus,
    required this.calculatedTds,
    required this.varianceTag,
    required this.varianceReason,
  });

  factory EmployeePayrollVarianceEntity.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return EmployeePayrollVarianceEntity(
      employeeId: parseInt(json['employeeId']),
      employeeName: json['employeeName']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      previousGrossPay: parse(json['previousGrossPay']),
      currentGrossPay: parse(json['currentGrossPay']),
      grossDifference: parse(json['grossDifference']),
      previousNetPay: parse(json['previousNetPay']),
      currentNetPay: parse(json['currentNetPay']),
      netDifference: parse(json['netDifference']),
      previousLopDays: parse(json['previousLopDays']),
      currentLopDays: parse(json['currentLopDays']),
      arrearsAmount: parse(json['arrearsAmount']),
      adHocBonus: parse(json['adHocBonus']),
      calculatedTds: parse(json['calculatedTds']),
      varianceTag: json['varianceTag']?.toString() ?? 'UNCHANGED',
      varianceReason: json['varianceReason']?.toString() ?? '',
    );
  }
}
