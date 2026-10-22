import 'package:hr_management/core/network/api_config.dart';

/// Top-level category for promotional banners and news
enum BannerCategory {
  announcement,
  celebration,
  birthday,
  officeEvent,
  festival,
  achievement,
  general;

  static BannerCategory fromString(String? value) {
    if (value == null) return BannerCategory.announcement;
    switch (value.trim().toUpperCase()) {
      case 'ANNOUNCEMENT':
        return BannerCategory.announcement;
      case 'CELEBRATION':
        return BannerCategory.celebration;
      case 'BIRTHDAY':
        return BannerCategory.birthday;
      case 'OFFICE_EVENT':
        return BannerCategory.officeEvent;
      case 'FESTIVAL':
        return BannerCategory.festival;
      case 'ACHIEVEMENT':
        return BannerCategory.achievement;
      default:
        return BannerCategory.general;
    }
  }

  String toServerString() {
    switch (this) {
      case BannerCategory.announcement:
        return 'ANNOUNCEMENT';
      case BannerCategory.celebration:
        return 'CELEBRATION';
      case BannerCategory.birthday:
        return 'BIRTHDAY';
      case BannerCategory.officeEvent:
        return 'OFFICE_EVENT';
      case BannerCategory.festival:
        return 'FESTIVAL';
      case BannerCategory.achievement:
        return 'ACHIEVEMENT';
      case BannerCategory.general:
        return 'GENERAL';
    }
  }
}

/// Primary discriminator: News vs Milestone Celebration
enum BannerType {
  news,
  celebration;

  static BannerType fromString(String? value) {
    if (value == null) return BannerType.news;
    return value.trim().toUpperCase() == 'CELEBRATION'
        ? BannerType.celebration
        : BannerType.news;
  }

  String toServerString() => this == BannerType.celebration ? 'CELEBRATION' : 'NEWS';
}

/// Subtype for celebration banners
enum CelebrationType {
  birthday,
  anniversary,
  general;

  static CelebrationType? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    switch (value.trim().toUpperCase()) {
      case 'BIRTHDAY':
        return CelebrationType.birthday;
      case 'ANNIVERSARY':
        return CelebrationType.anniversary;
      default:
        return CelebrationType.general;
    }
  }

  String toServerString() {
    switch (this) {
      case CelebrationType.birthday:
        return 'BIRTHDAY';
      case CelebrationType.anniversary:
        return 'ANNIVERSARY';
      case CelebrationType.general:
        return 'GENERAL';
    }
  }

  String get displayName {
    switch (this) {
      case CelebrationType.birthday:
        return 'Birthday 🎂';
      case CelebrationType.anniversary:
        return 'Work Anniversary 🎖️';
      case CelebrationType.general:
        return 'Milestone Celebration 🎉';
    }
  }
}

/// Summary returned after reacting to a banner
class BannerReactionSummary {
  final int bannerId;
  final Map<String, int> reactionCounts;
  final Set<String> userReactions;
  final int totalReactions;

  BannerReactionSummary({
    required this.bannerId,
    required this.reactionCounts,
    required this.userReactions,
    required this.totalReactions,
  });

  factory BannerReactionSummary.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['reactionCounts'] as Map<String, dynamic>? ?? {};
    final counts = countsRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    final userReactionsList = json['userReactions'] as List<dynamic>? ?? [];
    final userReactions = userReactionsList.map((e) => e.toString()).toSet();

    final total = (json['totalReactions'] as num?)?.toInt() ?? 0;
    final bId = (json['bannerId'] as num?)?.toInt() ?? 0;

    return BannerReactionSummary(
      bannerId: bId,
      reactionCounts: counts,
      userReactions: userReactions,
      totalReactions: total,
    );
  }
}

