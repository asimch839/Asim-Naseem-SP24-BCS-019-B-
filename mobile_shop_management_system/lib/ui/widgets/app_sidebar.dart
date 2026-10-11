import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../screens/login_screen.dart';

class NavItemData {
  final int index;
  final String title;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;

  const NavItemData({
    required this.index,
    required this.title,
    required this.icon,
    this.badgeText,
    this.badgeColor,
  });
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollapsed = app.isSidebarCollapsed;
    final sidebarWidth = isCollapsed ? 72.0 : 250.0;

    final lowStockCount = app.lowStockProducts.length + app.outOfStockProducts.length;
    final pendingRepairsCount = app.pendingRepairs.length;
    final duesCount = app.customersWithDues.length;

    final items = [
      const NavItemData(index: 0, title: 'Dashboard', icon: Icons.dashboard_rounded),
      const NavItemData(index: 1, title: 'POS / New Sale', icon: Icons.point_of_sale_rounded),
      const NavItemData(index: 2, title: 'Sales History', icon: Icons.receipt_long_rounded),
      const NavItemData(index: 3, title: 'Purchases', icon: Icons.shopping_bag_rounded),
      NavItemData(
        index: 4,
        title: 'Inventory & Stock',
        icon: Icons.inventory_2_rounded,
        badgeText: lowStockCount > 0 ? '$lowStockCount' : null,
        badgeColor: AppTheme.dangerRed,
      ),
      const NavItemData(index: 5, title: 'Mobile Phones (IMEI)', icon: Icons.phone_android_rounded),
      const NavItemData(index: 6, title: 'Accessories & Parts', icon: Icons.headphones_rounded),
      NavItemData(
        index: 7,
        title: 'Repair Lab',
        icon: Icons.build_circle_rounded,
        badgeText: pendingRepairsCount > 0 ? '$pendingRepairsCount' : null,
        badgeColor: AppTheme.warningOrange,
      ),
      const NavItemData(index: 8, title: 'Customers', icon: Icons.people_alt_rounded),
      const NavItemData(index: 9, title: 'Suppliers', icon: Icons.local_shipping_rounded),
      NavItemData(
        index: 10,
        title: 'Payments & Dues',
        icon: Icons.account_balance_wallet_rounded,
        badgeText: duesCount > 0 ? '$duesCount' : null,
        badgeColor: AppTheme.dangerRed,
      ),
      const NavItemData(index: 11, title: 'Expenses', icon: Icons.payments_rounded),
      const NavItemData(index: 12, title: 'Staff & Roles', icon: Icons.badge_rounded),
      const NavItemData(index: 13, title: 'Warranty Center', icon: Icons.verified_user_rounded),
      const NavItemData(index: 14, title: 'Reports & Profit', icon: Icons.bar_chart_rounded),
      const NavItemData(index: 15, title: 'Backup & Restore', icon: Icons.settings_backup_restore_rounded),
      const NavItemData(index: 16, title: 'Settings', icon: Icons.settings_rounded),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Branding Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 18,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryBlue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          app.settings.shopName.isNotEmpty ? app.settings.shopName : 'Mobile Shop Lab',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'POS & Repair Lab System',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation Links List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: isCollapsed ? 6 : 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = app.currentNavIndex == item.index;

                final itemWidget = Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Material(
                    color: isActive ? AppTheme.sidebarActive : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => app.setNavIndex(item.index),
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: const Color(0xFF1E293B),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 12 : 14,
                          vertical: 9.5,
                        ),
                        child: Row(
                          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 19,
                                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                                ),
                                if (isCollapsed && item.badgeText != null)
                                  Positioned(
                                    right: -6,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: item.badgeColor ?? AppTheme.dangerRed,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                                    ),
                                  ),
                              ],
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                                    fontSize: 12.5,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.badgeText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.badgeColor ?? AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                if (isCollapsed) {
                  return Tooltip(
                    message: item.title,
                    waitDuration: const Duration(milliseconds: 250),
                    child: itemWidget,
                  );
                }
                return itemWidget;
              },
            ),
          ),

          // User Profile & Sign Out Bottom Box (Hostel System Style)
          Container(
            padding: EdgeInsets.all(isCollapsed ? 10 : 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1120),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.sidebarActive.withValues(alpha: 0.25),
                  child: Text(
                    app.currentUser.name.isNotEmpty ? app.currentUser.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          app.currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          app.currentUser.role.displayName,
                          style: const TextStyle(
                            color: AppTheme.accentTealLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 18),
                    tooltip: 'Sign Out',
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ],
            ),
          ),

          // Software House Branding Footer (Hostel System Style)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: isCollapsed ? 6 : 10),
            decoration: const BoxDecoration(
              color: Color(0xFF090E1A),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: isCollapsed
                ? const Tooltip(
                    message: 'Software Developed by Devnix Limited\nContact: 0300-7720839',
                    child: Center(
                      child: Icon(Icons.code_rounded, size: 16, color: AppTheme.accentTealLight),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_rounded, size: 13, color: AppTheme.accentTealLight),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Devnix Limited • 0300-7720839',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.dangerRed, size: 22),
            SizedBox(width: 8),
            Text('Sign Out?'),
          ],
        ),
        content: const Text('Are you sure you want to log out from the system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
