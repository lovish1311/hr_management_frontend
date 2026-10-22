import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/kpi_card.dart';
import 'package:hr_management/core/widgets/leave_request_tile.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/upcoming_events_card.dart';
import 'package:hr_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:hr_management/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:hr_management/core/widgets/app_toast.dart';
import 'package:hr_management/core/utils/text_formatters.dart';
import 'package:hr_management/core/config/environment.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();



  String _getDisplayName() {
    final user = AuthStorage.userName;
    if (user != null && user.trim().isNotEmpty) return user.trim();
    final email = AuthStorage.userEmail;
    if (email != null && email.contains('@')) {
      final name = email.split('@').first;
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return 'HR Team';
  }

  Widget _buildSlideOutTile(LeaveRequest item, Animation<double> animation) {
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
          employeeName: item.employeeName,
          dates: item.dates,
          reason: item.reason,
        ),
      ),
    );
  }

  Future<void> _handleAction(LeaveRequest request, String status) async {
    final index = ref.read(dashboardProvider).pendingLeaves.indexWhere((element) => element.id == request.id);

    final success = await ref.read(dashboardProvider.notifier).updateLeaveStatus(
      leaveId: request.id,
      status: status,
      onBeforeRemove: () {
        if (index != -1) {
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildSlideOutTile(request, animation),
            duration: const Duration(milliseconds: 350),
          );
        }
      },
    );

    if (!success && mounted) {
      final error = ref.read(dashboardProvider).actionErrorMessage;
      AppToast.error(context, error ?? 'Could not update request. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = ref.watch(dashboardProvider);

    return ResponsiveScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: t.cardSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: t.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    TextFormatter.formatDate(DateTime.now()),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: t.onBackgroundText),
                if ((state.stats?.pendingLeaves.length ?? 0) > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: t.danger, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        '${state.stats!.pendingLeaves.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/leaves');
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.onBackgroundText),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              ref.read(dashboardProvider.notifier).loadDashboard();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            state.isLoading
                ? const DashboardSkeleton()
                : state.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 60, color: t.danger),
                              const SizedBox(height: 16),
                              Text('Failed to load dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.danger)),
                              const SizedBox(height: 8),
                              Text(state.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary)),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.white),
                                onPressed: () {
                                  ref.read(dashboardProvider.notifier).loadDashboard();
                                },
                                child: const Text('Try Again'),
                              )
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, rootConstraints) {
                          final isMobile = rootConstraints.maxWidth < 600;
                          final pagePadding = isMobile
                              ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)
                              : const EdgeInsets.all(24.0);
                          final bannerPadding = isMobile ? const EdgeInsets.all(14.0) : const EdgeInsets.all(24.0);
                          final bannerTitleSize = isMobile ? 18.0 : 24.0;
                          final bannerSubtitleSize = isMobile ? 12.0 : 14.0;

                          return SingleChildScrollView(
                            padding: pagePadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Hero Banner
                                Container(
                                  width: double.infinity,
                                  padding: bannerPadding,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [t.primaryDark, t.primary, t.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isMobile ? 18.0 : 24.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: t.glow,
                                        blurRadius: isMobile ? 12 : 20,
                                        offset: Offset(0, isMobile ? 5 : 8),
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
                                                color: Colors.white.withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      TextFormatter.formatDate(DateTime.now()),
                                                      style: const TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: isMobile ? 8 : 12),
                                            Text(
                                              TextFormatter.formatGreeting(_getDisplayName()),
                                              style: TextStyle(
                                                fontSize: bannerTitleSize,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            SizedBox(height: isMobile ? 4 : 6),
                                            Text(
                                              'Here is what is happening across ${Environment.companyName} today.',
                                              style: TextStyle(fontSize: bannerSubtitleSize, color: Colors.white.withValues(alpha: 0.85)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isMobile ? 14 : 24),

                                // KPI Stat Cards (semantic colors from theme)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 650;
                                    if (isNarrow) {
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              KpiCard(
                                                title: 'Total Employees',
                                                value: (state.stats?.totalEmployees ?? 0).toString(),
                                                icon: Icons.people_alt_rounded,
                                                cardType: KpiCardType.primary,
                                                trendText: '+12.4%',
                                                isTrendPositive: true,
                                              ),
                                              const SizedBox(width: 10),
                                              KpiCard(
                                                title: 'Present Today',
                                                value: (state.stats?.presentToday ?? 0).toString(),
                                                icon: Icons.verified_user_rounded,
                                                cardType: KpiCardType.success,
                                                trendText: '96.2%',
                                                isTrendPositive: true,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              KpiCard(
                                                title: 'On Leave Today',
                                                value: (state.stats?.onLeaveToday ?? 0).toString(),
                                                icon: Icons.event_busy_rounded,
                                                cardType: KpiCardType.warning,
                                                trendText: '${state.pendingLeaves.length} pending',
                                                isTrendPositive: false,
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        KpiCard(
                                          title: 'Total Employees',
                                          value: (state.stats?.totalEmployees ?? 0).toString(),
                                          icon: Icons.people_alt_rounded,
                                          cardType: KpiCardType.primary,
                                          trendText: '+12.4%',
                                          isTrendPositive: true,
                                        ),
                                        const SizedBox(width: 16),
                                        KpiCard(
                                          title: 'Present Today',
                                          value: (state.stats?.presentToday ?? 0).toString(),
                                          icon: Icons.verified_user_rounded,
                                          cardType: KpiCardType.success,
                                          trendText: '96.2%',
                                          isTrendPositive: true,
                                        ),
                                        const SizedBox(width: 16),
                                        KpiCard(
                                          title: 'On Leave Today',
                                          value: (state.stats?.onLeaveToday ?? 0).toString(),
                                          icon: Icons.event_busy_rounded,
                                          cardType: KpiCardType.warning,
                                          trendText: '${state.pendingLeaves.length} pending',
                                          isTrendPositive: false,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: isMobile ? 18 : 32),

                                // Quick Actions
                                Text(
                                  'Quick Actions',
                                  style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w800, color: t.onBackgroundText),
                                ),

                                SizedBox(height: isMobile ? 10 : 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmall = constraints.maxWidth < 500;
                                    final crossAxisCount = isSmall ? 1 : 3;
                                    final spacing = isSmall ? 8.0 : 12.0;
                                    final cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: [
                                        SizedBox(width: cardWidth, child: _buildQuickActionCard(context, icon: Icons.person_add_alt_1_rounded, title: 'Add Employee', subtitle: 'Onboard new hire', isCompact: isSmall, onTap: () => Navigator.pushNamed(context, '/employee_create'))),
                                        SizedBox(width: cardWidth, child: _buildQuickActionCard(context, icon: Icons.rule_rounded, title: 'Attendance', subtitle: 'Mark log today', isCompact: isSmall, onTap: () => Navigator.pushNamed(context, '/attendance'))),
                                        SizedBox(width: cardWidth, child: _buildQuickActionCard(context, icon: Icons.beach_access_rounded, title: 'Apply Leave', subtitle: 'Time off request', isCompact: isSmall, onTap: () => Navigator.pushNamed(context, '/leaves'))),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: isMobile ? 18 : 32),

                                // Responsive Main Grid (Pending Leaves + Culture Events)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth = MediaQuery.of(context).size.width;
                                    final isWideScreen = screenWidth > 850;

                                    if (isWideScreen) {
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 5, child: _buildPendingLeaveSection(context, state)),
                                          const SizedBox(width: 24),
                                          const Expanded(flex: 3, child: UpcomingEventsCard()),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildPendingLeaveSection(context, state),
                                          const SizedBox(height: 24),
                                          const UpcomingEventsCard(),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            // Centered Action Loading Spinner Overlay
            if (state.isActionLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: CircularProgressIndicator(color: context.appTheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingLeaveSection(BuildContext context, DashboardState state) {
    final t = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: t.glow, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: headerConstraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Pending Leave Approvals',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text),
                          ),
                        ),
                        if (state.pendingLeaves.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.pendingLeaves.length}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/leaves'),
                    child: Text('View All', style: TextStyle(color: t.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _buildPendingLeavesList(state),
        ],
      ),
    );
  }

  Widget _buildPendingLeavesList(DashboardState state) {
    if (state.pendingLeaves.isEmpty) {
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
      initialItemCount: state.pendingLeaves.length,
      itemBuilder: (context, index, animation) {
        if (index >= state.pendingLeaves.length) return const SizedBox();
        final leave = state.pendingLeaves[index];
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
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    final t = context.appTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12.0 : 16.0,
          vertical: isCompact ? 10.0 : 16.0,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          border: Border.all(color: t.border, width: 1.2),
          boxShadow: [
            BoxShadow(color: t.glow, blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: isCompact
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.primary, t.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: t.glow, blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: t.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: t.textSecondary),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.primary, t.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: t.glow, blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: t.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: t.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }
}
