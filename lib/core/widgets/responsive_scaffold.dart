import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final t = context.appTheme;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: isDesktop ? null : appBar,
              drawer: isDesktop ? null : const HrDrawer(),
              floatingActionButton: floatingActionButton,
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: t.backgroundGradient,
                  ),
                ),
                child: Row(
                  children: [
                    if (isDesktop)
                      const SizedBox(
                        width: 280,
                        child: HrDrawer(),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (isDesktop && appBar != null)
                            SafeArea(
                              bottom: false,
                              child: SizedBox(
                                height: appBar!.preferredSize.height,
                                child: appBar!,
                              ),
                            ),
                          Expanded(
                            child: SafeArea(
                              bottom: false,
                              right: false,
                              top: !isDesktop && appBar == null,
                              child: body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: isDesktop ? null : _buildBottomNav(context, t),
            );
          },
        );
      },
    );
  }

  Widget? _buildBottomNav(BuildContext context, AppThemeConfig t) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    final List<_NavItem> items = AuthStorage.isHr
        ? [
            _NavItem('Dashboard', Icons.dashboard_rounded, '/'),
            _NavItem('Employees', Icons.people_alt_rounded, '/employees'),
            _NavItem('Attendance', Icons.calendar_month_rounded, '/attendance'),
            _NavItem('Leaves', Icons.beach_access_rounded, '/leaves'),
            _NavItem('More', Icons.menu_rounded, null),
          ]
        : [
            _NavItem('Home', Icons.home_rounded, '/'),
            _NavItem('People', Icons.group_outlined, '/people'),
            _NavItem('Attendance', Icons.calendar_month_rounded, '/attendance'),
            _NavItem('Leaves', Icons.beach_access_rounded, '/leaves'),
            _NavItem('More', Icons.menu_rounded, null),
          ];

    int currentIndex = items.indexWhere((item) => item.route == currentRoute);
    if (currentIndex == -1) currentIndex = 0;

    return BottomNavigationBar(
      currentIndex: currentIndex >= 0 && currentIndex < 4 ? currentIndex : 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: t.card,
      selectedItemColor: t.primary,
      unselectedItemColor: t.textSecondary,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        final item = items[index];
        if (item.route != null && item.route != currentRoute) {
          Navigator.pushReplacementNamed(context, item.route!);
        } else if (item.route == null) {
          Scaffold.of(context).openDrawer();
        }
      },
      items: items.map((item) {
        return BottomNavigationBarItem(icon: Icon(item.icon), label: item.title);
      }).toList(),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String? route;
  _NavItem(this.title, this.icon, this.route);
}
