import 'package:flutter/material.dart';

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
                _buildDrawerItem(
                  context: context,
                  icon: Icons.trending_up_rounded,
                  title: 'Performance',
                  route: '/performance',
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
                        'Admin User',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'admin@company.com',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
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