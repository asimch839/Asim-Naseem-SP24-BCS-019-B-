import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/models/repair_job.dart';
import '../../core/models/user.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/revenue_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final led = context.watch<LedgerProvider>();
    final rep = context.watch<RepairProvider>();
    final inv = context.watch<InventoryProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Financial Metrics
    final totalSalesToday = led.sales.fold(0.0, (s, sale) => s + sale.grandTotal);
    final totalCashReceivedToday = led.sales.fold(0.0, (s, sale) => s + sale.paidAmount);
    final totalPurchases = led.purchases.fold(0.0, (s, p) => s + p.totalAmount);
    final totalExpenses = led.expenses.fold(0.0, (s, e) => s + e.amount);

    final productProfit = led.sales.fold(0.0, (s, sale) => s + sale.totalProfit);
    final repairProfit = rep.repairs.where((r) => r.status == RepairStatus.delivered).fold(0.0, (s, r) => s + r.netProfit);
    final totalGrossProfit = productProfit + repairProfit;
    final totalNetProfit = totalGrossProfit - totalExpenses;

    final customerDues = led.totalCustomerDues;
    final supplierDues = led.totalSupplierDues;

    // Repair Metrics
    final newRepairs = rep.repairs.where((r) => r.status == RepairStatus.received).length;
    final inProgressRepairs = rep.repairs.where((r) => r.status == RepairStatus.inProgress || r.status == RepairStatus.inspection).length;
    final readyRepairs = rep.repairs.where((r) => r.status == RepairStatus.readyForDelivery).length;
    final completedRepairs = rep.repairs.where((r) => r.status == RepairStatus.completed || r.status == RepairStatus.delivered).length;

    // Stock Metrics
    final lowStockCount = inv.products.where((p) => p.isLowStock).length;
    final outOfStockCount = inv.products.where((p) => p.isOutOfStock).length;
    final inStockPhones = inv.phones.where((ph) => ph.status == 'In Stock').length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header & Quick Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${app.currentUser.name}!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${app.settings.shopName} • Today is ${AppFormatters.date(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    if (app.currentUser.role.canMakeSales)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                        label: const Text('New Sale (F1)'),
                        onPressed: () => app.setNavIndex(1),
                      ),
                    if (app.currentUser.role.canManageRepairs)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purpleRepair),
                        icon: const Icon(Icons.build_circle_rounded, size: 16),
                        label: const Text('New Repair (F4)'),
                        onPressed: () => AppDialogs.showNewRepairDialog(context),
                      ),
                    if (app.currentUser.role.canReceivePayments)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppTheme.successGreen),
                        label: const Text('Receive Payment (F6)'),
                        onPressed: () => AppDialogs.showReceivePaymentDialog(context),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Today's Key Performance Indicators
            const Text(
              'TODAY\'S SHOP & LAB PERFORMANCE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - (3 * 14)) / 4;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Total Sales Revenue',
                        value: AppFormatters.currency(totalSalesToday),
                        icon: Icons.monetization_on_rounded,
                        iconColor: AppTheme.primaryBlue,
                        subtitle: '${led.sales.length} transactions recorded',
                        onTap: () => app.setNavIndex(2),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Cash & Digital Received',
                        value: AppFormatters.currency(totalCashReceivedToday),
                        icon: Icons.account_balance_rounded,
                        iconColor: AppTheme.successGreen,
                        subtitle: 'Cash in hand & Bank/JazzCash',
                      ),
                    ),
                    if (app.currentUser.role.canViewProfit)
                      SizedBox(
                        width: itemWidth,
                        child: StatCard(
                          title: 'Estimated Net Profit',
                          value: AppFormatters.currency(totalNetProfit),
                          icon: Icons.trending_up_rounded,
                          iconColor: const Color(0xFF0D9488),
                          subtitle: 'Sale & Repair Profit - Expenses',
                          onTap: () => app.setNavIndex(14),
                        ),
                      )
                    else
                      SizedBox(
                        width: itemWidth,
                        child: StatCard(
                          title: 'Active In-Stock Phones',
                          value: '$inStockPhones Units',
                          icon: Icons.phone_android_rounded,
                          iconColor: AppTheme.primaryBlue,
                          subtitle: 'With unique tracked IMEIs',
                          onTap: () => app.setNavIndex(5),
                        ),
                      ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Customer Due Balance',
                        value: AppFormatters.currency(customerDues),
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppTheme.dangerRed,
                        subtitle: '${led.customers.where((c) => c.totalDue > 0).length} customers with dues',
                        onTap: () => app.setNavIndex(10),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            RevenueChart(sales: led.sales, isDark: isDark),
            const SizedBox(height: 24),

            const SizedBox(height: 14),

            // Secondary KPI Row
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - (3 * 14)) / 4;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Repair Jobs in Lab',
                        value: '${rep.repairs.length} Total',
                        icon: Icons.build_rounded,
                        iconColor: AppTheme.purpleRepair,
                        subtitle: '$inProgressRepairs in progress • $readyRepairs ready',
                        onTap: () => app.setNavIndex(7),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Supplier Payable Due',
                        value: AppFormatters.currency(supplierDues),
                        icon: Icons.local_shipping_rounded,
                        iconColor: AppTheme.warningOrange,
                        subtitle: '${led.suppliers.where((s) => s.dueAmount > 0).length} suppliers pending',
                        onTap: () => app.setNavIndex(10),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Shop Expenses',
                        value: AppFormatters.currency(totalExpenses),
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFF64748B),
                        subtitle: '${led.expenses.length} expense entries',
                        onTap: () => app.setNavIndex(11),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        title: 'Stock Warning Alerts',
                        value: '${lowStockCount + outOfStockCount} Items',
                        icon: Icons.warning_rounded,
                        iconColor: (lowStockCount + outOfStockCount) > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                        subtitle: '$lowStockCount low stock • $outOfStockCount out of stock',
                        onTap: () => app.setNavIndex(4),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Split View: Repair Lab Workflow + Stock Alerts & Recent Sales
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Repair Lab Live Status
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.precision_manufacturing_rounded, size: 20, color: AppTheme.purpleRepair),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mobile Repair Lab Overview',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: const Text('View All Jobs'),
                                onPressed: () => app.setNavIndex(7),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Repair Status Badges
                          Row(
                            children: [
                              _repairStatusChip('Received', '$newRepairs', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
                              const SizedBox(width: 8),
                              _repairStatusChip('In Progress', '$inProgressRepairs', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
                              const SizedBox(width: 8),
                              _repairStatusChip('Ready for Delivery', '$readyRepairs', const Color(0xFFD1FAE5), const Color(0xFF047857)),
                              const SizedBox(width: 8),
                              _repairStatusChip('Completed / Delivered', '$completedRepairs', const Color(0xFFF3E8FF), const Color(0xFF6B21A8)),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Live Repair Jobs List
                          if (rep.repairs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.build_circle_outlined, size: 48, color: AppTheme.purpleRepair.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    const Text('No repair jobs recorded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    const Text('Start adding repair jobs to see them tracked here.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Add New Repair'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purpleRepair),
                                      onPressed: () => AppDialogs.showNewRepairDialog(context),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...rep.repairs.take(4).map((job) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.purpleRepair.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        job.jobId,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.purpleRepair),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${job.deviceBrand} ${job.deviceModel} • ${job.customerName}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Problem: ${job.reportedProblem}',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusBg(job.status),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            job.status.displayName,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusTextColor(job.status),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          job.remainingDue > 0
                                              ? 'Due: ${AppFormatters.currency(job.remainingDue)}'
                                              : 'Fully Paid',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: job.remainingDue > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right Column: Stock Alerts & Recent Sales Activity
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Stock Alerts Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.notification_important_rounded, size: 20, color: AppTheme.dangerRed),
                                      SizedBox(width: 8),
                                      Text('Inventory Alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => app.setNavIndex(4),
                                    child: const Text('Manage Stock'),
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (app.lowStockProducts.isEmpty && app.outOfStockProducts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                                      SizedBox(width: 8),
                                      Text('All products are adequately stocked!'),
                                    ],
                                  ),
                                )
                              else ...[
                                ...app.outOfStockProducts.take(2).map((p) => _stockAlertTile(p.name, 'Out of Stock (0 pcs)', AppTheme.dangerRed, isDark)),
                                ...app.lowStockProducts.take(3).map((p) => _stockAlertTile(p.name, 'Low Stock (${p.stockQuantity} pcs remaining)', AppTheme.warningOrange, isDark)),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recent Sales Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.history_rounded, size: 20, color: AppTheme.primaryBlue),
                                      SizedBox(width: 8),
                                      Text('Recent Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => app.setNavIndex(2),
                                    child: const Text('View Sales'),
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (led.sales.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 30),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.primaryBlue.withOpacity(0.5)),
                                        const SizedBox(height: 12),
                                        const Text('No recent sales', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        TextButton(onPressed: () => app.setNavIndex(1), child: const Text('Go to POS')),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...led.sales.take(3).map((s) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${s.invoiceNumber} • ${s.customerName}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                            Text(
                                              '${s.items.length} item(s) • ${s.paymentMethod}',
                                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              AppFormatters.currency(s.grandTotal),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (s.dueAmount > 0)
                                              Text('Due: ${AppFormatters.currency(s.dueAmount)}', style: const TextStyle(fontSize: 10, color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _repairStatusChip(String title, String count, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _stockAlertTile(String name, String status, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Color _getStatusBg(RepairStatus status) {
    switch (status) {
      case RepairStatus.received:
        return const Color(0xFFDBEAFE);
      case RepairStatus.inspection:
        return const Color(0xFFE0E7FF);
      case RepairStatus.inProgress:
        return const Color(0xFFFEF3C7);
      case RepairStatus.waitingForParts:
        return const Color(0xFFFFEDD5);
      case RepairStatus.readyForDelivery:
        return const Color(0xFFD1FAE5);
      case RepairStatus.delivered:
        return const Color(0xFFDCFCE7);
      case RepairStatus.cancelled:
      case RepairStatus.unrepairable:
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusTextColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.received:
        return const Color(0xFF1E40AF);
      case RepairStatus.inspection:
        return const Color(0xFF3730A3);
      case RepairStatus.inProgress:
        return const Color(0xFF92400E);
      case RepairStatus.waitingForParts:
        return const Color(0xFF9A3412);
      case RepairStatus.readyForDelivery:
        return const Color(0xFF065F46);
      case RepairStatus.delivered:
        return const Color(0xFF166534);
      case RepairStatus.cancelled:
      case RepairStatus.unrepairable:
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF334155);
    }
  }
}
