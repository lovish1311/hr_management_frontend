import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/utils/file_downloader.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hr_management/features/payroll/presentation/utils/payslip_pdf_generator.dart';
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
  String? _downloadingRecordId;

  String _selectedFinancialYear = 'All Financial Years';
  final List<String> _financialYears = ['All Financial Years', 'FY 2026-27', 'FY 2025-26', 'FY 2024-25'];

  @override
  void initState() {
    super.initState();
    AuthStorage.permissionRevision.addListener(_onPermissionsChanged);
    _fetchPayslips();
  }

  void _onPermissionsChanged() {
    if (mounted) {
      setState(() {});
      _fetchPayslips();
    }
  }

  @override
  void dispose() {
    AuthStorage.permissionRevision.removeListener(_onPermissionsChanged);
    super.dispose();
  }

  Future<void> _fetchPayslips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final empId = AuthStorage.employeeId ?? 1;
    final isPrivileged = AuthStorage.canManagePayroll;

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

  List<PayrollRecordEntity> get _filteredPayslips {
    if (_selectedFinancialYear == 'All Financial Years') return _payslips;
    return _payslips.where((p) {
      final fyParts = _selectedFinancialYear.replaceAll('FY ', '').split('-');
      if (fyParts.length == 2) {
        final startYear = int.tryParse(fyParts[0]) ?? 2026;
        final endYear = int.tryParse('20${fyParts[1]}') ?? (startYear + 1);
        final monthUpper = p.payrollMonth.toUpperCase();
        final isEarlyYear = ['JANUARY', 'FEBRUARY', 'MARCH'].contains(monthUpper);
        if (isEarlyYear) {
          return p.payrollYear == endYear;
        } else {
          return p.payrollYear == startYear;
        }
      }
      return true;
    }).toList();
  }

  double get _ytdGross => _filteredPayslips.fold(0.0, (acc, p) => acc + p.totalGrossPay);
  double get _ytdNet => _filteredPayslips.fold(0.0, (acc, p) => acc + p.netPay);
  double get _ytdTaxDeductions => _filteredPayslips.fold(0.0, (acc, p) => acc + p.totalDeductions);

  Future<void> _downloadRecordPdf(PayrollRecordEntity record) async {
    if (_downloadingRecordId != null) return;
    setState(() => _downloadingRecordId = record.id);

    try {
      final pdfBytes = await PayslipPdfGenerator.generatePayslipPdf(record);
      final empCode = record.employeeCode.isNotEmpty ? record.employeeCode : 'EMP${record.employeeId}';
      final fileName = 'Payslip_${empCode}_${record.payrollMonth}_${record.payrollYear}.pdf';

      FileDownloader.downloadBytes(
        bytes: pdfBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Payslip downloaded: $fileName')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download payslip: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingRecordId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final theme = Theme.of(context);
    final isPrivileged = AuthStorage.canManagePayroll;
    final displayList = _filteredPayslips;

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
                                        '${displayList.length} statement${displayList.length == 1 ? '' : 's'}',
                                        style: TextStyle(fontSize: 12, color: t.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // List of Months
                                  if (displayList.isEmpty)
                                    _buildEmptyState(context, t)
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: displayList.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, idx) {
                                        final record = displayList[idx];
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final titleWidget = Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: t.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Payslip Dashboard',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: t.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Review your monthly take-home salary, earnings, and taxes',
                      style: TextStyle(fontSize: 11, color: t.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionsWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      }
                    },
                  ),
                ),
              ),
              if (isPrivileged) ...[
                const SizedBox(width: 8),
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
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionsWidget,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleWidget),
              const SizedBox(width: 16),
              actionsWidget,
            ],
          );
        },
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
              Expanded(
                child: Text(
                  'Year-to-Date (YTD) Summary ($_selectedFinancialYear)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text),
                  overflow: TextOverflow.ellipsis,
                ),
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
    final isDownloading = _downloadingRecordId == record.id;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Month & Status + Take Home Amount ────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: t.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.payrollMonth} ${record.payrollYear}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.text),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: record.isPublished ? t.success.withValues(alpha: 0.15) : t.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record.isPublished ? 'PAID & PUBLISHED' : record.status,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: record.isPublished ? t.success : t.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${record.netPay.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Net Take Home',
                        style: TextStyle(fontSize: 10, color: t.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: t.border.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              // ── Bottom Row: Paid days metadata + Download / View ───────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Paid: ${record.paidDays.toStringAsFixed(record.paidDays.truncateToDouble() == record.paidDays ? 0 : 1)}/${record.totalDaysInMonth} days • A/C ${record.bankAccountNumber.length > 4 ? record.bankAccountNumber.substring(record.bankAccountNumber.length - 4) : record.bankAccountNumber}',
                      style: TextStyle(fontSize: 11, color: t.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: isDownloading ? null : () => _downloadRecordPdf(record),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDownloading)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: t.primary),
                            )
                          else
                            Icon(Icons.download_rounded, size: 16, color: t.primary),
                          const SizedBox(width: 4),
                          Text(
                            'PDF',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 16, color: t.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
