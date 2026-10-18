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

            // Card 5: Audit Trail
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_edu_rounded, size: 18, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('AUDIT TRAIL & SYSTEM SECURITY LOGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Full activity audit trail documenting backups, location changes, database restores, and administrative operations.',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    const Divider(height: 20),

                    if (_logs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No audit logs recorded yet.')),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Timestamp')),
                              DataColumn(label: Text('Operator')),
                              DataColumn(label: Text('Action Type')),
                              DataColumn(label: Text('Module')),
                              DataColumn(label: Text('Record / Ref')),
                              DataColumn(label: Text('Action Narrative & Verification')),
                            ],
                            rows: _logs.take(15).map((log) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(AppFormatters.dateTime(log.timestamp), style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  DataCell(Text(log.module)),
                                  DataCell(Text(log.recordId.isNotEmpty ? log.recordId : '-')),
                                  DataCell(
                                    SizedBox(
                                      width: 320,
                                      child: Text(log.details, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
}
