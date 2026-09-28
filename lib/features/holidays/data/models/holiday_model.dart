class HolidayModel {
  final int? id;
  final int? holidayListId;
  final String name;
  final DateTime date;
  final String type; // GENERAL, RESTRICTED
  final String? description;
  final bool active;
  final String? status; // HOLIDAY, NOT_APPLIED, PENDING, APPROVED, REJECTED
  final int? leaveRequestId;

  HolidayModel({
    this.id,
    this.holidayListId,
    required this.name,
    required this.date,
    required this.type,
    this.description,
    this.active = true,
    this.status,
    this.leaveRequestId,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      holidayListId: json['holidayListId'] is int
          ? json['holidayListId']
          : int.tryParse(json['holidayListId']?.toString() ?? ''),
      name: json['name'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: (json['type'] ?? 'GENERAL').toString().toUpperCase(),
      description: json['description'],
      active: json['active'] ?? true,
      status: json['status']?.toString().toUpperCase(),
      leaveRequestId: json['leaveRequestId'] is int
          ? json['leaveRequestId']
          : int.tryParse(json['leaveRequestId']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (holidayListId != null) 'holidayListId': holidayListId,
      'name': name,
      'date':
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'type': type,
      'description': description,
      'active': active,
    };
  }

  bool get isGeneral => type == 'GENERAL';
  bool get isRestricted => type == 'RESTRICTED';
}

class HolidayListModel {
  final int? id;
  final String name;
  final int year;
  final String? description;
  final String applicableGroup;
  final bool active;
  final bool published;
  final int totalHolidays;
  final int generalHolidaysCount;
  final int restrictedHolidaysCount;
  final List<HolidayModel> holidays;

  HolidayListModel({
    this.id,
    required this.name,
    required this.year,
    this.description,
    this.applicableGroup = 'ALL',
    this.active = true,
    this.published = false,
    this.totalHolidays = 0,
    this.generalHolidaysCount = 0,
    this.restrictedHolidaysCount = 0,
    this.holidays = const [],
  });

  factory HolidayListModel.fromJson(Map<String, dynamic> json) {
    var rawHolidays = json['holidays'] as List? ?? [];
    return HolidayListModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      description: json['description'],
      applicableGroup: json['applicableGroup'] ?? 'ALL',
      active: json['active'] ?? true,
      published: json['published'] ?? false,
      totalHolidays: json['totalHolidays'] ?? 0,
      generalHolidaysCount: json['generalHolidaysCount'] ?? 0,
      restrictedHolidaysCount: json['restrictedHolidaysCount'] ?? 0,
      holidays: rawHolidays.map((h) => HolidayModel.fromJson(h)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'year': year,
      'description': description,
      'applicableGroup': applicableGroup,
      'active': active,
      'published': published,
    };
  }
}

class EmployeeHolidayCalendarModel {
  final int year;
  final double restrictedHolidayQuota;
  final double restrictedHolidayUsed;
  final double restrictedHolidayRemaining;
  final List<HolidayModel> holidays;

  EmployeeHolidayCalendarModel({
    required this.year,
    this.restrictedHolidayQuota = 2.0,
    this.restrictedHolidayUsed = 0.0,
    this.restrictedHolidayRemaining = 2.0,
    this.holidays = const [],
  });

  factory EmployeeHolidayCalendarModel.fromJson(Map<String, dynamic> json) {
    var rawHolidays = json['holidays'] as List? ?? [];
    return EmployeeHolidayCalendarModel(
      year: json['year'] ?? DateTime.now().year,
      restrictedHolidayQuota: (json['restrictedHolidayQuota'] ?? 2.0).toDouble(),
      restrictedHolidayUsed: (json['restrictedHolidayUsed'] ?? 0.0).toDouble(),
      restrictedHolidayRemaining: (json['restrictedHolidayRemaining'] ?? 2.0).toDouble(),
      holidays: rawHolidays.map((h) => HolidayModel.fromJson(h)).toList(),
    );
  }
}
