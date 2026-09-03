import 'package:hr_management/features/attendance/domain/entities/attendance_calendar_day.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceCalendarDay>> getMonthlyCalendarSummary({
    required String employeeId,
    required int year,
    required int month,
  });

  Future<Map<String, dynamic>?> importBiometricExcel({
    required List<int> fileBytes,
    required String fileName,
    required DateTime targetDate,
  });
}
