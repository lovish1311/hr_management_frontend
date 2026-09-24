import 'package:flutter/material.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/presentation/widgets/employee_card.dart';

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

  List<Employee> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) return _employees;
    final q = _searchQuery.toLowerCase().trim();
    return _employees.where((emp) {
      return emp.name.toLowerCase().contains(q) ||
          emp.role.toLowerCase().contains(q) ||
          emp.department.toLowerCase().contains(q) ||
          emp.designation.toLowerCase().contains(q);
    }).toList();
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
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Floating, snapping, hardware-accelerated top header bar
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: theme.scaffoldBackgroundColor,
              toolbarHeight: 0,
              expandedHeight: 168.0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                  color: theme.scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Sleek Search Bar & High-End Add Button
                      Row(
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
                                  hintText: 'Search by name, role, department...',
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
                                      : Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            '⌘ K',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                  suffixIconConstraints: const BoxConstraints(maxHeight: 32),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
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
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: const Text(
                                'Add Employee',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Department Filters Pill Carousel
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _departments.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final dept = _departments[index];
                            final isSelected = dept == _selectedDepartment;
                            return InkWell(
                              onTap: () => _onDepartmentSelected(dept),
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                  borderRadius: BorderRadius.circular(24),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dept,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Status Bar & Total Employee Count
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Active Directory',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '•',
                            style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Total: ${_filteredEmployees.length} Employees',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sliver Grid View for Employee Cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredEmployees.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No employees found.',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                        )
                      : SliverLayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            double crossSpacing = 10;
                            double mainSpacing = 10;
                            double childAspectRatio = 0.84;

                            if (constraints.crossAxisExtent > 1200) {
                              crossAxisCount = 5;
                              crossSpacing = 18;
                              mainSpacing = 18;
                              childAspectRatio = 0.88;
                            } else if (constraints.crossAxisExtent > 900) {
                              crossAxisCount = 4;
                              crossSpacing = 14;
                              mainSpacing = 14;
                              childAspectRatio = 0.88;
                            } else if (constraints.crossAxisExtent > 600) {
                              crossAxisCount = 3;
                              crossSpacing = 12;
                              mainSpacing = 12;
                              childAspectRatio = 0.86;
                            } else if (constraints.crossAxisExtent > 340) {
                              crossAxisCount = 2;
                              crossSpacing = 10;
                              mainSpacing = 10;
                              childAspectRatio = 0.84;
                            } else {
                              crossAxisCount = 1;
                              crossSpacing = 8;
                              mainSpacing = 8;
                              childAspectRatio = 2.2;
                            }

                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: crossSpacing,
                                mainAxisSpacing: mainSpacing,
                                childAspectRatio: childAspectRatio,
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
                                  );
                                },
                                childCount: _filteredEmployees.length,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
