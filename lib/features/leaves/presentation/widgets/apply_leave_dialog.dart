import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class LeaveCategoryItem {
  final String title;
  final IconData icon;
  final Color color;

  const LeaveCategoryItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class LeaveTypeGridOption {
  final String type;
  final double balance;
  final Color color;
  final IconData icon;
  final Color iconColor;

  const LeaveTypeGridOption({
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    required this.iconColor,
  });
}

class ApplyLeaveDialog extends StatefulWidget {
  final Map<String, dynamic>? initialBalance;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Employee? targetEmployee;
  final String? initialRequestCategory; // 'Leave', 'Short Break', 'Early Out'
  final Function(Map<String, dynamic> leaveData) onSubmit;

  const ApplyLeaveDialog({
    super.key,
    this.initialBalance,
    this.initialStartDate,
    this.initialEndDate,
    this.targetEmployee,
    this.initialRequestCategory,
    required this.onSubmit,
  });

  @override
  State<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  int _currentStep = 0; // 0: Category, 1: Leave Type (if Leave), 2: Form Details

  String _selectedCategory = 'Leave';
  String _selectedLeaveType = 'Earned Leave';
  double _leaveBalanceDays = 12.0;

  late DateTime _fromDate;
  String _fromSession = 'Session 1';
  late TimeOfDay _fromTime;

  late DateTime _toDate;
  String _toSession = 'Session 2';
  late TimeOfDay _toTime;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  List<Employee> _allEmployees = [];
  final List<Employee> _selectedCcEmployees = [];
  bool _isLoadingEmployees = true;
  String? _attachedFileName;
  Employee? _selectedOnBehalfEmployee;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialStartDate ?? DateTime.now();
    _toDate = widget.initialEndDate ?? widget.initialStartDate ?? DateTime.now();
    _fromTime = const TimeOfDay(hour: 9, minute: 0);
    _toTime = const TimeOfDay(hour: 11, minute: 0);
    
    if (widget.initialRequestCategory != null) {
      _selectedCategory = widget.initialRequestCategory!;
      if (_selectedCategory == 'Leave') {
        _currentStep = 1; // Take to Leave Type
      } else {
        _currentStep = 2; // Short Break/Early Out go straight to Form
      }
    } else if (widget.initialStartDate != null) {
      _currentStep = 1; // Take directly to Leave Type selection if date was pre-selected from calendar
    }
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final repo = EmployeeRepositoryImpl();
      final list = await repo.getEmployees();
      final nonAdmin = list.where((e) {
        final r = e.role.toUpperCase();
        return r != 'ADMIN' && r != 'SUPERADMIN' && r != 'SUPER_ADMIN';
      }).toList();

      if (mounted) {
        setState(() {
          _allEmployees = nonAdmin.isNotEmpty ? nonAdmin : _getMockNonAdminEmployees();
          if (widget.targetEmployee != null) {
            final matchIndex = _allEmployees.indexWhere((e) => e.id == widget.targetEmployee!.id);
            if (matchIndex != -1) {
              _selectedOnBehalfEmployee = _allEmployees[matchIndex];
            } else {
              _allEmployees.insert(0, widget.targetEmployee!);
              _selectedOnBehalfEmployee = widget.targetEmployee;
            }
          } else if (_allEmployees.isNotEmpty && AuthStorage.isHr) {
            _selectedOnBehalfEmployee = _allEmployees.first;
          }
          _isLoadingEmployees = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allEmployees = _getMockNonAdminEmployees();
          if (widget.targetEmployee != null) {
            final matchIndex = _allEmployees.indexWhere((e) => e.id == widget.targetEmployee!.id);
            if (matchIndex != -1) {
              _selectedOnBehalfEmployee = _allEmployees[matchIndex];
            } else {
              _allEmployees.insert(0, widget.targetEmployee!);
              _selectedOnBehalfEmployee = widget.targetEmployee;
            }
          } else if (_allEmployees.isNotEmpty && AuthStorage.isHr) {
            _selectedOnBehalfEmployee = _allEmployees.first;
          }
          _isLoadingEmployees = false;
        });
      }
    }
  }

  List<Employee> _getMockNonAdminEmployees() {
    return [
      Employee(
        id: '2',
        name: 'Aarav Sharma',
        email: 'aarav.sharma@company.com',
        role: 'Senior Software Engineer',
        department: 'Engineering',
        phone: '+1 555-0102',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1992-05-14',
        emergencyContactName: 'Rita Sharma',
        emergencyContactPhone: '+1 555-9902',
      ),
      Employee(
        id: '3',
        name: 'Priya Patel',
        email: 'priya.patel@company.com',
        role: 'UI/UX Designer',
        department: 'Design',
        phone: '+1 555-0103',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1994-08-22',
        emergencyContactName: 'Kunal Patel',
        emergencyContactPhone: '+1 555-9903',
      ),
      Employee(
        id: '14',
        name: 'Rohan Gupta',
        email: 'rohan.gupta@company.com',
        role: 'Product Manager',
        department: 'Product',
        phone: '+1 555-0114',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1990-11-10',
        emergencyContactName: 'Sunita Gupta',
        emergencyContactPhone: '+1 555-9914',
      ),
      Employee(
        id: '15',
        name: 'Neha Verma',
        email: 'neha.verma@company.com',
        role: 'QA Lead',
        department: 'Quality Assurance',
        phone: '+1 555-0115',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1993-02-18',
        emergencyContactName: 'Amit Verma',
        emergencyContactPhone: '+1 555-9915',
      ),
      Employee(
        id: '16',
        name: 'Vikram Singh',
        email: 'vikram.singh@company.com',
        role: 'Backend Engineer',
        department: 'Engineering',
        phone: '+1 555-0116',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1991-07-04',
        emergencyContactName: 'Meena Singh',
        emergencyContactPhone: '+1 555-9916',
      ),
      Employee(
        id: '17',
        name: 'Ananya Roy',
        email: 'ananya.roy@company.com',
        role: 'HR Specialist',
        department: 'Human Resources',
        phone: '+1 555-0117',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1995-12-01',
        emergencyContactName: 'Sanjay Roy',
        emergencyContactPhone: '+1 555-9917',
      ),
      Employee(
        id: '18',
        name: 'Karan Mehta',
        email: 'karan.mehta@company.com',
        role: 'DevOps Specialist',
        department: 'Infrastructure',
        phone: '+1 555-0118',
        status: 'Active',
        managerName: 'Harsh Kaushal',
        dateOfBirth: '1989-09-30',
        emergencyContactName: 'Pooja Mehta',
        emergencyContactPhone: '+1 555-9918',
      ),
    ];
  }

  static const List<LeaveCategoryItem> _categories = [
    LeaveCategoryItem(
      title: 'Leave',
      icon: Icons.luggage_outlined,
      color: Color(0xFF0284C7),
    ),
    LeaveCategoryItem(
      title: 'Late Arrival',
      icon: Icons.access_time_outlined,
      color: Color(0xFFEF4444),
    ),
    LeaveCategoryItem(
      title: 'Short Break',
      icon: Icons.coffee_outlined,
      color: Color(0xFFF59E0B),
    ),
    LeaveCategoryItem(
      title: 'Early Out',
      icon: Icons.directions_run_outlined,
      color: Color(0xFF8B5CF6),
    ),
    LeaveCategoryItem(
      title: 'Restricted Holiday',
      icon: Icons.edit_calendar_outlined,
      color: Color(0xFF10B981),
    ),
    LeaveCategoryItem(
      title: 'Comp Off Grant',
      icon: Icons.card_giftcard_outlined,
      color: Color(0xFF059669),
    ),
  ];

  List<LeaveTypeGridOption> get _leaveTypes {
    final b = widget.initialBalance ?? {};
    return [
      LeaveTypeGridOption(
        type: 'Earned Leave',
        balance: (b['Earned Leave'] as num?)?.toDouble() ?? 12.0,
        color: const Color(0xFFECFDF5),
        icon: Icons.umbrella_rounded,
        iconColor: const Color(0xFF10B981),
      ),
      LeaveTypeGridOption(
        type: 'Casual Leave',
        balance: (b['Casual Leave'] as num?)?.toDouble() ?? 12.0,
        color: const Color(0xFFFEF3C7),
        icon: Icons.work_history_outlined,
        iconColor: const Color(0xFFD97706),
      ),
      LeaveTypeGridOption(
        type: 'Sick Leave',
        balance: (b['Sick Leave'] as num?)?.toDouble() ?? 10.0,
        color: const Color(0xFFE0F2FE),
        icon: Icons.health_and_safety_outlined,
        iconColor: const Color(0xFF0284C7),
      ),
      LeaveTypeGridOption(
        type: 'Work From Home',
        balance: (b['Work From Home'] as num?)?.toDouble() ?? 15.0,
        color: const Color(0xFFF1F5F9),
        icon: Icons.home_work_outlined,
        iconColor: const Color(0xFF475569),
      ),
      LeaveTypeGridOption(
        type: 'Comp - Off',
        balance: (b['Comp - Off'] as num?)?.toDouble() ?? 2.0,
        color: const Color(0xFFECFDF5),
        icon: Icons.card_membership_outlined,
        iconColor: const Color(0xFF059669),
      ),
      LeaveTypeGridOption(
        type: 'Birthday Leave',
        balance: (b['Birthday Leave'] as num?)?.toDouble() ?? 1.0,
        color: const Color(0xFFFFF1F2),
        icon: Icons.cake_outlined,
        iconColor: const Color(0xFFF43F5E),
      ),
      LeaveTypeGridOption(
        type: 'Bereavement Leave',
        balance: (b['Bereavement Leave'] as num?)?.toDouble() ?? 5.0,
        color: const Color(0xFFF5F3FF),
        icon: Icons.people_outline_rounded,
        iconColor: const Color(0xFF8B5CF6),
      ),
      LeaveTypeGridOption(
        type: 'Paternity Leave',
        balance: (b['Paternity Leave'] as num?)?.toDouble() ?? 5.0,
        color: const Color(0xFFF5F3FF),
        icon: Icons.child_care_outlined,
        iconColor: const Color(0xFF7C3AED),
      ),
      LeaveTypeGridOption(
        type: 'Loss Of Pay',
        balance: (b['Loss Of Pay'] as num?)?.toDouble() ?? 0.0,
        color: const Color(0xFFFEF2F2),
        icon: Icons.money_off_outlined,
        iconColor: const Color(0xFFDC2626),
      ),
    ];
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      if (cat == 'Short Break' || cat == 'Early Out') {
        _currentStep = 2; // Skip Leave Type for Short Break/Early Out
      } else {
        _currentStep = 1;
      }
    });
  }

  void _selectLeaveType(LeaveTypeGridOption item) {
    setState(() {
      _selectedLeaveType = item.type;
      _leaveBalanceDays = item.balance;
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Column(
            children: [
              // Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _currentStep == 0
                          ? 'Apply Category'
                          : _currentStep == 1
                              ? 'Leave Type'
                              : (_selectedCategory == 'Leave' ? _selectedLeaveType : _selectedCategory),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _currentStep == 0
                      ? _buildStep0Categories(isDark)
                      : _currentStep == 1
                          ? _buildStep1LeaveTypeGrid(isDark)
                          : _buildStep2Form(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 0: Category Selection
  Widget _buildStep0Categories(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Select Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose what type of request you wish to submit.',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        ..._categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _selectCategory(cat.title),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        cat.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // Step 1: Leave Type Selection Grid
  Widget _buildStep1LeaveTypeGrid(bool isDark) {
    final leaveOptions = _leaveTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap to select a leave type to continue.',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  children: const [
                    TextSpan(text: 'Your leaves as of '),
                    TextSpan(text: 'today ', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    TextSpan(text: 'are:'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: leaveOptions.length,
            itemBuilder: (context, index) {
              final item = leaveOptions[index];
              return InkWell(
                onTap: () => _selectLeaveType(item),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : item.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : item.iconColor.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.balance}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: item.iconColor, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Step 2: Form Details
  Widget _buildStep2Form(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (AuthStorage.isHr) ...[
            Text('Apply On Behalf Of Employee*', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Employee>(
                  isExpanded: true,
                  value: _selectedOnBehalfEmployee,
                  hint: const Text('Select Employee'),
                  dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  items: _allEmployees.map((emp) {
                    return DropdownMenuItem<Employee>(
                      value: emp,
                      child: Text(emp.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    );
                  }).toList(),
                  onChanged: widget.targetEmployee != null ? null : (emp) {
                    setState(() {
                      _selectedOnBehalfEmployee = emp;
                    });
                  },
                ),
              ),
            ),
          ] else ...[
            // Leave Balance Top Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.umbrella_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leave Balance', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$_leaveBalanceDays days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // FROM Section Card
          _buildDateSessionCard(
            title: 'From',
            selectedDate: _fromDate,
            selectedSession: _fromSession,
            selectedTime: _fromTime,
            isTimeMode: _selectedCategory == 'Short Break' || _selectedCategory == 'Early Out' || _selectedCategory == 'Late Arrival',
            isDark: isDark,
            onDateTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fromDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _fromDate = picked;
                  // Logically ensure To Date is never before From Date
                  if (_toDate.isBefore(_fromDate)) {
                    _toDate = _fromDate;
                  }
                });
              }
            },
            onSessionChanged: (val) => setState(() => _fromSession = val!),
            onTimeTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _fromTime,
              );
              if (picked != null) setState(() => _fromTime = picked);
            },
          ),
          const SizedBox(height: 16),

          // TO Section Card (Only show if it's 'Leave', Short Break/Early Out only need one date/time usually, but let's allow end time)
          _buildDateSessionCard(
            title: 'To',
            selectedDate: _toDate,
            selectedSession: _toSession,
            selectedTime: _toTime,
            isTimeMode: _selectedCategory == 'Short Break' || _selectedCategory == 'Early Out' || _selectedCategory == 'Late Arrival',
            isDark: isDark,
            onDateTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _toDate,
                firstDate: _fromDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _toDate = picked);
            },
            onSessionChanged: (val) => setState(() => _toSession = val!),
            onTimeTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _toTime,
              );
              if (picked != null) setState(() => _toTime = picked);
            },
          ),
          const SizedBox(height: 20),

          // Applying to (Assigned Manager Chip) Section
          Text('Applying to (Assigned Approver)*', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
                  child: const Text('HK', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harsh Kaushal (Engineering Lead)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                    Text('Assigned Reporting Manager • #EMP-101', style: TextStyle(fontSize: 10, color: Color(0xFF047857))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),


          // CC Section Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text('CC:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20, color: Color(0xFF3B82F6)),
                      onPressed: _showAddCcPicker,
                    ),
                  ],
                ),
                if (_selectedCcEmployees.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCcEmployees.map((emp) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          child: Text(
                            emp.name.isNotEmpty ? emp.name[0] : 'E',
                            style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        label: Text(emp.name, style: const TextStyle(fontSize: 12)),
                        onDeleted: () {
                          setState(() {
                            _selectedCcEmployees.remove(emp);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reason Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write here',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Attachment Box Card
          InkWell(
            onTap: () {
              setState(() {
                _attachedFileName = 'medical_document.pdf';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attached medical_document.pdf'), backgroundColor: Color(0xFF0D9488)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedFileName != null ? _attachedFileName! : 'Attachment',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Upload only pdf, xls, xlsx, doc, docx, txt, ppt, pptx, gif, jpg, jpeg, png',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contact Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    hintText: 'Write here',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bottom Action Submit Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Apply', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSessionCard({
    required String title,
    required DateTime selectedDate,
    required String selectedSession,
    required bool isDark,
    required VoidCallback onDateTap,
    required ValueChanged<String?> onSessionChanged,
    TimeOfDay? selectedTime,
    bool isTimeMode = false,
    VoidCallback? onTimeTap,
  }) {
    final dateStr = '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}';
    final timeStr = selectedTime != null ? selectedTime.format(context) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          InkWell(
            onTap: onDateTap,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF3B82F6)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(dateStr, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (isTimeMode) ...[
            Text('Select $title Time', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: onTimeTap,
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  Text(timeStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                ],
              ),
            ),
          ] else ...[
            Text('Select $title Session', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onSessionChanged('Session 1'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            selectedSession == 'Session 1' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selectedSession == 'Session 1' ? const Color(0xFF3B82F6) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Session 1', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => onSessionChanged('Session 2'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            selectedSession == 'Session 2' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selectedSession == 'Session 2' ? const Color(0xFF3B82F6) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Session 2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddCcPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add in CC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Select colleagues to notify regarding this leave request.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  if (_isLoadingEmployees)
                    const Center(child: CircularProgressIndicator())
                  else if (_allEmployees.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No employees available.')))
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        itemCount: _allEmployees.length,
                        itemBuilder: (context, index) {
                          final emp = _allEmployees[index];
                          final isSelected = _selectedCcEmployees.contains(emp);
                          return CheckboxListTile(
                            secondary: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              child: Text(
                                emp.name.isNotEmpty ? emp.name[0] : 'E',
                                style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('${emp.email}\n${emp.role} • ${emp.department}', style: const TextStyle(fontSize: 11, height: 1.3)),
                            isThreeLine: true,
                            value: isSelected,
                            activeColor: const Color(0xFF3B82F6),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  _selectedCcEmployees.add(emp);
                                } else {
                                  _selectedCcEmployees.remove(emp);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitForm() {
    final leaveData = {
      'category': _selectedCategory,
      'leaveType': _selectedCategory == 'Leave' ? _selectedLeaveType : _selectedCategory,
      'fromDate': _fromDate.toIso8601String().split('T')[0],
      'fromSession': _fromSession,
      'toDate': _selectedCategory == 'Leave' ? _toDate.toIso8601String().split('T')[0] : _fromDate.toIso8601String().split('T')[0],
      'toSession': _toSession,
      'startTime': _selectedCategory != 'Leave' ? '${_fromTime.hour.toString().padLeft(2, '0')}:${_fromTime.minute.toString().padLeft(2, '0')}' : null,
      'endTime': _selectedCategory != 'Leave' ? '${_toTime.hour.toString().padLeft(2, '0')}:${_toTime.minute.toString().padLeft(2, '0')}' : null,
      'reason': _reasonController.text,
      'contactDetails': _contactController.text,
      'ccEmployees': _selectedCcEmployees.map((e) => e.name).toList(),
      'attachment': _attachedFileName,
      if (AuthStorage.isHr && _selectedOnBehalfEmployee != null)
        'onBehalfEmployeeId': _selectedOnBehalfEmployee!.id,
    };

    widget.onSubmit(leaveData);
    Navigator.pop(context);
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }
}
