import 'package:flutter/material.dart';
import 'package:hr_management/core/constants/colors.dart';

class HrDrawer extends StatelessWidget {
  const HrDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TeamJoy HR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin Portal',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
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
            icon: Icons.beach_access_rounded, // Fits the fun, palm tree vibe for leaves
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
          const Divider(height: 32, thickness: 1),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings_rounded,
            title: 'Settings',
            route: '/settings',
            currentRoute: currentRoute,
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
    // Treat employee_profile as part of the /employees section for highlighting
    final isActive = currentRoute == route || (route == '/employees' && currentRoute == '/employee_profile');
    final color = isActive ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        selected: isActive,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
        hoverColor: theme.colorScheme.primary.withOpacity(0.05),
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pop(context); // Close drawer if already on page
          }
        },
      ),
    );
  }
}