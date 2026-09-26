import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/responsive.dart';
import 'settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Action
            ResponsiveHeader(
              title: 'System Settings & Maintenance',
              subtitle: 'Manage hostel identity, billing rules, offline data storage & backup, and account security',
              actions: [
                Obx(() {
                  if (controller.selectedTab.value == 0) {
                    return CustomButton(
                      text: 'Save All Settings',
                      icon: Icons.save_rounded,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.saveSettings,
                    );
                  } else if (controller.selectedTab.value == 1) {
                    return CustomButton(
                      text: 'Refresh Status',
                      icon: Icons.refresh_rounded,
                      type: ButtonType.secondary,
                      isLoading: controller.isLoadingDbInfo.value,
                      onPressed: controller.loadDatabaseInfo,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Modern Tab Navigation with Horizontal Scroll Safety
            Obx(() => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      index: 0,
                      label: 'General Configuration',
                      icon: Icons.tune_rounded,
                      isSelected: controller.selectedTab.value == 0,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      index: 1,
                      label: 'Data & Backup Center',
                      icon: Icons.storage_rounded,
                      isSelected: controller.selectedTab.value == 1,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      index: 2,
                      label: 'Account & Security',
                      icon: Icons.security_rounded,
                      isSelected: controller.selectedTab.value == 2,
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // Tab Content
            Obx(() {
              if (controller.selectedTab.value == 0) {
                return _buildGeneralSettingsTab();
              } else if (controller.selectedTab.value == 1) {
                return _buildDataAndBackupTab();
              } else {
                return _buildAccountSecurityTab();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => controller.selectedTab.value = index,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: GENERAL SETTINGS
  // ==========================================
  Widget _buildGeneralSettingsTab() {
    return Form(
      key: controller.formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 1000;
          final isMobile = constraints.maxWidth < 550;

          final leftCol = Column(
            children: [
              // Card 1: Hostel Profile Details
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader('Hostel Profile Details', Icons.business_rounded),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppStrings.logoSquareAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.apartment_rounded, size: 28, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.appName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.appTagline,
                                style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Hostel Name (Locked)',
                      controller: controller.hostelNameCtrl,
                      readOnly: true,
                      suffix: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Tooltip(
                          message: 'Hostel name is fixed and cannot be changed from settings.',
                          child: Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Address *',
                      hint: 'Street, Sector, City',
                      controller: controller.addressCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    isMobile
                        ? Column(
                            children: [
                              CustomTextField(
                                label: 'Official Phone *',
                                hint: '+92 300 1234567',
                                controller: controller.phoneCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                label: 'Official Email *',
                                hint: 'admin@hostel.local',
                                controller: controller.emailCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Official Phone *',
                                  hint: '+92 300 1234567',
                                  controller: controller.phoneCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Official Email *',
                                  hint: 'admin@hostel.local',
                                  controller: controller.emailCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card 2: Invoice & Receipt Details
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader('Invoice & Receipt Printing', Icons.receipt_long_rounded),
                    const SizedBox(height: 18),
                    isMobile
                        ? Column(
                            children: [
                              CustomTextField(
                                label: 'Receipt Number Prefix *',
                                hint: 'REC-',
                                controller: controller.receiptPrefixCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                label: 'Authorized Person *',
                                hint: 'Warden / Manager Name',
                                controller: controller.authorizedPersonCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Receipt Number Prefix *',
                                  hint: 'REC-',
                                  controller: controller.receiptPrefixCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Authorized Person *',
                                  hint: 'Warden / Manager Name',
                                  controller: controller.authorizedPersonCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Receipt Footer / Note *',
                      hint: 'Thank you for choosing our hostel!',
                      controller: controller.receiptFooterCtrl,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          );

          final rightCol = Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader('Default Monthly Rent & Billing', Icons.monetization_on_rounded),
                    const SizedBox(height: 18),
                    CustomTextField(
                      label: 'Default Monthly Rent Amount *',
                      hint: '15000',
                      controller: controller.defaultRentCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Must be positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    isMobile
                        ? Column(
                            children: [
                              CustomTextField(
                                label: 'Rent Due Day * (1-28)',
                                hint: '5',
                                controller: controller.dueDayCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final p = int.tryParse(v ?? '');
                                  if (p == null || p < 1 || p > 28) return 'Day between 1-28';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                label: 'Currency Symbol *',
                                hint: 'PKR / Rs.',
                                controller: controller.currencyCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Rent Due Day * (1-28)',
                                  hint: '5',
                                  controller: controller.dueDayCtrl,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final p = int.tryParse(v ?? '');
                                    if (p == null || p < 1 || p > 28) return 'Day between 1-28';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Currency Symbol *',
                                  hint: 'PKR / Rs.',
                                  controller: controller.currencyCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Card: Software Development & Support Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.code_rounded, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Software Development & Support',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Developed by ${AppStrings.developerCompany}',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Contact / Support: ${AppStrings.developerContact}',
                          style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          if (isStacked) {
            return Column(
              children: [
                leftCol,
                const SizedBox(height: 20),
                rightCol,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: leftCol),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: rightCol),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 2: DATA & BACKUP CENTER
  // ==========================================
  Widget _buildDataAndBackupTab() {
    final info = controller.dbInfo.value;
    final lastBackupFormatted = info?.lastBackupAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(info!.lastBackupAt!) ?? DateTime.now())
        : 'No backup recorded yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informational Banner Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_rounded, color: AppColors.info, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Separated Data Storage & Desktop Protection',
                      style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your hostel data is stored locally on this computer, completely independent of the application installation directory. Reinstalling or updating the app will not touch your records. Create regular backups to protect your data and move it safely to another computer or new laptop.',
                      style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 1000;
            final leftCol = Column(
              children: [
                // Card: Database Information
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildCardHeader('Database Information', Icons.dns_rounded)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Connected',
                                  style: AppStyles.caption.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Telemetry Metrics Grid
                      _buildInfoRow(
                        label: 'Current Database Location',
                        value: info?.path ?? 'Loading...',
                        icon: Icons.folder_rounded,
                        trailing: IconButton(
                          icon: const Icon(Icons.folder_open_rounded, size: 20, color: AppColors.primary),
                          tooltip: 'Open folder in File Explorer',
                          onPressed: controller.openDatabaseFolder,
                        ),
                      ),
                      const Divider(height: 24),
                      LayoutBuilder(
                        builder: (context, cardConstraints) {
                          if (cardConstraints.maxWidth < 450) {
                            return Column(
                              children: [
                                _buildInfoRow(
                                  label: 'Database File Size',
                                  value: info?.fileSizeFormatted ?? '0 B',
                                  icon: Icons.storage_rounded,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  label: 'Total Hostel Records',
                                  value: '${info?.totalRecords ?? 0} records',
                                  icon: Icons.analytics_rounded,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow(
                                  label: 'Database File Size',
                                  value: info?.fileSizeFormatted ?? '0 B',
                                  icon: Icons.storage_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoRow(
                                  label: 'Total Hostel Records',
                                  value: '${info?.totalRecords ?? 0} records',
                                  icon: Icons.analytics_rounded,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        label: 'Last Successful Backup',
                        value: lastBackupFormatted,
                        icon: Icons.history_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Change Data Location
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader('Change Data Location', Icons.drive_file_move_rounded),
                      const SizedBox(height: 10),
                      Text(
                        'You can choose any custom local drive or folder (e.g. D:\\Hostel Data\\) to store your active database. The system creates an automatic safety backup, copies the database files, verifies integrity, and seamlessly switches the application to the new location.',
                        style: AppStyles.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      Obx(() => CustomButton(
                        text: 'Change Data Location',
                        icon: Icons.folder_open_rounded,
                        type: ButtonType.secondary,
                        isLoading: controller.isMigratingLocation.value,
                        onPressed: () async {
                          final confirmed = await CustomDialog.showConfirm(
                            title: 'Change Database Storage Location?',
                            message: 'The system will safely move your active database to the folder you choose. An automated safety backup will be created before moving. Would you like to select a new folder now?',
                            confirmText: 'Select New Folder',
                          );
                          if (confirmed) {
                            controller.changeDataLocation();
                          }
                        },
                      )),
                    ],
                  ),
                ),
              ],
            );

            final rightCol = Column(
              children: [
                // Card: Backup & Restore Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader('Backup & Restore Actions', Icons.save_alt_rounded),
                      const SizedBox(height: 12),
                      Text(
                        'Save backups to an external USB drive, local disk, or cloud-synced folder (Google Drive / OneDrive) to move data to a new laptop or restore in emergencies.',
                        style: AppStyles.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      // Backup Button
                      Obx(() => CustomButton(
                        text: 'Backup Database',
                        icon: Icons.download_rounded,
                        width: double.infinity,
                        height: 46,
                        type: ButtonType.primary,
                        isLoading: controller.isBackingUp.value,
                        onPressed: controller.performBackup,
                      )),
                      const SizedBox(height: 14),

                      // Restore Button
                      Obx(() => CustomButton(
                        text: 'Restore Database',
                        icon: Icons.restore_page_rounded,
                        width: double.infinity,
                        height: 46,
                        type: ButtonType.danger,
                        isLoading: controller.isRestoring.value,
                        onPressed: () async {
                          final confirmed = await CustomDialog.showConfirm(
                            title: 'Restore Database from Backup?',
                            message: 'WARNING: Restoring will overwrite all current hostel records with the selected backup file. An automated safety backup of current data will be saved before restoring. Do you wish to proceed?',
                            confirmText: 'Yes, Select Backup File',
                          );
                          if (confirmed) {
                            controller.performRestore();
                          }
                        },
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Automated Safety Snapshots History
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader('Automated Safety Snapshots', Icons.shield_rounded),
                      const SizedBox(height: 8),
                      Text(
                        'Automatic safety snapshots created before migrations and restores:',
                        style: AppStyles.caption,
                      ),
                      const SizedBox(height: 14),
                      Obx(() {
                        final backups = controller.safetyBackups;
                        if (backups.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'No safety snapshots generated yet.',
                              style: AppStyles.caption,
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: backups.length > 5 ? 5 : backups.length,
                          separatorBuilder: (_, _) => const Divider(height: 12),
                          itemBuilder: (context, idx) {
                            final f = backups[idx];
                            final name = f.uri.pathSegments.last;
                            final modified = f.lastModifiedSync();
                            final size = (f.lengthSync() / 1024).toStringAsFixed(1);
                            return Row(
                              children: [
                                const Icon(Icons.backup_rounded, size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('${DateFormat('dd MMM, hh:mm a').format(modified)} • $size KB', style: AppStyles.caption),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Storage Optimization & Cache Cleanup
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader('Cache & Storage Optimization', Icons.cleaning_services_rounded),
                      const SizedBox(height: 10),
                      Text(
                        'Clear temporary application files, cached graphics/fonts, and compact the SQLite database file (VACUUM) to optimize performance and recover disk space.',
                        style: AppStyles.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      Obx(() => CustomButton(
                        text: 'Clear Cache & Optimize Storage',
                        icon: Icons.auto_fix_high_rounded,
                        width: double.infinity,
                        height: 46,
                        type: ButtonType.secondary,
                        isLoading: controller.isClearingCache.value,
                        onPressed: () async {
                          final confirmed = await CustomDialog.showConfirm(
                            title: 'Clean Temporary Cache & Compact?',
                            message: 'This will purge temporary files, reset in-memory caches, and defragment database storage to free disk space. Your hostel records will remain completely intact.',
                            confirmText: 'Clean Now',
                            confirmButtonType: ButtonType.primary,
                            icon: Icons.cleaning_services_rounded,
                          );
                          if (confirmed) {
                            controller.clearAppCache();
                          }
                        },
                      )),
                    ],
                  ),
                ),
              ],
            );

            if (isStacked) {
              return Column(
                children: [
                  leftCol,
                  const SizedBox(height: 20),
                  rightCol,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftCol),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: rightCol),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppStyles.caption),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildCardHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: AppStyles.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTeleItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _buildInfoRow(
      icon: icon,
      label: label,
      value: value,
    );
  }

  // ==========================================
  // TAB 3: ACCOUNT & SECURITY
  // ==========================================
  Widget _buildAccountSecurityTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final user = AuthService.to.currentUser.value;
          final isStacked = constraints.maxWidth < 950;
          final leftCol = Container(
            padding: const EdgeInsets.all(24),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader('Active User Profile', Icons.person_pin_rounded),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (user?.fullName.isNotEmpty ?? false)
                              ? user!.fullName[0].toUpperCase()
                              : (user?.username.isNotEmpty ?? false)
                                  ? user!.username[0].toUpperCase()
                                  : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? 'System User',
                        style: AppStyles.h3,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? "unknown"}',
                        style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusBadge(status: user?.role ?? 'Office Staff'),
                          const SizedBox(width: 8),
                          StatusBadge(status: (user?.isActive ?? 1) == 1 ? 'Active' : 'Inactive'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                _buildTeleItem(
                  icon: Icons.badge_rounded,
                  label: 'User Account ID',
                  value: '#${user?.id ?? "N/A"}',
                ),
                const SizedBox(height: 14),
                _buildTeleItem(
                  icon: Icons.shield_rounded,
                  label: 'Permission Level',
                  value: (user?.isAdmin ?? false) ? 'Administrator (Full Access)' : 'Staff (Restricted Access)',
                ),
                const SizedBox(height: 14),
                _buildTeleItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Account Created',
                  value: user != null ? DateFormat('MMM dd, yyyy').format(DateTime.tryParse(user.createdAt) ?? DateTime.now()) : 'N/A',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Passwords are encrypted with unique cryptographic salts and SHA-256 hashing. Once changed, all future logins require the new password.',
                          style: AppStyles.caption.copyWith(color: AppColors.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final rightCol = Container(
            padding: const EdgeInsets.all(24),
            decoration: AppStyles.cardDecoration,
            child: Form(
              key: controller.passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader('Change Account Password', Icons.lock_reset_rounded),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your current password to verify identity, then enter your new secure password.',
                    style: AppStyles.bodySmall,
                  ),
                  const Divider(height: 24),

                  // Current Password
                  CustomTextField(
                    label: 'Current Password *',
                    hint: 'Enter your existing password',
                    controller: controller.currentPasswordCtrl,
                    obscureText: !controller.isCurrentPasswordVisible.value,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isCurrentPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: controller.toggleCurrentPasswordVisibility,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Current password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // New Password
                  CustomTextField(
                    label: 'New Password *',
                    hint: 'Minimum 6 characters',
                    controller: controller.newPasswordCtrl,
                    obscureText: !controller.isNewPasswordVisible.value,
                    prefixIcon: Icons.vpn_key_outlined,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isNewPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: controller.toggleNewPasswordVisibility,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'New password is required';
                      if (v.trim().length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Confirm New Password
                  CustomTextField(
                    label: 'Confirm New Password *',
                    hint: 'Re-enter your new password',
                    controller: controller.confirmPasswordCtrl,
                    obscureText: !controller.isConfirmPasswordVisible.value,
                    prefixIcon: Icons.check_circle_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isConfirmPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please confirm your new password';
                      if (v.trim() != controller.newPasswordCtrl.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Action Button
                  CustomButton(
                    text: 'Update Password',
                    icon: Icons.check_circle_rounded,
                    width: 220,
                    height: 44,
                    isLoading: controller.isChangingPassword.value,
                    onPressed: controller.changePassword,
                  ),
                ],
              ),
            ),
          );

          if (isStacked) {
            return Column(
              children: [
                leftCol,
                const SizedBox(height: 20),
                rightCol,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: leftCol),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: rightCol),
            ],
          );
        });
      },
    );
  }
}
