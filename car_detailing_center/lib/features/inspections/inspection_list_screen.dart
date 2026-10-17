import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/inspection_model.dart';
import '../../data/repositories/inspection_repository.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final InspectionRepository _inspectionRepo = Get.find<InspectionRepository>();

  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInspections();
  }

  Future<void> _fetchInspections() async {
    setState(() => _isLoading = true);
    try {
      final list = await _inspectionRepo.getInspections(searchQuery: _searchQuery);
      if (mounted) {
        setState(() {
          _inspections = list;
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
      currentRoute: AppRoutes.inspections,
      title: 'Vehicle Inspections Audit Trail',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search inspections by Vehicle, Plate #, or Customer Name...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchInspections();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _fetchInspections,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading inspection reports...')
                  : _inspections.isEmpty
                      ? AppEmptyState(
                          icon: Icons.fact_check_outlined,
                          title: 'No Inspections Performed',
                          description: 'To conduct a digital vehicle audit, open any Vehicle in the Vehicles registry and tap "Inspect".',
                          actionLabel: 'Go to Vehicles',
                          onAction: () => Get.toNamed(AppRoutes.vehicles),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _inspections.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = _inspections[index];
                              final id = row['id'] as String;
                              final vehicleName = row['vehicle_name'] as String? ?? 'Vehicle';
                              final plateNumber = row['registration_number'] as String? ?? '';
                              final customerName = row['customer_name'] as String? ?? 'Customer';
                              final inspector = row['inspector_name'] as String? ?? 'Advisor';
                              final dateStr = row['inspection_date'] as String? ?? '';
                              final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                              final itemsCount = row['items_count'] ?? 0;
                              final photosCount = row['photos_count'] ?? 0;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text('$vehicleName ($plateNumber)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$itemsCount Parts Inspected',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                      ),
                                    ),
                                    if (photosCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$photosCount Photos',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Customer: $customerName • Inspector: $inspector • Date: ${Formatters.dateTime(date)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                  ),
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () async {
                                    final details = await _inspectionRepo.getInspectionDetails(id);
                                    if (details != null) {
                                      final business = AuthService.to.currentBusiness.value;
                                      if (business != null) {
                                        final inspModel = InspectionModel(
                                          id: id,
                                          businessId: 'local',
                                          vehicleId: details['vehicle_id'],
                                          customerId: details['customer_id'],
                                          inspectorStaffName: details['inspector_name'] ?? 'Advisor',
                                          inspectionDate: DateTime.tryParse(details['inspection_date'] ?? '') ?? DateTime.now(),
                                          diagramParts: (details['items'] as List<dynamic>? ?? []).map((i) {
                                            return InspectionPartItem(
                                              partName: i['part_name'] ?? '',
                                              view: i['view_type'] ?? 'General',
                                              condition: i['condition'] ?? 'Good',
                                              damageDescription: i['damage_description'],
                                              notes: i['notes'],
                                              hasDamage: (i['damage_description'] as String?)?.isNotEmpty == true,
                                            );
                                          }).toList(),
                                        );

                                        await PdfService.printInspectionReport(
                                          business: business,
                                          inspection: inspModel,
                                          vehicleReg: details['registration_number'] ?? '',
                                          vehicleName: details['vehicle_name'] ?? '',
                                          customerName: details['customer_name'] ?? '',
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.print_rounded, size: 16),
                                  label: const Text('Print PDF'),
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
