// Package: hr_management

class DashboardStats {
  final int totalEmployees;
  final int presentToday;
  final int onLeaveToday;
  final List<LeaveRequest> pendingLeaves;

  DashboardStats({
    required this.totalEmployees,
    required this.presentToday,
    required this.onLeaveToday,
    required this.pendingLeaves,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final pendingLeavesJson = json['pendingLeaves'];
    return DashboardStats(
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      presentToday: json['presentToday'] as int? ?? 0,
      onLeaveToday: json['onLeaveToday'] as int? ?? 0,
      pendingLeaves: pendingLeavesJson is List
          ? pendingLeavesJson
              .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class LeaveRequest {
  final int id;
  final String employeeName;
  final String startDate;
  final String endDate;
  final String reason;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      employeeName: json['employeeName'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      reason: json['reason'] as String,
    );
  }

  String get dates {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final startStr = "${months[start.month - 1]} ${start.day}";
      final endStr = "${months[end.month - 1]} ${end.day}";
      return "$startStr - $endStr";
    } catch (_) {
      return "$startDate - $endDate";
    }
  }
}
