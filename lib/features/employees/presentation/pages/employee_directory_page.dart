import 'package:flutter/material.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/presentation/widgets/employee_card.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_form_page.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  final EmployeeRepository _repository = EmployeeRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();

  List<Employee> _employees = [];
  bool _isLoading = true;
  String _selectedDepartment = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final List<String> _departments = [
    'All',
    'Engineering',
    'Product',
    'Design',
    'Sales',
    'Marketing',
    'Operations',
    'Human Resources',
  ];

  final List<String> _statusFilters = [
    'All',
    'Active',
    'Probation',
    'Notice',
    'Inactive',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await _repository.getEmployees(departmentFilter: _selectedDepartment);
      if (mounted) {
        setState(() {
          _employees = employees.where((emp) {
            final r = emp.role.toUpperCase();
            return r != 'SUPER_ADMIN' && r != 'ROLE_SUPER_ADMIN' && r != 'ADMIN';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDepartmentSelected(String department) {
    setState(() {
      _selectedDepartment = department;
    });
    _fetchEmployees();
  }

  void _onStatusSelected(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  List<Employee> get _filteredEmployees {
    List<Employee> list = _employees;

    // Filter by Status
    if (_selectedStatus != 'All') {
      if (_selectedStatus == 'Active') {
        list = list.where((e) => e.status == 'ACTIVE' && !e.isProbation && !e.isNoticePeriod).toList();
      } else if (_selectedStatus == 'Probation') {
        list = list.where((e) => e.status == 'PROBATION' || e.isProbation).toList();
      } else if (_selectedStatus == 'Notice') {
        list = list.where((e) => e.status == 'NOTICE_PERIOD' || e.status == 'NOTICE' || e.isNoticePeriod).toList();
      } else if (_selectedStatus == 'Inactive') {
        list = list.where((e) => e.status == 'INACTIVE' || e.status == 'TERMINATED').toList();
      }
    }

    // Filter by Search Query
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((emp) {
      return emp.name.toLowerCase().contains(q) ||
          emp.role.toLowerCase().contains(q) ||
          emp.department.toLowerCase().contains(q) ||
          emp.designation.toLowerCase().contains(q) ||
          emp.employeeCode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openCreateEmployee() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EmployeeFormPage(isModal: true),
    );
    if (result == true) {
      _fetchEmployees();
    }
  }

  Future<void> _openEditEmployee(Employee employee) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeFormPage(initialEmployee: employee, isModal: true),
    );
    if (result == true) {
      _fetchEmployees();
    }
  }

  Future<void> _toggleEmployeeStatus(Employee employee, String newStatus) async {
    final success = await _repository.toggleEmployeeStatus(employee.id, newStatus);
    if (success) {
      _fetchEmployees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'INACTIVE' ? Icons.block_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('${employee.name} status updated to $newStatus'),
              ],
            ),
            backgroundColor: newStatus == 'INACTIVE' ? Colors.red.shade700 : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
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
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Floating Top Header Bar
            // Top filter and search header that scrolls cleanly off-screen without any jitter
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Search Bar & High-End Add Button
                    LayoutBuilder(
                      builder: (context, headerConstraints) {
                        final isNarrow = headerConstraints.maxWidth < 360;
                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : primaryColor.withValues(alpha: 0.2),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                  style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search by name, role, department, code...',
                                    hintStyle: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
                                      fontSize: 13.5,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.search_rounded, color: primaryColor, size: 18),
                                      ),
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.cancel_rounded, size: 18, color: theme.hintColor),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor,
                                    Color.lerp(primaryColor, Colors.tealAccent, 0.25) ?? primaryColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: isNarrow
                                  ? IconButton(
                                      tooltip: 'Add Employee',
                                      icon: const Icon(Icons.person_add_rounded, size: 20, color: Colors.white),
                                      onPressed: _openCreateEmployee,
                                    )
                                  : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                      ),
                                      onPressed: _openCreateEmployee,
                                      icon: const Icon(Icons.person_add_rounded, size: 18),
                                      label: const Text(
                                        'Add Employee',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Department Filters Pill Carousel
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _departments.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final dept = _departments[index];
                          final isSelected = dept == _selectedDepartment;
                          return InkWell(
                            onTap: () => _onDepartmentSelected(dept),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                                        width: 1.0,
                                      ),
                              ),
                              child: Text(
                                dept,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Lifecycle Status Filter Pills
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusFilters.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = _statusFilters[index];
                          final isSelected = status == _selectedStatus;

                          Color activeColor = primaryColor;
                          if (status == 'Probation') activeColor = const Color(0xFFD97706);
                          if (status == 'Notice') activeColor = const Color(0xFF7C3AED);
                          if (status == 'Inactive') activeColor = const Color(0xFF64748B);

                          return InkWell(
                            onTap: () => _onStatusSelected(status),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor
                                    : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : (isDark ? Colors.white10 : Colors.grey.shade300),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status == 'Probation')
                                    Icon(Icons.timer_outlined, size: 12, color: isSelected ? Colors.white : const Color(0xFFD97706)),
                                  if (status == 'Notice')
                                    Icon(Icons.exit_to_app_rounded, size: 12, color: isSelected ? Colors.white : const Color(0xFF7C3AED)),
                                  if (status == 'Inactive')
                                    Icon(Icons.block_rounded, size: 12, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                                  if (status != 'All' && status != 'Active')
                                    const SizedBox(width: 4),
                                  Text(
                                    status == 'All' ? 'All Statuses' : status,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color,
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Results counter bar
                    Text(
                      'Showing  employees',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredEmployees.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 48, color: theme.disabledColor),
                                const SizedBox(height: 12),
                                Text(
                                  'No employees found matching criteria.',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 480,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: (180.0 + (MediaQuery.textScalerOf(context).scale(1.0) - 1.0) * 120).clamp(180.0, 320.0),
                          ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final employee = _filteredEmployees[index];
                                  return EmployeeCard(
                                    employee: employee,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/employee_profile',
                                        arguments: employee.id,
                                      );
                                    },
                                    onEdit: () => _openEditEmployee(employee),
                                    onStatusChanged: (newStatus) => _toggleEmployeeStatus(employee, newStatus),
                                  );
                                },
                                childCount: _filteredEmployees.length,
                                ),
                              ),
              ),
          ],
        ),
      ),
    );
  }
}
