import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phonelink_setup_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'POS & Repair Lab System',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = app.currentNavIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: () => app.setNavIndex(item.index),
                      borderRadius: BorderRadius.circular(7),
                      hoverColor: Colors.white.withOpacity(0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: isActive ? Colors.white : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                                  fontSize: 13,
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
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090E17) : const Color(0xFF16202E),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                  child: Text(
                    app.currentUser.name.isNotEmpty ? app.currentUser.name[0] : 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
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
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () => app.setNavIndex(16),
                ),
              ],
            ),
          ),
          // Devnix Branding
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            color: isDark ? const Color(0xFF090E17) : const Color(0xFF16202E),
            child: const Column(
              children: [
                Text(
                  'Software Developed by Devnix Limited',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2),
                Text(
                  '0300-7720839',
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
