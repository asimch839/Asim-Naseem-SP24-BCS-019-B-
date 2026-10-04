import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/expense.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();

    final expenses = led.expenses.where((e) {
      if (_selectedCategory != 'All' && e.category != _selectedCategory) return false;
      if (q.isNotEmpty) {
        final matches = e.title.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.notes.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    final totalAmount = expenses.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      body: Padding(
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
                    const Text('Shop Expense Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Record plaza rents, electricity bills, technician salaries, and lab tool purchases', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('+ Add New Expense'),
                  onPressed: () => _showAddExpenseDialog(context, led, app),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary Metric
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_rounded, color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text('Filtered Expenses Total (${expenses.length} records):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  Text(
                    AppFormatters.currency(totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.dangerRed),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search & Category Dropdown
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by title, category, or narration...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Expense Category'),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                      ...Expense.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Expenses Table
            Expanded(
              child: Card(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expense records found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Expense Title')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Payment Method')),
                              DataColumn(label: Text('Notes / Remarks')),
                              DataColumn(label: Text('Recorded By')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: expenses.map((exp) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                      child: Text(exp.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                    ),
                                  ),
                                  DataCell(Text(AppFormatters.currency(exp.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed))),
                                  DataCell(Text(AppFormatters.date(exp.date))),
                                  DataCell(Text(exp.paymentMethod)),
                                  DataCell(Text(exp.notes.isNotEmpty ? exp.notes : '-')),
                                  DataCell(Text(exp.recordedBy.isNotEmpty ? exp.recordedBy : 'Admin')),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Delete Expense',
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                      onPressed: () async {
                                        final ok = await AppDialogs.confirm(
                                          context,
                                          title: 'Delete Expense',
                                          message: 'Delete expense entry "${exp.title}" of ${AppFormatters.currency(exp.amount)}?',
                                        );
                                        if (ok) {
                                          await led.deleteExpense(exp.id);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, LedgerProvider led, AppProvider app) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = Expense.categories.first;
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Shop Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Expense Title *', hintText: 'e.g. Monthly Shop Rent')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Expense Category *'),
                      items: Expense.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => category = v!),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs.) *')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                        DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                      ],
                      onChanged: (v) => setState(() => method = v!),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Narration / Notes')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                  final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                  if (amt <= 0) return;

                  final exp = Expense(
                    id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    category: category,
                    amount: amt,
                    paymentMethod: method,
                    notes: notesCtrl.text.trim(),
                    recordedBy: app.currentUser.name,
                  );

                  await led.addExpense(exp);
                  Navigator.pop(ctx);
                },
                child: const Text('Record Expense'),
              ),
            ],
          );
        },
      ),
    );
  }
}