/// Core domain model representing a banner or Engage feed post
class BannerModel {
  final int id;
  final String title;
  final String? subtitle;
  final BannerCategory category;
  final BannerType bannerType;
  final CelebrationType? celebrationType;
  final int? targetEmployeeId;
  final String? targetEmployeeName;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionButtonText;
  final String? backgroundGradient;
  final String? targetDepartment;
  final DateTime startDate;
  final DateTime expiryDate;
  final int displayOrder;
  final bool isActive;
  final int? createdById;
  final String? createdByEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;
  final bool isCurrentlyActive;
  final bool isExpired;
  final bool isScheduled;
  final Map<String, int> reactionCounts;
  final Set<String> userReactions;
  final int totalReactions;

  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.category,
    required this.bannerType,
    this.celebrationType,
    this.targetEmployeeId,
    this.targetEmployeeName,
    this.imageUrl,
    this.actionUrl,
    this.actionButtonText,
    this.backgroundGradient,
    this.targetDepartment,
    required this.startDate,
    required this.expiryDate,
    required this.displayOrder,
    required this.isActive,
    this.createdById,
    this.createdByEmail,
    this.createdAt,
    this.updatedAt,
    required this.version,
    required this.isCurrentlyActive,
    required this.isExpired,
    required this.isScheduled,
    required this.reactionCounts,
    required this.userReactions,
    required this.totalReactions,
  });

  /// Canonical URL resolver ensuring both external URLs and relative server paths resolve properly
  String? get resolvedImageUrl {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return null;
    final trimmed = imageUrl!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  bool get isCelebration => bannerType == BannerType.celebration;
  bool get isBirthday => celebrationType == CelebrationType.birthday;
  bool get isAnniversary => celebrationType == CelebrationType.anniversary;
  bool get isNews => bannerType == BannerType.news;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['reactionCounts'] as Map<String, dynamic>? ?? {};
    final counts = countsRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    final userReactionsList = json['userReactions'] as List<dynamic>? ?? [];
    final userReactions = userReactionsList.map((e) => e.toString()).toSet();

    return BannerModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      category: BannerCategory.fromString(json['category']?.toString()),
      bannerType: BannerType.fromString(json['bannerType']?.toString()),
      celebrationType: CelebrationType.fromString(json['celebrationType']?.toString()),
      targetEmployeeId: (json['targetEmployeeId'] as num?)?.toInt(),
      targetEmployeeName: json['targetEmployeeName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      actionUrl: json['actionUrl']?.toString(),
      actionButtonText: json['actionButtonText']?.toString(),
      backgroundGradient: json['backgroundGradient']?.toString(),
      targetDepartment: json['targetDepartment']?.toString(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'].toString())
          : DateTime.now().plusHours(24),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdById: (json['createdById'] as num?)?.toInt(),
      createdByEmail: json['createdByEmail']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      version: (json['version'] as num?)?.toInt() ?? 0,
      isCurrentlyActive: json['isCurrentlyActive'] as bool? ?? true,
      isExpired: json['isExpired'] as bool? ?? false,
      isScheduled: json['isScheduled'] as bool? ?? false,
      reactionCounts: counts,
      userReactions: userReactions,
      totalReactions: (json['totalReactions'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category.toServerString(),
      'bannerType': bannerType.toServerString(),
      'celebrationType': celebrationType?.toServerString(),
      'targetEmployeeId': targetEmployeeId,
      'targetEmployeeName': targetEmployeeName,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionButtonText': actionButtonText,
      'backgroundGradient': backgroundGradient,
      'targetDepartment': targetDepartment,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'displayOrder': displayOrder,
      'isActive': isActive,
      'version': version,
      'reactionCounts': reactionCounts,
      'userReactions': userReactions.toList(),
      'totalReactions': totalReactions,
    };
  }

  BannerModel copyWith({
    int? id,
    String? title,
    String? subtitle,
    BannerCategory? category,
    BannerType? bannerType,
    CelebrationType? celebrationType,
    int? targetEmployeeId,
    String? targetEmployeeName,
    String? imageUrl,
    String? actionUrl,
    String? actionButtonText,
    String? backgroundGradient,
    String? targetDepartment,
    DateTime? startDate,
    DateTime? expiryDate,
    int? displayOrder,
    bool? isActive,
    int? createdById,
    String? createdByEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isCurrentlyActive,
    bool? isExpired,
    bool? isScheduled,
    Map<String, int>? reactionCounts,
    Set<String>? userReactions,
    int? totalReactions,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      bannerType: bannerType ?? this.bannerType,
      celebrationType: celebrationType ?? this.celebrationType,
      targetEmployeeId: targetEmployeeId ?? this.targetEmployeeId,
      targetEmployeeName: targetEmployeeName ?? this.targetEmployeeName,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionButtonText: actionButtonText ?? this.actionButtonText,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdById: createdById ?? this.createdById,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isCurrentlyActive: isCurrentlyActive ?? this.isCurrentlyActive,
      isExpired: isExpired ?? this.isExpired,
      isScheduled: isScheduled ?? this.isScheduled,
      reactionCounts: reactionCounts ?? Map<String, int>.from(this.reactionCounts),
      userReactions: userReactions ?? Set<String>.from(this.userReactions),
      totalReactions: totalReactions ?? this.totalReactions,
    );
  }
}

extension _DateTimeHelpers on DateTime {
  DateTime plusHours(int hours) => add(Duration(hours: hours));
}
