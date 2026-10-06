import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/utils/file_downloader.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/presentation/utils/payslip_pdf_generator.dart';

class PayslipDetailModal extends StatefulWidget {
  final PayrollRecordEntity record;
  final bool isDialog;

  const PayslipDetailModal({super.key, required this.record, this.isDialog = false});

  static void show(BuildContext context, PayrollRecordEntity record) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
              child: PayslipDetailModal(record: record, isDialog: true),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PayslipDetailModal(record: record, isDialog: false),
      );
    }
  }

  @override
  State<PayslipDetailModal> createState() => _PayslipDetailModalState();
}

class _PayslipDetailModalState extends State<PayslipDetailModal> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final pdfBytes = await PayslipPdfGenerator.generatePayslipPdf(widget.record);
      final empCode = widget.record.employeeCode.isNotEmpty ? widget.record.employeeCode : 'EMP${widget.record.employeeId}';
      final fileName = 'Payslip_${empCode}_${widget.record.payrollMonth}_${widget.record.payrollYear}.pdf';

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
          content: Text('Failed to generate PDF payslip: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isDialog = widget.isDialog;
    final t = context.appTheme;
    final theme = Theme.of(context);
    final borderRadius = isDialog
        ? BorderRadius.circular(24)
        : const BorderRadius.vertical(top: Radius.circular(24));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 720,
      ),
      margin: isDialog
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 24)
          : EdgeInsets.only(
              left: MediaQuery.of(context).size.width > 760 ? (MediaQuery.of(context).size.width - 720) / 2 : 0,
              right: MediaQuery.of(context).size.width > 760 ? (MediaQuery.of(context).size.width - 720) / 2 : 0,
            ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: borderRadius,
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle for mobile bottom sheet
          if (!isDialog)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: t.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payslip for ${record.payrollMonth} ${record.payrollYear}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.employeeName} (${record.employeeCode}) • ${record.designation}',
                        style: theme.textTheme.bodySmall?.copyWith(color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: t.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Take-home net pay
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.primary.withValues(alpha: 0.18), t.secondary.withValues(alpha: 0.12)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'NET TAKE-HOME PAY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${record.netPay.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: record.isPublished ? t.success.withValues(alpha: 0.15) : t.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record.isPublished ? 'PUBLISHED & DISBURSED' : 'STATUS: ${record.status}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: record.isPublished ? t.success : t.warning,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: t.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: t.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                record.taxRegime.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: t.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Comparative breakdown (Earnings vs Deductions)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildEarningsCard(context, t)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDeductionsCard(context, t)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildEarningsCard(context, t),
                          const SizedBox(height: 16),
                          _buildDeductionsCard(context, t),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Attendance Snapshot
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance & Calendar Days',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total Days', record.totalDaysInMonth.toString(), t),
                            _buildStatItem('Paid Days', record.paidDays.toStringAsFixed(record.paidDays.truncateToDouble() == record.paidDays ? 0 : 1), t),
                            _buildStatItem('LOP Days', '${record.lopDays}', t, highlight: record.lopDays > 0),
                            _buildStatItem('OT Hours', '${record.overtimeHours}h', t),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Functional Download PDF button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadPdf,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isDownloading ? 'Generating PDF...' : 'Download Official PDF Payslip',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, dynamic t) {
    final record = widget.record;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EARNINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.success)),
              Text('₹${record.totalGrossPay.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
            ],
          ),
          const Divider(height: 18),
          _buildLineItem('Basic Pay', record.calculatedBasic, t),
          _buildLineItem('House Rent Allowance (HRA)', record.calculatedHra, t),
          _buildLineItem('Conveyance Allowance', record.calculatedConveyance, t),
          _buildLineItem('Medical Allowance', record.calculatedMedical, t),
          _buildLineItem('Special Allowance', record.calculatedSpecial, t),
          if (record.overtimeAmount > 0)
            _buildLineItem('Overtime Pay', record.overtimeAmount, t, isGreen: true),
          if (record.adHocBonus > 0)
            _buildLineItem('Ad-Hoc Bonus', record.adHocBonus, t, isGreen: true),
          if (record.arrearsAmount > 0)
            _buildLineItem('Arrears / Revision Payout', record.arrearsAmount, t, isGreen: true),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard(BuildContext context, dynamic t) {
    final record = widget.record;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEDUCTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.danger)),
              Text('₹${record.totalDeductions.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
            ],
          ),
          const Divider(height: 18),
          _buildLineItem('Provident Fund (PF)', record.calculatedPf, t),
          if (record.calculatedEsi > 0)
            _buildLineItem('ESI Contribution', record.calculatedEsi, t),
          _buildLineItem('Professional Tax (PT)', record.calculatedPt, t),
          if (record.calculatedTds > 0)
            _buildLineItem('Income Tax (TDS)', record.calculatedTds, t, isRed: true),
          if (record.lopDeductionAmount > 0)
            _buildLineItem('LOP Deduction', record.lopDeductionAmount, t, isRed: true),
          if (record.adHocDeduction > 0)
            _buildLineItem('Ad-Hoc Deduction', record.adHocDeduction, t, isRed: true),
        ],
      ),
    );
  }

  Widget _buildLineItem(String title, double amount, dynamic t, {bool isGreen = false, bool isRed = false}) {
    Color col = t.text;
    if (isGreen) col = t.success;
    if (isRed) col = t.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: t.textSecondary))),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: col)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, dynamic t, {bool highlight = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: highlight ? t.danger : t.text)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: t.textSecondary)),
      ],
    );
  }
}
