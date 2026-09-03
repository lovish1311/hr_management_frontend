class AttendanceCalendarDay {
  final DateTime date;
  final String status; // PRESENT, LATE, PAID_LEAVE, LOP_LEAVE, UNEXCUSED_ABSENT, HOLIDAY, WEEKEND, UPCOMING
  final String statusLabel;
  final String? leaveType;
  final String? checkInTime;
  final String? checkOutTime;
  final String? notes;
  final bool isWeekend;
  final bool isHoliday;
  final int? leaveRequestId;
  final int totalWorkingMinutes;

  const AttendanceCalendarDay({
    required this.date,
    required this.status,
    required this.statusLabel,
    this.leaveType,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.isWeekend = false,
    this.isHoliday = false,
    this.leaveRequestId,
    this.totalWorkingMinutes = 0,
  });

  factory AttendanceCalendarDay.fromJson(Map<String, dynamic> json) {
    return AttendanceCalendarDay(
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'UPCOMING',
      statusLabel: json['statusLabel'] ?? '',
      leaveType: json['leaveType'],
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      notes: json['notes'],
      isWeekend: json['isWeekend'] ?? false,
      isHoliday: json['isHoliday'] ?? false,
      leaveRequestId: json['leaveRequestId'] != null ? (json['leaveRequestId'] as num).toInt() : null,
      totalWorkingMinutes: json['totalWorkingMinutes'] != null ? (json['totalWorkingMinutes'] as num).toInt() : 0,
    );
  }
}
