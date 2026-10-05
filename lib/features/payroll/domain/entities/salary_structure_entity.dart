class SalaryStructureEntity {
  final int? id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final String designation;

  final double basicPay;
  final double hra;
  final double conveyanceAllowance;
  final double medicalAllowance;
  final double specialAllowance;

  final double pfContribution;
  final double esiContribution;
  final double professionalTax;

  final String? effectiveDate;
  final bool isActive;

  final double totalFixedGross;
  final double totalStatutoryDeductions;
  final double netCtc;

  const SalaryStructureEntity({
    this.id,
    required this.employeeId,
    this.employeeName = '',
    this.employeeCode = '',
    this.department = '',
    this.designation = '',
    this.basicPay = 0.0,
    this.hra = 0.0,
    this.conveyanceAllowance = 0.0,
    this.medicalAllowance = 0.0,
    this.specialAllowance = 0.0,
    this.pfContribution = 0.0,
    this.esiContribution = 0.0,
    this.professionalTax = 200.0,
    this.effectiveDate,
    this.isActive = true,
    this.totalFixedGross = 0.0,
    this.totalStatutoryDeductions = 0.0,
    this.netCtc = 0.0,
  });

  factory SalaryStructureEntity.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final basic = parse(json['basicPay']);
    final hra = parse(json['hra']);
    final conv = parse(json['conveyanceAllowance']);
    final med = parse(json['medicalAllowance']);
    final spec = parse(json['specialAllowance']);
    final pf = parse(json['pfContribution']);
    final esi = parse(json['esiContribution']);
    final pt = parse(json['professionalTax']);

    final totalGross = parse(json['totalFixedGross']) > 0
        ? parse(json['totalFixedGross'])
        : (basic + hra + conv + med + spec);
    final totalDed = parse(json['totalStatutoryDeductions']) > 0
        ? parse(json['totalStatutoryDeductions'])
        : (pf + esi + pt);
    final net = parse(json['netCtc']) > 0 ? parse(json['netCtc']) : (totalGross - totalDed);

    return SalaryStructureEntity(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
      employeeName: json['employeeName']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      basicPay: basic,
      hra: hra,
      conveyanceAllowance: conv,
      medicalAllowance: med,
      specialAllowance: spec,
      pfContribution: pf,
      esiContribution: esi,
      professionalTax: pt,
      effectiveDate: json['effectiveDate']?.toString(),
      isActive: json['isActive'] == true || json['isActive'] == null,
      totalFixedGross: totalGross,
      totalStatutoryDeductions: totalDed,
      netCtc: net,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'basicPay': basicPay,
      'hra': hra,
      'conveyanceAllowance': conveyanceAllowance,
      'medicalAllowance': medicalAllowance,
      'specialAllowance': specialAllowance,
      'pfContribution': pfContribution,
      'esiContribution': esiContribution,
      'professionalTax': professionalTax,
      'effectiveDate': effectiveDate,
      'isActive': isActive,
    };
  }

  SalaryStructureEntity copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    String? designation,
    double? basicPay,
    double? hra,
    double? conveyanceAllowance,
    double? medicalAllowance,
    double? specialAllowance,
    double? pfContribution,
    double? esiContribution,
    double? professionalTax,
    String? effectiveDate,
    bool? isActive,
  }) {
    final b = basicPay ?? this.basicPay;
    final h = hra ?? this.hra;
    final c = conveyanceAllowance ?? this.conveyanceAllowance;
    final m = medicalAllowance ?? this.medicalAllowance;
    final s = specialAllowance ?? this.specialAllowance;
    final pf = pfContribution ?? this.pfContribution;
    final esi = esiContribution ?? this.esiContribution;
    final pt = professionalTax ?? this.professionalTax;

    final gross = b + h + c + m + s;
    final ded = pf + esi + pt;
    final net = gross - ded;

    return SalaryStructureEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      basicPay: b,
      hra: h,
      conveyanceAllowance: c,
      medicalAllowance: m,
      specialAllowance: s,
      pfContribution: pf,
      esiContribution: esi,
      professionalTax: pt,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      isActive: isActive ?? this.isActive,
      totalFixedGross: gross,
      totalStatutoryDeductions: ded,
      netCtc: net,
    );
  }
}
