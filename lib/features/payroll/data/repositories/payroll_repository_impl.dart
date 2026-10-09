import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_client.dart';
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/payroll/domain/entities/salary_structure_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/monthly_payroll_input_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_summary_entity.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_reconciliation_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  static http.Client get _http => ApiClient.client;
  String get _baseUrl => ApiConfig.baseUrl;

  String _formatError(http.Response res) {
    if (res.statusCode == 403) {
      return 'Access Denied: You do not have permission for this payroll action.';
    }
    if (res.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    try {
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return res.body.isNotEmpty ? res.body : 'Error ${res.statusCode} occurred.';
  }

  // =========================================================================
  // PHASE 1: STRUCTURE & INPUTS
  // =========================================================================

  @override
  Future<SalaryStructureEntity> getSalaryStructure(int employeeId) async {
    final url = Uri.parse('$_baseUrl/api/payroll/structure/$employeeId');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        return SalaryStructureEntity.fromJson(json.decode(res.body));
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching salary structure: $e');
      rethrow;
    }
  }

  @override
  Future<List<SalaryStructureEntity>> getAllSalaryStructures() async {
    final url = Uri.parse('$_baseUrl/api/payroll/structure');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        return list.map((item) => SalaryStructureEntity.fromJson(item)).toList();
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching all salary structures: $e');
      rethrow;
    }
  }

  @override
  Future<SalaryStructureEntity> saveSalaryStructure(SalaryStructureEntity structure) async {
    final url = Uri.parse('$_baseUrl/api/payroll/structure');
    try {
      final res = await _http.post(
        url,
        headers: AuthStorage.authHeaders,
        body: json.encode(structure.toJson()),
      );
      if (res.statusCode == 200) {
        return SalaryStructureEntity.fromJson(json.decode(res.body));
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error saving salary structure: $e');
      rethrow;
    }
  }

  @override
  Future<List<MonthlyPayrollInputEntity>> getMonthlyPayrollInputs({
    required String month,
    required int year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/inputs?month=$month&year=$year');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        return list.map((item) => MonthlyPayrollInputEntity.fromJson(item)).toList();
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching monthly payroll inputs: $e');
      rethrow;
    }
  }

  @override
  Future<MonthlyPayrollInputEntity> saveMonthlyPayrollInput(MonthlyPayrollInputEntity input) async {
    final url = Uri.parse('$_baseUrl/api/payroll/inputs');
    try {
      final res = await _http.post(
        url,
        headers: AuthStorage.authHeaders,
        body: json.encode(input.toJson()),
      );
      if (res.statusCode == 200) {
        return MonthlyPayrollInputEntity.fromJson(json.decode(res.body));
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error saving monthly payroll input: $e');
      rethrow;
    }
  }

  @override
  Future<List<MonthlyPayrollInputEntity>> syncInputsFromAttendance({
    required String month,
    required int year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/inputs/sync?month=$month&year=$year');
    try {
      final res = await _http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        return list.map((item) => MonthlyPayrollInputEntity.fromJson(item)).toList();
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error syncing inputs from attendance: $e');
      rethrow;
    }
  }

  @override
  Future<void> lockInputs({required String month, required int year}) async {
    final url = Uri.parse('$_baseUrl/api/payroll/inputs/lock?month=$month&year=$year');
    try {
      final res = await _http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode != 200) {
        throw Exception(_formatError(res));
      }
    } catch (e) {
      debugPrint('Error locking inputs: $e');
      rethrow;
    }
  }

  @override
  Future<void> unlockInputs({required String month, required int year}) async {
    final url = Uri.parse('$_baseUrl/api/payroll/inputs/unlock?month=$month&year=$year');
    try {
      final res = await _http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode != 200) {
        throw Exception(_formatError(res));
      }
    } catch (e) {
      debugPrint('Error unlocking inputs: $e');
      rethrow;
    }
  }

  // =========================================================================
  // PHASE 2: PROCESSING & VERIFICATION
  // =========================================================================

  @override
  Future<List<PayrollRecordEntity>> processPayroll({required String month, required int year}) async {
    final url = Uri.parse('$_baseUrl/api/payroll/process?month=$month&year=$year');
    try {
      final res = await _http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        return list.map((item) => PayrollRecordEntity.fromJson(item)).toList();
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error processing batch payroll: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyPayroll({required String month, required int year}) async {
    final url = Uri.parse('$_baseUrl/api/payroll/verify?month=$month&year=$year');
    try {
      final res = await _http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode != 200) {
        throw Exception(_formatError(res));
      }
    } catch (e) {
      debugPrint('Error verifying batch payroll: $e');
      rethrow;
    }
  }

  // =========================================================================
  // PHASE 3: PUBLISHING & ESS
  // =========================================================================

  @override
  Future<void> publishPayroll({required String month, required int year}) async {
    final url = Uri.parse('$_baseUrl/api/payroll/publish?month=$month&year=$year');
    try {
      final res = await _http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode != 200) {
        throw Exception(_formatError(res));
      }
    } catch (e) {
      debugPrint('Error publishing batch payroll: $e');
      rethrow;
    }
  }

  @override
  Future<List<PayrollRecordEntity>> getPayslips({
    required int employeeId,
    bool onlyPublished = true,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/payslips?employeeId=$employeeId&onlyPublished=$onlyPublished');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        return list.map((item) => PayrollRecordEntity.fromJson(item)).toList();
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching employee payslips: $e');
      rethrow;
    }
  }

  @override
  Future<PayrollRecordEntity> getPayslipById(String recordId) async {
    final url = Uri.parse('$_baseUrl/api/payroll/payslip/$recordId');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        return PayrollRecordEntity.fromJson(json.decode(res.body));
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching payslip by ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<PayrollRecordEntity>> getPayrollRecordsForMonth({
    required String month,
    required int year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/records?month=$month&year=$year');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        return list.map((item) => PayrollRecordEntity.fromJson(item)).toList();
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching records for month: $e');
      rethrow;
    }
  }

  @override
  Future<PayrollSummaryDtoEntity> getPayrollSummary({
    required String month,
    required int year,
  }) async => getPayrollSummaryInternal(month: month, year: year);

  Future<PayrollSummaryEntity> getPayrollSummaryInternal({
    required String month,
    required int year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/summary?month=$month&year=$year');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        return PayrollSummaryEntity.fromJson(json.decode(res.body));
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching payroll summary: $e');
      rethrow;
    }
  }

  // =========================================================================
  // PHASE 4: RECONCILIATION & BANKING EXPORT
  // =========================================================================

  @override
  Future<PayrollReconciliationReportEntity> getReconciliationReport({
    required String month,
    required int year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/reconciliation?month=$month&year=$year');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        return PayrollReconciliationReportEntity.fromJson(json.decode(res.body));
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error fetching reconciliation report: $e');
      rethrow;
    }
  }

  @override
  Future<Uint8List> exportBankPayoutCsv({
    required String month,
    required int year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payroll/export/bank-file?month=$month&year=$year');
    try {
      final res = await _http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        return res.bodyBytes;
      }
      throw Exception(_formatError(res));
    } catch (e) {
      debugPrint('Error exporting bank payout CSV: $e');
      rethrow;
    }
  }
}

typedef PayrollSummaryDtoEntity = PayrollSummaryEntity;
