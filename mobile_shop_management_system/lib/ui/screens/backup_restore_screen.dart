import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../core/providers/app_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/models/audit_log.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  DatabaseInfoModel? _dbInfo;
  List<File> _safetyBackups = [];
  List<AuditLog> _logs = [];
  bool _isLoading = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isMigrating = false;

  // Audit trail filtering & view controls
  String _auditSearchQuery = '';
  String _auditFilterModule = 'All';
  bool _showAllLogs = false;

  @override
  void initState() {
    super.initState();
    _loadBackupData();
  }

  Future<void> _loadBackupData() async {
    setState(() => _isLoading = true);
    try {
      final info = await DatabaseHelper.instance.getDatabaseInfo();
      final safetyList = await BackupService.getSafetyBackupsList();
      final logs = await DatabaseHelper.instance.getAllAuditLogs();
      if (mounted) {
        setState(() {
          _dbInfo = info;
          _safetyBackups = safetyList;
          _logs = logs;
        });
      }
    } catch (e) {
      debugPrint('Error loading backup data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadAllAppData() async {
    final app = context.read<AppProvider>();
    final inv = context.read<InventoryProvider>();
    final rep = context.read<RepairProvider>();
    final led = context.read<LedgerProvider>();

    await app.loadInitialData();
    await inv.loadInventory();
    await rep.loadRepairs();
    await led.loadAll();
    await _loadBackupData();
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final path = await BackupService.performBackup();
      if (path != null) {
        await _loadBackupData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.successGreen,
              content: Text('Database backup saved successfully to:\n$path'),
              action: SnackBarAction(
                label: 'Open Folder',
                textColor: Colors.white,
                onPressed: () => BackupService.openFolder(p.dirname(path)),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.dangerRed,
            content: Text('Backup Failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Restore Database from Backup?',
      message:
          'WARNING: Restoring will overwrite all current shop records with the selected backup file.\n\nAn automated safety backup of current data will be saved before restoring.\n\nDo you wish to proceed?',
      confirmLabel: 'Yes, Select Backup File',
      confirmColor: AppTheme.dangerRed,
    );

    if (confirmed && mounted) {
      setState(() => _isRestoring = true);
      try {
        final app = context.read<AppProvider>();
        final success = await BackupService.performRestore(currentUserName: app.currentUser.name);
        if (success) {
          await _reloadAllAppData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.successGreen,
                content: Text('Database restored successfully! All records have been reloaded.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.dangerRed,
              content: Text('Restore Failed: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isRestoring = false);
        }
      }
    }
  }

  Future<void> _handleRestoreFromFile(File file) async {
    final fileName = p.basename(file.path);
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Restore from Safety Snapshot?',
      message:
          'Restoring snapshot "$fileName" will replace all current shop records with the data inside this snapshot.\n\nAn automated safety backup of current data will be created before restoring.\n\nAre you sure you want to proceed?',
      confirmLabel: 'Yes, Restore Snapshot',
      confirmColor: AppTheme.dangerRed,
    );

    if (confirmed && mounted) {
      setState(() => _isRestoring = true);
      try {
        final app = context.read<AppProvider>();
        final success = await DatabaseHelper.instance.restoreDatabase(file.path, restoredBy: app.currentUser.name);
        if (success) {
          await _reloadAllAppData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.successGreen,
                content: Text('Database successfully restored from $fileName! All records reloaded.'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.dangerRed,
              content: Text('Restore Failed: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isRestoring = false);
        }
      }
    }
  }

  Future<void> _handleChangeDataLocation() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Change Database Storage Location?',
      message:
          'The system will safely move your active database to the folder you choose.\n\nAn automated safety backup will be created before moving. Would you like to select a new folder now?',
      confirmLabel: 'Select New Folder',
      confirmColor: AppTheme.primaryBlue,
    );

    if (confirmed && mounted) {
      setState(() => _isMigrating = true);
      try {
        final newPath = await BackupService.changeDataLocation();
        if (newPath != null) {
          await _reloadAllAppData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.successGreen,
                content: Text('Database storage location successfully moved to:\n$newPath'),
                action: SnackBarAction(
                  label: 'Open Folder',
                  textColor: Colors.white,
                  onPressed: () => BackupService.openFolder(newPath),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.dangerRed,
              content: Text('Location Change Failed: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isMigrating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lastBackupFormatted = _dbInfo?.lastBackupAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(_dbInfo!.lastBackupAt!) ?? DateTime.now())
        : 'No backup recorded yet';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Storage, Backup & Restore Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Choose custom backup folders, select backup destination, restore verified databases, and track audit history',
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: _isBackingUp
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Backup Database (Choose Folder)'),
                      onPressed: _isBackingUp ? null : _handleBackup,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: _isRestoring
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.restore_page_rounded, size: 16),
                      label: const Text('Restore Database from File'),
                      onPressed: _isRestoring ? null : _handleRestore,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informational Banner Card (Separated Data Storage & Desktop Protection)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_rounded, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Separated Data Storage & Desktop Protection',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your mobile shop records, IMEI inventories, repair jobs, and accounting ledgers are stored locally on this computer, completely independent of the application installation directory. Reinstalling or updating the app will not touch your records. You can select any custom local drive (D:\\, USB Drive, Google Drive) to save your backups and easily move data to another laptop.',
                          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Two-Column Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 980;

                final leftCol = Column(
                  children: [
                    // Card 1: Database Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.dns_rounded, size: 18, color: AppTheme.primaryBlue),
                                    SizedBox(width: 8),
                                    Text('DATABASE INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, size: 8, color: isDark ? const Color(0xFF34D399) : AppTheme.successGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Connected',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Location row with Explorer button
                            _buildInfoTile(
                              label: 'Current Database Location',
                              value: _dbInfo?.path ?? 'Loading...',
                              icon: Icons.folder_rounded,
                              isDark: isDark,
                              trailing: IconButton(
                                icon: const Icon(Icons.folder_open_rounded, size: 20, color: AppTheme.primaryBlue),
                                tooltip: 'Open folder in File Explorer',
                                onPressed: () {
                                  if (_dbInfo != null) {
                                    BackupService.openFolder(_dbInfo!.directory);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Size & Last Modified
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoTile(
                                    label: 'Database File Size',
                                    value: _dbInfo?.formattedSize ?? 'Loading...',
                                    icon: Icons.data_usage_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInfoTile(
                                    label: 'Last Modified',
                                    value: _dbInfo?.lastModified != null ? AppFormatters.dateTime(_dbInfo!.lastModified!) : '-',
                                    icon: Icons.access_time_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Record Counts Metrics Grid
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCounter('Products', _dbInfo?.totalProducts ?? 0, AppTheme.primaryBlue),
                                  _buildCounter('Sales', _dbInfo?.totalSales ?? 0, AppTheme.successGreen),
                                  _buildCounter('Repairs', _dbInfo?.totalRepairs ?? 0, AppTheme.purpleRepair),
                                  _buildCounter('Customers', _dbInfo?.totalCustomers ?? 0, AppTheme.warningOrange),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Last Backup Time
                            _buildInfoTile(
                              label: 'Last Successful Backup',
                              value: lastBackupFormatted,
                              subtitle: _dbInfo?.lastBackupPath,
                              icon: Icons.history_rounded,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 2: Change Data Storage Location
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.drive_file_move_rounded, size: 18, color: AppTheme.purpleRepair),
                                SizedBox(width: 8),
                                Text('CHANGE ACTIVE DATA STORAGE LOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.purpleRepair)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'You can choose any custom local drive or folder (e.g. D:\\Mobile Shop Data\\) to store your active database. The system creates an automatic safety backup, copies the database files, verifies integrity, and seamlessly switches the application to the new location.',
                              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: _isMigrating
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.folder_open_rounded, size: 16),
                              label: const Text('Change Database Location'),
                              onPressed: _isMigrating ? null : _handleChangeDataLocation,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                final rightCol = Column(
                  children: [
                    // Card 3: Backup & Restore Actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.save_alt_rounded, size: 18, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('BACKUP & RESTORE ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Save backups to an external USB drive, local disk, or cloud-synced folder (Google Drive / OneDrive) to move data to a new laptop or restore in emergencies.',
                              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),

                            // Primary Backup Button
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                ),
                                icon: _isBackingUp
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Backup Database (Choose Save Folder)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                onPressed: _isBackingUp ? null : _handleBackup,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Restore Button
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.warningOrange,
                                ),
                                icon: _isRestoring
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.restore_page_rounded, size: 18),
                                label: const Text('Restore Database from Backup (.db / .json)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                onPressed: _isRestoring ? null : _handleRestore,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 4: Automated Safety Snapshots History
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shield_rounded, size: 18, color: AppTheme.successGreen),
                                    SizedBox(width: 8),
                                    Text('AUTOMATED SAFETY SNAPSHOTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successGreen)),
                                  ],
                                ),
                                IconButton(
                                  tooltip: 'Refresh Snapshots',
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  onPressed: _loadBackupData,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Automatic safety snapshots created before migrations, restores, and manual backups:',
                              style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),

                            if (_isLoading)
                              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                            else if (_safetyBackups.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('No safety snapshots recorded yet. Create a backup to get started.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _safetyBackups.length > 5 ? 5 : _safetyBackups.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final file = _safetyBackups[idx];
                                  final fileName = p.basename(file.path);
                                  final stat = file.statSync();
                                  final sizeKb = (stat.size / 1024).toStringAsFixed(1);

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                      child: Icon(Icons.backup_rounded, size: 16, color: isDark ? const Color(0xFF6EE7B7) : AppTheme.successGreen),
                                    ),
                                    title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                                    subtitle: Text('${DateFormat('dd MMM yyyy, hh:mm a').format(stat.modified)} • $sizeKb KB', style: const TextStyle(fontSize: 11)),
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.warningOrange,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _handleRestoreFromFile(file),
                                      child: const Text('Restore'),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                if (isStacked) {
                  return Column(children: [leftCol, const SizedBox(height: 16), rightCol]);
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: leftCol),
                      const SizedBox(width: 16),
                      Expanded(child: rightCol),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // Card 5: Audit Trail & System Security Logs
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 20, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'AUDIT TRAIL & SYSTEM SECURITY LOGS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryBlue),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            '${_logs.length} Total Logs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Full activity audit trail documenting backups, location changes, database restores, and administrative operations.',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),

                    // Search & Filter Bar
                    if (_logs.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search audit logs (by operator, action, ref, or text)...',
                                  hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : Colors.grey),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                                style: const TextStyle(fontSize: 12.5),
                                onChanged: (val) => setState(() => _auditSearchQuery = val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_logs.length > 10)
                            TextButton.icon(
                              onPressed: () => setState(() => _showAllLogs = !_showAllLogs),
                              icon: Icon(_showAllLogs ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 16),
                              label: Text(
                                _showAllLogs ? 'Show Recent (10)' : 'Show All (${_logs.length})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Module Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                'Filter by Module:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            ...{'All', ..._logs.map((l) => l.module).where((m) => m.isNotEmpty)}.map((mod) {
                              final isSelected = _auditFilterModule == mod;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text(mod, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  onSelected: (_) => setState(() => _auditFilterModule = mod),
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                    ],

                    // Filter logic & DataTable
                    Builder(
                      builder: (context) {
                        if (_logs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No audit logs recorded yet.')),
                          );
                        }

                        final query = _auditSearchQuery.trim().toLowerCase();
                        final filtered = _logs.where((l) {
                          final matchesModule = _auditFilterModule == 'All' || l.module == _auditFilterModule;
                          if (!matchesModule) return false;
                          if (query.isEmpty) return true;
                          return l.userName.toLowerCase().contains(query) ||
                              l.action.toLowerCase().contains(query) ||
                              l.module.toLowerCase().contains(query) ||
                              l.recordId.toLowerCase().contains(query) ||
                              l.details.toLowerCase().contains(query);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No matching audit logs found for "$_auditSearchQuery".',
                                style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          );
                        }

                        final displayLogs = _showAllLogs ? filtered : filtered.take(10).toList();

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                  letterSpacing: 0.3,
                                ),
                                dataRowColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
                                  }
                                  return isDark ? const Color(0xFF0F172A).withValues(alpha: 0.3) : Colors.white;
                                }),
                                dividerThickness: 1,
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 64,
                                columnSpacing: 20,
                                horizontalMargin: 16,
                                columns: const [
                                  DataColumn(label: Text('Timestamp')),
                                  DataColumn(label: Text('Operator')),
                                  DataColumn(label: Text('Action Type')),
                                  DataColumn(label: Text('Module')),
                                  DataColumn(label: Text('Record / Ref')),
                                  DataColumn(label: Text('Action Narrative & Verification')),
                                  DataColumn(label: Text('Details')),
                                ],
                                rows: displayLogs.map((log) {
                                  return DataRow(
                                    cells: [
                                      // Timestamp
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              DateFormat('dd MMM yyyy').format(log.timestamp),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('hh:mm a').format(log.timestamp),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () => _showLogDetailsDialog(context, log, isDark),
                                      ),
                                      // Operator
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                              child: Text(
                                                log.userName.isNotEmpty ? log.userName[0].toUpperCase() : 'U',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? const Color(0xFF93C5FD) : AppTheme.primaryBlue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              log.userName.isNotEmpty ? log.userName : 'System',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.5,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () => _showLogDetailsDialog(context, log, isDark),
                                      ),
                                      // Action Type
                                      DataCell(
                                        _buildActionBadge(log.action, isDark),
                                        onTap: () => _showLogDetailsDialog(context, log, isDark),
                                      ),
                                      // Module
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Text(
                                            log.module,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        onTap: () => _showLogDetailsDialog(context, log, isDark),
                                      ),
                                      // Record / Ref
                                      DataCell(
                                        log.recordId.isEmpty || log.recordId == '-'
                                            ? Text('-', style: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey))
                                            : Tooltip(
                                                message: log.recordId,
                                                child: Container(
                                                  constraints: const BoxConstraints(maxWidth: 190),
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    log.recordId,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: 'monospace',
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                        onTap: () => _showLogDetailsDialog(context, log, isDark),
                                      ),
                                      // Action Narrative & Verification
                                      DataCell(
                                        Tooltip(
                                          message: log.details,
                                          child: SizedBox(
                                            width: 420,
                                            child: Text(
                                              log.details,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        onTap: () => _showLogDetailsDialog(context, log, isDark),
                                      ),
                                      // Details Button
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new_rounded, size: 17),
                                          color: isDark ? const Color(0xFF93C5FD) : AppTheme.primaryBlue,
                                          tooltip: 'View Full Audit Record',
                                          onPressed: () => _showLogDetailsDialog(context, log, isDark),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionBadge(String action, bool isDark) {
    final upper = action.toUpperCase();
    Color bg;
    Color text;
    Color border;
    IconData icon;

    if (upper.contains('RESTORE') || upper.contains('REVERT')) {
      bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.45) : const Color(0xFFFEF3C7);
      text = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
      border = isDark ? const Color(0xFFB45309) : const Color(0xFFFCD34D);
      icon = Icons.settings_backup_restore_rounded;
    } else if (upper.contains('BACKUP') || upper.contains('SAFETY')) {
      bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.45) : const Color(0xFFDCFCE7);
      text = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534);
      border = isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC);
      icon = Icons.verified_user_rounded;
    } else if (upper.contains('LOCATION') || upper.contains('MIGRATE') || upper.contains('MOVE')) {
      bg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.45) : const Color(0xFFDBEAFE);
      text = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
      border = isDark ? const Color(0xFF2563EB) : const Color(0xFF93C5FD);
      icon = Icons.drive_file_move_rounded;
    } else if (upper.contains('CREATE') || upper.contains('ADD') || upper.contains('INSERT') || upper.contains('SALE')) {
      bg = isDark ? const Color(0xFF042F2E).withValues(alpha: 0.45) : const Color(0xFFCCFBF1);
      text = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF115E59);
      border = isDark ? const Color(0xFF0D9488) : const Color(0xFF99F6E4);
      icon = Icons.add_circle_outline_rounded;
    } else if (upper.contains('UPDATE') || upper.contains('EDIT') || upper.contains('REPAIR')) {
      bg = isDark ? const Color(0xFF3B0764).withValues(alpha: 0.45) : const Color(0xFFF3E8FF);
      text = isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8);
      border = isDark ? const Color(0xFF9333EA) : const Color(0xFFD8B4FE);
      icon = Icons.edit_note_rounded;
    } else if (upper.contains('DELETE') || upper.contains('REMOVE') || upper.contains('DROP')) {
      bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.45) : const Color(0xFFFEE2E2);
      text = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
      border = isDark ? const Color(0xFFDC2626) : const Color(0xFFFCA5A5);
      icon = Icons.delete_outline_rounded;
    } else {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      text = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
      border = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
      icon = Icons.info_outline_rounded;
    }

    final displayAction = action.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 5),
          Text(
            displayAction,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDetailsDialog(BuildContext context, AuditLog log, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Audit Log Record Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogRow('Timestamp', DateFormat('dd MMMM yyyy, hh:mm:ss a').format(log.timestamp), isDark),
                _buildDialogRow('Operator / User', log.userName.isNotEmpty ? log.userName : 'System', isDark),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          'Action Type:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      _buildActionBadge(log.action, isDark),
                    ],
                  ),
                ),
                _buildDialogRow('Module', log.module, isDark),
                if (log.recordId.isNotEmpty)
                  _buildDialogRow('Record / Ref', log.recordId, isDark),
                const Divider(height: 24),
                Text(
                  'Action Narrative & Verification:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: SelectableText(
                    log.details,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      fontFamily: 'monospace',
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Timestamp: ${log.timestamp}\nOperator: ${log.userName}\nAction: ${log.action}\nModule: ${log.module}\nRecord: ${log.recordId}\nDetails: ${log.details}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Log narrative copied to clipboard!'), duration: Duration(seconds: 2)),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
