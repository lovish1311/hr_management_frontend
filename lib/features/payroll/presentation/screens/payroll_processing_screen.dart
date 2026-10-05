import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_summary_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hr_management/features/payroll/presentation/widgets/payslip_detail_modal.dart';

class PayrollProcessingScreen extends StatefulWidget {
  const PayrollProcessingScreen({super.key});

  @override
  State<PayrollProcessingScreen> createState() => _PayrollProcessingScreenState();
}

class _PayrollProcessingScreenState extends State<PayrollProcessingScreen> {
  final PayrollRepository _repository = PayrollRepositoryImpl();

  int _currentStep = 0; // 0: Verify, 1: Process, 2: Reconcile, 3: Publish
  String _selectedMonth = 'OCTOBER';
  int _selectedYear = 2026;

  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isPublishing = false;
  String? _errorMessage;

  PayrollSummaryEntity? _summary;
  List<PayrollRecordEntity> _processedRecords = [];

  final List<String> _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentMonthState();
  }

  Future<void> _loadCurrentMonthState() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _repository.getPayrollSummary(month: _selectedMonth, year: _selectedYear);
      final records = await _repository.getPayrollRecordsForMonth(month: _selectedMonth, year: _selectedYear);

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _processedRecords = records;
        _isLoading = false;

        // Auto determine initial step based on status
        if (summary.publishedCount > 0) {
          _currentStep = 3;
        } else if (summary.verifiedCount > 0) {
          _currentStep = 3;
        } else if (summary.draftCount > 0) {
          _currentStep = 2;
        } else {
          _currentStep = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _executeBatchPayroll() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final records = await _repository.processPayroll(month: _selectedMonth, year: _selectedYear);
      final summary = await _repository.getPayrollSummary(month: _selectedMonth, year: _selectedYear);

      if (!mounted) return;
      setState(() {
        _processedRecords = records;
        _summary = summary;
        _isProcessing = false;
        _currentStep = 2; // Move to Reconciliation
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully calculated batch payroll for ${records.length} employees.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calculation failed: $_errorMessage'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyBatchPayroll() async {
    try {
      await _repository.verifyPayroll(month: _selectedMonth, year: _selectedYear);
      await _loadCurrentMonthState();
      setState(() => _currentStep = 3);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payroll marked as VERIFIED. Proceed to publishing.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _publishPayslips() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Payslips to ESS?'),
        content: Text(
          'This action will publish finalized payslips for $_selectedMonth $_selectedYear.\n\n'
          'All ${_processedRecords.length} employees will be able to view and download their official payslips immediately. This action cannot be reversed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Yes, Publish Payslips'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPublishing = true);
    try {
      await _repository.publishPayroll(month: _selectedMonth, year: _selectedYear);
      await _loadCurrentMonthState();
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payslips PUBLISHED successfully! Employees can view them in their portals.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publishing error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return ResponsiveScaffold(
      body: Column(
        children: [
          // Header Bar
          _buildHeader(context, t),

          // 4-Step Progress Indicator
          _buildStepBar(context, t),

          // Main Step Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: _buildCurrentStepView(context, t),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.precision_manufacturing_outlined, color: t.primary, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payroll Processing Wizard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: t.text),
              ),
              Text('4-Step greytHR batch processing, pro-rata calculation, and ESS publishing', style: TextStyle(fontSize: 11, color: t.textSecondary)),
            ],
          ),
          const Spacer(),
          // Month & Year Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: t.cardSoft, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                dropdownColor: t.card,
                items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(fontSize: 12, color: t.text)))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedMonth = v);
                    _loadCurrentMonthState();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: t.cardSoft, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: t.card,
                items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y', style: TextStyle(fontSize: 12, color: t.text)))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedYear = v);
                    _loadCurrentMonthState();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar(BuildContext context, dynamic t) {
    final steps = [
      '1. Verification',
      '2. Calculation',
      '3. Reconciliation',
      '4. Publish & Disburse',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: t.cardSoft,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isCurrent = _currentStep == idx;
          final isCompleted = _currentStep > idx;

          Color badgeCol = t.textSecondary.withValues(alpha: 0.3);
          if (isCurrent) badgeCol = t.primary;
          if (isCompleted) badgeCol = t.success;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentStep = idx),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: badgeCol,
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text('${idx + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[idx],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? t.primary : (isCompleted ? t.text : t.textSecondary),
                      ),
                    ),
                  ),
                  if (idx < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 16, color: t.textSecondary.withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView(BuildContext context, dynamic t) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Verification(context, t);
      case 1:
        return _buildStep2Calculation(context, t);
      case 2:
        return _buildStep3Reconciliation(context, t);
      case 3:
      default:
        return _buildStep4Publish(context, t);
    }
  }

  // STEP 1: PRE-PROCESS VERIFICATION
  Widget _buildStep1Verification(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Icon(Icons.checklist_rtl_rounded, color: t.primary, size: 24),
              const SizedBox(width: 10),
              Text('Step 1: Pre-Process Verification Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Ensure all monthly inputs, attendance shortfalls, and active salary masters are validated.', style: TextStyle(fontSize: 12, color: t.textSecondary)),
          const Divider(height: 28),

          _buildCheckItem(
            title: 'Attendance Shortfalls & Leaves Audited',
            subtitle: 'Synced from biometric logs and leave request tables for $_selectedMonth $_selectedYear.',
            isDone: true,
            t: t,
          ),
          const SizedBox(height: 14),
          _buildCheckItem(
            title: 'Active Salary Structures Configured',
            subtitle: 'Employees have an active base structure configured in the Salary Master.',
            isDone: true,
            t: t,
          ),
          const SizedBox(height: 14),
          _buildCheckItem(
            title: 'Monthly Variables & LOP Locked / Reviewed',
            subtitle: 'HR has reviewed and finalized LOP days, overtime hours, and ad-hoc bonuses.',
            isDone: _summary != null && _summary!.processedCount > 0,
            t: t,
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/payroll_inputs'),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Review Inputs Table'),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Proceed to Calculation'),
                style: FilledButton.styleFrom(backgroundColor: t.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 2: CALCULATION ENGINE EXECUTION
  Widget _buildStep2Calculation(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(Icons.calculate_outlined, size: 56, color: t.primary),
          const SizedBox(height: 16),
          Text(
            'Execute Batch Payroll Calculation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              'The calculation engine will compute pro-rata earnings based on calendar days, deduct exact LOP days, add overtime and bonuses, and compute statutory deductions (PF, ESI, PT) with zero cent drift.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
          ),
          const SizedBox(height: 28),

          if (_isProcessing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text('Processing batch calculations across all active employees...', style: TextStyle(fontSize: 13, color: t.primary)),
          ] else ...[
            FilledButton.icon(
              onPressed: _executeBatchPayroll,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('Execute Batch Payroll for $_selectedMonth $_selectedYear'),
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 3: RECONCILIATION & VARIANCE DASHBOARD
  Widget _buildStep3Reconciliation(BuildContext context, dynamic t) {
    final summary = _summary;
    if (summary == null) {
      return Center(child: Text('No calculation data found. Run calculation first.', style: TextStyle(color: t.textSecondary)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 KPI Metric Cards
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Headcount', '${summary.totalHeadcount}', Icons.people, t.primary, t)),
            const SizedBox(width: 14),
            Expanded(child: _buildMetricCard('Total Gross Outflow', '₹${summary.totalGrossOutflow.toStringAsFixed(0)}', Icons.arrow_upward, t.success, t)),
            const SizedBox(width: 14),
            Expanded(child: _buildMetricCard('Total Deductions', '₹${summary.totalDeductionsOutflow.toStringAsFixed(0)}', Icons.arrow_downward, t.danger, t)),
            const SizedBox(width: 14),
            Expanded(child: _buildMetricCard('Net Payout', '₹${summary.totalNetPayout.toStringAsFixed(0)}', Icons.account_balance_wallet, t.primary, t)),
          ],
        ),
        const SizedBox(height: 18),

        // Variance & Anomaly Alert Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.compare_arrows, size: 20, color: t.primary),
                  const SizedBox(width: 8),
                  Text('Variance vs Prior Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.text)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: summary.variancePercentage >= 0 ? t.success.withValues(alpha: 0.15) : t.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${summary.variancePercentage >= 0 ? '+' : ''}${summary.variancePercentage.toStringAsFixed(2)}% net payout change',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: summary.variancePercentage >= 0 ? t.success : t.danger,
                      ),
                    ),
                  ),
                ],
              ),
              if (summary.anomalies.isNotEmpty) ...[
                const Divider(height: 20),
                Text('Audit Anomalies & Flagged Adjustments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.warning)),
                const SizedBox(height: 6),
                ...summary.anomalies.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: t.warning),
                      const SizedBox(width: 6),
                      Text(a, style: TextStyle(fontSize: 12, color: t.text)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Processed Records Table Preview
        Container(
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Calculated Payroll Drafts (${_processedRecords.length})', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _verifyBatchPayroll,
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text('Verify & Proceed to Publish'),
                      style: FilledButton.styleFrom(backgroundColor: t.primary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Employee')),
                    DataColumn(label: Text('Paid/Total Days')),
                    DataColumn(label: Text('Fixed Gross')),
                    DataColumn(label: Text('Earned Gross')),
                    DataColumn(label: Text('Total Deduct')),
                    DataColumn(label: Text('Net Pay')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _processedRecords.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${r.employeeName}\n${r.employeeCode}', style: TextStyle(fontSize: 12, color: t.text))),
                        DataCell(Text('${r.paidDays}/${r.totalDaysInMonth}', style: TextStyle(fontSize: 12, color: t.text))),
                        DataCell(Text('₹${r.masterFixedGross.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: t.text))),
                        DataCell(Text('₹${r.totalGrossPay.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: t.success))),
                        DataCell(Text('₹${r.totalDeductions.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: t.danger))),
                        DataCell(Text('₹${r.netPay.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.primary))),
                        DataCell(Text(r.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: r.isPublished ? t.success : t.warning))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            onPressed: () => PayslipDetailModal.show(context, r),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 4: PUBLISH & DISBURSE
  Widget _buildStep4Publish(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(Icons.send_rounded, size: 56, color: t.success),
          const SizedBox(height: 16),
          Text(
            'Finalize & Publish Payslips to ESS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              'Publishing makes these payslips visible on all employee self-service portals and mobile apps. You can also export the bank disbursement file (NEFT/RTGS format).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting Bank Disbursement File (CSV/Excel)...')),
                  );
                },
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Export Bank File (CSV)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.text,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _isPublishing ? null : _publishPayslips,
                icon: _isPublishing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.rocket_launch, size: 18),
                label: Text(_isPublishing ? 'Publishing...' : 'Publish Payslips to ESS'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({required String title, required String subtitle, required bool isDone, required dynamic t}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? t.success : t.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.text)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: t.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 11, color: t.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
        ],
      ),
    );
  }
}
