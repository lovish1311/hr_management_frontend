import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/domain/repositories/employee_repository.dart';

class EmployeeFormPage extends StatefulWidget {
  final Employee? initialEmployee; // If null, mode is Create; if present, mode is Edit
  final bool isModal;

  const EmployeeFormPage({
    super.key,
    this.initialEmployee,
    this.isModal = false,
  });

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeRepository _repository = EmployeeRepositoryImpl();

  bool get isEdit => widget.initialEmployee != null;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _employeeCodeController;
  late TextEditingController _designationController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  // Personal state
  DateTime? _dateOfBirth;
  String _selectedGender = 'Male';

  // Employment state
  DateTime _joiningDate = DateTime.now();
  String _selectedDepartment = 'Engineering';
  String _selectedRole = 'EMPLOYEE';
  String _selectedEmploymentType = 'FULL_TIME';
  String? _selectedManagerId;
  String _selectedManagerName = 'Unassigned';
  bool _isAttendanceTracked = true;
  String _status = 'ACTIVE';

  // Probation state
  bool _isProbation = false;
  DateTime _probationStartDate = DateTime.now();
  int _probationDurationMonths = 3;
  String _probationPolicyCycle = 'Quarterly'; // 'Quarterly' (1.5 leaves) or 'Half-Yearly' (3.0 leaves)

  // Notice Period state
  bool _isNoticePeriod = false;
  DateTime _noticeStartDate = DateTime.now();
  int _noticeDurationDays = 60;

  // Available managers list
  List<Employee> _availableManagers = [];
  bool _isLoading = false;

  final List<String> _departments = [
    'Engineering',
    'Product',
    'Design',
    'Sales',
    'Marketing',
    'Operations',
    'Human Resources',
    'Finance',
    'Executive',
  ];

  final List<String> _roles = [
    'EMPLOYEE',
    'MANAGER',
    'HR',
    'SUPER_ADMIN',
  ];

  final List<String> _employmentTypes = [
    'FULL_TIME',
    'PART_TIME',
    'CONTRACT',
    'INTERN',
  ];

  final List<String> _statusOptions = [
    'ACTIVE',
    'PROBATION',
    'NOTICE_PERIOD',
    'INACTIVE',
  ];

