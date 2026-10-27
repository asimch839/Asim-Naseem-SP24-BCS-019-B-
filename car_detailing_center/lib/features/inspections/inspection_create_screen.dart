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

  // Free-text Section Conditions (User types actual condition per Section 16 & 17)
  final Map<String, TextEditingController> _sectionControllers = {};

  // Drive Condition Fields (Section 22)
  final TextEditingController _driveConditionController = TextEditingController();
  final TextEditingController _steeringController = TextEditingController();
  final TextEditingController _brakeController = TextEditingController();
  final TextEditingController _suspensionController = TextEditingController();
  final TextEditingController _engineBehaviorController = TextEditingController();
  final TextEditingController _transmissionController = TextEditingController();
  final TextEditingController _unusualNoiseController = TextEditingController();
  final TextEditingController _generalObservationController = TextEditingController();

  // Suspension (Section 23)
  final TextEditingController _frontSuspensionController = TextEditingController();
  final TextEditingController _rearSuspensionController = TextEditingController();

  // Electronics (Section 24)
  final TextEditingController _lightsController = TextEditingController();
  final TextEditingController _acController = TextEditingController();
  final TextEditingController _audioController = TextEditingController();
  final TextEditingController _camerasSensorsController = TextEditingController();
  final TextEditingController _locksWindowsController = TextEditingController();

  // Body & Paint (Section 25)
  final TextEditingController _bodyConditionController = TextEditingController();
  final TextEditingController _paintConditionController = TextEditingController();

  // Belongings Checklist (Section 33)
  final List<ChecklistRecordItem> _checklistItems = [];

  final TextEditingController _staffRemarksController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();
  bool _isSaving = false;

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
          MediaQuery.of(context).size.width < 600
              ? IconButton(
                  onPressed: _isSaving ? null : _saveAndGeneratePdf,
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf_rounded),
                  tooltip: 'Save & Generate PDF',
                )
              : ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndGeneratePdf,
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Save & Generate PDF'),
                ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Banner
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 550;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car_rounded, size: 28, color: AppColors.primaryLight),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${activeVehicle.make} ${activeVehicle.model} (${activeVehicle.year ?? "Year N/A"})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Plate: ${activeVehicle.registrationNumber} • Mileage: ${activeVehicle.mileage ?? 0} km • Date: ${Formatters.date(DateTime.now())}'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Inspector: ${AuthService.to.currentUser.value?.fullName ?? "Advisor"}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        const Icon(Icons.directions_car_rounded, size: 28, color: AppColors.primaryLight),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${activeVehicle.make} ${activeVehicle.model} (${activeVehicle.year ?? "Year N/A"})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Plate: ${activeVehicle.registrationNumber} • Mileage: ${activeVehicle.mileage ?? 0} km • Date: ${Formatters.date(DateTime.now())}'),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Inspector: ${AuthService.to.currentUser.value?.fullName ?? "Advisor"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. Interactive Vehicle Body Inspection Diagram (Section 18 & 19)
            VehicleDiagramWidget(
              parts: _diagramParts,
              onPartTap: _onPartTap,
              onAddCustomPart: _addCustomPart,
            ),
            const SizedBox(height: 24),

            // 2. Drive Condition Section (Section 22)
            _buildDriveConditionCard(),
            const SizedBox(height: 24),

            // 3. Suspension & Electronics Section (Section 23 & 24)
            _buildSuspensionAndElectronicsCard(),
            const SizedBox(height: 24),

            // 4. Body & Paint Condition (Section 25)
            _buildBodyAndPaintCard(),
            const SizedBox(height: 24),

            // 5. Configurable Inspection Sections (Section 16 & 17)
            _buildConfigurableSectionsCard(),
            const SizedBox(height: 24),

            // 6. Vehicle Belongings Checklist (Section 33)
            _buildChecklistCard(),
            const SizedBox(height: 24),

            // 7. General Remarks & Signatures
            _buildRemarksAndSignatureCard(),
            const SizedBox(height: 32),

            // Bottom Save Button
            Center(
              child: SizedBox(
                width: 320,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndGeneratePdf,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Complete Inspection & Print Report'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldPair(bool isNarrow, Widget first, Widget second) {
    if (isNarrow) {
      return Column(
        children: [
          first,
          const SizedBox(height: 14),
          second,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 14),
        Expanded(child: second),
      ],
    );
  }

  // DRIVE CONDITION
  Widget _buildDriveConditionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 550;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text('Vehicle Drive Condition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Free-text record of driving dynamics, transmission, steering, and engine behavior.', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                const SizedBox(height: 16),
                _buildFieldPair(
                  isNarrow,
                  TextFormField(
                    controller: _driveConditionController,
                    decoration: const InputDecoration(labelText: 'Drive Condition (e.g. Smooth, Pulls to left, Stiff)'),
                  ),
                  TextFormField(
                    controller: _steeringController,
                    decoration: const InputDecoration(labelText: 'Steering Condition (e.g. Center alignment off, Vibration)'),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFieldPair(
                  isNarrow,
                  TextFormField(
                    controller: _brakeController,
                    decoration: const InputDecoration(labelText: 'Brake Condition (e.g. Squeaking, Spongy pedal, Good)'),
                  ),
                  TextFormField(
                    controller: _suspensionController,
                    decoration: const InputDecoration(labelText: 'Suspension Condition (e.g. Creaking over bumps, Firm)'),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFieldPair(
                  isNarrow,
                  TextFormField(
                    controller: _engineBehaviorController,
                    decoration: const InputDecoration(labelText: 'Engine Behavior (e.g. Normal idle, Hesitation, Ticking sound)'),
                  ),
                  TextFormField(
                    controller: _transmissionController,
                    decoration: const InputDecoration(labelText: 'Transmission Behavior (e.g. Smooth shifting, Delayed reverse)'),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unusualNoiseController,
                  decoration: const InputDecoration(labelText: 'Any Unusual Noise Observed (e.g. Belt whine, Wheel bearing hum)'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // SUSPENSION & ELECTRONICS
  Widget _buildSuspensionAndElectronicsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 550;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text('Suspension & Electronics Inspection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldPair(
                  isNarrow,
                  TextFormField(
                    controller: _frontSuspensionController,
                    decoration: const InputDecoration(labelText: 'Front Suspension (e.g. Bushing wear, Strut leakage)'),
                  ),
                  TextFormField(
                    controller: _rearSuspensionController,
                    decoration: const InputDecoration(labelText: 'Rear Suspension (e.g. Good condition, Sagging springs)'),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFieldPair(
                  isNarrow,
                  TextFormField(
                    controller: _lightsController,
                    decoration: const InputDecoration(labelText: 'Lights & Indicators (e.g. High beam bulb out, Fog light foggy)'),
                  ),
                  TextFormField(
                    controller: _acController,
                    decoration: const InputDecoration(labelText: 'AC & Climate (e.g. Cooling optimal, Odor from blower)'),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFieldPair(
                  isNarrow,
                  TextFormField(
                    controller: _audioController,
                    decoration: const InputDecoration(labelText: 'Audio & Displays (e.g. Touchscreen responsive, Speaker buzz)'),
                  ),
                  TextFormField(
                    controller: _camerasSensorsController,
                    decoration: const InputDecoration(labelText: 'Cameras & Reverse Sensors (e.g. Rear camera lens cloudy)'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // BODY & PAINT
  Widget _buildBodyAndPaintCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_paint_rounded, color: AppColors.primaryLight),
                SizedBox(width: 8),
                Text('Body & Paint Condition (Free Typing)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyConditionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Body Condition (Dents, Scratches, Cracks, Panel Gaps)',
                hintText: 'Type any body abnormalities observed...',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _paintConditionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Paint Condition (Swirl marks, Fading, Oxidation, Repainted panels)',
                hintText: 'Type paint depth, clear coat health, swirl level...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONFIGURABLE SECTIONS
  Widget _buildConfigurableSectionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text('Inspection Areas (Free Text)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    final newSecController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Custom Inspection Section'),
                        content: TextField(
                          controller: newSecController,
                          decoration: const InputDecoration(labelText: 'Section Name (e.g. PPF Status, Ceramic Hydrophobicity)'),
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
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Section'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._sectionControllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          hintText: 'Type condition observation for ${entry.key}...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Rename Section',
                      onPressed: () {
                        final renameCtrl = TextEditingController(text: entry.key);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Rename Inspection Section'),
                            content: TextField(
                              controller: renameCtrl,
                              decoration: const InputDecoration(labelText: 'New Section Name'),
                            ),
                            actions: [
                              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  final newName = renameCtrl.text.trim();
                                  if (newName.isNotEmpty && newName != entry.key) {
                                    setState(() {
                                      final existingText = entry.value.text;
                                      _sectionControllers.remove(entry.key);
                                      _sectionControllers[newName] = TextEditingController(text: existingText);
                                    });
                                    Get.back();
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
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
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // CHECKLIST
  Widget _buildChecklistCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text('Vehicle Belongings & Inventory Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    final itemCtrl = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Checklist Item'),
                        content: TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'Belonging Item')),
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
                            child: const Text('Add Item'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _checklistItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = _checklistItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.item, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: ['Present', 'Missing', 'Damaged', 'N/A'].map((s) {
                                final isSelected = c.status == s;
                                return ChoiceChip(
                                  label: Text(s, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSelected,
                                  selectedColor: s == 'Present' ? AppColors.success : s == 'Missing' ? AppColors.error : AppColors.primary,
                                  onSelected: (_) {
                                    setState(() {
                                      _checklistItems[index] = ChecklistRecordItem(item: c.item, status: s, notes: c.notes);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: Text(c.item, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          Wrap(
                            spacing: 4,
                            children: ['Present', 'Missing', 'Damaged', 'N/A'].map((s) {
                              final isSelected = c.status == s;
                              return ChoiceChip(
                                label: Text(s, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                selectedColor: s == 'Present' ? AppColors.success : s == 'Missing' ? AppColors.error : AppColors.primary,
                                onSelected: (_) {
                                  setState(() {
                                    _checklistItems[index] = ChecklistRecordItem(item: c.item, status: s, notes: c.notes);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // REMARKS & SIGNATURES
  Widget _buildRemarksAndSignatureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Remarks & Sign-off', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                if (isNarrow) ...[
                  TextFormField(
                    controller: _staffRemarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Service Advisor / Inspector Remarks',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerRemarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Customer Notes / Acknowledgement',
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _staffRemarksController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Service Advisor / Inspector Remarks',
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _customerRemarksController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Customer Notes / Acknowledgement',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
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
          },
        ),
      ),
    );
  }
}
