import 'package:flutter/material.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/features/employees/data/repositories/dummy_employee_repository.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/presentation/widgets/employee_card.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({Key? key}) : super(key: key);

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  final DummyEmployeeRepository _repository = DummyEmployeeRepository();
  List<Employee> _employees = [];
  bool _isLoading = true;
  String _selectedDepartment = 'All';

  final List<String> _departments = [
    'All',
    'Engineering',
    'Design',
    'Manager',
    'Marketing',
    'Finance',
    'HR',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await _repository.getEmployees(departmentFilter: _selectedDepartment);
      if (mounted) {
        setState(() {
          _employees = employees;
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
                    hintText: 'Search by name, role...',
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Employee'),
            ),
          ],
        ),
      ),
      drawer: const HrDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _departments.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    final isSelected = dept == _selectedDepartment;
                    return InkWell(
                      onTap: () => _onDepartmentSelected(dept),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : (isDark ? Colors.white12 : theme.colorScheme.surface),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dept,
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Total: ${_employees.length} Employees',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              // Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _employees.isEmpty
                        ? const Center(child: Text('No employees found.'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 2;
                              if (constraints.maxWidth > 1200) {
                                crossAxisCount = 5;
                              } else if (constraints.maxWidth > 900) {
                                crossAxisCount = 4;
                              } else if (constraints.maxWidth > 600) {
                                crossAxisCount = 3;
                              }
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: 0.75, // Adjust for card proportions
                                ),
                                itemCount: _employees.length,
                                itemBuilder: (context, index) {
                                  final employee = _employees[index];
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
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
