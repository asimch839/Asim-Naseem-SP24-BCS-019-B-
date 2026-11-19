import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../responsive/responsive_layout.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../../features/notifications/notification_controller.dart';
import '../../features/search/global_search_dialog.dart';
import '../../features/staff/staff_screen.dart';

class NavSubItem {
  final String title;
  final IconData icon;
  final int tabIndex;

  const NavSubItem({
    required this.title,
    required this.icon,
    required this.tabIndex,
  });
}

class MainModuleItem {
  final String title;
  final IconData icon;
  final String route;
  final List<NavSubItem>? subItems;

  const MainModuleItem({
    required this.title,
    required this.icon,
    required this.route,
    this.subItems,
  });
}

class AppScaffold extends StatefulWidget {
  final String currentRoute;
  final String? currentSubItem;
  final void Function(NavSubItem subItem)? onSubItemSelect;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.currentRoute,
    this.currentSubItem,
    this.onSubItemSelect,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final Map<String, bool> _expandedModules = {
    'Staff': false,
    'Inventory': false,
  };

  static double _sidebarScrollOffset = 0.0;
  late final ScrollController _sidebarScrollController;
  final GlobalKey _activeModuleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final isStaff = widget.currentRoute == AppRoutes.staff;
    final isInventory = widget.currentRoute == AppRoutes.inventory || widget.currentRoute == AppRoutes.vendors;
    if (isStaff) _expandedModules['Staff'] = true;
    if (isInventory) _expandedModules['Inventory'] = true;

