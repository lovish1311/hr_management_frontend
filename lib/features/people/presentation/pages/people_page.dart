import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  String _selectedView = 'Directory'; // 'Directory' or 'Org Chart'
  String _directoryTab = 'Everyone'; // 'Starred' or 'Everyone'
  String _searchQuery = '';

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  final List<Employee> _directoryEmployees = [];
  final Set<String> _starredEmployeeIds = {};
  Employee? _selectedEmployee;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    _fetchStarredPeers();
    _fetchEmployeesPage(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMorePages && _directoryTab == 'Everyone') {
        _fetchEmployeesPage(reset: false);
      }
    }
  }

  Future<void> _fetchStarredPeers() async {
    final empId = AuthStorage.employeeId ?? 1;
    final url = Uri.parse('$_baseUrl/api/v1/employees/starred?starrerId=$empId');
    try {
      final res = await http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        if (mounted) {
          setState(() {
            _starredEmployeeIds.clear();
            _starredEmployeeIds.addAll(list.map((id) => id.toString()));
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching starred peers: $e');
    }
  }

  Future<void> _fetchEmployeesPage({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _hasMorePages = true;
        _isLoadingInitial = true;
        _directoryEmployees.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final queryParam = _searchQuery.trim().isNotEmpty ? '&query=${Uri.encodeComponent(_searchQuery.trim())}' : '';
    final url = Uri.parse('$_baseUrl/api/v1/employees/search?page=$_currentPage&size=$_pageSize$queryParam');

    try {
      final res = await http.get(url, headers: AuthStorage.authHeaders);
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        final List<dynamic> content = data['content'] ?? [];
        final isLast = data['last'] as bool? ?? true;

        final newEmps = content.map((item) => Employee.fromJson(item)).toList();

        if (mounted) {
          setState(() {
            _directoryEmployees.addAll(newEmps);
            _hasMorePages = !isLast;
            _currentPage++;
            if (_selectedEmployee == null && _directoryEmployees.isNotEmpty) {
              _selectedEmployee = _directoryEmployees.first;
            }
            _isLoadingInitial = false;
            _isLoadingMore = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingInitial = false;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching employee page: $e');
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleStar(Employee emp) async {
    final empId = AuthStorage.employeeId ?? 1;
    final url = Uri.parse('$_baseUrl/api/v1/employees/starred/${emp.id}?starrerId=$empId');

    // Optimistic UI update
    final wasStarred = _starredEmployeeIds.contains(emp.id);
    setState(() {
      if (wasStarred) {
        _starredEmployeeIds.remove(emp.id);
      } else {
        _starredEmployeeIds.add(emp.id);
      }
    });

    try {
      final res = await http.post(url, headers: AuthStorage.authHeaders);
      if (res.statusCode != 200) {
        // Revert on failure
        setState(() {
          if (wasStarred) {
            _starredEmployeeIds.add(emp.id);
          } else {
            _starredEmployeeIds.remove(emp.id);
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling star status in backend DB: $e');
    }
  }

  List<Employee> get _filteredEmployees {
    if (_directoryTab == 'Starred') {
      return _directoryEmployees.where((e) => _starredEmployeeIds.contains(e.id)).toList();
    }
    return _directoryEmployees;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return ResponsiveScaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        title: Text(
          'People',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          // Top Center View Switcher (Directory vs Org Chart)
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildViewTabButton('Directory', isDark),
                  _buildViewTabButton('Org Chart', isDark),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : (_selectedView == 'Directory'
              ? _buildDirectoryView(isDark, isDesktop)
              : _buildDynamicOrgChartView(isDark, isDesktop)),
    );
  }

  Widget _buildViewTabButton(String title, bool isDark) {
    final isSelected = _selectedView == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // ================= DIRECTORY VIEW =================
  Widget _buildDirectoryView(bool isDark, bool isDesktop) {
    return Column(
      children: [
        // Sub Tabs (Starred vs Everyone)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildSubTab('Starred', isDark),
                const SizedBox(width: 24),
                _buildSubTab('Everyone', isDark),
              ],
            ),
          ),
        ),

        // Content Body
        Expanded(
          child: isDesktop
              ? Row(
                  children: [
                    // Left Pane - Employee List (Fixed width 340)
                    SizedBox(
                      width: 340,
                      child: _buildEmployeeListPane(isDark),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    // Right Pane - Peer Detail View
                    Expanded(
                      child: _buildEmployeeDetailPane(isDark, isDesktop),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: _buildEmployeeListPane(isDark),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubTab(String title, bool isDark) {
    final isSelected = _directoryTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _directoryTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF0284C7)
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeListPane(bool isDark) {
    final employees = _filteredEmployees;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          // Search & Filter Box (Matching Screenshot Header)
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      onChanged: (v) {
                        _searchQuery = v;
                        _fetchEmployeesPage(reset: true);
                      },
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter Emp. Name or ID',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(Icons.tune_rounded, size: 20, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Infinite Scroll List View
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Text(
                      _directoryTab == 'Starred'
                          ? 'Looks like you don\'t have any records'
                          : 'No matching employees found',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: employees.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                    itemBuilder: (context, index) {
                      if (index == employees.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }

                      final emp = employees[index];
                      final isSelected = _selectedEmployee?.id == emp.id;
                      final isStarred = _starredEmployeeIds.contains(emp.id);

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF0D9488),
                          child: Text(
                            emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : 'E',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              '${emp.firstName} ${emp.lastName}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(#${emp.employeeCode})',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        trailing: isStarred
                            ? const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedEmployee = emp;
                          });

                          if (MediaQuery.of(context).size.width < 900) {
                            _showMobileEmployeeSheet(context, emp, isDark);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetailPane(bool isDark, bool isDesktop) {
    if (_directoryTab == 'Starred' && _filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_outline_rounded, size: 54, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hey, you haven\'t starred any peers!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final emp = _selectedEmployee;
    if (emp == null) {
      return const Center(child: Text('Select an employee from the directory'));
    }

    final isStarred = _starredEmployeeIds.contains(emp.id);

    return Container(
      padding: const EdgeInsets.all(28.0),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF64748B),
                  child: Icon(Icons.person, size: 50, color: isDark ? const Color(0xFF1E293B) : Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${emp.firstName} ${emp.lastName}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isStarred ? const Color(0xFFF59E0B) : Colors.grey,
                            ),
                            onPressed: () => _toggleStar(emp),
                          ),
                        ],
                      ),
                      Text(
                        '#${emp.employeeCode}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // CONTACT DETAILS Section
            _buildSectionTitle('CONTACT DETAILS', isDark),
            const SizedBox(height: 12),
            _buildDetailRow('Extension No', '-', isDark),
            _buildDetailRow('Email', emp.email, isDark),
            _buildDetailRow('Phone', emp.phone.isNotEmpty ? emp.phone : '-', isDark),
            const SizedBox(height: 24),

            // CATEGORY Section
            _buildSectionTitle('CATEGORY', isDark),
            const SizedBox(height: 12),
            _buildDetailRow('Location', emp.location.isNotEmpty ? emp.location : 'Zirakpur', isDark),
            _buildDetailRow('Department', emp.department, isDark),
            _buildDetailRow('Designation', emp.designation, isDark),
            const SizedBox(height: 24),

            // OTHER INFORMATION Section
            _buildSectionTitle('OTHER INFORMATION', isDark),
            const SizedBox(height: 12),
            _buildDetailRow('Joining Date', emp.joiningDate.isNotEmpty ? emp.joiningDate : '26 May, 2025', isDark),
            _buildDetailRow('Date Of Birth', emp.dateOfBirth.isNotEmpty ? emp.dateOfBirth : '-', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileEmployeeSheet(BuildContext context, Employee emp, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: _buildEmployeeDetailPane(isDark, false),
      ),
    );
  }

  // ================= DYNAMIC MANAGER ORG CHART VIEW =================
  Widget _buildDynamicOrgChartView(bool isDark, bool isDesktop) {
    // 1. Group employees by manager
    final Map<String, List<Employee>> managerGroups = {};
    for (var emp in _directoryEmployees) {
      final mgrName = (emp.managerName.isNotEmpty && emp.managerName != 'Unassigned')
          ? emp.managerName
          : 'Aadisha Dhullar (HR Admin)';
      managerGroups.putIfAbsent(mgrName, () => []).add(emp);
    }

    return Stack(
      children: [
        Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          child: Column(
            children: [
              // Search Input Top Left
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 240,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Text('Search', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          Spacer(),
                          Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Hierarchy Tree Canvas
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(500),
                  minScale: 0.5,
                  maxScale: 2.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Root Executive Node (Ankesh Verma / Director)
                        _buildOrgNode(
                          name: 'Ankesh Verma',
                          role: 'Director',
                          code: 'Emp ID - GSS-001',
                          isRoot: true,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 30),
                        Container(width: 30, height: 2, color: const Color(0xFFCBD5E1)),
                        const SizedBox(width: 30),

                        // Manager Columns & Assigned Employees
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: managerGroups.entries.map((entry) {
                            final managerName = entry.key;
                            final reportees = entry.value;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                children: [
                                  // Manager Node
                                  _buildOrgNode(
                                    name: managerName,
                                    role: 'Manager / Lead',
                                    code: 'Manager Node',
                                    isRoot: false,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 20),
                                  Container(width: 20, height: 2, color: const Color(0xFFCBD5E1)),
                                  const SizedBox(width: 20),

                                  // Reportees List under Manager
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: reportees.map((emp) {
                                      return _buildOrgNode(
                                        name: '${emp.firstName} ${emp.lastName}',
                                        role: emp.designation.isNotEmpty ? emp.designation : emp.role,
                                        code: 'Emp ID - ${emp.employeeCode}',
                                        isRoot: false,
                                        isDark: isDark,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Zoom Controls Bottom Right
        Positioned(
          right: 20,
          bottom: 20,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(icon: const Icon(Icons.fullscreen_rounded, size: 20), onPressed: () {}),
                const Divider(height: 1),
                IconButton(icon: const Icon(Icons.aspect_ratio_rounded, size: 20), onPressed: () {}),
                const Divider(height: 1),
                IconButton(icon: const Icon(Icons.add_rounded, size: 20), onPressed: () {}),
                const Divider(height: 1),
                IconButton(icon: const Icon(Icons.remove_rounded, size: 20), onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrgNode({
    required String name,
    required String role,
    required String code,
    required bool isRoot,
    required bool isDark,
  }) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRoot
            ? (isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF))
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRoot ? const Color(0xFF6366F1) : const Color(0xFF38BDF8),
          width: isRoot ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isRoot ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  code,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
