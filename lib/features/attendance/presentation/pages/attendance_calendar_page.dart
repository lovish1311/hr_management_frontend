import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hr_management/features/attendance/domain/entities/attendance_calendar_day.dart';
import 'package:hr_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_management/features/attendance/presentation/widgets/attendance_calendar_grid.dart';
import 'package:hr_management/features/attendance/presentation/widgets/biometric_import_dialog.dart';
import 'package:hr_management/features/leaves/presentation/widgets/apply_leave_dialog.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';

class AttendanceCalendarPage extends StatefulWidget {
  final String currentEmployeeId;

  const AttendanceCalendarPage({
    super.key,
    this.currentEmployeeId = '1',
  });

  @override
  State<AttendanceCalendarPage> createState() => _AttendanceCalendarPageState();
}

class _AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  AppThemeConfig get t => context.appTheme;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  final AttendanceRepository _repository = AttendanceRepositoryImpl();

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  DateTime _activeMonth = DateTime.now();
  List<AttendanceCalendarDay> _days = [];
  bool _isLoading = true;

  int presentCount = 0;
  int paidLeaveCount = 0;
  int lopCount = 0;
  int holidayCount = 0;
  int weeklyWorkingMinutes = 0;

  final ScrollController _dropdownScrollController = ScrollController();
  final EmployeeRepository _employeeRepo = EmployeeRepositoryImpl();
  List<Employee> _dropdownEmployees = [];
  int _dropdownPage = 0;
  bool _isDropdownLoading = false;
  bool _hasMoreDropdown = true;
  String _dropdownSearchQuery = '';
  bool _isDropdownOpen = false;
  Employee? _selectedEmployee;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    if (AuthStorage.isHr) {
      _isLoading = false;
      _dropdownScrollController.addListener(() {
        if (_dropdownScrollController.position.pixels >=
            _dropdownScrollController.position.maxScrollExtent - 200) {
          if (_hasMoreDropdown && !_isDropdownLoading) {
            _loadDropdownPage();
          }
        }
      });
      _loadDropdownPage(reset: true).then((_) {
        if (_dropdownEmployees.isNotEmpty) {
          setState(() {
            _selectedEmployee = _dropdownEmployees.first;
          });
          _fetchCalendarData();
        }
      });
    } else {
      _fetchCalendarData();
    }
  }

  Future<void> _fetchCalendarData() async {
    final empId = AuthStorage.isHr
        ? (_selectedEmployee?.id ?? '')
        : widget.currentEmployeeId;

    if (empId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final days = await _repository.getMonthlyCalendarSummary(
        employeeId: empId,
        year: _activeMonth.year,
        month: _activeMonth.month,
      );

      int present = 0;
      int paidLeave = 0;
      int lop = 0;
      int holiday = 0;
      int weeklyMins = 0;

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      for (var d in days) {
        if (d.status == 'PRESENT' || d.status == 'LATE') present++;
        if (d.status == 'PAID_LEAVE') paidLeave++;
        if (d.status == 'LOP_LEAVE' || d.status == 'UNEXCUSED_ABSENT') lop++;
        if (d.status == 'HOLIDAY') holiday++;
        
        if (d.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
            d.date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          weeklyMins += d.totalWorkingMinutes;
        }
      }

      if (mounted) {
        setState(() {
          _days = days;
          presentCount = present;
          paidLeaveCount = paidLeave;
          lopCount = lop;
          holidayCount = holiday;
          weeklyWorkingMinutes = weeklyMins;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDropdownPage({bool reset = false}) async {
    if (_isDropdownLoading) return;
    if (reset) {
      setState(() {
        _dropdownPage = 0;
        _dropdownEmployees = [];
        _hasMoreDropdown = true;
      });
    }

    setState(() {
      _isDropdownLoading = true;
    });

    try {
      final list = await _employeeRepo.searchEmployeesPaginated(
        query: _dropdownSearchQuery,
        page: _dropdownPage,
        size: 50,
      );

      final nonAdmin = list.where((e) {
        final r = e.role.toUpperCase();
        return r != 'ADMIN' && r != 'SUPERADMIN' && r != 'SUPER_ADMIN';
      }).toList();

      if (mounted) {
        setState(() {
          if (reset) {
            _dropdownEmployees = nonAdmin;
          } else {
            _dropdownEmployees.addAll(nonAdmin);
          }
          _hasMoreDropdown = list.length >= 50;
          _dropdownPage++;
          _isDropdownLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDropdownLoading = false;
        });
      }
    }
  }

  void _onDropdownSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _dropdownSearchQuery = query;
      _loadDropdownPage(reset: true);
    });
  }

  Future<void> _refreshSelectedEmployee() async {
    if (_selectedEmployee == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/v1/employees/${_selectedEmployee!.id}'),
        headers: AuthStorage.authHeaders,
      );
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final updatedEmp = Employee.fromJson(decoded);
        setState(() {
          _selectedEmployee = updatedEmp;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitLeaveRequest(Map<String, dynamic> data) async {
    final type = data['leaveType'] as String;
    final fromDateStr = data['fromDate'] as String;
    final toDateStr = data['toDate'] as String;
    final fromSession = data['fromSession'] as String;
    final toSession = data['toSession'] as String;

    double days = 1.0;
    try {
      final start = DateTime.parse(fromDateStr);
      final end = DateTime.parse(toDateStr);
      final diff = end.difference(start).inDays + 1;
      if (diff == 1 && (fromSession != 'Session 1' || toSession != 'Session 2')) {
        days = 0.5;
      } else {
        days = diff.toDouble();
      }
    } catch (_) {}

    final empId = data['onBehalfEmployeeId'] != null
        ? int.tryParse(data['onBehalfEmployeeId'].toString()) ?? 1
        : AuthStorage.employeeId ?? 1;

    final body = json.encode({
      'employeeId': empId,
      'startDate': fromDateStr,
      'endDate': toDateStr,
      'leaveType': type.toUpperCase().replaceAll(' ', '_'),
      'totalDays': days,
      'reason': data['reason'] ?? '',
      if (data['startTime'] != null) 'startTime': data['startTime'],
      if (data['endTime'] != null) 'endTime': data['endTime'],
    });

    try {
      final isAdminApply = AuthStorage.isHr && data['onBehalfEmployeeId'] != null;
      final urlStr = isAdminApply
          ? '$_baseUrl/api/v1/leaves/admin/apply-on-behalf'
          : '$_baseUrl/api/v1/leaves/apply';

      final res = await http.post(
        Uri.parse(urlStr),
        headers: AuthStorage.authHeaders,
        body: body,
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully applied for $days day(s) of $type.'),
            backgroundColor: t.success,
          ),
        );
        _fetchCalendarData();
        _refreshSelectedEmployee();
      } else {
        String errMsg = 'Failed to apply for leave.';
        try {
          final errBody = json.decode(res.body);
          if (errBody['message'] != null) {
            errMsg = errBody['message'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: t.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error applying for leave: $e'),
          backgroundColor: t.danger,
        ),
      );
    }
  }

  Future<void> _processLeaveRequest(int leaveRequestId, String status, String? rejectionReason) async {
    final approverId = AuthStorage.employeeId ?? 1;
    final body = json.encode({
      'status': status,
      'rejectionReason': rejectionReason ?? '',
      'approverId': approverId.toString(),
    });

    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/v1/leaves/$leaveRequestId/status'),
        headers: AuthStorage.authHeaders,
        body: body,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request has been $status!'),
            backgroundColor: status == 'APPROVED' ? t.success : t.danger,
          ),
        );
        _fetchCalendarData();
        _refreshSelectedEmployee();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update leave request status.'),
            backgroundColor: t.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating leave status: $e'),
          backgroundColor: t.danger,
        ),
      );
    }
  }

  void _showReviewLeaveDialog(AttendanceCalendarDay day) {
    
    final t = context.appTheme;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Review Leave Request',
          style: TextStyle(fontWeight: FontWeight.bold, color: t.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Date', _formatDate(day.date), t),
            _buildDetailRow('Type', day.leaveType != null ? _formatLeaveType(day.leaveType!) : 'Casual Leave', t),
            _buildDetailRow('Status', 'Pending Approval', t),
            const SizedBox(height: 12),
            Text(
              'Optional Rejection Reason:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processLeaveRequest(day.leaveRequestId!, 'REJECTED', reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: t.danger),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processLeaveRequest(day.leaveRequestId!, 'APPROVED', null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: t.success),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + delta, 1);
    });
    _fetchCalendarData();
  }

  void _openBiometricImportDialog() {
    showDialog(
      context: context,
      builder: (context) => BiometricImportDialog(
        onImportSuccess: () {
          _fetchCalendarData();
        },
      ),
    );
  }

  Future<void> _clearLeaveData({required bool clearAll}) async {
    final targetName = clearAll
        ? 'ALL employees'
        : (_selectedEmployee?.name ?? 'selected employee');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Data Clear (${clearAll ? "ALL Employees" : (_selectedEmployee?.name ?? "Selected Employee")})'),
        content: Text(
          clearAll
              ? 'Are you sure you want to permanently delete ALL leave requests, permissions, short breaks, and reset leave balances for ALL employees?'
              : 'Are you sure you want to permanently delete ALL leave requests and reset balances for ${_selectedEmployee?.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete / Clear Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final empId = _selectedEmployee?.id;
      final url = clearAll
          ? Uri.parse('$_baseUrl/api/v1/leaves/clear/all')
          : Uri.parse('$_baseUrl/api/v1/leaves/clear/employee/$empId');

      final res = await http.delete(
        url,
        headers: AuthStorage.authHeaders,
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully cleared leave data for $targetName!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _fetchCalendarData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear leave data: ${res.statusCode} ${res.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing leave data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApplyRequestOptionsForDate(AttendanceCalendarDay day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final t = context.appTheme;
        final maxHeight = MediaQuery.of(context).size.height * 0.85;
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apply Request for ${_formatDate(day.date)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildApplyOptionTile(
                    icon: Icons.luggage_outlined,
                    color: t.primary,
                    title: 'Apply Leave',
                    subtitle: 'Full day or half day leave',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog(day.date, 'Leave');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildApplyOptionTile(
                    icon: Icons.coffee_outlined,
                    color: t.warning,
                    title: 'Apply Short Break',
                    subtitle: 'Partial time off during shift',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog(day.date, 'Short Break');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildApplyOptionTile(
                    icon: Icons.directions_run_outlined,
                    color: t.secondary,
                    title: 'Apply Early Out',
                    subtitle: 'Leave work earlier than schedule',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog(day.date, 'Early Out');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildApplyOptionTile(
                    icon: Icons.watch_later_outlined,
                    color: const Color(0xFFEF4444),
                    title: 'Apply Late Arrival',
                    subtitle: 'Permission for arriving after shift start',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog(day.date, 'Late Arrival');
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplyOptionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _openApplyDialog(DateTime date, String category) {
    showDialog(
      context: context,
      builder: (context) => ApplyLeaveDialog(
        initialStartDate: date,
        initialEndDate: date,
        initialRequestCategory: category,
        // Admin applies on behalf of selected employee; Employee applies for themselves (null)
        targetEmployee: AuthStorage.isHr ? _selectedEmployee : null,
        onSubmit: (data) {
          _submitLeaveRequest(data);
        },
      ),
    );
  }

  void _setReminderForDate(AttendanceCalendarDay day) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${_formatDate(day.date)} check-in!'),
        backgroundColor: t.warning,
      ),
    );
  }

  void _showDayDetailsDialog(AttendanceCalendarDay day) {
    // Admin reviewing an employee's calendar can approve/reject pending leaves
    if (AuthStorage.isHr && day.status == 'PENDING_LEAVE' && day.leaveRequestId != null) {
      _showReviewLeaveDialog(day);
      return;
    }

    final t = context.appTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _formatDate(day.date),
          style: TextStyle(fontWeight: FontWeight.bold, color: t.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', day.statusLabel, t),
            if (day.leaveType != null) _buildDetailRow('Leave Category', _formatLeaveType(day.leaveType!), t),
            if (day.checkInTime != null) _buildDetailRow('Check-in Time', day.checkInTime!, t),
            if (day.checkOutTime != null) _buildDetailRow('Check-out Time', day.checkOutTime!, t),
            if (day.isWeekend) _buildDetailRow('Schedule', 'Official Weekend (No Check-in required)', t),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showApplyRequestOptionsForDate(day);
            },
            style: ElevatedButton.styleFrom(backgroundColor: t.primary),
            child: const Text('Apply Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, AppThemeConfig t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _getMonthName(int month) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  String _formatLeaveType(String raw) {
    final formatted = raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
    return formatted.contains('Leave') ? formatted : '$formatted Leave';
  }

  @override
  Widget build(BuildContext context) {
    
    final t = context.appTheme;
    final isAdmin = AuthStorage.isHr;

    // KPI Metrics calculation
    final paidLeaveCount = _days.where((d) => d.status == 'PAID_LEAVE').length;
    final lopCount = _days.where((d) => d.status == 'LOP_LEAVE' || d.status == 'UNEXCUSED_ABSENT').length;
    final holidayCount = _days.where((d) => d.status == 'HOLIDAY').length;
    final String weeklyHoursStr = '${weeklyWorkingMinutes ~/ 60}h ${weeklyWorkingMinutes % 60}m';

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Attendance Management' : 'Attendance Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, color: t.onBackgroundText),
        ),
        iconTheme: IconThemeData(color: t.onBackgroundText),
        actions: [
          if (!isAdmin)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: t.onBackgroundText),
              onPressed: _fetchCalendarData,
            ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HR Biometric Sheet Upload Header Card (Visible ONLY for Super Admin)
                if (isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: t.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.upload_file_rounded, color: Color(0xFF6366F1), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biometric Attendance Management',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: t.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Upload punch machine Excel (.xlsx) to process and sync daily attendance',
                                style: TextStyle(fontSize: 12, color: t.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openBiometricImportDialog,
                          icon: const Icon(Icons.note_add_rounded, size: 18),
                          label: const Text('Import Punch Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          tooltip: 'Clear Leave Data Options',
                          onSelected: (val) {
                            if (val == 'selected') {
                              _clearLeaveData(clearAll: false);
                            } else if (val == 'all') {
                              _clearLeaveData(clearAll: true);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'selected',
                              enabled: _selectedEmployee != null,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_remove_outlined, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedEmployee != null
                                        ? 'Clear ${_selectedEmployee!.name}\'s Leave Data'
                                        : 'Select an employee to clear',
                                    style: const TextStyle(fontSize: 13, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever_outlined, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Clear ALL Employees\' Leave Data', style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cleaning_services_rounded, color: Colors.red, size: 18),
                                SizedBox(width: 6),
                                Text('Clear Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                Icon(Icons.arrow_drop_down_rounded, color: Colors.red, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildEmployeeSelector(t),
                  const SizedBox(height: 20),
                ],

                if (!isAdmin || _selectedEmployee != null) ...[
                  // KPI Stats Summary Cards (Responsive for mobile vs desktop)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                _buildKpiCard('Weekly Hours', weeklyHoursStr, t.success, Icons.timer_rounded, t),
                                const SizedBox(width: 12),
                                _buildKpiCard('Paid Leaves', '$paidLeaveCount', t.primary, Icons.umbrella_rounded, t),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildKpiCard('LOP / Absent', '$lopCount', const Color(0xFFEF4444), Icons.money_off_rounded, t),
                                const SizedBox(width: 12),
                                _buildKpiCard('Holidays', '$holidayCount', const Color(0xFF06B6D4), Icons.star_outline_rounded, t),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          _buildKpiCard('Weekly Hours', weeklyHoursStr, t.success, Icons.timer_rounded, t),
                          const SizedBox(width: 12),
                          _buildKpiCard('Paid Leaves', '$paidLeaveCount', t.primary, Icons.umbrella_rounded, t),
                          const SizedBox(width: 12),
                          _buildKpiCard('LOP / Absent', '$lopCount', const Color(0xFFEF4444), Icons.money_off_rounded, t),
                          const SizedBox(width: 12),
                          _buildKpiCard('Holidays', '$holidayCount', const Color(0xFF06B6D4), Icons.star_outline_rounded, t),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Calendar Main Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Month Navigation Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 28),
                              onPressed: () => _changeMonth(-1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_getMonthName(_activeMonth.month)} ${_activeMonth.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: t.text,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 28),
                              onPressed: () => _changeMonth(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Calendar Grid Component
                        _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : AttendanceCalendarGrid(
                                activeMonth: _activeMonth,
                                days: _days,
                                onDayTap: _showDayDetailsDialog,
                                onApplyLeaveForDate: _showApplyRequestOptionsForDate,
                                onSetReminderForDate: _setReminderForDate,
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Color Legend Footer Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color Legend & Gestures',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          children: [
                            _buildLegendItem('Present', t.success, t),
                            _buildLegendItem('Late Check-In', t.warning, t),
                            _buildLegendItem('Paid Leave', t.primary, t),
                            _buildLegendItem('Pending Leave Approval', const Color(0xFFFF9800), t),
                            _buildLegendItem('LOP / Unpaid', const Color(0xFFEF4444), t),
                            _buildLegendItem('Holiday', const Color(0xFF06B6D4), t),
                            _buildLegendItem('Weekend', isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), t),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          isAdmin
                              ? '💡 Hint: Click or tap a pending leave tile (Orange) to review and approve/reject it directly. Click any other date to apply leave on behalf of the employee.'
                              : '💡 Hint: Click (web) or tap (mobile) any date tile to set a reminder, view day log, or apply leave pre-filled for that date.',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color, IconData icon, AppThemeConfig t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector(AppThemeConfig t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Select Employee to View Attendance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isDropdownOpen = !_isDropdownOpen;
                if (_isDropdownOpen && _dropdownEmployees.isEmpty) {
                  _loadDropdownPage(reset: true);
                }
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isDropdownOpen
                        ? t.primary
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: 1.5,
                  ),
                  boxShadow: _isDropdownOpen
                      ? [BoxShadow(color: t.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: t.primary.withValues(alpha: 0.12),
                      child: Text(
                        _selectedEmployee != null && _selectedEmployee!.name.isNotEmpty
                            ? _selectedEmployee!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Color(0xFF6366F1), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedEmployee?.name ?? 'Search and select an employee...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _selectedEmployee != null
                                  ? (t.text)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedEmployee != null
                                ? '${_selectedEmployee!.role} • ${_selectedEmployee!.department} • Balance: ${_selectedEmployee!.leaveBalance} days'
                                : 'Tap to search & filter the workforce directory',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedEmployee != null && !_isDropdownOpen) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          _showApplyRequestOptionsForDate(AttendanceCalendarDay(date: DateTime.now(), status: 'UPCOMING', statusLabel: ''));
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text('New Request', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.success,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      _isDropdownOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isDropdownOpen) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Box
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name, role or email...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        _onDropdownSearchQueryChanged(val);
                      },
                    ),
                  ),
                  Expanded(
                    child: _dropdownEmployees.isEmpty && _isDropdownLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _dropdownEmployees.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 36, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No employees found', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _dropdownScrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                itemCount: _dropdownEmployees.length + (_hasMoreDropdown ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _dropdownEmployees.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final emp = _dropdownEmployees[index];
                                  final isSelected = _selectedEmployee?.id == emp.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        tileColor: isSelected
                                            ? t.primary.withValues(alpha: 0.08)
                                            : null,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isSelected
                                              ? t.primary.withValues(alpha: 0.2)
                                              : t.primary.withValues(alpha: 0.1),
                                          child: Text(
                                            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                                            style: TextStyle(
                                              color: t.primary,
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          emp.name,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? t.primary : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${emp.role} • ${emp.department}',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 20)
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedEmployee = emp;
                                            _isDropdownOpen = false;
                                          });
                                          _fetchCalendarData();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, AppThemeConfig t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textSecondary),
        ),
      ],
    );
  }
}




