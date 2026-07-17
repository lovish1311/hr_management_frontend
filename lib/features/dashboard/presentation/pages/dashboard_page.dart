import 'package:flutter/material.dart';
import 'package:hr_management/core/constants/colors.dart';
import 'package:hr_management/core/widgets/kpi_card.dart';
import 'package:hr_management/core/widgets/leave_request_tile.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:hr_management/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:hr_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hr_management/core/widgets/upcoming_events_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardRepository _repository = DashboardRepositoryImpl();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  DashboardStats? _stats;
  List<LeaveRequest> _pendingLeaves = [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _repository.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _pendingLeaves = List.from(stats.pendingLeaves);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(LeaveRequest request, String status) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      // 1. Send status update to backend API
      await _repository.updateLeaveStatus(request.id, status);

      // 2. Animate item slide-out to the left and fade-out smoothly
      final index = _pendingLeaves.indexWhere((element) => element.id == request.id);
      if (index != -1) {
        final removedItem = _pendingLeaves.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) {
            final slideLeftAnimation = Tween<Offset>(
              begin: const Offset(-1.0, 0.0), // Exit to the left
              end: const Offset(0.0, 0.0),
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));
            return SlideTransition(
              position: slideLeftAnimation,
              child: FadeTransition(
                opacity: animation,
                child: LeaveRequestTile(
                  employeeName: removedItem.employeeName,
                  dates: removedItem.dates,
                  reason: removedItem.reason,
                ),
              ),
            );
          },
          duration: const Duration(milliseconds: 350),
        );
      }

      // 3. Silently fetch background stats to refresh KPI counts
      final freshStats = await _repository.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = freshStats;
          // Keep local state in sync
          _pendingLeaves = List.from(freshStats.pendingLeaves);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update request: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final greenCardColor = isDark ? const Color(0xFF1B5E20) : AppColors.accentGreen;
    final blueCardColor = isDark ? const Color(0xFF006064) : AppColors.accentBlue;

    final attendanceColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);
    final applyLeaveColor = isDark ? Colors.blueAccent : const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchStats();
            },
          )
        ],
      ),
      drawer: const HrDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 60, color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load dashboard',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                              ),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _fetchStats();
                                },
                                child: const Text('Try Again'),
                              )
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning, HR Team!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                KpiCard(
                                  title: 'Total Employees',
                                  value: (_stats?.totalEmployees ?? 0).toString(),
                                  icon: Icons.people_outline,
                                  backgroundColor: theme.colorScheme.surface,
                                ),
                                const SizedBox(width: 16),
                                KpiCard(
                                  title: 'Present Today',
                                  value: (_stats?.presentToday ?? 0).toString(),
                                  icon: Icons.check_circle_outline,
                                  backgroundColor: greenCardColor,
                                ),
                                const SizedBox(width: 16),
                                KpiCard(
                                  title: 'On Leave',
                                  value: (_stats?.onLeaveToday ?? 0).toString(),
                                  icon: Icons.event_busy,
                                  backgroundColor: blueCardColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickAction(
                                  context,
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: 'Add Employee',
                                  color: theme.colorScheme.primary,
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  icon: Icons.rule_rounded,
                                  label: 'Attendance',
                                  color: attendanceColor,
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  icon: Icons.date_range_rounded,
                                  label: 'Apply Leave',
                                  color: applyLeaveColor,
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  icon: Icons.post_add_rounded,
                                  label: 'Create Job',
                                  color: theme.colorScheme.secondary,
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final isWideScreen = screenWidth > 800;

                                if (isWideScreen) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _buildPendingLeaveSection(theme, isDark),
                                      ),
                                      const SizedBox(width: 24),
                                      const Expanded(
                                        flex: 1,
                                        child: UpcomingEventsCard(),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildPendingLeaveSection(theme, isDark),
                                      const SizedBox(height: 24),
                                      const UpcomingEventsCard(),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
            // Centered Action Loading Spinner Overlay
            if (_isActionLoading)
              Container(
                color: Colors.black.withOpacity(0.2), // Semi-transparent overlay to prevent clicks
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingLeaveSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Leave Approvals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildPendingLeavesList(),
        ],
      ),
    );
  }

  Widget _buildPendingLeavesList() {
    if (_pendingLeaves.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Text('No pending leave requests.'),
      );
    }
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _pendingLeaves.length,
      itemBuilder: (context, index, animation) {
        if (index >= _pendingLeaves.length) return const SizedBox();
        final leave = _pendingLeaves[index];
        final slideInAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Enter from the right
          end: const Offset(0.0, 0.0),
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        return SlideTransition(
          position: slideInAnimation,
          child: FadeTransition(
            opacity: animation,
            child: LeaveRequestTile(
              employeeName: leave.employeeName,
              dates: leave.dates,
              reason: leave.reason,
              onApprove: () => _handleAction(leave, 'APPROVED'),
              onDecline: () => _handleAction(leave, 'REJECTED'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48 - 24) / 4,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
