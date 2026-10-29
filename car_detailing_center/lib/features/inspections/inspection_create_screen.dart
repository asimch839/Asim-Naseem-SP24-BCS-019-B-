import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/vehicle_model.dart';
import 'widgets/vehicle_diagram_widget.dart';
import 'widgets/part_inspection_dialog.dart';

class InspectionCreateScreen extends StatefulWidget {
  final VehicleModel? vehicle;
  final VehicleModel? preselectedVehicle;
  final String? preselectedCustomerId;
  final String? preselectedCustomerName;
  final String? jobId;

  const InspectionCreateScreen({
    super.key,
    this.vehicle,
    this.preselectedVehicle,
    this.preselectedCustomerId,
    this.preselectedCustomerName,
    this.jobId,
  });

  VehicleModel get activeVehicle => vehicle ?? preselectedVehicle!;

  @override
  State<InspectionCreateScreen> createState() => _InspectionCreateScreenState();
}

class _InspectionCreateScreenState extends State<InspectionCreateScreen> {
  VehicleModel get activeVehicle => widget.activeVehicle;

  // Diagram Parts List
  final List<InspectionPartItem> _diagramParts = [];

  // Free-text Section Conditions (Configurable areas)
  final Map<String, TextEditingController> _sectionControllers = {};

  // Drive Condition Fields
  final TextEditingController _driveConditionController = TextEditingController();
  final TextEditingController _steeringController = TextEditingController();
  final TextEditingController _brakeController = TextEditingController();
  final TextEditingController _suspensionController = TextEditingController();
  final TextEditingController _engineBehaviorController = TextEditingController();
  final TextEditingController _transmissionController = TextEditingController();
  final TextEditingController _unusualNoiseController = TextEditingController();
  final TextEditingController _generalObservationController = TextEditingController();

  // Suspension & Electronics Fields
  final TextEditingController _frontSuspensionController = TextEditingController();
  final TextEditingController _rearSuspensionController = TextEditingController();
  final TextEditingController _lightsController = TextEditingController();
  final TextEditingController _acController = TextEditingController();
  final TextEditingController _audioController = TextEditingController();
  final TextEditingController _camerasSensorsController = TextEditingController();
  final TextEditingController _locksWindowsController = TextEditingController();

  // Body & Paint Fields
  final TextEditingController _bodyConditionController = TextEditingController();
  final TextEditingController _paintConditionController = TextEditingController();

  // Belongings Checklist
  final List<ChecklistRecordItem> _checklistItems = [];

  final TextEditingController _staffRemarksController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();
  bool _isSaving = false;

  // Accordion Expand/Collapse State
  final Map<String, bool> _sectionExpanded = {
    'diagram': true,
    'drive': false,
    'suspension': false,
    'body': false,
    'areas': false,
    'checklist': false,
    'remarks': false,
  };

  final List<String> _defaultChecklistTitles = [
    'Spare Wheel & Jack',
    'Toolkit & Rod',
    'Floor Mats (Front & Rear)',
    'Audio / Media Player & Remote',
    'Perfume / Freshener',
    'Original Documents / Tax Token',
    'Cigarette Lighter',
    'Personal Valuables & Belongings',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default checklist items
    final business = AuthService.to.currentBusiness.value;
    final checklistSource = business?.checklistItems ?? _defaultChecklistTitles;
    for (var item in checklistSource) {
      _checklistItems.add(ChecklistRecordItem(item: item, status: 'Present'));
    }

    // Default Sections
    final defaultSections = [
      'Exterior Condition',
      'Interior Condition',
      'Tires & Wheels',
      'Engine Bay & Fluids',
      'Windscreen & Mirrors',
      'Underchassis & Exhaust',
    ];
    for (var s in defaultSections) {
      _sectionControllers[s] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _sectionControllers.values) {
      c.dispose();
    }
    _driveConditionController.dispose();
    _steeringController.dispose();
    _brakeController.dispose();
    _suspensionController.dispose();
    _engineBehaviorController.dispose();
    _transmissionController.dispose();
    _unusualNoiseController.dispose();
    _generalObservationController.dispose();
    _frontSuspensionController.dispose();
    _rearSuspensionController.dispose();
    _lightsController.dispose();
    _acController.dispose();
    _audioController.dispose();
    _camerasSensorsController.dispose();
    _locksWindowsController.dispose();
    _bodyConditionController.dispose();
    _paintConditionController.dispose();
    _staffRemarksController.dispose();
    _customerRemarksController.dispose();
    super.dispose();
  }

