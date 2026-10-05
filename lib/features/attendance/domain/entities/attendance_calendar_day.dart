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
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'UPCOMING',
      statusLabel: json['statusLabel']?.toString() ?? '',
      leaveType: json['leaveType']?.toString(),
      checkInTime: json['checkInTime']?.toString(),
      checkOutTime: json['checkOutTime']?.toString(),
      notes: json['notes']?.toString(),
      isWeekend: json['isWeekend'] == true,
      isHoliday: json['isHoliday'] == true,
      leaveRequestId: (json['leaveRequestId'] as num?)?.toInt() ?? (int.tryParse(json['leaveRequestId']?.toString() ?? '')),
      totalWorkingMinutes: (json['totalWorkingMinutes'] as num?)?.toInt() ?? (int.tryParse(json['totalWorkingMinutes']?.toString() ?? '') ?? 0),
    );
  }
}
