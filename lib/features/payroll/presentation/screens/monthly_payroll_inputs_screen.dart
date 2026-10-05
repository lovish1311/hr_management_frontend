import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/monthly_payroll_input_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';

class MonthlyPayrollInputsScreen extends StatefulWidget {
  const MonthlyPayrollInputsScreen({super.key});

  @override
  State<MonthlyPayrollInputsScreen> createState() => _MonthlyPayrollInputsScreenState();
}

class _MonthlyPayrollInputsScreenState extends State<MonthlyPayrollInputsScreen> {
  final PayrollRepository _repository = PayrollRepositoryImpl();

  String _selectedMonth = 'OCTOBER';
  int _selectedYear = 2026;

  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isLocking = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedDepartment = 'ALL';

  List<MonthlyPayrollInputEntity> _inputs = [];
  final Map<int, MonthlyPayrollInputEntity> _localEdits = {};

  final List<String> _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInputs();
  }

  Future<void> _fetchInputs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getMonthlyPayrollInputs(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (!mounted) return;
      setState(() {
        _inputs = list;
        _localEdits.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _syncFromAttendance() async {
    setState(() => _isSyncing = true);
    try {
      final synced = await _repository.syncInputsFromAttendance(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (!mounted) return;
      setState(() {
        _inputs = synced;
        _localEdits.clear();
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-synced LOP days and attendance records. All fields remain editable.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveSingleInput(MonthlyPayrollInputEntity item) async {
    try {
      final saved = await _repository.saveMonthlyPayrollInput(item);
      if (!mounted) return;
      setState(() {
        final idx = _inputs.indexWhere((i) => i.employeeId == item.employeeId);
        if (idx != -1) _inputs[idx] = saved;
        _localEdits.remove(item.employeeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved adjustments for ${item.employeeName}.'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleLockState(bool lock) async {
    final title = lock ? 'Lock Payroll Inputs?' : 'Unlock Payroll Inputs?';
    final content = lock
        ? 'Locking inputs freezes attendance deductions, overtime hours, and ad-hoc bonuses for $_selectedMonth $_selectedYear. You must lock inputs before running the batch calculation.'
        : 'Unlocking inputs allows editing of variables. Any previously calculated draft records will need to be reprocessed.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: lock ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
            ),
            child: Text(lock ? 'Lock Inputs' : 'Unlock Inputs'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLocking = true);
    try {
      if (lock) {
        await _repository.lockInputs(month: _selectedMonth, year: _selectedYear);
      } else {
        await _repository.unlockInputs(month: _selectedMonth, year: _selectedYear);
      }
      await _fetchInputs();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating lock status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool get _isMonthLocked => _inputs.isNotEmpty && _inputs.every((i) => i.isLocked);

  List<MonthlyPayrollInputEntity> get _filteredInputs {
    return _inputs.where((i) {
      final matchesSearch = _searchQuery.isEmpty ||
          i.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDepartment == 'ALL' ||
          i.department.toUpperCase() == _selectedDepartment.toUpperCase();
      return matchesSearch && matchesDept;
    }).toList();
  }

  Set<String> get _allDepartments {
    final set = {'ALL'};
    for (var i in _inputs) {
      if (i.department.isNotEmpty) set.add(i.department.toUpperCase());
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return ResponsiveScaffold(
      body: Column(
        children: [
          // Filter & Control Header
          _buildFilterHeader(context, t),

          // Main Table / Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: t.danger),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: TextStyle(color: t.danger)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchInputs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildTableContent(context, t),
          ),

          // Footer Status Bar
          _buildFooter(context, t),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_outlined, color: t.primary, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Payroll Inputs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: t.text),
                  ),
                  Text('Review and adjust LOP days, overtime hours, and bonuses before batch processing', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                ],
              ),
              const Spacer(),
              // Month & Year Selector
              _buildMonthDropdown(t),
              const SizedBox(width: 10),
              _buildYearDropdown(t),
              const SizedBox(width: 14),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isMonthLocked ? t.warning.withValues(alpha: 0.15) : t.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isMonthLocked ? t.warning.withValues(alpha: 0.4) : t.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isMonthLocked ? Icons.lock : Icons.lock_open, size: 14, color: _isMonthLocked ? t.warning : t.success),
                    const SizedBox(width: 4),
                    Text(
                      _isMonthLocked ? 'LOCKED' : 'UNLOCKED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isMonthLocked ? t.warning : t.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Sync Attendance Button
              OutlinedButton.icon(
                onPressed: (_isMonthLocked || _isSyncing) ? null : _syncFromAttendance,
                icon: _isSyncing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Attendance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.primary,
                  side: BorderSide(color: t.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(width: 10),
              // Lock / Unlock Button
              FilledButton.icon(
                onPressed: _isLocking ? null : () => _toggleLockState(!_isMonthLocked),
                icon: Icon(_isMonthLocked ? Icons.lock_open : Icons.lock_outline, size: 16),
                label: Text(_isMonthLocked ? 'Unlock Inputs' : 'Lock Inputs'),
                style: FilledButton.styleFrom(
                  backgroundColor: _isMonthLocked ? t.cardSoft : t.primary,
                  foregroundColor: _isMonthLocked ? t.text : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search & Department Filter row
          Row(
            children: [
              SizedBox(
                width: 260,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: t.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search employee name or code...',
                    hintStyle: TextStyle(color: t.textSecondary, fontSize: 12),
                    prefixIcon: Icon(Icons.search, size: 18, color: t.textSecondary),
                    filled: true,
                    fillColor: t.cardSoft,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Department Chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _allDepartments.map((dept) {
                      final isSel = _selectedDepartment == dept;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSel,
                          label: Text(dept, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : t.textSecondary)),
                          backgroundColor: t.cardSoft,
                          selectedColor: t.primary,
                          checkmarkColor: Colors.white,
                          onSelected: (_) => setState(() => _selectedDepartment = dept),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown(dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: t.cardSoft, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          dropdownColor: t.card,
          items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(fontSize: 12, color: t.text)))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedMonth = v);
              _fetchInputs();
            }
          },
        ),
      ),
    );
  }

  Widget _buildYearDropdown(dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: t.cardSoft, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: t.card,
          items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y', style: TextStyle(fontSize: 12, color: t.text)))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedYear = v);
              _fetchInputs();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTableContent(BuildContext context, dynamic t) {
    final list = _filteredInputs;
    if (list.isEmpty) {
      return Center(
        child: Text('No employees found matching filter.', style: TextStyle(color: t.textSecondary)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(t.cardSoft),
              horizontalMargin: 16,
              columnSpacing: 18,
              columns: const [
                DataColumn(label: Text('Employee', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Fixed Base Gross', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('LOP Days', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('OT Hours', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ad-Hoc Bonus', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ad-Hoc Deduct', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: list.map((item) {
                final isLocked = item.isLocked;
                final edited = _localEdits[item.employeeId] ?? item;

                return DataRow(
                  cells: [
                    // Employee Info
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.employeeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.text)),
                          Text('${item.employeeCode} • ${item.department}', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                        ],
                      ),
                    ),
                    // Fixed Gross
                    DataCell(
                      Text('₹${item.fixedGross.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w600, color: t.text)),
                    ),
                    // LOP Days (Editable)
                    DataCell(
                      _buildInlineNumberCell(
                        value: edited.lopDays.toString(),
                        isLocked: isLocked,
                        t: t,
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _localEdits[item.employeeId] = edited.copyWith(lopDays: parsed);
                          });
                        },
                      ),
                    ),
                    // Overtime Hours (Editable)
                    DataCell(
                      _buildInlineNumberCell(
                        value: edited.overtimeHours.toString(),
                        isLocked: isLocked,
                        t: t,
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _localEdits[item.employeeId] = edited.copyWith(overtimeHours: parsed);
                          });
                        },
                      ),
                    ),
                    // Ad-Hoc Bonus (Editable)
                    DataCell(
                      _buildInlineNumberCell(
                        value: edited.adHocBonus.toStringAsFixed(0),
                        isLocked: isLocked,
                        prefix: '₹',
                        t: t,
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _localEdits[item.employeeId] = edited.copyWith(adHocBonus: parsed);
                          });
                        },
                      ),
                    ),
                    // Ad-Hoc Deduction (Editable)
                    DataCell(
                      _buildInlineNumberCell(
                        value: edited.adHocDeduction.toStringAsFixed(0),
                        isLocked: isLocked,
                        prefix: '₹',
                        t: t,
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _localEdits[item.employeeId] = edited.copyWith(adHocDeduction: parsed);
                          });
                        },
                      ),
                    ),
                    // Save Action
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_localEdits.containsKey(item.employeeId))
                            IconButton(
                              icon: Icon(Icons.check_circle, size: 20, color: t.success),
                              tooltip: 'Save Edits',
                              onPressed: () => _saveSingleInput(_localEdits[item.employeeId]!),
                            )
                          else
                            Icon(isLocked ? Icons.lock : Icons.edit_note, size: 18, color: t.textSecondary),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildInlineNumberCell({
    required String value,
    required bool isLocked,
    String? prefix,
    required dynamic t,
    required ValueChanged<String> onChanged,
  }) {
    if (isLocked) {
      return Text(
        prefix != null ? '$prefix $value' : value,
        style: TextStyle(color: t.textSecondary, fontSize: 13),
      );
    }

    return SizedBox(
      width: 75,
      height: 32,
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        style: TextStyle(fontSize: 12, color: t.text, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixText: prefix != null ? '$prefix ' : null,
          prefixStyle: TextStyle(fontSize: 11, color: t.textSecondary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: t.cardSoft,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, dynamic t) {
    final totalHeadcount = _inputs.length;
    final totalLop = _inputs.fold<double>(0.0, (acc, i) => acc + i.lopDays);
    final totalOt = _inputs.fold<double>(0.0, (acc, i) => acc + i.overtimeHours);
    final totalBonus = _inputs.fold<double>(0.0, (acc, i) => acc + i.adHocBonus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Text('Total Headcount: $totalHeadcount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.text)),
          const SizedBox(width: 24),
          Text('Total LOP Days: ${totalLop.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.danger)),
          const SizedBox(width: 24),
          Text('Total OT Hours: ${totalOt.toStringAsFixed(1)}h', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.primary)),
          const SizedBox(width: 24),
          Text('Total Bonuses: ₹${totalBonus.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.success)),
        ],
      ),
    );
  }
}
