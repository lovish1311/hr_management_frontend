import 'package:hr_management/core/network/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';

/// Domain Model for Payslip Records
class PayrollRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String designation;
  final String department;
  final double basicSalary;
  final double hra;
  final double specialAllowance;
  final double bonuses;
  final double grossSalary;
  final double providentFund;
  final double professionalTax;
  final double taxDeduction;
  final double unpaidLeaveDeduction;
  final double otherDeductions;
  final double totalDeductions;
  final double netSalary;
  final String payPeriod;
  final String paymentStatus;
  final String? paymentDate;
  final int totalWorkingDays;
  final int daysWorked;
  final int unpaidDays;
  final String paymentMethod;
  final String bankAccountNumber;

  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.basicSalary,
    required this.hra,
    required this.specialAllowance,
    required this.bonuses,
    required this.grossSalary,
    required this.providentFund,
    required this.professionalTax,
    required this.taxDeduction,
    required this.unpaidLeaveDeduction,
    required this.otherDeductions,
    required this.totalDeductions,
    required this.netSalary,
    required this.payPeriod,
    required this.paymentStatus,
    this.paymentDate,
    required this.totalWorkingDays,
    required this.daysWorked,
    required this.unpaidDays,
    required this.paymentMethod,
    required this.bankAccountNumber,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'] as int? ?? 0,
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? 'Lovish Kumar',
      employeeCode: json['employeeCode'] as String? ?? 'EMP-202',
      designation: json['designation'] as String? ?? 'Senior Software Developer',
      department: json['department'] as String? ?? 'Engineering',
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 
                   (json['baseSalary'] as num?)?.toDouble() ?? 25000.0,
      hra: (json['hra'] as num?)?.toDouble() ?? 10000.0,
      specialAllowance: (json['specialAllowance'] as num?)?.toDouble() ?? 5000.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 40000.0,
      providentFund: (json['providentFund'] as num?)?.toDouble() ?? 1800.0,
      professionalTax: (json['professionalTax'] as num?)?.toDouble() ?? 200.0,
      taxDeduction: (json['taxDeduction'] as num?)?.toDouble() ?? 1000.0,
      unpaidLeaveDeduction: (json['unpaidLeaveDeduction'] as num?)?.toDouble() ?? 0.0,
      otherDeductions: (json['otherDeductions'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 
                       (json['deductions'] as num?)?.toDouble() ?? 3000.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 37000.0,
      payPeriod: json['payPeriod'] as String? ?? '2026-06',
      paymentStatus: json['paymentStatus'] as String? ?? 'PAID',
      paymentDate: json['paymentDate'] as String? ?? '2026-06-28',
      totalWorkingDays: json['totalWorkingDays'] as int? ?? 30,
      daysWorked: json['daysWorked'] as int? ?? 30,
      unpaidDays: json['unpaidDays'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Bank Transfer (NEFT)',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '•••• •••• 9842',
    );
  }
}

class PayslipPage extends StatefulWidget {
  const PayslipPage({super.key});

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PayrollRecord> _payrollHistory = [];
  PayrollRecord? _selectedRecord;
  bool _isEarningsExpanded = true;
  bool _isDeductionsExpanded = true;

