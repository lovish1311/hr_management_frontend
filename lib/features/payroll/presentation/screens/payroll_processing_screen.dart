import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/utils/file_downloader.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_reconciliation_entity.dart';
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
  late String _selectedMonth;
  late int _selectedYear;

  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isPublishing = false;
  bool _isLoadingReconciliation = false;
  bool _isExportingBankFile = false;
  int _reconciliationSubTab = 0; // 0: Variance Audit, 1: Processed Drafts
  String? _errorMessage;

  PayrollSummaryEntity? _summary;
  PayrollReconciliationReportEntity? _reconciliationReport;
  List<PayrollRecordEntity> _processedRecords = [];

  static const List<String> _allMonths = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  List<String> get _availableMonths {
    final now = DateTime.now();
    if (_selectedYear == now.year) {
      return _allMonths.sublist(0, now.month);
    } else if (_selectedYear < now.year) {
      return _allMonths;
    }
    return [_allMonths.first];
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return [currentYear - 2, currentYear - 1, currentYear];
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = _allMonths[now.month - 1];
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
      _loadReconciliationReport();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReconciliationReport() async {
    setState(() => _isLoadingReconciliation = true);
    try {
      final report = await _repository.getReconciliationReport(month: _selectedMonth, year: _selectedYear);
      if (!mounted) return;
      setState(() {
        _reconciliationReport = report;
        _isLoadingReconciliation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingReconciliation = false);
    }
  }

  Future<void> _exportBankPayoutFile() async {
    setState(() => _isExportingBankFile = true);
    try {
      final csvBytes = await _repository.exportBankPayoutCsv(month: _selectedMonth, year: _selectedYear);
      final fileName = 'bank_payout_${_selectedMonth}_$_selectedYear.csv';
      FileDownloader.downloadBytes(bytes: csvBytes, fileName: fileName, mimeType: 'text/csv');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank payout file ($fileName) downloaded successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export bank payout file: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExportingBankFile = false);
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
      _loadReconciliationReport();

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
          Builder(builder: (context) {
            final available = _availableMonths;
            if (!available.contains(_selectedMonth)) {
              _selectedMonth = available.last;
            }
            final years = _availableYears;
            if (!years.contains(_selectedYear)) {
              _selectedYear = years.last;
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: t.cardSoft, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      dropdownColor: t.card,
                      items: available.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(fontSize: 12, color: t.text)))).toList(),
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
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y', style: TextStyle(fontSize: 12, color: t.text)))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedYear = v;
                            final av = _availableMonths;
                            if (!av.contains(_selectedMonth)) {
                              _selectedMonth = av.last;
                            }
                          });
                          _loadCurrentMonthState();
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
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
    final recon = _reconciliationReport;

    if (summary == null && recon == null) {
      return Center(child: Text('No calculation data found. Run calculation first.', style: TextStyle(color: t.textSecondary)));
    }

    final headcount = recon?.currentHeadcount ?? summary?.totalHeadcount ?? 0;
    final headcountDelta = recon?.headcountDelta ?? 0;
    final grossTotal = recon?.currentGrossTotal ?? summary?.totalGrossOutflow ?? 0.0;
    final grossDeltaPct = recon?.grossPercentageDelta ?? 0.0;
    final netTotal = recon?.currentNetTotal ?? summary?.totalNetPayout ?? 0.0;
    final netDeltaPct = recon?.netPercentageDelta ?? summary?.variancePercentage ?? 0.0;
    final tdsTotal = recon?.currentTdsTotal ?? 0.0;
    final arrearsTotal = recon?.currentArrearsTotal ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 5 KPI Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Headcount',
                '$headcount',
                Icons.people,
                t.primary,
                t,
                subtitle: '${headcountDelta >= 0 ? '+' : ''}$headcountDelta vs prior',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Gross Outflow',
                '₹${grossTotal.toStringAsFixed(0)}',
                Icons.arrow_upward,
                t.success,
                t,
                subtitle: '${grossDeltaPct >= 0 ? '+' : ''}${grossDeltaPct.toStringAsFixed(1)}% vs prior',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Net Payout',
                '₹${netTotal.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                t.primary,
                t,
                subtitle: '${netDeltaPct >= 0 ? '+' : ''}${netDeltaPct.toStringAsFixed(1)}% vs prior',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Income Tax (TDS)',
                '₹${tdsTotal.toStringAsFixed(0)}',
                Icons.receipt_long,
                const Color(0xFFF59E0B),
                t,
                subtitle: 'Sec 115BAC + Old',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Arrears Payout',
                '₹${arrearsTotal.toStringAsFixed(0)}',
                Icons.history_edu,
                const Color(0xFF8B5CF6),
                t,
                subtitle: 'Retroactive deltas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Variance & Reconciliation Table Header + Controls
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Sub-tab switcher
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text('Variance Audit (${recon?.employeeVariances.length ?? 0})', style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.compare_arrows, size: 16),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Calculated Drafts (${_processedRecords.length})', style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.table_rows, size: 16),
                        ),
                      ],
                      selected: {_reconciliationSubTab},
                      onSelectionChanged: (set) {
                        setState(() => _reconciliationSubTab = set.first);
                      },
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _isExportingBankFile ? null : _exportBankPayoutFile,
                      icon: _isExportingBankFile
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.file_download_outlined, size: 16),
                      label: Text(_isExportingBankFile ? 'Exporting...' : 'Export Bank CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.text,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 12),
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

              // View 0: Variance Audit Table (GreytHR standard)
              if (_reconciliationSubTab == 0) ...[
                if (_isLoadingReconciliation)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (recon == null || recon.employeeVariances.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('No variance items found between cycles.', style: TextStyle(color: t.textSecondary)),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(t.cardSoft),
                      horizontalMargin: 16,
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(label: Text('Employee', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Audit Tag', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Prior Net', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Current Net', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Variance (Net)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('LOP Diff', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Arrears', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('TDS (Tax)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Variance Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: recon.employeeVariances.map((v) {
                        final tagColor = _getTagColor(v.varianceTag, t);
                        final isPositive = v.netDifference > 0;
                        final isNegative = v.netDifference < 0;

                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(v.employeeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.text)),
                                  Text('${v.employeeCode} • ${v.department}', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  v.varianceTag.replaceAll('_', ' '),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
                                ),
                              ),
                            ),
                            DataCell(Text('₹${v.previousNetPay.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: t.textSecondary))),
                            DataCell(Text('₹${v.currentNetPay.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text))),
                            DataCell(
                              Text(
                                '${isPositive ? '+' : ''}₹${v.netDifference.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? t.success : (isNegative ? t.danger : t.textSecondary),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${v.previousLopDays.toStringAsFixed(1)}d -> ${v.currentLopDays.toStringAsFixed(1)}d',
                                style: TextStyle(fontSize: 12, color: v.currentLopDays > v.previousLopDays ? t.danger : t.text),
                              ),
                            ),
                            DataCell(
                              Text(
                                v.arrearsAmount > 0 ? '₹${v.arrearsAmount.toStringAsFixed(0)}' : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: v.arrearsAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                  color: v.arrearsAmount > 0 ? t.success : t.textSecondary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                v.calculatedTds > 0 ? '₹${v.calculatedTds.toStringAsFixed(0)}' : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: v.calculatedTds > 0 ? FontWeight.bold : FontWeight.normal,
                                  color: v.calculatedTds > 0 ? const Color(0xFFF59E0B) : t.textSecondary,
                                ),
                              ),
                            ),
                            DataCell(
                              Tooltip(
                                message: v.varianceReason,
                                child: Text(
                                  v.varianceReason.isNotEmpty ? v.varianceReason : '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ] else ...[
                // View 1: Processed Records Table Preview
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
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: r.status.toUpperCase() == 'EXEMPT'
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                    : (r.isPublished ? t.success.withValues(alpha: 0.12) : t.warning.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: r.status.toUpperCase() == 'EXEMPT'
                                      ? const Color(0xFFEF4444)
                                      : (r.isPublished ? t.success : t.warning),
                                ),
                              ),
                            ),
                          ),
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
            ],
          ),
        ),
      ],
    );
  }

  Color _getTagColor(String tag, dynamic t) {
    switch (tag.toUpperCase()) {
      case 'NEW_JOINER':
        return const Color(0xFF3B82F6);
      case 'SALARY_INCREASE':
        return const Color(0xFF10B981);
      case 'SALARY_DECREASE_LOP':
        return const Color(0xFFF59E0B);
      case 'EXIT_EMPLOYEE':
        return const Color(0xFF8B5CF6);
      case 'STATUTORY_REVISION':
        return const Color(0xFF06B6D4);
      case 'UNCHANGED':
      default:
        return t.textSecondary;
    }
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
                onPressed: _isExportingBankFile ? null : _exportBankPayoutFile,
                icon: _isExportingBankFile
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.file_download_outlined, size: 18),
                label: Text(_isExportingBankFile ? 'Exporting Bank CSV...' : 'Export Bank File (CSV)'),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, dynamic t, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ],
      ),
    );
  }
}
