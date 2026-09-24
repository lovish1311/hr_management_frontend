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

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t.backgroundGradient,
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                extendBodyBehindAppBar: false,
                appBar: isDesktop
                    ? null
                    : (appBar != null
                        ? PreferredSize(
                            preferredSize: appBar!.preferredSize,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                iconTheme: const IconThemeData(color: Colors.white),
                                appBarTheme: const AppBarTheme(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  iconTheme: IconThemeData(color: Colors.white),
                                  actionsIconTheme: IconThemeData(color: Colors.white),
                                ),
                              ),
                              child: appBar!,
                            ),
                          )
                        : null),
                drawer: isDesktop ? null : const HrDrawer(),
                floatingActionButton: floatingActionButton,
                body: Row(
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
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    iconTheme: const IconThemeData(color: Colors.white),
                                    appBarTheme: const AppBarTheme(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      iconTheme: IconThemeData(color: Colors.white),
                                      actionsIconTheme: IconThemeData(color: Colors.white),
                                    ),
                                  ),
                                  child: appBar!,
                                ),
                              ),
                            ),
                          Expanded(
                            child: SafeArea(
                              bottom: true,
                              right: false,
                              top: isDesktop || appBar == null,
                              child: body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isDesktop ? null : _buildBottomNav(context, t),
              ),
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

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.border.withValues(alpha: 0.5), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: BottomNavigationBar(
            currentIndex: currentIndex >= 0 && currentIndex < items.length ? currentIndex : 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: t.primary,
            unselectedItemColor: t.textSecondary.withValues(alpha: 0.8),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              final item = items[index];
              if (item.route != null && item.route != currentRoute) {
                Navigator.pushReplacementNamed(context, item.route!);
              } else if (item.route == null) {
                Scaffold.of(context).openDrawer();
              }
            },
            items: items.map((item) {
              return BottomNavigationBarItem(icon: Icon(item.icon, size: 20), label: item.title);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String? route;
  _NavItem(this.title, this.icon, this.route);
}
