import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hr_management/features/attendance/domain/entities/attendance_calendar_day.dart';
import 'package:hr_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_management/features/attendance/presentation/widgets/attendance_calendar_grid.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final EmployeeRepository _repository = EmployeeRepositoryImpl();
  final AttendanceRepository _attendanceRepository = AttendanceRepositoryImpl();
  Employee? _employee;
  bool _isLoading = true;

  DateTime _attendanceActiveMonth = DateTime.now();
  List<AttendanceCalendarDay> _attendanceCalendarDays = [];
  bool _isAttendanceCalendarLoading = false;

  List<ProfileAttendanceRecord> _attendanceRecords = [];
  List<LeaveBalanceItem> _leaveBalances = [];
  List<ProfileLeaveRequestRecord> _leaveRequests = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_employee == null) {
      final employeeId = ModalRoute.of(context)?.settings.arguments as String?;
      if (employeeId != null) {
        _fetchEmployee(employeeId);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchAttendanceCalendar() async {
    if (_employee == null) return;
    setState(() => _isAttendanceCalendarLoading = true);
    try {
      final days = await _attendanceRepository.getMonthlyCalendarSummary(
        employeeId: _employee!.id,
        year: _attendanceActiveMonth.year,
        month: _attendanceActiveMonth.month,
      );
      if (mounted) {
        setState(() {
          _attendanceCalendarDays = days;
          _isAttendanceCalendarLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAttendanceCalendarLoading = false);
    }
  }

  String _formatTimeDisplay(String? timeStr, String fallback) {
    if (timeStr == null || timeStr == 'CLEAR' || timeStr.isEmpty) return fallback;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        String minStr = minute.toString().padLeft(2, '0');
        return '${displayHour.toString().padLeft(2, '0')}:$minStr $period';
      }
    } catch (_) {}
    return timeStr;
  }

  Future<void> _fetchEmployee(String id) async {
    try {
      final emp = await _repository.getEmployeeById(id);
      if (mounted) {
        setState(() {
          _employee = emp;
          _isLoading = false;
          
          _attendanceRecords = [
            ProfileAttendanceRecord(date: 'Jul 17, 2026', clockIn: '09:00 AM', clockOut: '05:30 PM', totalHours: '8.5 hrs', status: 'On Time'),
            ProfileAttendanceRecord(date: 'Jul 16, 2026', clockIn: '09:15 AM', clockOut: '06:00 PM', totalHours: '8.75 hrs', status: 'Late'),
            ProfileAttendanceRecord(date: 'Jul 15, 2026', clockIn: '08:55 AM', clockOut: '05:00 PM', totalHours: '8.0 hrs', status: 'On Time'),
            ProfileAttendanceRecord(date: 'Jul 14, 2026', clockIn: '09:05 AM', clockOut: '05:30 PM', totalHours: '8.4 hrs', status: 'On Time'),
            ProfileAttendanceRecord(date: 'Jul 13, 2026', clockIn: '--:--', clockOut: '--:--', totalHours: '0.0 hrs', status: 'Absent'),
          ];
          
          _leaveBalances = [
            LeaveBalanceItem(type: 'Annual Leave', taken: emp != null ? emp.leaveBalance : 5, total: 14),
            LeaveBalanceItem(type: 'Sick Leave', taken: 2, total: 10),
            LeaveBalanceItem(type: 'Unpaid Leave', taken: 0, total: 5),
          ];
          
          _leaveRequests = [
            ProfileLeaveRequestRecord(leaveType: 'Annual Leave', startDate: 'Jul 26, 2026', endDate: 'Jul 28, 2026', reason: 'Doctor appointment', status: 'Pending'),
            ProfileLeaveRequestRecord(leaveType: 'Annual Leave', startDate: 'Aug 10, 2026', endDate: 'Aug 15, 2026', reason: 'Family vacation', status: 'Approved'),
            ProfileLeaveRequestRecord(leaveType: 'Sick Leave', startDate: 'Jun 05, 2026', endDate: 'Jun 06, 2026', reason: 'Fever', status: 'Approved'),
            ProfileLeaveRequestRecord(leaveType: 'Annual Leave', startDate: 'May 02, 2026', endDate: 'May 04, 2026', reason: 'Personal work', status: 'Rejected'),
          ];
        });

        _fetchAttendanceCalendar();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return ResponsiveScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.notifications_outlined, color: primaryColor),
            const SizedBox(width: 16),
            const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              child: const Icon(Icons.person, size: 18),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _employee == null
                ? const Center(child: Text('Employee not found.'))
                : DefaultTabController(
                    length: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWideScreen = constraints.maxWidth > 850;
                        if (isWideScreen) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCard(context, _employee!, true),
                              Expanded(
                                child: _buildDetailsArea(context, _employee!),
                              ),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildSummaryCard(context, _employee!, false),
                                _buildDetailsArea(context, _employee!),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Employee emp, bool isWideScreen) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: isWideScreen ? 320 : double.infinity,
      margin: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gradient Hero Header Accent Bar
          Container(
            height: 70,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -35),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                        backgroundImage: NetworkImage(
                          'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(emp.name)}',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  emp.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${emp.role} • ${emp.department}',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Attendance tracking & Exemption Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    if (!emp.isAttendanceTracked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text('Untracked / Exempt', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (emp.lateArrivalAllowedUntil != null && emp.lateArrivalAllowedUntil!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text('Late Upto ${emp.lateArrivalAllowedUntil}', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (emp.earlyOutAllowedAfter != null && emp.earlyOutAllowedAfter!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.logout_rounded, size: 12, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            Text('Early Out After ${emp.earlyOutAllowedAfter}', style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Manager
                Text(
                  'Direct Manager',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(emp.managerName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const Spacer(),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        child: const Icon(Icons.person, size: 14, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contact Info
                _buildContactRow(context, 'Email', emp.email, Icons.email_outlined),
                const SizedBox(height: 10),
                _buildContactRow(context, 'Phone', emp.phone, Icons.phone_outlined),
                const SizedBox(height: 20),
                // Quick Links & HR Actions
                Text(
                  'Management Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                if (AuthStorage.isHr) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAssignManagerDialog(emp),
                      icon: const Icon(Icons.supervisor_account_rounded, size: 16),
                      label: const Text('Assign Manager / Approver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        foregroundColor: const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPermissionsDialog(emp),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Manage Permissions & Exemptions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (AuthStorage.isHr) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showElevateRoleDialog(emp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.security_rounded, size: 16),
                      label: const Text('Elevate / Change Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignManagerDialog(Employee emp) {
    Employee? selectedPrimaryManager;
    final List<Employee> selectedSecondaryApprovers = [];
    List<Employee> availableEmployees = [];
    bool isLoadingList = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isLoadingList) {
              _repository.getEmployees().then((list) {
                if (context.mounted) {
                  setDialogState(() {
                    availableEmployees = list.where((e) => 
                      e.id != emp.id && 
                      e.role != 'SUPER_ADMIN' && 
                      e.role != 'ROLE_SUPER_ADMIN' && 
                      !e.role.toUpperCase().contains('ADMIN')
                    ).toList();

                    if (availableEmployees.isNotEmpty) {
                      try {
                        selectedPrimaryManager = availableEmployees.firstWhere(
                          (e) => e.name.toLowerCase() == emp.managerName.toLowerCase() || (emp.managerId != null && e.id == emp.managerId)
                        );
                      } catch (_) {
                        selectedPrimaryManager = availableEmployees.first;
                      }
                    }
                    isLoadingList = false;
                  });
                }
              });
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.supervisor_account_rounded, color: Color(0xFF0D9488), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Assign Manager & Leave Approvers', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('Set reporting lead and optional secondary approvers for ${emp.name}.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      if (isLoadingList)
                        const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))))
                      else ...[
                        Text('1. Primary Reporting Manager*', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Employee>(
                              value: selectedPrimaryManager,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D9488)),
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              items: availableEmployees.map((mgr) {
                                return DropdownMenuItem<Employee>(
                                  value: mgr,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                                        child: Text(mgr.name.isNotEmpty ? mgr.name[0] : 'E', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${mgr.name} (${mgr.role} • ${mgr.department})',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                setDialogState(() {
                                  selectedPrimaryManager = newVal;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('2. Secondary Co-Approvers (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: ListView.separated(
                              itemCount: availableEmployees.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final candidate = availableEmployees[index];
                                if (candidate.id == selectedPrimaryManager?.id) {
                                  return const SizedBox.shrink();
                                }
                                final isChecked = selectedSecondaryApprovers.contains(candidate);
                                return CheckboxListTile(
                                  dense: true,
                                  value: isChecked,
                                  activeColor: const Color(0xFF0D9488),
                                  title: Text(candidate.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text('${candidate.email} • ${candidate.role}', style: const TextStyle(fontSize: 11)),
                                  secondary: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                    child: Text(candidate.name[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                                  ),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedSecondaryApprovers.add(candidate);
                                      } else {
                                        selectedSecondaryApprovers.remove(candidate);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (selectedPrimaryManager != null) {
                                await _repository.assignManager(emp.id, selectedPrimaryManager!.id);
                                if (mounted) {
                                  setState(() {
                                    _employee = Employee(
                                      id: emp.id,
                                      employeeCode: emp.employeeCode,
                                      name: emp.name,
                                      firstName: emp.firstName,
                                      lastName: emp.lastName,
                                      role: emp.role,
                                      department: emp.department,
                                      designation: emp.designation,
                                      status: emp.status,
                                      email: emp.email,
                                      phone: emp.phone,
                                      managerName: selectedPrimaryManager!.name,
                                      managerId: selectedPrimaryManager!.id,
                                      dateOfBirth: emp.dateOfBirth,
                                      joiningDate: emp.joiningDate,
                                      employmentType: emp.employmentType,
                                      address: emp.address,
                                      location: emp.location,
                                      emergencyContactName: emp.emergencyContactName,
                                      emergencyContactPhone: emp.emergencyContactPhone,
                                      leaveBalance: emp.leaveBalance,
                                      attendanceRate: emp.attendanceRate,
                                      isAttendanceTracked: emp.isAttendanceTracked,
                                      departmentCategory: emp.departmentCategory,
                                    );
                                  });
                                }
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Assigned ${selectedPrimaryManager?.name ?? "Manager"} as Leave Approver for ${emp.name}!'),
                                    backgroundColor: const Color(0xFF0D9488),
                                  ),
                                );
                                _fetchEmployee(emp.id);
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Save Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPermissionsDialog(Employee emp) {
    bool isTracked = emp.isAttendanceTracked;
    String selectedLateTime = emp.lateArrivalAllowedUntil ?? 'CLEAR';
    String selectedEarlyTime = emp.earlyOutAllowedAfter ?? 'CLEAR';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.more_time_rounded, color: Color(0xFF0D9488), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Employee Permissions & Timing Exemptions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('Manage tracking rules and clock timing exemptions for ${emp.name}.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Attendance Tracking Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTracked ? Icons.event_available_rounded : Icons.event_busy_rounded,
                              color: isTracked ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTracked ? 'Attendance Tracking Enabled' : 'Attendance Tracking Disabled (Exempt)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isTracked ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFFD97706)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isTracked
                                        ? 'Punches are logged and tracked in attendance reports.'
                                        : 'Employee is marked EXEMPT from daily attendance reports.',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isTracked,
                              activeThumbColor: const Color(0xFF0D9488),
                              onChanged: (newVal) {
                                showDialog(
                                  context: context,
                                  builder: (confirmContext) {
                                    return AlertDialog(
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Row(
                                        children: [
                                          Icon(
                                            newVal ? Icons.event_available_rounded : Icons.warning_amber_rounded,
                                            color: newVal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            newVal ? 'Enable Tracking?' : 'Disable Tracking?',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        newVal
                                            ? 'Are you sure you want to enable attendance tracking for ${emp.name}? Daily biometric punches will be logged.'
                                            : 'Are you sure you want to disable attendance tracking for ${emp.name}? This employee will be marked EXEMPT from daily reports.',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(confirmContext),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: newVal ? const Color(0xFF0D9488) : const Color(0xFFF59E0B),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(confirmContext);
                                            setDialogState(() => isTracked = newVal);
                                          },
                                          child: Text(newVal ? 'Confirm Enable' : 'Confirm Disable'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Late Arrival Exemption Clock Picker
                      Text('Late Arrival Exemption', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          TimeOfDay initial = const TimeOfDay(hour: 10, minute: 0);
                          if (selectedLateTime != 'CLEAR' && selectedLateTime.contains(':')) {
                            final p = selectedLateTime.split(':');
                            initial = TimeOfDay(hour: int.tryParse(p[0]) ?? 10, minute: int.tryParse(p[1]) ?? 0);
                          }
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                            helpText: 'SELECT LATE ARRIVAL CUTOFF TIME',
                          );
                          if (picked != null) {
                            final hh = picked.hour.toString().padLeft(2, '0');
                            final mm = picked.minute.toString().padLeft(2, '0');
                            setDialogState(() {
                              selectedLateTime = '$hh:$mm:00';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded, color: Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedLateTime != 'CLEAR' && selectedLateTime.isNotEmpty
                                      ? 'Late Allowed Upto: ${_formatTimeDisplay(selectedLateTime, "09:30 AM")}'
                                      : 'Standard Cutoff (09:30 AM)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedLateTime != 'CLEAR' ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              if (selectedLateTime != 'CLEAR' && selectedLateTime.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => setDialogState(() => selectedLateTime = 'CLEAR'),
                                  icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                                  label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF3B82F6)),
                                    SizedBox(width: 4),
                                    Text('Tap Clock', style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Early Out Exemption Clock Picker
                      Text('Early Out Exemption', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          TimeOfDay initial = const TimeOfDay(hour: 17, minute: 0);
                          if (selectedEarlyTime != 'CLEAR' && selectedEarlyTime.contains(':')) {
                            final p = selectedEarlyTime.split(':');
                            initial = TimeOfDay(hour: int.tryParse(p[0]) ?? 17, minute: int.tryParse(p[1]) ?? 0);
                          }
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                            helpText: 'SELECT EARLY OUT PERMITTED TIME',
                          );
                          if (picked != null) {
                            final hh = picked.hour.toString().padLeft(2, '0');
                            final mm = picked.minute.toString().padLeft(2, '0');
                            setDialogState(() {
                              selectedEarlyTime = '$hh:$mm:00';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, color: Color(0xFF8B5CF6), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedEarlyTime != 'CLEAR' && selectedEarlyTime.isNotEmpty
                                      ? 'Early Out Allowed After: ${_formatTimeDisplay(selectedEarlyTime, "06:00 PM")}'
                                      : 'Standard Shift End (06:00 PM)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedEarlyTime != 'CLEAR' ? const Color(0xFF7C3AED) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              if (selectedEarlyTime != 'CLEAR' && selectedEarlyTime.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => setDialogState(() => selectedEarlyTime = 'CLEAR'),
                                  icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                                  label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF8B5CF6)),
                                    SizedBox(width: 4),
                                    Text('Tap Clock', style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _repository.updatePermissions(
                                emp.id,
                                isAttendanceTracked: isTracked,
                                lateArrivalAllowedUntil: selectedLateTime,
                                earlyOutAllowedAfter: selectedEarlyTime,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Updated permissions and standing exemptions for ${emp.name}!'),
                                    backgroundColor: const Color(0xFF0D9488),
                                  ),
                                );
                                _fetchEmployee(emp.id);
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Save Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showElevateRoleDialog(Employee emp) {
    String selectedRole = emp.role;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Elevate User Role (Master Admin)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change system permissions for ${emp.name}:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole.contains('SUPER_ADMIN')
                    ? 'SUPER_ADMIN'
                    : selectedRole.contains('HR')
                        ? 'HR'
                        : selectedRole.contains('MANAGER')
                            ? 'MANAGER'
                            : 'EMPLOYEE',
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'System Role'),
                items: const [
                  DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin (Master Access)')),
                  DropdownMenuItem(value: 'HR', child: Text('HR Admin')),
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manager / Team Lead')),
                  DropdownMenuItem(value: 'EMPLOYEE', child: Text('Standard Employee')),
                ],
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${emp.name} role updated to $selectedRole!'), backgroundColor: const Color(0xFF8B5CF6)),
                );
                _fetchEmployee(emp.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text('Update Role', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildContactRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsArea(BuildContext context, Employee emp) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 24.0, right: 24.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: 'Profile Details'),
              Tab(text: 'Attendance'),
              Tab(text: 'Leaves'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              children: [
                _buildProfileDetailsTab(context, emp),
                _buildAttendanceTab(context),
                _buildLeavesTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsTab(BuildContext context, Employee emp) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField(context, 'Employee ID', emp.id)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildReadOnlyField(context, 'Department', emp.department)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField(context, 'Role', emp.role)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildReadOnlyField(context, 'Status', emp.status)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField(context, 'Date of Birth', emp.dateOfBirth)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildReadOnlyField(context, 'Location', emp.location)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField(context, 'Contact Name', emp.emergencyContactName)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildReadOnlyField(context, 'Contact Phone', emp.emergencyContactPhone)),
                ],
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Attendance Rate',
                        value: '${emp.attendanceRate}%',
                        color: Colors.green.shade100,
                        textColor: Colors.green.shade900,
                        icon: Icons.bar_chart,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Leave Balance',
                        value: '${emp.leaveBalance} Days',
                        color: Colors.blue.shade100,
                        textColor: Colors.blue.shade900,
                        icon: Icons.pie_chart,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel = '${monthNames[_attendanceActiveMonth.month - 1]} ${_attendanceActiveMonth.year}';

    int presentDays = 0;
    int paidLeaves = 0;
    int lopDays = 0;
    for (var d in _attendanceCalendarDays) {
      if (d.status == 'PRESENT' || d.status == 'LATE') presentDays++;
      if (d.status == 'PAID_LEAVE') paidLeaves++;
      if (d.status == 'LOP_LEAVE' || d.status == 'UNEXCUSED_ABSENT') lopDays++;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0D9488), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Monthly Attendance Calendar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: () {
                        setState(() {
                          _attendanceActiveMonth = DateTime(_attendanceActiveMonth.year, _attendanceActiveMonth.month - 1, 1);
                        });
                        _fetchAttendanceCalendar();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        monthLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      onPressed: () {
                        setState(() {
                          _attendanceActiveMonth = DateTime(_attendanceActiveMonth.year, _attendanceActiveMonth.month + 1, 1);
                        });
                        _fetchAttendanceCalendar();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final cards = [
                _buildSummaryCardMetric(context, 'Present Days', '$presentDays Days', Icons.check_circle_outline, const Color(0xFF10B981)),
                _buildSummaryCardMetric(context, 'Paid Leaves', '$paidLeaves Days', Icons.event_available_rounded, const Color(0xFF6366F1)),
                _buildSummaryCardMetric(context, 'LOP / Absent', '$lopDays Days', Icons.cancel_outlined, const Color(0xFFEF4444)),
                _buildSummaryCardMetric(context, 'Avg Work Hours', '8.4 hrs', Icons.access_time_rounded, const Color(0xFF0D9488)),
              ];
              if (isDesktop) {
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12.0), child: c))).toList(),
                );
              } else {
                return Column(
                  children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: c)).toList(),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Full Month Attendance Calendar Grid
          if (_isAttendanceCalendarLoading)
            const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
            )
          else
            AttendanceCalendarGrid(
              activeMonth: _attendanceActiveMonth,
              days: _attendanceCalendarDays,
              showReminderOption: (AuthStorage.userEmail ?? '').toLowerCase() == (_employee?.email ?? '').toLowerCase() || (AuthStorage.employeeId != null && AuthStorage.employeeId.toString() == _employee?.id),
              onDayTap: (day) {},
              onApplyLeaveForDate: (day) {},
              onSetReminderForDate: (day) {},
            ),

          const SizedBox(height: 32),
          Text(
            'Daily Attendance Records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildAttendanceTable(context, _attendanceRecords),
        ],
      ),
    );
  }

  Widget _buildSummaryCardMetric(BuildContext context, String title, String value, IconData icon, [Color? iconColor]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = iconColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(BuildContext context, List<ProfileAttendanceRecord> records) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        if (isDesktop) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200, width: 1.0),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Date', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Clock-In', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Clock-Out', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Total Hours', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Status', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                ...records.map((r) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(child: Text(r.clockIn, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(r.clockOut, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(r.totalHours, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: r.status))),
                        ],
                      ),
                    ),
                    if (records.last != r) Divider(height: 1, color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200),
                  ],
                )),
              ],
            ),
          );
        } else {
          return Column(
            children: records.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      StatusPill(status: r.status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Clock-In', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(r.clockIn, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Clock-Out', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(r.clockOut, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Hours', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(r.totalHours, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            )).toList(),
          );
        }
      },
    );
  }

  Widget _buildLeavesTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final cards = _leaveBalances.map((b) => Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.type, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${b.taken} / ${b.total} Days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: LinearProgressIndicator(
                        value: b.total > 0 ? b.taken / b.total : 0,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              )).toList();
              
              if (isDesktop) {
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12.0), child: c))).toList(),
                );
              } else {
                return Column(
                  children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: c)).toList(),
                );
              }
            },
          ),
          const SizedBox(height: 32),
          const Text('Leave Request History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildLeavesHistoryTable(context, _leaveRequests),
        ],
      ),
    );
  }

  Widget _buildLeavesHistoryTable(BuildContext context, List<ProfileLeaveRequestRecord> records) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        if (isDesktop) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200, width: 1.0),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Leave Type', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Start Date', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('End Date', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 3, child: Text('Reason', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                ...records.map((r) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(r.leaveType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 2, child: Text(r.startDate, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 2, child: Text(r.endDate, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 3, child: Text(r.reason, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: r.status))),
                        ],
                      ),
                    ),
                    if (records.last != r) Divider(height: 1, color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200),
                  ],
                )),
              ],
            ),
          );
        } else {
          return Column(
            children: records.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.leaveType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      StatusPill(status: r.status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${r.startDate} - ${r.endDate}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reason', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(r.reason, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            )).toList(),
          );
        }
      },
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              width: 1.0,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required Color color, required Color textColor, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24)),
            ],
          ),
          Icon(icon, color: textColor.withValues(alpha: 0.5), size: 36),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'on time':
        bgColor = isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade100;
        textColor = isDark ? Colors.greenAccent : Colors.green.shade900;
        break;
      case 'approved':
        bgColor = theme.colorScheme.primary.withValues(alpha: 0.15);
        textColor = theme.colorScheme.primary;
        break;
      case 'late':
      case 'pending':
        bgColor = isDark ? Colors.amber.withValues(alpha: 0.2) : Colors.amber.shade100;
        textColor = isDark ? Colors.amberAccent : Colors.amber.shade900;
        break;
      case 'absent':
      case 'rejected':
        bgColor = isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade100;
        textColor = isDark ? Colors.redAccent : Colors.red.shade900;
        break;
      default:
        bgColor = isDark ? Colors.white12 : Colors.grey.shade100;
        textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ProfileAttendanceRecord {
  final String date;
  final String clockIn;
  final String clockOut;
  final String totalHours;
  final String status;

  ProfileAttendanceRecord({
    required this.date,
    required this.clockIn,
    required this.clockOut,
    required this.totalHours,
    required this.status,
  });
}

class LeaveBalanceItem {
  final String type;
  final int taken;
  final int total;

  LeaveBalanceItem({
    required this.type,
    required this.taken,
    required this.total,
  });
}

class ProfileLeaveRequestRecord {
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;

  ProfileLeaveRequestRecord({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });
}
