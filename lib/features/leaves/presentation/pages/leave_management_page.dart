import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import '../../../../core/services/auth_storage.dart';
import '../widgets/apply_leave_dialog.dart';

class QuotaGridCardItem {
  final String title;
  final String key;
  final Color color;
  final IconData icon;

  const QuotaGridCardItem({
    required this.title,
    required this.key,
    required this.color,
    required this.icon,
  });
}

class LeaveManagementPage extends StatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  State<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends State<LeaveManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';

  // Live employee leave balances (Default initial HR quota for all employees)
  final Map<String, double> _balances = {
    'Earned Leave': 12.0,
    'Casual Leave': 12.0,
    'Sick Leave': 10.0,
    'Work From Home': 15.0,
    'Comp - Off': 2.0,
    'Birthday Leave': 1.0,
    'Bereavement Leave': 5.0,
    'Paternity Leave': 5.0,
    'Loss Of Pay': 0.0,
  };

  // Initial total quota limits for progress calculation
  final Map<String, double> _quotaLimits = {
    'Earned Leave': 12.0,
    'Casual Leave': 12.0,
    'Sick Leave': 10.0,
    'Work From Home': 15.0,
    'Comp - Off': 2.0,
    'Birthday Leave': 1.0,
    'Bereavement Leave': 5.0,
    'Paternity Leave': 5.0,
    'Loss Of Pay': 10.0,
  };

  List<dynamic> _myLeaves = [];
  List<dynamic> _pendingApprovals = [];

  final String _baseUrl = 'http://localhost:8080/api/v1/leaves';

  static const List<QuotaGridCardItem> _quotaGridItems = [
    QuotaGridCardItem(
      title: 'Earned Leave',
      key: 'Earned Leave',
      color: Color(0xFF10B981),
      icon: Icons.umbrella_rounded,
    ),
    QuotaGridCardItem(
      title: 'Casual Leave',
      key: 'Casual Leave',
      color: Color(0xFFD97706),
      icon: Icons.work_history_outlined,
    ),
    QuotaGridCardItem(
      title: 'Sick Leave',
      key: 'Sick Leave',
      color: Color(0xFF0284C7),
      icon: Icons.health_and_safety_outlined,
    ),
    QuotaGridCardItem(
      title: 'Work From Home',
      key: 'Work From Home',
      color: Color(0xFF475569),
      icon: Icons.home_work_outlined,
    ),
    QuotaGridCardItem(
      title: 'Comp - Off',
      key: 'Comp - Off',
      color: Color(0xFF059669),
      icon: Icons.card_membership_outlined,
    ),
    QuotaGridCardItem(
      title: 'Birthday Leave',
      key: 'Birthday Leave',
      color: Color(0xFFF43F5E),
      icon: Icons.cake_outlined,
    ),
    QuotaGridCardItem(
      title: 'Bereavement',
      key: 'Bereavement Leave',
      color: Color(0xFF8B5CF6),
      icon: Icons.people_outline_rounded,
    ),
    QuotaGridCardItem(
      title: 'Paternity Leave',
      key: 'Paternity Leave',
      color: Color(0xFF7C3AED),
      icon: Icons.child_care_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeaveData();
  }

  Future<void> _fetchLeaveData() async {
    setState(() => _isLoading = true);
    final headers = AuthStorage.authHeaders;
    final empId = AuthStorage.employeeId ?? 1;

    try {
      // 1. Fetch employee leave balances from DB
      final balanceRes = await http.get(Uri.parse('$_baseUrl/balance/$empId'), headers: headers);
      if (balanceRes.statusCode == 200) {
        final Map<String, dynamic> b = json.decode(balanceRes.body);
        _balances['Casual Leave'] = (b['casualLeaveRemaining'] as num?)?.toDouble() ?? 11.0;
        _balances['Sick Leave'] = (b['sickLeaveRemaining'] as num?)?.toDouble() ?? 8.0;
        _balances['Earned Leave'] = (b['earnedLeaveRemaining'] as num?)?.toDouble() ?? 12.0;
        _balances['Work From Home'] = (b['workFromHomeRemaining'] as num?)?.toDouble() ?? 0.0;

        _quotaLimits['Casual Leave'] = (b['casualLeaveQuota'] as num?)?.toDouble() ?? 12.0;
        _quotaLimits['Sick Leave'] = (b['sickLeaveQuota'] as num?)?.toDouble() ?? 10.0;
        _quotaLimits['Earned Leave'] = (b['earnedLeaveQuota'] as num?)?.toDouble() ?? 15.0;
        _quotaLimits['Work From Home'] = (b['workFromHomeQuota'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Fetch employee leave history from DB
      final myLeavesRes = await http.get(Uri.parse('$_baseUrl/employee/$empId'), headers: headers);
      if (myLeavesRes.statusCode == 200) {
        final List<dynamic> decoded = json.decode(myLeavesRes.body);
        if (decoded.isNotEmpty) {
          _myLeaves = decoded.map((item) {
            final rawType = (item['leaveType'] as String? ?? 'Casual Leave');
            final formattedType = rawType
                .replaceAll('_', ' ')
                .toLowerCase()
                .split(' ')
                .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                .join(' ');
            final leaveTitle = formattedType.contains('Leave') ? formattedType : '$formattedType Leave';

            return {
              'id': item['id'],
              'leaveType': leaveTitle,
              'category': 'Leave',
              'totalDays': (item['totalDays'] as num?)?.toDouble() ?? 1.0,
              'appliedOn': item['startDate'] ?? 'Today',
              'startDate': item['startDate'] ?? 'Today',
              'startSession': 'Session 1',
              'endDate': item['endDate'] ?? 'Today',
              'endSession': 'Session 2',
              'reason': item['reason'] ?? 'Leave Request',
              'status': item['status'] ?? 'PENDING',
            };
          }).toList();
        } else {
          _seedMockLeaves();
        }
      } else {
        _seedMockLeaves();
      }

      // 3. Fetch pending approval requests for Manager / HR
      final endpoint = AuthStorage.isHr ? '$_baseUrl/pending/all' : '$_baseUrl/pending/manager/$empId';
      final pendingRes = await http.get(Uri.parse(endpoint), headers: headers);
      if (pendingRes.statusCode == 200) {
        final List<dynamic> pendingList = json.decode(pendingRes.body);
        if (pendingList.isNotEmpty) {
          _pendingApprovals = pendingList;
        }
      }
    } catch (e) {
      debugPrint('Backend leave fetch fallback: $e');
      _seedMockLeaves();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seedMockLeaves() {
    if (_myLeaves.isEmpty) {
      _myLeaves = [
        {
          'id': 101,
          'leaveType': 'Birthday Leave',
          'category': 'Leave',
          'totalDays': 0.5,
          'appliedOn': '19 Mar 2026',
          'startDate': '19 Mar 2026',
          'startSession': 'Session 2',
          'endDate': '19 Mar 2026',
          'endSession': 'Session 2',
          'reason': 'Birthday half-day off',
          'status': 'PENDING',
        },
        {
          'id': 102,
          'leaveType': 'Casual Leave',
          'category': 'Leave',
          'totalDays': 1.0,
          'appliedOn': '10 Feb 2026',
          'startDate': '14 Feb 2026',
          'startSession': 'Session 1',
          'endDate': '14 Feb 2026',
          'endSession': 'Session 2',
          'reason': 'Personal errands',
          'status': 'APPROVED',
        },
        {
          'id': 103,
          'leaveType': 'Earned Leave',
          'category': 'Leave',
          'totalDays': 2.0,
          'appliedOn': '05 Jan 2026',
          'startDate': '10 Jan 2026',
          'startSession': 'Session 1',
          'endDate': '11 Jan 2026',
          'endSession': 'Session 2',
          'reason': 'Family trip',
          'status': 'APPROVED',
        },
      ];
    }

    if (_pendingApprovals.isEmpty) {
      _pendingApprovals = [
        {
          'id': 301,
          'employeeId': 3,
          'employeeName': 'Priya Patel',
          'employeeEmail': 'priya.patel@company.com',
          'leaveType': 'Sick Leave',
          'totalDays': 2.0,
          'startDate': '2026-08-05',
          'endDate': '2026-08-06',
          'reason': 'Personal Medical Leave',
          'status': 'PENDING',
        },
        {
          'id': 302,
          'employeeId': 15,
          'employeeName': 'Neha Verma',
          'employeeEmail': 'neha.verma@company.com',
          'leaveType': 'Sick Leave',
          'totalDays': 2.0,
          'startDate': '2026-08-30',
          'endDate': '2026-08-31',
          'reason': 'Dental procedure',
          'status': 'PENDING',
        },
        {
          'id': 303,
          'employeeId': 14,
          'employeeName': 'Rohan Gupta',
          'employeeEmail': 'rohan.gupta@company.com',
          'leaveType': 'Casual Leave',
          'totalDays': 3.0,
          'startDate': '2026-08-27',
          'endDate': '2026-08-29',
          'reason': 'Personal work & family commitment',
          'status': 'PENDING',
        },
      ];
    }
  }

  Future<void> _applyForLeaveFromMap(Map<String, dynamic> data) async {
    final type = data['leaveType'] as String;
    final fromDateStr = data['fromDate'] as String;
    final toDateStr = data['toDate'] as String;
    final fromSession = data['fromSession'] as String;
    final toSession = data['toSession'] as String;

    double days = 1.0;
    try {
      final start = DateTime.parse(fromDateStr);
      final end = DateTime.parse(toDateStr);
      final diff = end.difference(start).inDays + 1;
      if (diff == 1 && (fromSession != 'Session 1' || toSession != 'Session 2')) {
        days = 0.5;
      } else {
        days = diff.toDouble();
      }
    } catch (_) {}

    final empId = data['onBehalfEmployeeId'] != null
        ? int.tryParse(data['onBehalfEmployeeId'].toString()) ?? 1
        : AuthStorage.employeeId ?? 1;
    final body = json.encode({
      'employeeId': empId,
      'startDate': fromDateStr,
      'endDate': toDateStr,
      'leaveType': type.toUpperCase().replaceAll(' ', '_'),
      'totalDays': days,
      'reason': data['reason'] ?? '',
      if (data['startTime'] != null) 'startTime': data['startTime'],
      if (data['endTime'] != null) 'endTime': data['endTime'],
    });

    try {
      final isAdminApply = AuthStorage.isHr && data['onBehalfEmployeeId'] != null;
      final url = isAdminApply
          ? Uri.parse('$_baseUrl/admin/apply-on-behalf')
          : Uri.parse('$_baseUrl/apply');

      final res = await http.post(
        url,
        headers: AuthStorage.authHeaders,
        body: body,
      );
      debugPrint('Apply leave response status: ${res.statusCode}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Refetch all data from backend for authoritative state
        await _fetchLeaveData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied for $days day(s) of $type successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        if (!mounted) return;
        final errorBody = res.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply: $errorBody'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Apply leave backend call exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying leave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _withdrawLeave(dynamic leave) {
    final type = leave['leaveType'] as String;
    final days = (leave['totalDays'] as num).toDouble();

    setState(() {
      _myLeaves.removeWhere((l) => l['id'] == leave['id']);
      if (_balances.containsKey(type)) {
        final limit = _quotaLimits[type] ?? 12.0;
        _balances[type] = (_balances[type]! + days).clamp(0.0, limit);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Withdrew $type request. Restored $days day(s) to balance.'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Future<void> _updateLeaveStatus(int leaveId, String status, {String? rejectionReason}) async {
    final approverId = AuthStorage.employeeId ?? 1;
    final body = json.encode({
      'status': status,
      'rejectionReason': rejectionReason ?? '',
      'approverId': approverId.toString(),
    });

    try {
      await http.put(
        Uri.parse('$_baseUrl/$leaveId/status'),
        headers: AuthStorage.authHeaders,
        body: body,
      );
      // Refetch all data from backend so balances update after approval
      await _fetchLeaveData();
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave request $status!'),
        backgroundColor: status == 'APPROVED' ? const Color(0xFF10B981) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leave Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Quotas',
            onPressed: _fetchLeaveData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: AuthStorage.isHr
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0D9488),
                labelColor: const Color(0xFF0D9488),
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline), text: 'My Leaves & Quotas'),
                  Tab(icon: Icon(Icons.approval_outlined), text: 'Team Approvals'),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyRequestOptions,
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          // Admin always applies on behalf of an employee, not for themselves
          AuthStorage.isHr ? 'Apply On Behalf of Employee' : 'Apply Request',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
            : (AuthStorage.isHr
                // Admin: directly shows the approvals view — no personal My Leaves tab
                ? _buildPendingApprovalsView(isDark)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyLeavesDashboard(isDark),
                      _buildPendingApprovalsView(isDark),
                    ],
                  )),
      ),
    );
  }

  Widget _buildMyLeavesDashboard(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dashboard Welcome Hero Banner
          _buildHeroBanner(isDark),
          const SizedBox(height: 28),

          // 2. Leave Quotas Grid (Desktop 4-col / Mobile 2-col)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Quota Balances',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Allocated by HR Admin',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildQuotaGrid(isDark),
          const SizedBox(height: 32),

          // 3. Responsive Main Grid (Left: Request History, Right: Company Holidays & Guidelines)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 850;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildHistorySection(isDark),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _buildSidebarSection(isDark),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildHistorySection(isDark),
                    const SizedBox(height: 24),
                    _buildSidebarSection(isDark),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Gradient Welcome Hero Banner matching Dashboard
  Widget _buildHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.beach_access_rounded, color: Color(0xFFFACC15), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'LIVE LEAVE PORTAL',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Account for your absence by managing leaves 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Apply for time off, monitor remaining quotas, and track request approvals in real-time.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showApplyRequestOptions,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  // Quota Grid Cards
  Widget _buildQuotaGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.45,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: _quotaGridItems.length,
          itemBuilder: (context, index) {
            final item = _quotaGridItems[index];
            final rem = _balances[item.key] ?? 0.0;
            final limit = _quotaLimits[item.key] ?? 12.0;
            final color = item.color;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: color, size: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$rem',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Out of ${limit.toInt()} Allocated Days',
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: limit > 0 ? (rem / limit).clamp(0.0, 1.0) : 0,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
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

  // Filterable Request History Section
  Widget _buildHistorySection(bool isDark) {
    final filtered = _myLeaves.where((leave) {
      if (_selectedStatusFilter == 'All') return true;
      return (leave['status'] as String).toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Request History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length} Requests',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedStatusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          if (filtered.isEmpty)
            _buildEmptyState('No leave requests found for status "$_selectedStatusFilter"')
          else
            ...filtered.map((leave) => _buildInspirationLeaveCard(leave, isDark)),
        ],
      ),
    );
  }

  // Card matching screenshot 6 & 7 exactly
  Widget _buildInspirationLeaveCard(dynamic leave, bool isDark) {
    final leaveType = leave['leaveType'] ?? 'Leave';
    final totalDays = leave['totalDays'] ?? 1.0;
    final category = leave['category'] ?? 'Leave';
    final appliedOn = leave['appliedOn'] ?? '19 Mar 2026';
    final startDate = leave['startDate'] ?? '19 Mar 2026';
    final startSession = leave['startSession'] ?? 'Session 1';
    final endDate = leave['endDate'] ?? '19 Mar 2026';
    final endSession = leave['endSession'] ?? 'Session 2';
    final status = leave['status'] ?? 'PENDING';

    final isPending = status == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Chip Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: const Color(0xFFA7F3D0).withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$leaveType - $totalDays day(s)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'APPROVED'
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : status == 'REJECTED'
                                ? Colors.red.withValues(alpha: 0.15)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'APPROVED'
                              ? const Color(0xFF10B981)
                              : status == 'REJECTED'
                                  ? Colors.red
                                  : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.north_east_rounded, size: 16, color: Color(0xFF0D9488)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(width: 32),
                    const Icon(Icons.check_box_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Applied on', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(appliedOn, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(startDate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(startSession, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('—', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(endDate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(endSession, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _withdrawLeave(leave),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Right Sidebar Component (Holidays & Company Guidelines)
  Widget _buildSidebarSection(bool isDark) {
    return Column(
      children: [
        // Upcoming Holidays Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Holidays',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF0D9488)),
                ],
              ),
              const SizedBox(height: 16),
              _buildHolidayItem('Diwali Festival', 'Oct 31, 2026', 'Mandatory', isDark),
              const SizedBox(height: 10),
              _buildHolidayItem('Christmas Day', 'Dec 25, 2026', 'Mandatory', isDark),
              const SizedBox(height: 10),
              _buildHolidayItem("New Year's Eve", 'Dec 31, 2026', 'Restricted', isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Policy Guidelines Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Text(
                    'Leave Policy Highlights',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Leave requests exceeding 3 consecutive days require manager approval at least 48 hours prior.\n'
                '• Unused Sick Leave and Casual Leave auto-reset at fiscal year-end.\n'
                '• Session 1 represents morning hours (09:00 AM - 01:30 PM), Session 2 represents afternoon hours (01:30 PM - 06:00 PM).',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHolidayItem(String name, String date, String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tag == 'Mandatory' ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: tag == 'Mandatory' ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending Team Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Chip(
                label: Text('${_pendingApprovals.length} Pending', style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _pendingApprovals.isEmpty
                ? _buildEmptyState('No pending approval requests.')
                : ListView.builder(
                    itemCount: _pendingApprovals.length,
                    itemBuilder: (context, index) {
                      final leave = _pendingApprovals[index];
                      return _buildApprovalCard(leave, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getMockEmployeeName(dynamic empId) {
    final Map<dynamic, String> names = {
      1: 'Harsh Kaushal',
      2: 'Aarav Sharma',
      3: 'Priya Patel',
      14: 'Rohan Gupta',
      15: 'Neha Verma',
    };
    return names[empId] ?? 'Team Member #${empId ?? 1}';
  }

  String _getMockEmployeeEmail(dynamic empId) {
    final Map<dynamic, String> emails = {
      1: 'harsh.k@company.com',
      2: 'aarav.s@company.com',
      3: 'priya.p@company.com',
      14: 'rohan.g@company.com',
      15: 'neha.v@company.com',
    };
    return emails[empId] ?? 'employee${empId ?? 1}@company.com';
  }

  Widget _buildApprovalCard(dynamic leave, bool isDark) {
    final empId = leave['employeeId'];
    final empName = leave['employeeName'] ?? leave['employee']?['name'] ?? _getMockEmployeeName(empId);
    final empEmail = leave['employeeEmail'] ?? leave['employee']?['email'] ?? _getMockEmployeeEmail(empId);
    final leaveType = leave['leaveType'] ?? leave['type'] ?? 'Casual Leave';
    final totalDays = leave['totalDays'] ?? leave['days'] ?? 1.0;
    final startDate = leave['startDate'] ?? '2026-08-25';
    final endDate = leave['endDate'] ?? '2026-08-26';
    final reason = leave['reason'] ?? 'None provided';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  child: Text(
                    empName.isNotEmpty ? empName[0] : 'E',
                    style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        empEmail,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$leaveType ($totalDays Days)',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Dates: $startDate ➔ $endDate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reason: $reason', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _updateLeaveStatus(leave['id'], 'REJECTED', rejectionReason: 'Manager Rejected'),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _updateLeaveStatus(leave['id'], 'APPROVED'),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showApplyRequestOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AuthStorage.isHr ? 'Apply Request on Behalf of Employee' : 'Apply Request',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildApplyOptionTile(
                  icon: Icons.luggage_outlined,
                  color: const Color(0xFF0284C7),
                  title: 'Apply Leave',
                  subtitle: AuthStorage.isHr ? 'Full/half-day leave on behalf of employee' : 'Full day or half day leave',
                  onTap: () {
                    Navigator.pop(context);
                    _openApplyDialog('Leave');
                  },
                ),
                // Time-based exemptions are personal (employee applies for themselves)
                // Admin does NOT see these — they don't personally clock in/out
                if (!AuthStorage.isHr) ...[
                  const SizedBox(height: 12),
                  _buildApplyOptionTile(
                    icon: Icons.coffee_outlined,
                    color: const Color(0xFFF59E0B),
                    title: 'Apply Short Break',
                    subtitle: 'Partial time off during shift',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog('Short Break');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildApplyOptionTile(
                    icon: Icons.directions_run_outlined,
                    color: const Color(0xFF8B5CF6),
                    title: 'Apply Early Out',
                    subtitle: 'Leave work earlier than schedule',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog('Early Out');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildApplyOptionTile(
                    icon: Icons.watch_later_outlined,
                    color: const Color(0xFFEF4444),
                    title: 'Apply Late Arrival',
                    subtitle: 'Permission for arriving after shift start',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog('Late Arrival');
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplyOptionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _openApplyDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => ApplyLeaveDialog(
        initialBalance: _balances,
        initialRequestCategory: category,
        // Admin always applies on behalf of an employee — no self-service apply
        // Employee applies for themselves (targetEmployee is null)
        targetEmployee: null,
        onSubmit: (data) => _applyForLeaveFromMap(data),
      ),
    );
  }
}
