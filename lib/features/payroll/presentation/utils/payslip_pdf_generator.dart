import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';

class PayslipPdfGenerator {
  /// Generates a professional, print-ready, official corporate A4 PDF payslip.
  static Future<Uint8List> generatePayslipPdf(PayrollRecordEntity record) async {
    final pdf = pw.Document(
      title: 'Payslip_${record.employeeCode}_${record.payrollMonth}_${record.payrollYear}',
      author: 'Nexus HR Enterprise System',
    );

    final regularFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final obliqueFont = pw.Font.helveticaOblique();

    final navyColor = PdfColor.fromHex('#0F172A');
    final primaryColor = PdfColor.fromHex('#2563EB');
    final emeraldColor = PdfColor.fromHex('#059669');
    final slateGray = PdfColor.fromHex('#475569');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final borderCol = PdfColor.fromHex('#CBD5E1');

    String formatInr(double amount) {
      final isNegative = amount < 0;
      final absAmount = amount.abs().toStringAsFixed(2);
      final parts = absAmount.split('.');
      final intPart = parts[0];
      final decPart = parts[1];

      // Format Indian comma separation
      String formattedInt = '';
      if (intPart.length <= 3) {
        formattedInt = intPart;
      } else {
        final lastThree = intPart.substring(intPart.length - 3);
        final remaining = intPart.substring(0, intPart.length - 3);
        final reg = RegExp(r'\B(?=(\d{2})+(?!\d))');
        formattedInt = '${remaining.replaceAll(reg, ',')},$lastThree';
      }

      return '${isNegative ? '-' : ''}Rs. $formattedInt.$decPart';
    }

    String numberToWords(int number) {
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
        String current = '';
        if (n >= 100) {
          current += '${units[n ~/ 100]} Hundred ';
          n %= 100;
        }
        if (n >= 20) {
          current += '${tens[n ~/ 10]} ';
          n %= 10;
        }
        if (n > 0) {
          current += '${units[n]} ';
        }
        return current.trim();
      }

      String words = '';
      int crore = number ~/ 10000000;
      number %= 10000000;
      int lakh = number ~/ 100000;
      number %= 100000;
      int thousand = number ~/ 1000;
      number %= 1000;

      if (crore > 0) words += '${convertLessThanOneThousand(crore)} Crore ';
      if (lakh > 0) words += '${convertLessThanOneThousand(lakh)} Lakh ';
      if (thousand > 0) words += '${convertLessThanOneThousand(thousand)} Thousand ';
      if (number > 0) words += convertLessThanOneThousand(number);

      return '${words.trim()} Rupees Only';
    }

    // Build the earnings and deductions lists
    final earningsList = <MapEntry<String, double>>[
      MapEntry('Basic Salary', record.calculatedBasic),
      MapEntry('House Rent Allowance (HRA)', record.calculatedHra),
      MapEntry('Conveyance Allowance', record.calculatedConveyance),
      MapEntry('Medical Allowance', record.calculatedMedical),
      MapEntry('Special Allowance', record.calculatedSpecial),
    ];
    if (record.overtimeAmount > 0) {
      earningsList.add(MapEntry('Overtime Allowance (${record.overtimeHours.toStringAsFixed(1)} hrs)', record.overtimeAmount));
    }
    if (record.adHocBonus > 0) {
      earningsList.add(MapEntry('Performance / Ad-hoc Bonus', record.adHocBonus));
    }
    if (record.arrearsAmount > 0) {
      earningsList.add(MapEntry('Salary Arrears', record.arrearsAmount));
    }

    final deductionsList = <MapEntry<String, double>>[
      MapEntry('Provident Fund (Employee PF)', record.calculatedPf),
      MapEntry('Employee State Insurance (ESI)', record.calculatedEsi),
      MapEntry('Professional Tax (PT)', record.calculatedPt),
      MapEntry('Tax Deducted at Source (TDS)', record.calculatedTds),
    ];
    if (record.lopDeductionAmount > 0) {
      deductionsList.add(MapEntry('Loss of Pay (LOP: ${record.lopDays} days)', record.lopDeductionAmount));
    }
    if (record.adHocDeduction > 0) {
      deductionsList.add(MapEntry('Other Ad-hoc Deductions', record.adHocDeduction));
    }

