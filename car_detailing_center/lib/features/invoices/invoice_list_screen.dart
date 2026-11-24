import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_payment_repository.dart';
import '../../data/repositories/job_repository.dart';
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
  String? _startDate;
  String? _endDate;

  double _totalInvoicedAll = 0.0;
  double _totalPaidAll = 0.0;
  double _totalPendingAll = 0.0;
  int _pendingCountAll = 0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['status'] != null) {
      _statusFilter = args['status'] as String;
    }
    _fetchInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final list = await _invoiceRepo.getInvoices(
        searchQuery: _searchQuery,
        status: _statusFilter == 'All' ? null : _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
      );

      final models = list.map((m) => InvoiceModel.fromSqlite(m)).toList();

      // Compute overall stats for KPIs across the period
      final allList = await _invoiceRepo.getInvoices(startDate: _startDate, endDate: _endDate);
      final allModels = allList.map((m) => InvoiceModel.fromSqlite(m)).toList();
      final billed = allModels.fold(0.0, (sum, inv) => sum + inv.grandTotal);
      final paid = allModels.fold(0.0, (sum, inv) => sum + inv.paidAmount);
      final pending = allModels.fold(0.0, (sum, inv) => sum + inv.remainingAmount);
      final pCount = allModels.where((inv) => inv.remainingAmount > 0.01).length;

      if (mounted) {
        setState(() {
          _invoices = models;
          _totalInvoicedAll = billed;
          _totalPaidAll = paid;
          _totalPendingAll = pending;
          _pendingCountAll = pCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<InvoiceModel> _loadFullInvoice(InvoiceModel invoice) async {
    try {
      final details = await _invoiceRepo.getInvoiceDetails(invoice.id);
      if (details != null) {
        final rawItems = (details['items'] as List<dynamic>? ?? []);
        List<InvoiceItem> items = rawItems
            .map((i) => InvoiceItem.fromMap(Map<String, dynamic>.from(i as Map)))
            .where((i) => i.name.trim().isNotEmpty)
            .toList();

        // If items are empty and this invoice was created from a job, load services from job_services!
        if (items.isEmpty && invoice.jobId != null && invoice.jobId!.isNotEmpty) {
          final jobRepo = Get.find<JobRepository>();
          final jobDetails = await jobRepo.getJobById(invoice.jobId!);
          if (jobDetails != null) {
            final svcList = (jobDetails['services'] as List<dynamic>? ?? []);
            for (final s in svcList) {
              final desc = (s['description']?.toString() ?? '').trim();
              final amt = (s['amount'] as num?)?.toDouble() ?? 0.0;
              items.add(InvoiceItem(
                name: desc.isNotEmpty ? desc : 'Detailing Service',
                type: desc.toLowerCase().contains('stock') || desc.toLowerCase().contains('chemical') || desc.toLowerCase().contains('bottle') ? 'product' : 'service',
                quantity: 1.0,
                unitPrice: amt,
                total: amt,
              ));
            }
          }
        }

        // If items are still empty, create an itemized line item from vehicle and subtotal
        if (items.isEmpty) {
          final desc = (invoice.notes != null && invoice.notes!.isNotEmpty)
              ? invoice.notes!
              : (invoice.vehicleDisplayName != null && invoice.vehicleDisplayName!.isNotEmpty
                  ? 'Detailing Service Package - ${invoice.vehicleDisplayName}'
                  : 'Detailing Services & Labour');
          final price = invoice.subtotal > 0 ? invoice.subtotal : invoice.grandTotal;
          items.add(InvoiceItem(
            name: desc,
            type: 'service',
            quantity: 1.0,
            unitPrice: price,
            total: price,
          ));
        }

        return InvoiceModel.fromSqlite(details, items);
      }
    } catch (e) {
      debugPrint('Error loading full invoice details: $e');
    }

    if (invoice.items.isEmpty) {
      final desc = (invoice.vehicleDisplayName != null && invoice.vehicleDisplayName!.isNotEmpty)
          ? 'Detailing Service Package - ${invoice.vehicleDisplayName}'
          : 'Detailing Services & Labour';
      final price = invoice.subtotal > 0 ? invoice.subtotal : invoice.grandTotal;
      final fallbackItem = InvoiceItem(
        name: desc,
        type: 'service',
        quantity: 1.0,
        unitPrice: price,
        total: price,
      );
      return invoice.copyWith(items: [fallbackItem]);
    }
    return invoice;
  }

  Widget _buildSummaryKpiCard({
    required String title,
    required double amount,
    required String currency,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 11.5, color: AppColors.textDarkSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(amount, symbol: currency),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewInvoice(InvoiceModel invoice) async {
    final business = AuthService.to.currentBusiness.value;
    if (business == null) return;

    try {
      final fullInvoice = await _loadFullInvoice(invoice);
      final pdfBytes = await PdfService.buildInvoiceBytes(business: business, invoice: fullInvoice);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.surfaceDark,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950, maxHeight: 850),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.cardDark,
                    border: Border(bottom: BorderSide(color: AppColors.borderDark)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tax Invoice: ${fullInvoice.invoiceNumber} • ${fullInvoice.customerName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shareInvoice(fullInvoice);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textDarkMuted),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) async => pdfBytes,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: true,
                    allowSharing: true,
                    pdfFileName: 'Invoice_${fullInvoice.invoiceNumber}.pdf',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to render invoice preview: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  Future<void> _shareInvoice(InvoiceModel invoice) async {
    final business = AuthService.to.currentBusiness.value;
    if (business == null) return;

    try {
      final fullInvoice = await _loadFullInvoice(invoice);
      final pdfBytes = await PdfService.buildInvoiceBytes(business: business, invoice: fullInvoice);

      final tempDir = await getTemporaryDirectory();
      final baseName = 'Invoice_${fullInvoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = File('${tempDir.path}/$baseName.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Only 1 item sent: the official Invoice PDF
      if (Platform.isWindows) {
        await WindowsClipboardService.copyFileToClipboard(pdfFile.path);
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$baseName.pdf');
      }

      // Try opening WhatsApp with client's phone number
      final phone = fullInvoice.customerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
      final whatsappUri = Uri.parse(phone.isNotEmpty ? 'whatsapp://send?phone=$phone' : 'whatsapp://send');
      final webWhatsappUri = Uri.parse(phone.isNotEmpty ? 'https://web.whatsapp.com/send?phone=$phone' : 'https://web.whatsapp.com');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri);
      }

      if (!mounted) return;

      Get.snackbar(
        'Invoice PDF Copied!',
        'Single Tax Invoice PDF copied. Open client chat & press Ctrl + V to send!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.25),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366)),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to share invoice: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  void _showMobileBillingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                const Text('New Billing / Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    child: const Icon(Icons.point_of_sale_rounded, color: AppColors.success),
                  ),
                  title: const Text('Sell Stock / Counter Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('POS counter sale for chemicals, pads, or products'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.cardDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final res = await showDialog(
                      context: context,
                      builder: (_) => const InvoiceCreateDialog(isDirectSale: true),
                    );
                    if (res == true) _fetchInvoices();
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Create Service Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Standard tax invoice for vehicle detailing & coating jobs'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.cardDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final res = await showDialog(
                      context: context,
                      builder: (_) => const InvoiceCreateDialog(),
                    );
                    if (res == true) _fetchInvoices();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final isMobile = ResponsiveLayout.isMobile(context);

    return AppScaffold(
      currentRoute: AppRoutes.invoices,
      title: 'Tax Invoices & Billing Center',
      actions: isMobile
          ? [
              IconButton(
                icon: const Icon(Icons.point_of_sale_rounded, color: AppColors.success),
                tooltip: 'Sell Stock / Counter Bill',
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (_) => const InvoiceCreateDialog(isDirectSale: true),
                  );
                  if (res == true) _fetchInvoices();
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
                tooltip: 'Create Invoice',
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (_) => const InvoiceCreateDialog(),
                  );
                  if (res == true) _fetchInvoices();
                },
              ),
            ]
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await showDialog(
                      context: context,
                      builder: (_) => const InvoiceCreateDialog(isDirectSale: true),
                    );
                    if (res == true) _fetchInvoices();
                  },
                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                  label: const Text('Sell Stock / Counter Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await showDialog(
                      context: context,
                      builder: (_) => const InvoiceCreateDialog(),
                    );
                    if (res == true) _fetchInvoices();
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Create Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              heroTag: 'mobileInvoiceFab',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('New Invoice / Bill'),
              onPressed: () => _showMobileBillingOptions(context),
            )
          : Wrap(
              direction: Axis.horizontal,
              spacing: 8,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'sellStockFabInv',
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    final res = await showDialog(
                      context: context,
                      builder: (_) => const InvoiceCreateDialog(isDirectSale: true),
                    );
                    if (res == true) _fetchInvoices();
                  },
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const Text('Sell Stock / Bill'),
                ),
                FloatingActionButton.extended(
                  heroTag: 'createInvFab',
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
              ],
            ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          children: [
            // 1. KPI Summary Cards (Billed, Paid, Pending Dues)
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 720;
                final cardBilled = _buildSummaryKpiCard(
                  title: 'Total Invoiced',
                  amount: _totalInvoicedAll,
                  currency: currency,
                  subtitle: '${_invoices.length} Invoices',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primaryLight,
                );
                final cardPaid = _buildSummaryKpiCard(
                  title: 'Total Paid (Collected)',
                  amount: _totalPaidAll,
                  currency: currency,
                  subtitle: 'Client payments received',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                );
                final cardPending = _buildSummaryKpiCard(
                  title: 'Total Pending / Due',
                  amount: _totalPendingAll,
                  currency: currency,
                  subtitle: '$_pendingCountAll Clients with Baqaya',
                  icon: Icons.warning_amber_rounded,
                  color: _totalPendingAll > 0 ? AppColors.error : AppColors.success,
                  isSelected: _statusFilter == 'Pending',
                  onTap: () {
                    setState(() => _statusFilter = _statusFilter == 'Pending' ? 'All' : 'Pending');
                    _fetchInvoices();
                  },
                );

                if (isSmall) {
                  return Column(
                    children: [
                      cardPending,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: cardBilled),
                          const SizedBox(width: 8),
                          Expanded(child: cardPaid),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cardBilled),
                    const SizedBox(width: 12),
                    Expanded(child: cardPaid),
                    const SizedBox(width: 12),
                    Expanded(child: cardPending),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search Invoice #, Name, Plate...',
                                    prefixIcon: Icon(Icons.search_rounded),
                                  ),
                                  onChanged: (val) {
                                    _searchQuery = val.trim();
                                    _fetchInvoices();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh',
                                onPressed: _fetchInvoices,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _statusFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Status Filter',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Payment Statuses')),
                              DropdownMenuItem(value: 'Pending', child: Text('⚠️ Pending Dues Only (Baqaya)')),
                              DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                              DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid Only')),
                              DropdownMenuItem(value: 'Paid', child: Text('Fully Paid')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _statusFilter = val);
                                _fetchInvoices();
                              }
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
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
                            DropdownMenuItem(value: 'Pending', child: Text('⚠️ Pending Dues Only (Baqaya)')),
                            DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                            DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid Only')),
                            DropdownMenuItem(value: 'Paid', child: Text('Fully Paid')),
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
                    );
                  },
                ),
                const SizedBox(height: 12),
                DateRangeFilterBar(
                  onFilterChanged: (start, end, label) {
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                    _fetchInvoices();
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('All Invoices (${_invoices.length})'),
                        selected: _statusFilter == 'All',
                        onSelected: (_) {
                          setState(() => _statusFilter = 'All');
                          _fetchInvoices();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                        label: Text(
                          '⚠️ Pending Dues ($_pendingCountAll Clients)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statusFilter == 'Pending' ? Colors.white : AppColors.error,
                          ),
                        ),
                        selected: _statusFilter == 'Pending',
                        selectedColor: AppColors.error,
                        onSelected: (_) {
                          setState(() => _statusFilter = _statusFilter == 'Pending' ? 'All' : 'Pending');
                          _fetchInvoices();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Partially Paid'),
                        selected: _statusFilter == 'Partially Paid',
                        onSelected: (_) {
                          setState(() => _statusFilter = 'Partially Paid');
                          _fetchInvoices();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Unpaid Only'),
                        selected: _statusFilter == 'Unpaid',
                        onSelected: (_) {
                          setState(() => _statusFilter = 'Unpaid');
                          _fetchInvoices();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Fully Paid'),
                        selected: _statusFilter == 'Paid',
                        onSelected: (_) {
                          setState(() => _statusFilter = 'Paid');
                          _fetchInvoices();
                        },
                      ),
                    ],
                  ),
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

                              return InkWell(
                                onTap: () => _viewInvoice(invoice),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.receipt_rounded, color: statusColor),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    invoice.status,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '• ${invoice.customerName}',
                                                    style: const TextStyle(fontSize: 13),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${invoice.vehicleDisplayName ?? "General Detailing"} ${invoice.vehicleRegNumber != null && invoice.vehicleRegNumber!.isNotEmpty ? "(${invoice.vehicleRegNumber})" : ""} • ${Formatters.date(invoice.createdAt)}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isMobile) ...[
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Text(
                                                    'Total: ${Formatters.currency(invoice.grandTotal, symbol: currency)}',
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    'Paid: ${Formatters.currency(invoice.paidAmount, symbol: currency)}',
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                                  ),
                                                  Text(
                                                    invoice.remainingAmount > 0
                                                        ? 'Due: ${Formatters.currency(invoice.remainingAmount, symbol: currency)}'
                                                        : 'Settled (Rs. 0)',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: invoice.remainingAmount > 0 ? AppColors.error : AppColors.success,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (isMobile)
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded),
                                          onSelected: (action) async {
                                            if (action == 'view') {
                                              _viewInvoice(invoice);
                                            } else if (action == 'share') {
                                              _shareInvoice(invoice);
                                            } else if (action == 'print') {
                                              final business = AuthService.to.currentBusiness.value;
                                              if (business != null) {
                                                final fullInvoice = await _loadFullInvoice(invoice);
                                                await PdfService.printInvoice(business: business, invoice: fullInvoice);
                                              }
                                            } else if (action == 'pay') {
                                              final res = await showDialog(
                                                context: context,
                                                builder: (_) => RecordPaymentDialog(invoice: invoice),
                                              );
                                              if (res == true) _fetchInvoices();
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'view',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility_rounded, size: 18, color: AppColors.primaryLight),
                                                  SizedBox(width: 8),
                                                  Text('View Invoice'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'share',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.share_rounded, size: 18, color: Color(0xFF25D366)),
                                                  SizedBox(width: 8),
                                                  Text('Share WhatsApp', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'print',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.print_rounded, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Print / Save PDF'),
                                                ],
                                              ),
                                            ),
                                            if (invoice.remainingAmount > 0)
                                              const PopupMenuItem(
                                                value: 'pay',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.price_check_rounded, color: AppColors.success, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Collect Payment', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('Total Bill: ', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                                                    Text(
                                                      Formatters.currency(invoice.grandTotal, symbol: currency),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('Client Paid: ', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                                                    Text(
                                                      Formatters.currency(invoice.paidAmount, symbol: currency),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      invoice.remainingAmount > 0 ? 'Pending Due: ' : 'Status: ',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                                    ),
                                                    Text(
                                                      invoice.remainingAmount > 0
                                                          ? Formatters.currency(invoice.remainingAmount, symbol: currency)
                                                          : 'Settled (Rs. 0)',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: invoice.remainingAmount > 0 ? AppColors.error : AppColors.success,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 14),
                                            if (invoice.remainingAmount > 0) ...[
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.price_check_rounded, size: 15),
                                                label: const Text('Collect Due'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.success,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                ),
                                                onPressed: () async {
                                                  final res = await showDialog(
                                                    context: context,
                                                    builder: (_) => RecordPaymentDialog(invoice: invoice),
                                                  );
                                                  if (res == true) _fetchInvoices();
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            // 1. View Button
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.visibility_rounded, size: 15),
                                              label: const Text('View'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primaryLight,
                                                side: const BorderSide(color: AppColors.primaryLight),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              ),
                                              onPressed: () => _viewInvoice(invoice),
                                            ),
                                            const SizedBox(width: 8),
                                            // 2. Share WhatsApp Button
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.share_rounded, size: 15),
                                              label: const Text('Share'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF25D366),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              ),
                                              onPressed: () => _shareInvoice(invoice),
                                            ),
                                            const SizedBox(width: 8),
                                            // 3. Print PDF Button
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.print_rounded, size: 15),
                                              label: const Text('Print PDF'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              ),
                                              onPressed: () async {
                                                final business = AuthService.to.currentBusiness.value;
                                                if (business != null) {
                                                  final fullInvoice = await _loadFullInvoice(invoice);
                                                  await PdfService.printInvoice(business: business, invoice: fullInvoice);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
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
