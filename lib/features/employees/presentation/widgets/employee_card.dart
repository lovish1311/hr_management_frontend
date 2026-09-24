import 'package:flutter/material.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final avatarRadius = isCompact ? 26.0 : 32.0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8.0 : 12.0,
              vertical: isCompact ? 10.0 : 14.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with Status Indicator Dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      backgroundImage: NetworkImage(
                        'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(employee.name)}',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  employee.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 13 : 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),

                // Role & Department
                Text(
                  '${employee.role} • ${employee.department}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),

                // Live Today Attendance Status Badge
                _buildTodayStatusBadge(
                  employee.isAttendanceTracked ? employee.todayAttendanceStatus : 'EXEMPT',
                  isCompact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayStatusBadge(String status, bool isCompact) {
    Color bg;
    Color text;
    String label;
    IconData icon = Icons.circle;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        text = const Color(0xFF10B981);
        label = 'PRESENT';
        break;
      case 'LATE':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        text = const Color(0xFFD97706);
        label = 'LATE';
        break;
      case 'ON_LEAVE':
      case 'PAID_LEAVE':
        bg = const Color(0xFF6366F1).withValues(alpha: 0.15);
        text = const Color(0xFF6366F1);
        label = 'ON LEAVE';
        break;
      case 'EXEMPT':
      case 'UNTRACKED':
        bg = Colors.amber.withValues(alpha: 0.15);
        text = const Color(0xFFD97706);
        label = 'EXEMPT';
        icon = Icons.do_not_disturb_on_rounded;
        break;
      case 'ABSENT':
      default:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        text = const Color(0xFFEF4444);
        label = 'ABSENT';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6.0 : 8.0,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 6 : 7, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 8.5 : 9.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
