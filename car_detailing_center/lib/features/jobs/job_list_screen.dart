import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/job_repository.dart';
import 'job_create_dialog.dart';
import 'job_detail_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JobRepository _jobRepo = Get.find<JobRepository>();

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final list = await _jobRepo.getJobs(
        searchQuery: _searchQuery,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _jobs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return AppScaffold(
      currentRoute: AppRoutes.jobs,
      title: 'Detailing Job Cards & Orders',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (_) => const JobCreateDialog(),
          );
          if (res == true) _fetchJobs();
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Job Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by Job #, Vehicle Plate, or Customer Name...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchJobs();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Job Statuses')),
                        ...AppConstants.allJobStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _fetchJobs();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _fetchJobs,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jobs Table
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading active job cards...')
                  : _jobs.isEmpty
                      ? AppEmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No Job Cards Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No job cards match your search criteria.'
                              : 'Create your first service order to start tracking vehicle progress.',
                          actionLabel: 'Create Job Card',
                          onAction: () async {
                            final res = await showDialog(
                              context: context,
                              builder: (_) => const JobCreateDialog(),
                            );
                            if (res == true) _fetchJobs();
                          },
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _jobs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = _jobs[index];
                              final jobId = row['id'] as String;
                              final jobNum = row['job_number'] as String? ?? '';
                              final customerName = row['customer_name'] as String? ?? 'Walk-in';
                              final plate = row['registration_number'] as String? ?? '';
                              final vehicleName = row['vehicle_name'] as String? ?? '';
                              final status = row['status'] as String? ?? 'New';
                              final grandTotal = (row['grand_total'] as num?)?.toDouble() ?? 0.0;
                              final paidAmount = (row['paid_amount'] as num?)?.toDouble() ?? 0.0;
                              final recDate = DateTime.tryParse(row['receiving_date'] ?? '') ?? DateTime.now();

                              final jobModel = JobModel(
                                id: jobId,
                                jobNumber: jobNum,
                                businessId: 'local',
                                customerId: row['customer_id'] ?? '',
                                customerName: customerName,
                                customerPhone: row['customer_phone'] ?? '',
                                vehicleId: row['vehicle_id'] ?? '',
                                vehicleRegNumber: plate,
                                vehicleDisplayName: vehicleName,
                                services: [],
                                status: status,
                                grandTotal: grandTotal,
                                paidAmount: paidAmount,
                                remainingAmount: (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0.0,
                                createdAt: recDate,
                              );

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.getJobStatusColor(status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.directions_car_rounded,
                                    color: AppColors.getJobStatusColor(status),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(jobNum, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.getJobStatusColor(status).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getJobStatusColor(status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('• $customerName', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '$vehicleName ($plate) • Date: ${Formatters.date(recDate)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          Formatters.currency(grandTotal, symbol: currency),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          'Paid: ${Formatters.currency(paidAmount, symbol: currency)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailScreen(job: jobModel),
                                          ),
                                        );
                                        _fetchJobs();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
