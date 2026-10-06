import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_management/features/payroll/domain/entities/salary_structure_entity.dart';
import 'package:hr_management/features/payroll/domain/repositories/payroll_repository.dart';

class SalaryStructureScreen extends StatefulWidget {
  final int? initialEmployeeId;

  const SalaryStructureScreen({super.key, this.initialEmployeeId});

  @override
  State<SalaryStructureScreen> createState() => _SalaryStructureScreenState();
}

class _SalaryStructureScreenState extends State<SalaryStructureScreen> {
  final PayrollRepository _repository = PayrollRepositoryImpl();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _errorMessage;

  List<SalaryStructureEntity> _allStructures = [];
  SalaryStructureEntity? _currentStructure;

  // Text editing controllers for components
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _conveyanceController = TextEditingController();
  final _medicalController = TextEditingController();
  final _specialController = TextEditingController();

  final _pfController = TextEditingController();
  final _esiController = TextEditingController();
  final _ptController = TextEditingController();

  // Real-time computed sums
  double _computedGross = 0.0;
  double _computedDeductions = 0.0;
  double _computedNetCtc = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchStructures();
  }

  @override
  void dispose() {
    _basicController.dispose();
    _hraController.dispose();
    _conveyanceController.dispose();
    _medicalController.dispose();
    _specialController.dispose();
    _pfController.dispose();
    _esiController.dispose();
    _ptController.dispose();
    super.dispose();
  }

  Future<void> _fetchStructures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getAllSalaryStructures();
      if (!mounted) return;

      SalaryStructureEntity? selected;
      if (widget.initialEmployeeId != null) {
        selected = list.firstWhere(
          (s) => s.employeeId == widget.initialEmployeeId,
          orElse: () => list.isNotEmpty ? list.first : const SalaryStructureEntity(employeeId: 1),
        );
      } else if (list.isNotEmpty) {
        selected = list.first;
      }

      setState(() {
        _allStructures = list;
        _isLoading = false;
      });

      if (selected != null) {
        _populateFields(selected);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  void _populateFields(SalaryStructureEntity s) {
    setState(() {
      _currentStructure = s;
      _isDirty = false;

      _basicController.text = s.basicPay > 0 ? s.basicPay.toStringAsFixed(0) : '';
      _hraController.text = s.hra > 0 ? s.hra.toStringAsFixed(0) : '';
      _conveyanceController.text = s.conveyanceAllowance > 0 ? s.conveyanceAllowance.toStringAsFixed(0) : '';
      _medicalController.text = s.medicalAllowance > 0 ? s.medicalAllowance.toStringAsFixed(0) : '';
      _specialController.text = s.specialAllowance > 0 ? s.specialAllowance.toStringAsFixed(0) : '';

      _pfController.text = s.pfContribution > 0 ? s.pfContribution.toStringAsFixed(0) : '';
      _esiController.text = s.esiContribution > 0 ? s.esiContribution.toStringAsFixed(0) : '';
      _ptController.text = s.professionalTax > 0 ? s.professionalTax.toStringAsFixed(0) : '200';

      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    double parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

    final basic = parse(_basicController);
    final hra = parse(_hraController);
    final conv = parse(_conveyanceController);
    final med = parse(_medicalController);
    final spec = parse(_specialController);

    final pf = parse(_pfController);
    final esi = parse(_esiController);
    final pt = parse(_ptController);

    setState(() {
      _computedGross = basic + hra + conv + med + spec;
      _computedDeductions = pf + esi + pt;
      _computedNetCtc = _computedGross - _computedDeductions;
      _isDirty = true;
    });
  }

  Future<bool> _handlePopScope() async {
    if (!_isDirty) return true;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Unsaved Changes?'),
        content: const Text('You have unsaved changes to this salary structure. Are you sure you want to discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  Future<void> _saveStructure() async {
    if (_currentStructure == null) return;
    double parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

    final basic = parse(_basicController);
    if (basic <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Basic Pay must be greater than zero.'), backgroundColor: Colors.red),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Salary Revision'),
        content: Text(
          'This revision will update the base compensation for ${_currentStructure!.employeeName}.\n\n'
          'New Monthly Gross: ₹${_computedGross.toStringAsFixed(2)}\n'
          'New Net CTC: ₹${_computedNetCtc.toStringAsFixed(2)}\n\n'
          'Subsequent payroll calculations will pro-rate against this updated structure.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save & Activate')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final updated = _currentStructure!.copyWith(
        basicPay: basic,
        hra: parse(_hraController),
        conveyanceAllowance: parse(_conveyanceController),
        medicalAllowance: parse(_medicalController),
        specialAllowance: parse(_specialController),
        pfContribution: parse(_pfController),
        esiContribution: parse(_esiController),
        professionalTax: parse(_ptController),
        effectiveDate: DateTime.now().toIso8601String().substring(0, 10),
        isActive: true,
      );

      final saved = await _repository.saveSalaryStructure(updated);
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isDirty = false;
        _currentStructure = saved;
        final idx = _allStructures.indexWhere((s) => s.employeeId == saved.employeeId);
        if (idx != -1) {
          _allStructures[idx] = saved;
        } else {
          _allStructures.add(saved);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salary structure saved and activated for ${saved.employeeName}.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final can = await _handlePopScope();
          if (can && context.mounted) Navigator.pop(context);
        }
      },
      child: ResponsiveScaffold(
        body: _isLoading
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
                          onPressed: _fetchStructures,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header & Employee Selector
                      _buildHeader(context, t),

                      // Main Two-Column Scrollable Form
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1080),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 720;
                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildEarningsCard(context, t)),
                                        const SizedBox(width: 24),
                                        Expanded(child: _buildDeductionsCard(context, t)),
                                      ],
                                    );
                                  }
                                  return Column(
                                    children: [
                                      _buildEarningsCard(context, t),
                                      const SizedBox(height: 20),
                                      _buildDeductionsCard(context, t),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Sticky Bottom Calculation Bar
                      _buildStickyBottomBar(context, t),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleMaxWidth = constraints.maxWidth > 540 ? 460.0 : constraints.maxWidth;
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: titleMaxWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: t.primary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary Structure Master',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: t.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Configure master earnings & statutory deductions per employee',
                            style: TextStyle(fontSize: 12, color: t.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Employee Dropdown
              Container(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: t.cardSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _currentStructure?.employeeId,
                    dropdownColor: t.card,
                    isDense: true,
                    items: _allStructures.map((s) {
                      return DropdownMenuItem<int>(
                        value: s.employeeId,
                        child: Text(
                          '${s.employeeName} (${s.employeeCode})',
                          style: TextStyle(color: t.text, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) async {
                      if (id == null) return;
                      if (_isDirty) {
                        final canDiscard = await _handlePopScope();
                        if (!canDiscard) return;
                      }
                      final selected = _allStructures.firstWhere((s) => s.employeeId == id);
                      _populateFields(selected);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: t.success, size: 20),
              const SizedBox(width: 8),
              Text('Earnings Components', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t.text)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Fixed monthly earnings components forming the base gross.', style: TextStyle(fontSize: 11, color: t.textSecondary)),
          const Divider(height: 24),
          _buildNumberField(controller: _basicController, label: 'Basic Pay (Monthly)', required: true, t: t),
          const SizedBox(height: 14),
          _buildNumberField(controller: _hraController, label: 'House Rent Allowance (HRA)', t: t),
          const SizedBox(height: 14),
          _buildNumberField(controller: _conveyanceController, label: 'Conveyance Allowance', t: t),
          const SizedBox(height: 14),
          _buildNumberField(controller: _medicalController, label: 'Medical Allowance', t: t),
          const SizedBox(height: 14),
          _buildNumberField(controller: _specialController, label: 'Special / Other Allowance', t: t),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: t.primary, size: 20),
              const SizedBox(width: 8),
              Text('Statutory & Other Deductions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t.text)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Mandatory PF, ESI, and tax contributions.', style: TextStyle(fontSize: 11, color: t.textSecondary)),
          const Divider(height: 24),
          _buildNumberField(controller: _pfController, label: 'Provident Fund (PF Employee)', t: t),
          const SizedBox(height: 14),
          _buildNumberField(controller: _esiController, label: 'ESI Contribution', t: t),
          const SizedBox(height: 14),
          _buildNumberField(controller: _ptController, label: 'Professional Tax (PT)', t: t),
          const SizedBox(height: 24),
          // Information notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.cardSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: t.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Standard Professional Tax defaults to ₹200/mo. Variable LOP absences are applied separately during the monthly batch process.',
                    style: TextStyle(fontSize: 11, color: t.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    required dynamic t,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text)),
            if (required) Text(' *', style: TextStyle(color: t.danger, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _recalculateTotals(),
          style: TextStyle(color: t.text, fontSize: 14),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(color: t.textSecondary, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: t.cardSoft,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildSummaryPill('Total Fixed Gross', '₹${_computedGross.toStringAsFixed(2)}', t.success),
                      _buildSummaryPill('Deductions', '₹${_computedDeductions.toStringAsFixed(2)}', t.danger),
                      _buildSummaryPill('Calculated Net CTC', '₹${_computedNetCtc.toStringAsFixed(2)}', t.primary, isEmphasized: true),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveStructure,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save & Activate Structure'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPill(String title, String value, Color color, {bool isEmphasized = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isEmphasized ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
