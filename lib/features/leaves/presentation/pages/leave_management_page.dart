import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/core/network/api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_client.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';

import '../../../../core/services/auth_storage.dart';
import '../widgets/apply_leave_dialog.dart';
import 'package:hr_management/core/widgets/skeleton_loaders.dart';

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
  http.Client get _http => ApiClient.client;
  Employee? _currentEmployee;
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';

  bool _hasError = false;
  String? _errorMessage;

  // Live employee leave balances
  final Map<String, double> _balances = {
    'Earned Leave': 0.0,
    'Casual Leave': 0.0,
    'Sick Leave': 0.0,
    'Work From Home': 0.0,
    'Comp - Off': 0.0,
    'Birthday Leave': 0.0,
    'Bereavement Leave': 0.0,
    'Paternity Leave': 0.0,
    'Loss Of Pay': 0.0,
  };

  // Initial total quota limits for progress calculation
  final Map<String, double> _quotaLimits = {
    'Earned Leave': 0.0,
    'Casual Leave': 0.0,
    'Sick Leave': 0.0,
    'Work From Home': 0.0,
    'Comp - Off': 0.0,
    'Birthday Leave': 0.0,
    'Bereavement Leave': 0.0,
    'Paternity Leave': 0.0,
    'Loss Of Pay': 0.0,
  };

  List<dynamic> _myLeaves = [];
  List<dynamic> _pendingApprovals = [];

  String get _baseUrl => "${ApiConfig.baseUrl}/api/v1/leaves";

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
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    final headers = AuthStorage.authHeaders;
    final empId = AuthStorage.employeeId ?? 1;
    try {
      final empRepo = EmployeeRepositoryImpl();
      _currentEmployee = await empRepo.getEmployeeById(empId.toString());
    } catch (_) {}

    try {
      // 1. Fetch employee leave balances from DB (fresh, un-cached)
      final t = DateTime.now().millisecondsSinceEpoch;
      final balanceRes = await _http.get(Uri.parse('$_baseUrl/balance/$empId?t=$t'), headers: headers);
      if (balanceRes.statusCode == 200) {
        final Map<String, dynamic> b = json.decode(balanceRes.body);
        _balances['Casual Leave'] = (b['casualLeaveRemaining'] as num?)?.toDouble() ?? 0.0;
        _balances['Sick Leave'] = (b['sickLeaveRemaining'] as num?)?.toDouble() ?? 0.0;
        _balances['Earned Leave'] = (b['earnedLeaveRemaining'] as num?)?.toDouble() ?? 0.0;
        _balances['Work From Home'] = (b['workFromHomeRemaining'] as num?)?.toDouble() ?? 0.0;

        _quotaLimits['Casual Leave'] = (b['casualLeaveQuota'] as num?)?.toDouble() ?? 0.0;
        _quotaLimits['Sick Leave'] = (b['sickLeaveQuota'] as num?)?.toDouble() ?? 0.0;
        _quotaLimits['Earned Leave'] = (b['earnedLeaveQuota'] as num?)?.toDouble() ?? 0.0;
        _quotaLimits['Work From Home'] = (b['workFromHomeQuota'] as num?)?.toDouble() ?? 0.0;
      } else {
        _hasError = true;
        _errorMessage = 'Failed to fetch leave balances from server (Status: ${balanceRes.statusCode}).';
      }

      // 2. Fetch employee leave history from DB
      final myLeavesRes = await _http.get(Uri.parse('$_baseUrl/employee/$empId'), headers: headers);
      if (myLeavesRes.statusCode == 200) {
        final List<dynamic> decoded = json.decode(myLeavesRes.body);
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
      } else if (!_hasError) {
        _hasError = true;
        _errorMessage = 'Failed to fetch leave requests from server (Status: ${myLeavesRes.statusCode}).';
      }

      // 3. Fetch pending approval requests for Manager / HR / Global Approver
      if (AuthStorage.isManager || AuthStorage.isHr || AuthStorage.canApproveAllLeaves) {
        final endpoint = (AuthStorage.isHr || AuthStorage.canApproveAllLeaves)
            ? '$_baseUrl/pending/all'
            : '$_baseUrl/pending/manager/$empId';
        try {
          final pendingRes = await _http.get(Uri.parse(endpoint), headers: headers);
          if (pendingRes.statusCode == 200) {
            final List<dynamic> pendingList = json.decode(pendingRes.body);
            _pendingApprovals = pendingList;
          }
        } catch (_) {
          // Non-fatal for personal leave dashboard
        }
      } else {
        _pendingApprovals = [];
      }
    } catch (e) {
      debugPrint('[LEAVE FETCH ERROR] Failed to load leave data: $e');
      _hasError = true;
      _errorMessage = 'Unable to connect to server. Please check your connection and backend API.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyForLeaveFromMap(Map<String, dynamic> data) async {
    final type = data['leaveType']?.toString() ?? 'CASUAL';
    final fromDateStr = data['fromDate']?.toString() ?? DateTime.now().toIso8601String().split('T')[0];
    final toDateStr = data['toDate']?.toString() ?? fromDateStr;
    final fromSession = data['fromSession']?.toString() ?? 'Session 1';
    final toSession = data['toSession']?.toString() ?? 'Session 2';

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

      final res = await _http.post(
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
        final errorMsg = _formatErrorMessage(res);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('Apply leave backend call exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error applying leave: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _formatErrorMessage(http.Response res) {
    if (res.statusCode == 403) {
      return 'Access Denied: You do not have permission to perform this action.';
    }
    if (res.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    if (res.statusCode == 404) {
      return 'The requested leave record was not found.';
    }
    String msg = res.body;
    try {
      final decoded = json.decode(res.body);
      if (decoded is Map) {
        if (decoded.containsKey('message') && decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
          msg = decoded['message'].toString();
        } else if (decoded.containsKey('error') && decoded['error'] != null) {
          msg = decoded['error'].toString();
        }
      }
    } catch (_) {}
    msg = msg.replaceAll(RegExp(r'^[a-zA-Z0-9_.]+(Exception|Error):\s*'), '');
    msg = msg.replaceAll('AccessDenied: ', '');
    return msg;
  }

  Future<void> _withdrawLeave(dynamic leave) async {
    final leaveId = leave['id'];
    final type = leave['leaveType'] as String? ?? 'Leave';

    try {
      final res = await _http.put(
        Uri.parse('$_baseUrl/$leaveId/withdraw'),
        headers: AuthStorage.authHeaders,
        body: json.encode({'actorId': (AuthStorage.employeeId ?? 1).toString()}),
      );
      if (res.statusCode == 200) {
        // Refetch FRESH balance and leave history from backend — never trust local state
        await _fetchLeaveData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type request withdrawn successfully.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        if (!mounted) return;
        final errorMsg = _formatErrorMessage(res);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('[WITHDRAW ERROR] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _updateLeaveStatus(int leaveId, String status, {String? rejectionReason}) async {
    final approverId = AuthStorage.employeeId ?? 1;
    final body = json.encode({
      'status': status,
      'rejectionReason': rejectionReason ?? '',
      'approverId': approverId.toString(),
    });

    try {
      final res = await _http.put(
        Uri.parse('$_baseUrl/$leaveId/status'),
        headers: AuthStorage.authHeaders,
        body: body,
      );
      if (res.statusCode == 200) {
        await _fetchLeaveData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request $status successfully!'),
            backgroundColor: status == 'APPROVED' ? const Color(0xFF10B981) : Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        final errorMsg = _formatErrorMessage(res);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $errorMsg'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Leave Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: t.onBackgroundText)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.onBackgroundText),
            tooltip: 'Refresh Quotas',
            onPressed: _fetchLeaveData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: AuthStorage.isHr
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: t.card.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.border.withValues(alpha: 0.3)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: t.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: t.onBackgroundTextSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(icon: Icon(Icons.person_outline_rounded, size: 18), text: 'My Leaves & Quotas'),
                      Tab(icon: Icon(Icons.approval_rounded, size: 18), text: 'Team Approvals'),
                    ],
                  ),
                ),
              ),
      ),

      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = MediaQuery.of(context).size.width < 500;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [t.primary, t.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: Colors.transparent,
              onPressed: _showApplyRequestOptions,
              icon: Icon(Icons.add_rounded, color: Colors.white, size: isMobile ? 18 : 22),
              label: Text(
                AuthStorage.isHr
                    ? (isMobile ? 'Apply on Behalf' : 'Apply On Behalf of Employee')
                    : (isMobile ? 'Apply Leave' : 'Apply Request'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const LeaveManagementSkeletonLoader()
            : (_hasError
                ? _buildErrorView(t)
                : (AuthStorage.isHr
                    ? _buildPendingApprovalsView(t)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyLeavesDashboard(t),
                          _buildPendingApprovalsView(t),
                        ],
                      ))),
      ),
    );
  }

  Widget _buildErrorView(AppThemeConfig t) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Can't load page",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: t.onBackgroundText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Unable to connect to server. Please check your network connection or server status.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: t.onBackgroundTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchLeaveData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthStorage.clear();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log In Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.primary,
                    side: BorderSide(color: t.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLeavesDashboard(AppThemeConfig t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 24.0,
            vertical: isMobile ? 12.0 : 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dashboard Welcome Hero Banner
              _buildHeroBanner(t),
              SizedBox(height: isMobile ? 16 : 28),

              // 2. Leave Quotas Grid (Desktop 4-col / Mobile 2-col)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Leave Quota Balances',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.w800,
                        color: t.onBackgroundText,
                      ),
                    ),
                  ),
                  Text(
                    'Allocated by HR Admin',
                    style: TextStyle(fontSize: isMobile ? 10.5 : 12, color: t.onBackgroundTextSecondary),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 14),
              if (_currentEmployee != null && (_currentEmployee!.isProbation || _currentEmployee!.status == 'PROBATION'))
                _buildProbationWarningBanner(t),
              if (_currentEmployee != null && (_currentEmployee!.isNoticePeriod || _currentEmployee!.status == 'NOTICE_PERIOD' || _currentEmployee!.status == 'NOTICE'))
                _buildNoticeWarningBanner(t),
              _buildQuotaGrid(t),
              SizedBox(height: isMobile ? 20 : 32),

              // 3. Responsive Main Grid
              LayoutBuilder(
                builder: (context, gridConstraints) {
                  final isDesktop = gridConstraints.maxWidth > 850;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildHistorySection(t),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _buildSidebarSection(t),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildHistorySection(t),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildSidebarSection(t),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Gradient Welcome Hero Banner matching Dashboard
  Widget _buildHeroBanner(AppThemeConfig t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.beach_access_rounded, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE LEAVE PORTAL',
                    style: TextStyle(color: t.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Account for your absence by managing leaves 👋',
              style: TextStyle(
                fontSize: isMobile ? 17 : 22,
                fontWeight: FontWeight.w800,
                color: t.text,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Apply for time off, monitor remaining quotas, and track request approvals in real-time.',
              style: TextStyle(
                fontSize: isMobile ? 11.5 : 13,
                color: t.textSecondary,
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [t.primary, t.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
                boxShadow: [
                  BoxShadow(
                    color: t.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showApplyRequestOptions,
                icon: Icon(Icons.add_rounded, size: isMobile ? 16 : 18, color: Colors.white),
                label: Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12.5 : 14, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 10 : 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 14 : 20)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/holidays'),
              icon: Icon(Icons.event_available_rounded, size: isMobile ? 15 : 16, color: t.primary),
              label: Text('Holidays & RH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11.5 : 12, color: t.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.primary.withValues(alpha: 0.4)),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 9 : 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 14 : 16)),
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(isMobile ? 18.0 : 24.0),
            border: Border.all(color: t.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: t.glow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textBlock,
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: textBlock),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [actionButtons],
                    ),
                  ],
                ),
        );
      },
    );
  }

  // Quota Grid Cards
  Widget _buildQuotaGrid(AppThemeConfig t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 3 : 2);
        final childAspect = constraints.maxWidth < 400 ? 1.35 : 1.45;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspect,
            crossAxisSpacing: constraints.maxWidth < 400 ? 10 : 14,
            mainAxisSpacing: constraints.maxWidth < 400 ? 10 : 14,
          ),
          itemCount: _quotaGridItems.length,
          itemBuilder: (context, index) {
            final item = _quotaGridItems[index];
            final rem = _balances[item.key] ?? 0.0;
            final limit = _quotaLimits[item.key] ?? 12.0;

            return _QuotaCardTile(
              item: item,
              remaining: rem,
              limit: limit,
              t: t,
            );
          },
        );
      },
    );
  }

  // Filterable Request History Section
  Widget _buildHistorySection(AppThemeConfig t) {
    final filtered = _myLeaves.where((leave) {
      if (_selectedStatusFilter == 'All') return true;
      return (leave['status']?.toString() ?? '').toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: t.glow, blurRadius: 14, offset: const Offset(0, 6)),
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
                  color: t.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length} Requests',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.primary),
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
                    selectedColor: t.primary,
                    backgroundColor: t.cardSoft,
                    side: BorderSide(color: isSelected ? t.primary : t.border),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : t.textSecondary,
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
            ...filtered.map((leave) => RepaintBoundary(child: _buildInspirationLeaveCard(leave, t))),
        ],
      ),
    );
  }

  // Individual Request Card
  Widget _buildInspirationLeaveCard(dynamic leave, AppThemeConfig t) {
    final leaveType = leave['leaveType'] ?? 'Leave';
    final totalDays = leave['totalDays'] ?? 1.0;
    final category = leave['category'] ?? 'Leave';
    final appliedOn = leave['appliedOn'] ?? '19 Mar 2026';
    final startDate = leave['startDate'] ?? '19 Mar 2026';
    final startSession = leave['startSession'] ?? 'Session 1';
    final endDate = leave['endDate'] ?? '19 Mar 2026';
    final endSession = leave['endSession'] ?? 'Session 2';
    final status = (leave['status'] ?? 'PENDING').toString().toUpperCase();

    final canWithdraw = status == 'PENDING' || status == 'IN_REVIEW';

    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    if (status == 'APPROVED') {
      statusBgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
      statusTextColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'REJECTED') {
      statusBgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
      statusTextColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    } else if (status == 'WITHDRAWN' || status == 'CANCELLED') {
      statusBgColor = const Color(0xFF64748B).withValues(alpha: 0.15);
      statusTextColor = const Color(0xFF94A3B8);
      statusIcon = Icons.undo_rounded;
    } else {
      // PENDING or IN_REVIEW
      statusBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      statusTextColor = const Color(0xFFD97706);
      statusIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(color: t.glow.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Chip Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: t.border.withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$leaveType - $totalDays day(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: t.text),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.north_east_rounded, size: 15, color: t.primary),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 15, color: t.textSecondary),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category', style: TextStyle(fontSize: 9.5, color: t.textSecondary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 1),
                            Text(category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_box_outlined, size: 15, color: t.textSecondary),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Applied on', style: TextStyle(fontSize: 9.5, color: t.textSecondary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 1),
                            Text(appliedOn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 15, color: t.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From', style: TextStyle(fontSize: 9.5, color: t.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 1),
                              Text(startDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.text)),
                              Text(startSession, style: TextStyle(fontSize: 9.5, color: t.textSecondary)),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text('—', style: TextStyle(color: t.textSecondary, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To', style: TextStyle(fontSize: 9.5, color: t.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 1),
                              Text(endDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.text)),
                              Text(endSession, style: TextStyle(fontSize: 9.5, color: t.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (canWithdraw) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _withdrawLeave(leave),
                      icon: const Icon(Icons.undo_rounded, size: 14),
                      label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
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
  Widget _buildSidebarSection(AppThemeConfig t) {
    return Column(
      children: [
        // Upcoming Holidays Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.border, width: 1.2),
            boxShadow: [
              BoxShadow(color: t.glow, blurRadius: 14, offset: const Offset(0, 6)),
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
                      color: t.text,
                    ),
                  ),
                  Icon(Icons.event_available_rounded, size: 20, color: t.primary),
                ],
              ),
              const SizedBox(height: 16),
              _buildHolidayItem('Diwali Festival', 'Oct 31, 2026', 'Mandatory', t),
              const SizedBox(height: 10),
              _buildHolidayItem('Christmas Day', 'Dec 25, 2026', 'Mandatory', t),
              const SizedBox(height: 10),
              _buildHolidayItem("New Year's Eve", 'Dec 31, 2026', 'Restricted', t),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Policy Guidelines Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.border, width: 1.2),
            boxShadow: [
              BoxShadow(color: t.glow, blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: t.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Leave Policy Highlights',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: t.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Leave requests exceeding 3 consecutive days require manager approval at least 48 hours prior.\n'
                '• Unused Sick Leave and Casual Leave auto-reset at fiscal year-end.\n'
                '• Session 1 represents morning hours (09:00 AM - 01:30 PM), Session 2 represents afternoon hours (01:30 PM - 06:00 PM).',
                style: TextStyle(fontSize: 12, color: t.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHolidayItem(String name, String date, String tag, AppThemeConfig t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text)),
              const SizedBox(height: 2),
              Text(date, style: TextStyle(fontSize: 11, color: t.textSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildPendingApprovalsView(AppThemeConfig t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 24.0,
            vertical: isMobile ? 10.0 : 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Pending Team Requests',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: t.onBackgroundText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pendingApprovals.length} Pending',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 14),
              Expanded(
                child: _pendingApprovals.isEmpty
                    ? _buildEmptyState('No pending approval requests.')
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88.0),
                        itemCount: _pendingApprovals.length,
                        itemBuilder: (context, index) {
                          final leave = _pendingApprovals[index];
                          return RepaintBoundary(
                            child: _buildApprovalCard(leave, t, isMobile: isMobile),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovalCard(dynamic leave, AppThemeConfig t, {bool isMobile = false}) {
    final empId = leave['employeeId'];
    final empName = leave['employeeName'] ?? leave['employee']?['name'] ?? 'Employee #$empId';
    final empEmail = leave['employeeEmail'] ?? leave['employee']?['email'] ?? '';
    final dept = leave['employeeDepartment'] ?? 'General';
    final leaveType = (leave['leaveType'] ?? leave['type'] ?? 'Casual Leave').toString().replaceAll('_', ' ');
    final totalDays = leave['totalDays'] ?? leave['days'] ?? 1.0;
    final startDate = leave['startDate'] ?? 'Today';
    final endDate = leave['endDate'] ?? 'Today';
    final reason = leave['reason'] ?? 'None provided';

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(color: t.glow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isMobile ? 17 : 20,
                  backgroundColor: t.primary.withValues(alpha: 0.15),
                  child: Text(
                    empName.isNotEmpty ? empName[0] : 'E',
                    style: TextStyle(color: t.primary, fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: TextStyle(
                          fontSize: isMobile ? 14.5 : 16,
                          fontWeight: FontWeight.w800,
                          color: t.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        empEmail.isNotEmpty ? '$empEmail • $dept' : dept,
                        style: TextStyle(fontSize: isMobile ? 11 : 12, color: t.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 3 : 4),
                        decoration: BoxDecoration(
                          color: t.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$leaveType ($totalDays Days)',
                          style: TextStyle(
                            color: t.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 16),
            Divider(height: 1, color: t.border),
            SizedBox(height: isMobile ? 10 : 14),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: isMobile ? 14 : 16, color: t.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Dates: $startDate ➔ $endDate', style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600, color: t.text), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, size: isMobile ? 14 : 16, color: t.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reason: $reason', style: TextStyle(fontSize: isMobile ? 12 : 13, color: t.textSecondary)),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 18),
            if (empId != null && AuthStorage.employeeId != null && empId.toString() == AuthStorage.employeeId.toString())
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: t.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Self Request (Self-Approval Prohibited)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateLeaveStatus(leave['id'], 'REJECTED', rejectionReason: 'Manager Rejected'),
                    icon: Icon(Icons.close_rounded, size: isMobile ? 14 : 16),
                    label: Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 8 : 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateLeaveStatus(leave['id'], 'APPROVED'),
                    icon: Icon(Icons.check_rounded, size: isMobile ? 14 : 16),
                    label: Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 8 : 10),
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
    final t = context.appTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.85;
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuthStorage.isHr ? 'Apply Request on Behalf of Employee' : 'Apply Request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text),
                  ),
                  const SizedBox(height: 16),
                  _buildApplyOptionTile(
                    t: t,
                    icon: Icons.luggage_outlined,
                    color: const Color(0xFF0284C7),
                    title: 'Apply Leave',
                    subtitle: AuthStorage.isHr ? 'Full/half-day leave on behalf of employee' : 'Full day or half day leave',
                    onTap: () {
                      Navigator.pop(context);
                      _openApplyDialog('Leave');
                    },
                  ),
                  if (!AuthStorage.isHr) ...[
                    const SizedBox(height: 12),
                    _buildApplyOptionTile(
                      t: t,
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
                      t: t,
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
                      t: t,
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
          ),
        );
      },
    );
  }

  Widget _buildApplyOptionTile({required AppThemeConfig t, required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
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
                  Text(subtitle, style: TextStyle(fontSize: 12, color: t.textSecondary)),
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
        targetEmployee: null,
        onSubmit: (data) => _applyForLeaveFromMap(data),
      ),
    );
  }

  Widget _buildProbationWarningBanner(AppThemeConfig t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Probation Active: Earned Leave Accrual = 0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))),
                Text('Earned Leaves do not accrue during probation. Prorated balance will be evaluated according to the 15th-day rule upon completion.', style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeWarningBanner(AppThemeConfig t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.exit_to_app_rounded, color: Color(0xFF7C3AED), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notice Period Active: Normal Leave Requests Locked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED))),
                Text('Per company policy, Casual, Sick, and Earned leaves cannot be applied during notice period. Loss of Pay (LOP) remains permitted. Balances are preserved.', style: TextStyle(fontSize: 11.5, color: Color(0xFF6D28D9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _QuotaCardTile extends StatefulWidget {
  final QuotaGridCardItem item;
  final double remaining;
  final double limit;
  final AppThemeConfig t;

  const _QuotaCardTile({
    required this.item,
    required this.remaining,
    required this.limit,
    required this.t,
  });

  @override
  State<_QuotaCardTile> createState() => _QuotaCardTileState();
}

class _QuotaCardTileState extends State<_QuotaCardTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final item = widget.item;
    final rem = widget.remaining;
    final limit = widget.limit;
    final color = item.color;
    final isDesktop = kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 185;
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0.0, _isHovered && isDesktop ? -3.0 : 0.0, 0.0),
            padding: EdgeInsets.all(isCompact ? 11.0 : 18.0),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
              border: Border.all(
                color: _isHovered ? color : color.withValues(alpha: 0.3),
                width: _isHovered ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered ? color.withValues(alpha: 0.2) : t.glow,
                  blurRadius: _isHovered ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
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
                        style: TextStyle(fontSize: isCompact ? 11.5 : 13, fontWeight: FontWeight.bold, color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.all(isCompact ? 5 : 7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                      ),
                      child: Icon(item.icon, color: color, size: isCompact ? 15 : 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${rem % 1 == 0 ? rem.toInt() : rem}',
                        style: TextStyle(
                          fontSize: isCompact ? 20 : 24,
                          fontWeight: FontWeight.w800,
                          color: t.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.key == 'Work From Home' ? 'Remote Days' : 'Out of ${limit.toInt()} Allocated',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isCompact ? 9.5 : 11, color: t.textSecondary),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item.key == 'Work From Home' ? 1.0 : (limit > 0 ? (rem / limit).clamp(0.0, 1.0) : 0),
                    backgroundColor: t.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: isCompact ? 4 : 5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
