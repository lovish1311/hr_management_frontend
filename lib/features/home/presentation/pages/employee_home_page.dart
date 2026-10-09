import 'package:hr_management/core/network/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/services/auth_storage.dart';

import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/core/utils/file_downloader.dart';
import 'package:hr_management/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/payroll_record_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hr_management/features/payroll/presentation/utils/payslip_pdf_generator.dart';
import 'package:hr_management/features/holidays/data/services/holiday_service.dart';
import 'package:hr_management/features/holidays/data/models/holiday_model.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  bool _showSalary = false; // Salary hidden by default
  int _exceptionDaysCount = 0;
  bool _isLoadingAttendance = true;
  List<HolidayModel> _upcomingHolidays = [];
  bool _isHolidayCalendarPublished = false;
  bool _isLoadingHolidays = true;
  List<dynamic> _teamPendingApprovals = [];
  bool _isLoadingTeamApprovals = true;

  final PayrollRepository _payrollRepo = PayrollRepositoryImpl();
  PayrollRecordEntity? _latestPayslip;
  bool _isLoadingPayslip = true;
  bool _isDownloadingDashboardPayslip = false;

  String get _baseUrl => ApiConfig.baseUrl;

  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');
  static String _formatDayName(DateTime dt) => _days[dt.weekday - 1];
  static String _formatFullDate(DateTime dt) =>
      '${_formatTwoDigits(dt.day)} ${_months[dt.month - 1]} ${dt.year}';

  @override
  void initState() {
    super.initState();
    AuthStorage.permissionRevision.addListener(_onPermissionsChanged);
    _fetchEmployeeAttendanceData();
    _fetchUpcomingHolidays();
    _fetchTeamApprovals();
    _fetchLatestPayslip();
  }

  void _onPermissionsChanged() {
    if (mounted) {
      setState(() {});
      _fetchTeamApprovals();
      _fetchLatestPayslip();
    }
  }

  Future<void> _fetchLatestPayslip() async {
    final empId = AuthStorage.employeeId ?? 1;
    final isPrivileged = AuthStorage.isSuperAdmin || AuthStorage.isHr;
    try {
      final list = await _payrollRepo.getPayslips(
        employeeId: empId,
        onlyPublished: !isPrivileged,
      );
      if (mounted) {
        setState(() {
          _latestPayslip = list.isNotEmpty ? list.first : null;
          _isLoadingPayslip = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPayslip = false);
      }
    }
  }

  Future<void> _downloadDashboardPayslip(PayrollRecordEntity record) async {
    if (_isDownloadingDashboardPayslip) return;
    setState(() => _isDownloadingDashboardPayslip = true);

    try {
      final pdfBytes = await PayslipPdfGenerator.generatePayslipPdf(record);
      final empCode = record.employeeCode.isNotEmpty ? record.employeeCode : 'EMP${record.employeeId}';
      final fileName = 'Payslip_${empCode}_${record.payrollMonth}_${record.payrollYear}.pdf';

      FileDownloader.downloadBytes(
        bytes: pdfBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Payslip downloaded: $fileName')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download payslip: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingDashboardPayslip = false);
    }
  }

  Future<void> _fetchTeamApprovals() async {
    final empId = AuthStorage.employeeId?.toString() ?? '1';
    final token = AuthStorage.token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final endpoint = AuthStorage.isHr
        ? '$_baseUrl/api/v1/leaves/pending/all'
        : '$_baseUrl/api/v1/leaves/pending/manager/$empId';

    try {
      final res = await http.get(Uri.parse(endpoint), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _teamPendingApprovals = data;
            _isLoadingTeamApprovals = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingTeamApprovals = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeamApprovals = false);
    }
  }

  Future<void> _updateLeaveStatus(int id, String status, {String? rejectionReason}) async {
    final empId = AuthStorage.employeeId ?? 1;
    final token = AuthStorage.token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final body = json.encode({
      'status': status,
      'rejectionReason': rejectionReason ?? '',
      'approverId': empId.toString(),
    });

    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/v1/leaves/$id/status'),
        headers: headers,
        body: body,
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'APPROVED' ? 'Request Approved Successfully!' : 'Request Rejected.'),
              backgroundColor: status == 'APPROVED' ? const Color(0xFF10B981) : Colors.red,
            ),
          );
          _fetchTeamApprovals();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update request status.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    AuthStorage.permissionRevision.removeListener(_onPermissionsChanged);
    super.dispose();
  }

  Future<void> _fetchEmployeeAttendanceData() async {
    final empId = AuthStorage.employeeId?.toString() ?? '1';
    final now = DateTime.now();
    try {
      final days = await AttendanceRepositoryImpl().getMonthlyCalendarSummary(
        employeeId: empId,
        year: now.year,
        month: now.month,
      );

      final absentDays = days.where((d) {
        final isPastOrToday = d.date.isBefore(now.add(const Duration(days: 1)));
        return isPastOrToday && (d.status == 'ABSENT' || d.status == 'LOP_LEAVE');
      }).toList();


      if (mounted) {
        setState(() {
          _exceptionDaysCount = absentDays.length;
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

  Future<void> _fetchUpcomingHolidays() async {
    final now = DateTime.now();
    try {
      final calendar = await HolidayService.getEmployeeHolidayCalendar(now.year);
      if (mounted) {
        final allHolidays = calendar.holidays;
        final isPublished = allHolidays.isNotEmpty;

        final todayMidnight = DateTime(now.year, now.month, now.day);
        final upcoming = allHolidays.where((h) {
          final hMidnight = DateTime(h.date.year, h.date.month, h.date.day);
          return !hMidnight.isBefore(todayMidnight);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        setState(() {
          _isHolidayCalendarPublished = isPublished;
          _upcomingHolidays = upcoming;
          _isLoadingHolidays = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching holiday calendar on dashboard: $e');
      if (mounted) {
        setState(() {
          _isHolidayCalendarPublished = false;
          _upcomingHolidays = [];
          _isLoadingHolidays = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userEmail = AuthStorage.userEmail ?? 'Employee';
    final namePart = userEmail.split('@').first;
    final formattedName = namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Employee';
    final initials = formattedName.length >= 2
        ? formattedName.substring(0, 2).toUpperCase()
        : 'EM';

    final t = context.appTheme;

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.spa_rounded, color: Color(0xFF0D9488), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'TeamJoy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: t.cardSoft,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: t.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850), // Responsive Max Width for Desktop Web
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting header
                  Text(
                    'Good ${_getGreeting()}, $formattedName! 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: t.onBackgroundText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Have a productive and joyful day at work',
                    style: TextStyle(
                      fontSize: 13,
                      color: t.onBackgroundTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),


                  // Sun Clock Shift Card (Isolated RepaintBoundary with internal ticker)
                  const RepaintBoundary(
                    child: _SunClockShiftCard(),
                  ),

                  const SizedBox(height: 14),

                  // Team Pending Approvals Section (For Managers & HR Approvers)
                  _buildTeamApprovalsSection(isDark),

                  // Exception Days Alert Bar (Only shows if absent days > 0!)
                  if (!_isLoadingAttendance && _exceptionDaysCount > 0)
                    _buildExceptionAlertBar(isDark),

                  const SizedBox(height: 14),

                  // Payslip Card Section with Green Toggle Switch
                  _buildPayslipOverviewCard(isDark),

                  const SizedBox(height: 24),

                  // Dynamic Upcoming Holidays Section
                  _buildUpcomingHolidaysSection(isDark),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildExceptionAlertBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_exceptionDaysCount Exception days (Absent this month)',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.red.shade200 : const Color(0xFF991B1B),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Regularization Request Portal...')),
                );
              },
              child: const Text(
                'Regularize',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipOverviewCard(bool isDark) {
    if (_isLoadingPayslip) {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final p = _latestPayslip;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/payslip'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payslip Title & Month Info Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Payslip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.north_east_rounded, size: 18, color: Color(0xFF0D9488)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p != null ? '${p.payrollMonth} ${p.payrollYear}' : 'No Cycle Active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p != null
                          ? '${p.paidDays.toStringAsFixed(p.paidDays.truncateToDouble() == p.paidDays ? 0 : 1)} paid days'
                          : 'Pending publication',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Piggy bank illustration & Net Pay Box
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Net Pay Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: p == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Published Payslips Found',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your official salary slips will appear here as soon as HR publishes payroll for the active cycle.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Net Pay',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: _isDownloadingDashboardPayslip
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        )
                                      : const Icon(Icons.download_rounded, size: 20, color: Color(0xFF3B82F6)),
                                  tooltip: 'Download PDF',
                                  onPressed: _isDownloadingDashboardPayslip ? null : () => _downloadDashboardPayslip(p),
                                ),
                              ],
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _showSalary ? '₹${p.netPay.toStringAsFixed(2)}' : '₹*****',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Gross Pay', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      _showSalary ? '₹${p.totalGrossPay.toStringAsFixed(2)}' : '₹*****',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Deductions', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      _showSalary ? '₹${p.totalDeductions.toStringAsFixed(2)}' : '₹*****',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Show Salary',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Switch.adaptive(
                                        value: _showSalary,
                                        activeThumbColor: const Color(0xFF10B981),
                                        activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                                        onChanged: (val) {
                                          setState(() {
                                            _showSalary = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                // Piggy Bank vector icon badge
                Positioned(
                  right: 14,
                  top: -20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE047),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.savings_rounded, color: Color(0xFF854D0E), size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingHolidaysSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              'Upcoming Holidays',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/holidays'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${DateTime.now().year} Calendar',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingHolidays)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (!_isHolidayCalendarPublished)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Color(0xFFF59E0B),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Holiday calendar is not published yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'The official company holiday calendar for ${DateTime.now().year} will appear here once published by HR.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_upcomingHolidays.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF3B82F6),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No more upcoming holidays for ${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'All scheduled holidays for this calendar year have concluded.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._upcomingHolidays.take(5).map((h) {
            final dateStr = _formatFullDate(h.date);
            final dayStr = _formatDayName(h.date);
            final isRestricted = h.isRestricted;
            final iconColor = isRestricted ? const Color(0xFF8B5CF6) : const Color(0xFF0D9488);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  final badge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );

                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardConstraints.maxWidth),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isRestricted ? Icons.event_note_rounded : Icons.beach_access_rounded,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.name.isNotEmpty ? h.name : 'Company Holiday',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$dayStr • ${isRestricted ? 'Restricted Holiday' : 'Official Holiday'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      badge,
                    ],
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTeamApprovalsSection(bool isDark) {
    if (!_isLoadingTeamApprovals && _teamPendingApprovals.isEmpty && !AuthStorage.isHr && !AuthStorage.isManager) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: headerConstraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Team Pending Approvals',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Review requests from your direct reports & team',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _teamPendingApprovals.isNotEmpty ? const Color(0xFFF59E0B) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_teamPendingApprovals.length} Pending',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_isLoadingTeamApprovals)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_teamPendingApprovals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All caught up! No pending team requests.',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._teamPendingApprovals.take(3).map((leave) => _buildHomePageApprovalCard(leave, isDark)),
          if (_teamPendingApprovals.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/leave-management'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text('View All ${_teamPendingApprovals.length} Requests'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomePageApprovalCard(dynamic leave, bool isDark) {
    final int reqId = leave['id'] ?? 0;
    final String empName = leave['employeeName'] ?? 'Team Member';
    final String dept = leave['employeeDepartment'] ?? 'General';
    final String leaveType = (leave['leaveType'] ?? 'CASUAL').toString().replaceAll('_', ' ');
    final bool isTimeBased = leave['isTimeBased'] == true;
    final String startDate = leave['startDate'] ?? '';
    final String endDate = leave['endDate'] ?? '';
    final String reason = leave['reason'] ?? 'No reason provided';
    final double totalDays = (leave['totalDays'] as num?)?.toDouble() ?? 1.0;
    final String startTime = leave['startTime'] ?? '';
    final String endTime = leave['endTime'] ?? '';

    final String initials = empName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTimeBased
                      ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                      : const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    leaveType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isTimeBased ? const Color(0xFF6366F1) : const Color(0xFF0D9488),
                    ),
                  ),
                ),
              );

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          child: Text(
                            initials.isNotEmpty ? initials : 'TM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                empName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                dept,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  badgeWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isTimeBased ? Icons.access_time_rounded : Icons.date_range_rounded,
                size: 14,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isTimeBased
                      ? '$startDate ($startTime - $endTime)'
                      : '$startDate to $endDate ($totalDays ${totalDays == 1 ? "day" : "days"})',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty && reason != 'N/A') ...[
            const SizedBox(height: 6),
            Text(
              'Reason: "$reason"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectReasonDialog(reqId, empName, isDark),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateLeaveStatus(reqId, 'APPROVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectReasonDialog(int reqId, String empName, bool isDark) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reject Request for $empName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please provide a reason for rejecting this request.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason (optional)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _updateLeaveStatus(reqId, 'REJECTED', rejectionReason: controller.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => controller.dispose());
  }
}

/// Isolated Sun Clock Shift Card that maintains its own internal 1-second ticker.
/// Prevents the parent EmployeeHomePage and its 150+ widgets from rebuilding every second.
class _SunClockShiftCard extends StatefulWidget {
  const _SunClockShiftCard();

  @override
  State<_SunClockShiftCard> createState() => _SunClockShiftCardState();
}

class _SunClockShiftCardState extends State<_SunClockShiftCard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) {
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    return '${_formatTwoDigits(hour)}:${_formatTwoDigits(dt.minute)}';
  }

  String _formatAmPm(DateTime dt) => dt.hour >= 12 ? 'PM' : 'AM';
  String _formatDayName(DateTime dt) => _days[dt.weekday - 1];
  String _formatFullDate(DateTime dt) =>
      '${_formatTwoDigits(dt.day)} ${_months[dt.month - 1]} ${dt.year}';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayName = _formatDayName(_currentTime);
    final fullDateStr = _formatFullDate(_currentTime);
    final timeStr = _formatTime(_currentTime);
    final amPmStr = _formatAmPm(_currentTime);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // City Skyline Graphic Banner Top
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF3B0764), const Color(0xFF1E293B)]
                    : [const Color(0xFFFDE68A), const Color(0xFFFFFBEB)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final count = (constraints.maxWidth / 22).floor().clamp(4, 40);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(
                            count,
                            (i) => Container(
                              width: 12.0 + (i % 3) * 6,
                              height: 16.0 + (i % 5) * 5,
                              color: (isDark ? Colors.purple.shade900 : Colors.amber.shade200)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                // Sun Clock graphic on left
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFDE047),
                        Color(0xFFF59E0B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF78350F),
                              ),
                            ),
                            Text(
                              amPmStr,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Shift Timings Info on right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayName | 10:00 AM To 19:00 PM Shift',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              fullDateStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

