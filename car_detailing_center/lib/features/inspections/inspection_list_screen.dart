import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/business_model.dart';
import '../../data/models/inspection_model.dart';
import '../../data/repositories/inspection_repository.dart';
import 'inspection_create_screen.dart';
import 'models/diagram_marker_model.dart';
import 'services/vehicle_diagram_renderer.dart';
import 'widgets/car_damage_diagram_painter.dart';

class _InspectionDataHolder {
  final BusinessModel business;
  final InspectionModel inspection;
  final String vehicleReg;
  final String vehicleName;
  final String customerName;
  final String? customerPhone;
  final Uint8List? carDiagramBytes;

  _InspectionDataHolder({
    required this.business,
    required this.inspection,
    required this.vehicleReg,
    required this.vehicleName,
    required this.customerName,
    this.customerPhone,
    this.carDiagramBytes,
  });
}

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

  void _startNewInspection() async {
    final res = await Get.to(() => const InspectionCreateScreen());
    if (res == true) _fetchInspections();
  }

  Color _getDefectColor(String defectType) {
    switch (defectType.toLowerCase().trim()) {
      case 'dent':
        return const Color(0xFFFF3B30);
      case 'scratch':
        return const Color(0xFFFF9500);
      case 'chip':
      case 'stone chip':
        return const Color(0xFFFFCC00);
      case 'crack':
        return const Color(0xFFAF52DE);
      case 'repaint':
      case 'repainted':
        return const Color(0xFF007AFF);
      case 'swirls':
      case 'scuff':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF00B4D8);
    }
  }

  Future<_InspectionDataHolder?> _getReportData(String id) async {
    try {
      final details = await _inspectionRepo.getInspectionDetails(id);
      if (details == null) {
        Get.snackbar('Error', 'Inspection details not found', backgroundColor: AppColors.error.withValues(alpha: 0.2));
        return null;
      }
      final business = AuthService.to.currentBusiness.value ?? BusinessModel(
        id: 'default_business',
        name: "DAWOOD'S GARAGE DETAIL & PERFORMANCE",
        ownerId: 'admin',
        phone: '0306-1361676 | 0335-0001676',
        email: 'contact@dawoodsgarage.com',
        address: 'Behind HBL bank, Hasilpur road Vehari.',
        currency: 'Rs.',
      );

      final items = (details['items'] as List<dynamic>? ?? []);
      final diagramParts = <InspectionPartItem>[];
      final sectionConditions = <String, String>{};
      final driveConditions = <String, String>{};
      final checklist = <ChecklistRecordItem>[];

      for (final i in items) {
        final section = (i['section_name'] as String? ?? '');
        final partName = (i['part_name'] as String? ?? '');
        final condition = (i['condition'] as String? ?? 'Good');
        final damage = i['damage_description'] as String?;
        final notes = i['notes'] as String?;
        final view = (i['view_type'] as String? ?? 'General');

        if (section == 'Diagram Parts' ||
            view == 'General' ||
            view == 'Top' ||
            view == 'Front' ||
            view == 'Rear' ||
            view == 'Left' ||
            view == 'Right' ||
            view == 'Custom') {
          diagramParts.add(InspectionPartItem(
            partName: partName,
            view: view,
            condition: condition,
            damageDescription: damage,
            notes: notes,
            hasDamage: damage != null && damage.isNotEmpty,
          ));
        } else if (section == 'Drive & Systems' || view == 'Mechanical') {
          driveConditions[partName] = condition;
        } else if (section == 'Checklist' || section == 'Belongings' || view == 'Inventory') {
          checklist.add(ChecklistRecordItem(item: partName, status: condition));
        } else {
          sectionConditions[partName] = condition;
        }
      }

      // Attempt to load or render the vehicle inspection diagram
      Uint8List? carDiagramBytes;
      final photos = (details['photos'] as List<dynamic>? ?? []);
      Map<String, dynamic>? diagPhoto;
      for (final ph in photos) {
        if (ph is Map && (ph['photo_type']?.toString().toLowerCase() == 'diagram')) {
          diagPhoto = Map<String, dynamic>.from(ph);
          break;
        }
      }

      if (diagPhoto != null && diagPhoto['file_path'] != null) {
        final f = File(diagPhoto['file_path'] as String);
        if (await f.exists()) {
          try {
            carDiagramBytes = await f.readAsBytes();
          } catch (_) {}
        }
      }

      if (carDiagramBytes == null) {
        try {
          final markers = <DiagramMarker>[];
          final seenKeys = <String>{};

          // 1. Explicit diagram markers
          for (final i in items) {
            final sec = i['section_name']?.toString() ?? '';
            final partName = i['part_name']?.toString() ?? '';
            final viewName = i['view_type']?.toString() ?? 'General';
            final condition = i['condition']?.toString() ?? 'Note';
            final notes = (i['notes']?.toString() ?? i['damage_description']?.toString() ?? '').trim();
            final xPos = (i['x_pos'] as num?)?.toDouble() ?? 0.0;
            final yPos = (i['y_pos'] as num?)?.toDouble() ?? 0.0;

            if (sec == 'Diagram Marker') {
              final key = '$partName-$viewName-$xPos-$yPos';
              seenKeys.add(key);
              markers.add(DiagramMarker(
                id: i['id']?.toString() ?? const Uuid().v4(),
                x: xPos,
                y: yPos,
                defectType: condition,
                panelName: partName,
                viewName: viewName,
                note: notes,
                color: _getDefectColor(condition),
              ));
            }
          }

          // 2. Inspected diagram parts (matches records like c63 where parts were marked)
          for (final i in items) {
            final sec = i['section_name']?.toString() ?? '';
            final partName = i['part_name']?.toString() ?? '';
            final viewName = i['view_type']?.toString() ?? 'General';
            final condition = i['condition']?.toString() ?? 'Note';
            final notes = (i['notes']?.toString() ?? i['damage_description']?.toString() ?? '').trim();

            if (sec == 'Diagram Parts' || sec == 'Diagram' || sec == 'General' || viewName.contains('Side') || viewName == 'Front' || viewName == 'Rear' || viewName == 'Top') {
              final key = '$partName-$viewName';
              if (!seenKeys.any((k) => k.startsWith(key))) {
                seenKeys.add(key);
                final defaultPos = CarDamageDiagramPainter.getPositionForPanel(partName, view: viewName);
                final xPos = ((i['x_pos'] as num?)?.toDouble() ?? 0.0);
                final yPos = ((i['y_pos'] as num?)?.toDouble() ?? 0.0);
                final resolvedX = (xPos > 0.01) ? xPos : defaultPos.dx;
                final resolvedY = (yPos > 0.01) ? yPos : defaultPos.dy;

                markers.add(DiagramMarker(
                  id: i['id']?.toString() ?? const Uuid().v4(),
                  x: resolvedX,
                  y: resolvedY,
                  defectType: condition,
                  panelName: partName,
                  viewName: viewName,
                  note: notes,
                  color: _getDefectColor(condition),
                ));
              }
            }
          }

          carDiagramBytes = await VehicleDiagramRenderer.renderToPngBytes(
            markers: markers,
            isDarkMode: true,
          );
        } catch (e) {
          debugPrint('Diagram renderer fallback error: $e');
        }
      }

      final inspModel = InspectionModel(
        id: id,
        businessId: 'local',
        vehicleId: details['vehicle_id']?.toString() ?? '',
        customerId: details['customer_id']?.toString() ?? '',
        inspectorStaffName: details['inspector_name']?.toString() ?? 'Advisor',
        inspectionDate: DateTime.tryParse(details['inspection_date']?.toString() ?? '') ?? DateTime.now(),
        diagramParts: diagramParts,
        sectionConditions: sectionConditions,
        driveCondition: driveConditions,
        checklist: checklist,
        staffRemarks: details['notes']?.toString(),
      );

      return _InspectionDataHolder(
        business: business,
        inspection: inspModel,
        vehicleReg: details['registration_number']?.toString() ?? '',
        vehicleName: details['vehicle_name']?.toString() ?? '',
        customerName: details['customer_name']?.toString() ?? 'Customer',
        customerPhone: details['customer_phone'] as String?,
        carDiagramBytes: carDiagramBytes,
      );
    } catch (e, stack) {
      debugPrint('Error loading inspection report data: $e\n$stack');
      Get.snackbar('Error', 'Failed to load inspection data: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return null;
    }
  }

  Future<void> _printInspection(String id) async {
    try {
      final data = await _getReportData(id);
      if (data == null) return;
      await PdfService.printInspectionReport(
        business: data.business,
        inspection: data.inspection,
        vehicleReg: data.vehicleReg,
        vehicleName: data.vehicleName,
        customerName: data.customerName,
        carDiagramBytes: data.carDiagramBytes,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to print inspection: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  Future<void> _shareInspection(String id) async {
    try {
      final data = await _getReportData(id);
      if (data == null) return;

      final pdfBytes = await PdfService.buildInspectionReportBytes(
        business: data.business,
        inspection: data.inspection,
        vehicleReg: data.vehicleReg,
        vehicleName: data.vehicleName,
        customerName: data.customerName,
        carDiagramBytes: data.carDiagramBytes,
      );

      final tempDir = await getTemporaryDirectory();
      final baseName = 'Inspection_${data.vehicleReg.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = File('${tempDir.path}/$baseName.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Render high-res A4 picture (PNG)
      String? imagePath;
      final imageBytes = await PdfService.renderInspectionReportToImage(
        business: data.business,
        inspection: data.inspection,
        vehicleReg: data.vehicleReg,
        vehicleName: data.vehicleName,
        customerName: data.customerName,
        carDiagramBytes: data.carDiagramBytes,
      );

      if (imageBytes != null) {
        final imgFile = File('${tempDir.path}/$baseName.png');
        await imgFile.writeAsBytes(imageBytes);
        imagePath = imgFile.path;
      }

      // Copy to Windows Clipboard as Image & File Drop
      if (imagePath != null) {
        await WindowsClipboardService.copyImageToClipboard(imagePath, pdfPath: pdfFile.path);
      } else {
        await WindowsClipboardService.copyFileToClipboard(pdfFile.path);
      }

      // Try opening WhatsApp
      final phone = data.customerPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
      final whatsappUri = Uri.parse(phone.isNotEmpty ? 'whatsapp://send?phone=$phone' : 'whatsapp://send');
      final webWhatsappUri = Uri.parse(phone.isNotEmpty ? 'https://web.whatsapp.com/send?phone=$phone' : 'https://web.whatsapp.com');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri);
      }

      if (!mounted) return;

      Get.snackbar(
        'Copied to Clipboard!',
        'A4 Inspection Sheet copied. Press Ctrl + V in WhatsApp chat to paste!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.25),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366)),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate PDF: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  Future<void> _viewInspection(String id) async {
    final data = await _getReportData(id);
    if (data == null) return;

    try {
      final pdfBytes = await PdfService.buildInspectionReportBytes(
        business: data.business,
        inspection: data.inspection,
        vehicleReg: data.vehicleReg,
        vehicleName: data.vehicleName,
        customerName: data.customerName,
        carDiagramBytes: data.carDiagramBytes,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950, maxHeight: 850),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inspection Sheet: ${data.vehicleName} (${data.vehicleReg})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shareInspection(id);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) async => pdfBytes,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: true,
                    allowSharing: true,
                    pdfFileName: 'Inspection_${data.vehicleReg}.pdf',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to render inspection sheet: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return AppScaffold(
      currentRoute: AppRoutes.inspections,
      title: 'Vehicle Inspections Audit Trail',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewInspection,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Car Inspection'),
      ),
      actions: [
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              onPressed: _startNewInspection,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Inspection'),
            ),
          )
        else
          IconButton(
            onPressed: _startNewInspection,
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'New Inspection',
          ),
      ],
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: isMobile
                              ? 'Search inspections...'
                              : 'Search inspections by Vehicle, Plate #, or Customer Name...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: isMobile,
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
                          description: 'Conduct a digital vehicle audit with interactive body diagram defect marking.',
                          actionLabel: 'New Car Inspection',
                          onAction: _startNewInspection,
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
                                contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 8),
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
                                title: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '$vehicleName ($plateNumber)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
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
                                    if (photosCount > 0)
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
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Customer: $customerName • Inspector: $inspector • Date: ${Formatters.dateTime(date)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: MediaQuery.of(context).size.width < 750
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility_rounded, color: AppColors.primaryLight, size: 20),
                                            tooltip: 'View Sheet',
                                            onPressed: () => _viewInspection(id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
                                            tooltip: 'Share on WhatsApp',
                                            onPressed: () => _shareInspection(id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.print_rounded, color: AppColors.primaryLight, size: 20),
                                            tooltip: 'Print PDF',
                                            onPressed: () => _printInspection(id),
                                          ),
                                        ],
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.visibility_rounded, size: 16),
                                            label: const Text('View'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.primaryLight,
                                              side: const BorderSide(color: AppColors.primaryLight),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: () => _viewInspection(id),
                                          ),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.share_rounded, size: 16),
                                            label: const Text('Share'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF25D366),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: () => _shareInspection(id),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => _printInspection(id),
                                            icon: const Icon(Icons.print_rounded, size: 16),
                                            label: const Text('Print PDF'),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
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
