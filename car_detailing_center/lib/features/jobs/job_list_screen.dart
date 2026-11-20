import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/date_range_filter_bar.dart';
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
  String _selectedStatus = 'Active Orders';
  String? _startDate;
  String? _endDate;

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
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
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
        padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 12 : 24),
        child: Column(
          children: [
            // Filter Bar with Quick Status Chips
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by Job #, Vehicle Plate, or Customer...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _fetchJobs();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (val) {
                              _searchQuery = val.trim();
                              _fetchJobs();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Refresh',
                          onPressed: _fetchJobs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Active Orders',
                          AppConstants.jobStatusInProgress,
                          AppConstants.jobStatusReadyForDelivery,
                          AppConstants.jobStatusNew,
                          AppConstants.jobStatusWaiting,
                          'Completed Orders',
                          'All Orders',
                          AppConstants.jobStatusCancelled,
                        ].map((st) {
                          final isSelected = _selectedStatus == st;
                          Color chipColor;
                          if (st == 'Active Orders') {
                            chipColor = AppColors.primary;
                          } else if (st == 'Completed Orders') {
                            chipColor = AppColors.success;
                          } else if (st == 'All Orders') {
                            chipColor = AppColors.primaryLight;
                          } else {
                            chipColor = AppColors.getJobStatusColor(st);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                st == 'Active Orders' ? 'Active Orders (Floor)' : (st == 'Completed Orders' ? 'Completed (History)' : st),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: chipColor,
                              onSelected: (_) {
                                setState(() => _selectedStatus = st);
                                _fetchJobs();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DateRangeFilterBar(
                      onFilterChanged: (start, end, label) {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                        _fetchJobs();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Live Counter & Completed Filter Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedStatus == 'Active Orders'
                        ? 'Active Ongoing Orders on Floor (${_jobs.length})'
                        : (_selectedStatus == 'Completed Orders'
                            ? 'Completed & Delivered History (${_jobs.length})'
                            : '$_selectedStatus (${_jobs.length})'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDarkSecondary),
                  ),
                  if (_selectedStatus == 'Active Orders')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Completed orders removed',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Jobs Table
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading active job cards...')
                  : _jobs.isEmpty
                      ? AppEmptyState(
                          icon: _selectedStatus == 'Active Orders' ? Icons.task_alt_rounded : Icons.assignment_outlined,
                          title: _selectedStatus == 'Active Orders' ? 'No Active Orders on Floor' : 'No Job Cards Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No job cards match your search criteria.'
                              : (_selectedStatus == 'Active Orders'
                                  ? 'All previous vehicle orders are completed and safely archived to Vehicle Service History! Create a new job card when a vehicle arrives.'
                                  : 'No orders recorded under this status filter.'),
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

                              final isMobile = ResponsiveLayout.isMobile(context);

                              return ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobDetailScreen(job: jobModel),
                                    ),
                                  );
                                  _fetchJobs();
                                },
                                contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 8),
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
                                title: isMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(jobNum, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getJobStatusColor(status).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.getJobStatusColor(status),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            customerName,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      )
                                    : Row(
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
                                          Flexible(
                                            child: Text(
                                              '• $customerName',
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '$vehicleName ($plate) • ${Formatters.date(recDate)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Formatters.currency(grandTotal, symbol: currency),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
                                    ),
                                    Text(
                                      'Paid: ${Formatters.currency(paidAmount, symbol: currency)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
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
