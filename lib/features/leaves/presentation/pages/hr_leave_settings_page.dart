import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class HrLeaveSettingsPage extends StatefulWidget {
  const HrLeaveSettingsPage({super.key});

  @override
  State<HrLeaveSettingsPage> createState() => _HrLeaveSettingsPageState();
}

class _HrLeaveSettingsPageState extends State<HrLeaveSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EmployeeRepositoryImpl _employeeRepository = EmployeeRepositoryImpl();

  List<Employee> _employees = [];
  bool _isLoadingEmployees = true;

  // Section 1: Bulk Grant state
  String _selectedCycle = 'Quarterly';
  String _selectedLeaveType = 'Casual Leave';
  double _grantDays = 3.0;
  final List<Employee> _excludedEmployees = [];

  // Section 2: Employee Direct Override & Staged Quota Edit state
  Employee? _selectedEmployee;
  String _searchQuery = '';
  final TextEditingController _onBehalfReasonController = TextEditingController();
  DateTime _onBehalfStartDate = DateTime.now();
  DateTime _onBehalfEndDate = DateTime.now();
  String _onBehalfLeaveType = 'Casual Leave';

  final List<String> _cycles = ['Quarterly', 'Half-Yearly', 'Yearly'];
  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Work From Home',
    'Comp-Off',
    'Birthday Leave',
    'Bereavement Leave',
    'Paternity Leave',
  ];

  final Map<String, double> _selectedEmployeeQuotas = {
    'Casual Leave': 12.0,
    'Sick Leave': 10.0,
    'Earned Leave': 15.0,
    'Work From Home': 0.0,
    'Comp-Off': 2.0,
    'Birthday Leave': 1.0,
  };

  // Staged pending adjustments: tracks leaveType -> delta (+2.0, -1.0)
  final Map<String, double> _pendingQuotaDeltas = {};

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final list = await _employeeRepository.getEmployees();
      if (mounted) {
        setState(() {
          _employees = list;
          if (_employees.isNotEmpty) {
            _selectedEmployee = _employees.first;
          }
          _isLoadingEmployees = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _onBehalfReasonController.dispose();
    super.dispose();
  }

  Future<void> _executeBulkGrant() async {
    final payload = {
      'leaveType': _selectedLeaveType.toUpperCase().replaceAll(' ', '_'),
      'grantDays': _grantDays.toInt(),
      'frequency': _selectedCycle,
      'excludedEmployeeIds': _excludedEmployees.map((e) => int.tryParse(e.id) ?? 0).toList(),
    };

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/v1/leaves/admin/bulk-grant'),
        headers: AuthStorage.authHeaders,
        body: json.encode(payload),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully granted $_grantDays day(s) of $_selectedLeaveType to all employees (${_excludedEmployees.length} excluded).'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _applyOnBehalf() async {
    if (_selectedEmployee == null) return;

    final startStr = '${_onBehalfStartDate.year}-${_onBehalfStartDate.month.toString().padLeft(2, '0')}-${_onBehalfStartDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_onBehalfEndDate.year}-${_onBehalfEndDate.month.toString().padLeft(2, '0')}-${_onBehalfEndDate.day.toString().padLeft(2, '0')}';

    final payload = {
      'employeeId': int.tryParse(_selectedEmployee!.id) ?? 1,
      'startDate': startStr,
      'endDate': endStr,
      'leaveType': _onBehalfLeaveType.toUpperCase().replaceAll(' ', '_'),
      'reason': _onBehalfReasonController.text.isEmpty ? 'HR Direct Application' : _onBehalfReasonController.text,
    };

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/v1/leaves/admin/apply-on-behalf'),
        headers: AuthStorage.authHeaders,
        body: json.encode(payload),
      );
    } catch (_) {}

    if (!mounted) return;
    _onBehalfReasonController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave applied on behalf of ${_selectedEmployee!.name}! Date check bypassed.'),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  // Stages quota adjustment locally (+ / -) to prevent accidental misclicks
  void _stageQuotaAdjustment(String type, double delta) {
    setState(() {
      final currentDelta = _pendingQuotaDeltas[type] ?? 0.0;
      final newDelta = currentDelta + delta;
      if (newDelta == 0.0) {
        _pendingQuotaDeltas.remove(type);
      } else {
        _pendingQuotaDeltas[type] = newDelta;
      }
    });
  }

  // Opens structured confirmation modal showing exact details of planned additions/deductions
  void _showConfirmAdjustmentsModal() {
    if (_selectedEmployee == null || _pendingQuotaDeltas.isEmpty) return;

    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF3B82F6), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Confirm Leave Balance Edits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Review changes for ${_selectedEmployee!.name} before saving to database.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  const Text('Summary of Planned Adjustments:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: _pendingQuotaDeltas.entries.map((entry) {
                        final leaveType = entry.key;
                        final delta = entry.value;
                        final base = _selectedEmployeeQuotas[leaveType] ?? 10.0;
                        final updated = base + delta;
                        final isAddition = delta > 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Icon(
                                isAddition ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                                color: isAddition ? const Color(0xFF10B981) : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$leaveType: ${isAddition ? "Addition of +$delta" : "Deduction of $delta"} day(s)',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isAddition ? const Color(0xFF10B981) : Colors.red).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'New Balance: $updated Days',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAddition ? const Color(0xFF10B981) : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'HR Audit Note / Reason (Optional)',
                      hintText: 'e.g. Performance credit / Policy adjustment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel & Edit'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _commitQuotaAdjustments();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Confirm & Save Updates', style: TextStyle(fontWeight: FontWeight.bold)),
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
  }

  // Commits staged changes to backend database
  Future<void> _commitQuotaAdjustments() async {
    if (_selectedEmployee == null || _pendingQuotaDeltas.isEmpty) return;

    final empId = int.tryParse(_selectedEmployee!.id) ?? 1;

    for (var entry in _pendingQuotaDeltas.entries) {
      final type = entry.key;
      final delta = entry.value;

      setState(() {
        final current = _selectedEmployeeQuotas[type] ?? 10.0;
        _selectedEmployeeQuotas[type] = (current + delta).clamp(0.0, 999.0);
      });

      try {
        await http.post(
          Uri.parse('$_baseUrl/api/v1/leaves/admin/adjust-balance'),
          headers: AuthStorage.authHeaders,
          body: json.encode({
            'employeeId': empId,
            'leaveType': type.toUpperCase().replaceAll(' ', '_'),
            'adjustmentDays': delta.toInt(),
          }),
        );
      } catch (_) {}
    }

    setState(() {
      _pendingQuotaDeltas.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated leave balances for ${_selectedEmployee!.name}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Company Leave Policy & Quotas', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0D9488),
          labelColor: const Color(0xFF0D9488),
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          tabs: const [
            Tab(icon: Icon(Icons.tune_rounded), text: '1. Company-Wide Leave Allocation'),
            Tab(icon: Icon(Icons.person_pin_rounded), text: '2. Individual Employee Leave Management'),
          ],
        ),
      ),
      drawer: const HrDrawer(),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSection1BulkGrants(isDark),
            _buildSection2EmployeeOverrides(isDark),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: Organization Bulk Grants & Exclusions
  // ---------------------------------------------------------------------------
  Widget _buildSection1BulkGrants(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Company-Wide Annual & Quarterly Leave Distribution',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Allocate standard leave balances to all team members across the organization. Easily exclude employees currently on probation or notice period.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Select Grant Frequency
                    const Text('Step 1: Select Allocation Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: _cycles.map((cycle) {
                        final isSelected = _selectedCycle == cycle;
                        return ChoiceChip(
                          label: Text(cycle, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0D9488),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCycle = cycle);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Step 2: Select Leave Type & Quantity
                    const Text('Step 2: Select Leave Category & Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _leaveTypes.map((type) {
                        final isSelected = _selectedLeaveType == type;
                        return FilterChip(
                          label: Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0D9488),
                          onSelected: (val) {
                            if (val) setState(() => _selectedLeaveType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Allocation Days to Grant:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF0D9488)),
                          onPressed: () {
                            if (_grantDays > 0.5) setState(() => _grantDays -= 0.5);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_grantDays Days',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0D9488)),
                          onPressed: () {
                            setState(() => _grantDays += 0.5);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Step 3: Exclusions Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Step 3: Employee Exclusions (Probation / Notice Period)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_excludedEmployees.length} Excluded',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Selected employees will be skipped and will not receive this allocation grant.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),

                    if (_isLoadingEmployees)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _employees.map((emp) {
                              final isExcluded = _excludedEmployees.contains(emp);
                              return FilterChip(
                                avatar: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isExcluded ? Colors.red : const Color(0xFF0D9488),
                                  child: Text(emp.name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                label: Text(emp.name, style: TextStyle(fontSize: 12, color: isExcluded ? Colors.red : null)),
                                selected: isExcluded,
                                selectedColor: Colors.red.withValues(alpha: 0.15),
                                checkmarkColor: Colors.red,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _excludedEmployees.add(emp);
                                    } else {
                                      _excludedEmployees.remove(emp);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _executeBulkGrant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                        label: Text(
                          'Distribute $_grantDays Days of $_selectedLeaveType to Active Employees',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: Employee Direct Overrides & Unrestricted Leave Applications
  // ---------------------------------------------------------------------------
  Widget _buildSection2EmployeeOverrides(bool isDark) {
    final filtered = _employees.where((e) {
      final q = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(q) || e.email.toLowerCase().contains(q) || e.department.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 340,
                      child: _buildEmployeeRosterList(filtered, isDark),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _selectedEmployee == null
                          ? const Center(child: Text('Select an employee to manage leaves.'))
                          : _buildEmployeeManagementPanel(_selectedEmployee!, isDark),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: _buildEmployeeRosterList(filtered, isDark),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedEmployee != null) _buildEmployeeManagementPanel(_selectedEmployee!, isDark),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmployeeRosterList(List<Employee> list, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search employee...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No employees found.', style: TextStyle(fontSize: 13, color: Colors.grey)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final emp = list[index];
                      final isSelected = _selectedEmployee?.id == emp.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          child: Text(emp.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                        ),
                        title: Text(emp.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('${emp.role} • ${emp.department}', style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          setState(() {
                            _selectedEmployee = emp;
                            _pendingQuotaDeltas.clear();
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeManagementPanel(Employee emp, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF0D9488),
                  child: Text(emp.name[0], style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${emp.role} • ${emp.department} • ${emp.email}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action 1: Direct Apply on Behalf
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_calendar_rounded, color: Color(0xFF0D9488), size: 20),
                    SizedBox(width: 10),
                    Text('Apply Leave for Employee', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Submit official leave requests directly for team members who requested assistance.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Leave Type
                    DropdownButton<String>(
                      value: _onBehalfLeaveType,
                      items: _leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _onBehalfLeaveType = val);
                      },
                    ),

                    // Start Date Picker
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _onBehalfStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _onBehalfStartDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: Text('From: ${_onBehalfStartDate.year}-${_onBehalfStartDate.month.toString().padLeft(2, '0')}-${_onBehalfStartDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12)),
                    ),

                    // End Date Picker
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _onBehalfEndDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _onBehalfEndDate = picked);
                      },
                      icon: const Icon(Icons.event_rounded, size: 14),
                      label: Text('To: ${_onBehalfEndDate.year}-${_onBehalfEndDate.month.toString().padLeft(2, '0')}-${_onBehalfEndDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _onBehalfReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Note for Leave',
                    hintText: 'e.g. Requested via phone / Medical emergency',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _applyOnBehalf,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text('Submit Leave Request for ${emp.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action 2: Direct Quota Add/Deduct Adjustments with Staging & Confirmation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_moderator_rounded, color: Color(0xFF3B82F6), size: 20),
                        SizedBox(width: 10),
                        Text('Adjust Employee Leave Balances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_pendingQuotaDeltas.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_pendingQuotaDeltas.length} Pending Edits',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Click + or - to stage adjustments. Changes will require your explicit confirmation before saving.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _selectedEmployeeQuotas.entries.map((entry) {
                    final type = entry.key;
                    final base = entry.value;
                    final pendingDelta = _pendingQuotaDeltas[type] ?? 0.0;
                    final hasPending = pendingDelta != 0.0;
                    final isAddition = pendingDelta > 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasPending
                            ? (isAddition ? const Color(0xFF10B981) : Colors.red).withValues(alpha: 0.08)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasPending
                              ? (isAddition ? const Color(0xFF10B981) : Colors.red)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: hasPending ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Text('$base Days', style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                                  if (hasPending) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      isAddition ? '(+$pendingDelta)' : '($pendingDelta)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isAddition ? const Color(0xFF10B981) : Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_rounded, color: Colors.red, size: 20),
                            onPressed: () => _stageQuotaAdjustment(type, -1.0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981), size: 20),
                            onPressed: () => _stageQuotaAdjustment(type, 1.0),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Confirmation Action Bar
                if (_pendingQuotaDeltas.isNotEmpty) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _pendingQuotaDeltas.clear()),
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                        label: const Text('Discard Edits', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showConfirmAdjustmentsModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.fact_check_rounded, size: 18),
                        label: Text(
                          'Confirm & Review Updates (${_pendingQuotaDeltas.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
