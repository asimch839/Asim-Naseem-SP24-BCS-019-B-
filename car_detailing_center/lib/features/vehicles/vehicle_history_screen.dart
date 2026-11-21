import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import '../customers/add_service_record_dialog.dart';
import '../inspections/inspection_create_screen.dart';
import '../jobs/job_detail_screen.dart';

class VehicleHistoryScreen extends StatefulWidget {
  final VehicleModel vehicle;
  const VehicleHistoryScreen({super.key, required this.vehicle});

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen> {
  CustomerModel? _customer;
  List<Map<String, dynamic>> _serviceHistory = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final custRepo = Get.find<CustomerRepository>();
    final vehRepo = Get.find<VehicleRepository>();
    final jobRepo = Get.find<JobRepository>();
    final inspRepo = Get.find<InspectionRepository>();

    final cust = await custRepo.getCustomerById(widget.vehicle.customerId);
    final jobs = await jobRepo.getJobs(vehicleId: widget.vehicle.id);

    // Sync all jobs of this vehicle to ensure all services and dates appear in permanent service records
    for (final j in jobs) {
      final jobId = j['id'] as String?;
      if (jobId != null) {
        await jobRepo.syncJobToVehicleHistory(jobId);
      }
    }

    final history = await vehRepo.getVehicleServiceHistory(widget.vehicle.id);
    final inspections = await inspRepo.getInspections(vehicleId: widget.vehicle.id);

    if (mounted) {
      setState(() {
        _customer = cust;
        _serviceHistory = history;
        _jobs = jobs;
        _inspections = inspections;
        _isLoading = false;
      });
    }
  }

