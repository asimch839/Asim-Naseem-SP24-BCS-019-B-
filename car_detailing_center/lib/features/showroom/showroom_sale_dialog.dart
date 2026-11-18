import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/showroom_car_model.dart';
import '../../data/repositories/showroom_repository.dart';

class ShowroomSaleDialog extends StatefulWidget {
  final ShowroomCarModel car;

  const ShowroomSaleDialog({super.key, required this.car});

  @override
  State<ShowroomSaleDialog> createState() => _ShowroomSaleDialogState();
}

class _ShowroomSaleDialogState extends State<ShowroomSaleDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _soldPriceCtrl;
  late final TextEditingController _buyerNameCtrl;
  late final TextEditingController _buyerPhoneCtrl;
  late final TextEditingController _buyerCommissionCtrl;
  late final TextEditingController _sellerCommissionCtrl;
  late final TextEditingController _buyerCnicCtrl;
  late final TextEditingController _notesCtrl;

  DateTime _saleDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.car;
    final initialSold = c.soldPrice > 0 ? c.soldPrice : c.demandPrice;
    _soldPriceCtrl = TextEditingController(text: initialSold > 0 ? initialSold.toStringAsFixed(0) : '');
    _buyerNameCtrl = TextEditingController(text: c.buyerName ?? '');
    _buyerPhoneCtrl = TextEditingController(text: c.buyerPhone ?? '');
    _buyerCommissionCtrl = TextEditingController(
      text: c.buyerCommission > 0 ? c.buyerCommission.toStringAsFixed(0) : '',
    );
    _sellerCommissionCtrl = TextEditingController(
      text: c.sellerCommission > 0 ? c.sellerCommission.toStringAsFixed(0) : '',
    );
    _buyerCnicCtrl = TextEditingController(text: c.buyerCnic ?? '');
    _notesCtrl = TextEditingController(text: c.notes ?? '');
    _saleDate = c.saleDate ?? DateTime.now();
    _paymentMethod = c.paymentMethod;
  }

  @override
  void dispose() {
    _soldPriceCtrl.dispose();
    _buyerNameCtrl.dispose();
    _buyerPhoneCtrl.dispose();
    _buyerCommissionCtrl.dispose();
    _sellerCommissionCtrl.dispose();
    _buyerCnicCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _soldPrice => double.tryParse(_soldPriceCtrl.text.trim()) ?? 0.0;
  double get _buyerCommission => double.tryParse(_buyerCommissionCtrl.text.trim()) ?? 0.0;
  double get _sellerCommission => double.tryParse(_sellerCommissionCtrl.text.trim()) ?? 0.0;
  double get _totalCommission => _buyerCommission + _sellerCommission;

  void _completeSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = Get.find<ShowroomRepository>();

    try {
      final ok = await repo.markAsSold(
        id: widget.car.id,
        soldPrice: _soldPrice > 0 ? _soldPrice : widget.car.demandPrice,
        buyerName: _buyerNameCtrl.text.trim(),
        buyerPhone: _buyerPhoneCtrl.text.trim(),
        buyerCnic: _buyerCnicCtrl.text.trim().isNotEmpty ? _buyerCnicCtrl.text.trim() : null,
        saleDate: _saleDate,
        buyerCommission: _buyerCommission,
        sellerCommission: _sellerCommission,
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );

      if (ok) {
        Get.back(result: true);
        final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
        Get.snackbar(
          'Deal Finalized & Commission Added',
          'Car marked as SOLD! ${Formatters.currency(_totalCommission, symbol: currency)} commission added to business income.',
          backgroundColor: AppColors.success.withValues(alpha: 0.2),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to finalize sale: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handshake_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark Car as Sold (Deal Finalization)',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.car.displayName} • ${widget.car.registrationNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car & Seller Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 420;
                            final carInfoCol = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.car.registrationNumber}${widget.car.color != null && widget.car.color!.isNotEmpty ? " • ${widget.car.color}" : ""}${widget.car.condition != null && widget.car.condition!.isNotEmpty ? " (${widget.car.condition})" : ""}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Seller: ${widget.car.customerName} (${widget.car.customerPhone})',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                ),
                              ],
                            );

                            final priceCol = Column(
                              crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Customer Price: ${Formatters.currency(widget.car.customerPrice, symbol: currency)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                ),
                                Text(
                                  'Demand: ${Formatters.currency(widget.car.demandPrice, symbol: currency)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                ),
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  carInfoCol,
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 6),
                                  priceCol,
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: carInfoCol),
                                const SizedBox(width: 10),
                                priceCol,
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Final Sold Price
                      TextFormField(
                        controller: _soldPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Final Sold / Deal Price ($currency) *',
                          hintText: 'e.g. 4300000',
                          prefixIcon: const Icon(Icons.payments_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Sold price required' : null,
                      ),
                      const SizedBox(height: 16),

                      // 1. Buyer Information Section
                      const Text(
                        'Buyer / Purchaser Details *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buyerNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Buyer Name *',
                                hintText: 'Enter buyer full name',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Buyer name required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _buyerPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Buyer Phone Number *',
                                hintText: '0300-xxxxxxx',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Buyer phone required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Commissions Section
                      const Text(
                        'Dealership Commissions *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buyerCommissionCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Buyer Commission ($currency)',
                                hintText: 'e.g. 25000',
                                prefixIcon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.success),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sellerCommissionCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Seller Commission ($currency)',
                                hintText: 'e.g. 25000',
                                prefixIcon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.success),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Commission Earned Card (Added directly to business income)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Deal Commission:', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                                Text(
                                  Formatters.currency(_totalCommission, symbol: currency),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.success),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, color: AppColors.success, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Added to Business Income',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Method & Date
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.payment_rounded)),
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer / Online')),
                                DropdownMenuItem(value: 'Cheque / Pay Order', child: Text('Cheque / Pay Order')),
                              ],
                              onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _saleDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (picked != null) setState(() => _saleDate = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Sale Date',
                                  prefixIcon: Icon(Icons.calendar_today_rounded),
                                ),
                                child: Text(DateFormat('dd MMM yyyy').format(_saleDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Optional Buyer CNIC & Notes
                      TextFormField(
                        controller: _buyerCnicCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buyer CNIC (Optional)',
                          hintText: '35202-xxxxxxx-x',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Sale Notes / Transfer Remarks (Optional)',
                          hintText: 'Biometric status, token adjustment, guarantee notes...',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _completeSale,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Confirm Sale & Add to Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