  void _onPartTap(InspectionPartItem part) {
    showDialog(
      context: context,
      builder: (_) => PartInspectionDialog(
        part: part,
        onSave: (updated) {
          setState(() {
            final idx = _diagramParts.indexWhere((p) => p.partName == updated.partName);
            if (idx != -1) {
              _diagramParts[idx] = updated;
            } else {
              _diagramParts.add(updated);
            }
          });
        },
        onDelete: part.view == 'Custom'
            ? () {
                setState(() {
                  _diagramParts.removeWhere((p) => p.partName == part.partName);
                });
              }
            : null,
      ),
    );
  }

  void _addCustomPart() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Vehicle Part'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Part Name *',
              hintText: 'e.g., Right Fender, Bull Bar, Spoiler, Running Board',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Get.back();
                  _onPartTap(InspectionPartItem(partName: name, view: 'Custom', condition: 'Good'));
                }
              },
              child: const Text('Add & Inspect'),
            ),
          ],
        );
      },
    );
  }

  // --- 1-TAP FAST PASS ACTIONS ---
  void _setAllMechanicalNormal() {
    setState(() {
      _driveConditionController.text = 'Normal / Smooth operation';
      _steeringController.text = 'Normal / Accurate alignment';
      _brakeController.text = 'Normal / Good pedal feel';
      _suspensionController.text = 'Normal / Smooth ride';
      _engineBehaviorController.text = 'Normal idle / Responsive acceleration';
      _transmissionController.text = 'Normal / Smooth gear shifts';
      _unusualNoiseController.text = 'None detected';
      _generalObservationController.text = 'All driving dynamics within normal spec';
    });
    Get.snackbar(
      'Mechanical Checked',
      'All 7 mechanical systems set to Normal / Good',
      backgroundColor: AppColors.success.withValues(alpha: 0.25),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _setAllSuspensionElectronicsWorking() {
    setState(() {
      _frontSuspensionController.text = 'Good / Firm';
      _rearSuspensionController.text = 'Good / Firm';
      _lightsController.text = 'All headlights, tails & indicators working';
      _acController.text = 'AC cooling optimal / Fan blower normal';
      _audioController.text = 'Touchscreen & audio working';
      _camerasSensorsController.text = 'Cameras & parking sensors operational';
      _locksWindowsController.text = 'Power windows & locks working';
    });
    Get.snackbar(
      'Electrical & Suspension Checked',
      'All electrical and suspension fields set to Working',
      backgroundColor: AppColors.success.withValues(alpha: 0.25),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _setAllDetailAreasGood() {
    setState(() {
      for (var entry in _sectionControllers.entries) {
        entry.value.text = 'Clean / Good condition';
      }
    });
    Get.snackbar(
      'Inspection Areas Checked',
      'All inspection areas marked as Clean / Good',
      backgroundColor: AppColors.success.withValues(alpha: 0.25),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _setAllBelongingsPresent() {
    setState(() {
      for (int i = 0; i < _checklistItems.length; i++) {
        _checklistItems[i] = ChecklistRecordItem(
          item: _checklistItems[i].item,
          status: 'Present',
          notes: _checklistItems[i].notes,
        );
      }
    });
    Get.snackbar(
      'Checklist Updated',
      'All items marked as Present',
      backgroundColor: AppColors.success.withValues(alpha: 0.25),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _toggleAllSections(bool expand) {
    setState(() {
      for (var key in _sectionExpanded.keys) {
        _sectionExpanded[key] = expand;
      }
    });
  }

  void _saveAndGeneratePdf() async {
    setState(() => _isSaving = true);
    final businessId = AuthService.to.businessId;
    final staff = AuthService.to.currentUser.value;
    final inspectionId = const Uuid().v4();

    // Compile section conditions
    final Map<String, String> sectionConditions = {};
    for (var entry in _sectionControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        sectionConditions[entry.key] = entry.value.text.trim();
      }
    }

    // Compile Drive Condition Map
    final Map<String, String> driveCondition = {
      'Drive Condition': _driveConditionController.text.trim(),
      'Steering Condition': _steeringController.text.trim(),
      'Brake Condition': _brakeController.text.trim(),
      'Suspension Condition': _suspensionController.text.trim(),
      'Engine Behavior': _engineBehaviorController.text.trim(),
      'Transmission Behavior': _transmissionController.text.trim(),
      'Unusual Noise': _unusualNoiseController.text.trim(),
      'Observations': _generalObservationController.text.trim(),
      'Front Suspension': _frontSuspensionController.text.trim(),
      'Rear Suspension': _rearSuspensionController.text.trim(),
      'Lights': _lightsController.text.trim(),
      'AC': _acController.text.trim(),
      'Audio': _audioController.text.trim(),
      'Cameras & Sensors': _camerasSensorsController.text.trim(),
      'Locks & Windows': _locksWindowsController.text.trim(),
      'Body Condition': _bodyConditionController.text.trim(),
      'Paint Condition': _paintConditionController.text.trim(),
    };

    // Gather all photos
    final List<String> allPhotos = [];
    for (var p in _diagramParts) {
      allPhotos.addAll(p.photoUrls);
    }

    final inspection = InspectionModel(
      id: inspectionId,
      businessId: businessId,
      vehicleId: activeVehicle.id,
      customerId: activeVehicle.customerId,
      jobId: widget.jobId,
      inspectorStaffId: staff?.uid ?? 'inspector',
      inspectorStaffName: staff?.fullName ?? 'Service Advisor',
      inspectionDate: DateTime.now(),
      diagramParts: _diagramParts,
      sectionConditions: sectionConditions,
      driveCondition: driveCondition,
      checklist: _checklistItems,
      staffRemarks: _staffRemarksController.text.trim().isNotEmpty ? _staffRemarksController.text.trim() : null,
      customerRemarks: _customerRemarksController.text.trim().isNotEmpty ? _customerRemarksController.text.trim() : null,
      damagePhotoUrls: allPhotos,
    );

    try {
      final inspRepo = Get.find<InspectionRepository>();
      final custRepo = Get.find<CustomerRepository>();

      final List<Map<String, dynamic>> itemsToSave = [];
      for (var p in _diagramParts) {
        itemsToSave.add({
          'section_name': 'Diagram Parts',
          'part_name': p.partName,
          'condition': p.condition,
          'damage_description': p.damageDescription ?? '',
          'notes': p.notes ?? '',
          'view_type': p.view,
        });
      }
      for (var entry in _sectionControllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          itemsToSave.add({
            'section_name': entry.key,
            'part_name': entry.key,
            'condition': entry.value.text.trim(),
            'view_type': 'Section',
          });
        }
      }

      final List<Map<String, dynamic>> photosToSave = [];
      for (var ph in allPhotos) {
        photosToSave.add({
          'photo_type': 'Damage',
          'file_path': ph,
        });
      }

      await inspRepo.saveInspection(
        id: inspectionId,
        vehicleId: activeVehicle.id,
        customerId: activeVehicle.customerId,
        jobId: widget.jobId,
        inspectorName: staff?.fullName ?? 'Service Advisor',
        inspectionDate: DateTime.now(),
        items: itemsToSave,
        photos: photosToSave,
        notes: _staffRemarksController.text.trim(),
      );

      final business = AuthService.to.currentBusiness.value;
      if (business != null) {
        final cust = await custRepo.getCustomerById(activeVehicle.customerId);
        await PdfService.printInspectionReport(
          business: business,
          inspection: inspection,
          vehicleReg: activeVehicle.registrationNumber,
          vehicleName: '${activeVehicle.make} ${activeVehicle.model}',
          customerName: cust?.fullName ?? widget.preselectedCustomerName ?? 'Customer',
        );
      }

      Get.back(result: true);
      Get.snackbar(
        'Inspection Complete',
        'Inspection saved to SQLite & comprehensive PDF generated',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save inspection: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allCollapsed = _sectionExpanded.values.every((v) => !v);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inspection: ${activeVehicle.make} ${activeVehicle.model} (${activeVehicle.registrationNumber})',
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Expand/Collapse all toggle
          TextButton.icon(
            onPressed: () => _toggleAllSections(allCollapsed),
            icon: Icon(allCollapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded, size: 16),
            label: Text(allCollapsed ? 'Expand All' : 'Collapse All', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAndGeneratePdf,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Save & PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Vehicle Info Banner
            _buildVehicleBanner(),
            const SizedBox(height: 14),

            // 2. Interactive Vehicle Body Diagram
            _buildCollapsibleCard(
              id: 'diagram',
              icon: Icons.directions_car_rounded,
              title: 'Vehicle Diagram & Marked Parts',
              subtitle: 'Tap any body part to record dents, scratches, or wear',
              statusBadge: '${_diagramParts.length} Parts Marked',
              badgeColor: _diagramParts.isEmpty ? AppColors.textDarkMuted : AppColors.primaryLight,
              child: VehicleDiagramWidget(
                parts: _diagramParts,
                onPartTap: _onPartTap,
                onAddCustomPart: _addCustomPart,
              ),
            ),
            const SizedBox(height: 12),

            // 3. Drive Dynamics & Mechanical Section
            _buildCollapsibleCard(
              id: 'drive',
              icon: Icons.speed_rounded,
              title: 'Drive & Mechanical Check',
              subtitle: 'Transmission, steering, braking, engine dynamics & noises',
              trailingAction: TextButton.icon(
                onPressed: _setAllMechanicalNormal,
                icon: const Icon(Icons.flash_on_rounded, size: 15, color: AppColors.success),
                label: const Text('Set All Normal', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
              child: _buildDriveConditionContent(),
            ),
            const SizedBox(height: 12),

            // 4. Suspension & Electrical Systems
            _buildCollapsibleCard(
              id: 'suspension',
              icon: Icons.tune_rounded,
              title: 'Suspension, Lights & Electronics',
              subtitle: 'Struts, headlights, AC cooling, sensors, and power windows',
              trailingAction: TextButton.icon(
                onPressed: _setAllSuspensionElectronicsWorking,
                icon: const Icon(Icons.flash_on_rounded, size: 15, color: AppColors.success),
                label: const Text('Set All Working', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
              child: _buildSuspensionElectronicsContent(),
            ),
            const SizedBox(height: 12),

            // 5. Body & Paint Observations
            _buildCollapsibleCard(
              id: 'body',
              icon: Icons.format_paint_rounded,
              title: 'Body Panels & Paint Condition',
              subtitle: 'Panel gaps, swirl marks, clear coat scratches, and repainted areas',
              child: _buildBodyPaintContent(),
            ),
            const SizedBox(height: 12),

            // 6. Configurable Inspection Sections
            _buildCollapsibleCard(
              id: 'areas',
              icon: Icons.category_rounded,
              title: 'Detailed Inspection Areas',
              subtitle: 'Exterior, interior, tires, engine bay, windscreen & chassis',
              trailingAction: TextButton.icon(
                onPressed: _setAllDetailAreasGood,
                icon: const Icon(Icons.flash_on_rounded, size: 15, color: AppColors.success),
                label: const Text('Set All Good', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
              child: _buildInspectionAreasContent(),
            ),
            const SizedBox(height: 12),

            // 7. Belongings Checklist
            _buildCollapsibleCard(
              id: 'checklist',
              icon: Icons.checklist_rounded,
              title: 'Vehicle Belongings Checklist',
              subtitle: 'Document valuables, spare wheel, documents, and tools',
              statusBadge: '${_checklistItems.where((c) => c.status == 'Present').length}/${_checklistItems.length} Present',
              badgeColor: AppColors.success,
              trailingAction: TextButton.icon(
                onPressed: _setAllBelongingsPresent,
                icon: const Icon(Icons.done_all_rounded, size: 15, color: AppColors.success),
                label: const Text('All Present', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
              child: _buildChecklistContent(),
            ),
            const SizedBox(height: 12),

            // 8. Remarks & Customer Sign-off
            _buildCollapsibleCard(
              id: 'remarks',
              icon: Icons.verified_user_rounded,
              title: 'Remarks & Customer Sign-off',
              subtitle: 'Advisor notes, customer acknowledgement, and pre-existing condition agreement',
              child: _buildRemarksContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --- VEHICLE TOP BANNER ---
  Widget _buildVehicleBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activeVehicle.make} ${activeVehicle.model} ${activeVehicle.year != null ? "(${activeVehicle.year})" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Plate: ${activeVehicle.registrationNumber} • Mileage: ${activeVehicle.mileage ?? 0} km • Date: ${Formatters.date(DateTime.now())}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Advisor: ${AuthService.to.currentUser.value?.fullName ?? "Advisor"}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE COLLAPSIBLE SECTION CARD ---
  Widget _buildCollapsibleCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailingAction,
    String? statusBadge,
    Color badgeColor = AppColors.primary,
  }) {
    final isExpanded = _sectionExpanded[id] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? AppColors.primary.withValues(alpha: 0.45) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isExpanded ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _sectionExpanded[id] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primaryLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            if (statusBadge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(statusBadge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  ?trailingAction,
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textDarkSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  // --- REUSABLE QUICK RATING INPUT COMPONENT ---
  Widget _buildQuickField({
    required String label,
    required TextEditingController controller,
    List<String> options = const ['Normal / Good', 'Fair', 'Needs Attention', 'N/A'],
  }) {
    final currentText = controller.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (currentText.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => controller.clear()),
                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((opt) {
              final isSelected = currentText.toLowerCase() == opt.toLowerCase() ||
                  (opt.startsWith('Normal') && (currentText.toLowerCase().contains('normal') || currentText.toLowerCase().contains('smooth') || currentText.toLowerCase().contains('good')));

              Color chipColor = AppColors.primary;
              if (opt.toLowerCase().contains('good') || opt.toLowerCase().contains('normal') || opt.toLowerCase().contains('working')) {
                chipColor = AppColors.success;
              } else if (opt.toLowerCase().contains('fair')) {
                chipColor = AppColors.warning;
              } else if (opt.toLowerCase().contains('attention') || opt.toLowerCase().contains('repair')) {
                chipColor = AppColors.error;
              }

              return ChoiceChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: chipColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      controller.text = opt;
                    } else {
                      controller.clear();
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Or type custom note for $label...',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // --- 1. DRIVE CONDITION CONTENT ---
  Widget _buildDriveConditionContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuickField(
                      label: 'Drive Condition',
                      controller: _driveConditionController,
                      options: const ['Normal / Smooth', 'Pulls to Left/Right', 'Sluggish Response', 'N/A'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickField(
                      label: 'Steering Condition',
                      controller: _steeringController,
                      options: const ['Normal / Centered', 'Alignment Off', 'Steering Vibration', 'N/A'],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuickField(
                      label: 'Brake Condition',
                      controller: _brakeController,
                      options: const ['Normal / Responsive', 'Squeaking / Noise', 'Spongy Pedal', 'N/A'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickField(
                      label: 'Suspension Dynamics',
                      controller: _suspensionController,
                      options: const ['Normal / Smooth', 'Creaking Over Bumps', 'Excessive Bouncing', 'N/A'],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuickField(
                      label: 'Engine Behavior',
                      controller: _engineBehaviorController,
                      options: const ['Normal Idle / Smooth', 'Rough Idle', 'Ticking / Noise', 'N/A'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickField(
                      label: 'Transmission Behavior',
                      controller: _transmissionController,
                      options: const ['Normal / Smooth Shifts', 'Delayed Engagement', 'Gear Jerking', 'N/A'],
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildQuickField(
                label: 'Drive Condition',
                controller: _driveConditionController,
                options: const ['Normal / Smooth', 'Pulls to Left/Right', 'Sluggish', 'N/A'],
              ),
              _buildQuickField(
                label: 'Steering Condition',
                controller: _steeringController,
                options: const ['Normal / Centered', 'Alignment Off', 'Vibration', 'N/A'],
              ),
              _buildQuickField(
                label: 'Brake Condition',
                controller: _brakeController,
                options: const ['Normal / Responsive', 'Squeaking', 'Spongy', 'N/A'],
              ),
              _buildQuickField(
                label: 'Suspension Dynamics',
                controller: _suspensionController,
                options: const ['Normal / Smooth', 'Creaking', 'Bouncy', 'N/A'],
              ),
              _buildQuickField(
                label: 'Engine Behavior',
                controller: _engineBehaviorController,
                options: const ['Normal Idle', 'Rough Idle', 'Noise', 'N/A'],
              ),
              _buildQuickField(
                label: 'Transmission Behavior',
                controller: _transmissionController,
                options: const ['Normal Shifts', 'Delayed', 'Jerking', 'N/A'],
              ),
            ],
            _buildQuickField(
              label: 'Unusual Noise Observed',
              controller: _unusualNoiseController,
              options: const ['None / Silent', 'Belt Whine', 'Wheel Bearing Hum', 'Exhaust Leak'],
            ),
          ],
        );
      },
    );
  }

  // --- 2. SUSPENSION & ELECTRONICS CONTENT ---
  Widget _buildSuspensionElectronicsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuickField(
                      label: 'Front Suspension',
                      controller: _frontSuspensionController,
                      options: const ['Normal / Firm', 'Bushing Wear', 'Strut Leakage', 'N/A'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickField(
                      label: 'Rear Suspension',
                      controller: _rearSuspensionController,
                      options: const ['Normal / Firm', 'Sagging Springs', 'Shock Leakage', 'N/A'],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuickField(
                      label: 'Lights & Indicators',
                      controller: _lightsController,
                      options: const ['All Working', 'Bulb Blown', 'Lens Foggy', 'N/A'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickField(
                      label: 'AC & Climate Control',
                      controller: _acController,
                      options: const ['Cooling Optimal', 'Weak Airflow', 'Odor from Blower', 'N/A'],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuickField(
                      label: 'Audio & Displays',
                      controller: _audioController,
                      options: const ['All Working', 'Touch Lag', 'Speaker Buzz', 'N/A'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickField(
                      label: 'Cameras & Reverse Sensors',
                      controller: _camerasSensorsController,
                      options: const ['All Functional', 'Lens Cloudy', 'Sensor Fault', 'N/A'],
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildQuickField(
                label: 'Front Suspension',
                controller: _frontSuspensionController,
                options: const ['Normal / Firm', 'Bushing Wear', 'Leakage', 'N/A'],
              ),
              _buildQuickField(
                label: 'Rear Suspension',
                controller: _rearSuspensionController,
                options: const ['Normal / Firm', 'Sagging Springs', 'Leakage', 'N/A'],
              ),
              _buildQuickField(
                label: 'Lights & Indicators',
                controller: _lightsController,
                options: const ['All Working', 'Bulb Blown', 'Foggy', 'N/A'],
              ),
              _buildQuickField(
                label: 'AC & Climate',
                controller: _acController,
                options: const ['Cooling Optimal', 'Weak Airflow', 'Odor', 'N/A'],
              ),
              _buildQuickField(
                label: 'Audio & Displays',
                controller: _audioController,
                options: const ['All Working', 'Touch Lag', 'Speaker Buzz', 'N/A'],
              ),
              _buildQuickField(
                label: 'Cameras & Sensors',
                controller: _camerasSensorsController,
                options: const ['All Functional', 'Lens Cloudy', 'Sensor Fault', 'N/A'],
              ),
            ],
            _buildQuickField(
              label: 'Locks & Windows',
              controller: _locksWindowsController,
              options: const ['All Functional', 'Slow Window Motor', 'Lock Actuator Stuck', 'N/A'],
            ),
          ],
        );
      },
    );
  }

  // --- 3. BODY & PAINT CONTENT ---
  Widget _buildBodyPaintContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickField(
          label: 'Body Panel Condition',
          controller: _bodyConditionController,
          options: const ['Clean / No Dents', 'Minor Door Dings', 'Scratches Present', 'Panel Gap Issue'],
        ),
        _buildQuickField(
          label: 'Paintwork & Clear Coat Condition',
          controller: _paintConditionController,
          options: const ['Gloss Optimal', 'Light Swirl Marks', 'Heavy Swirls & Oxidation', 'Repainted Panels'],
        ),
      ],
    );
  }

  // --- 4. CONFIGURABLE AREAS CONTENT ---
  Widget _buildInspectionAreasContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select standard condition or type custom notes:',
              style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
            TextButton.icon(
              onPressed: () {
                final newSecController = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add Custom Section'),
                    content: TextField(
                      controller: newSecController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Section Name (e.g. PPF Status, Ceramic Coating)'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          if (newSecController.text.trim().isNotEmpty) {
                            setState(() {
                              _sectionControllers[newSecController.text.trim()] = TextEditingController();
                            });
                            Get.back();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 15),
              label: const Text('+ Add Custom Area', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._sectionControllers.entries.map((entry) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickField(
                  label: entry.key,
                  controller: entry.value,
                  options: const ['Clean / Good', 'Needs Detailing', 'Heavy Soiled', 'Scratches / Wear'],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                tooltip: 'Remove Section',
                onPressed: () {
                  setState(() {
                    _sectionControllers.remove(entry.key);
                  });
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  // --- 5. CHECKLIST CONTENT ---
  Widget _buildChecklistContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick tap each item status:',
              style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
            TextButton.icon(
              onPressed: () {
                final itemCtrl = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add Belonging Item'),
                    content: TextField(
                      controller: itemCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          if (itemCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              _checklistItems.add(ChecklistRecordItem(item: itemCtrl.text.trim(), status: 'Present'));
                            });
                            Get.back();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 15),
              label: const Text('+ Add Belonging', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _checklistItems.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = _checklistItems[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(c.item, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Wrap(
                    spacing: 6,
                    children: ['Present', 'Missing', 'Damaged', 'N/A'].map((s) {
                      final isSelected = c.status == s;
                      Color chipColor = AppColors.primary;
                      if (s == 'Present') chipColor = AppColors.success;
                      if (s == 'Missing') chipColor = AppColors.error;
                      if (s == 'Damaged') chipColor = AppColors.warning;

                      return ChoiceChip(
                        label: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: chipColor,
                        onSelected: (_) {
                          setState(() {
                            _checklistItems[index] = ChecklistRecordItem(item: c.item, status: s, notes: c.notes);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- 6. REMARKS & SIGNATURES ---
  Widget _buildRemarksContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _staffRemarksController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Service Advisor / Inspector Remarks',
            hintText: 'e.g., Customer advised for 2-stage paint correction before ceramic application...',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerRemarksController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Customer Instructions & Special Requests',
            hintText: 'e.g., Pay special attention to dog hair on rear seats...',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Customer agrees that all pre-existing scratches, dents, and belongings listed above reflect the accurate condition of the vehicle prior to detailing.',
                  style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- PERSISTENT BOTTOM ACTION BAR ---
  Widget _buildBottomActionBar() {
    final presentCount = _checklistItems.where((c) => c.status == 'Present').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildStatPill('Diagram Parts', '${_diagramParts.length} marked', Icons.touch_app_rounded),
                  _buildStatPill('Checklist', '$presentCount/${_checklistItems.length} Present', Icons.checklist_rounded),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAndGeneratePdf,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save & Print PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text('$title: ', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
        ],
      ),
    );
  }
}
