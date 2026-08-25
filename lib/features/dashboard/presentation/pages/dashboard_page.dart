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
  const DashboardPage({super.key});

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Friday, Aug 21',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchStats();
            },
          ),
          const SizedBox(width: 8),
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
                              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
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
                            // Welcome Hero Banner
                            Container(
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
                                              Icon(Icons.bolt, color: Color(0xFFFACC15), size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'LIVE HR METRICS',
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Good Morning, HR Team 👋',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Here is what is happening across your organization today.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // KPI Stat Cards Section
                            Row(
                              children: [
                                KpiCard(
                                  title: 'Total Employees',
                                  value: (_stats?.totalEmployees ?? 0).toString(),
                                  icon: Icons.people_alt_rounded,
                                  gradient: AppColors.totalEmployeesGradient,
                                  trendText: '+12.4%',
                                  isTrendPositive: true,
                                ),
                                const SizedBox(width: 16),
                                KpiCard(
                                  title: 'Present Today',
                                  value: (_stats?.presentToday ?? 0).toString(),
                                  icon: Icons.verified_user_rounded,
                                  gradient: AppColors.presentTodayGradient,
                                  trendText: '96.2%',
                                  isTrendPositive: true,
                                ),
                                const SizedBox(width: 16),
                                KpiCard(
                                  title: 'On Leave Today',
                                  value: (_stats?.onLeaveToday ?? 0).toString(),
                                  icon: Icons.event_busy_rounded,
                                  gradient: AppColors.onLeaveGradient,
                                  trendText: '${_pendingLeaves.length} pending',
                                  isTrendPositive: false,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Quick Actions
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                                
                                final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
                                const spacing = 12.0;
                                final cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildQuickActionCard(
                                        context,
                                        icon: Icons.person_add_alt_1_rounded,
                                        title: 'Add Employee',
                                        subtitle: 'Onboard new hire',
                                        gradient: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                                        onTap: () => Navigator.pushNamed(context, '/employees'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildQuickActionCard(
                                        context,
                                        icon: Icons.rule_rounded,
                                        title: 'Attendance',
                                        subtitle: 'Mark log today',
                                        gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
                                        onTap: () => Navigator.pushNamed(context, '/attendance'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildQuickActionCard(
                                        context,
                                        icon: Icons.beach_access_rounded,
                                        title: 'Apply Leave',
                                        subtitle: 'Time off request',
                                        gradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                                        onTap: () => Navigator.pushNamed(context, '/leaves'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildQuickActionCard(
                                        context,
                                        icon: Icons.post_add_rounded,
                                        title: 'Create Job',
                                        subtitle: 'Post new opening',
                                        gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                                        onTap: () => Navigator.pushNamed(context, '/recruitment'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Responsive Main Grid (Pending Leaves + Culture Events)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final isWideScreen = screenWidth > 850;

                                if (isWideScreen) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _buildPendingLeaveSection(theme, isDark),
                                      ),
                                      const SizedBox(width: 24),
                                      const Expanded(
                                        flex: 3,
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
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingLeaveSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Pending Leave Approvals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pendingLeaves.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/leaves'),
                child: const Text('View All', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildPendingLeavesList(),
        ],
      ),
    );
  }

  Widget _buildPendingLeavesList() {
    if (_pendingLeaves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 44, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                'All leave requests are cleared!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
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
          begin: const Offset(1.0, 0.0),
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

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
