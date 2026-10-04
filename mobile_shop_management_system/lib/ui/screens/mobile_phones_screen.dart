import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/models/phone_item.dart';
import '../../core/models/supplier.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class MobilePhonesScreen extends StatefulWidget {
  const MobilePhonesScreen({super.key});

  @override
  State<MobilePhonesScreen> createState() => _MobilePhonesScreenState();
}

class _MobilePhonesScreenState extends State<MobilePhonesScreen> {
  final TextEditingController _imeiSearchCtrl = TextEditingController();
  String _selectedStatus = 'All'; // 'All', 'In Stock', 'Sold', 'Returned'
  String _selectedCondition = 'All'; // 'All', 'New', 'Used', 'Refurbished'

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final led = context.watch<LedgerProvider>();
    final rep = context.watch<RepairProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _imeiSearchCtrl.text.trim().toLowerCase();

    final phones = inv.phones.where((ph) {
      if (_selectedStatus != 'All' && ph.status != _selectedStatus) return false;
      if (_selectedCondition != 'All' && ph.condition != _selectedCondition) return false;

      if (q.isNotEmpty) {
        final matches = ph.imei1.contains(q) ||
            ph.imei2.contains(q) ||
            ph.brand.toLowerCase().contains(q) ||
            ph.model.toLowerCase().contains(q) ||
            ph.serialNumber.toLowerCase().contains(q) ||
            ph.color.toLowerCase().contains(q) ||
            (ph.customerName?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList();

    final inStockCount = inv.phones.where((p) => p.status == 'In Stock').length;
    final soldCount = inv.phones.where((p) => p.status == 'Sold').length;

    return Scaffold(
      body: Padding(
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
                    const Text('Mobile Phones & IMEI Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Individual handset tracking with Dual IMEI, PTA status, and full traceability', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_to_photos_rounded, size: 16),
                  label: const Text('+ Add Phone Unit'),
                  onPressed: () => _showAddPhoneDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Metrics Summary Row
            Row(
              children: [
                _summaryChip('In Shop Stock', '$inStockCount Handsets', AppTheme.primaryBlue, const Color(0xFFE0F2FE)),
                const SizedBox(width: 12),
                _summaryChip('Sold Units', '$soldCount Handsets', AppTheme.successGreen, const Color(0xFFDCFCE7)),
                const SizedBox(width: 12),
                _summaryChip('Total Tracked IMEIs', '${inv.phones.length * 2} (Dual SIM)', const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
              ],
            ),

            const SizedBox(height: 16),

            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imeiSearchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search 15-digit IMEI, Brand, Model, Serial, or Customer Name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _imeiSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _imeiSearchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                      DropdownMenuItem(value: 'Sold', child: Text('Sold')),
                      DropdownMenuItem(value: 'Reserved', child: Text('Reserved')),
                      DropdownMenuItem(value: 'Returned', child: Text('Returned')),
                    ],
                    onChanged: (v) => setState(() => _selectedStatus = v!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    decoration: const InputDecoration(labelText: 'Condition'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Conditions')),
                      DropdownMenuItem(value: 'New', child: Text('New (Box Pack)')),
                      DropdownMenuItem(value: 'Used', child: Text('Used / Mint')),
                      DropdownMenuItem(value: 'Refurbished', child: Text('Refurbished')),
                    ],
                    onChanged: (v) => setState(() => _selectedCondition = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Phones Table
            Expanded(
              child: Card(
                child: phones.isEmpty
                    ? const Center(child: Text('No mobile phones match the filter criteria.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Handset / Model')),
                              DataColumn(label: Text('Primary IMEI 1')),
                              DataColumn(label: Text('IMEI 2 / Serial')),
                              DataColumn(label: Text('PTA Status')),
                              DataColumn(label: Text('Condition')),
                              DataColumn(label: Text('Cost Price')),
                              DataColumn(label: Text('Sale Price')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Traceability / Lifecycle')),
                            ],
                            rows: phones.map((ph) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('${ph.brand} ${ph.model}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('${ph.variant.isNotEmpty ? ph.variant : '${ph.ram}/${ph.storage}'} • ${ph.color}', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    SelectableText(
                                      ph.imei1,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      ph.imei2.isNotEmpty ? ph.imei2 : (ph.serialNumber.isNotEmpty ? 'S/N: ${ph.serialNumber}' : '-'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ph.ptaStatus == 'PTA Approved'
                                            ? AppTheme.successGreen.withOpacity(0.12)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ph.ptaStatus,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: ph.ptaStatus == 'PTA Approved' ? AppTheme.successGreen : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(ph.condition)),
                                  DataCell(Text(AppFormatters.currency(ph.purchasePrice))),
                                  DataCell(Text(AppFormatters.currency(ph.salePrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ph.status == 'In Stock'
                                            ? AppTheme.primaryBlue.withOpacity(0.12)
                                            : (ph.status == 'Sold' ? AppTheme.successGreen.withOpacity(0.12) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ph.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: ph.status == 'In Stock'
                                              ? AppTheme.primaryBlue
                                              : (ph.status == 'Sold' ? AppTheme.successGreen : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.history_rounded, size: 14),
                                      label: const Text('Trace History'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11),
                                      ),
                                      onPressed: () => _showTraceabilityDialog(context, ph, rep),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  void _showTraceabilityDialog(BuildContext context, PhoneItem ph, RepairProvider rep) {
    // Check if device has any repairs in lab
    final repairs = rep.repairs.where((r) => r.imei == ph.imei1 || (ph.imei2.isNotEmpty && r.imei == ph.imei2)).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('Complete Traceability (${ph.brand} ${ph.model})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _traceRow('IMEI 1 (Unique):', ph.imei1, isBold: true),
                if (ph.imei2.isNotEmpty) _traceRow('IMEI 2:', ph.imei2),
                if (ph.serialNumber.isNotEmpty) _traceRow('Serial Number:', ph.serialNumber),
                _traceRow('Color / Variant:', '${ph.color} • ${ph.variant}'),
                _traceRow('PTA Status:', ph.ptaStatus),
                _traceRow('Condition:', ph.condition),
                _traceRow('Warranty:', ph.warrantyPeriod),
                const Divider(height: 20),

                // Source
                const Text('SOURCING & PROCUREMENT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                const SizedBox(height: 4),
                _traceRow('Supplier:', ph.supplierName.isNotEmpty ? ph.supplierName : 'Wholesale Market'),
                _traceRow('Purchase Date:', AppFormatters.date(ph.purchaseDate)),
                _traceRow('Purchase Cost Price:', AppFormatters.currency(ph.purchasePrice)),
                const Divider(height: 20),

                // Sale History
                const Text('SALES & CURRENT DISPOSITION:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                const SizedBox(height: 4),
                _traceRow('Current Status:', ph.status, isBold: true),
                if (ph.status == 'Sold') ...[
                  _traceRow('Sold To Customer:', ph.customerName ?? 'Walk-in'),
                  _traceRow('Sale Invoice Number:', '#${ph.saleInvoiceNumber ?? "-"}'),
                  _traceRow('Sold Date:', AppFormatters.date(ph.soldDate)),
                  _traceRow('Sale Price:', AppFormatters.currency(ph.salePrice)),
                  _traceRow('Product Margin:', AppFormatters.currency(ph.salePrice - ph.purchasePrice), color: AppTheme.successGreen),
                ] else
                  const Text('Device is currently available in shop stock ready for sale.', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),

                const Divider(height: 20),

                // Lab Repair History
                const Text('LAB REPAIR & SERVICE HISTORY:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                const SizedBox(height: 4),
                if (repairs.isEmpty)
                  const Text('No repair jobs recorded for this device IMEI.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...repairs.map((r) {
                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Job #${r.jobId} • ${r.status.displayName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Problem: ${r.reportedProblem}', style: const TextStyle(fontSize: 11)),
                          Text('Date: ${AppFormatters.date(r.createdAt)} • Cost: ${AppFormatters.currency(r.finalTotal)}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _traceRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(width: 170, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color))),
        ],
      ),
    );
  }

  void _showAddPhoneDialog(BuildContext context) {
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final variantCtrl = TextEditingController(text: '8GB / 256GB');
    final colorCtrl = TextEditingController();
    final imei1Ctrl = TextEditingController();
    final imei2Ctrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final warrantyCtrl = TextEditingController(text: '1 Year Official');

    String ptaStatus = 'PTA Approved';
    String condition = 'New';
    Supplier? selectedSup;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final led = ctx.read<LedgerProvider>();
          final inv = ctx.read<InventoryProvider>();

          return AlertDialog(
            title: const Text('Add Mobile Phone Handset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand (e.g. Samsung, Apple) *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model Name *'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: variantCtrl, decoration: const InputDecoration(labelText: 'RAM / Storage Variant'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Color'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ptaStatus,
                            decoration: const InputDecoration(labelText: 'PTA Status *'),
                            items: const [
                              DropdownMenuItem(value: 'PTA Approved', child: Text('PTA Approved')),
                              DropdownMenuItem(value: 'Non-PTA', child: Text('Non-PTA')),
                              DropdownMenuItem(value: 'CPID Approved', child: Text('CPID Approved')),
                              DropdownMenuItem(value: 'JV / Gevey', child: Text('JV / Gevey')),
                            ],
                            onChanged: (v) => setState(() => ptaStatus = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: condition,
                            decoration: const InputDecoration(labelText: 'Condition *'),
                            items: const [
                              DropdownMenuItem(value: 'New', child: Text('New (Box Pack)')),
                              DropdownMenuItem(value: 'Used', child: Text('Used / Mint')),
                              DropdownMenuItem(value: 'Refurbished', child: Text('Refurbished')),
                            ],
                            onChanged: (v) => setState(() => condition = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: imei1Ctrl, decoration: const InputDecoration(labelText: 'IMEI 1 (15 Digits) *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: imei2Ctrl, decoration: const InputDecoration(labelText: 'IMEI 2 (Optional)'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Purchase Cost (Rs.) *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail Sale Price (Rs.) *'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Supplier>(
                            value: selectedSup,
                            decoration: const InputDecoration(labelText: 'Sourced From Supplier'),
                            items: led.suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                            onChanged: (s) => setState(() => selectedSup = s),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Warranty Term'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (brandCtrl.text.isEmpty || modelCtrl.text.isEmpty || imei1Ctrl.text.isEmpty) return;

                  final existing = await inv.findByImei(imei1Ctrl.text.trim());
                  if (existing != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: This IMEI 1 already exists in the system!')),
                    );
                    return;
                  }

                  final phone = PhoneItem(
                    id: 'PHN-${DateTime.now().millisecondsSinceEpoch}',
                    brand: brandCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                    variant: variantCtrl.text.trim(),
                    color: colorCtrl.text.trim(),
                    ptaStatus: ptaStatus,
                    imei1: imei1Ctrl.text.trim(),
                    imei2: imei2Ctrl.text.trim(),
                    serialNumber: serialCtrl.text.trim(),
                    purchasePrice: double.tryParse(costCtrl.text) ?? 0.0,
                    salePrice: double.tryParse(priceCtrl.text) ?? 0.0,
                    supplierId: selectedSup?.id ?? '',
                    supplierName: selectedSup?.name ?? '',
                    warrantyPeriod: warrantyCtrl.text.trim(),
                    condition: condition,
                    status: 'In Stock',
                  );

                  await inv.addPhoneItem(phone);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Handset'),
              ),
            ],
          );
        },
      ),
    );
  }
}
