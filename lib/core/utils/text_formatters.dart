import 'package:hr_management/core/services/auth_storage.dart';

/// Production-grade text and enum formatting utilities with memoized caching.
/// Eliminates ugly technical database enums (e.g. `ROLE_SUPER_ADMIN`, `WORK_FROM_HOME`)
/// and replaces them with polished, user-facing title-case strings.
class TextFormatter {
  TextFormatter._();

  // In-memory memoization cache for $O(1)$ fast lookups across 1000+ item lists.
  static final Map<String, String> _enumCache = {};
  static final Map<String, String> _roleCache = {};

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Formats technical IAM / system roles into professional human labels.
  /// Example:
  /// - `ROLE_SUPER_ADMIN` -> "Super Admin"
  /// - `SUPER_ADMIN` -> "Super Admin"
  /// - `ROLE_HR_ADMIN` / `HR` -> "HR Admin"
  /// - `ROLE_MANAGER` / `MANAGER` -> "Manager"
  /// - `ROLE_EMPLOYEE` / `EMPLOYEE` -> "Employee"
  static String formatRole(String? role) {
    if (role == null || role.trim().isEmpty) return 'Employee';
    final raw = role.trim();
    if (_roleCache.containsKey(raw)) return _roleCache[raw]!;

    final normalized = raw.toUpperCase().replaceAll('ROLE_', '');
    String result;
    switch (normalized) {
      case 'SUPER_ADMIN':
        result = 'Super Admin';
        break;
      case 'HR_ADMIN':
      case 'HR':
        result = 'HR Admin';
        break;
      case 'MANAGER':
        result = 'Manager';
        break;
      case 'EMPLOYEE':
        result = 'Employee';
        break;
      default:
        // Handles custom job titles like "Senior UX Designer" or "Power BI Developer"
        result = formatEnum(normalized);
        break;
    }

    _roleCache[raw] = result;
    return result;
  }

  /// Formats uppercase attendance, leave, or employee status enums into clean Title Case.
  /// Example:
  /// - `ON_LEAVE` -> "On Leave"
  /// - `PAID_LEAVE` -> "Paid Leave"
  /// - `WORK_FROM_HOME` / `WFH` -> "Work From Home"
  /// - `IN_OFFICE` -> "In Office"
  /// - `PENDING_APPROVAL` -> "Pending Approval"
  /// - `PENDING_ACTIVATION` -> "Pending Activation"
  static String formatStatus(String? status) {
    if (status == null || status.trim().isEmpty) return '-';
    final raw = status.trim();
    final normalized = raw.toUpperCase();

    if (normalized == 'WFH') return 'Work From Home';
    if (normalized == 'LOP') return 'Loss of Pay';

    return formatEnum(raw);
  }

  /// Formats leave policy types into professional labels.
  /// Example:
  /// - `CASUAL_LEAVE` -> "Casual Leave"
  /// - `SICK_LEAVE` -> "Sick Leave"
  /// - `EARNED_LEAVE` -> "Earned Leave"
  /// - `COMP_OFF` -> "Compensatory Off"
  /// - `LOSS_OF_PAY` -> "Loss of Pay"
  static String formatLeaveType(String? leaveType) {
    if (leaveType == null || leaveType.trim().isEmpty) return 'Leave';
    final normalized = leaveType.trim().toUpperCase();

    switch (normalized) {
      case 'COMP_OFF':
        return 'Compensatory Off';
      case 'LOSS_OF_PAY':
      case 'LOP':
        return 'Loss of Pay';
      case 'RESTRICTED_HOLIDAY':
        return 'Restricted Holiday';
      case 'GENERAL_HOLIDAY':
        return 'General Holiday';
      default:
        return formatEnum(leaveType);
    }
  }

  /// Formats any generic SCREAMING_SNAKE_CASE string into Clean Title Case.
  /// Memoized for instant $O(1)$ performance across lists and tables.
  static String formatEnum(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final raw = text.trim();
    if (_enumCache.containsKey(raw)) return _enumCache[raw]!;

    final words = raw
        .replaceAll('ROLE_', '')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty);

    final formatted = words.map((w) {
      if (w.length == 1) return w.toUpperCase();
      // Handle standard industry abbreviations
      final upper = w.toUpperCase();
      const abbreviations = {'HR', 'UI', 'UX', 'ID', 'IT', 'BI', 'QA', 'AI', 'ML', 'CEO', 'CTO', 'CFO', 'VP'};
      if (abbreviations.contains(upper)) {
        return upper;
      }
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    _enumCache[raw] = formatted;
    return formatted;
  }

  /// Generates a dynamic greeting based on current time of day and authenticated user name.
  /// Example:
  /// - 09:00: "Good Morning, Lovish 👋"
  /// - 14:00: "Good Afternoon, Lovish 👋"
  /// - 19:00: "Good Evening, Lovish 👋"
  static String formatGreeting([String? name]) {
    final hour = DateTime.now().hour;
    final timeSalutation = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final effectiveName = (name ?? AuthStorage.userName)?.trim();
    if (effectiveName == null || effectiveName.isEmpty || effectiveName == 'User') {
      return '$timeSalutation 👋';
    }

    // Extract first name if full name provided for warm personalized greeting
    final firstName = effectiveName.split(' ').first;
    return '$timeSalutation, $firstName 👋';
  }

  /// Formats date dynamically without needing heavy external dependencies.
  /// Default output: "Wednesday, Oct 21" (matches modern dashboard style).
  static String formatDate(
    DateTime date, {
    bool includeWeekday = true,
    bool shortMonth = true,
    bool includeYear = false,
  }) {
    final weekday = _weekdays[date.weekday - 1];
    final month = shortMonth ? _monthsShort[date.month - 1] : _monthsFull[date.month - 1];
    final day = date.day;

    final base = '$month $day';
    final withYear = includeYear ? '$base, ${date.year}' : base;
    return includeWeekday ? '$weekday, $withYear' : withYear;
  }

  /// Returns localized current weekday name (e.g. "Monday", "Tuesday").
  static String currentWeekday([DateTime? date]) {
    final d = date ?? DateTime.now();
    return _weekdays[d.weekday - 1];
  }
}