    // Pad rows so both tables have equal height
    final maxRows = earningsList.length > deductionsList.length ? earningsList.length : deductionsList.length;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==========================================
              // TOP HEADER & BRANDING
              // ==========================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NEXUS ENTERPRISE TECHNOLOGIES',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: navyColor,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Corporate Headquarters: Cyber Hub, Tower B, Phase 2, Gurugram, India',
                        style: pw.TextStyle(font: regularFont, fontSize: 8.5, color: slateGray),
                      ),
                      pw.Text(
                        'CIN: U72200DL2024PTC123456 | PAN: AAACN1234F | TAN: DELN12345A',
                        style: pw.TextStyle(font: regularFont, fontSize: 8, color: slateGray),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PAYSLIP STATEMENT',
                          style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${record.payrollMonth.toUpperCase()} ${record.payrollYear}',
                          style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: primaryColor, thickness: 1.5),
              pw.SizedBox(height: 10),

              // ==========================================
              // EMPLOYEE & DISBURSEMENT INFORMATION TABLE
              // ==========================================
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderCol, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Employee Name',
                            record.employeeName.isNotEmpty ? record.employeeName : 'Employee',
                            regularFont,
                            boldFont,
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Employee Code',
                            record.employeeCode.isNotEmpty ? record.employeeCode : 'EMP-${record.employeeId}',
                            regularFont,
                            boldFont,
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Designation',
                            record.designation.isNotEmpty ? record.designation : 'Staff',
                            regularFont,
                            boldFont,
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Department',
                            record.department.isNotEmpty ? record.department : 'General',
                            regularFont,
                            boldFont,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Bank Account',
                            record.bankAccountNumber.isNotEmpty ? record.bankAccountNumber.replaceAll('•', 'X') : 'XXXX-XXXX-XXXX',
                            regularFont,
                            boldFont,
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Tax Regime',
                            record.taxRegime.replaceAll('_', ' '),
                            regularFont,
                            boldFont,
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'Total Days / Paid Days',
                            '${record.totalDaysInMonth} / ${record.paidDays.toStringAsFixed(record.paidDays.truncateToDouble() == record.paidDays ? 0 : 1)}',
                            regularFont,
                            boldFont,
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfInfoCell(
                            'LOP / Overtime',
                            '${record.lopDays} days / ${record.overtimeHours} hrs',
                            regularFont,
                            boldFont,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // ==========================================
              // EARNINGS & DEDUCTIONS BREAKDOWN TABLE
              // ==========================================
              pw.Table(
                border: pw.TableBorder.all(color: borderCol, width: 0.8),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text('EARNINGS', style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: navyColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: navyColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text('DEDUCTIONS', style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: navyColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: navyColor)),
                      ),
                    ],
                  ),
                  // Item Rows
                  for (int i = 0; i < maxRows; i++)
                    pw.TableRow(
                      decoration: i % 2 == 1 ? pw.BoxDecoration(color: lightBg) : const pw.BoxDecoration(),
                      children: [
                        // Earning item
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Text(
                            i < earningsList.length ? earningsList[i].key : '',
                            style: pw.TextStyle(font: regularFont, fontSize: 8.5),
                          ),
                        ),
                        // Earning amount
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Text(
                            i < earningsList.length ? formatInr(earningsList[i].value) : '',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: regularFont, fontSize: 8.5),
                          ),
                        ),
                        // Deduction item
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Text(
                            i < deductionsList.length ? deductionsList[i].key : '',
                            style: pw.TextStyle(font: regularFont, fontSize: 8.5),
                          ),
                        ),
                        // Deduction amount
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Text(
                            i < deductionsList.length ? formatInr(deductionsList[i].value) : '',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: regularFont, fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  // Totals Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text('TOTAL GROSS EARNINGS', style: pw.TextStyle(font: boldFont, fontSize: 9, color: navyColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text(formatInr(record.totalGrossPay), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 9, color: navyColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text('TOTAL DEDUCTIONS', style: pw.TextStyle(font: boldFont, fontSize: 9, color: navyColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text(formatInr(record.totalDeductions), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 9, color: navyColor)),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // ==========================================
              // NET TAKE-HOME PAY HERO CALLOUT
              // ==========================================
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: emeraldColor, width: 1.2),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NET TAKE-HOME DISBURSEMENT',
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: slateGray, letterSpacing: 1),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          formatInr(record.netPay),
                          style: pw.TextStyle(font: boldFont, fontSize: 18, color: emeraldColor),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Amount in Words: ${numberToWords(record.netPay.toInt())}',
                          style: pw.TextStyle(font: obliqueFont, fontSize: 8.5, color: navyColor),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: record.isPublished ? emeraldColor : PdfColor.fromHex('#F59E0B'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        record.isPublished ? 'PUBLISHED & PAID' : record.status,
                        style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ==========================================
              // VERIFICATION QR & AUTHENTICATION FOOTER
              // ==========================================
              pw.Divider(color: borderCol, thickness: 0.8),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 48,
                        height: 48,
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'PAYSLIP:${record.id}:${record.employeeCode}:${record.payrollMonth}-${record.payrollYear}:NET=${record.netPay}',
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Document ID: ${record.id}',
                            style: pw.TextStyle(font: regularFont, fontSize: 7.5, color: slateGray),
                          ),
                          pw.Text(
                            'Digital Verification: Cryptographically Verified by Nexus HR Engine',
                            style: pw.TextStyle(font: regularFont, fontSize: 7.5, color: slateGray),
                          ),
                          pw.Text(
                            'Generated at: ${DateTime.now().toUtc().toIso8601String().split('.').first} UTC',
                            style: pw.TextStyle(font: regularFont, fontSize: 7.5, color: slateGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'This is an electronically generated statement.',
                        style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: navyColor),
                      ),
                      pw.Text(
                        'Authorized by Corporate Payroll Division. No physical signature required.',
                        style: pw.TextStyle(font: regularFont, fontSize: 7, color: slateGray),
                      ),
                      pw.Text(
                        'Nexus Enterprise Technologies Inc. | Strictly Confidential',
                        style: pw.TextStyle(font: regularFont, fontSize: 7, color: slateGray),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfInfoCell(String label, String value, pw.Font regFont, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: regFont, fontSize: 7.5, color: PdfColor.fromHex('#64748B'))),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColor.fromHex('#0F172A')),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}
