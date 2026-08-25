import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';

class HrDrawer extends StatelessWidget {
  const HrDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF0D9488),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: '/',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people_alt_rounded,
                  title: 'Employees',
                  route: '/employees',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Attendance',
                  route: '/attendance',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.beach_access_rounded,
                  title: 'Leaves',
                  route: '/leaves',
                  currentRoute: currentRoute,
                ),
                if (AuthStorage.isHr)
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Leave Policy & Quotas',
                    route: '/hr_leave_settings',
                    currentRoute: currentRoute,
                  ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.payments_rounded,
                  title: 'Payroll',
                  route: '/payroll',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Recruitment',
                  route: '/recruitment',
                  currentRoute: currentRoute,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(height: 28, thickness: 1),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  route: '/settings',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
          // User profile card footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/employee_profile',
                        arguments: AuthStorage.employeeId?.toString(),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF0D9488),
                            child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AuthStorage.isSuperAdmin
                                        ? const Color(0xFF8B5CF6)
                                        : AuthStorage.isHr
                                            ? const Color(0xFF0D9488)
                                            : AuthStorage.isManager
                                                ? const Color(0xFF3B82F6)
                                                : const Color(0xFF64748B),
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
                  icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to log out of the HR portal?'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
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
  }


  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required String currentRoute,
  }) {
    final theme = Theme.of(context);
    final isActive = currentRoute == route || (route == '/employees' && currentRoute == '/employee_profile');
    final color = isActive ? const Color(0xFF0D9488) : theme.textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 3.0),
      child: ListTile(
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        selected: isActive,
        selectedTileColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
        hoverColor: const Color(0xFF0D9488).withValues(alpha: 0.06),
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