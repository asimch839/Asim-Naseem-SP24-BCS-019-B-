import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/models/receipt_model.dart';
import '../../data/repositories/rent_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../widgets/custom_button.dart';

class ReceiptController extends GetxController {
  final RentRepository _rentRepo = RentRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  final receipts = <ReceiptModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final monthFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReceipts();
  }

  Future<void> fetchReceipts() async {
    isLoading.value = true;
    try {
      receipts.value = await _rentRepo.getAllReceipts(
        search: searchQuery.value,
        monthFilter: monthFilter.value,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load receipts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareReceiptWhatsApp(ReceiptModel receipt) async {
    final settings = await _settingsRepo.getSettings();
    if (Get.context != null) {
      WhatsAppService.showShareDialog(
        context: Get.context!,
        receipt: receipt,
        settings: settings,
      );
    }
  }

  Future<void> previewReceipt(ReceiptModel receipt) async {
    final settings = await _settingsRepo.getSettings();
    final isThermal = false.obs;

    Get.dialog(
      Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          final isNarrow = screenSize.width < 640;

          final titleCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Receipt Preview (${receipt.receiptNumber})',
                style: AppStyles.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                'Student: ${receipt.studentName} • ${receipt.studentIdCode}',
                style: AppStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actionsRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('A4')),
                  ButtonSegment(value: true, label: Text('Thermal')),
                ],
                selected: {isThermal.value},
                onSelectionChanged: (set) => isThermal.value = set.first,
              )),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Share',
                icon: Icons.share_rounded,
                type: ButtonType.secondary,
                height: 36,
                onPressed: () {
                  WhatsAppService.showShareDialog(
                    context: context,
                    receipt: receipt,
                    settings: settings,
                    isThermal: isThermal.value,
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Close',
                onPressed: () {
                  if (Get.isDialogOpen == true) Get.back();
                },
              ),
            ],
          );

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 850,
                maxHeight: screenSize.height * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleCol,
                              const SizedBox(height: 10),
                              actionsRow,
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: titleCol),
                              const SizedBox(width: 12),
                              actionsRow,
                            ],
                          ),
                    const Divider(height: 20),

                    // PDF Preview View
                    Expanded(
                      child: Obx(() {
                        final thermal = isThermal.value;
                        return PdfPreview(
                          key: ValueKey(thermal),
                          build: (format) async {
                            if (thermal) {
                              return await PdfService.generateReceiptPdfThermal(receipt: receipt, settings: settings);
                            } else {
                              return await PdfService.generateReceiptPdfA4(receipt: receipt, settings: settings);
                            }
                          },
                          allowPrinting: true,
                          allowSharing: true,
                          pdfFileName: 'Receipt_${receipt.receiptNumber}.pdf',
                          onShared: (context) async {
                            WhatsAppService.showShareDialog(
                              context: context,
                              receipt: receipt,
                              settings: settings,
                              isThermal: isThermal.value,
                            );
                          },
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          dynamicLayout: false,
                          previewPageMargin: const EdgeInsets.all(12),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
