import 'package:flutter/gestures.dart';
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
import '../widgets/interactive_scroll_view.dart';

class RepairLabScreen extends StatefulWidget {
  const RepairLabScreen({super.key});

  @override
  State<RepairLabScreen> createState() => _RepairLabScreenState();
}

class _RepairLabScreenState extends State<RepairLabScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _kanbanHorizontalController = ScrollController();
  final ScrollController _screenVerticalController = ScrollController();
  final ScrollController _tableVerticalController = ScrollController();
  final ScrollController _tableHorizontalController = ScrollController();

  bool _isKanbanView = true;
  RepairStatus? _selectedStatus;
  String _selectedTechnician = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _kanbanHorizontalController.dispose();
    _screenVerticalController.dispose();
    _tableVerticalController.dispose();
    _tableHorizontalController.dispose();
    super.dispose();
  }

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight < 680;

          final content = Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isSmallHeight ? MainAxisSize.min : MainAxisSize.max,
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
                          label: const Text('+ New Repair Job'),
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

                const SizedBox(height: 14),

                // Main Display: Kanban Board or Table
                if (isSmallHeight)
                  SizedBox(
                    height: 560,
                    child: _isKanbanView
                        ? _buildKanbanBoard(context, rep, inv, app, isDark)
                        : _buildTableView(context, filtered, inv, rep, app, isDark),
                  )
                else
                  Expanded(
                    child: _isKanbanView
                        ? _buildKanbanBoard(context, rep, inv, app, isDark)
                        : _buildTableView(context, filtered, inv, rep, app, isDark),
                  ),
              ],
            ),
          );

          if (isSmallHeight) {
            return Scrollbar(
              controller: _screenVerticalController,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _screenVerticalController,
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  // Quick Phase Navigation Toolbar for Kanban
  Widget _buildStageNavigationToolbar(RepairProvider rep, bool isDark) {
    final stages = [
      {'name': 'Received Intake', 'count': rep.receivedJobs.length, 'color': const Color(0xFF3B82F6), 'index': 0},
      {'name': 'Under Inspection', 'count': rep.inspectionJobs.length, 'color': const Color(0xFF6366F1), 'index': 1},
      {'name': 'In Progress & Repairing', 'count': rep.inProgressJobs.length, 'color': const Color(0xFFD97706), 'index': 2},
      {'name': 'Waiting for Parts', 'count': rep.waitingForPartsJobs.length, 'color': const Color(0xFFEA580C), 'index': 3},
      {'name': 'Ready for Delivery', 'count': rep.readyJobs.length, 'color': const Color(0xFF059669), 'index': 4},
      {'name': 'Delivered to Customer', 'count': rep.deliveredJobs.length, 'color': const Color(0xFF16A34A), 'index': 5},
    ];

    void scrollToStage(int index) {
      if (!_kanbanHorizontalController.hasClients) return;
      // Each column is 290px wide + 14px margin = 304px
      final target = (index * 304.0)
          .clamp(0.0, _kanbanHorizontalController.position.maxScrollExtent);
      _kanbanHorizontalController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                tooltip: 'Scroll Left (◀)',
                onPressed: () {
                  if (_kanbanHorizontalController.hasClients) {
                    final target = (_kanbanHorizontalController.offset - 304.0)
                        .clamp(0.0, _kanbanHorizontalController.position.maxScrollExtent);
                    _kanbanHorizontalController.animateTo(
                      target,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                tooltip: 'Scroll Right (▶)',
                onPressed: () {
                  if (_kanbanHorizontalController.hasClients) {
                    final target = (_kanbanHorizontalController.offset + 304.0)
                        .clamp(0.0, _kanbanHorizontalController.position.maxScrollExtent);
                    _kanbanHorizontalController.animateTo(
                      target,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Text(
            'Jump to Stage:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                children: stages.map((s) {
                  final color = s['color'] as Color;
                  final count = s['count'] as int;
                  final idx = s['index'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => scrollToStage(idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha: 0.28)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              '${s['name']}',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stage Jump Toolbar
        _buildStageNavigationToolbar(rep, isDark),
        const SizedBox(height: 10),
        // Kanban Columns with Horizontal Scrollbar & Mouse Wheel / Drag Support
        Expanded(
          child: ScrollConfiguration(
            behavior: scrollBehavior,
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent &&
                    _kanbanHorizontalController.hasClients) {
                  // Allow standard vertical mouse wheel or horizontal tilt wheel to scroll horizontally
                  final delta = pointerSignal.scrollDelta.dx != 0
                      ? pointerSignal.scrollDelta.dx
                      : pointerSignal.scrollDelta.dy;
                  final target = (_kanbanHorizontalController.offset + delta)
                      .clamp(0.0, _kanbanHorizontalController.position.maxScrollExtent);
                  _kanbanHorizontalController.jumpTo(target);
                }
              },
              child: Scrollbar(
                controller: _kanbanHorizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: ListView(
                  controller: _kanbanHorizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    _buildKanbanColumn('Received Intake', rep.receivedJobs, const Color(0xFF3B82F6), const Color(0xFFDBEAFE), context, rep, inv, app, isDark),
                    _buildKanbanColumn('Under Inspection', rep.inspectionJobs, const Color(0xFF6366F1), const Color(0xFFE0E7FF), context, rep, inv, app, isDark),
                    _buildKanbanColumn('In Progress & Repairing', rep.inProgressJobs, const Color(0xFFD97706), const Color(0xFFFEF3C7), context, rep, inv, app, isDark),
                    _buildKanbanColumn('Waiting for Parts / Customer', rep.waitingForPartsJobs, const Color(0xFFEA580C), const Color(0xFFFFEDD5), context, rep, inv, app, isDark),
                    _buildKanbanColumn('Ready for Delivery', rep.readyJobs, const Color(0xFF059669), const Color(0xFFD1FAE5), context, rep, inv, app, isDark),
                    _buildKanbanColumn('Delivered to Customer', rep.deliveredJobs, const Color(0xFF16A34A), const Color(0xFFDCFCE7), context, rep, inv, app, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
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

          // Cards List with Vertical Scrollbar
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text('No jobs in this phase', style: TextStyle(fontSize: 11.5, color: Colors.grey)))
                : Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: jobs.length,
                      itemBuilder: (context, idx) {
                        final job = jobs[idx];
                        return _buildJobCard(context, job, rep, inv, app, isDark);
                      },
                    ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Final: ${AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        if (job.remainingDue > 0)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text('Due: ${AppFormatters.currency(job.remainingDue)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                              InkWell(
                                onTap: () => _showCollectPaymentDialog(context, job, rep, app),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.35)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.payments_rounded, size: 11, color: AppTheme.successGreen),
                                      SizedBox(width: 3),
                                      Text('Clear', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          const Text('Fully Paid', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                      ],
                    ),
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
          : InteractiveBiDirectionalScrollView(
              verticalController: _tableVerticalController,
              horizontalController: _tableHorizontalController,
              minWidth: 1100,
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
                            color: AppTheme.purpleRepair.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(job.status.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleRepair)),
                        ),
                      ),
                      DataCell(Text(AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        job.remainingDue > 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(AppFormatters.currency(job.remainingDue), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _showCollectPaymentDialog(context, job, rep, app),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successGreen.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.35)),
                                      ),
                                      child: const Text('Clear', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                    ),
                                  ),
                                ],
                              )
                            : const Text('Fully Cleared', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (job.remainingDue > 0)
                              IconButton(
                                tooltip: 'Collect Payment / Clear Due',
                                icon: const Icon(Icons.payments_rounded, size: 20, color: AppTheme.successGreen),
                                onPressed: () => _showCollectPaymentDialog(context, job, rep, app),
                              ),
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
                              const SizedBox(height: 3),
                              Text(job.customerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('Phone: ${job.customerPhone}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                              if (job.customerAltPhone.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text('Alt: ${job.customerAltPhone}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEVICE DETAILS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                              const SizedBox(height: 3),
                              Text('${job.deviceBrand} ${job.deviceModel}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              if (job.imei.isNotEmpty) ...[
                                Text('IMEI: ${job.imei}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                                const SizedBox(height: 1),
                              ],
                              Text('Condition: ${job.deviceCondition}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                              const SizedBox(height: 1),
                              Text('Accessories: ${job.accessoriesReceived}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Problem & Password PIN (Masked with toggle!)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.6) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Problem Reported: ${job.reportedProblem}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Device Lock PIN / Pattern: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                                ),
                              ),
                              Text(
                                revealPassword ? (job.lockPinOrPassword.isNotEmpty ? job.lockPinOrPassword : 'None') : '••••••••',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.5,
                                  color: isDark ? Colors.white : const Color(0xFF78350F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => setState(() => revealPassword = !revealPassword),
                                child: Icon(
                                  revealPassword ? Icons.visibility_off : Icons.visibility,
                                  size: 16,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                                ),
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
                      Text('No replacement parts attached yet.', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))
                    else
                      ...job.partsUsed.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${p.quantity}x ${p.partName}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(AppFormatters.currency(p.totalSellingPrice), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))),
                            ],
                          ),
                        );
                      }),

                    const Divider(height: 20),

                    // Cost Calculation Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('COST CALCULATION & PAYMENT BREAKDOWN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_note_rounded, size: 14),
                          label: const Text('Edit Labor / Discount', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditChargesDialog(context, job, rep, inv, app);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Labor Charges:', style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                              Text(
                                AppFormatters.currency(job.laborCharges),
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Parts Total:', style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                              Text(
                                AppFormatters.currency(job.partsTotalSelling),
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          if (job.discount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount:', style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed)),
                                Text(
                                  '- ${AppFormatters.currency(job.discount)}',
                                  style: TextStyle(color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Final Total Repair Cost:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(
                                AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Advance Deposit Paid:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                              Text(
                                AppFormatters.currency(job.advancePaid),
                                style: TextStyle(color: isDark ? const Color(0xFF34D399) : AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Balance Due from Customer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed)),
                              Text(
                                AppFormatters.currency(job.remainingDue),
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed),
                              ),
                            ],
                          ),
                          if (job.remainingDue > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.25) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pending_actions_rounded, size: 20, color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pending Balance from Client',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? const Color(0xFFFCA5A5) : AppTheme.dangerRed),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Amount to Clear: ${AppFormatters.currency(job.remainingDue)}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(Icons.payments_rounded, size: 16),
                                    label: const Text('Clear / Collect Due'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showCollectPaymentDialog(context, job, rep, app);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 16, color: isDark ? const Color(0xFF34D399) : const Color(0xFF166534)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Status: Fully Paid & Cleared',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534)),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                            final isFinishing = (nextStatus == RepairStatus.completed ||
                                nextStatus == RepairStatus.readyForDelivery ||
                                nextStatus == RepairStatus.delivered);

                            if (isFinishing && job.remainingDue > 0) {
                              final clearNow = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: Row(
                                    children: [
                                      const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.warningOrange),
                                      const SizedBox(width: 8),
                                      Text('Pending Balance (${AppFormatters.currency(job.remainingDue)})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: Text(
                                    'Job #${job.jobId} is being marked as "${nextStatus.displayName}".\n\n'
                                    'The client has a remaining balance of ${AppFormatters.currency(job.remainingDue)}.\n\n'
                                    'Would you like to collect and clear this payment now?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx, false),
                                      child: const Text('Save Status Only (Keep Due)'),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                                      icon: const Icon(Icons.payments_rounded, size: 16),
                                      label: const Text('Collect Payment Now'),
                                      onPressed: () => Navigator.pop(dialogCtx, true),
                                    ),
                                  ],
                                ),
                              );

                              if (clearNow == true) {
                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                _showCollectPaymentDialog(context, job, rep, app, targetStatus: nextStatus);
                                return;
                              }
                            }

                            await rep.updateRepairStatus(
                              repairId: job.id,
                              newStatus: nextStatus,
                              changedBy: app.currentUser.name,
                              notes: statusNotesCtrl.text.trim(),
                            );
                            if (!context.mounted) return;
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

                    if ((job.status == RepairStatus.completed || job.status == RepairStatus.readyForDelivery) && job.remainingDue > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.status == RepairStatus.completed ? 'Repair Completed!' : 'Ready for Delivery!',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Remaining balance due: ${AppFormatters.currency(job.remainingDue)}',
                                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.payments_outlined, size: 15),
                                  label: const Text('Clear Balance Only'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
                                    side: BorderSide(color: isDark ? const Color(0xFF059669) : const Color(0xFF166534)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showCollectPaymentDialog(context, job, rep, app, markDelivered: false);
                                  },
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                                  label: const Text('Collect & Deliver Device'),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showCollectPaymentDialog(context, job, rep, app, markDelivered: true);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (job.status == RepairStatus.delivered && job.remainingDue > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.25) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Device Delivered with Balance Pending!',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFCA5A5) : AppTheme.dangerRed),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Outstanding Due: ${AppFormatters.currency(job.remainingDue)}',
                                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D)),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                              icon: const Icon(Icons.payments_rounded, size: 16),
                              label: const Text('Settle Pending Balance'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showCollectPaymentDialog(context, job, rep, app);
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: job.history.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.radio_button_checked_rounded, size: 12, color: AppTheme.primaryBlue),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${AppFormatters.dateTime(h.timestamp)}: [${h.status.displayName}] by ${h.changedBy}${h.notes.isNotEmpty ? " - ${h.notes}" : ""}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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

                  if (!context.mounted) return;
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

  void _showCollectPaymentDialog(
    BuildContext context,
    RepairJob job,
    RepairProvider rep,
    AppProvider app, {
    RepairStatus? targetStatus,
    bool markDelivered = false,
  }) {
    final amountCtrl = TextEditingController(text: job.remainingDue.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String paymentMethod = 'Cash';
    bool shouldDeliver = markDelivered || (job.status == RepairStatus.readyForDelivery || job.status == RepairStatus.completed);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentInputAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          final remainingAfterPayment = (job.remainingDue - currentInputAmount).clamp(0.0, double.infinity);

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.payments_rounded, color: AppTheme.successGreen),
                const SizedBox(width: 8),
                Text('Collect Payment - Job #${job.jobId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer & Device Info Card
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(job.customerPhone, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${job.deviceBrand} ${job.deviceModel}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              Text('Status: ${job.status.displayName}', style: const TextStyle(fontSize: 11, color: AppTheme.purpleRepair, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Financial Overview Breakdown
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Repair Cost:', style: TextStyle(fontSize: 12)),
                              Text(AppFormatters.currency(job.finalTotal > 0 ? job.finalTotal : job.estimatedCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Advance Deposit Paid:', style: TextStyle(fontSize: 12)),
                              Text(AppFormatters.currency(job.advancePaid), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining Balance Due:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.dangerRed)),
                              Text(AppFormatters.currency(job.remainingDue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.dangerRed)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Amount to Collect Input
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Payment Amount to Collect (Rs.) *',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Set to Full Due Amount',
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          onPressed: () {
                            amountCtrl.text = job.remainingDue.toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 6),

                    // Quick Fill Buttons (Full, Half)
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.done_all_rounded, size: 13, color: AppTheme.successGreen),
                          label: Text('Full Balance (${AppFormatters.currency(job.remainingDue)})', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            amountCtrl.text = job.remainingDue.toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                        if (job.remainingDue > 500)
                          ActionChip(
                            avatar: const Icon(Icons.pie_chart_outline_rounded, size: 13, color: AppTheme.primaryBlue),
                            label: Text('Half Balance (${AppFormatters.currency(job.remainingDue / 2)})', style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              amountCtrl.text = (job.remainingDue / 2).toStringAsFixed(0);
                              setState(() {});
                            },
                          ),
                      ],
                    ),

                    if (currentInputAmount > 0 && remainingAfterPayment > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Partial payment: Remaining balance after this payment will be ${AppFormatters.currency(remainingAfterPayment)}',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.warningOrange, fontWeight: FontWeight.w600),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Payment Method Dropdown
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method *',
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                        DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'Card', child: Text('Card / POS')),
                      ],
                      onChanged: (v) => setState(() => paymentMethod = v!),
                    ),

                    const SizedBox(height: 10),

                    // Remarks / Notes
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Voucher Notes (Optional)',
                        hintText: 'e.g. Cleared remaining balance on delivery',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Checkbox for delivery status
                    if (job.status != RepairStatus.delivered)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Mark device as Delivered to customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Updates status to Delivered and sets handover timestamp', style: TextStyle(fontSize: 11)),
                        value: shouldDeliver,
                        onChanged: (v) => setState(() => shouldDeliver = v ?? false),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Confirm Payment & Clear'),
                onPressed: () async {
                  final payAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (payAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid payment amount greater than 0.')),
                    );
                    return;
                  }

                  final targetSt = shouldDeliver
                      ? RepairStatus.delivered
                      : (targetStatus ?? (job.status == RepairStatus.received ? RepairStatus.inProgress : job.status));

                  final payment = await rep.collectPayment(
                    repairId: job.id,
                    paymentAmount: payAmount,
                    paymentMethod: paymentMethod,
                    notes: notesCtrl.text.trim(),
                    collectedBy: app.currentUser.name,
                    newStatus: targetSt != job.status ? targetSt : null,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(ctx);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment of ${AppFormatters.currency(payAmount)} received for #${job.jobId}!'),
                        action: SnackBarAction(
                          label: 'Print Voucher',
                          onPressed: () {
                            if (payment != null) {
                              PrintService.printPaymentReceipt(payment: payment, settings: app.settings);
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditChargesDialog(
    BuildContext context,
    RepairJob job,
    RepairProvider rep,
    InventoryProvider inv,
    AppProvider app,
  ) {
    final laborCtrl = TextEditingController(text: job.laborCharges.toStringAsFixed(0));
    final otherCtrl = TextEditingController(text: job.otherCharges.toStringAsFixed(0));
    final discountCtrl = TextEditingController(text: job.discount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final labor = double.tryParse(laborCtrl.text.trim()) ?? 0.0;
          final other = double.tryParse(otherCtrl.text.trim()) ?? 0.0;
          final discount = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
          final partsTotal = job.partsTotalSelling;
          final calculatedFinal = (labor + partsTotal + other) - discount;
          final calculatedDue = (calculatedFinal - job.advancePaid).clamp(0.0, double.infinity);

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('Edit Charges & Discount - #${job.jobId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: laborCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Labor Charges (Rs.)',
                        prefixIcon: Icon(Icons.engineering_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: otherCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Other / Extra Charges (Rs.)',
                        prefixIcon: Icon(Icons.add_circle_outline_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Discount Given (Rs.)',
                        prefixIcon: Icon(Icons.discount_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Parts Consumed Total:', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                              Text(AppFormatters.currency(partsTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('New Total Cost:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(AppFormatters.currency(calculatedFinal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Advance Already Paid:', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                              Text(AppFormatters.currency(job.advancePaid), style: TextStyle(color: isDark ? const Color(0xFF34D399) : AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('New Balance Due:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed)),
                              Text(AppFormatters.currency(calculatedDue), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? const Color(0xFFF87171) : AppTheme.dangerRed)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await rep.updateCosts(
                    repairId: job.id,
                    labor: labor,
                    other: other,
                    discount: discount,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  final updatedJob = rep.repairs.firstWhere((r) => r.id == job.id);
                  _showJobDetailsDialog(context, updatedJob, rep, inv, app);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repair charges and due amount updated successfully!')),
                  );
                },
                child: const Text('Save Charges'),
              ),
            ],
          );
        },
      ),
    );
  }
}
