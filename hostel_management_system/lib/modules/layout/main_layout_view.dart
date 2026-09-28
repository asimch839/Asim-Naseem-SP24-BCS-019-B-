import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/interactive_scroll_view.dart';
import 'main_layout_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../students/student_view.dart';
import '../rooms/room_view.dart';
import '../admissions/admission_view.dart';
import '../rent/rent_view.dart';
import '../receipts/receipt_view.dart';
import '../expenses/expense_view.dart';
import '../history/history_view.dart';
import '../reports/report_view.dart';
import '../users/user_view.dart';
import '../settings/settings_view.dart';

class MainLayoutView extends GetView<MainLayoutController> {
  const MainLayoutView({super.key});

  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Desktop stability guard: Prevent root dashboard route from ever popping and exiting the application
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: isMobile ? _buildDrawer(context) : null,
        body: Row(
          children: [
            // 1. Persistent Sidebar for Desktop & Tablets
            if (!isMobile) _buildSidebar(context),

            // 2. Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top App Bar
                  _buildTopAppBar(context, isMobile),

                  // Active Module View
                  Expanded(
                    child: InteractiveBiDirectionalScrollView(
                      minWidth: isMobile ? 0.0 : 1050.0,
                      minHeight: isMobile ? 0.0 : 680.0,
                      child: Obx(() {
                        switch (controller.selectedIndex.value) {
                          case 0:
                            return const DashboardView();
                          case 1:
                            return const StudentView();
                          case 2:
                            return const RoomView();
                          case 3:
                            return const AdmissionView();
                          case 4:
                            return const RentView();
                          case 5:
                            return const ReceiptView();
                          case 6:
                            return const ExpenseView();
                          case 7:
                            return const HistoryView();
                          case 8:
                            return const ReportView();
                          case 9:
                            return const UserView();
                          case 10:
                            return const SettingsView();
                          default:
                            return const DashboardView();
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Drawer for mobile view
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.sidebarBg,
      child: SafeArea(
        child: _buildSidebarContent(context, isDrawer: true),
      ),
    );
  }

  /// Persistent sidebar for tablet & desktop
  Widget _buildSidebar(BuildContext context) {
    return Obx(() {
      final isCollapsed = controller.isSidebarCollapsed.value;
      final sidebarWidth = isCollapsed ? 72.0 : 250.0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: sidebarWidth,
        color: AppColors.sidebarBg,
        child: _buildSidebarContent(context, isCollapsed: isCollapsed),
      );
    });
  }

  Widget _buildSidebarContent(BuildContext context, {bool isDrawer = false, bool isCollapsed = false}) {
    return Column(
      children: [
        // Brand & Logo Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 18, vertical: 18),
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
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    AppStrings.logoSquareAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final hostel = controller.hostelSettings.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hostel?.hostelName ?? AppStrings.appName,
                          style: AppStyles.h4.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.appTagline,
                          style: AppStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 9.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ],
          ),
        ),

        // Navigation Links List
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: isCollapsed ? 6 : 10),
            children: [
              _navItem(0, 'Dashboard', Icons.dashboard_rounded, isCollapsed, isDrawer),
              _navItem(1, 'Students', Icons.people_alt_rounded, isCollapsed, isDrawer),
              _navItem(2, 'Rooms & Beds', Icons.meeting_room_rounded, isCollapsed, isDrawer),
              _navItem(3, 'Admissions', Icons.how_to_reg_rounded, isCollapsed, isDrawer),
              _navItem(4, 'Rent & Payments', Icons.payments_rounded, isCollapsed, isDrawer),
              _navItem(5, 'Receipts', Icons.receipt_long_rounded, isCollapsed, isDrawer),
              _navItem(6, 'Expenses', Icons.shopping_bag_outlined, isCollapsed, isDrawer),
              _navItem(7, 'History', Icons.history_rounded, isCollapsed, isDrawer),
              _navItem(8, 'Reports', Icons.insert_chart_outlined_rounded, isCollapsed, isDrawer),
              if (AuthService.to.isAdmin)
                _navItem(9, 'Users & Roles', Icons.manage_accounts_rounded, isCollapsed, isDrawer),
              _navItem(10, 'Settings', Icons.settings_outlined, isCollapsed, isDrawer),
            ],
          ),
        ),

        // User Profile & Logout Bottom Box
        Container(
          padding: EdgeInsets.all(isCollapsed ? 10 : 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.sidebarHover,
                child: Text(
                  AuthService.to.currentUsername.isNotEmpty
                      ? AuthService.to.currentUsername[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                        AuthService.to.currentUser.value?.fullName ?? AuthService.to.currentUsername,
                        style: AppStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AuthService.to.currentUser.value?.role ?? 'Staff',
                        style: AppStyles.caption.copyWith(color: AppColors.accentLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 18),
                  tooltip: 'Sign Out',
                  onPressed: () => _handleLogout(),
                ),
              ],
            ],
          ),
        ),

