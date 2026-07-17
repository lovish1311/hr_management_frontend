import 'package:flutter/material.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/features/employees/data/repositories/dummy_employee_repository.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({Key? key}) : super(key: key);

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final DummyEmployeeRepository _repository = DummyEmployeeRepository();
  Employee? _employee;
  bool _isLoading = true;

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
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
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
              backgroundColor: primaryColor.withOpacity(0.2),
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
    final isDark = theme.brightness == Brightness.dark;
    final avatarColor = _getAvatarColor(emp.name);
    final initials = emp.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();

    return Container(
      width: isWideScreen ? 300 : double.infinity,
      margin: const EdgeInsets.all(24.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            backgroundColor: avatarColor.withOpacity(0.12),
            child: Text(
              initials,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: avatarColor),
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
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 32),
          // Manager
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Direct Manager',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(emp.managerName, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: const Icon(Icons.person, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Contact Info
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactRow(context, 'Email', emp.email, Icons.email),
                const SizedBox(height: 16),
                _buildContactRow(context, 'Phone', emp.phone, Icons.phone),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Quick Links
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Links',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(height: 12),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
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
                const Center(child: Text('Attendance Details Placeholder')),
                const Center(child: Text('Leaves Details Placeholder')),
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
              Expanded(child: _buildReadOnlyField(context, 'Role', emp.role)), // Mockup had Role twice
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
          Row(
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(value, style: const TextStyle(fontSize: 14)),
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
          Icon(icon, color: textColor.withOpacity(0.5), size: 36),
        ],
      ),
    );
  }
}
