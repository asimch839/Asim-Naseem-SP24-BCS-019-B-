import 'dart:io';
import 'package:flutter/material.dart';
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
  List<FileSystemEntity> _backups = [];
  List<AuditLog> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupData();
  }

  Future<void> _loadBackupData() async {
    setState(() => _isLoading = true);
    try {
      final list = await BackupService.listBackups();
      final logs = await DatabaseHelper.instance.getAllAuditLogs();
      setState(() {
        _backups = list;
        _logs = logs;
      });
    } catch (e) {
      debugPrint('Error loading backup list: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    const Text('Database Backup, Restore & Audit Trail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Automated safety snapshots, 1-click database export/import, and sensitive action audit trail', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.backup_rounded, size: 16),
                  label: const Text('Create Manual Backup Now'),
                  onPressed: () => _handleCreateBackup(context, app),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Backup Status Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppTheme.successGreen, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Zero Data Loss Architecture (Offline-First)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          'All sales, customers, repair jobs, and IMEIs are stored locally in an embedded SQLite database. Backups create a JSON snapshot that can be restored on any computer anytime.',
                          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Backups Available on Disk
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('LOCAL BACKUP SNAPSHOTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                        IconButton(
                          tooltip: 'Refresh Backups',
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          onPressed: _loadBackupData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_backups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No backup files found on disk yet. Click "Create Manual Backup Now" above.')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _backups.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final file = File(_backups[idx].path);
                          final stat = file.statSync();
                          final fileName = p.basename(file.path);
                          final sizeKb = (stat.size / 1024).toStringAsFixed(1);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2FE),
                              child: Icon(Icons.description_rounded, color: AppTheme.primaryBlue, size: 20),
                            ),
                            title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('Modified: ${AppFormatters.dateTime(stat.modified)} • Size: $sizeKb KB • Local Snapshot', style: const TextStyle(fontSize: 11)),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('Restore from this Backup'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange),
                              onPressed: () => _handleRestoreBackup(context, file.path, app),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Audit Logs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AUDIT TRAIL & SENSITIVE SHOP ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    Text('Tracks sales, price modifications, repair status updates, stock adjustments, and backup events.', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
                              DataColumn(label: Text('Staff Member')),
                              DataColumn(label: Text('Action Type')),
                              DataColumn(label: Text('Module')),
                              DataColumn(label: Text('Record / Ref')),
                              DataColumn(label: Text('Action Details & Audit Narrative')),
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

  Future<void> _handleCreateBackup(BuildContext context, AppProvider app) async {
    try {
      final path = await BackupService.createBackup(note: 'User manual backup');
      await _loadBackupData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created successfully at: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup creation failed: $e')),
        );
      }
    }
  }

  Future<void> _handleRestoreBackup(BuildContext context, String filePath, AppProvider app) async {
    final fileName = p.basename(filePath);
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'WARNING: Restore Database Backup',
      message:
          'Restoring backup "$fileName" will replace all current shop records with the data inside the backup.\n\nA safety backup of current data will be created automatically before proceeding.\n\nAre you sure you want to restore?',
      confirmLabel: 'Proceed with Restore',
      confirmColor: AppTheme.dangerRed,
    );

    if (confirmed && context.mounted) {
      try {
        await BackupService.restoreBackup(filePath, app.currentUser.name);

        // Reload all providers
        await app.reloadAll();
        context.read<LedgerProvider>().loadAll();
        context.read<InventoryProvider>().loadInventory();
        context.read<RepairProvider>().loadRepairs();
        await _loadBackupData();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database successfully restored from $fileName!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e')),
          );
        }
      }
    }
  }
}
