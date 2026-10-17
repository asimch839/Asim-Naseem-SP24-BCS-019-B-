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
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_form_dialog.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerRepository _customerRepo = Get.find<CustomerRepository>();

  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _customerRepo.getCustomers(
        searchQuery: _searchQuery,
        activeOnly: _statusFilter == 'Active',
      );
      if (mounted) {
        setState(() {
          _customers = list;
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
      currentRoute: AppRoutes.customers,
      title: 'Customer Management',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (_) => const CustomerFormDialog(),
          );
          if (res == true) _fetchCustomers();
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer'),
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
                          hintText: 'Search by Customer Name or Phone Number...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchCustomers();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _statusFilter = val);
                          _fetchCustomers();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _fetchCustomers,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customers Table / List
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading customers directory...')
                  : _customers.isEmpty
                      ? AppEmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'No Customers Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No customer matched your search query.'
                              : 'Get started by creating your first client record.',
                          actionLabel: 'Register Customer',
                          onAction: () async {
                            final res = await showDialog(
                              context: context,
                              builder: (_) => const CustomerFormDialog(),
                            );
                            if (res == true) _fetchCustomers();
                          },
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _customers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final customer = _customers[index];

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : 'C',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: customer.status == 'Active'
                                            ? AppColors.success.withValues(alpha: 0.15)
                                            : AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        customer.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: customer.status == 'Active' ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Phone: ${customer.phone} • Registered: ${Formatters.date(customer.createdAt)} • Visits: ${customer.totalVisits}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (customer.outstandingBalance > 0)
                                      Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Due: ${Formatters.currency(customer.outstandingBalance, symbol: currency)}',
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded),
                                      tooltip: 'View Profile',
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CustomerDetailScreen(customer: customer),
                                          ),
                                        );
                                        _fetchCustomers();
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          final res = await showDialog(
                                            context: context,
                                            builder: (_) => CustomerFormDialog(customer: customer),
                                          );
                                          if (res == true) _fetchCustomers();
                                        } else if (val == 'deactivate') {
                                          final updated = customer.copyWith(status: customer.status == 'Active' ? 'Inactive' : 'Active');
                                          await _customerRepo.saveCustomer(updated);
                                          _fetchCustomers();
                                        } else if (val == 'delete') {
                                          final conf = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Soft Delete Customer'),
                                              content: Text('Are you sure you want to remove ${customer.fullName} from active records?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (conf == true) {
                                            await _customerRepo.deleteCustomer(customer.id, softDelete: true);
                                            _fetchCustomers();
                                          }
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit Customer')),
                                        PopupMenuItem(
                                          value: 'deactivate',
                                          child: Text(customer.status == 'Active' ? 'Deactivate' : 'Activate'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Soft Delete', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
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
