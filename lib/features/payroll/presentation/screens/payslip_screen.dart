import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hr_management/features/payroll/presentation/widgets/payslip_detail_modal.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final PayrollRepository _repository = PayrollRepositoryImpl();

  bool _isLoading = true;
  String? _errorMessage;
  List<PayrollRecordEntity> _payslips = [];

  String _selectedFinancialYear = 'FY 2026-27';
  final List<String> _financialYears = ['FY 2026-27', 'FY 2025-26'];

  @override
  void initState() {
    super.initState();
    _fetchPayslips();
  }

  Future<void> _fetchPayslips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final empId = AuthStorage.employeeId ?? 1;
    final isPrivileged = AuthStorage.isSuperAdmin || AuthStorage.isHr;

    try {
      final list = await _repository.getPayslips(
        employeeId: empId,
        onlyPublished: !isPrivileged, // privileged users can preview draft/verified records
      );
      if (!mounted) return;
      setState(() {
        _payslips = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  double get _ytdGross => _payslips.fold(0.0, (acc, p) => acc + p.totalGrossPay);
  double get _ytdNet => _payslips.fold(0.0, (acc, p) => acc + p.netPay);
  double get _ytdTaxDeductions => _payslips.fold(0.0, (acc, p) => acc + p.totalDeductions);

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final theme = Theme.of(context);
    final isPrivileged = AuthStorage.isSuperAdmin || AuthStorage.isHr;

    return ResponsiveScaffold(
      body: Column(
        children: [
          // Header Bar
          _buildHeader(context, t, isPrivileged),

          // Main Scrollable Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: t.danger),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: TextStyle(color: t.danger)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchPayslips,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPayslips,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 960),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // YTD Summary Hero Card
                                  _buildYtdCard(context, t),
                                  const SizedBox(height: 24),

                                  // Historical Payslips Section Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payment History & Payslips',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: t.text,
                                        ),
                                      ),
                                      Text(
                                        '${_payslips.length} statement${_payslips.length == 1 ? '' : 's'}',
                                        style: TextStyle(fontSize: 12, color: t.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // List of Months
                                  if (_payslips.isEmpty)
                                    _buildEmptyState(context, t)
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _payslips.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, idx) {
                                        final record = _payslips[idx];
                                        return _buildPayslipCard(context, record, t);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic t, bool isPrivileged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: t.primary, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Payslip Dashboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: t.text),
              ),
              Text('Review your monthly take-home salary, earnings breakdown, and tax deductions', style: TextStyle(fontSize: 11, color: t.textSecondary)),
            ],
          ),
          const Spacer(),
          // Financial Year Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: t.cardSoft, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFinancialYear,
                dropdownColor: t.card,
                items: _financialYears.map((fy) => DropdownMenuItem(value: fy, child: Text(fy, style: TextStyle(fontSize: 12, color: t.text)))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedFinancialYear = v);
                    _fetchPayslips();
                  }
                },
              ),
            ),
          ),
          if (isPrivileged) ...[
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: Icon(Icons.admin_panel_settings_outlined, color: t.primary),
              tooltip: 'Admin Payroll Controls',
              onSelected: (route) => Navigator.pushNamed(context, route),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: '/salary_structure', child: Text('🛠️ Salary Master')),
                const PopupMenuItem(value: '/payroll_inputs', child: Text('📊 Monthly Inputs')),
                const PopupMenuItem(value: '/payroll_process', child: Text('⚙️ Process Payroll Wizard')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYtdCard(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, color: t.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Year-to-Date (YTD) Summary ($_selectedFinancialYear)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildYtdStat('Total Gross Earned', '₹${_ytdGross.toStringAsFixed(0)}', t.text, t),
              ),
              Expanded(
                child: _buildYtdStat('Total Deductions', '₹${_ytdTaxDeductions.toStringAsFixed(0)}', t.danger, t),
              ),
              Expanded(
                child: _buildYtdStat('Net Take-Home', '₹${_ytdNet.toStringAsFixed(0)}', t.success, t),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYtdStat(String label, String value, Color valueCol, dynamic t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: t.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueCol)),
      ],
    );
  }

  Widget _buildPayslipCard(BuildContext context, PayrollRecordEntity record, dynamic t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: InkWell(
        onTap: () => PayslipDetailModal.show(context, record),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt, color: t.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.payrollMonth} ${record.payrollYear}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Disbursed via ${record.bankAccountNumber} • Paid Days: ${record.paidDays}/${record.totalDaysInMonth}',
                      style: TextStyle(fontSize: 11, color: t.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${record.netPay.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t.text),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: record.isPublished ? t.success.withValues(alpha: 0.15) : t.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.isPublished ? 'PAID & PUBLISHED' : record.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: record.isPublished ? t.success : t.warning),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: t.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 48, color: t.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No published payslips found for $_selectedFinancialYear',
            style: TextStyle(fontWeight: FontWeight.bold, color: t.text),
          ),
          const SizedBox(height: 4),
          Text(
            'When HR finalizes and publishes monthly payroll, your payslips will appear here.',
            style: TextStyle(fontSize: 12, color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}
