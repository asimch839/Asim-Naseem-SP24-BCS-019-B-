import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/invoice_payment_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import 'add_customer_car_dialog.dart';
import 'customer_form_dialog.dart';
import '../vehicles/vehicle_history_screen.dart';
import '../inspections/inspection_create_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late CustomerModel _currentCustomer;
  List<VehicleModel> _vehicles = [];
  List<Map<String, dynamic>> _serviceHistory = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadAllCustomerData();
  }

  Future<void> _loadAllCustomerData() async {
    setState(() => _isLoading = true);
    final custRepo = Get.find<CustomerRepository>();
    final jobRepo = Get.find<JobRepository>();
    final invRepo = Get.find<InvoicePaymentRepository>();
    final inspRepo = Get.find<InspectionRepository>();

    final updatedCust = await custRepo.getCustomerById(_currentCustomer.id);
    final vehicles = await custRepo.getCustomerVehicles(_currentCustomer.id);
    final history = await custRepo.getCustomerServiceHistory(_currentCustomer.id);
    final jobs = await jobRepo.getJobs(customerId: _currentCustomer.id);
    final invoices = await invRepo.getInvoices(customerId: _currentCustomer.id);
    final payments = await invRepo.getPayments(customerId: _currentCustomer.id);
    final inspections = await inspRepo.getInspections(customerId: _currentCustomer.id);

    if (mounted) {
      setState(() {
        if (updatedCust != null) _currentCustomer = updatedCust;
        _vehicles = vehicles;
        _serviceHistory = history;
        _jobs = jobs;
        _invoices = invoices;
        _payments = payments;
        _inspections = inspections;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCustomer.fullName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer Info',
            onPressed: () async {
              final res = await showDialog(
                context: context,
                builder: (_) => CustomerFormDialog(customer: _currentCustomer),
              );
              if (res == true) _loadAllCustomerData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Customer Information Profile Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              _currentCustomer.fullName.isNotEmpty ? _currentCustomer.fullName[0].toUpperCase() : 'C',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(_currentCustomer.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _currentCustomer.status == 'Active'
                                            ? AppColors.success.withValues(alpha: 0.15)
                                            : AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _currentCustomer.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _currentCustomer.status == 'Active' ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: ${_currentCustomer.phone} • Registered: ${Formatters.date(_currentCustomer.createdAt)}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Address: ${_currentCustomer.address ?? "Not specified"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
                                ),
                                if (_currentCustomer.notes != null && _currentCustomer.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Notes: ${_currentCustomer.notes}', style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Outstanding Balance', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                              Text(
                                Formatters.currency(_currentCustomer.outstandingBalance, symbol: currency),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _currentCustomer.outstandingBalance > 0 ? AppColors.error : AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Total Visits: ${_currentCustomer.totalVisits}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Jobs: ${_jobs.length} • Inspections: ${_inspections.length}', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Customer Registered Cars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_car_rounded, color: AppColors.primaryLight),
                          SizedBox(width: 8),
                          Text('Associated Vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final res = await showDialog(
                            context: context,
                            builder: (_) => AddCustomerCarDialog(customer: _currentCustomer),
                          );
                          if (res == true) _loadAllCustomerData();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Vehicle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_vehicles.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No vehicles linked to this customer yet.')),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
                            ),
                            title: Text('${v.make} ${v.model} (${v.year ?? "N/A"})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Plate #: ${v.registrationNumber} • Mileage: ${v.mileage ?? 0} KM ${v.color != null && v.color!.isNotEmpty ? "• Color: ${v.color}" : ""}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.history_rounded, size: 14),
                                  label: const Text('History'),
                                  onPressed: () {
                                    Get.to(() => VehicleHistoryScreen(vehicle: v));
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.fact_check_rounded, size: 14),
                                  label: const Text('Inspect'),
                                  onPressed: () {
                                    Get.to(() => InspectionCreateScreen(
                                          preselectedVehicle: v,
                                          preselectedCustomerId: _currentCustomer.id,
                                          preselectedCustomerName: _currentCustomer.fullName,
                                        ));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // 3. Permanent Service History
                  const Text('Permanent Service History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_serviceHistory.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No service records logged yet.')),
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
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Delivery Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _serviceHistory.map((r) {
                            final dt = DateTime.tryParse(r['date'] ?? '') ?? DateTime.now();
                            final deliveryDate = r['delivery_date'] != null ? DateTime.tryParse(r['delivery_date']) : null;
                            final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
                            final odo = (r['odometer'] as num?)?.toDouble() ?? 0.0;
                            final status = r['payment_status'] as String? ?? 'Unpaid';

                            return DataRow(
                              cells: [
                                DataCell(Text(Formatters.date(dt))),
                                DataCell(Text(r['service_description'] ?? 'Detailing')),
                                DataCell(Text('${odo.toInt()} KM')),
                                DataCell(Text(Formatters.currency(amount, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
                                DataCell(Text(status)),
                                DataCell(Text(deliveryDate != null ? Formatters.date(deliveryDate) : '-')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 4. Invoices & Payments Summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoices
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (_invoices.isEmpty)
                              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No invoices issued.')))
                            else
                              Card(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _invoices.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final inv = _invoices[i];
                                    final total = (inv['grand_total'] as num?)?.toDouble() ?? 0.0;
                                    final rem = (inv['remaining_amount'] as num?)?.toDouble() ?? 0.0;
                                    return ListTile(
                                      title: Text(inv['invoice_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(Formatters.date(DateTime.tryParse(inv['date'] ?? '') ?? DateTime.now())),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(Formatters.currency(total, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            rem > 0 ? 'Remaining: ${Formatters.currency(rem, symbol: currency)}' : 'Paid',
                                            style: TextStyle(fontSize: 11, color: rem > 0 ? AppColors.error : AppColors.success),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Payments
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payments Received', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (_payments.isEmpty)
                              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No payments recorded.')))
                            else
                              Card(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _payments.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final p = _payments[i];
                                    final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                                    return ListTile(
                                      title: Text(Formatters.currency(amount, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                                      subtitle: Text('${p['payment_method']} • ${Formatters.date(DateTime.tryParse(p['payment_date'] ?? '') ?? DateTime.now())}'),
                                      trailing: Text(p['invoice_number'] != null ? 'Inv: ${p['invoice_number']}' : ''),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