  String get _baseUrl => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchPayrollData();
  }

  Future<void> _fetchPayrollData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Default to employee ID 15 (Lovish) if not present in auth storage
      final empId = AuthStorage.employeeId ?? 15;
      final url = Uri.parse('$_baseUrl/api/v1/payroll/employee/$empId');
      
      final response = await http.get(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final records = list.map((item) => PayrollRecord.fromJson(item)).toList();

        setState(() {
          _payrollHistory = records;
          if (records.isNotEmpty) {
            _selectedRecord = records.first;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server returned status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading payroll records: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to connect to backend: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    // Standard Indian number format (e.g. 39,000.00)
    final parts = amount.toStringAsFixed(2).split('.');
    String integerPart = parts[0];
    final decimalPart = parts[1];

    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      final regExp = RegExp(r'(\d)(?=(\d{2})+(?!\d))');
      integerPart = '${remaining.replaceAllMapped(regExp, (m) => '${m[1]},')},$lastThree';
    }
    return '₹$integerPart.$decimalPart';
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero';
    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertLessThanOneThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) return '${tens[n ~/ 10]} ${units[n % 10]}'.trim();
      return '${units[n ~/ 100]} Hundred ${convertLessThanOneThousand(n % 100)}'.trim();
    }

    String result = '';
    if (number >= 10000000) {
      result += '${convertLessThanOneThousand(number ~/ 10000000)} Crore ';
      number %= 10000000;
    }
    if (number >= 100000) {
      result += '${convertLessThanOneThousand(number ~/ 100000)} Lakh ';
      number %= 100000;
    }
    if (number >= 1000) {
      result += '${convertLessThanOneThousand(number ~/ 1000)} Thousand ';
      number %= 1000;
    }
    if (number > 0) {
      result += convertLessThanOneThousand(number);
    }
    return 'Rupees ${result.trim()} Only';
  }

  String _formatPeriodLabel(String period) {
    try {
      if (period.contains('-')) {
        final parts = period.split('-');
        final year = parts[0];
        final month = int.parse(parts[1]);
        const monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${monthNames[month - 1]} $year';
      }
    } catch (_) {}
    return period;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t.onBackgroundText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payslip',
          style: TextStyle(
            color: t.onBackgroundText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.onBackgroundText),
            tooltip: 'Refresh Payroll',
            onPressed: _fetchPayrollData,
          ),
          IconButton(
            icon: Icon(Icons.home_outlined, color: t.onBackgroundText),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchPayrollData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _selectedRecord == null
                    ? const Center(child: Text('No payroll records found.'))
                    : _buildPayslipContent(isDark, t),
      ),
    );
  }

  Widget _buildPayslipContent(bool isDark, dynamic t) {
    final record = _selectedRecord!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payroll Month Selector
                InkWell(
                  onTap: _showMonthPicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Payroll Month: ${_formatPeriodLabel(record.payPeriod)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                record.paymentStatus,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Employee Overview Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        child: Text(
                          record.employeeName.isNotEmpty ? record.employeeName[0] : 'E',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.employeeName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${record.designation} • ${record.department}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Code: ${record.employeeCode} | Days Worked: ${record.daysWorked}/${record.totalWorkingDays}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Net Pay Highlight Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                          : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Take-Home Pay',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Disbursed',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatCurrency(record.netSalary),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _numberToWords(record.netSalary.toInt()),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.account_balance_rounded, size: 14, color: isDark ? Colors.white60 : const Color(0xFF047857)),
                          const SizedBox(width: 6),
                          Text(
                            '${record.paymentMethod} (${record.bankAccountNumber})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Earnings Section Card
                _buildBreakdownCard(
                  title: 'Earnings',
                  totalAmount: record.grossSalary,
                  isExpanded: _isEarningsExpanded,
                  isDark: isDark,
                  headerColor: const Color(0xFF15803D),
                  onToggle: () {
                    setState(() {
                      _isEarningsExpanded = !_isEarningsExpanded;
                    });
                  },
                  items: [
                    _BreakdownItem('Basic Salary', record.basicSalary),
                    _BreakdownItem('House Rent Allowance (HRA)', record.hra),
                    _BreakdownItem('Special Allowance', record.specialAllowance),
                    if (record.bonuses > 0) _BreakdownItem('Performance Bonus', record.bonuses),
                  ],
                ),
                const SizedBox(height: 16),

                // Deductions Section Card
                _buildBreakdownCard(
                  title: 'Deductions',
                  totalAmount: record.totalDeductions,
                  isExpanded: _isDeductionsExpanded,
                  isDark: isDark,
                  headerColor: const Color(0xFFDC2626),
                  onToggle: () {
                    setState(() {
                      _isDeductionsExpanded = !_isDeductionsExpanded;
                    });
                  },
                  items: [
                    _BreakdownItem('Provident Fund (PF)', record.providentFund),
                    _BreakdownItem('Professional Tax', record.professionalTax),
                    _BreakdownItem('Income Tax (TDS)', record.taxDeduction),
                    if (record.unpaidLeaveDeduction > 0)
                      _BreakdownItem('Loss of Pay (Unpaid Leave)', record.unpaidLeaveDeduction),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // Action Buttons: Preview A4 & Download PDF
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPayslipPreviewModal(record),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: const Text('View Payslip A4'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _triggerPrintOrDownload(record),
                icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required double totalAmount,
    required bool isExpanded,
    required bool isDark,
    required Color headerColor,
    required VoidCallback onToggle,
    required List<_BreakdownItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(totalAmount),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          _formatCurrency(item.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.85;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payroll Month',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._payrollHistory.map((rec) {
                  final isSelected = rec.payPeriod == _selectedRecord?.payPeriod;
                  return ListTile(
                    leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB)),
                    title: Text(
                      _formatPeriodLabel(rec.payPeriod),
                      style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: Text('Net Pay: ${_formatCurrency(rec.netSalary)} • ${rec.paymentStatus}'),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)) : null,
                    onTap: () {
                      setState(() {
                        _selectedRecord = rec;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerPrintOrDownload(PayrollRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded / Opened print dialog for ${_formatPeriodLabel(record.payPeriod)} Payslip!'),
        backgroundColor: const Color(0xFF15803D),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPayslipPreviewModal(PayrollRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 650,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Company Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANTIGRAVITY TECH CORP',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                          ),
                          SizedBox(height: 2),
                          Text('Plot 45, IT Park, Chandigarh, India', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('Email: payroll@company.com', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CONFIDENTIAL PAYSLIP',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1.5, color: Color(0xFFCBD5E1)),

                  // Employee Details Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Employee Name:', record.employeeName, 'Pay Period:', _formatPeriodLabel(record.payPeriod)),
                        const SizedBox(height: 6),
                        _infoRow('Employee Code:', record.employeeCode, 'Department:', record.department),
                        const SizedBox(height: 6),
                        _infoRow('Designation:', record.designation, 'Days Worked:', '${record.daysWorked} / ${record.totalWorkingDays}'),
                        const SizedBox(height: 6),
                        _infoRow('Payment Method:', record.paymentMethod, 'Bank A/c:', record.bankAccountNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Earnings & Deductions Table
                  Table(
                    border: TableBorder.all(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Deductions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      _tableDataRow('Basic Salary', record.basicSalary, 'Provident Fund (PF)', record.providentFund),
                      _tableDataRow('HRA', record.hra, 'Professional Tax', record.professionalTax),
                      _tableDataRow('Special Allowance', record.specialAllowance, 'Tax (TDS)', record.taxDeduction),
                      _tableDataRow('Bonus/Incentives', record.bonuses, 'Loss of Pay (LOP)', record.unpaidLeaveDeduction),
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: [
                          const Padding(padding: EdgeInsets.all(8), child: Text('Total Gross', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(_formatCurrency(record.grossSalary), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const Padding(padding: EdgeInsets.all(8), child: Text('Total Deductions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(_formatCurrency(record.totalDeductions), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Net Pay Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NET SALARY PAYABLE:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                            const SizedBox(height: 2),
                            Text(_numberToWords(record.netSalary.toInt()), style: const TextStyle(fontSize: 11, color: Color(0xFF047857))),
                          ],
                        ),
                        Text(
                          _formatCurrency(record.netSalary),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer & Close
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text('This is a system-generated document and requires no signature.', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _triggerPrintOrDownload(record);
                        },
                        icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                        label: const Text('Print / Save PDF', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label1, String val1, String label2, String val2) {
    return Row(
      children: [
        Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 11, color: Color(0xFF334155)), children: [TextSpan(text: '$label1 ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: val1)]))),
        Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 11, color: Color(0xFF334155)), children: [TextSpan(text: '$label2 ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: val2)]))),
      ],
    );
  }

  TableRow _tableDataRow(String l1, double v1, String l2, double v2) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text(l1, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text(_formatCurrency(v1), style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text(l2, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text(_formatCurrency(v2), style: const TextStyle(fontSize: 11))),
      ],
    );
  }
}

class _BreakdownItem {
  final String label;
  final double amount;
  _BreakdownItem(this.label, this.amount);
}

