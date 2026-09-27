import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_button.dart';
import '../../core/utils/responsive.dart';
import 'receipt_controller.dart';

class ReceiptView extends GetView<ReceiptController> {
  const ReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header Bar
            const ResponsiveHeader(
              title: 'Receipts & Invoices',
              subtitle: 'Generated payment slips with printable A4 and thermal formats',
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        controller.searchQuery.value = val;
                        controller.fetchReceipts();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by receipt number, student name, or ID code...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Receipts Table
            Obx(() {
              final list = controller.receipts;

                final List<List<Widget>> tableRows = list.map((r) {
                  return [
                    Text(r.receiptNumber, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(DateFormatter.formatDate(DateTime.tryParse(r.paymentDate)), style: AppStyles.bodySmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(r.studentName ?? '-', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text('${r.studentIdCode ?? '-'} • Room ${r.roomNumber ?? '-'}', style: AppStyles.caption),
                      ],
                    ),
                    Text(DateFormatter.formatMonthYearString(r.rentMonth), style: AppStyles.bodySmall),
                    Text(r.paymentMethod, style: AppStyles.bodySmall),
                    Text(
                      CurrencyFormatter.format(r.amountPaid),
                      style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                    Text(
                      CurrencyFormatter.format(r.remainingAmount),
                      style: AppStyles.bodySmall.copyWith(
                        color: r.remainingAmount > 0 ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButton(
                          text: 'Preview',
                          icon: Icons.print_rounded,
                          type: ButtonType.secondary,
                          height: 32,
                          onPressed: () => controller.previewReceipt(r),
                        ),
                        const SizedBox(width: 6),
                        CustomButton(
                          text: 'Share',
                          icon: Icons.share_rounded,
                          type: ButtonType.secondary,
                          height: 32,
                          onPressed: () => controller.shareReceiptWhatsApp(r),
                        ),
                      ],
                    ),
                  ];
                }).toList();

                return DataTableWidget(
                  isLoading: controller.isLoading.value,
                  columns: const [
                    TableColumnDef(title: 'Receipt #'),
                    TableColumnDef(title: 'Payment Date'),
                    TableColumnDef(title: 'Student'),
                    TableColumnDef(title: 'Month'),
                    TableColumnDef(title: 'Method'),
                    TableColumnDef(title: 'Amount Paid'),
                    TableColumnDef(title: 'Remaining'),
                    TableColumnDef(title: 'Action', alignment: Alignment.center),
                  ],
                  rows: tableRows,
                  emptyTitle: 'No Receipts Generated',
                  emptySubtitle: 'Payment receipts will appear here automatically when payments are recorded.',
                );
              }),
            ],
        ),
      );
    }
}
