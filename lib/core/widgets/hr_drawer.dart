import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class HrDrawer extends StatelessWidget {
  const HrDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final t = context.appTheme;
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

        return Drawer(
          backgroundColor: t.sidebar,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            t.primaryDark,
                            t.primary,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.badge_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TeamJoy HR',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Enterprise Portal',
                                style: TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (AuthStorage.isHr) ...[
                      _item(context, t, Icons.dashboard_rounded, 'Dashboard', '/', currentRoute),
                      _item(context, t, Icons.people_alt_rounded, 'Employees', '/employees', currentRoute),
                      _item(context, t, Icons.group_outlined, 'People Directory', '/people', currentRoute),
                      _item(context, t, Icons.calendar_month_rounded, 'Attendance', '/attendance', currentRoute),
                      _item(context, t, Icons.beach_access_rounded, 'Leaves', '/leaves', currentRoute),
                      _item(context, t, Icons.admin_panel_settings_rounded, 'Leave Policy & Quotas', '/hr_leave_settings', currentRoute),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 28, thickness: 1, color: t.border),
                      ),
                      _item(context, t, Icons.settings_rounded, 'Settings', '/settings', currentRoute),
                    ] else ...[
                      _item(context, t, Icons.home_rounded, 'Home', '/', currentRoute),
                      _item(context, t, Icons.group_outlined, 'People', '/people', currentRoute),
                      _item(context, t, Icons.calendar_month_rounded, 'My Attendance', '/attendance', currentRoute),
                      _item(context, t, Icons.beach_access_rounded, 'My Leaves', '/leaves', currentRoute),
                      _item(context, t, Icons.receipt_long_rounded, 'My Payslips', '/payslip', currentRoute),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 28, thickness: 1, color: t.border),
                      ),
                      _item(context, t, Icons.settings_rounded, 'Settings', '/settings', currentRoute),
                      _item(context, t, Icons.person_rounded, 'My Profile', '/employee_profile', currentRoute),
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
                        onTap: AuthStorage.isHr
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Admin accounts do not have a personal employee profile.')),
                                );
                              }
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/employee_profile',
                                  arguments: AuthStorage.employeeId?.toString(),
                                );
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
                                  AuthStorage.isHr
                                      ? 'HR'
                                      : (AuthStorage.userEmail != null && AuthStorage.userEmail!.length >= 2
                                          ? AuthStorage.userEmail!.substring(0, 2).toUpperCase()
                                          : 'EM'),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AuthStorage.userEmail ?? 'User',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: t.text,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AuthStorage.isHr
                                            ? t.secondary
                                            : AuthStorage.isManager
                                                ? t.primary
                                                : t.textSecondary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (AuthStorage.userRole ?? 'EMPLOYEE').replaceAll('ROLE_', ''),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
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
                      icon: Icon(Icons.logout_rounded, size: 20, color: t.danger),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: t.card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('Confirm Logout', style: TextStyle(color: t.text)),
                            content: Text('Are you sure you want to log out of the HR portal?', style: TextStyle(color: t.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel', style: TextStyle(color: t.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: t.danger, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await AuthStorage.clear();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(BuildContext context, AppThemeConfig t, IconData icon, String title, String route, String currentRoute) {
    final isActive = currentRoute == route || (route == '/employees' && currentRoute == '/employee_profile');
    final color = isActive ? t.primary : t.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: ListTile(
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: color),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isActive,
        selectedTileColor: t.primary.withValues(alpha: 0.12),
        hoverColor: t.primary.withValues(alpha: 0.06),
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}