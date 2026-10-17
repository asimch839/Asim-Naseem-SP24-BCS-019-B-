import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_image.dart';
import '../../data/models/business_model.dart';
import '../../data/database/app_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Business Information Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsAppController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _currencyController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _jobPrefixController;
  late final TextEditingController _invoicePrefixController;
  late final TextEditingController _lowStockThresholdController;

  String? _logoUrl;
  bool _isUploadingLogo = false;
  bool _isSaving = false;
  bool _isSavingPermissions = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  // Manager configurable permissions state
  bool _canManageStaff = true;
  bool _canAccessSalaries = false;
  bool _canAccessFinancials = true;
  bool _canManageInventory = true;

  // Inspection Checklist Items & Sections
  late List<String> _inspectionSections;
  late List<String> _checklistItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    final b = AuthService.to.currentBusiness.value;
    final u = AuthService.to.currentUser.value;

    _canManageStaff = u?.canManageStaffPermission ?? true;
    _canAccessSalaries = u?.canAccessSalariesPermission ?? false;
    _canAccessFinancials = u?.canAccessFinancialsPermission ?? true;
    _canManageInventory = u?.canManageInventoryPermission ?? true;

    _nameController = TextEditingController(text: b?.name ?? 'Apex Car Detailing & Studio');
    _phoneController = TextEditingController(text: b?.phone ?? '+92 300 1234567');
    _whatsAppController = TextEditingController(text: b?.whatsapp ?? '');
    _emailController = TextEditingController(text: b?.email ?? 'admin@autodetail.com');
    _addressController = TextEditingController(text: b?.address ?? 'Plot 42, Auto Sector, Main Boulevard');
    _currencyController = TextEditingController(text: b?.currency ?? 'Rs.');
    _timezoneController = TextEditingController(text: b?.timezone ?? 'Asia/Karachi (PKT +05:00)');
    _taxRateController = TextEditingController(text: b?.taxRate.toString() ?? '0.0');
    _jobPrefixController = TextEditingController(text: b?.jobPrefix ?? 'JOB-');
    _invoicePrefixController = TextEditingController(text: b?.invoicePrefix ?? 'INV-');
    _lowStockThresholdController = TextEditingController(text: b?.globalLowStockThreshold.toStringAsFixed(0) ?? '5');
    _logoUrl = b?.logoUrl;

    _inspectionSections = List.from(b?.inspectionSections ?? [
      'Exterior',
      'Interior',
      'Tires',
      'Engine',
      'Wind Screen / Glass',
      'Body',
      'Paint',
      'Suspension',
      'Electronics',
      'Body Parts',
      'Drive',
    ]);

    _checklistItems = List.from(b?.checklistItems ?? [
      'Spare Wheel & Jack',
      'Toolkit & Rod',
      'Floor Mats (Front & Rear)',
      'Audio / Media Player & Remote',
      'Perfume / Freshener',
      'Original Documents / Tax Token',
      'Cigarette Lighter',
      'Personal Valuables & Belongings',
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _currencyController.dispose();
    _timezoneController.dispose();
    _taxRateController.dispose();
    _jobPrefixController.dispose();
    _invoicePrefixController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingLogo = true);
    try {
      final businessId = AuthService.to.businessId;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final url = await StorageService.uploadFile(
        bytes: bytes,
        path: 'businesses/$businessId/logos/logo_${const Uuid().v4()}.$ext',
      );
      setState(() => _logoUrl = url);
      Get.snackbar('Uploaded', 'Business logo saved locally to media folder');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload logo: $e');
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  void _saveAllSettings() async {
    setState(() => _isSaving = true);
    try {
      final currentBiz = AuthService.to.currentBusiness.value;
      final bizId = AuthService.to.businessId;
      final ownerId = AuthService.to.currentUser.value?.uid ?? 'owner';

      final updated = (currentBiz != null)
          ? currentBiz.copyWith(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              whatsapp: _whatsAppController.text.trim().isNotEmpty ? _whatsAppController.text.trim() : null,
              email: _emailController.text.trim(),
              address: _addressController.text.trim(),
              logoUrl: _logoUrl,
              currency: _currencyController.text.trim(),
              timezone: _timezoneController.text.trim().isNotEmpty ? _timezoneController.text.trim() : 'Asia/Karachi (PKT +05:00)',
              taxRate: double.tryParse(_taxRateController.text.trim()) ?? 0.0,
              jobPrefix: _jobPrefixController.text.trim(),
              invoicePrefix: _invoicePrefixController.text.trim(),
              globalLowStockThreshold: double.tryParse(_lowStockThresholdController.text.trim()) ?? 5.0,
              inspectionSections: _inspectionSections,
              checklistItems: _checklistItems,
            )
          : BusinessModel(
              id: bizId,
              name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Apex Car Detailing & Studio',
              ownerId: ownerId,
              phone: _phoneController.text.trim(),
              whatsapp: _whatsAppController.text.trim().isNotEmpty ? _whatsAppController.text.trim() : null,
              email: _emailController.text.trim(),
              address: _addressController.text.trim(),
              logoUrl: _logoUrl,
              currency: _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim() : 'Rs.',
              timezone: _timezoneController.text.trim().isNotEmpty ? _timezoneController.text.trim() : 'Asia/Karachi (PKT +05:00)',
              taxRate: double.tryParse(_taxRateController.text.trim()) ?? 0.0,
              jobPrefix: _jobPrefixController.text.trim().isNotEmpty ? _jobPrefixController.text.trim() : 'JOB-',
              invoicePrefix: _invoicePrefixController.text.trim().isNotEmpty ? _invoicePrefixController.text.trim() : 'INV-',
              globalLowStockThreshold: double.tryParse(_lowStockThresholdController.text.trim()) ?? 5.0,
              inspectionSections: _inspectionSections,
              checklistItems: _checklistItems,
            );

      await SettingsRepository().saveSettings({
        'business_name': updated.name,
        'phone': updated.phone,
        'whatsapp': updated.whatsapp ?? '',
        'email': updated.email,
        'address': updated.address,
        'logo_url': updated.logoUrl ?? '',
        'currency': updated.currency,
        'timezone': updated.timezone,
        'tax_rate': updated.taxRate.toString(),
        'job_prefix': updated.jobPrefix,
        'invoice_prefix': updated.invoicePrefix,
        'low_stock_threshold': updated.globalLowStockThreshold.toString(),
      });
      AuthService.to.updateCurrentBusiness(updated);
      Get.snackbar(
        'Settings Saved',
        'Business configuration updated successfully in SQLite database',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save settings: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _savePermissions() async {
    setState(() => _isSavingPermissions = true);
    try {
      final user = AuthService.to.currentUser.value;
      if (user != null) {
        final updated = user.copyWith(
          canManageStaffPermission: _canManageStaff,
          canAccessSalariesPermission: _canAccessSalaries,
          canAccessFinancialsPermission: _canAccessFinancials,
          canManageInventoryPermission: _canManageInventory,
        );
        final db = await AppDatabase.instance.database;
        await db.update(
          'users',
          {
            'can_manage_staff': _canManageStaff ? 1 : 0,
            'can_access_salaries': _canAccessSalaries ? 1 : 0,
            'can_access_financials': _canAccessFinancials ? 1 : 0,
            'can_manage_inventory': _canManageInventory ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [user.uid],
        );
        AuthService.to.updateCurrentUser(updated);
      }
      Get.snackbar(
        'Permissions Updated',
        'Manager permissions have been saved and applied',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save permissions: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
      );
    } finally {
      if (mounted) setState(() => _isSavingPermissions = false);
    }
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isBackingUp = true);
    try {
      String? targetDir;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        targetDir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Destination Folder for Backup Archive',
        );
        if (targetDir == null) return;
      } else {
        final docs = await getApplicationDocumentsDirectory();
        targetDir = docs.path;
      }

      final backupPath = await LocalStorageService.to.createCompleteBackup(targetDir);
      if (backupPath != null) {
        final backupFile = File(backupPath);
        final sizeBytes = await backupFile.length();
        final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);

        Get.defaultDialog(
          title: 'Complete Backup Created',
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A complete offline backup bundle was generated. All SQLite tables and local photographs are safely preserved.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text('File: ${backupFile.uri.pathSegments.last}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Location: $backupPath', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                const SizedBox(height: 4),
                Text('Size: $sizeKb KB', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          textConfirm: 'Done',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
        );
      }
    } catch (e) {
      Get.snackbar('Backup Failed', e.toString(), backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestoreBackup() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select Backup Archive (.ZIP) to Restore',
      );
      if (res == null || res.files.single.path == null) return;

      final zipPath = res.files.single.path!;
      final zipFile = File(zipPath);
      final sizeBytes = await zipFile.length();
      final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);

      Get.defaultDialog(
        title: 'Confirm System Restore',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: Restoring will completely replace your existing local SQLite database and media files with the archive snapshot.',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text('Archive: ${res.files.single.name} ($sizeKb KB)', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text('Are you sure you want to proceed with this restore operation?', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        textConfirm: 'Restore & Overwrite',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.error,
        textCancel: 'Cancel',
        onConfirm: () async {
          Get.back();
          setState(() => _isRestoring = true);
          try {
            final success = await LocalStorageService.to.restoreCompleteBackup(zipPath);
            if (success) {
              final db = await AppDatabase.instance.database;
              final settings = await db.query('settings');
              final Map<String, String> map = {};
              for (final s in settings) {
                map[s['key'] as String] = s['value'] as String;
              }
              final biz = BusinessModel(
                id: 'default_business',
                name: map['business_name'] ?? 'Apex Car Detailing & Studio',
                ownerId: 'admin',
                phone: map['phone'] ?? '+92 300 1234567',
                whatsapp: map['whatsapp'],
                email: map['email'] ?? 'admin@autodetail.com',
                address: map['address'] ?? 'Plot 42, Auto Sector, Main Boulevard',
                currency: map['currency'] ?? 'Rs.',
                timezone: map['timezone'] ?? 'Asia/Karachi (PKT +05:00)',
                taxRate: double.tryParse(map['tax_rate'] ?? '0') ?? 0.0,
                jobPrefix: map['job_prefix'] ?? 'JOB-',
                invoicePrefix: map['invoice_prefix'] ?? 'INV-',
                globalLowStockThreshold: double.tryParse(map['low_stock_threshold'] ?? '5') ?? 5.0,
              );
              AuthService.to.updateCurrentBusiness(biz);

              Get.snackbar(
                'Restore Complete',
                'System database and media restored successfully! Database reloaded.',
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
                duration: const Duration(seconds: 4),
              );
            }
          } catch (e) {
            Get.snackbar('Restore Failed', e.toString(), backgroundColor: AppColors.error.withValues(alpha: 0.2));
          } finally {
            if (mounted) setState(() => _isRestoring = false);
          }
        },
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> _exportTableToCsv(String tableName) async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(tableName);
      if (rows.isEmpty) {
        Get.snackbar('Export', 'Table $tableName has no records to export.');
        return;
      }

      final headers = rows.first.keys.toList();
      final List<List<dynamic>> csvData = [
        headers,
        ...rows.map((r) => headers.map((h) => r[h]?.toString() ?? '').toList()),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);

      String? targetDir;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        targetDir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder for CSV Export');
        if (targetDir == null) return;
      } else {
        final docs = await getApplicationDocumentsDirectory();
        targetDir = docs.path;
      }

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '$targetDir/${tableName}_export_$dateStr.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      Get.snackbar('Export Succeeded', 'Saved to $filePath', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Export Failed', e.toString(), backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.settings,
      title: 'System Settings',
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: AppColors.textDarkSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.business_rounded), text: 'Business Information'),
                Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Users & Permissions'),
                Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Inventory Settings'),
                Tab(icon: Icon(Icons.fact_check_rounded), text: 'Inspection Settings'),
                Tab(icon: Icon(Icons.palette_rounded), text: 'Appearance'),
                Tab(icon: Icon(Icons.backup_rounded), text: 'Backup & Restore'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBusinessInfoTab(),
                _buildUsersTab(),
                _buildInventoryTab(),
                _buildInspectionSettingsTab(),
                _buildAppearanceTab(),
                _buildBackupRestoreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. BUSINESS INFORMATION TAB
  Widget _buildBusinessInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo uploader
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: AppImage(
                            imagePath: _logoUrl,
                            placeholder: Container(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              child: const Icon(Icons.business_rounded, size: 36, color: AppColors.primaryLight),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Business Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('Upload PNG or JPG logo to appear on job cards and tax invoices.', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _isUploadingLogo ? null : _pickLogo,
                              icon: _isUploadingLogo
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.upload_file_rounded, size: 16),
                              label: const Text('Change Logo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Form fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Business Name *', prefixIcon: Icon(Icons.store_rounded, size: 20)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_rounded, size: 20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _whatsAppController,
                              decoration: const InputDecoration(labelText: 'WhatsApp Number', prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 20)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Business Email *', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Physical Studio Address *', prefixIcon: Icon(Icons.location_on_outlined, size: 20)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currencyController,
                              decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. Rs., \$, AED)'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _taxRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _timezoneController,
                        decoration: const InputDecoration(
                          labelText: 'Business Timezone (e.g. Asia/Karachi PKT +05:00)',
                          prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _jobPrefixController,
                              decoration: const InputDecoration(labelText: 'Job Card Prefix (e.g. JOB-)'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _invoicePrefixController,
                              decoration: const InputDecoration(labelText: 'Invoice Prefix (e.g. INV-)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Business Settings'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. USERS & PERMISSIONS TAB (Strictly Admin and Manager per Section 5)
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security_rounded, color: AppColors.primaryLight),
                          SizedBox(width: 8),
                          Text('System User Roles & Access Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The system strictly enforces two user roles: Admin (full access) and Manager (configurable operations). Staff members are business records, NOT login roles.',
                        style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryLight),
                        ),
                        title: const Text('Administrator Role', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Full, unrestricted access to all modules, financial ledgers, salaries, and configurations.'),
                        trailing: const Chip(label: Text('Full Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ),
                      const Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          child: const Icon(Icons.person_rounded, color: AppColors.accent),
                        ),
                        title: const Text('Manager Role', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Access to standard garage operations (customers, vehicles, inspections, job cards, invoices).'),
                      ),
                      const SizedBox(height: 12),
                      const Text('Manager Configurable Permissions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Can View & Manage Staff Records', style: TextStyle(fontSize: 13)),
                        value: _canManageStaff,
                        onChanged: (v) => setState(() => _canManageStaff = v ?? true),
                      ),
                      CheckboxListTile(
                        title: const Text('Can Access Salary Ledgers & Payouts', style: TextStyle(fontSize: 13)),
                        value: _canAccessSalaries,
                        onChanged: (v) => setState(() => _canAccessSalaries = v ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Can Access Financial Revenue & Expense Reports', style: TextStyle(fontSize: 13)),
                        value: _canAccessFinancials,
                        onChanged: (v) => setState(() => _canAccessFinancials = v ?? true),
                      ),
                      CheckboxListTile(
                        title: const Text('Can Adjust Inventory Quantities (+ / -)', style: TextStyle(fontSize: 13)),
                        value: _canManageInventory,
                        onChanged: (v) => setState(() => _canManageInventory = v ?? true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSavingPermissions ? null : _savePermissions,
                icon: _isSavingPermissions
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shield_rounded),
                label: Text(_isSavingPermissions ? 'Saving Permissions...' : 'Save Manager Permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. INVENTORY SETTINGS TAB (Global Low Stock Threshold per Section 47)
  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_rounded, color: AppColors.primaryLight),
                          SizedBox(width: 8),
                          Text('Global Inventory Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Per business rules, individual items do NOT have minimum stock fields. Instead, low-stock detection across the dashboard and inventory is driven by this global threshold.',
                        style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lowStockThresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Global Low Stock Threshold (Quantity Units) *',
                          hintText: 'e.g. 5',
                          prefixIcon: Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Items with current quantity less than or equal to this threshold will be flagged as Low Stock on the dashboard.',
                        style: TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Inventory Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. INSPECTION SETTINGS TAB (Section 16 & 33)
  Widget _buildInspectionSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inspection Sections Manager
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Inspection Sections (Editable)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          TextButton.icon(
                            onPressed: () {
                              final ctrl = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Add Section'),
                                  content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Section Name')),
                                  actions: [
                                    TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (ctrl.text.trim().isNotEmpty) {
                                          setState(() => _inspectionSections.add(ctrl.text.trim()));
                                          Get.back();
                                        }
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add Section'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _inspectionSections.map((s) {
                          return Chip(
                            label: Text(s),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _inspectionSections.remove(s)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Checklist Items Manager
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Belongings & Inventory Checklist Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          TextButton.icon(
                            onPressed: () {
                              final ctrl = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Add Checklist Item'),
                                  content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Item Name')),
                                  actions: [
                                    TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (ctrl.text.trim().isNotEmpty) {
                                          setState(() => _checklistItems.add(ctrl.text.trim()));
                                          Get.back();
                                        }
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _checklistItems.map((c) {
                          return Chip(
                            label: Text(c),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _checklistItems.remove(c)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Inspection Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. APPEARANCE TAB
  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded, color: AppColors.primaryLight),
                      SizedBox(width: 8),
                      Text('Appearance & Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Dark Mode (Recommended for Studios)'),
                    subtitle: const Text('High-contrast sleek automotive dark theme'),
                    leading: const Icon(Icons.dark_mode_rounded),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                    onTap: () => Get.changeThemeMode(ThemeMode.dark),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Light Mode'),
                    subtitle: const Text('Classic high-brightness light theme'),
                    leading: const Icon(Icons.light_mode_rounded),
                    onTap: () => Get.changeThemeMode(ThemeMode.light),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('System Mode'),
                    subtitle: const Text('Follow operating system theme preferences'),
                    leading: const Icon(Icons.settings_brightness_rounded),
                    onTap: () => Get.changeThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 6. BACKUP & RESTORE TAB
  Widget _buildBackupRestoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.security_rounded, color: AppColors.primaryLight, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline-First Local Data Storage & Backup',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'This management system operates 100% offline using high-performance local SQLite storage. All customer accounts, vehicle service logs, high-resolution inspection photos, job cards, inventory transactions, and financial entries reside safely on this machine. Create regular zip backups to external storage or cloud sync folders to prevent data loss.',
                              style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Full Backup Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.archive_rounded, color: AppColors.success),
                          SizedBox(width: 10),
                          Text('Create Complete Offline Backup (.ZIP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Generates an uncorrupted compressed archive containing your SQLite database (customers, vehicles, job cards, invoices, expenses, inventory, staff, attendance, salaries) along with the complete folder of inspection photos, signatures, and receipts.',
                        style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: _isBackingUp ? null : _handleCreateBackup,
                        icon: _isBackingUp
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download_rounded),
                        label: Text(_isBackingUp ? 'Generating Backup Archive...' : 'Choose Destination & Backup Now (.ZIP)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Restore Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.unarchive_rounded, color: AppColors.warning),
                          SizedBox(width: 10),
                          Text('Restore Database & Media Archive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Caution: Restoring an archive replaces all current SQLite records and inspection photos with the backup state. Always create a backup of current data before restoring.',
                                style: TextStyle(fontSize: 12, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isRestoring ? null : _handleRestoreBackup,
                        icon: _isRestoring
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(_isRestoring ? 'Restoring System...' : 'Select Backup Archive (.ZIP) to Restore'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CSV Spreadsheets Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.table_chart_rounded, color: AppColors.info),
                          SizedBox(width: 10),
                          Text('CSV Spreadsheets Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Export raw data tables directly to CSV for Microsoft Excel, Google Sheets, or external accounting software:',
                        style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildCsvButton('Customers', 'customers', Icons.people_outline_rounded),
                          _buildCsvButton('Vehicles', 'vehicles', Icons.directions_car_outlined),
                          _buildCsvButton('Invoices', 'invoices', Icons.receipt_long_outlined),
                          _buildCsvButton('Payments', 'payments', Icons.payments_outlined),
                          _buildCsvButton('Inventory Items', 'inventory_items', Icons.inventory_2_outlined),
                          _buildCsvButton('Garage Expenses', 'garage_expenses', Icons.account_balance_wallet_outlined),
                          _buildCsvButton('Staff List', 'staff', Icons.badge_outlined),
                          _buildCsvButton('Attendance', 'attendance', Icons.fact_check_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCsvButton(String label, String tableName, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryLight),
      label: Text(label),
      onPressed: () => _exportTableToCsv(tableName),
    );
  }
}
