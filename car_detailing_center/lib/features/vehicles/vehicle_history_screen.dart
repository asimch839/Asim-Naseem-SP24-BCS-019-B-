import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import '../customers/add_service_record_dialog.dart';
import '../inspections/inspection_create_screen.dart';

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
    final history = await vehRepo.getVehicleServiceHistory(widget.vehicle.id);
    final jobs = await jobRepo.getJobs(vehicleId: widget.vehicle.id);
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
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (payStatus == 'Paid' ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(payStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: payStatus == 'Paid' ? AppColors.success : AppColors.warning)),
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
                  if (_jobs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No job cards on record for this vehicle.')),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) {
                        final job = _jobs[index];
                        final grandTotal = (job['grand_total'] as num?)?.toDouble() ?? 0.0;
                        final paid = (job['paid_amount'] as num?)?.toDouble() ?? 0.0;
                        final st = job['status'] as String? ?? 'New';
                        final recDate = DateTime.tryParse(job['receiving_date'] ?? '') ?? DateTime.now();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(job['job_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.getJobStatusColor(st).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(st, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.getJobStatusColor(st))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Received: ${Formatters.date(recDate)} • Technician: ${job['technician_name'] ?? "Unassigned"}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                                  ],
                                ),
                                Text(
                                  'Total: ${Formatters.currency(grandTotal, symbol: currency)} (Paid: ${Formatters.currency(paid, symbol: currency)})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
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
