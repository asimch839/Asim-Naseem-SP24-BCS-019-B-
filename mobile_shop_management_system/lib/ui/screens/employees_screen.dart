import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/user.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
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
                    const Text('Staff, Technicians & Role Permissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Manage sales staff, mobile hardware technicians, cashiers, and access controls', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('+ Add Staff Member'),
                  onPressed: () => _showAddUserDialog(context, app),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Staff Members List Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE SHOP & LAB STAFF MEMBERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 12),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Assigned Role')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Joined Date')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: app.allUsers.map((u) {
                        final isCurrent = u.id == app.currentUser.id;
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                                    child: Text(u.name.isNotEmpty ? u.name[0] : 'U', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (isCurrent)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Logged In', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(u.username)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                child: Text(u.role.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              ),
                            ),
                            DataCell(Text(AppFormatters.formatPhone(u.phone))),
                            DataCell(Text(AppFormatters.date(u.createdAt))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                child: const Text('Active', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Visual Role-Based Permissions Matrix
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security_rounded, size: 20, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('Role-Based Access Control & Permissions Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enforces strict segregation of duties. Technicians handle repair workflow and parts consumption, while financial reports and profit calculations are restricted to Owners & Managers.',
                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                    ),
                    const Divider(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Permission / Capability')),
                          DataColumn(label: Text('Shop Owner')),
                          DataColumn(label: Text('Admin')),
                          DataColumn(label: Text('Manager')),
                          DataColumn(label: Text('Sales Staff')),
                          DataColumn(label: Text('Technician')),
                          DataColumn(label: Text('Cashier')),
                        ],
                        rows: [
                          _permRow('Make POS Sales & Invoices', true, true, true, true, false, true),
                          _permRow('View Repair Lab & Jobs', true, true, true, true, true, false),
                          _permRow('Update Repair Status & Add Parts', true, true, true, false, true, false),
                          _permRow('Receive Customer Due Payments', true, true, true, false, false, true),
                          _permRow('View Net Profit & Profit Margin', true, true, false, false, false, false),
                          _permRow('View Financial & P&L Reports', true, true, true, false, false, false),
                          _permRow('Manage Supplier Payables', true, true, true, false, false, false),
                          _permRow('Perform Database Backup & Restore', true, true, false, false, false, false),
                          _permRow('Edit Shop Settings & Invoicing', true, true, false, false, false, false),
                        ],
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

  DataRow _permRow(String perm, bool owner, bool admin, bool mgr, bool sales, bool tech, bool cash) {
    return DataRow(
      cells: [
        DataCell(Text(perm, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(_checkIcon(owner)),
        DataCell(_checkIcon(admin)),
        DataCell(_checkIcon(mgr)),
        DataCell(_checkIcon(sales)),
        DataCell(_checkIcon(tech)),
        DataCell(_checkIcon(cash)),
      ],
    );
  }

  Widget _checkIcon(bool enabled) {
    return enabled
        ? const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 18)
        : const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18);
  }

  void _showAddUserDialog(BuildContext context, AppProvider app) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    UserRole role = UserRole.salesStaff;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                  const SizedBox(height: 10),
                  TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Login Username *')),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Phone *')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role / Designation *'),
                    items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                    onChanged: (v) => setState(() => role = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || userCtrl.text.isEmpty) return;

                  final u = AppUser(
                    id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    username: userCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: role,
                  );

                  await DatabaseHelper.instance.insertUser(u);
                  await app.reloadAll();
                  Navigator.pop(ctx);
                },
                child: const Text('Add Staff'),
              ),
            ],
          );
        },
      ),
    );
  }
}
