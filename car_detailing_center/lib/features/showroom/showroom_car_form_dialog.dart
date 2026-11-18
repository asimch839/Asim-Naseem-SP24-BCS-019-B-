import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/showroom_car_model.dart';
import '../../data/repositories/showroom_repository.dart';

class ShowroomCarFormDialog extends StatefulWidget {
  final ShowroomCarModel? car;
  final bool initialIsCommission;

  const ShowroomCarFormDialog({
    super.key,
    this.car,
    this.initialIsCommission = false,
  });

  @override
  State<ShowroomCarFormDialog> createState() => _ShowroomCarFormDialogState();
}

class _ShowroomCarFormDialogState extends State<ShowroomCarFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _dealType; // 'inventory' or 'commission'
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _customerPhoneCtrl;
  late final TextEditingController _regNoCtrl;
  late final TextEditingController _carNameCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _demandCtrl; // Also used as Deal Price in commission mode
  late final TextEditingController _customerPriceCtrl;
  late final TextEditingController _commissionCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _conditionCtrl;
  late final TextEditingController _notesCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.car;
    _dealType = c?.dealType ?? (widget.initialIsCommission ? 'commission' : 'inventory');

    _customerNameCtrl = TextEditingController(text: c?.customerName ?? '');
    _customerPhoneCtrl = TextEditingController(text: c?.customerPhone ?? '');
    _regNoCtrl = TextEditingController(text: c?.registrationNumber ?? '');
    _carNameCtrl = TextEditingController(text: c?.carName ?? '');
    _modelCtrl = TextEditingController(text: c?.model ?? '');
    _demandCtrl = TextEditingController(text: c != null && c.demandPrice > 0 ? c.demandPrice.toStringAsFixed(0) : '');
    _customerPriceCtrl = TextEditingController(text: c != null && c.customerPrice > 0 ? c.customerPrice.toStringAsFixed(0) : '');
    _commissionCtrl = TextEditingController(text: c != null && c.totalCommission > 0 ? c.totalCommission.toStringAsFixed(0) : '');
    _colorCtrl = TextEditingController(text: c?.color ?? '');
    _conditionCtrl = TextEditingController(text: c?.condition ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _regNoCtrl.dispose();
    _carNameCtrl.dispose();
    _modelCtrl.dispose();
    _demandCtrl.dispose();
    _customerPriceCtrl.dispose();
    _commissionCtrl.dispose();
    _colorCtrl.dispose();
    _conditionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _demand => double.tryParse(_demandCtrl.text.trim()) ?? 0.0;
  double get _customerPrice => double.tryParse(_customerPriceCtrl.text.trim()) ?? 0.0;
  double get _commission => double.tryParse(_commissionCtrl.text.trim()) ?? 0.0;

  void _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = Get.find<ShowroomRepository>();
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    final isCommissionDeal = _dealType == 'commission';
    final price = _demand;
    final comm = _commission;

    final carModel = ShowroomCarModel(
      id: widget.car?.id ?? '',
      dealType: _dealType,
      carName: _carNameCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      registrationNumber: _regNoCtrl.text.trim().toUpperCase(),
      color: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
      condition: _conditionCtrl.text.trim().isNotEmpty ? _conditionCtrl.text.trim() : null,
      customerName: _customerNameCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      buyerName: isCommissionDeal ? _customerNameCtrl.text.trim() : widget.car?.buyerName,
      buyerPhone: isCommissionDeal ? _customerPhoneCtrl.text.trim() : widget.car?.buyerPhone,
      demandPrice: price,
      customerPrice: isCommissionDeal ? price : _customerPrice,
      soldPrice: isCommissionDeal ? price : (widget.car?.soldPrice ?? 0.0),
      saleDate: isCommissionDeal ? (widget.car?.saleDate ?? DateTime.now()) : widget.car?.saleDate,
      buyerCommission: isCommissionDeal ? comm : (widget.car?.buyerCommission ?? 0.0),
      sellerCommission: widget.car?.sellerCommission ?? 0.0,
      commissionAmount: isCommissionDeal ? comm : (widget.car?.commissionAmount ?? 0.0),
      profitAmount: isCommissionDeal ? comm : (widget.car?.isSold == true ? (widget.car?.profitAmount ?? 0.0) : 0.0),
      status: isCommissionDeal ? 'Sold' : (widget.car?.status ?? 'Available'),
      tokenAmount: widget.car?.tokenAmount ?? 0.0,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      paymentMethod: widget.car?.paymentMethod ?? 'Cash',
      isDeleted: false,
      createdAt: widget.car?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.saveCar(carModel);
      Get.back(result: true);
      if (isCommissionDeal && comm > 0) {
        Get.snackbar(
          'Commission Deal Saved & Income Added',
          '${Formatters.currency(comm, symbol: currency)} commission successfully added to business income!',
          backgroundColor: AppColors.success.withValues(alpha: 0.2),
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Success',
          widget.car == null ? 'Car record saved successfully' : 'Car record updated successfully',
          backgroundColor: AppColors.success.withValues(alpha: 0.2),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save car: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final isEdit = widget.car != null;
    final isCommissionMode = _dealType == 'commission';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isCommissionMode ? AppColors.success : AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCommissionMode ? Icons.handshake_rounded : Icons.directions_car_filled_rounded,
                      color: isCommissionMode ? AppColors.success : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? (isCommissionMode ? 'Edit Commission Deal' : 'Edit Car Details')
                              : (isCommissionMode ? 'Add Commission Deal (Brokerage)' : 'Add Showroom Car for Sale'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isCommissionMode
                              ? 'Record car procured for customer & brokerage commission'
                              : 'Enter customer & car details for showroom sale',
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

            // Form Fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deal Category Selector (Showroom Car vs Commission Deal)
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Showroom Car (For Sale)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              selected: _dealType == 'inventory',
                              selectedColor: AppColors.primary.withValues(alpha: 0.25),
                              side: BorderSide(
                                color: _dealType == 'inventory' ? AppColors.primary : AppColors.textDarkMuted.withValues(alpha: 0.3),
                              ),
                              onSelected: (_) => setState(() => _dealType = 'inventory'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Commission Deal (Brokerage)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              selected: _dealType == 'commission',
                              selectedColor: AppColors.success.withValues(alpha: 0.25),
                              side: BorderSide(
                                color: _dealType == 'commission' ? AppColors.success : AppColors.textDarkMuted.withValues(alpha: 0.3),
                              ),
                              onSelected: (_) => setState(() => _dealType = 'commission'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;

                          // 1. Customer Name & Customer Number
                          final customerNameField = TextFormField(
                            controller: _customerNameCtrl,
                            decoration: InputDecoration(
                              labelText: isCommissionMode ? 'Customer Name *' : 'Customer Name *',
                              hintText: isCommissionMode ? 'Customer who purchased vehicle' : 'e.g. Asim, Ali Khan',
                              prefixIcon: const Icon(Icons.person_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Customer name required' : null,
                          );

                          final customerPhoneField = TextFormField(
                            controller: _customerPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Customer Number *',
                              hintText: '0300-1234567',
                              prefixIcon: Icon(Icons.phone_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Customer phone required' : null,
                          );

                          // 2. Car Name & Model
                          final carNameField = TextFormField(
                            controller: _carNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Car Name *',
                              hintText: 'e.g. Corolla, Civic, Alto',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Car name required' : null,
                          );

                          final modelField = TextFormField(
                            controller: _modelCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Model *',
                              hintText: 'e.g. 2024, 2022',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Model required' : null,
                          );

                          // 3. Registration Number & Color
                          final regNoField = TextFormField(
                            controller: _regNoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reg Number (Plate #) *',
                              hintText: 'e.g. LEA-786, ICT-2022',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Reg number required' : null,
                          );

                          final colorField = TextFormField(
                            controller: _colorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Color *',
                              hintText: 'e.g. White, Black',
                              prefixIcon: Icon(Icons.palette_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Color required' : null,
                          );

                          // 5. Pricing & Commission fields
                          final priceField = TextFormField(
                            controller: _demandCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isCommissionMode ? 'Car / Deal Price ($currency) *' : 'Demand ($currency) *',
                              hintText: isCommissionMode ? 'e.g. 4200000' : 'e.g. 4500000',
                              prefixIcon: Icon(isCommissionMode ? Icons.payments_outlined : Icons.sell_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => v == null || v.trim().isEmpty ? (isCommissionMode ? 'Car price required' : 'Demand price required') : null,
                          );

                          final secondaryPriceField = isCommissionMode
                              ? TextFormField(
                                  controller: _commissionCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Commission ($currency) *',
                                    hintText: 'e.g. 30000',
                                    prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.success),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Commission required' : null,
                                )
                              : TextFormField(
                                  controller: _customerPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Price ($currency) *',
                                    hintText: 'e.g. 4200000',
                                    prefixIcon: const Icon(Icons.payments_outlined),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Customer price required' : null,
                                );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer row / col
                              if (isNarrow) ...[
                                customerNameField,
                                const SizedBox(height: 12),
                                customerPhoneField,
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(child: customerNameField),
                                    const SizedBox(width: 12),
                                    Expanded(child: customerPhoneField),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Car Name & Model
                              if (isNarrow) ...[
                                carNameField,
                                const SizedBox(height: 12),
                                modelField,
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(flex: 3, child: carNameField),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: modelField),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Reg Number & Color
                              if (isNarrow) ...[
                                regNoField,
                                const SizedBox(height: 12),
                                colorField,
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(flex: 3, child: regNoField),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: colorField),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Condition (always full width)
                              TextFormField(
                                controller: _conditionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Condition (Optional)',
                                  hintText: 'e.g. Total Genuine, 2 Pieces Touchup, Shower',
                                  prefixIcon: Icon(Icons.verified_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Pricing row / col
                              if (isNarrow) ...[
                                priceField,
                                const SizedBox(height: 12),
                                secondaryPriceField,
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(child: priceField),
                                    const SizedBox(width: 12),
                                    Expanded(child: secondaryPriceField),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // 6. Notes / Remarks
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Remarks (Optional)',
                          hintText: 'e.g. Deal terms, token status, payment info...',
                          prefixIcon: Icon(Icons.notes_rounded),
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
                    onPressed: _isSaving ? null : _saveCar,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      isEdit
                          ? 'Save Changes'
                          : (isCommissionMode ? 'Save Commission Deal' : 'Save Car Record'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCommissionMode ? AppColors.success : AppColors.primary,
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
