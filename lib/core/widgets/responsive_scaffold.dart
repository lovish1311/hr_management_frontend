import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class ResponsiveScaffold extends StatefulWidget {
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

  // Global static notifier so sidebar collapse state is remembered across pages
  static final ValueNotifier<bool> isSidebarCollapsed = ValueNotifier<bool>(false);

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager.instance, ResponsiveScaffold.isSidebarCollapsed]),
      builder: (context, _) {
        final t = context.appTheme;
        final isCollapsed = ResponsiveScaffold.isSidebarCollapsed.value;

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
                    : (widget.appBar != null
                        ? PreferredSize(
                            preferredSize: widget.appBar!.preferredSize,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                iconTheme: IconThemeData(color: t.onBackgroundText),
                                appBarTheme: AppBarTheme(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  iconTheme: IconThemeData(color: t.onBackgroundText),
                                  actionsIconTheme: IconThemeData(color: t.onBackgroundText),
                                  titleTextStyle: TextStyle(
                                    color: t.onBackgroundText,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              child: widget.appBar!,
                            ),
                          )
                        : null),
                drawer: isDesktop ? null : HrDrawer(key: ValueKey('drawer_${t.name}')),
                floatingActionButton: widget.floatingActionButton,
                body: Row(
                  children: [
                    if (isDesktop)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        width: isCollapsed ? 0 : 280,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: isCollapsed ? Colors.transparent : t.border.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: OverflowBox(
                          minWidth: 280,
                          maxWidth: 280,
                          alignment: Alignment.topLeft,
                          child: HrDrawer(
                            key: ValueKey('sidebar_${t.name}'),
                            onCollapse: () {
                              ResponsiveScaffold.isSidebarCollapsed.value = true;
                            },
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (isDesktop)
                            SafeArea(
                              bottom: false,
                              child: SizedBox(
                                height: widget.appBar?.preferredSize.height ?? 52,
                                child: Row(
                                  children: [
                                    if (isCollapsed)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                                        child: Tooltip(
                                          message: 'Open Sidebar',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(10),
                                              onTap: () {
                                                ResponsiveScaffold.isSidebarCollapsed.value = false;
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: (t.isDarkTheme ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: (t.isDarkTheme ? Colors.white : Colors.black).withValues(alpha: 0.12),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.menu_rounded,
                                                  size: 20,
                                                  color: t.isDarkTheme ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (widget.appBar != null)
                                      Expanded(
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            iconTheme: IconThemeData(color: t.onBackgroundText),
                                            appBarTheme: AppBarTheme(
                                              backgroundColor: Colors.transparent,
                                              elevation: 0,
                                              iconTheme: IconThemeData(color: t.onBackgroundText),
                                              actionsIconTheme: IconThemeData(color: t.onBackgroundText),
                                              titleTextStyle: TextStyle(
                                                color: t.onBackgroundText,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          child: widget.appBar!,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          Expanded(
                            child: SafeArea(
                              bottom: true,
                              right: false,
                              top: isDesktop || widget.appBar == null,
                              child: widget.body,
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
