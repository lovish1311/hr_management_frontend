import re
with open('lib/features/attendance/presentation/pages/attendance_calendar_page.dart', 'r') as f:
    content = f.read()

# Add final t = context.appTheme; final isDark = Theme.of(context).brightness == Brightness.dark; 
# to the start of specific methods
methods_to_patch = [
    r'(Future<void> _reviewLeaveRequest\(String requestId, String status, String note\) async \{)(.*?)',
    r'(void _showReviewLeaveDialog\(AttendanceCalendarDay day\) \{)(.*?)',
    r'(void _showImportBiometricDialog\(\) \{)(.*?)',
    r'(Widget _buildEmployeeSelector\(AppThemeConfig t\) \{)(.*?)',
    r'(Widget _buildApplyOptionTile\(\{required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap\}\) \{)(.*?)',
    r'(Widget _buildDetailRow\(String label, String value, AppThemeConfig t\) \{)(.*?)',
    r'(Widget _buildKpiCard\(String label, String value, Color color, IconData icon, AppThemeConfig t\) \{)(.*?)',
    r'(Widget _buildLegendItem\(String label, Color color, AppThemeConfig t\) \{)(.*?)'
]

for pattern in methods_to_patch:
    content = re.sub(pattern, r'\1\n    final t = context.appTheme;\n    final isDark = Theme.of(context).brightness == Brightness.dark;\2', content, count=1, flags=re.DOTALL)

# Fix constant errors where 'const SnackBar' has a dynamic color
content = content.replace('const SnackBar(', 'SnackBar(')

# Fix some remaining builder contexts where t is used
content = re.sub(r'(builder: \(context\) \{)', r'\1\n        final t = context.appTheme;', content)

# Fix build method if it needs isDark restored
content = re.sub(r'(Widget build\(BuildContext context\) \{)', r'\1\n    final isDark = Theme.of(context).brightness == Brightness.dark;', content)

with open('lib/features/attendance/presentation/pages/attendance_calendar_page.dart', 'w') as f:
    f.write(content)
