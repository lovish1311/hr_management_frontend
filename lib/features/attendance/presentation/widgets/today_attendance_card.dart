import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/features/attendance/domain/entities/attendance_calendar_day.dart';
import 'package:hr_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_management/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hr_management/core/widgets/app_toast.dart';

class TodayAttendanceCard extends StatefulWidget {
  final AttendanceCalendarDay? todayAttendance;
  final VoidCallback onPunchCompleted;
  final bool isSelf;

  const TodayAttendanceCard({
    super.key,
    required this.todayAttendance,
    required this.onPunchCompleted,
    this.isSelf = true,
  });

  @override
  State<TodayAttendanceCard> createState() => _TodayAttendanceCardState();
}

class _TodayAttendanceCardState extends State<TodayAttendanceCard> {
  final AttendanceRepository _repository = AttendanceRepositoryImpl();
  bool _isPunching = false;
  late Timer _tickerTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer.cancel();
    super.dispose();
  }

  String _formatLiveTime(DateTime dt) {
    int hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    return '${displayHour.toString().padLeft(2, '0')}:$min:$sec $period';
  }

  String _formatTodayDate(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _handleCheckIn() async {
    if (_isPunching) return;
    setState(() => _isPunching = true);

    try {
      final res = await _repository.checkIn();
      if (!mounted) return;
      AppToast.success(context, 'Clocked in successfully at ${res['checkInTime'] ?? 'now'}.');
      widget.onPunchCompleted();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _isPunching = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_isPunching) return;
    setState(() => _isPunching = true);

    try {
      final res = await _repository.checkOut();
      if (!mounted) return;
      AppToast.success(context, 'Clocked out successfully. Total: ${res['totalWorkingMinutes'] ?? 0} mins.');
      widget.onPunchCompleted();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _isPunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final today = widget.todayAttendance;
    final hasCheckedIn = today?.checkInTime != null && today!.checkInTime!.isNotEmpty;
    final hasCheckedOut = today?.checkOutTime != null && today!.checkOutTime!.isNotEmpty;
    final isWeekend = today?.isWeekend == true;
    final isHoliday = today?.isHoliday == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasCheckedIn
              ? (hasCheckedOut ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFF6366F1).withValues(alpha: 0.4))
              : t.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 768;

          Widget headerSection = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasCheckedIn
                      ? (hasCheckedOut ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF6366F1).withValues(alpha: 0.15))
                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasCheckedOut
                      ? Icons.task_alt_rounded
                      : (hasCheckedIn ? Icons.login_rounded : Icons.schedule_rounded),
                  color: hasCheckedOut
                      ? const Color(0xFF10B981)
                      : (hasCheckedIn ? const Color(0xFF6366F1) : const Color(0xFFF59E0B)),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatTodayDate(_currentTime),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textSecondary),
                        ),
                        if (isWeekend)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Weekend', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                          )
                        else if (isHoliday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Holiday', style: TextStyle(fontSize: 11, color: Colors.cyan, fontWeight: FontWeight.bold)),
                          )
                        else if (hasCheckedIn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (today.status == 'LATE' ? Colors.amber : const Color(0xFF10B981)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              today.statusLabel.isNotEmpty ? today.statusLabel : today.status,
                              style: TextStyle(
                                fontSize: 11,
                                color: today.status == 'LATE' ? Colors.amber[800] : const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatLiveTime(_currentTime),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.text, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shift: 10:00 AM – 07:00 PM (15m Grace)',
                      style: TextStyle(fontSize: 11.5, color: t.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          );

          Widget punchActionSection;
          if (!widget.isSelf) {
            punchActionSection = const SizedBox.shrink();
          } else if (hasCheckedOut) {
            punchActionSection = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Punched Out at ${today.checkOutTime ?? ''} (${today.totalWorkingMinutes ~/ 60}h ${today.totalWorkingMinutes % 60}m worked)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          } else if (hasCheckedIn) {
            punchActionSection = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In at ${today.checkInTime ?? ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.text)),
                    Text('Working...', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                  ],
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: _isPunching ? null : _handleCheckOut,
                  icon: _isPunching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Punch Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            );
          } else {
            punchActionSection = ElevatedButton.icon(
              onPressed: _isPunching ? null : _handleCheckIn,
              icon: _isPunching
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.fingerprint_rounded, size: 20),
              label: const Text('Check In Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
            );
          }

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerSection,
                if (widget.isSelf) ...[
                  const SizedBox(height: 16),
                  punchActionSection,
                ],
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: headerSection),
                punchActionSection,
              ],
            );
          }
        },
      ),
    );
  }
}
