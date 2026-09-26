import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/data_table_widget.dart';
import '../../core/utils/responsive.dart';
import 'user_controller.dart';

class UserView extends GetView<UserController> {
  const UserView({super.key});

  void _showUserFormDialog([UserModel? user]) {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final passwordCtrl = TextEditingController();
    final selectedRole = (user?.role ?? AppStrings.roleStaff).obs;
    final isActive = (user != null ? user.isActive == 1 : true).obs;

    CustomDialog.show(
      title: user == null ? 'Create New User Account' : 'Edit User ${user.username}',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Full Name *',
              hint: 'e.g. Muhammad Usman',
              controller: fullNameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Username *',
              hint: 'e.g. usman.admin',
              controller: usernameCtrl,
              readOnly: user != null, // username should be immutable once created
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: user == null ? 'Password *' : 'New Password (Leave blank to keep unchanged)',
              hint: 'Enter password',
              controller: passwordCtrl,
              obscureText: true,
              validator: (v) {
                if (user == null && (v == null || v.trim().isEmpty)) {
                  return 'Password is required for new accounts';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Role *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole.value,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    AppStrings.roleAdmin,
                    AppStrings.roleStaff,
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) {
                    if (v != null) selectedRole.value = v;
                  },
                ),
              ],
            )),
            if (user != null) ...[
              const SizedBox(height: 14),
              Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Account Status', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(isActive.value ? 'Active & Permitted to Login' : 'Deactivated / Suspended', style: AppStyles.caption),
                value: isActive.value,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => isActive.value = v,
              )),
            ],
          ],
        ),
      ),
      actions: [
        CustomButton(
          text: 'Cancel',
          type: ButtonType.secondary,
          onPressed: () {
            if (Get.isDialogOpen == true) Get.back();
          },
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: user == null ? 'Create Account' : 'Save Changes',
          onPressed: () {
            if (formKey.currentState!.validate()) {
              if (user == null) {
                controller.createUser(
                  username: usernameCtrl.text,
                  password: passwordCtrl.text,
                  fullName: fullNameCtrl.text,
                  role: selectedRole.value,
                );
              } else {
                controller.updateUser(
                  id: user.id!,
                  fullName: fullNameCtrl.text,
                  role: selectedRole.value,
                  isActive: isActive.value ? 1 : 0,
                  newPassword: passwordCtrl.text.isNotEmpty ? passwordCtrl.text : null,
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            ResponsiveHeader(
              title: 'User & Role Management',
              subtitle: 'Manage administrator and office staff accounts, roles, and security access',
              actions: [
                CustomButton(
                  text: 'Add New User',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => _showUserFormDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Users Table
            Expanded(
              child: Obx(() {
                final list = controller.users;

                final List<List<Widget>> tableRows = list.map((u) {
                  return [
                    Text('#${u.id}', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                    Text(u.fullName, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text(u.username, style: AppStyles.bodySmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: u.isAdmin ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: u.isAdmin ? AppColors.primaryLight : AppColors.border),
                      ),
                      child: Text(
                        u.role,
                        style: AppStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: u.isAdmin ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(status: u.enabled ? 'Active' : 'Deactivated'),
                    Text(DateFormatter.formatDate(DateTime.tryParse(u.createdAt)), style: AppStyles.caption),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          tooltip: 'Edit User / Reset Password',
                          onPressed: () => _showUserFormDialog(u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          tooltip: 'Delete User',
                          onPressed: () async {
                            final confirmed = await CustomDialog.showConfirm(
                              title: 'Delete User ${u.username}?',
                              message: 'Are you sure you want to permanently delete user account "${u.username}"?',
                            );
                            if (confirmed) {
                              controller.deleteUser(u);
                            }
                          },
                        ),
                      ],
                    ),
                  ];
                }).toList();

                return DataTableWidget(
                  isLoading: controller.isLoading.value,
                  columns: const [
                    TableColumnDef(title: 'User ID'),
                    TableColumnDef(title: 'Full Name'),
                    TableColumnDef(title: 'Username'),
                    TableColumnDef(title: 'Role'),
                    TableColumnDef(title: 'Status'),
                    TableColumnDef(title: 'Created Date'),
                    TableColumnDef(title: 'Action', alignment: Alignment.center),
                  ],
                  rows: tableRows,
                  emptyTitle: 'No Users Found',
                  emptySubtitle: 'No user accounts found in local database.',
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