    _sidebarScrollController = ScrollController(initialScrollOffset: _sidebarScrollOffset);
    _sidebarScrollController.addListener(() {
      if (_sidebarScrollController.hasClients) {
        _sidebarScrollOffset = _sidebarScrollController.offset;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_activeModuleKey.currentContext != null) {
        Scrollable.ensureVisible(
          _activeModuleKey.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    super.dispose();
  }

  int _getBottomNavIndex() {
    switch (widget.currentRoute) {
      case AppRoutes.dashboard:
        return 0;
      case AppRoutes.jobs:
        return 1;
      case AppRoutes.invoices:
        return 2;
      case AppRoutes.staff:
        return 3;
      default:
        return 4; // 'More'
    }
  }

  // The 11 Strict Main Navigation Modules per Section 6
  static const List<MainModuleItem> _modules = [
    MainModuleItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: AppRoutes.dashboard,
    ),
    MainModuleItem(
      title: 'Job Cards & Orders',
      icon: Icons.assignment_rounded,
      route: AppRoutes.jobs,
    ),
    MainModuleItem(
      title: 'Staff',
      icon: Icons.badge_rounded,
      route: AppRoutes.staff,
      subItems: [
        NavSubItem(title: 'Staff List', icon: Icons.people_alt_rounded, tabIndex: 0),
        NavSubItem(title: 'Commission Staff', icon: Icons.handshake_rounded, tabIndex: 1),
        NavSubItem(title: 'Attendance', icon: Icons.event_available_rounded, tabIndex: 2),
        NavSubItem(title: 'Salaries', icon: Icons.payments_rounded, tabIndex: 3),
        NavSubItem(title: 'Staff Expenses', icon: Icons.account_balance_wallet_rounded, tabIndex: 4),
      ],
    ),
    MainModuleItem(
      title: 'Garage Expense',
      icon: Icons.receipt_long_rounded,
      route: AppRoutes.garageExpenses,
    ),
    MainModuleItem(
      title: 'Inventory',
      icon: Icons.inventory_2_rounded,
      route: AppRoutes.inventory,
      subItems: [
        NavSubItem(title: 'Stock Details', icon: Icons.format_list_bulleted_rounded, tabIndex: 0),
        NavSubItem(title: 'Vendors', icon: Icons.storefront_rounded, tabIndex: 1),
      ],
    ),
    MainModuleItem(
      title: 'Invoices',
      icon: Icons.description_rounded,
      route: AppRoutes.invoices,
    ),
    MainModuleItem(
      title: 'Payments',
      icon: Icons.price_check_rounded,
      route: AppRoutes.payments,
    ),
    MainModuleItem(
      title: 'Reports',
      icon: Icons.analytics_rounded,
      route: AppRoutes.reports,
    ),
    MainModuleItem(
      title: 'Settings',
      icon: Icons.settings_rounded,
      route: AppRoutes.settings,
    ),
    MainModuleItem(
      title: 'Vehicles',
      icon: Icons.directions_car_rounded,
      route: AppRoutes.vehicles,
    ),
    MainModuleItem(
      title: 'Car Showroom',
      icon: Icons.directions_car_filled_rounded,
      route: AppRoutes.showroom,
    ),
    MainModuleItem(
      title: 'Customers',
      icon: Icons.people_alt_rounded,
      route: AppRoutes.customers,
    ),
    MainModuleItem(
      title: 'Inspections',
      icon: Icons.fact_check_rounded,
      route: AppRoutes.inspections,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.to;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: ResponsiveLayout.isDesktop(context)
          ? null
          : Drawer(
              child: _buildSidebarContent(context),
            ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _getBottomNavIndex(),
              height: 60,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    if (widget.currentRoute != AppRoutes.dashboard) Get.offNamed(AppRoutes.dashboard);
                    break;
                  case 1:
                    if (widget.currentRoute != AppRoutes.jobs) Get.offNamed(AppRoutes.jobs);
                    break;
                  case 2:
                    if (widget.currentRoute != AppRoutes.invoices) Get.offNamed(AppRoutes.invoices);
                    break;
                  case 3:
                    if (widget.currentRoute != AppRoutes.staff) Get.offNamed(AppRoutes.staff);
                    break;
                  case 4:
                    _scaffoldKey.currentState?.openDrawer();
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, size: 20),
                  selectedIcon: Icon(Icons.dashboard_rounded, size: 20),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined, size: 20),
                  selectedIcon: Icon(Icons.assignment_rounded, size: 20),
                  label: 'Job Cards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, size: 20),
                  selectedIcon: Icon(Icons.receipt_long_rounded, size: 20),
                  label: 'Invoices',
                ),
                NavigationDestination(
                  icon: Icon(Icons.badge_outlined, size: 20),
                  selectedIcon: Icon(Icons.badge_rounded, size: 20),
                  label: 'Staff',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded, size: 20),
                  selectedIcon: Icon(Icons.menu_open_rounded, size: 20),
                  label: 'More',
                ),
              ],
            )
          : null,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Global Search trigger
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Global Search',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const GlobalSearchDialog(),
              );
            },
          ),

          // Notification Bell with Unread Badge
          Obx(() {
            final unread = Get.isRegistered<NotificationController>()
                ? NotificationController.to.unreadCount.value
                : 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'Notifications',
                  onPressed: () => Get.toNamed(AppRoutes.notifications),
                ),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
          ...?widget.actions,
        ],
      ),
      body: ResponsiveLayout(
        mobile: widget.body,
        tablet: widget.body,
        desktop: Row(
          children: [
            // Sidebar for Windows Desktop
            SizedBox(
              width: 260,
              child: _buildSidebarContent(context),
            ),
            const VerticalDivider(width: 1),
            // Main Content Area
            Expanded(child: widget.body),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final textMuted = isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;

    final activeText = isDark ? Colors.white : AppColors.primaryDark;
    final activeIcon = isDark ? AppColors.primaryLight : AppColors.primary;
    final activeBg = isDark ? AppColors.primary.withValues(alpha: 0.22) : AppColors.primary.withValues(alpha: 0.12);
    final activeBorder = isDark ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.4);

    return Material(
      color: Theme.of(context).cardTheme.color,
      child: Column(
        children: [
          // Business Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Detail & Performance',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 11 Navigation Modules List
          Expanded(
            child: ListView.builder(
              controller: _sidebarScrollController,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                final isDirectSelected = widget.currentRoute == module.route;

                if (module.subItems != null && module.subItems!.isNotEmpty) {
                  final isExpanded = _expandedModules[module.title] ?? false;
                  final hasActiveSubItem = module.subItems!.any((sub) {
                    if (widget.currentSubItem != null && widget.currentSubItem!.isNotEmpty) {
                      return sub.title.toLowerCase() == widget.currentSubItem!.toLowerCase();
                    }
                    return (sub.title == 'Vendors' && widget.currentRoute == AppRoutes.vendors) ||
                        (sub.title == 'Stock Details' && widget.currentRoute == AppRoutes.inventory) ||
                        (sub.title == 'Staff List' && widget.currentRoute == AppRoutes.staff);
                  });
                  final isModuleActive = isDirectSelected || hasActiveSubItem;
                  final showHeaderIndicator = !isExpanded && isModuleActive;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          key: isModuleActive ? _activeModuleKey : null,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: showHeaderIndicator ? activeBg : Colors.transparent,
                            border: showHeaderIndicator
                                ? Border.all(color: activeBorder, width: 1.2)
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: showHeaderIndicator ? 3.5 : 0,
                                    height: 20,
                                    margin: EdgeInsets.only(right: showHeaderIndicator ? 8 : 0),
                                    decoration: BoxDecoration(
                                      color: activeIcon,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: showHeaderIndicator
                                          ? [
                                              BoxShadow(
                                                color: activeIcon.withValues(alpha: 0.8),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  Icon(
                                    module.icon,
                                    size: 20,
                                    color: isModuleActive ? activeIcon : textSecondary,
                                  ),
                                ],
                              ),
                              title: Text(
                                module.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isModuleActive ? FontWeight.bold : FontWeight.w500,
                                  color: isModuleActive ? activeText : textPrimary,
                                ),
                              ),
                              trailing: Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isModuleActive ? activeIcon : textMuted,
                              ),
                              onTap: () {
                                if (widget.currentRoute != module.route) {
                                  setState(() {
                                    _expandedModules[module.title] = true;
                                  });
                                  Get.offNamed(module.route);
                                } else {
                                  setState(() {
                                    _expandedModules[module.title] = !isExpanded;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Column(
                              children: module.subItems!.map((sub) {
                                final bool isSubSelected;
                                if (widget.currentSubItem != null && widget.currentSubItem!.isNotEmpty) {
                                  isSubSelected = sub.title.toLowerCase() == widget.currentSubItem!.toLowerCase();
                                } else {
                                  isSubSelected = (sub.title == 'Vendors' && widget.currentRoute == AppRoutes.vendors) ||
                                      (sub.title == 'Stock Details' && widget.currentRoute == AppRoutes.inventory) ||
                                      (sub.title == 'Staff List' && widget.currentRoute == AppRoutes.staff);
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: isSubSelected ? activeBg : Colors.transparent,
                                    border: isSubSelected
                                        ? Border.all(color: activeBorder, width: 1.2)
                                        : Border.all(color: Colors.transparent, width: 1.2),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: isSubSelected ? 3.5 : 0,
                                            height: 16,
                                            margin: EdgeInsets.only(right: isSubSelected ? 6 : 0),
                                            decoration: BoxDecoration(
                                              color: activeIcon,
                                              borderRadius: BorderRadius.circular(2),
                                              boxShadow: isSubSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: activeIcon.withValues(alpha: 0.9),
                                                        blurRadius: 6,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                          Icon(
                                            sub.icon,
                                            size: 16,
                                            color: isSubSelected ? activeIcon : textMuted,
                                          ),
                                        ],
                                      ),
                                      title: Text(
                                        sub.title,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isSubSelected ? activeText : textSecondary,
                                          fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                      trailing: isSubSelected
                                          ? Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: activeIcon,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: activeIcon.withValues(alpha: 0.9),
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        if (module.route == AppRoutes.staff) {
                                          if (widget.currentRoute == AppRoutes.staff && widget.onSubItemSelect != null) {
                                            widget.onSubItemSelect!(sub);
                                          } else {
                                            Get.offAll(() => StaffScreen(initialTabIndex: sub.tabIndex));
                                          }
                                        } else if (sub.title == 'Vendors') {
                                          Get.offNamed(AppRoutes.vendors);
                                        } else if (sub.title == 'Stock Details') {
                                          Get.offNamed(AppRoutes.inventory);
                                        } else {
                                          Get.offNamed(module.route);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final isSelected = widget.currentRoute == module.route;
                return Container(
                  key: isSelected ? _activeModuleKey : null,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? activeBg : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: activeBorder, width: 1.2)
                        : Border.all(color: Colors.transparent, width: 1.2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 3.5 : 0,
                            height: 20,
                            margin: EdgeInsets.only(right: isSelected ? 8 : 0),
                            decoration: BoxDecoration(
                              color: activeIcon,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: activeIcon.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          Icon(
                            module.icon,
                            size: 20,
                            color: isSelected ? activeIcon : textSecondary,
                          ),
                        ],
                      ),
                      title: Text(
                        module.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? activeText : textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: activeIcon,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: activeIcon.withValues(alpha: 0.9),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            )
                          : null,
                      onTap: () {
                        if (!isSelected) {
                          Get.offNamed(module.route);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Devnix Limited Developer Footer
          InkWell(
            onTap: () => _showDeveloperInfo(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.shade100,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4))),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 14, color: isDark ? AppColors.primaryLight : AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConstants.developerName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Support: ${AppConstants.developerPhone}',
                          style: TextStyle(fontSize: 10, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(AppConstants.developerName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Software Engineering & IT Solutions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'This enterprise management software is developed and supported by Devnix Limited.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Direct Support Helpline:', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                      SelectableText(
                        AppConstants.developerPhone,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out from the business center?'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Get.back(result: true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await AuthService.to.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
