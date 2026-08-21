import 'package:flutter/material.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final EmployeeRepository _repository = EmployeeRepositoryImpl();
  Employee? _employee;
  bool _isLoading = true;
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

  Future<void> _fetchEmployee(String id) async {
    try {
      final emp = await _repository.getEmployeeById(id);
      if (mounted) {
        setState(() {
          _employee = emp;
          _isLoading = false;
          
          // Seed realistic data for the employee details tabs
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
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getAvatarColor(String name) {
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.deepOrange,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
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
      drawer: const HrDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _employee == null
                ? const Center(child: Text('Employee not found.'))
                : DefaultTabController(
                    length: 4,
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
    final avatarColor = _getAvatarColor(emp.name);

    return Container(
      width: isWideScreen ? 300 : double.infinity,
      margin: const EdgeInsets.all(24.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: avatarColor.withValues(alpha: 0.12),
            backgroundImage: NetworkImage(
              'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(emp.name)}',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            emp.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${emp.role} | ${emp.department}',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 24),
          // Manager
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Direct Manager',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(emp.managerName, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Contact Info
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactRow(context, 'Email', emp.email, Icons.email),
                const SizedBox(height: 12),
                _buildContactRow(context, 'Phone', emp.phone, Icons.phone),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick Links
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Links',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Edit Profile', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Emergency Info', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
          ),
        ],
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
              Tab(text: 'Performance'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              children: [
                _buildProfileDetailsTab(context, emp),
                _buildAttendanceTab(context),
                _buildLeavesTab(context),
                const Center(child: Text('Performance Details Placeholder')),
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
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final cards = [
                _buildSummaryCardMetric(context, 'Total Days Present', '22 Days', Icons.check_circle_outline),
                _buildSummaryCardMetric(context, 'Average Work Hours', '8.4 hrs', Icons.access_time),
                _buildSummaryCardMetric(context, 'Late Arrivals', '3 Times', Icons.warning_amber_rounded),
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
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Select Date Range', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'All',
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'On Time', child: Text('On Time')),
                      DropdownMenuItem(value: 'Late', child: Text('Late')),
                      DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                    ],
                    onChanged: (val) {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAttendanceTable(context, _attendanceRecords),
        ],
      ),
    );
  }

  Widget _buildSummaryCardMetric(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
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
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
