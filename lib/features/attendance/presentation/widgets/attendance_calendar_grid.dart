import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/attendance/domain/entities/attendance_calendar_day.dart';

class AttendanceCalendarGrid extends StatelessWidget {
  final DateTime activeMonth;
  final List<AttendanceCalendarDay> days;
  final Function(AttendanceCalendarDay day) onDayTap;
  final Function(AttendanceCalendarDay day) onApplyLeaveForDate;
  final Function(AttendanceCalendarDay day) onSetReminderForDate;
  final bool showReminderOption;

  const AttendanceCalendarGrid({
    super.key,
    required this.activeMonth,
    required this.days,
    required this.onDayTap,
    required this.onApplyLeaveForDate,
    required this.onSetReminderForDate,
    this.showReminderOption = true,
  });

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return const Color(0xFF10B981); // Emerald Green
      case 'LATE':
        return const Color(0xFFF59E0B); // Warm Amber
      case 'PAID_LEAVE':
        return const Color(0xFF6366F1); // Royal Indigo
      case 'PENDING_LEAVE':
        return const Color(0xFFFF9800); // Orange
      case 'LOP_LEAVE':
      case 'UNEXCUSED_ABSENT':
        return const Color(0xFFEF4444); // Crimson Rose
      case 'HOLIDAY':
        return const Color(0xFF06B6D4); // Cyan Blue
      case 'WEEKEND':
        return isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1); // Muted Slate
      default:
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    }
  }

  void _showContextMenu(BuildContext context, AttendanceCalendarDay day, Offset tapPosition) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = AuthStorage.isHr;
    final isPendingLeave = day.status == 'PENDING_LEAVE' && day.leaveRequestId != null;
    
    // For Web right-click popup menu
    if (kIsWeb) {
      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      showMenu(
        context: context,
        position: RelativeRect.fromRect(
          tapPosition & const Size(40, 40),
          Offset.zero & overlay.size,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: [
          if (isAdmin && isPendingLeave)
            PopupMenuItem(
              onTap: () => Future.microtask(() => onDayTap(day)),
              child: const Row(
                children: [
                  Icon(Icons.rate_review_rounded, color: Color(0xFFFF9800), size: 18),
                  SizedBox(width: 10),
                  Text('Review Leave Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF9800))),
                ],
              ),
            ),
          PopupMenuItem(
              onTap: () => Future.microtask(() => onApplyLeaveForDate(day)),
              child: const Row(
                children: [
                  Icon(Icons.edit_calendar_rounded, color: Color(0xFF6366F1), size: 18),
                  SizedBox(width: 10),
                  Text('Request Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
                ],
              ),
            ),
          if (!isAdmin && isPendingLeave)
            PopupMenuItem(
              onTap: () => Future.microtask(() => onDayTap(day)),
              child: const Row(
                children: [
                  Icon(Icons.visibility_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 10),
                  Text('Review / Withdraw Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF59E0B))),
                ],
              ),
            ),
          if (showReminderOption)
            PopupMenuItem(
              onTap: () => Future.microtask(() => onSetReminderForDate(day)),
              child: const Row(
                children: [
                  Icon(Icons.alarm_add_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 10),
                  Text('Set Attendance Reminder', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          PopupMenuItem(
            onTap: () => Future.microtask(() => onDayTap(day)),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF06B6D4), size: 18),
                SizedBox(width: 10),
                Text('View Day Log & Details', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      );
      return;
    }

    // For Mobile Long-Press Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.85;
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actions for ${_formatDate(day.date)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${day.statusLabel}',
                    style: TextStyle(fontSize: 12, color: _getStatusColor(day.status, isDark)),
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin && isPendingLeave)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: Color(0xFFFF9800), size: 20),
                      ),
                      title: const Text('Review Leave Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF9800))),
                      subtitle: const Text('Approve or reject this pending leave', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(context);
                        onDayTap(day);
                      },
                    ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF6366F1), size: 20),
                    ),
                    title: const Text('Request Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6366F1))),
                    subtitle: const Text('Apply leave, short break, early out, or late arrival', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      onApplyLeaveForDate(day);
                    },
                  ),
                  if (!isAdmin && isPendingLeave)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.visibility_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      title: const Text('Review / Withdraw Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF59E0B))),
                      subtitle: const Text('View pending request details or withdraw', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(context);
                        onDayTap(day);
                      },
                    ),
                  if (showReminderOption)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.alarm_add_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      title: const Text('Set Attendance Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Get notified before check-in cutoff', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(context);
                        onSetReminderForDate(day);
                      },
                    ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF06B6D4), size: 20),
                    ),
                    title: const Text('View Day Log & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF06B6D4))),
                    subtitle: const Text('Check check-in/out timestamps and notes', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      onDayTap(day);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDayOfMonth = DateTime(activeMonth.year, activeMonth.month, 1);
    final daysInMonth = DateTime(activeMonth.year, activeMonth.month + 1, 0).day;
    final leadingPaddingDays = firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1 ...

    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Weekday Headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              final isWeekendHeader = day == 'Sun' || day == 'Sat';
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isWeekendHeader
                        ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Grid Cells with fixed mainAxisExtent for compact height across all screen sizes
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: MediaQuery.of(context).size.width < 450 ? 52 : 64,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: leadingPaddingDays + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingPaddingDays) {
              return const SizedBox.shrink(); // Empty space before 1st day of month
            }

            final dayNumber = index - leadingPaddingDays + 1;
            final targetDate = DateTime(activeMonth.year, activeMonth.month, dayNumber);
            
            final dayData = days.firstWhere(
              (d) => d.date.year == targetDate.year && d.date.month == targetDate.month && d.date.day == targetDate.day,
              orElse: () => AttendanceCalendarDay(
                date: targetDate,
                status: targetDate.weekday == DateTime.saturday || targetDate.weekday == DateTime.sunday ? 'WEEKEND' : 'UPCOMING',
                statusLabel: '',
                isWeekend: targetDate.weekday == DateTime.saturday || targetDate.weekday == DateTime.sunday,
              ),
            );

            final statusColor = _getStatusColor(dayData.status, isDark);
            final isToday = DateTime.now().year == targetDate.year &&
                DateTime.now().month == targetDate.month &&
                DateTime.now().day == targetDate.day;

            Offset tapPos = Offset.zero;

            return GestureDetector(
              onTapDown: (details) {
                tapPos = details.globalPosition;
              },
              onTap: () {
                _showContextMenu(context, dayData, tapPos);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: dayData.status == 'UPCOMING'
                      ? LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: dayData.status == 'UPCOMING'
                      ? null
                      : (dayData.status == 'WEEKEND'
                          ? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF1F5F9))
                          : statusColor.withValues(alpha: isDark ? 0.2 : 0.12)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFF3B82F6)
                        : (dayData.status == 'UPCOMING'
                            ? (isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0))
                            : (dayData.status == 'WEEKEND'
                                ? Colors.transparent
                                : statusColor.withValues(alpha: 0.35))),
                    width: isToday ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Day Number & Today Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday || dayData.status != 'UPCOMING' ? FontWeight.w800 : FontWeight.w600,
                            color: dayData.status == 'WEEKEND'
                                ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),

                    // Bottom Row: Status Micro Pill / Dot
                    if (dayData.status != 'WEEKEND' && dayData.status != 'UPCOMING')
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _getMicroStatusLabel(dayData.status, dayData.leaveType),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMicroStatusLabel(String status, String? leaveType) {
    final normType = leaveType != null ? leaveType.toUpperCase().replaceAll(RegExp(r'[ _-]'), '') : '';
    switch (status.toUpperCase()) {
      case 'PRESENT':
        if (normType.contains('SHORTBREAK') || normType.contains('SHORTLEAVE')) {
          return 'Break (Present)';
        } else if (normType.contains('EARLYOUT') || normType.contains('EARLYLEAVE')) {
          return 'Early Out (Present)';
        }
        return 'Present';
      case 'LATE':
        return 'Late';
      case 'PAID_LEAVE':
        return 'On Leave';
      case 'PENDING_LEAVE':
        return 'Pending';
      case 'LOP_LEAVE':
      case 'UNEXCUSED_ABSENT':
        return 'LOP';
      case 'HOLIDAY':
        return 'Holiday';
      default:
        return '';
    }
  }
}
