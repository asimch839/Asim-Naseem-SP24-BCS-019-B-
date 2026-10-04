import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/models/warranty.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = led.warranties.where((w) {
      if (q.isNotEmpty) {
        final matches = w.itemName.toLowerCase().contains(q) ||
            w.imei.contains(q) ||
            w.customerName.toLowerCase().contains(q) ||
            w.customerPhone.contains(q) ||
            w.referenceId.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    final activeWarranties = filtered.where((w) => !w.isExpired).toList();
    final expiringSoon = filtered.where((w) => w.isExpiringSoon).toList();
    final expiredWarranties = filtered.where((w) => w.isExpired).toList();
    final claimedWarranties = filtered.where((w) => w.claims.isNotEmpty).toList();

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
                    const Text('Warranty Management & Claims Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Track official and shop warranties for sold phones, accessories, and lab repair services', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_moderator_rounded, size: 16),
                  label: const Text('+ File Warranty Claim'),
                  onPressed: () => _showFileClaimDialog(context, led),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by IMEI, Item Name, Customer Phone, or Invoice/Job #...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Tabs Header
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: AppTheme.primaryBlue,
              tabs: [
                Tab(text: 'Active Warranties (${activeWarranties.length})'),
                Tab(text: 'Expiring Soon [15 Days] (${expiringSoon.length})'),
                Tab(text: 'Expired (${expiredWarranties.length})'),
                Tab(text: 'Warranty Claims Filed (${claimedWarranties.length})'),
              ],
            ),

            const SizedBox(height: 12),

            // Table Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWarrantyTable(context, activeWarranties, led, isDark),
                  _buildWarrantyTable(context, expiringSoon, led, isDark),
                  _buildWarrantyTable(context, expiredWarranties, led, isDark),
                  _buildWarrantyTable(context, claimedWarranties, led, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyTable(BuildContext context, List<WarrantyRecord> list, LedgerProvider led, bool isDark) {
    return Card(
      child: list.isEmpty
          ? const Center(child: Text('No warranty records in this status.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Item / Device')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('IMEI / Serial')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Reference #')),
                    DataColumn(label: Text('Start Date')),
                    DataColumn(label: Text('Expiry Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list.map((w) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(w.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(w.warrantyTerms, style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        DataCell(Text(w.type.toUpperCase())),
                        DataCell(
                          Text(
                            w.imei.isNotEmpty ? w.imei : '-',
                            style: TextStyle(fontWeight: w.imei.isNotEmpty ? FontWeight.bold : FontWeight.normal, color: AppTheme.primaryBlue),
                          ),
                        ),
                        DataCell(Text('${w.customerName}\n${w.customerPhone}', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(w.referenceId, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(AppFormatters.date(w.startDate))),
                        DataCell(
                          Text(
                            AppFormatters.date(w.endDate),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: w.isExpired ? AppTheme.dangerRed : (w.isExpiringSoon ? AppTheme.warningOrange : null),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: w.isExpired
                                  ? AppTheme.dangerRed.withOpacity(0.12)
                                  : (w.isExpiringSoon ? AppTheme.warningOrange.withOpacity(0.12) : AppTheme.successGreen.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              w.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: w.isExpired ? AppTheme.dangerRed : (w.isExpiringSoon ? AppTheme.warningOrange : AppTheme.successGreen),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            onPressed: () => _showClaimModal(context, w, led),
                            child: const Text('Claim / Details', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  void _showClaimModal(BuildContext context, WarrantyRecord w, LedgerProvider led) {
    final issueCtrl = TextEditingController();
    final resolutionCtrl = TextEditingController();
    String claimStatus = 'Approved';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Warranty Details & Claims (${w.itemName})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${w.customerName} (${w.customerPhone})'),
                if (w.imei.isNotEmpty) Text('IMEI: ${w.imei}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                Text('Valid From: ${AppFormatters.date(w.startDate)} to ${AppFormatters.date(w.endDate)}'),
                Text('Terms: ${w.warrantyTerms}'),
                const Divider(height: 20),
                const Text('EXISTING CLAIMS ON THIS WARRANTY:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                const SizedBox(height: 6),
                if (w.claims.isEmpty)
                  const Text('No prior warranty claims filed.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...w.claims.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Claimed on: ${AppFormatters.date(c.claimDate)} • Status: ${c.status}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Issue: ${c.reportedIssue}', style: const TextStyle(fontSize: 11.5)),
                          if (c.resolution.isNotEmpty) Text('Resolution: ${c.resolution}', style: const TextStyle(fontSize: 11, color: AppTheme.successGreen)),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 20),
                const Text('FILE NEW CLAIM:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                const SizedBox(height: 8),
                TextField(controller: issueCtrl, decoration: const InputDecoration(labelText: 'Fault / Issue Reported *')),
                const SizedBox(height: 8),
                TextField(controller: resolutionCtrl, decoration: const InputDecoration(labelText: 'Lab Resolution / Replacement details')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: claimStatus,
                  decoration: const InputDecoration(labelText: 'Claim Decision'),
                  items: const [
                    DropdownMenuItem(value: 'Approved', child: Text('Approved (Free Repair / Replacement)')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending Lab Inspection')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected (Physical / Water Damage)')),
                  ],
                  onChanged: (v) => claimStatus = v!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            onPressed: () async {
              if (issueCtrl.text.isEmpty) return;

              await led.addWarrantyClaim(
                warrantyId: w.id,
                issue: issueCtrl.text.trim(),
                resolution: resolutionCtrl.text.trim(),
                status: claimStatus,
                technicianNotes: 'Processed at warranty desk',
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Warranty claim processed successfully!')),
              );
            },
            child: const Text('Submit Claim'),
          ),
        ],
      ),
    );
  }

  void _showFileClaimDialog(BuildContext context, LedgerProvider led) {
    if (led.warranties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active warranties registered yet.')),
      );
      return;
    }
    _showClaimModal(context, led.warranties.first, led);
  }
}
