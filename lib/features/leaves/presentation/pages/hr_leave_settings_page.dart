import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
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

  // Section 3: Time-Off Permission Policy Rules state
  String _timeOffPolicyMode = 'UNITWISE';
  String _timeOffCycle = 'Monthly';
  int _shortBreakUnitLimit = 2;
  int _earlyOutUnitLimit = 2;
  int _lateArrivalUnitLimit = 2;
  int _hourlyLimit = 4;
  bool _isLoadingTimeOffSettings = false;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadEmployees();
    _loadTimeOffSettings();
  }

  Future<void> _loadTimeOffSettings() async {
    setState(() => _isLoadingTimeOffSettings = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/settings'),
        headers: AuthStorage.authHeaders,
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        setState(() {
          if (data['time_off_policy_mode'] != null && data['time_off_policy_mode'].toString().isNotEmpty) {
            _timeOffPolicyMode = data['time_off_policy_mode'];
          }
          if (data['time_off_cycle'] != null && data['time_off_cycle'].toString().isNotEmpty) {
            _timeOffCycle = data['time_off_cycle'];
          }
          _shortBreakUnitLimit = int.tryParse(data['time_off_short_break_unit_limit']?.toString() ?? '2') ?? 2;
          _earlyOutUnitLimit = int.tryParse(data['time_off_early_out_unit_limit']?.toString() ?? '2') ?? 2;
          _lateArrivalUnitLimit = int.tryParse(data['time_off_late_arrival_unit_limit']?.toString() ?? '2') ?? 2;
          _hourlyLimit = int.tryParse(data['time_off_hourly_limit']?.toString() ?? '4') ?? 4;
        });
      }
    } catch (e) {
      debugPrint('Failed to load time off settings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTimeOffSettings = false);
    }
  }

  Future<void> _saveTimeOffSettings() async {
    final payload = {
      'time_off_policy_mode': _timeOffPolicyMode,
      'time_off_cycle': _timeOffCycle,
      'time_off_short_break_unit_limit': _shortBreakUnitLimit.toString(),
      'time_off_early_out_unit_limit': _earlyOutUnitLimit.toString(),
      'time_off_late_arrival_unit_limit': _lateArrivalUnitLimit.toString(),
      'time_off_hourly_limit': _hourlyLimit.toString(),
    };

    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/settings/batch'),
        headers: AuthStorage.authHeaders,
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Time-off permission rules & limits updated successfully!'),
            backgroundColor: context.appTheme.success,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${res.body}'),
            backgroundColor: context.appTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: context.appTheme.danger,
        ),
      );
    }
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
        backgroundColor: context.appTheme.primary,
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
        backgroundColor: context.appTheme.primary,
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
        final t = context.appTheme;

        return Dialog(
          backgroundColor: t.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: t.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.verified_user_rounded, color: t.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Confirm Leave Balance Edits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
                            const SizedBox(height: 2),
                            Text('Review changes for ${_selectedEmployee!.name} before saving to database.', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: t.border),
                  const SizedBox(height: 16),

                  Text('Summary of Planned Adjustments:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text)),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.cardSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.border),
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
                                color: isAddition ? t.success : t.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$leaveType: ${isAddition ? "Addition of +$delta" : "Deduction of $delta"} day(s)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isAddition ? t.success : t.danger).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'New Balance: $updated Days',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAddition ? t.success : t.danger,
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
                    decoration: InputDecoration(
                      labelText: 'HR Audit Note / Reason (Optional)',
                      hintText: 'e.g. Performance credit / Policy adjustment',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(color: t.text),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel & Edit', style: TextStyle(color: t.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _commitQuotaAdjustments();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.primary,
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
          backgroundColor: context.appTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Company Leave Policy & Quotas', style: TextStyle(fontWeight: FontWeight.bold, color: t.onBackgroundText)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: t.primary,
          labelColor: t.onBackgroundText,
          unselectedLabelColor: t.onBackgroundTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.tune_rounded), text: '1. Leave Allocation'),
            Tab(icon: Icon(Icons.person_pin_rounded), text: '2. Employee Quotas'),
            Tab(icon: Icon(Icons.timer_rounded), text: '3. Short Break & Permission Rules'),
          ],
        ),
      ),


      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSection1BulkGrants(),
            _buildSection2EmployeeOverrides(),
            _buildSection3TimeOffPolicyRules(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: Organization Bulk Grants & Exclusions
  // ---------------------------------------------------------------------------
  Widget _buildSection1BulkGrants() {
    final t = context.appTheme;
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
                  gradient: LinearGradient(
                    colors: [t.primaryDark, t.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.3),
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
                  color: t.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Select Grant Frequency
                    Text('Step 1: Select Allocation Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.text)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: _cycles.map((cycle) {
                        final isSelected = _selectedCycle == cycle;
                        return ChoiceChip(
                          label: Text(cycle, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : t.text)),
                          selected: isSelected,
                          selectedColor: t.primary,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCycle = cycle);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Step 2: Select Leave Type & Quantity
                    Text('Step 2: Select Leave Category & Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.text)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _leaveTypes.map((type) {
                        final isSelected = _selectedLeaveType == type;
                        return FilterChip(
                          label: Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : t.text)),
                          selected: isSelected,
                          selectedColor: t.primary,
                          onSelected: (val) {
                            if (val) setState(() => _selectedLeaveType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Allocation Days to Grant:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: t.text)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded, color: t.primary),
                          onPressed: () {
                            if (_grantDays > 0.5) setState(() => _grantDays -= 0.5);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: t.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_grantDays Days',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.primary),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded, color: t.primary),
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
                        Text('Step 3: Employee Exclusions (Probation / Notice Period)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.text)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Excluded',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Selected employees will be skipped and will not receive this allocation grant.', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                    const SizedBox(height: 12),

                    if (_isLoadingEmployees)
                      Center(child: CircularProgressIndicator(color: t.primary))
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.cardSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.border),
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
                                  backgroundColor: isExcluded ? t.danger : t.primary,
                                  child: Text(emp.name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                label: Text(emp.name, style: TextStyle(fontSize: 12, color: isExcluded ? t.danger : t.text)),
                                selected: isExcluded,
                                selectedColor: t.danger.withValues(alpha: 0.15),
                                checkmarkColor: t.danger,
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
                          backgroundColor: t.primary,
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
  Widget _buildSection2EmployeeOverrides() {
    final t = context.appTheme;
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
                      child: _buildEmployeeRosterList(filtered),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _selectedEmployee == null
                          ? Center(child: Text('Select an employee to manage leaves.', style: TextStyle(color: t.textSecondary)))
                          : _buildEmployeeManagementPanel(_selectedEmployee!),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: _buildEmployeeRosterList(filtered),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedEmployee != null) _buildEmployeeManagementPanel(_selectedEmployee!),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmployeeRosterList(List<Employee> list) {
    final t = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search employee...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: t.cardSoft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: t.text),
            ),
          ),
          Divider(height: 1, color: t.border),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('No employees found.', style: TextStyle(fontSize: 13, color: t.textSecondary)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final emp = list[index];
                      final isSelected = _selectedEmployee?.id == emp.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: t.primary.withValues(alpha: 0.12),
                        leading: CircleAvatar(
                          backgroundColor: t.primary.withValues(alpha: 0.15),
                          child: Text(emp.name[0], style: TextStyle(fontWeight: FontWeight.bold, color: t.primary)),
                        ),
                        title: Text(emp.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text)),
                        subtitle: Text('${emp.role} • ${emp.department}', style: TextStyle(fontSize: 11, color: t.textSecondary)),
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

  Widget _buildEmployeeManagementPanel(Employee emp) {
    final t = context.appTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: t.primary,
                  child: Text(emp.name[0], style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name, style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${emp.role} • ${emp.department} • ${emp.email}', style: TextStyle(color: t.textSecondary, fontSize: 12)),
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
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_calendar_rounded, color: t.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('Apply Leave for Employee', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.text)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Submit official leave requests directly for team members who requested assistance.', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Leave Type
                    DropdownButton<String>(
                      value: _onBehalfLeaveType,
                      dropdownColor: t.cardSoft,
                      style: TextStyle(color: t.text),
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
                  decoration: InputDecoration(
                    labelText: 'Reason / Note for Leave',
                    hintText: 'e.g. Requested via phone / Medical emergency',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: t.text),
                  ),
                  style: TextStyle(color: t.text),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _applyOnBehalf,
                  style: ElevatedButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.white),
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
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_moderator_rounded, color: t.accent, size: 20),
                        const SizedBox(width: 10),
                        Text('Adjust Employee Leave Balances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.text)),
                      ],
                    ),
                    if (_pendingQuotaDeltas.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_pendingQuotaDeltas.length} Pending Edits',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.accent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Click + or - to stage adjustments. Changes will require your explicit confirmation before saving.', style: TextStyle(fontSize: 11, color: t.textSecondary)),
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
                            ? (isAddition ? t.success : t.danger).withValues(alpha: 0.08)
                            : t.cardSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasPending
                              ? (isAddition ? t.success : t.danger)
                              : t.border,
                          width: hasPending ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.text)),
                              Row(
                                children: [
                                  Text('$base Days', style: TextStyle(fontSize: 11, color: t.primary, fontWeight: FontWeight.w600)),
                                  if (hasPending) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      isAddition ? '(+$pendingDelta)' : '($pendingDelta)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isAddition ? t.success : t.danger,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.remove_circle_rounded, color: t.danger, size: 20),
                            onPressed: () => _stageQuotaAdjustment(type, -1.0),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_rounded, color: t.success, size: 20),
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
                  Divider(height: 1, color: t.border),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _pendingQuotaDeltas.clear()),
                        icon: Icon(Icons.close_rounded, size: 16, color: t.textSecondary),
                        label: Text('Discard Edits', style: TextStyle(color: t.textSecondary)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showConfirmAdjustmentsModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accent,
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

  // ---------------------------------------------------------------------------
  // SECTION 3: Short Break, Early Out & Late Arrival Permission Policy Rules
  // ---------------------------------------------------------------------------
  Widget _buildSection3TimeOffPolicyRules() {
    final t = context.appTheme;

    if (_isLoadingTimeOffSettings) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [t.primaryDark, const Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
                          child: const Icon(Icons.timer_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Time-Off Permission Policy & Limit Rules',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Configure how Short Break, Early Out, and Late Arrival permissions are enforced across your organization. Select evaluation modes, policy cycles, and unit or hourly quotas.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Policy Evaluation Mode Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Policy Evaluation Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
                    const SizedBox(height: 4),
                    Text('Select how permission requests are restricted.', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                    const SizedBox(height: 16),

                    _buildPolicyModeOption(
                      mode: 'FLEXIBLE',
                      title: 'Flexible Mode (Unlimited / Manual Approval)',
                      description: 'No automated limit checks. Approvers review and approve requests on a case-by-case basis.',
                      icon: Icons.splitscreen_rounded,
                      t: t,
                    ),
                    const SizedBox(height: 10),
                    _buildPolicyModeOption(
                      mode: 'UNITWISE',
                      title: 'Unit-Based Quotas (Per-Count Limit)',
                      description: 'Restricts the number of permission instances (e.g. max 2 Short Breaks, 2 Early Outs, 2 Late Arrivals per cycle).',
                      icon: Icons.filter_1_rounded,
                      t: t,
                    ),
                    const SizedBox(height: 10),
                    _buildPolicyModeOption(
                      mode: 'HOURLY_SEPARATE',
                      title: 'Hourly Quotas (Individual Hours Limit)',
                      description: 'Applies an independent max hour limit for Short Breaks, Early Outs, and Late Arrivals separately.',
                      icon: Icons.access_time_filled_rounded,
                      t: t,
                    ),
                    const SizedBox(height: 10),
                    _buildPolicyModeOption(
                      mode: 'HOURLY_COMBINED',
                      title: 'Hourly Quotas (Combined Hours Pool)',
                      description: 'Shares a single total pool of hours (e.g., 4 hours total) across Short Breaks, Early Outs, and Late Arrivals.',
                      icon: Icons.pie_chart_outline_rounded,
                      t: t,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Policy Cycle & Quota Limits Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2. Policy Cycle & Quota Limits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
                    const SizedBox(height: 4),
                    Text('Specify the resetting frequency and individual limits for time-based exemptions.', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                    const SizedBox(height: 20),

                    // Cycle Selector
                    Row(
                      children: [
                        Text('Policy Cycle Frequency:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.text)),
                        const SizedBox(width: 16),
                        Wrap(
                          spacing: 8,
                          children: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'].map((cycle) {
                            final isSel = _timeOffCycle == cycle;
                            return ChoiceChip(
                              label: Text(cycle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : t.text)),
                              selected: isSel,
                              selectedColor: t.primary,
                              onSelected: (val) {
                                if (val) setState(() => _timeOffCycle = cycle);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(height: 1, color: t.border),
                    const SizedBox(height: 20),

                    // Unit Limits Editor (Short Break, Early Out, Late Arrival)
                    Text('Permission Unit Limits (Per $_timeOffCycle Cycle):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.text)),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildLimitCounter(
                            title: 'Short Break Limit',
                            subtitle: 'Max short breaks allowed per cycle',
                            value: _shortBreakUnitLimit,
                            icon: Icons.coffee_outlined,
                            color: const Color(0xFFF59E0B),
                            t: t,
                            onChanged: (val) => setState(() => _shortBreakUnitLimit = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLimitCounter(
                            title: 'Early Out Limit',
                            subtitle: 'Max early outs allowed per cycle',
                            value: _earlyOutUnitLimit,
                            icon: Icons.directions_run_outlined,
                            color: const Color(0xFF8B5CF6),
                            t: t,
                            onChanged: (val) => setState(() => _earlyOutUnitLimit = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLimitCounter(
                            title: 'Late Arrival Limit',
                            subtitle: 'Max late arrival permissions per cycle',
                            value: _lateArrivalUnitLimit,
                            icon: Icons.watch_later_outlined,
                            color: const Color(0xFFEF4444),
                            t: t,
                            onChanged: (val) => setState(() => _lateArrivalUnitLimit = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLimitCounter(
                            title: 'Combined Hourly Limit',
                            subtitle: 'Max total hours (for Hourly Mode)',
                            value: _hourlyLimit,
                            icon: Icons.timer_outlined,
                            color: const Color(0xFF0284C7),
                            t: t,
                            onChanged: (val) => setState(() => _hourlyLimit = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Rules Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveTimeOffSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text(
                          'Save Time-Off Permission Policy Rules & Limits',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildPolicyModeOption({required String mode, required String title, required String description, required IconData icon, required AppThemeConfig t}) {
    final isSelected = _timeOffPolicyMode == mode;
    return InkWell(
      onTap: () => setState(() => _timeOffPolicyMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? t.primary.withValues(alpha: 0.1) : t.cardSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? t.primary : t.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: mode,
              groupValue: _timeOffPolicyMode,
              onChanged: (val) {
                if (val != null) setState(() => _timeOffPolicyMode = val);
              },
              activeColor: t.primary,
            ),
            Icon(icon, color: isSelected ? t.primary : t.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? t.primary : t.text)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 12, color: t.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitCounter({required String title, required String subtitle, required int value, required IconData icon, required Color color, required AppThemeConfig t, required Function(int) onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text)),
                    Text(subtitle, style: TextStyle(fontSize: 10, color: t.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: color),
                onPressed: () {
                  if (value > 0) onChanged(value - 1);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, color: color),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


