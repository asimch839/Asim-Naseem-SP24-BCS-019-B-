import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import 'global_search_dialog.dart';
import 'custom_dialogs.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Global Search trigger button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const GlobalSearchDialog(),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 320,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search IMEI, Phone, Product, Customer... [F2]',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'Ctrl+F',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Quick Action Buttons
          if (app.currentUser.role.canMakeSales)
            ElevatedButton.icon(
              onPressed: () => app.setNavIndex(1), // POS
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
              label: const Text('New Sale (F1)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),

          const SizedBox(width: 8),

          if (app.currentUser.role.canManageRepairs)
            ElevatedButton.icon(
              onPressed: () {
                AppDialogs.showNewRepairDialog(context);
              },
              icon: const Icon(Icons.build_rounded, size: 16),
              label: const Text('New Repair (F4)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purpleRepair,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),

          const SizedBox(width: 8),

          if (app.currentUser.role.canReceivePayments)
            OutlinedButton.icon(
              onPressed: () {
                AppDialogs.showReceivePaymentDialog(context);
              },
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppTheme.successGreen),
              label: const Text('Receive Payment (F6)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),

          const Spacer(),

          // Active Role Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: app.currentUser.id,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: app.allUsers.map((u) {
                  return DropdownMenuItem<String>(
                    value: u.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle_rounded, size: 17, color: AppTheme.primaryBlue),
                        const SizedBox(width: 6),
                        Text(
                          '${u.name} (${u.role.displayName})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    final target = app.allUsers.firstWhere((u) => u.id == id);
                    app.switchUser(target);
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Notifications Bell Popover
          PopupMenuButton<void>(
            tooltip: 'Alerts & Notifications',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
                if (app.totalNotificationsCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${app.totalNotificationsCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'Active Shop Alerts (${app.totalNotificationsCount})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                if (app.lowStockProducts.isNotEmpty)
                  PopupMenuItem(
                    onTap: () => app.setNavIndex(4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.dangerRed),
                        const SizedBox(width: 8),
                        Text('${app.lowStockProducts.length} Products Low in Stock'),
                      ],
                    ),
                  ),
                if (app.readyRepairs.isNotEmpty)
                  PopupMenuItem(
                    onTap: () => app.setNavIndex(7),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppTheme.successGreen),
                        const SizedBox(width: 8),
                        Text('${app.readyRepairs.length} Repaired Devices Ready for Delivery'),
                      ],
                    ),
                  ),
                if (app.customersWithDues.isNotEmpty)
                  PopupMenuItem(
                    onTap: () => app.setNavIndex(10),
                    child: Row(
                      children: [
                        const Icon(Icons.money_off_rounded, size: 18, color: AppTheme.warningOrange),
                        const SizedBox(width: 8),
                        Text('${app.customersWithDues.length} Customers with Outstanding Dues'),
                      ],
                    ),
                  ),
                if (app.totalNotificationsCount == 0)
                  const PopupMenuItem(
                    enabled: false,
                    child: Text('All clear! No pending alerts.'),
                  ),
              ];
            },
          ),

          const SizedBox(width: 6),

          // Theme Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
            ),
            onPressed: () => app.toggleDarkMode(),
          ),

          const SizedBox(width: 6),

          // Refresh All Data
          IconButton(
            tooltip: 'Refresh All (F5)',
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            onPressed: () {
              app.reloadAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shop data refreshed successfully'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
