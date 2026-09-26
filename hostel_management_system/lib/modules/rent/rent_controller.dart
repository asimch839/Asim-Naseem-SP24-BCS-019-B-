import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/rent_record_model.dart';
import '../../data/models/receipt_model.dart';
import '../../data/repositories/rent_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/services/app_refresh_service.dart';
import '../../core/services/whatsapp_service.dart';

class RentController extends GetxController {
  final RentRepository _rentRepo = RentRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  final rentRecords = <RentRecordModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;
  final monthFilter = 'All'.obs;

  // Monthly billing generator state
  final isGeneratingBills = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRentRecords();
  }

  Future<void> fetchRentRecords() async {
    isLoading.value = true;
    try {
      rentRecords.value = await _rentRepo.getRentRecords(
        search: searchQuery.value,
        statusFilter: statusFilter.value,
        monthFilter: monthFilter.value,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load rent records: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateBills(String targetMonth) async {
    isGeneratingBills.value = true;
    try {
      final settings = await _settingsRepo.getSettings();
      final count = await _rentRepo.generateMonthlyBills(
        targetMonth,
        dueDay: settings.rentDueDay,
      );
      Get.snackbar(
        'Billing Complete',
        count > 0 ? 'Successfully generated $count monthly rent records for $targetMonth.' : 'Rent records for $targetMonth already exist for all active students.',
      );
      await AppRefreshService.refreshAll();
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isGeneratingBills.value = false;
    }
  }

  Future<ReceiptModel> recordPayment({
    required int rentRecordId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    double securityAmount = 0.0,
    String? notes,
  }) async {
    try {
      final receipt = await _rentRepo.recordPayment(
        rentRecordId: rentRecordId,
        paymentAmount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        securityAmount: securityAmount,
        notes: notes,
      );

      await AppRefreshService.refreshAll();
      return receipt;
    } catch (e) {
      rethrow;
    }
  }

  /// Open WhatsApp rent due reminder dialog with prefilled details
  Future<void> sendRentReminder(BuildContext context, RentRecordModel rent) async {
    try {
      final settings = await _settingsRepo.getSettings();
      if (!context.mounted) return;
      WhatsAppService.showRentReminderDialog(
        context: context,
        rent: rent,
        settings: settings,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not open reminder dialog: $e');
    }
  }
}
