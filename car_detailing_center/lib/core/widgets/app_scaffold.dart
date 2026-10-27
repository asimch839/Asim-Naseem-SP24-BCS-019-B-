import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../responsive/responsive_layout.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../../features/notifications/notification_controller.dart';
import 'sync_badge.dart';
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
  static final Map<String, bool> _expandedModules = {
    'Staff': false,
    'Inventory': false,
  };

  // The 11 Strict Main Navigation Modules per Section 6
  static const List<MainModuleItem> _modules = [
    MainModuleItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: AppRoutes.dashboard,
    ),
    MainModuleItem(
      title: 'Staff',
      icon: Icons.badge_rounded,
      route: AppRoutes.staff,
      subItems: [
        NavSubItem(title: 'Staff List', icon: Icons.people_alt_rounded, tabIndex: 0),
        NavSubItem(title: 'Attendance', icon: Icons.event_available_rounded, tabIndex: 1),
        NavSubItem(title: 'Salaries', icon: Icons.payments_rounded, tabIndex: 2),
        NavSubItem(title: 'Staff Expenses', icon: Icons.account_balance_wallet_rounded, tabIndex: 3),
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
    final userRole = auth.currentUser.value?.role ?? AppConstants.roleAdmin;

    return Scaffold(
      drawer: ResponsiveLayout.isDesktop(context)
          ? null
          : Drawer(
              child: _buildSidebarContent(context),
            ),
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

          // Sync Badge (shown on tablet & desktop)
          if (!ResponsiveLayout.isMobile(context)) ...[
            const SizedBox(width: 8),
            const SyncBadge(),
            const SizedBox(width: 8),
          ],

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

          // Role Badge (shown on tablet & desktop)
          if (!ResponsiveLayout.isMobile(context)) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                userRole.toUpperCase(),
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],

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
    return Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Car Detailing Center Management',
                        style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
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
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: showHeaderIndicator
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : Colors.transparent,
                            border: showHeaderIndicator
                                ? Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.2)
                                : null,
                          ),
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
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: showHeaderIndicator
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryLight.withValues(alpha: 0.8),
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
                                  color: isModuleActive ? AppColors.primaryLight : AppColors.textDarkSecondary,
                                ),
                              ],
                            ),
                            title: Text(
                              module.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isModuleActive ? FontWeight.bold : FontWeight.normal,
                                color: isModuleActive ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isModuleActive ? AppColors.primaryLight : AppColors.textDarkMuted,
                            ),
                            onTap: () {
                              setState(() {
                                _expandedModules[module.title] = !isExpanded;
                              });
                            },
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
                                    color: isSubSelected
                                        ? AppColors.primary.withValues(alpha: 0.22)
                                        : Colors.transparent,
                                    border: isSubSelected
                                        ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.55), width: 1.2)
                                        : Border.all(color: Colors.transparent, width: 1.2),
                                  ),
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
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(2),
                                            boxShadow: isSubSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primaryLight.withValues(alpha: 0.9),
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
                                          color: isSubSelected ? AppColors.primaryLight : AppColors.textDarkMuted,
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      sub.title,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isSubSelected ? Colors.white : AppColors.textDarkSecondary,
                                        fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: isSubSelected
                                        ? Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryLight.withValues(alpha: 0.9),
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
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5), width: 1.2)
                        : Border.all(color: Colors.transparent, width: 1.2),
                  ),
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
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryLight.withValues(alpha: 0.8),
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
                          color: isSelected ? AppColors.primaryLight : AppColors.textDarkSecondary,
                        ),
                      ],
                    ),
                    title: Text(
                      module.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLight.withValues(alpha: 0.9),
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
                );
              },
            ),
          ),

          // User Profile Card & Sign Out at Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    AuthService.to.currentUser.value?.fullName.isNotEmpty == true
                        ? AuthService.to.currentUser.value!.fullName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthService.to.currentUser.value?.fullName ?? 'Administrator',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AuthService.to.currentUser.value?.email ?? 'admin@autodetail.com',
                        style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
