import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';
import 'vehicle_form_dialog.dart';
import 'vehicle_history_screen.dart';
import '../inspections/inspection_create_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VehicleRepository _vehicleRepo = Get.find<VehicleRepository>();

  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final list = await _vehicleRepo.getVehiclesWithCustomerInfo(searchQuery: _searchQuery);
      if (mounted) {
        setState(() {
          _vehicles = list;
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
    return AppScaffold(
      currentRoute: AppRoutes.vehicles,
      title: 'Vehicles',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (_) => const VehicleFormDialog(),
          );
          if (res == true) _fetchVehicles();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by Vehicle Name, Number Plate, Customer Name, or Phone...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchVehicles();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _fetchVehicles,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Fleet List
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading vehicles...')
                  : _vehicles.isEmpty
                      ? AppEmptyState(
                          icon: Icons.directions_car_filled_outlined,
                          title: 'No Vehicles Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No vehicle matched your search query.'
                              : 'Add customer vehicles to begin tracking inspections and service history.',
                          actionLabel: 'Add Vehicle',
                          onAction: () async {
                            final res = await showDialog(
                              context: context,
                              builder: (_) => const VehicleFormDialog(),
                            );
                            if (res == true) _fetchVehicles();
                          },
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _vehicles.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = _vehicles[index];
                              final v = VehicleModel.fromSqlite(row);
                              final customerName = row['customer_name'] as String? ?? 'N/A';
                              final customerPhone = row['customer_phone'] as String? ?? '';
                              final modelYear = row['model_year']?.toString() ?? 'N/A';
                              final odo = (row['current_odometer'] as num?)?.toDouble() ?? 0.0;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
                                ),
                                title: Row(
                                  children: [
                                    // Vehicle Name & Model Year
                                    Flexible(
                                      child: Text(
                                        '${v.make} ${v.model} ($modelYear)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Vehicle Number / Plate Number
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        v.registrationNumber,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Owner: $customerName ($customerPhone) • Mileage: ${odo.toInt()} KM ${v.color != null && v.color!.isNotEmpty ? "• Color: ${v.color}" : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact = MediaQuery.of(context).size.width < 680;
                                    if (isCompact) {
                                      return PopupMenuButton<String>(
                                        onSelected: (val) async {
                                          if (val == 'history') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => VehicleHistoryScreen(vehicle: v),
                                              ),
                                            );
                                          } else if (val == 'inspect') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => InspectionCreateScreen(
                                                  preselectedVehicle: v,
                                                  preselectedCustomerId: v.customerId,
                                                  preselectedCustomerName: customerName,
                                                ),
                                              ),
                                            );
                                          } else if (val == 'edit') {
                                            final res = await showDialog(
                                              context: context,
                                              builder: (_) => VehicleFormDialog(vehicle: v),
                                            );
                                            if (res == true) _fetchVehicles();
                                          } else if (val == 'delete') {
                                            final conf = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Delete Vehicle'),
                                                content: Text('Delete ${v.displayName} from garage records?'),
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
                                              await _vehicleRepo.deleteVehicle(v.id);
                                              _fetchVehicles();
                                            }
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'history', child: Text('Service History')),
                                          const PopupMenuItem(value: 'inspect', child: Text('Inspect Vehicle')),
                                          const PopupMenuItem(value: 'edit', child: Text('Edit Vehicle')),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete Vehicle', style: TextStyle(color: AppColors.error))),
                                        ],
                                      );
                                    }

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.history_rounded, size: 16),
                                          label: const Text('Service History'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => VehicleHistoryScreen(vehicle: v),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.fact_check_rounded, size: 16),
                                          label: const Text('Inspect'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => InspectionCreateScreen(
                                                  preselectedVehicle: v,
                                                  preselectedCustomerId: v.customerId,
                                                  preselectedCustomerName: customerName,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          onSelected: (val) async {
                                            if (val == 'edit') {
                                              final res = await showDialog(
                                                context: context,
                                                builder: (_) => VehicleFormDialog(vehicle: v),
                                              );
                                              if (res == true) _fetchVehicles();
                                            } else if (val == 'delete') {
                                              final conf = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete Vehicle'),
                                                  content: Text('Delete ${v.displayName} from garage records?'),
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
                                                await _vehicleRepo.deleteVehicle(v.id);
                                                _fetchVehicles();
                                              }
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Edit Vehicle')),
                                            const PopupMenuItem(value: 'delete', child: Text('Delete Vehicle', style: TextStyle(color: AppColors.error))),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
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
