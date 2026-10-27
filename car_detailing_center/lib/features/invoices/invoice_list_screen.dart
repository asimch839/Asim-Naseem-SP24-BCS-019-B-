import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_payment_repository.dart';
import 'invoice_create_dialog.dart';
import '../payments/record_payment_dialog.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final InvoicePaymentRepository _invoiceRepo = Get.find<InvoicePaymentRepository>();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final list = await _invoiceRepo.getInvoices(
        searchQuery: _searchQuery,
        status: _statusFilter == 'All' ? null : _statusFilter,
      );

      final models = list.map((m) => InvoiceModel.fromSqlite(m)).toList();
      if (mounted) {
        setState(() {
          _invoices = models;
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

    return AppScaffold(
      currentRoute: AppRoutes.invoices,
      title: 'Tax Invoices & Billing Center',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (_) => const InvoiceCreateDialog(),
          );
          if (res == true) _fetchInvoices();
        },
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('Create Invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by Invoice #, Customer Name, or Plate Number...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchInvoices();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Payment Statuses')),
                        DropdownMenuItem(value: 'Paid', child: Text('Fully Paid')),
                        DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                        DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _statusFilter = val);
                          _fetchInvoices();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _fetchInvoices,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Invoices List
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading billing invoices...')
                  : _invoices.isEmpty
                      ? AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Invoices Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No invoices matched your filter query.'
                              : 'Issue tax invoices for completed detailing jobs or customer service visits.',
                          actionLabel: 'Create Invoice',
                          onAction: () async {
                            final res = await showDialog(
                              context: context,
                              builder: (_) => const InvoiceCreateDialog(),
                            );
                            if (res == true) _fetchInvoices();
                          },
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _invoices.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final invoice = _invoices[index];
                              final isPaid = invoice.status == 'Paid';
                              final isPartial = invoice.status == 'Partially Paid' || invoice.status == 'Partial';

                              final statusColor = isPaid
                                  ? AppColors.success
                                  : (isPartial ? AppColors.warning : AppColors.error);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.receipt_rounded, color: statusColor),
                                ),
                                title: Row(
                                  children: [
                                    Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '• ${invoice.customerName}',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        invoice.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${invoice.vehicleDisplayName ?? "General Detailing"} ${invoice.vehicleRegNumber != null && invoice.vehicleRegNumber!.isNotEmpty ? "(${invoice.vehicleRegNumber})" : ""} • Date: ${Formatters.date(invoice.createdAt)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          Formatters.currency(invoice.grandTotal, symbol: currency),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          invoice.remainingAmount > 0
                                              ? 'Remaining: ${Formatters.currency(invoice.remainingAmount, symbol: currency)}'
                                              : 'Fully Settled',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: invoice.remainingAmount > 0 ? AppColors.error : AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    if (invoice.remainingAmount > 0)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final res = await showDialog(
                                            context: context,
                                            builder: (_) => RecordPaymentDialog(invoice: invoice),
                                          );
                                          if (res == true) _fetchInvoices();
                                        },
                                        icon: const Icon(Icons.price_check_rounded, size: 16),
                                        label: const Text('Pay'),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.print_rounded),
                                      tooltip: 'Print / Save PDF',
                                      onPressed: () async {
                                        final business = AuthService.to.currentBusiness.value;
                                        if (business != null) {
                                          await PdfService.printInvoice(business: business, invoice: invoice);
                                        }
                                      },
                                    ),
                                  ],
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
