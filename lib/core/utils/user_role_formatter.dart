/// Utility to humanize system role names and granular authorities into
/// user-friendly, clean titles across the UI (e.g., "ROLE_ADMIN" -> "Administrator").
class UserRoleFormatter {
  /// Converts raw role identifiers into human-readable titles.
  static String formatRole(String? role) {
    if (role == null || role.trim().isEmpty) return 'Employee';
    final normalized = role.trim().toUpperCase().replaceAll('ROLE_', '');
    switch (normalized) {
      case 'SUPER_ADMIN':
        return 'Super Administrator';
      case 'ADMIN':
        return 'Administrator';
      case 'HR':
        return 'HR Manager';
      case 'MANAGER':
        return 'Team Manager';
      case 'EMPLOYEE':
        return 'Employee';
      default:
        // Capitalize words cleanly
        return normalized
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  /// Converts granular system permissions into clean, descriptive feature titles.
  static String formatAuthority(String? authority) {
    if (authority == null || authority.trim().isEmpty) return '';
    final normalized = authority.trim().toUpperCase();
    switch (normalized) {
      case 'BANNER_MANAGE':
        return 'Banner Management';
      case 'GAME_MANAGE':
        return 'Game Room & Access Management';
      case 'PAYROLL_MANAGE':
        return 'Payroll Management';
      case 'SALARY_STRUCTURE_MANAGE':
        return 'Salary Structure Management';
      case 'LEAVE_APPROVE_ALL':
        return 'Global Leave Approval';
      default:
        return normalized
            .replaceAll('ROLE_', '')
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  /// Detailed subtitle description for permission switches in elevate role dialog.
  static String getAuthorityDescription(String? authority) {
    if (authority == null) return '';
    final normalized = authority.trim().toUpperCase();
    switch (normalized) {
      case 'BANNER_MANAGE':
        return 'Allows creating, editing, and publishing news announcements and celebration banners.';
      case 'GAME_MANAGE':
        return 'Grants host privileges to launch Tambola, Draw & Guess, and arcade sessions.';
      case 'PAYROLL_MANAGE':
        return 'Allows calculating monthly payroll, processing LOP, and issuing payslips.';
      case 'SALARY_STRUCTURE_MANAGE':
        return 'Allows configuring CTC breakdown, allowances, and compensation slabs.';
      case 'LEAVE_APPROVE_ALL':
        return 'Grants bypass approval rights for company-wide leave requests.';
      default:
        return 'Grants access to manage and configure $normalized operations.';
    }
  }
}
