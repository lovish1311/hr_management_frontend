import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class HrDrawer extends StatelessWidget {
  final VoidCallback? onCollapse;
  const HrDrawer({super.key, this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final t = context.appTheme;
        final activeRoute = ModalRoute.of(context)?.settings.name ?? '/';

        return Drawer(
          backgroundColor: t.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                children: [
                  // ── Header / Logo ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: t.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: t.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TeamJoy HR',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: t.isDarkTheme ? Colors.white : t.text,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Enterprise Portal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: t.isDarkTheme ? Colors.white70 : t.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onCollapse != null)
                          Tooltip(
                            message: 'Collapse Sidebar',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: onCollapse,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: (t.isDarkTheme ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: (t.isDarkTheme ? Colors.white : Colors.black).withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 17,
                                    color: t.isDarkTheme ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (AuthStorage.isSuperAdmin) ...[
                    // ── Super Admin Exclusive Navigation ───────────────────
                    _item(context, t, Icons.dashboard_rounded, 'Dashboard', '/', activeRoute),
                    _item(context, t, Icons.sports_esports_rounded, 'Game Zone', '/games', activeRoute),
                    _item(context, t, Icons.people_alt_rounded, 'Employees', '/employees', activeRoute),
                    _item(context, t, Icons.group_outlined, 'People Directory', '/people', activeRoute),
                    _item(context, t, Icons.calendar_month_rounded, 'Attendance', '/attendance', activeRoute),
                    _item(context, t, Icons.beach_access_rounded, 'Leaves', '/leaves', activeRoute),
                    _item(context, t, Icons.event_available_rounded, 'Holiday Calendar', '/holidays', activeRoute),
                    _item(context, t, Icons.calendar_today_rounded, 'Holiday Management', '/holiday_management', activeRoute),
                    _item(context, t, Icons.admin_panel_settings_rounded, 'Leave Policy & Quotas', '/hr_leave_settings', activeRoute),
                    _item(context, t, Icons.payments_rounded, 'Run Payroll', '/payroll_process', activeRoute),
                    _item(context, t, Icons.edit_calendar_rounded, 'Payroll Inputs & LOP', '/payroll_inputs', activeRoute),
                    _item(context, t, Icons.account_balance_wallet_rounded, 'Salary Structures', '/salary_structure', activeRoute),
                    _item(context, t, Icons.receipt_long_rounded, 'All Payslips', '/payslip', activeRoute),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 28, thickness: 1, color: t.border),
                    ),
                    _item(context, t, Icons.settings_rounded, 'Settings', '/settings', activeRoute),
                  ] else ...[
                    // ── HR, Managers, and Employees Navigation ──────────────
                    _item(context, t, Icons.home_rounded, 'Home', '/', activeRoute),
                    _item(context, t, Icons.sports_esports_rounded, 'Game Zone', '/games', activeRoute),
                    _item(context, t, Icons.group_outlined, 'People', '/people', activeRoute),
                    _item(context, t, Icons.calendar_month_rounded, 'My Attendance', '/attendance', activeRoute),
                    _item(context, t, Icons.beach_access_rounded, 'My Leaves', '/leaves', activeRoute),
                    _item(context, t, Icons.event_available_rounded, 'Holiday Calendar', '/holidays', activeRoute),
                    if (AuthStorage.isHr) ...[
                      _item(context, t, Icons.calendar_today_rounded, 'Holiday Management', '/holiday_management', activeRoute),
                      _item(context, t, Icons.payments_rounded, 'Run Payroll', '/payroll_process', activeRoute),
                      _item(context, t, Icons.edit_calendar_rounded, 'Payroll Inputs & LOP', '/payroll_inputs', activeRoute),
                      _item(context, t, Icons.account_balance_wallet_rounded, 'Salary Structures', '/salary_structure', activeRoute),
                    ],
                    _item(context, t, Icons.menu_book_rounded, 'Leave Policy', '/leave_policy', activeRoute),
                    _item(context, t, Icons.receipt_long_rounded, 'My Payslips', '/payslip', activeRoute),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 28, thickness: 1, color: t.border),
                    ),
                    _item(context, t, Icons.settings_rounded, 'Settings', '/settings', activeRoute),
                    _item(context, t, Icons.person_rounded, 'My Profile', '/employee_profile', activeRoute),
                  ],
                ],
              ),
            ),

            // ── Footer: User card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.cardSoft,
                border: Border(top: BorderSide(color: t.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: AuthStorage.isSuperAdmin
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Super Admin accounts do not have a personal employee profile.')),
                              );
                            }
                          : () {
                              final scaffold = Scaffold.maybeOf(context);
                              if (scaffold != null && scaffold.isDrawerOpen) {
                                Navigator.pop(context);
                              }
                              if (activeRoute != '/employee_profile') {
                                Navigator.pushNamed(
                                  context,
                                  '/employee_profile',
                                  arguments: AuthStorage.employeeId?.toString(),
                                );
                              }
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: t.primary,
                              child: Text(
                                AuthStorage.isSuperAdmin
                                    ? 'AD'
                                    : (AuthStorage.userEmail != null && AuthStorage.userEmail!.length >= 2
                                        ? AuthStorage.userEmail!.substring(0, 2).toUpperCase()
                                        : 'EM'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AuthStorage.userEmail ?? 'user@company.com',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: t.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: t.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AuthStorage.userRole ?? 'EMPLOYEE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: t.primary,
                                        letterSpacing: 0.5,
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
                  ),
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
                    tooltip: 'Sign Out',
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _item(
    BuildContext context,
    AppThemeConfig t,
    IconData icon,
    String label,
    String route,
    String activeRoute,
  ) {
    final isSelected = activeRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: isSelected ? t.primary.withValues(alpha: 0.15) : Colors.transparent,
          leading: Icon(
            icon,
            color: isSelected ? t.primary : t.text.withValues(alpha: 0.6),
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? t.primary : t.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          onTap: () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              Navigator.pop(context); // close mobile drawer overlay only if open
            }
            if (activeRoute != route) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthStorage.clear();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}
