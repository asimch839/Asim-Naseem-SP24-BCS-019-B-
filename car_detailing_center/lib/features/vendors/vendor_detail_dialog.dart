import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vendor_model.dart';
import '../../data/repositories/vendor_repository.dart';
import '../expenses/garage_expense_screen.dart';
import 'vendor_form_dialog.dart';

class VendorDetailDialog extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailDialog({super.key, required this.vendor});

  @override
  State<VendorDetailDialog> createState() => _VendorDetailDialogState();
}

class _VendorDetailDialogState extends State<VendorDetailDialog> {
  final _vendorRepo = Get.find<VendorRepository>();
  late VendorModel _vendor;
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoadingExpenses = true);
    final list = await _vendorRepo.getVendorExpenses(_vendor.name, company: _vendor.company);
    if (mounted) {
      setState(() {
        _expenses = list;
        _isLoadingExpenses = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      '$label copied to clipboard',
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      colorText: AppColors.primaryLight,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Delete Vendor',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: 'Are you sure you want to remove ${_vendor.name} (${_vendor.company ?? "Vendor"})? This cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back(); // close confirm dialog
        await _vendorRepo.deleteVendor(_vendor.id);
        Get.back(result: true); // close detail dialog
        Get.snackbar(
          'Deleted',
          'Vendor removed successfully',
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          colorText: AppColors.error,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final totalSpend = _expenses.fold<double>(
      0.0,
      (acc, exp) => acc + ((exp['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      _vendor.name.isNotEmpty ? _vendor.name[0].toUpperCase() : 'V',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vendor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_vendor.company != null && _vendor.company!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: AppColors.primaryLight),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _vendor.company!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDarkSecondary, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
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

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(_vendor.phone, 'Phone number'),
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: Text(_vendor.phone),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (_) => GarageExpenseFormDialog(
                                  prefillVendorName: _vendor.name,
                                  prefillVendorCompany: _vendor.company,
                                  prefillVendorPhone: _vendor.phone,
                                ),
                              );
                              if (res == true) _loadExpenses();
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Log Expense'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (_) => VendorFormDialog(existing: _vendor),
                              );
                              if (res == true) {
                                final updated = await _vendorRepo.getVendorById(_vendor.id);
                                if (updated != null && mounted) {
                                  setState(() => _vendor = updated);
                                }
                              }
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            onPressed: _confirmDelete,
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4 Clean Vendor Fields Profile
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.badge_rounded, size: 16, color: AppColors.primaryLight),
                                SizedBox(width: 8),
                                Text(
                                  'VENDOR DETAILS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _detailRow('Person Name', _vendor.name, Icons.person_rounded),
                            _detailRow('Shop Name', _vendor.company ?? '-', Icons.storefront_rounded),
                            _detailRow('Phone Number', _vendor.phone, Icons.phone_rounded),
                            _detailRow('Description', _vendor.notes ?? 'No description provided', Icons.description_rounded),
                            _detailRow('Added On', Formatters.date(_vendor.createdAt), Icons.calendar_today_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Spend & Transaction History
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Total Invoiced Spend',
                            value: Formatters.currency(totalSpend, symbol: currency),
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _statCard(
                            title: 'Expenses Recorded',
                            value: '${_expenses.length}',
                            icon: Icons.history_rounded,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'LOGGED EXPENSES WITH THIS VENDOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _isLoadingExpenses
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _expenses.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderDark),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No expenses recorded under this vendor yet.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textDarkMuted),
                                  ),
                                ),
                              )
                            : Card(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _expenses.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final exp = _expenses[index];
                                    final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
                                    final title = exp['title'] as String? ?? 'Expense';
                                    final category = exp['category'] as String? ?? 'General';
                                    final dateStr = exp['date'] as String?;
                                    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.primaryLight),
                                      ),
                                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      subtitle: Text(
                                        '$category • ${date != null ? Formatters.date(date) : '-'}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                                      ),
                                      trailing: Text(
                                        Formatters.currency(amount, symbol: currency),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.info),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textDarkMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
