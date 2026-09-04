import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/core/widgets/animated_gradient_border.dart';

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

  List<Employee> get _filteredEmployees {
    if (_directoryTab == 'Starred') {
      return _directoryEmployees.where((e) => _starredEmployeeIds.contains(e.id)).toList();
    }
    if (_searchQuery.trim().isEmpty) {
      return _directoryEmployees;
    }
    final q = _searchQuery.toLowerCase();
    return _directoryEmployees.where((e) {
      final name = '${e.firstName} ${e.lastName}'.toLowerCase();
      final code = e.employeeCode.toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        title: Text(
          'People Directory',
          style: TextStyle(
            color: t.onBackgroundText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: t.card.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
                boxShadow: [BoxShadow(color: t.glow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  _buildViewTabButton('Directory', t),
                  _buildViewTabButton('Org Chart', t),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: t.onBackgroundTextSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new_rounded, color: t.onBackgroundTextSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoadingInitial
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : (_selectedView == 'Directory'
              ? _buildDirectoryView(t, isDesktop)
              : _buildDynamicOrgChartView(t, isDesktop)),
    );
  }

  Widget _buildViewTabButton(String title, AppThemeConfig t) {
    final isSelected = _selectedView == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedView = title;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? t.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : t.text,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryView(AppThemeConfig t, bool isDesktop) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: t.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
            boxShadow: [BoxShadow(color: t.glow, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubTab('Starred', t),
              const SizedBox(width: 8),
              _buildSubTab('Everyone', t),
            ],
          ),
        ),
        Expanded(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 10, bottom: 20, top: 4),
                        child: _buildEmployeeListPane(t),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 20, bottom: 20, top: 4),
                        child: _buildEmployeeDetailPane(t, isDesktop),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildEmployeeListPane(t),
                ),
        ),
      ],
    );
  }

  Widget _buildSubTab(String title, AppThemeConfig t) {
    final isSelected = _directoryTab == title;
    return InkWell(
      onTap: () {
        setState(() {
          _directoryTab = title;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? t.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: t.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Icon(
              title == 'Starred' ? Icons.star_rounded : Icons.people_alt_rounded,
              size: 16,
              color: isSelected ? t.primary : t.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? t.primary : t.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeListPane(AppThemeConfig t) {
    final employees = _filteredEmployees;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: t.glow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: t.cardSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: TextField(
                      onChanged: (v) {
                        setState(() {
                          _searchQuery = v;
                        });
                      },
                      style: TextStyle(fontSize: 13, color: t.text),
                      decoration: InputDecoration(
                        hintText: 'Enter Emp. Name or ID',
                        hintStyle: TextStyle(fontSize: 12, color: t.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: t.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Icon(Icons.tune_rounded, size: 20, color: t.primary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: t.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _directoryTab == 'Starred'
                              ? 'No starred peers found'
                              : 'No matching employees found',
                          style: TextStyle(fontSize: 13, color: t.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: employees.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == employees.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: t.primary)),
                        );
                      }
                      final emp = employees[index];
                      final isSelected = _selectedEmployee?.id == emp.id;
                      final isStarred = _starredEmployeeIds.contains(emp.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _EmployeeListTile(
                          emp: emp,
                          isSelected: isSelected,
                          isStarred: isStarred,
                          t: t,
                          onTap: () {
                            setState(() {
                              _selectedEmployee = emp;
                            });
                            if (MediaQuery.of(context).size.width < 900) {
                              _showMobileEmployeeSheet(context, emp, t);
                            }
                          },
                          onStarToggle: () => _toggleStar(emp),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetailPane(AppThemeConfig t, bool isDesktop) {
    if (_directoryTab == 'Starred' && _filteredEmployees.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: t.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star_outline_rounded, size: 54, color: t.warning),
              ),
              const SizedBox(height: 16),
              Text(
                'Hey, you haven\'t starred any peers!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text),
              ),
              const SizedBox(height: 6),
              Text(
                'Star your frequent collaborators for quick access.',
                style: TextStyle(fontSize: 13, color: t.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    final emp = _selectedEmployee;
    if (emp == null) {
      return Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border),
        ),
        child: Center(
          child: Text('Select an employee from the directory', style: TextStyle(color: t.textSecondary)),
        ),
      );
    }
    final isStarred = _starredEmployeeIds.contains(emp.id);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: t.glow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [t.primaryDark, t.primary, t.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: t.glow, blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : 'E',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: t.primaryDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${emp.firstName} ${emp.lastName}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: isStarred ? const Color(0xFFFACC15) : Colors.white70,
                                    size: 26,
                                  ),
                                  onPressed: () => _toggleStar(emp),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    emp.designation,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code: #${emp.employeeCode}',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _quickActionButton(
                          icon: Icons.email_rounded,
                          label: 'Send Email',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening mail client for ${emp.email}...')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Call Direct',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${emp.phone.isNotEmpty ? emp.phone : "extension"}...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildSectionHeaderCard(
              t: t,
              icon: Icons.contact_phone_rounded,
              title: 'CONTACT DETAILS',
              children: [
                _buildInfoTile(t, 'Extension No', emp.employeeCode.isNotEmpty ? 'Ext. ${emp.employeeCode}' : '-'),
                _buildInfoTile(t, 'Email Address', emp.email),
                _buildInfoTile(t, 'Phone Number', emp.phone.isNotEmpty ? emp.phone : '+91 98123 45228'),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionHeaderCard(
              t: t,
              icon: Icons.business_center_rounded,
              title: 'CATEGORY & ORGANIZATION',
              children: [
                _buildInfoTile(t, 'Work Location', emp.location.isNotEmpty ? emp.location : 'Headquarters'),
                _buildInfoTile(t, 'Department', emp.department),
                _buildInfoTile(t, 'Designation', emp.designation),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionHeaderCard(
              t: t,
              icon: Icons.info_outline_rounded,
              title: 'EMPLOYMENT INFORMATION',
              children: [
                _buildInfoTile(t, 'Joining Date', emp.joiningDate.isNotEmpty ? emp.joiningDate : '2024-01-15'),
                _buildInfoTile(t, 'Date Of Birth', emp.dateOfBirth.isNotEmpty ? emp.dateOfBirth : '1995-08-14'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderCard({
    required AppThemeConfig t,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: t.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: t.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: t.border),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(AppThemeConfig t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
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

  void _showMobileEmployeeSheet(BuildContext context, Employee emp, AppThemeConfig t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.88;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          margin: const EdgeInsets.all(12),
          child: _buildEmployeeDetailPane(t, false),
        );
      },
    );
  }

  Widget _buildDynamicOrgChartView(AppThemeConfig t, bool isDesktop) {
    final Map<String, List<Employee>> managerGroups = {};
    for (var emp in _directoryEmployees) {
      final mgrName = (emp.managerName.isNotEmpty && emp.managerName != 'Unassigned')
          ? emp.managerName
          : 'HR Admin';
      managerGroups.putIfAbsent(mgrName, () => []).add(emp);
    }

    return Stack(
      children: [
        InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.2,
          maxScale: 2.5,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Root Executive Node
                      _buildOrgNode(
                        t: t,
                        name: 'Ankesh Verma',
                        role: 'Director',
                        code: 'Emp ID - GSS-001',
                        isRoot: true,
                      ),
                      const SizedBox(width: 30),
                      Container(width: 30, height: 2, color: t.border),
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
                                  t: t,
                                  name: managerName,
                                  role: 'Manager / Lead',
                                  code: 'Manager Node',
                                  isRoot: false,
                                ),
                                const SizedBox(width: 20),
                                Container(width: 20, height: 2, color: t.border),
                                const SizedBox(width: 20),

                                // Reportees List under Manager
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: reportees.map((emp) {
                                    return _buildOrgNode(
                                      t: t,
                                      name: '${emp.firstName} ${emp.lastName}',
                                      role: emp.designation.isNotEmpty ? emp.designation : emp.role,
                                      code: 'Emp ID - ${emp.employeeCode}',
                                      isRoot: false,
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
          ),
        ),

        // Zoom Controls Bottom Right
        Positioned(
          right: 20,
          bottom: 20,
          child: Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(icon: Icon(Icons.fullscreen_rounded, size: 20, color: t.text), onPressed: () {}),
                Divider(height: 1, color: t.border),
                IconButton(icon: Icon(Icons.aspect_ratio_rounded, size: 20, color: t.text), onPressed: () {}),
                Divider(height: 1, color: t.border),
                IconButton(icon: Icon(Icons.add_rounded, size: 20, color: t.text), onPressed: () {}),
                Divider(height: 1, color: t.border),
                IconButton(icon: Icon(Icons.remove_rounded, size: 20, color: t.text), onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrgNode({
    required AppThemeConfig t,
    required String name,
    required String role,
    required String code,
    required bool isRoot,
  }) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRoot
            ? t.primary.withValues(alpha: 0.15)
            : t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRoot ? t.primary : t.border,
          width: isRoot ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: t.glow,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isRoot ? t.primary : t.primary.withValues(alpha: 0.2),
            child: Icon(Icons.person, size: 20, color: isRoot ? Colors.white : t.primary),
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
                    color: t.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: TextStyle(fontSize: 10, color: t.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  code,
                  style: TextStyle(fontSize: 9, color: t.textSecondary.withValues(alpha: 0.7)),
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

class _EmployeeListTile extends StatefulWidget {
  final Employee emp;
  final bool isSelected;
  final bool isStarred;
  final AppThemeConfig t;
  final VoidCallback onTap;
  final VoidCallback onStarToggle;

  const _EmployeeListTile({
    super.key,
    required this.emp,
    required this.isSelected,
    required this.isStarred,
    required this.t,
    required this.onTap,
    required this.onStarToggle,
  });

  @override
  State<_EmployeeListTile> createState() => _EmployeeListTileState();
}

class _EmployeeListTileState extends State<_EmployeeListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final emp = widget.emp;
    final isDesktop = kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    Widget cardChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isSelected ? t.primary.withValues(alpha: 0.08) : t.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: widget.isSelected
            ? Border.all(color: t.primary.withValues(alpha: 0.3))
            : Border.all(color: t.border),
        boxShadow: [
          if (_isHovered)
            BoxShadow(
              color: t.glow.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: t.primary.withValues(alpha: 0.15),
            child: Text(
              emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : 'E',
              style: TextStyle(fontWeight: FontWeight.bold, color: t.primary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${emp.firstName} ${emp.lastName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: t.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  emp.designation.isNotEmpty ? emp.designation : emp.role,
                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
              color: widget.isStarred ? const Color(0xFFF59E0B) : t.textSecondary,
              size: 20,
            ),
            onPressed: widget.onStarToggle,
          ),
        ],
      ),
    );

    if (widget.isSelected) {
      cardChild = AnimatedGradientBorder(
        borderRadius: 16.0,
        borderWidth: 2.0,
        borderColors: [
          t.primary,
          t.secondary,
          t.accent,
          t.primary,
        ],
        child: cardChild,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered && isDesktop ? -3.0 : 0.0, 0.0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: cardChild,
        ),
      ),
    );
  }
}