  @override
  void initState() {
    super.initState();
    final emp = widget.initialEmployee;

    _firstNameController = TextEditingController(text: emp?.firstName ?? '');
    _lastNameController = TextEditingController(text: emp?.lastName ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _phoneController = TextEditingController(text: emp?.phone ?? '');
    _employeeCodeController = TextEditingController(
      text: (emp != null && emp.employeeCode.isNotEmpty) 
          ? emp.employeeCode 
          : 'EMP-${(DateTime.now().millisecondsSinceEpoch % 900) + 100}',
    );
    _designationController = TextEditingController(text: emp?.designation ?? 'Software Engineer');
    _addressController = TextEditingController(text: emp?.address ?? '');
    _emergencyNameController = TextEditingController(text: emp?.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: emp?.emergencyContactPhone ?? '');

    if (emp != null) {
      if (emp.joiningDate.isNotEmpty) {
        _joiningDate = DateTime.tryParse(emp.joiningDate) ?? DateTime.now();
      }
      if (emp.dateOfBirth.isNotEmpty) {
        _dateOfBirth = DateTime.tryParse(emp.dateOfBirth);
      }
      _selectedDepartment = _departments.contains(emp.department) ? emp.department : _departments.first;
      _selectedRole = _roles.contains(emp.role) ? emp.role : 'EMPLOYEE';
      _selectedEmploymentType = _employmentTypes.contains(emp.employmentType) ? emp.employmentType : 'FULL_TIME';
      _selectedManagerId = emp.managerId;
      _selectedManagerName = emp.managerName;
      _isAttendanceTracked = emp.isAttendanceTracked;
      _status = emp.status;

      _isProbation = emp.isProbation || emp.status == 'PROBATION';
      if (emp.probationStartDate != null) {
        _probationStartDate = DateTime.tryParse(emp.probationStartDate!) ?? _joiningDate;
      } else {
        _probationStartDate = _joiningDate;
      }
      _probationDurationMonths = emp.probationDurationMonths ?? 3;

      _isNoticePeriod = emp.isNoticePeriod || emp.status == 'NOTICE_PERIOD';
      if (emp.noticeStartDate != null) {
        _noticeStartDate = DateTime.tryParse(emp.noticeStartDate!) ?? DateTime.now();
      }
      _noticeDurationDays = emp.noticeDurationDays ?? 60;
    }

    _loadManagers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeCodeController.dispose();
    _designationController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadManagers() async {
    try {
      final list = await _repository.getEmployees();
      if (mounted) {
        setState(() {
          _availableManagers = list.where((e) => e.id != widget.initialEmployee?.id).toList();
        });
      }
    } catch (_) {}
  }

  // --- Probation Date & 15th-day rule calculation ---
  DateTime get _calculatedProbationEndDate {
    final start = _probationStartDate;
    int year = start.year;
    int month = start.month + _probationDurationMonths;
    while (month > 12) {
      year++;
      month -= 12;
    }
    final daysInTargetMonth = DateUtils.getDaysInMonth(year, month);
    final day = start.day > daysInTargetMonth ? daysInTargetMonth : start.day;
    return DateTime(year, month, day);
  }

  // 15th-day rule calculation
  bool get _isEndOnOrBefore15th => _calculatedProbationEndDate.day <= 15;

  DateTime get _firstEligibleAccrualDate {
    final endDate = _calculatedProbationEndDate;
    if (_isEndOnOrBefore15th) {
      return DateTime(endDate.year, endDate.month, 1);
    } else {
      int nextMonth = endDate.month + 1;
      int year = endDate.year;
      if (nextMonth > 12) {
        year++;
        nextMonth = 1;
      }
      return DateTime(year, nextMonth, 1);
    }
  }

  // Proration calculation based on policy cycle
  Map<String, dynamic> get _prorationSummary {
    final eligibleDate = _firstEligibleAccrualDate;
    final eligibleMonth = eligibleDate.month;

    if (_probationPolicyCycle == 'Quarterly') {
      // 1.5 leaves per 3 months -> 0.5 leaves per eligible month
      final currentQuarter = ((eligibleMonth - 1) ~/ 3) + 1;
      final quarterEndMonth = currentQuarter * 3;
      final remainingEligibleMonthsInCycle = (quarterEndMonth - eligibleMonth + 1).clamp(0, 3);
      final earnedLeaveAccrual = remainingEligibleMonthsInCycle * 0.5;

      return {
        'cycle': 'Quarterly',
        'monthlyShare': 0.5,
        'remainingMonths': remainingEligibleMonthsInCycle,
        'cycleEndMonth': quarterEndMonth,
        'creditedLeaves': earnedLeaveAccrual,
      };
    } else {
      // Half-Yearly: 3.0 leaves per 6 months -> 0.5 leaves per eligible month
      final currentHalf = ((eligibleMonth - 1) ~/ 6) + 1;
      final halfEndMonth = currentHalf * 6;
      final remainingEligibleMonthsInCycle = (halfEndMonth - eligibleMonth + 1).clamp(0, 6);
      final earnedLeaveAccrual = remainingEligibleMonthsInCycle * 0.5;

      return {
        'cycle': 'Half-Yearly',
        'monthlyShare': 0.5,
        'remainingMonths': remainingEligibleMonthsInCycle,
        'cycleEndMonth': halfEndMonth,
        'creditedLeaves': earnedLeaveAccrual,
      };
    }
  }

  // --- Notice Period Calculation ---
  DateTime get _calculatedNoticeEndDate {
    return _noticeStartDate.add(Duration(days: _noticeDurationDays));
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.appTheme.primary,
              onPrimary: Colors.white,
              surface: context.appTheme.card,
              onSurface: context.appTheme.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    final fullName = '$fn $ln'.trim();

    String effectiveStatus = _status;
    if (_isProbation) {
      effectiveStatus = 'PROBATION';
    } else if (_isNoticePeriod) {
      effectiveStatus = 'NOTICE_PERIOD';
    }

    final employeeToSave = Employee(
      id: widget.initialEmployee?.id ?? '',
      employeeCode: _employeeCodeController.text.trim(),
      name: fullName,
      firstName: fn,
      lastName: ln,
      role: _selectedRole,
      department: _selectedDepartment,
      designation: _designationController.text.trim(),
      status: effectiveStatus,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      managerName: _selectedManagerName,
      managerId: _selectedManagerId,
      dateOfBirth: _dateOfBirth != null ? _dateOfBirth!.toIso8601String().split('T')[0] : '',
      joiningDate: _joiningDate.toIso8601String().split('T')[0],
      employmentType: _selectedEmploymentType,
      address: _addressController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      isAttendanceTracked: _isAttendanceTracked,
      isProbation: _isProbation,
      probationStartDate: _isProbation ? _probationStartDate.toIso8601String().split('T')[0] : null,
      probationDurationMonths: _isProbation ? _probationDurationMonths : null,
      probationEndDate: _isProbation ? _calculatedProbationEndDate.toIso8601String().split('T')[0] : null,
      isNoticePeriod: _isNoticePeriod,
      noticeStartDate: _isNoticePeriod ? _noticeStartDate.toIso8601String().split('T')[0] : null,
      noticeDurationDays: _isNoticePeriod ? _noticeDurationDays : null,
      noticeEndDate: _isNoticePeriod ? _calculatedNoticeEndDate.toIso8601String().split('T')[0] : null,
    );

    try {
      if (isEdit) {
        await _repository.updateEmployee(employeeToSave);
      } else {
        await _repository.createEmployee(employeeToSave);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(isEdit ? 'Employee updated successfully!' : 'Employee created successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving employee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = t.isCardDark;
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;

    final content = Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Hero Card
                _buildHeaderCard(t),
                const SizedBox(height: 24),

                // Section 1: Basic Information
                _buildSectionContainer(
                  t: t,
                  title: 'Basic Information',
                  subtitle: 'Personal details and credentials of the employee',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _firstNameController,
                              label: 'First Name',
                              hint: 'e.g. Rahul',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty ? 'First name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _lastNameController,
                              label: 'Last Name',
                              hint: 'e.g. Verma',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Last name is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _emailController,
                              label: 'Work Email Address',
                              hint: 'rahul.verma@company.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email is required';
                                if (!v.contains('@') || !v.contains('.')) return 'Invalid email format';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: '+91 98765 43210',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerTile(
                              t: t,
                              label: 'Date of Birth',
                              selectedDate: _dateOfBirth,
                              fallbackText: 'Select Date of Birth',
                              icon: Icons.cake_outlined,
                              onTap: () => _pickDate(
                                context: context,
                                initialDate: _dateOfBirth ?? DateTime(1996, 1, 1),
                                onPicked: (d) => _dateOfBirth = d,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gender', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: ['Male', 'Female', 'Other'].map((g) {
                                    final isSel = _selectedGender == g;
                                    return ChoiceChip(
                                      label: Text(g, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : textColor)),
                                      selected: isSel,
                                      selectedColor: t.primary,
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : t.cardSoft,
                                      onSelected: (_) => setState(() => _selectedGender = g),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        t: t,
                        controller: _addressController,
                        label: 'Residential Address',
                        hint: 'Flat, Street, City, State, ZIP',
                        icon: Icons.home_work_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _emergencyNameController,
                              label: 'Emergency Contact Person',
                              hint: 'e.g. Ramesh Verma (Father)',
                              icon: Icons.contact_emergency_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _emergencyPhoneController,
                              label: 'Emergency Phone',
                              hint: '+91 98765 00000',
                              icon: Icons.phone_callback_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Employment Details
                _buildSectionContainer(
                  t: t,
                  title: 'Employment Details',
                  subtitle: 'Role, hierarchy, department, and attendance policies',
                  icon: Icons.work_rounded,
                  iconColor: const Color(0xFF10B981),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSystemGeneratedCodeTile(t),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDatePickerTile(
                              t: t,
                              label: 'Joining Date',
                              selectedDate: _joiningDate,
                              fallbackText: 'Select Joining Date',
                              icon: Icons.calendar_today_rounded,
                              onTap: () => _pickDate(
                                context: context,
                                initialDate: _joiningDate,
                                onPicked: (d) {
                                  _joiningDate = d;
                                  if (!_isProbation) {
                                    _probationStartDate = d;
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Department', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: t.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDepartment,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 13.5, color: textColor)))).toList(),
                                      onChanged: (v) => setState(() => _selectedDepartment = v ?? _selectedDepartment),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              t: t,
                              controller: _designationController,
                              label: 'Job Designation / Title',
                              hint: 'e.g. Senior Software Engineer',
                              icon: Icons.title_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Designation is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('System Role', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: _roles.map((r) {
                                    final isSel = _selectedRole == r;
                                    return ChoiceChip(
                                      label: Text(r, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : textColor)),
                                      selected: isSel,
                                      selectedColor: const Color(0xFF0D9488),
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : t.cardSoft,
                                      onSelected: (_) => setState(() => _selectedRole = r),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Employment Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: _employmentTypes.map((et) {
                                    final isSel = _selectedEmploymentType == et;
                                    return ChoiceChip(
                                      label: Text(et.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : textColor)),
                                      selected: isSel,
                                      selectedColor: t.primary,
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : t.cardSoft,
                                      onSelected: (_) => setState(() => _selectedEmploymentType = et),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Direct Manager / Approver selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Manager / Leave Approver', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: t.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedManagerId,
                                hint: Text('Select Assigned Manager (Optional)', style: TextStyle(fontSize: 13.5, color: textSecondary)),
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Unassigned (Direct Super Admin)', style: TextStyle(fontSize: 13.5, color: textSecondary)),
                                  ),
                                  ..._availableManagers.map((m) {
                                    return DropdownMenuItem<String>(
                                      value: m.id,
                                      child: Text('${m.name} (${m.role} • ${m.department})', style: TextStyle(fontSize: 13.5, color: textColor)),
                                    );
                                  }),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedManagerId = v;
                                    if (v != null) {
                                      final match = _availableManagers.where((m) => m.id == v);
                                      if (match.isNotEmpty) {
                                        _selectedManagerName = match.first.name;
                                      }
                                    } else {
                                      _selectedManagerName = 'Unassigned';
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Attendance tracking switch
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : t.cardSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.fingerprint_rounded, color: t.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Track Daily Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor)),
                                  Text('Enables biometric check-in tracking and automated absence detection.', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isAttendanceTracked,
                              activeTrackColor: t.primary,
                              onChanged: (val) => setState(() => _isAttendanceTracked = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Probation Period (Core Highlight)
                _buildProbationSection(t, isDark),
                const SizedBox(height: 24),

                // Section 4: Notice Period (Core Highlight)
                _buildNoticePeriodSection(t, isDark),
                const SizedBox(height: 24),

                // Section 5: Employee Status / Lifecycle
                _buildStatusSection(t, isDark),
                const SizedBox(height: 32),

                // Submit Action Buttons
                _buildActionButtons(t),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isModal) {
      return Dialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: content,
        ),
      );
    }

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: content),
    );
  }

  // --- Widget Builders ---

  Widget _buildHeaderCard(AppThemeConfig t) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.primary.withValues(alpha: 0.85),
            Color.lerp(t.primary, Colors.indigo, 0.4) ?? t.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: t.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Employee Details' : 'Create New Employee',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? 'Update employment parameters, adjust probation status, or configure notice period.'
                      : 'Enroll a new employee with probation timelines, notice rules, and attendance credentials.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isModal)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required AppThemeConfig t,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final isDark = t.isCardDark;
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: t.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: t.glow.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    Text(subtitle, style: TextStyle(fontSize: 11.5, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required AppThemeConfig t,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = t.isCardDark;
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 13.5, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, size: 18, color: t.primary),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : t.cardSoft,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemGeneratedCodeTile(AppThemeConfig t) {
    final isDark = t.isCardDark;
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;
    final code = _employeeCodeController.text.trim().isNotEmpty
        ? _employeeCodeController.text.trim()
        : 'EMP-${(DateTime.now().millisecondsSinceEpoch % 900) + 100}';
    
    // Ensure controller has the assigned code
    if (_employeeCodeController.text.trim().isEmpty) {
      _employeeCodeController.text = code;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text('Employee Code', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: t.primary.withValues(alpha: 0.3)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SYSTEM GENERATED',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: t.primary, letterSpacing: 0.2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : t.cardSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_clock_outlined, size: 18, color: t.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome_rounded, size: 16, color: t.primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile({
    required AppThemeConfig t,
    required String label,
    required DateTime? selectedDate,
    required String fallbackText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = t.isCardDark;
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : t.cardSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: t.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedDate != null ? _formatDate(selectedDate) : fallbackText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: selectedDate != null ? textColor : textSecondary.withValues(alpha: 0.6),
                      fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Probation Section ---
  Widget _buildProbationSection(AppThemeConfig t, bool isDark) {
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;
    final proration = _prorationSummary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isProbation 
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5) 
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: _isProbation ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isProbation ? const Color(0xFFF59E0B).withValues(alpha: 0.08) : Colors.transparent,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Switch Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Probation Period Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        if (_isProbation)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                            ),
                            child: const Text('PROBATION ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                          ),
                      ],
                    ),
                    Text('Controls Earned Leave accrual blocking & 15th-day cutoff proration', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isProbation,
                activeTrackColor: const Color(0xFFF59E0B),
                onChanged: (val) => setState(() => _isProbation = val),
              ),
            ],
          ),

          if (_isProbation) ...[
            const Divider(height: 28),
            // Start Date and Duration Selector
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerTile(
                    t: t,
                    label: 'Probation Start Date',
                    selectedDate: _probationStartDate,
                    fallbackText: 'Select Start Date',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDate(
                      context: context,
                      initialDate: _probationStartDate,
                      onPicked: (d) => _probationStartDate = d,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Probation Duration', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [1, 3, 6].map((months) {
                          final isSel = _probationDurationMonths == months;
                          return ChoiceChip(
                            label: Text('$months Mo', style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : textColor)),
                            selected: isSel,
                            selectedColor: const Color(0xFFD97706),
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : t.cardSoft,
                            onSelected: (_) => setState(() => _probationDurationMonths = months),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Calculated End Date & 15th-Day Rule Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.event_available_rounded, color: Color(0xFFD97706), size: 18),
                      Text('Calculated Probation End Date: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                      Text(
                        _formatDate(_calculatedProbationEndDate),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 15th-Day Cutoff Interpretation Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.amber.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isEndOnOrBefore15th ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                              color: _isEndOnOrBefore15th ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '15th-Day Cutoff Rule Evaluation:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEndOnOrBefore15th
                              ? '• Probation ends on or before the 15th (${_calculatedProbationEndDate.day}th). That month counts as the FIRST eligible accrual month!'
                              : '• Probation ends after the 15th (${_calculatedProbationEndDate.day}th). That month does NOT count. First eligible month begins in ${_formatDate(_firstEligibleAccrualDate)}.',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Non-Negotiable Rules Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 14),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Earned Leave Accrual = 0.0 during probation',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No retroactive grant for probation months', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Accrual Proration Simulator
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text('Policy Cycle Simulation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
                      ChoiceChip(
                        label: const Text('Quarterly (1.5 leaves)', style: TextStyle(fontSize: 11)),
                        selected: _probationPolicyCycle == 'Quarterly',
                        selectedColor: t.primary,
                        onSelected: (_) => setState(() => _probationPolicyCycle = 'Quarterly'),
                      ),
                      ChoiceChip(
                        label: const Text('Half-Yearly (3.0 leaves)', style: TextStyle(fontSize: 11)),
                        selected: _probationPolicyCycle == 'Half-Yearly',
                        selectedColor: t.primary,
                        onSelected: (_) => setState(() => _probationPolicyCycle = 'Half-Yearly'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prorated Entitlement on Completion: ${proration['creditedLeaves']} Earned Leave (${proration['remainingMonths']} eligible month(s) × ${proration['monthlyShare']} leave/month)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Notice Period Section ---
  Widget _buildNoticePeriodSection(AppThemeConfig t, bool isDark) {
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isNoticePeriod 
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5) 
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: _isNoticePeriod ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isNoticePeriod ? const Color(0xFF8B5CF6).withValues(alpha: 0.08) : Colors.transparent,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.exit_to_app_rounded, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Notice Period Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        if (_isNoticePeriod)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                            ),
                            child: const Text('ON NOTICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                          ),
                      ],
                    ),
                    Text('Manages resignation timeline & leave application restrictions', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isNoticePeriod,
                activeTrackColor: const Color(0xFF8B5CF6),
                onChanged: (val) => setState(() => _isNoticePeriod = val),
              ),
            ],
          ),

          if (_isNoticePeriod) ...[
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerTile(
                    t: t,
                    label: 'Notice Start Date',
                    selectedDate: _noticeStartDate,
                    fallbackText: 'Select Start Date',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDate(
                      context: context,
                      initialDate: _noticeStartDate,
                      onPicked: (d) => _noticeStartDate = d,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notice Duration', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [30, 60, 90].map((days) {
                          final isSel = _noticeDurationDays == days;
                          return ChoiceChip(
                            label: Text('$days Days', style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : textColor)),
                            selected: isSel,
                            selectedColor: const Color(0xFF7C3AED),
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : t.cardSoft,
                            onSelected: (_) => setState(() => _noticeDurationDays = days),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Notice Period End Date & Leave Restrictions Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.event_busy_rounded, color: Color(0xFF7C3AED), size: 18),
                      Text('Last Working Day (LWD): ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                      Text(
                        _formatDate(_calculatedNoticeEndDate),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Non-Negotiable Notice Leave Rules
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.purple.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notice Period Leave Enforcement Rules:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(height: 6),
                        _buildRuleBullet(
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFEF4444),
                          text: 'Normal Leave Blocked: Casual, Sick, and Earned leaves cannot be applied.',
                        ),
                        const SizedBox(height: 4),
                        _buildRuleBullet(
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          text: 'Loss Of Pay (LOP) Allowed: Employee remains authorized to submit LOP requests.',
                        ),
                        const SizedBox(height: 4),
                        _buildRuleBullet(
                          icon: Icons.visibility_rounded,
                          color: const Color(0xFF3B82F6),
                          text: 'Leave Balances Retained: Existing quota balances remain visible and will not be zeroed.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleBullet({required IconData icon, required Color color, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 11.5)),
        ),
      ],
    );
  }

  // --- Status Section ---
  Widget _buildStatusSection(AppThemeConfig t, bool isDark) {
    final textColor = t.surfaceText;
    final textSecondary = t.surfaceTextSecondary;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.toggle_on_outlined, color: Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Employee Status & Deactivation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    Text('Controls employee operational access while preserving historical data', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: _statusOptions.map((st) {
              final isSel = _status == st;
              Color chipColor = t.primary;
              if (st == 'PROBATION') chipColor = const Color(0xFFD97706);
              if (st == 'NOTICE_PERIOD') chipColor = const Color(0xFF7C3AED);
              if (st == 'INACTIVE') chipColor = const Color(0xFFEF4444);

              return ChoiceChip(
                label: Text(
                  st.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : textColor,
                  ),
                ),
                selected: isSel,
                selectedColor: chipColor,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : t.cardSoft,
                onSelected: (_) {
                  setState(() {
                    _status = st;
                    if (st == 'PROBATION') _isProbation = true;
                    if (st == 'NOTICE_PERIOD') _isNoticePeriod = true;
                  });
                },
              );
            }).toList(),
          ),
          if (_status == 'INACTIVE') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Soft Deactivation Active: Account login is disabled, but all historical records (leaves, approvals, attendance, audit trail) are strictly preserved.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Action Buttons ---
  Widget _buildActionButtons(AppThemeConfig t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final isNarrow = constraints.maxWidth < (textScale > 1.2 ? 700 : 450);
        final cancelButton = OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: t.border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Cancel', style: TextStyle(color: t.surfaceTextSecondary, fontWeight: FontWeight.w600)),
          ),
        );

        final saveButton = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [t.primary, Color.lerp(t.primary, Colors.tealAccent, 0.3) ?? t.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(isEdit ? Icons.save_rounded : Icons.person_add_rounded, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _isLoading
                    ? 'Saving...'
                    : (isEdit ? 'Save Employee Changes' : 'Create Employee Profile'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
              ),
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              const SizedBox(height: 12),
              cancelButton,
            ],
          );
        }

        return Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            cancelButton,
            saveButton,
          ],
        );
      },
    );
  }
}
