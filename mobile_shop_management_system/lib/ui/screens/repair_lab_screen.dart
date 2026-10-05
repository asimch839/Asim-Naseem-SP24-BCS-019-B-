import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/repair_job.dart';
import '../../core/models/product.dart';
import '../../core/services/print_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class RepairLabScreen extends StatefulWidget {
  const RepairLabScreen({super.key});

  @override
  State<RepairLabScreen> createState() => _RepairLabScreenState();
}

class _RepairLabScreenState extends State<RepairLabScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isKanbanView = true;
  RepairStatus? _selectedStatus;
  String _selectedTechnician = 'All';

  @override
  Widget build(BuildContext context) {
    final rep = context.watch<RepairProvider>();
    final inv = context.watch<InventoryProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = rep.repairs.where((r) {
      if (_selectedStatus != null && r.status != _selectedStatus) return false;
      if (_selectedTechnician != 'All' && r.technicianName != _selectedTechnician) return false;
      if (q.isNotEmpty) {
        final matches = r.jobId.toLowerCase().contains(q) ||
            r.customerName.toLowerCase().contains(q) ||
            r.customerPhone.contains(q) ||
            r.deviceBrand.toLowerCase().contains(q) ||
            r.deviceModel.toLowerCase().contains(q) ||
            r.imei.contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

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
                    const Text('Mobile Repairing Lab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Hardware diagnostics, parts consumption, job cards, and workflow tracking', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    // View Toggle
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Workflow Board'), icon: Icon(Icons.view_kanban_rounded, size: 16)),
                        ButtonSegment(value: false, label: Text('Table List'), icon: Icon(Icons.table_rows_rounded, size: 16)),
                      ],
                      selected: {_isKanbanView},
                      onSelectionChanged: (set) => setState(() => _isKanbanView = set.first),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purpleRepair),
                      icon: const Icon(Icons.build_rounded, size: 16),
                      label: const Text('+ New Repair Job (F4)'),
                      onPressed: () => AppDialogs.showNewRepairDialog(context),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search Job ID (#REP-1001), Customer, IMEI, or Device Model...',
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
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<RepairStatus?>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status Filter'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses', overflow: TextOverflow.ellipsis)),
                      ...RepairStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (s) => setState(() => _selectedStatus = s),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _selectedTechnician,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Technician'),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Technicians', overflow: TextOverflow.ellipsis)),
                      ...app.allUsers.map((u) {
                        return DropdownMenuItem(value: u.name, child: Text('${u.name} (${u.role.displayName})', overflow: TextOverflow.ellipsis));
                      }),
                    ],
                    onChanged: (v) => setState(() => _selectedTechnician = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main Display: Kanban Board or Table
            Expanded(
              child: _isKanbanView
                  ? _buildKanbanBoard(context, rep, inv, app, isDark)
                  : _buildTableView(context, filtered, inv, rep, app, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Kanban Board Layout
  Widget _buildKanbanBoard(
    BuildContext context,
    RepairProvider rep,
    InventoryProvider inv,
    AppProvider app,
    bool isDark,
  ) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _buildKanbanColumn('Received Intake', rep.receivedJobs, const Color(0xFF3B82F6), const Color(0xFFDBEAFE), context, rep, inv, app, isDark),
        _buildKanbanColumn('Under Inspection', rep.inspectionJobs, const Color(0xFF6366F1), const Color(0xFFE0E7FF), context, rep, inv, app, isDark),
        _buildKanbanColumn('In Progress & Repairing', rep.inProgressJobs, const Color(0xFFD97706), const Color(0xFFFEF3C7), context, rep, inv, app, isDark),
        _buildKanbanColumn('Waiting for Parts / Customer', rep.waitingForPartsJobs, const Color(0xFFEA580C), const Color(0xFFFFEDD5), context, rep, inv, app, isDark),
        _buildKanbanColumn('Ready for Delivery', rep.readyJobs, const Color(0xFF059669), const Color(0xFFD1FAE5), context, rep, inv, app, isDark),
        _buildKanbanColumn('Delivered to Customer', rep.deliveredJobs, const Color(0xFF16A34A), const Color(0xFFDCFCE7), context, rep, inv, app, isDark),
      ],
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<RepairJob> jobs,
    Color headerColor,
    Color badgeBg,
    BuildContext context,
    RepairProvider rep,
    InventoryProvider inv,
    AppProvider app,
    bool isDark,
  ) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: headerColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                  child: Text('${jobs.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: headerColor)),
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text('No jobs in this phase', style: TextStyle(fontSize: 11.5, color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: jobs.length,
                    itemBuilder: (context, idx) {
                      final job = jobs[idx];
                      return _buildJobCard(context, job, rep, inv, app, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    RepairJob job,
    RepairProvider rep,
    InventoryProvider inv,
    AppProvider app,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showJobDetailsDialog(context, job, rep, inv, app),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.jobId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.purpleRepair)),
                  Text(AppFormatters.date(job.createdAt), style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${job.deviceBrand} ${job.deviceModel}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'Customer: ${job.customerName}',
                style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  'Problem: ${job.reportedProblem}',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Final: ${AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      if (job.remainingDue > 0)
                        Text('Due: ${AppFormatters.currency(job.remainingDue)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed))
                      else
                        const Text('Fully Paid', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Print Job Card',
                    icon: const Icon(Icons.print_rounded, size: 18, color: AppTheme.primaryBlue),
                    onPressed: () => PrintService.printRepairJobCard(job: job, settings: app.settings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Table View
  Widget _buildTableView(
    BuildContext context,
    List<RepairJob> jobs,
    InventoryProvider inv,
    RepairProvider rep,
    AppProvider app,
    bool isDark,
  ) {
    return Card(
      child: jobs.isEmpty
          ? const Center(child: Text('No repair jobs found.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Job ID')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Device & IMEI')),
                    DataColumn(label: Text('Reported Problem')),
                    DataColumn(label: Text('Technician')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Final Cost')),
                    DataColumn(label: Text('Remaining Due')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: jobs.map((job) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(job.jobId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.purpleRepair)),
                          onTap: () => _showJobDetailsDialog(context, job, rep, inv, app),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(job.customerPhone, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${job.deviceBrand} ${job.deviceModel}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (job.imei.isNotEmpty)
                                Text('IMEI: ${job.imei}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Text(job.reportedProblem, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        DataCell(Text(job.technicianName)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleRepair.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(job.status.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleRepair)),
                          ),
                        ),
                        DataCell(Text(AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          job.remainingDue > 0
                              ? Text(AppFormatters.currency(job.remainingDue), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))
                              : const Text('Fully Cleared', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Job Card Details & Status Update',
                                icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primaryBlue),
                                onPressed: () => _showJobDetailsDialog(context, job, rep, inv, app),
                              ),
                              IconButton(
                                tooltip: 'Print Job Card',
                                icon: const Icon(Icons.print_rounded, size: 18),
                                onPressed: () => PrintService.printRepairJobCard(job: job, settings: app.settings),
                              ),
                            ],
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

  // Job Details & Status Lifecycle Modal
  void _showJobDetailsDialog(
    BuildContext context,
    RepairJob job,
    RepairProvider rep,
    InventoryProvider inv,
    AppProvider app,
  ) {
    bool revealPassword = false;
    RepairStatus nextStatus = job.status;
    final statusNotesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.build_circle_rounded, color: AppTheme.purpleRepair),
                    const SizedBox(width: 8),
                    Text('Repair Job #${job.jobId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text('Created: ${AppFormatters.dateTime(job.createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer & Device Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CUSTOMER:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                              Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('Phone: ${job.customerPhone}'),
                              if (job.customerAltPhone.isNotEmpty) Text('Alt: ${job.customerAltPhone}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEVICE DETAILS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                              Text('${job.deviceBrand} ${job.deviceModel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              if (job.imei.isNotEmpty) Text('IMEI: ${job.imei}'),
                              Text('Condition: ${job.deviceCondition}'),
                              Text('Accessories: ${job.accessoriesReceived}'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Problem & Password PIN (Masked with toggle!)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Problem Reported: ${job.reportedProblem}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('Device Lock PIN / Pattern: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF92400E))),
                              Text(
                                revealPassword ? (job.lockPinOrPassword.isNotEmpty ? job.lockPinOrPassword : 'None') : '••••••••',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: Color(0xFF92400E)),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => setState(() => revealPassword = !revealPassword),
                                child: Icon(revealPassword ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFF92400E)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Parts Used in this repair
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PARTS CONSUMED FROM INVENTORY:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                        TextButton.icon(
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                          label: const Text('Add Part (+)', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showAddPartDialog(context, job, rep, inv, app),
                        ),
                      ],
                    ),
                    if (job.partsUsed.isEmpty)
                      const Text('No replacement parts attached yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      ...job.partsUsed.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${p.quantity}x ${p.partName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              Text(AppFormatters.currency(p.totalSellingPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ],
                          ),
                        );
                      }),

                    const Divider(height: 20),

                    // Cost Calculation Breakdown
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Labor Charges:'),
                              Text(AppFormatters.currency(job.laborCharges), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Parts Total:'),
                              Text(AppFormatters.currency(job.partsTotalSelling), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (job.discount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:'),
                                Text('- ${AppFormatters.currency(job.discount)}', style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Final Total Repair Cost:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Advance Deposit Paid:'),
                              Text(AppFormatters.currency(job.advancePaid), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Balance Due from Customer:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                              Text(AppFormatters.currency(job.remainingDue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.dangerRed)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status Transition Action
                    const Text('UPDATE REPAIR STATUS (12 WORKFLOW PHASES):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<RepairStatus>(
                            value: nextStatus,
                            decoration: const InputDecoration(labelText: 'New Status'),
                            items: RepairStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                            onChanged: (s) => setState(() => nextStatus = s!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await rep.updateRepairStatus(
                              repairId: job.id,
                              newStatus: nextStatus,
                              changedBy: app.currentUser.name,
                              notes: statusNotesCtrl.text.trim(),
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Job #${job.jobId} updated to "${nextStatus.displayName}"!')),
                            );
                          },
                          child: const Text('Save Status'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: statusNotesCtrl,
                      decoration: const InputDecoration(labelText: 'Status Transition Note (e.g. OLED replaced, tested OK)'),
                    ),

                    if (job.status == RepairStatus.readyForDelivery && job.remainingDue > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ready for Delivery!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                Text('Remaining due: ${AppFormatters.currency(job.remainingDue)}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('Collect & Deliver Device'),
                              onPressed: () async {
                                await rep.deliverAndSettle(
                                  repairId: job.id,
                                  paymentAmount: job.remainingDue,
                                  paymentMethod: 'Cash',
                                  deliveredBy: app.currentUser.name,
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Device delivered for #${job.jobId} and remaining balance cleared!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Status History Audit Trail
                    const Text('STATUS TIMELINE & AUDIT HISTORY:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    ...job.history.map((h) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${AppFormatters.dateTime(h.timestamp)}: [${h.status.displayName}] by ${h.changedBy} ${h.notes.isNotEmpty ? "- ${h.notes}" : ""}',
                          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Print Job Card'),
                onPressed: () => PrintService.printRepairJobCard(job: job, settings: app.settings),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPartDialog(
    BuildContext context,
    RepairJob job,
    RepairProvider rep,
    InventoryProvider inv,
    AppProvider app,
  ) {
    Product? selectedPart;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    final parts = inv.products.where((p) => p.type == ProductType.part || p.category.contains('Screen') || p.category.contains('Battery')).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Attach Replacement Part from Stock'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Product>(
                    value: selectedPart,
                    decoration: const InputDecoration(labelText: 'Select Part *'),
                    items: parts.map((p) {
                      return DropdownMenuItem(value: p, child: Text('${p.name} (Stock: ${p.stockQuantity})'));
                    }).toList(),
                    onChanged: (p) {
                      if (p != null) {
                        setState(() {
                          selectedPart = p;
                          priceCtrl.text = p.salePrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity Consumed'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Selling Price to Customer (Rs.)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedPart == null) return;
                  final q = int.tryParse(qtyCtrl.text) ?? 1;
                  final p = double.tryParse(priceCtrl.text) ?? selectedPart!.salePrice;

                  await rep.addPartToRepair(
                    repairId: job.id,
                    partProduct: selectedPart!,
                    quantity: q,
                    sellingPrice: p,
                    technicianName: app.currentUser.name,
                  );

                  Navigator.pop(ctx); // Close part modal
                  Navigator.pop(context); // Refresh details modal
                  _showJobDetailsDialog(context, rep.repairs.firstWhere((r) => r.id == job.id), rep, inv, app);
                },
                child: const Text('Consume Part & Recalculate'),
              ),
            ],
          );
        },
      ),
    );
  }
}