  void _showSettlePaymentDialog(Map<String, dynamic> record) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final jobId = record['job_id'] as String?;
    final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;
    final desc = record['service_description']?.toString() ?? 'Service';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Settle Payment in Full', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: $desc', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Total Amount: ${Formatters.currency(amount, symbol: currency)}'),
            const SizedBox(height: 12),
            const Text(
              'Did the customer pay this bill in full? Clicking "Mark Paid in Full" will update the status to Paid and clear any remaining balance.',
              style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Mark Paid in Full'),
            onPressed: () async {
              Navigator.pop(ctx);
              if (jobId != null && jobId.isNotEmpty) {
                final jobRepo = Get.find<JobRepository>();
                await jobRepo.markJobPaidInFull(jobId);
              } else {
                final histId = record['id'] as String?;
                if (histId != null) {
                  final vehRepo = Get.find<VehicleRepository>();
                  await vehRepo.updateServiceHistoryPaymentStatus(histId, 'Paid');
                }
              }
              await _loadHistory();
              Get.snackbar(
                'Payment Marked Paid',
                'Payment status updated to Paid in full.',
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final v = widget.vehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text('Permanent Vehicle History: ${v.make} ${v.model} (${v.registrationNumber})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_car_filled_rounded, size: 36, color: AppColors.primaryLight),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v.make} ${v.model} (${v.year ?? "Year N/A"})',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Plate Number: ${v.registrationNumber} • Current Mileage: ${v.mileage ?? 0} KM ${v.color != null && v.color!.isNotEmpty ? "• Color: ${v.color}" : ""}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customer: ${_customer?.fullName ?? "Walk-in"} • Phone: ${_customer?.phone ?? "-"}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _customer != null
                                    ? () async {
                                        final res = await showDialog(
                                          context: context,
                                          builder: (_) => AddServiceRecordDialog(customer: _customer!, vehicle: v),
                                        );
                                        if (res == true) _loadHistory();
                                      }
                                    : null,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Log Service Visit'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Get.to(() => InspectionCreateScreen(
                                        preselectedVehicle: v,
                                        preselectedCustomerId: v.customerId,
                                        preselectedCustomerName: _customer?.fullName,
                                      ));
                                },
                                icon: const Icon(Icons.fact_check_outlined, size: 16),
                                label: const Text('New Inspection'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Permanent Chronological Service Records
                  const Text('Permanent Chronological Service Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_serviceHistory.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No permanent service history records logged for this vehicle yet.')),
                      ),
                    )
                  else
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
                          columns: const [
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Service Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Odometer / KM', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Assigned Staff', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Delivery Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _serviceHistory.map((r) {
                            final date = DateTime.tryParse(r['date'] ?? '') ?? DateTime.now();
                            final deliveryDate = r['delivery_date'] != null ? DateTime.tryParse(r['delivery_date']) : null;
                            final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
                            final odo = (r['odometer'] as num?)?.toDouble() ?? 0.0;
                            final payStatus = r['payment_status'] as String? ?? 'Unpaid';

                            return DataRow(
                              cells: [
                                DataCell(Text(Formatters.date(date))),
                                DataCell(Text(r['service_description'] ?? 'Detailing')),
                                DataCell(Text('${odo.toInt()} KM')),
                                DataCell(Text(r['staff_names']?.toString().isNotEmpty == true ? r['staff_names'] : 'Tech')),
                                DataCell(Text(Formatters.currency(amount, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
                                DataCell(InkWell(
                                  onTap: payStatus == 'Paid' ? null : () => _showSettlePaymentDialog(r),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (payStatus == 'Paid' ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: (payStatus == 'Paid' ? AppColors.success : AppColors.warning).withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          payStatus == 'Paid' ? Icons.check_circle_rounded : Icons.pending_rounded,
                                          size: 12,
                                          color: payStatus == 'Paid' ? AppColors.success : AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          payStatus,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: payStatus == 'Paid' ? AppColors.success : AppColors.warning,
                                          ),
                                        ),
                                        if (payStatus != 'Paid') ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit_outlined, size: 10, color: AppColors.warning),
                                        ],
                                      ],
                                    ),
                                  ),
                                )),
                                DataCell(Text(deliveryDate != null ? Formatters.date(deliveryDate) : '-')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Digital Job Cards
                  const Text('Linked Job Cards & Work Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final activeJobCards = _jobs.where((job) {
                        final grandTotal = (job['grand_total'] as num?)?.toDouble() ?? 0.0;
                        final paid = (job['paid_amount'] as num?)?.toDouble() ?? 0.0;
                        final remaining = (job['remaining_amount'] as num?)?.toDouble() ?? 0.0;
                        final st = job['status'] as String? ?? 'New';
                        final isDeliveredOrCompleted = (st == 'Delivered' || st == 'Completed');
                        final isPaidFull = (remaining <= 0) || (grandTotal > 0 && paid >= grandTotal);

                        // If car is delivered/completed AND payment is complete, remove from Linked Job Cards!
                        if (isDeliveredOrCompleted && isPaidFull) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (activeJobCards.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                _jobs.isEmpty
                                    ? 'No job cards on record for this vehicle.'
                                    : 'All completed orders have been delivered, fully settled, and archived to Permanent Service Records above.',
                                style: const TextStyle(color: AppColors.textDarkSecondary),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeJobCards.length,
                        itemBuilder: (context, index) {
                          final job = activeJobCards[index];
                        final grandTotal = (job['grand_total'] as num?)?.toDouble() ?? 0.0;
                        final paid = (job['paid_amount'] as num?)?.toDouble() ?? 0.0;
                        final st = job['status'] as String? ?? 'New';
                        final recDate = DateTime.tryParse(job['receiving_date'] ?? '') ?? DateTime.now();
                        final odoIn = (job['odometer_in'] as num?)?.toDouble() ?? 0.0;
                        final servicesSummary = job['services_summary'] as String? ?? '';

                        final jobModel = JobModel(
                          id: job['id'] ?? '',
                          jobNumber: job['job_number'] ?? '',
                          businessId: 'local',
                          customerId: job['customer_id'] ?? '',
                          customerName: _customer?.fullName ?? job['customer_name'] ?? '',
                          customerPhone: _customer?.phone ?? job['customer_phone'] ?? '',
                          vehicleId: widget.vehicle.id,
                          vehicleRegNumber: widget.vehicle.registrationNumber,
                          vehicleDisplayName: widget.vehicle.displayName,
                          services: [],
                          status: st,
                          grandTotal: grandTotal,
                          paidAmount: paid,
                          remainingAmount: (grandTotal - paid) > 0 ? (grandTotal - paid) : 0.0,
                          createdAt: recDate,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobDetailScreen(job: jobModel),
                                ),
                              );
                              _loadHistory();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            job['job_number'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.getJobStatusColor(st).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              st,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.getJobStatusColor(st),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Total: ${Formatters.currency(grandTotal, symbol: currency)} (Paid: ${Formatters.currency(paid, symbol: currency)})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textDarkSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Service Date: ${Formatters.date(recDate)}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                                          ),
                                        ],
                                      ),
                                      if (odoIn > 0)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.speed_rounded, size: 14, color: AppColors.textDarkSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${odoIn.toInt()} KM',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                            ),
                                          ],
                                        ),
                                      if (job['technician_name'] != null && job['technician_name'].toString().isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textDarkSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tech: ${job['technician_name']}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Icons.handyman_rounded, size: 15, color: AppColors.primaryLight),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            servicesSummary.isNotEmpty
                                                ? 'Work Done: $servicesSummary'
                                                : 'General Detailing / Inspection',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                  // Inspection Records
                  const Text('Inspection Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_inspections.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No condition inspections recorded for this vehicle.')),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _inspections.length,
                      itemBuilder: (context, index) {
                        final insp = _inspections[index];
                        final dt = DateTime.tryParse(insp['inspection_date'] ?? '') ?? DateTime.now();
                        final itemsCount = insp['items_count'] ?? 0;
                        final photosCount = insp['photos_count'] ?? 0;

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.fact_check_rounded, color: AppColors.primaryLight),
                            title: Text('Inspection on ${Formatters.date(dt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Inspector: ${insp['inspector_name']} • Inspected Parts / Sections: $itemsCount'),
                            trailing: photosCount > 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.photo_library_outlined, size: 16),
                                      const SizedBox(width: 4),
                                      Text('$photosCount photos'),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
