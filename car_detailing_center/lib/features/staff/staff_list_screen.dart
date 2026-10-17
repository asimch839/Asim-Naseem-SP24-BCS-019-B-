import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/staff_repository.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/staff_model.dart';
import 'staff_form_dialog.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _staffRepo = StaffRepository();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final canViewSalaries = AuthService.to.canAccessSalaries();

    return AppScaffold(
      currentRoute: AppRoutes.staff,
      title: 'Staff Management & Team',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (_) => const StaffFormDialog(),
          );
          if (res == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Staff Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Staff Name, Designation, Phone, or CNIC...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: FutureBuilder<List<StaffModel>>(
                future: _staffRepo.getStaffList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(message: 'Loading staff directory...');
                  }

                  final allStaff = snapshot.data ?? [];
                  final filtered = allStaff.where((s) {
                    final matches = s.name.toLowerCase().contains(_searchQuery) ||
                        s.designation.toLowerCase().contains(_searchQuery) ||
                        s.phone.contains(_searchQuery) ||
                        (s.cnic != null && s.cnic!.contains(_searchQuery));
                    return matches;
                  }).toList();

                  if (filtered.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.badge_outlined,
                      title: 'No Staff Found',
                      description: 'Onboard your detailing specialists, technicians, and supervisors.',
                      actionLabel: 'Add Staff Member',
                      onAction: () {
                        showDialog(
                          context: context,
                          builder: (_) => const StaffFormDialog(),
                        );
                      },
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final st = filtered[index];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              st.name[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(st.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  st.designation,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Phone: ${st.phone} ${st.cnic != null ? "• CNIC: ${st.cnic}" : ""} • Structure: ${st.salaryType} • Joined: ${Formatters.date(st.joiningDate)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canViewSalaries)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Base Salary', style: TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
                                    Text(
                                      Formatters.currency(st.baseSalary, symbol: currency),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () async {
                                  final res = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => StaffFormDialog(staff: st),
                                  );
                                  if (res == true && mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