        // Software House Branding Footer
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: isCollapsed ? 6 : 12),
          decoration: const BoxDecoration(
            color: Color(0xFF090E1A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: isCollapsed
              ? const Tooltip(
                  message: '${AppStrings.developerCompany}\nContact: ${AppStrings.developerContact}',
                  child: Center(
                    child: Icon(Icons.code_rounded, size: 16, color: AppColors.accentLight),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.code_rounded, size: 13, color: AppColors.accentLight),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppStrings.developerBrandingShort,
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
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
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await CustomDialog.showConfirm(
      title: 'Sign Out?',
      message: 'Are you sure you want to log out from the system?',
      confirmText: 'Log Out',
      confirmButtonType: ButtonType.danger,
    );
    if (confirmed) {
      AuthService.to.logout();
    }
  }

  Widget _navItem(int index, String title, IconData icon, bool isCollapsed, bool isDrawer) {
    return Obx(() {
      final isSelected = controller.selectedIndex.value == index;
      final itemWidget = Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: isSelected ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              controller.setNavIndex(index);
              if (isDrawer) {
                _scaffoldKey.currentState?.closeDrawer();
              }
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: isSelected ? AppColors.sidebarActive : AppColors.sidebarHover,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 14,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.bodySmall.copyWith(
                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          message: title,
          waitDuration: const Duration(milliseconds: 300),
          child: itemWidget,
        );
      }
      return itemWidget;
    });
  }

  Widget _buildTopAppBar(BuildContext context, bool isMobile) {
    final topPadding = isMobile ? (MediaQuery.of(context).padding.top + 8.0) : 0.0;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding,
        left: isMobile ? 12 : 20,
        right: isMobile ? 12 : 20,
        bottom: isMobile ? 8 : 0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Menu button (Mobile) or Collapse Toggle (Desktop/Tablet) + DB Badge
            Row(
              children: [
                if (isMobile) ...[
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                    tooltip: 'Open Menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  IconButton(
                    icon: Obx(() => Icon(
                      controller.isSidebarCollapsed.value ? Icons.menu_open_rounded : Icons.menu_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    )),
                    tooltip: 'Toggle Sidebar',
                    onPressed: controller.toggleSidebar,
                  ),
                ],
              ],
            ),

            // Right: Realtime Clock & Refresh View
            Row(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = MediaQuery.of(context).size.width;
                    if (screenW < 450) {
                      return const SizedBox.shrink(); // hide clock on extremely small phone screen
                    }
                    return Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Obx(() => Text(
                          controller.currentTimeString.value,
                          style: AppStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: screenW < 700 ? 11 : 12,
                          ),
                        )),
                        const SizedBox(width: 12),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                  tooltip: 'Refresh Current View',
                  onPressed: () => controller.setNavIndex(controller.selectedIndex.value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
