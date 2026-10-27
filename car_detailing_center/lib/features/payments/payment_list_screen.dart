import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/repositories/invoice_payment_repository.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final InvoicePaymentRepository _paymentRepo = Get.find<InvoicePaymentRepository>();

  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final list = await _paymentRepo.getPayments(searchQuery: _searchQuery);
      if (mounted) {
        setState(() {
          _payments = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final totalCollected = _payments.fold<double>(
      0.0,
      (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return AppScaffold(
      currentRoute: AppRoutes.payments,
      title: 'Payment Transactions & Collection Receipts',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search Bar & Inflow Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search payments by Invoice #, Customer Name, or Reference...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchPayments();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh Ledger',
                      onPressed: _fetchPayments,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Inflow banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    '${_payments.length} Payments Recorded',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    'Total Collections: ${Formatters.currency(totalCollected, symbol: currency)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading payment ledger...')
                  : _payments.isEmpty
                      ? AppEmptyState(
                          icon: Icons.price_check_outlined,
                          title: 'No Payments Recorded Yet',
                          description: _searchQuery.isNotEmpty
                              ? 'No payments found matching "$_searchQuery".'
                              : 'Record customer payments against invoices to reconcile balances.',
                          actionLabel: 'View Invoices',
                          onAction: () => Get.toNamed(AppRoutes.invoices),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _payments.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = _payments[index];
                              final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                              final dateStr = p['payment_date'] as String? ?? '';
                              final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                              final customerName = p['customer_name'] as String? ?? 'Walk-in Customer';
                              final invNum = p['invoice_number'] as String? ?? 'N/A';
                              final method = p['payment_method'] as String? ?? 'Cash';
                              final ref = p['reference_number'] as String? ?? '';
                              final isRefund = (p['is_refund'] as int? ?? 0) == 1;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isRefund ? AppColors.error : AppColors.success).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isRefund ? Icons.remove_circle_outline_rounded : Icons.check_circle_outline_rounded,
                                    color: isRefund ? AppColors.error : AppColors.success,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Invoice $invNum',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                      ),
                                    ),
                                    if (isRefund) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('REFUND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error)),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Method: $method • Date: ${Formatters.dateTime(date)}${ref.isNotEmpty ? " • Ref: $ref" : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Text(
                                  Formatters.currency(amount, symbol: currency),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isRefund ? AppColors.error : AppColors.success,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
