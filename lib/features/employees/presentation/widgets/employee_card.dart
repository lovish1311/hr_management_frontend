import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final Function(String newStatus)? onStatusChanged;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onTap,
    this.onEdit,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = t.isDarkTheme;

    // Status dot and theme accents
    Color statusColor = const Color(0xFF10B981); // Emerald
    String statusLabel = 'ACTIVE';
    IconData statusIcon = Icons.check_circle_rounded;

    if (employee.status == 'PROBATION' || employee.isProbation) {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusLabel = 'PROBATION';
      statusIcon = Icons.timer_outlined;
    } else if (employee.status == 'NOTICE_PERIOD' || employee.isNoticePeriod) {
      statusColor = const Color(0xFF8B5CF6); // Purple
      statusLabel = 'NOTICE';
      statusIcon = Icons.exit_to_app_rounded;
    } else if (employee.status == 'INACTIVE' || employee.status == 'TERMINATED') {
      statusColor = const Color(0xFF94A3B8); // Slate
      statusLabel = 'INACTIVE';
      statusIcon = Icons.block_rounded;
    } else if (employee.isAttendanceTracked) {
      switch (employee.todayAttendanceStatus.toUpperCase()) {
        case 'PRESENT':
          statusColor = const Color(0xFF10B981);
          statusLabel = 'PRESENT';
          statusIcon = Icons.check_circle_rounded;
          break;
        case 'LATE':
          statusColor = const Color(0xFFF59E0B);
          statusLabel = 'LATE';
          statusIcon = Icons.access_time_filled_rounded;
          break;
        case 'ON_LEAVE':
        case 'PAID_LEAVE':
          statusColor = const Color(0xFF6366F1);
          statusLabel = 'ON LEAVE';
          statusIcon = Icons.beach_access_rounded;
          break;
        case 'ABSENT':
          statusColor = const Color(0xFFEF4444);
          statusLabel = 'ABSENT';
          statusIcon = Icons.cancel_rounded;
          break;
      }
    }

    final isInactive = employee.status == 'INACTIVE' || employee.status == 'TERMINATED';

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: t.border.withValues(alpha: isDark ? 0.35 : 0.65),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          hoverColor: t.primary.withValues(alpha: 0.05),
          splashColor: t.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Avatar + Name/Role + Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with badge
                    Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://api.dicebear.com/7.x/adventurer/png?seed=',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                backgroundColor: t.primary.withValues(alpha: 0.15),
                                child: Text(
                                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: t.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: t.card,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Name + Code
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isInactive
                                  ? (isDark ? Colors.white38 : Colors.grey.shade400)
                                  : t.text,
                              decoration: isInactive ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.employeeCode.isNotEmpty
                                ? employee.employeeCode
                                : employee.designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action menu
                    if (onEdit != null || onStatusChanged != null)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: t.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          color: t.card,
                          onSelected: (action) {
                            if (action == 'view') {
                              onTap();
                            } else if (action == 'edit' && onEdit != null) {
                              onEdit!();
                            } else if (action == 'toggle_active' && onStatusChanged != null) {
                              final newStatus = isInactive ? 'ACTIVE' : 'INACTIVE';
                              onStatusChanged!(newStatus);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              height: 36,
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 16, color: t.primary),
                                  const SizedBox(width: 8),
                                  Text('View Profile', style: TextStyle(fontSize: 12.5, color: t.text)),
                                ],
                              ),
                            ),
                            if (onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                height: 36,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16, color: t.primary),
                                    const SizedBox(width: 8),
                                    Text('Edit Details', style: TextStyle(fontSize: 12.5, color: t.text)),
                                  ],
                                ),
                              ),
                            if (onStatusChanged != null)
                              PopupMenuItem(
                                value: 'toggle_active',
                                height: 36,
                                child: Row(
                                  children: [
                                    Icon(
                                      isInactive ? Icons.check_circle_outline : Icons.block_rounded,
                                      size: 16,
                                      color: isInactive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isInactive ? 'Reactivate' : 'Deactivate',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isInactive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Department & Designation tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.cardSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: t.border.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Text(
                        employee.department,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: t.text,
                        ),
                      ),
                    ),
                    if (employee.role.isNotEmpty && employee.role != employee.department)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: t.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          employee.role,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: t.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Divider line
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: t.border.withValues(alpha: 0.35),
                ),

                const SizedBox(height: 9),

                // Bottom row: Status badge + Contact info icon / email
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Email / Contact indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (employee.email.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.mail_outline_rounded,
                              size: 15,
                              color: t.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        if (employee.phone.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: t.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
