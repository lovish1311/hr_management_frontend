import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/presentation/utils/payslip_pdf_generator.dart';

void main() {
  group('PayslipPdfGenerator Enterprise Test Suite', () {
    test('generates valid binary PDF bytes with standard %PDF- header', () async {
      const record = PayrollRecordEntity(
        id: 'test-uuid-101',
        employeeId: 42,
        employeeName: 'Aarav Sharma',
        employeeCode: 'EMP-0042',
        designation: 'Senior Software Architect',
        department: 'Platform Engineering',
        bankAccountNumber: '••••••••8912',
        payrollMonth: 'OCTOBER',
        payrollYear: 2026,
        totalDaysInMonth: 31,
        paidDays: 30.0,
        lopDays: 1.0,
        overtimeHours: 6.5,
        masterFixedGross: 120000.0,
        calculatedBasic: 60000.0,
        calculatedHra: 24000.0,
        calculatedConveyance: 5000.0,
        calculatedMedical: 5000.0,
        calculatedSpecial: 26000.0,
        overtimeAmount: 2800.0,
        adHocBonus: 10000.0,
        arrearsAmount: 1500.0,
        calculatedPf: 1800.0,
        calculatedEsi: 0.0,
        calculatedPt: 200.0,
        calculatedTds: 12500.0,
        lopDeductionAmount: 3870.0,
        adHocDeduction: 0.0,
        totalGrossPay: 134300.0,
        totalDeductions: 18370.0,
        netPay: 115930.0,
        status: 'PUBLISHED',
      );

      final pdfBytes = await PayslipPdfGenerator.generatePayslipPdf(record);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);

      // Verify PDF Magic Bytes: First bytes must be '%PDF-'
      final headerString = ascii.decode(pdfBytes.sublist(0, 5));
      expect(headerString, equals('%PDF-'));
    });

    test('handles edge case amounts (zero values, decimal paid days) gracefully', () async {
      const zeroRecord = PayrollRecordEntity(
        id: 'zero-test-id',
        employeeId: 1,
        employeeName: 'New Hire',
        employeeCode: 'EMP-0001',
        designation: 'Associate',
        department: 'Operations',
        bankAccountNumber: '••••1234',
        payrollMonth: 'NOVEMBER',
        payrollYear: 2026,
        totalDaysInMonth: 30,
        paidDays: 15.5,
        lopDays: 14.5,
        overtimeHours: 0.0,
        calculatedBasic: 20000.0,
        totalGrossPay: 20000.0,
        totalDeductions: 500.0,
        netPay: 19500.0,
        status: 'PUBLISHED',
      );

      final pdfBytes = await PayslipPdfGenerator.generatePayslipPdf(zeroRecord);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
