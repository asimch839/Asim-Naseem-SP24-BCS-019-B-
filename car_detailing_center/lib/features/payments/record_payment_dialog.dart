import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_payment_repository.dart';

class RecordPaymentDialog extends StatefulWidget {
  final InvoiceModel invoice;
  const RecordPaymentDialog({super.key, required this.invoice});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = AppConstants.paymentCash;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.invoice.remainingAmount.toStringAsFixed(0));
  }

  void _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return; // Prevent double click

    setState(() => _isSaving = true);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    try {
      final paymentRepo = Get.find<InvoicePaymentRepository>();
      await paymentRepo.recordPayment(
        invoiceId: widget.invoice.id,
        customerId: widget.invoice.customerId,
        vehicleId: widget.invoice.vehicleId,
        amount: amount,
        paymentDate: DateTime.now(),
        paymentMethod: _paymentMethod,
        referenceNumber: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      Get.back(result: true);
      Get.snackbar(
        'Payment Recorded',
        'Invoice balance updated successfully in SQLite',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Payment failed: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Collect Payment: ${widget.invoice.invoiceNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.invoice.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                            Text('Total: ${Formatters.currency(widget.invoice.grandTotal, symbol: currency)}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining Due', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                          Text(
                            Formatters.currency(widget.invoice.remainingAmount, symbol: currency),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Received Amount *', prefixIcon: Icon(Icons.attach_money_rounded)),
                  keyboardType: TextInputType.number,
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.payment_rounded)),
                  items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _refController,
                  decoration: const InputDecoration(labelText: 'Transaction Reference / Cheque # / Slip ID', prefixIcon: Icon(Icons.tag_rounded)),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Payment Notes'),
                ),
                const SizedBox(height: 24),

                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submitPayment,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Confirm Payment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
