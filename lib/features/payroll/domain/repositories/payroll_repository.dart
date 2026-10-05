import 'package:hr_management/features/payroll/domain/entities/salary_structure_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/monthly_payroll_input_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_summary_entity.dart';

abstract class PayrollRepository {
  // Phase 1: Structure & Inputs
  Future<SalaryStructureEntity> getSalaryStructure(int employeeId);
  Future<List<SalaryStructureEntity>> getAllSalaryStructures();
  Future<SalaryStructureEntity> saveSalaryStructure(SalaryStructureEntity structure);

  Future<List<MonthlyPayrollInputEntity>> getMonthlyPayrollInputs({required String month, required int year});
  Future<MonthlyPayrollInputEntity> saveMonthlyPayrollInput(MonthlyPayrollInputEntity input);
  Future<List<MonthlyPayrollInputEntity>> syncInputsFromAttendance({required String month, required int year});
  Future<void> lockInputs({required String month, required int year});
  Future<void> unlockInputs({required String month, required int year});

  // Phase 2: Processing & Verification
  Future<List<PayrollRecordEntity>> processPayroll({required String month, required int year});
  Future<void> verifyPayroll({required String month, required int year});

  // Phase 3: Publishing & ESS
  Future<void> publishPayroll({required String month, required int year});
  Future<List<PayrollRecordEntity>> getPayslips({required int employeeId, bool onlyPublished = true});
  Future<PayrollRecordEntity> getPayslipById(String recordId);
  Future<List<PayrollRecordEntity>> getPayrollRecordsForMonth({required String month, required int year});
  Future<PayrollSummaryEntity> getPayrollSummary({required String month, required int year});
}
