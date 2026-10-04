import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/models/repair_job.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _dateFilter = 'All Time'; // 'Today', 'This Month', 'All Time'

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final rep = context.watch<RepairProvider>();
    final inv = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter by date
    final now = DateTime.now();
    final sales = led.sales.where((s) {
      if (_dateFilter == 'Today') {
        return s.saleDate.year == now.year && s.saleDate.month == now.month && s.saleDate.day == now.day;
      } else if (_dateFilter == 'This Month') {
        return s.saleDate.year == now.year && s.saleDate.month == now.month;
      }
      return true;
    }).toList();

    final repairs = rep.repairs.where((r) {
      if (_dateFilter == 'Today') {
        return r.createdAt.year == now.year && r.createdAt.month == now.month && r.createdAt.day == now.day;
      } else if (_dateFilter == 'This Month') {
        return r.createdAt.year == now.year && r.createdAt.month == now.month;
      }
      return true;
    }).toList();

    final expenses = led.expenses.where((e) {
      if (_dateFilter == 'Today') {
        return e.date.year == now.year && e.date.month == now.month && e.date.day == now.day;
      } else if (_dateFilter == 'This Month') {
        return e.date.year == now.year && e.date.month == now.month;
      }
      return true;
    }).toList();

    // Financial Metrics Calculation
    final totalSalesRevenue = sales.fold(0.0, (s, sale) => s + sale.grandTotal);
    final totalProductCost = sales.fold(0.0, (s, sale) => s + sale.totalCost);
    final productProfit = totalSalesRevenue - totalProductCost;

    final totalRepairRevenue = repairs.where((r) => r.status == RepairStatus.delivered).fold(0.0, (s, r) => s + r.finalTotal);
    final totalRepairPartsCost = repairs.where((r) => r.status == RepairStatus.delivered).fold(0.0, (s, r) => s + r.partsTotalCost);
    final repairProfit = totalRepairRevenue - totalRepairPartsCost;

    final totalGrossProfit = productProfit + repairProfit;
    final totalExpensesAmount = expenses.fold(0.0, (s, e) => s + e.amount);
    final netProfit = totalGrossProfit - totalExpensesAmount;

    // Inventory Valuation
    final inventoryCostValuation = inv.products.fold(0.0, (s, p) => s + (p.purchasePrice * p.stockQuantity));
    final inventoryRetailValuation = inv.products.fold(0.0, (s, p) => s + (p.salePrice * p.stockQuantity));

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
                    const Text('Business Reports & Profit/Loss Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Comprehensive financial statement, product margin, repair lab revenue, and stock valuation', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _dateFilter,
                      items: const [
                        DropdownMenuItem(value: 'Today', child: Text('Filter: Today')),
                        DropdownMenuItem(value: 'This Month', child: Text('Filter: This Month')),
                        DropdownMenuItem(value: 'All Time', child: Text('Filter: All Time')),
                      ],
                      onChanged: (v) => setState(() => _dateFilter = v!),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export Inventory CSV'),
                      onPressed: () async {
                        final path = await ExportService.exportInventoryToCsv(inv.products);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Inventory valuation exported to: $path')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // P&L Statement Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue, size: 22),
                        SizedBox(width: 8),
                        Text('PROFIT & LOSS STATEMENT (ACCURATE ACCOUNTING)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculates actual gross margin from products sold, net lab revenue after replacement parts, and subtracts shop overheads.',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const Divider(height: 24),

                    // Financial Items
                    _financialLine('1. Total Product Sales Revenue', totalSalesRevenue, isBold: true),
                    _financialLine('   Less: Cost of Mobile Phones & Accessories Sold (COGS)', -totalProductCost, color: AppTheme.dangerRed),
                    _financialLine('   = Product Gross Profit Margin', productProfit, isBold: true, color: AppTheme.successGreen),
                    const SizedBox(height: 10),

                    _financialLine('2. Total Mobile Repair Lab Revenue (Delivered)', totalRepairRevenue, isBold: true),
                    _financialLine('   Less: Lab Replacement Parts Cost (OLEDs, Batteries, Flex)', -totalRepairPartsCost, color: AppTheme.dangerRed),
                    _financialLine('   = Repair Lab Gross Profit', repairProfit, isBold: true, color: AppTheme.successGreen),
                    const Divider(height: 20),

                    _financialLine('TOTAL COMBINED GROSS PROFIT', totalGrossProfit, isBold: true, fontSize: 15, color: const Color(0xFF0369A1)),
                    _financialLine('Less: Operating Expenses (Rent, Bills, Salaries, Transport)', -totalExpensesAmount, isBold: true, color: AppTheme.dangerRed),
                    const Divider(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: netProfit >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NET BUSINESS PROFIT (${_dateFilter.toUpperCase()}):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: netProfit >= 0 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                ),
                              ),
                              Text(
                                'Final take-home profit after all merchandise costs and overheads',
                                style: TextStyle(fontSize: 11, color: netProfit >= 0 ? const Color(0xFF166534) : const Color(0xFF991B1B)),
                              ),
                            ],
                          ),
                          Text(
                            AppFormatters.currency(netProfit),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: netProfit >= 0 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Two Column Cards: Inventory Valuation & Payment Breakdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inventory Valuation
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_rounded, color: AppTheme.primaryBlue, size: 20),
                              SizedBox(width: 8),
                              Text('Inventory Valuation on Hand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 20),
                          _statRow('Total Active Products:', '${inv.products.length} products'),
                          _statRow('Total Physical Units in Shop:', '${inv.products.fold(0, (s, p) => s + p.stockQuantity)} pcs'),
                          _statRow('Tracked Mobile Phones:', '${inv.phones.where((p) => p.status == "In Stock").length} handsets'),
                          const Divider(height: 16),
                          _statRow('Stock Value (at Purchase Cost):', AppFormatters.currency(inventoryCostValuation), isBold: true),
                          _statRow('Stock Value (at Retail Sale Price):', AppFormatters.currency(inventoryRetailValuation), isBold: true, color: AppTheme.primaryBlue),
                          _statRow('Potential Unrealized Profit:', AppFormatters.currency(inventoryRetailValuation - inventoryCostValuation), isBold: true, color: AppTheme.successGreen),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Cashflow & Payment Methods
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.payments_rounded, color: AppTheme.successGreen, size: 20),
                              SizedBox(width: 8),
                              Text('Cash Flow & Customer Dues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 20),
                          _statRow('Total Cash & Digital Collected:', AppFormatters.currency(sales.fold<double>(0.0, (s, sale) => s + sale.paidAmount)), isBold: true, color: AppTheme.successGreen),
                          _statRow('Outstanding Customer Dues:', AppFormatters.currency(led.totalCustomerDues), isBold: true, color: AppTheme.dangerRed),
                          _statRow('Outstanding Supplier Payables:', AppFormatters.currency(led.totalSupplierDues), isBold: true, color: AppTheme.warningOrange),
                          const Divider(height: 16),
                          _statRow('Delivered Repair Jobs:', '${repairs.where((r) => r.status == RepairStatus.delivered).length} jobs'),
                          _statRow('Pending Active Repairs in Lab:', '${repairs.where((r) => !r.status.isTerminal).length} devices'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _financialLine(String label, double amount, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(AppFormatters.currency(amount), style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
