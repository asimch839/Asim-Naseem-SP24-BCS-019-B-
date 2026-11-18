import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/showroom_car_model.dart';
import '../../data/repositories/showroom_repository.dart';
import 'showroom_car_form_dialog.dart';
import 'showroom_sale_dialog.dart';

class CarShowroomScreen extends StatefulWidget {
  const CarShowroomScreen({super.key});

  @override
  State<CarShowroomScreen> createState() => _CarShowroomScreenState();
}

class _CarShowroomScreenState extends State<CarShowroomScreen> with SingleTickerProviderStateMixin {
  final _showroomRepo = ShowroomRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  late TabController _tabController;
  String _searchQuery = '';
  String _dealTypeFilter = 'All'; // All, inventory, commission

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _currentTabStatus {
    switch (_tabController.index) {
      case 0:
        return 'Available';
      case 1:
        return 'Sold';
      case 2:
        return 'Booked';
      default:
        return 'All';
    }
  }

  Future<void> _openAddCarDialog({bool isCommission = false}) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShowroomCarFormDialog(initialIsCommission: isCommission),
    );
    if (res == true && mounted) setState(() {});
  }

  Future<void> _openEditCarDialog(ShowroomCarModel car) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShowroomCarFormDialog(car: car),
    );
    if (res == true && mounted) setState(() {});
  }

  Future<void> _openSaleDialog(ShowroomCarModel car) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShowroomSaleDialog(car: car),
    );
    if (res == true && mounted) setState(() {});
  }

  Future<void> _recordTokenDialog(ShowroomCarModel car) async {
    final tokenCtrl = TextEditingController(text: car.tokenAmount > 0 ? car.tokenAmount.toStringAsFixed(0) : '');
    final nameCtrl = TextEditingController(text: car.buyerName ?? '');
    final phoneCtrl = TextEditingController(text: car.buyerPhone ?? '');
    final notesCtrl = TextEditingController(text: car.notes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.bookmark_added_rounded, color: AppColors.warning, size: 22),
            SizedBox(width: 8),
            Text('Book Car / Record Token Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Record advance token money received for ${car.displayName} (${car.registrationNumber}):',
                style: const TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: tokenCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Token Amount (PKR) *', prefixIcon: Icon(Icons.payments_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Buyer Name *', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Buyer Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Token Agreement Notes', prefixIcon: Icon(Icons.notes_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(tokenCtrl.text.trim()) ?? 0.0;
              final name = nameCtrl.text.trim();
              if (amt <= 0 || name.isEmpty) {
                Get.snackbar('Required', 'Please enter valid token amount and buyer name', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                return;
              }
              await _showroomRepo.markAsBooked(
                id: car.id,
                tokenAmount: amt,
                buyerName: name,
                buyerPhone: phoneCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              if (mounted) setState(() {});
              Get.snackbar('Car Booked', 'Token money recorded for ${car.displayName}', backgroundColor: AppColors.success.withValues(alpha: 0.2));
            },
            child: const Text('Save Token Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCar(ShowroomCarModel car) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Car Deal / Record'),
        content: Text('Are you sure you want to remove "${car.displayName}" (${car.registrationNumber}) from the showroom?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _showroomRepo.deleteCar(car.id);
      Get.snackbar('Deleted', 'Car record removed from showroom');
      if (mounted) setState(() {});
    }
  }

  Future<void> _printCarDealReceipt(ShowroomCarModel car) async {
    final business = AuthService.to.currentBusiness.value;
    if (business == null) return;

    try {
      await PdfService.printCarDealReceipt(business: business, car: car);
    } catch (e) {
      Get.snackbar('Print Error', 'Could not print car deal receipt: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  void _showMobileAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                const Text('Choose Deal Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Add Showroom Car', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Showroom Stock: Car purchased for floor sale'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.cardDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAddCarDialog(isCommission: false);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    child: const Icon(Icons.handshake_rounded, color: AppColors.success),
                  ),
                  title: const Text('Add Commission Deal', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Brokerage Deal: Car procured for customer'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.cardDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAddCarDialog(isCommission: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final isMobile = ResponsiveLayout.isMobile(context);

    return AppScaffold(
      currentRoute: AppRoutes.showroom,
      title: 'Car Showroom & Brokerage Deals',
      actions: isMobile
          ? [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight),
                tooltip: 'Add Showroom Car',
                onPressed: () => _openAddCarDialog(isCommission: false),
              ),
              IconButton(
                icon: const Icon(Icons.handshake_rounded, color: AppColors.success),
                tooltip: 'Add Commission Deal',
                onPressed: () => _openAddCarDialog(isCommission: true),
              ),
            ]
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _openAddCarDialog(isCommission: false),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Showroom Car'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _openAddCarDialog(isCommission: true),
                  icon: const Icon(Icons.handshake_rounded, size: 18),
                  label: const Text('Add Commission Deal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              heroTag: 'mobileShowroomFab',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Deal / Car'),
              onPressed: () => _showMobileAddOptions(context),
            )
          : Wrap(
              direction: Axis.horizontal,
              spacing: 8,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'addCommissionFab',
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () => _openAddCarDialog(isCommission: true),
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Commission Deal'),
                ),
                FloatingActionButton.extended(
                  heroTag: 'addShowroomCarFab',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _openAddCarDialog(isCommission: false),
                  icon: const Icon(Icons.directions_car_filled_rounded),
                  label: const Text('Add Showroom Car'),
                ),
              ],
            ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          children: [
            // 1. Top KPI Summary Cards
            FutureBuilder<Map<String, dynamic>>(
              future: _showroomRepo.getShowroomKPIs(),
              builder: (context, snapshot) {
                final kpi = snapshot.data ?? {};
                final availCount = kpi['available_count'] ?? 0;
                final totalCost = (kpi['total_inventory_cost'] as num?)?.toDouble() ?? 0.0;
                final totalDemand = (kpi['total_demand_value'] as num?)?.toDouble() ?? 0.0;
                final soldCount = kpi['sold_count'] ?? 0;
                final totalSoldProfit = (kpi['total_profit_earned'] as num?)?.toDouble() ?? 0.0;
                final totalCommission = (kpi['total_commission_earned'] as num?)?.toDouble() ?? 0.0;
                final totalCarIncome = (kpi['total_car_trading_income'] as num?)?.toDouble() ?? 0.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;
                    final isTablet = constraints.maxWidth > 580;

                    if (isDesktop) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Cars Available for Sale',
                              value: '$availCount Cars',
                              subtitle: 'Demand: ${Formatters.currency(totalDemand, symbol: currency)}',
                              icon: Icons.directions_car_filled_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Showroom Stock Investment',
                              value: Formatters.currency(totalCost, symbol: currency),
                              subtitle: 'Active capital on floor',
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Cars Sold & Delivered',
                              value: '$soldCount Sold',
                              subtitle: 'Completed sales & deals',
                              icon: Icons.verified_rounded,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Car Sales & Commission Income',
                              value: Formatters.currency(totalCarIncome, symbol: currency),
                              subtitle: 'Realized profit added to accounts',
                              icon: Icons.trending_up_rounded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      );
                    }

                    final crossCount = isTablet ? 2 : 1;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isTablet ? 2.4 : 3.2,
                      children: [
                        _buildKpiCard(
                          title: 'Cars Available for Sale',
                          value: '$availCount Cars',
                          subtitle: 'Demand: ${Formatters.currency(totalDemand, symbol: currency)}',
                          icon: Icons.directions_car_filled_rounded,
                          color: AppColors.primary,
                        ),
                        _buildKpiCard(
                          title: 'Showroom Stock Cost',
                          value: Formatters.currency(totalCost, symbol: currency),
                          subtitle: 'Active capital on floor',
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        _buildKpiCard(
                          title: 'Cars Sold & Delivered',
                          value: '$soldCount Sold',
                          subtitle: 'Completed deals',
                          icon: Icons.verified_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                        _buildKpiCard(
                          title: 'Total Car Income (Profit + Comm)',
                          value: Formatters.currency(totalCarIncome, symbol: currency),
                          subtitle: 'Added to garage income',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.success,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. Search & Category Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;
                    if (isNarrow) {
                      return Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search make, model, reg #, color, buyer...',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _dealTypeFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Deal Category', isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Deal Types')),
                              DropdownMenuItem(value: 'inventory', child: Text('Showroom Stock Only')),
                              DropdownMenuItem(value: 'commission', child: Text('Commission / Brokerage Only')),
                            ],
                            onChanged: (v) => setState(() => _dealTypeFilter = v ?? 'All'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search make, model, reg #, color, seller, buyer...',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 14),
                        DropdownButton<String>(
                          value: _dealTypeFilter,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Deal Types')),
                            DropdownMenuItem(value: 'inventory', child: Text('Showroom Stock Only')),
                            DropdownMenuItem(value: 'commission', child: Text('Commission / Brokerage Only')),
                          ],
                          onChanged: (v) => setState(() => _dealTypeFilter = v ?? 'All'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Status Tabs (Available, Sold, Booked, All)
            TabBar(
              controller: _tabController,
              isScrollable: isMobile,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.directions_car_rounded, size: 18), text: 'Available for Sale'),
                Tab(icon: Icon(Icons.verified_rounded, size: 18), text: 'Sold Cars Archive'),
                Tab(icon: Icon(Icons.bookmark_added_rounded, size: 18), text: 'Booked / Token'),
                Tab(icon: Icon(Icons.view_list_rounded, size: 18), text: 'All Records'),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Car Deals Grid / List
            Expanded(
              child: FutureBuilder<List<ShowroomCarModel>>(
                future: _showroomRepo.getCars(
                  status: _currentTabStatus,
                  dealType: _dealTypeFilter,
                  searchQuery: _searchQuery,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(message: 'Loading showroom cars & deals...');
                  }

                  final cars = snapshot.data ?? [];
                  if (cars.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.directions_car_filled_rounded,
                      title: 'No Cars Found',
                      description: _currentTabStatus == 'Available'
                          ? 'No cars currently available for sale on the showroom floor. Click "Add Showroom Car" or "Add Commission Deal" to list one.'
                          : 'No records matching the selected status and search criteria.',
                      actionLabel: 'Add Car for Sale',
                      onAction: () => _openAddCarDialog(isCommission: false),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: cars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final car = cars[idx];
                      return _buildCarCard(car, currency);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(ShowroomCarModel car, String currency) {
    Color statusColor = AppColors.success;
    if (car.status == 'Sold') statusColor = const Color(0xFF6366F1);
    if (car.status == 'Booked') statusColor = const Color(0xFFF59E0B);

    final isCommission = car.isCommission;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: car.isSold
              ? AppColors.success.withValues(alpha: 0.3)
              : car.isBooked
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : Theme.of(context).dividerColor,
          width: car.isSold || car.isBooked ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 740;

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Icon / Thumbnail
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Icon(
                        isCommission ? Icons.handshake_rounded : Icons.directions_car_filled_rounded,
                        color: statusColor,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Car Info
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              car.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                car.status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCommission ? Colors.purple : AppColors.primary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCommission ? 'Brokerage Deal' : 'Showroom Stock',
                                style: TextStyle(color: isCommission ? Colors.purpleAccent : AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _specChip(Icons.pin_rounded, 'Reg: ${car.registrationNumber}'),
                            if (car.color != null && car.color!.isNotEmpty)
                              _specChip(Icons.palette_outlined, 'Color: ${car.color}'),
                            if (car.condition != null && car.condition!.isNotEmpty)
                              _specChip(Icons.verified_outlined, 'Condition: ${car.condition}'),
                            _specChip(Icons.person_outline_rounded, 'Customer: ${car.customerName}'),
                            _specChip(Icons.phone_outlined, car.customerPhone),
                          ],
                        ),
                        if (car.notes != null && car.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Notes: ${car.notes}', style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                        ],
                        if (car.isSold && car.buyerName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Sold to: ${car.buyerName} (${car.buyerPhone ?? ""}) on ${car.saleDate != null ? DateFormat("dd MMM yyyy").format(car.saleDate!) : ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ] else if (car.isBooked && car.buyerName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Booked by: ${car.buyerName} (Token: ${Formatters.currency(car.tokenAmount, symbol: currency)})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Pricing & Profit Details
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (car.isSold) ...[
                            Text(
                              'Sold Price: ${Formatters.currency(car.soldPrice, symbol: currency)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Commission: +${Formatters.currency(car.effectiveProfit, symbol: currency)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                                ),
                              ],
                            ),
                            if (car.buyerCommission > 0 || car.sellerCommission > 0)
                              Text(
                                'Buyer: ${Formatters.currency(car.buyerCommission, symbol: currency)} • Seller: ${Formatters.currency(car.sellerCommission, symbol: currency)}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
                              ),
                          ] else ...[
                            Text(
                              'Demand: ${Formatters.currency(car.demandPrice, symbol: currency)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryLight),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Customer Price: ${Formatters.currency(car.customerPrice, symbol: currency)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Actions
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!car.isSold) ...[
                        ElevatedButton.icon(
                          onPressed: () => _openSaleDialog(car),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: Text(isCommission ? 'Close Deal' : 'Mark as Sold'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!car.isBooked)
                          OutlinedButton.icon(
                            onPressed: () => _recordTokenDialog(car),
                            icon: const Icon(Icons.bookmark_add_outlined, size: 15),
                            label: const Text('Token / Book', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF59E0B),
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                          ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: () => _printCarDealReceipt(car),
                          icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primaryLight),
                          label: const Text('Deal Receipt (PDF)', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textDarkSecondary),
                            tooltip: 'Edit details',
                            onPressed: () => _openEditCarDialog(car),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            tooltip: 'Delete',
                            onPressed: () => _deleteCar(car),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }

            // Mobile view
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Icon(
                          isCommission ? Icons.handshake_rounded : Icons.directions_car_filled_rounded,
                          color: statusColor,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(car.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(car.registrationNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryLight)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(car.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (car.color != null && car.color!.isNotEmpty)
                      _specChip(Icons.palette_outlined, car.color!),
                    if (car.condition != null && car.condition!.isNotEmpty)
                      _specChip(Icons.verified_outlined, car.condition!),
                    _specChip(Icons.person_outline_rounded, car.customerName),
                    _specChip(Icons.phone_outlined, car.customerPhone),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (car.isSold) ...[
                          Text('Sold: ${Formatters.currency(car.soldPrice, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'Commission: +${Formatters.currency(car.effectiveProfit, symbol: currency)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                          if (car.buyerCommission > 0 || car.sellerCommission > 0)
                            Text(
                              'Buyer: ${Formatters.currency(car.buyerCommission, symbol: currency)} • Seller: ${Formatters.currency(car.sellerCommission, symbol: currency)}',
                              style: const TextStyle(fontSize: 9, color: AppColors.textDarkSecondary),
                            ),
                        ] else ...[
                          Text('Demand: ${Formatters.currency(car.demandPrice, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight)),
                          Text('Customer Price: ${Formatters.currency(car.customerPrice, symbol: currency)}', style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (!car.isSold)
                          ElevatedButton(
                            onPressed: () => _openSaleDialog(car),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Sell', style: TextStyle(fontSize: 11)),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.print_rounded, size: 18),
                            tooltip: 'Print Deal',
                            onPressed: () => _printCarDealReceipt(car),
                          ),
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openEditCarDialog(car)),
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), onPressed: () => _deleteCar(car)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _specChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textDarkSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
      ],
    );
  }
}

