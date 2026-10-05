class PayrollSummaryEntity {
  final String payrollMonth;
  final int payrollYear;
  final int totalHeadcount;
  final int processedCount;
  final int draftCount;
  final int verifiedCount;
  final int publishedCount;

  final double totalGrossOutflow;
  final double totalDeductionsOutflow;
  final double totalNetPayout;

  final double priorMonthNetPayout;
  final double variancePercentage;
  final List<String> anomalies;

  const PayrollSummaryEntity({
    required this.payrollMonth,
    required this.payrollYear,
    this.totalHeadcount = 0,
    this.processedCount = 0,
    this.draftCount = 0,
    this.verifiedCount = 0,
    this.publishedCount = 0,
    this.totalGrossOutflow = 0.0,
    this.totalDeductionsOutflow = 0.0,
    this.totalNetPayout = 0.0,
    this.priorMonthNetPayout = 0.0,
    this.variancePercentage = 0.0,
    this.anomalies = const [],
  });

  factory PayrollSummaryEntity.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final rawAnomalies = json['anomalies'];
    final List<String> anomList = [];
    if (rawAnomalies is List) {
      for (var item in rawAnomalies) {
        if (item != null) anomList.add(item.toString());
      }
    }

    return PayrollSummaryEntity(
      payrollMonth: json['payrollMonth']?.toString() ?? 'OCTOBER',
      payrollYear: (json['payrollYear'] as num?)?.toInt() ?? 2026,
      totalHeadcount: (json['totalHeadcount'] as num?)?.toInt() ?? 0,
      processedCount: (json['processedCount'] as num?)?.toInt() ?? 0,
      draftCount: (json['draftCount'] as num?)?.toInt() ?? 0,
      verifiedCount: (json['verifiedCount'] as num?)?.toInt() ?? 0,
      publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
      totalGrossOutflow: parse(json['totalGrossOutflow']),
      totalDeductionsOutflow: parse(json['totalDeductionsOutflow']),
      totalNetPayout: parse(json['totalNetPayout']),
      priorMonthNetPayout: parse(json['priorMonthNetPayout']),
      variancePercentage: parse(json['variancePercentage']),
      anomalies: anomList,
    );
  }
}
