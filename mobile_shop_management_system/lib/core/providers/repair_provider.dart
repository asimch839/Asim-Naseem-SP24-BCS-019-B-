import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/repair_job.dart';
import '../models/product.dart';
import '../models/payment_record.dart';

class RepairProvider extends ChangeNotifier {
  List<RepairJob> _repairs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  RepairStatus? _filterStatus;
  String _filterTechnician = 'All';

  List<RepairJob> get repairs => _repairs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  RepairStatus? get filterStatus => _filterStatus;
  String get filterTechnician => _filterTechnician;

  List<RepairJob> get filteredRepairs {
    return _repairs.where((r) {
      if (_filterStatus != null && r.status != _filterStatus) return false;
      if (_filterTechnician != 'All' && r.technicianName != _filterTechnician) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = r.jobId.toLowerCase().contains(q) ||
            r.customerName.toLowerCase().contains(q) ||
            r.customerPhone.contains(q) ||
            r.deviceBrand.toLowerCase().contains(q) ||
            r.deviceModel.toLowerCase().contains(q) ||
            r.imei.contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  // Kanban groupings
  List<RepairJob> get receivedJobs => _repairs.where((r) => r.status == RepairStatus.received).toList();
  List<RepairJob> get inspectionJobs => _repairs.where((r) => r.status == RepairStatus.inspection).toList();
  List<RepairJob> get inProgressJobs => _repairs.where((r) => r.status == RepairStatus.inProgress || r.status == RepairStatus.approved).toList();
  List<RepairJob> get waitingForPartsJobs => _repairs.where((r) => r.status == RepairStatus.waitingForParts || r.status == RepairStatus.waitingForCustomer || r.status == RepairStatus.waitingForApproval).toList();
  List<RepairJob> get readyJobs => _repairs.where((r) => r.status == RepairStatus.readyForDelivery || r.status == RepairStatus.completed).toList();
  List<RepairJob> get deliveredJobs => _repairs.where((r) => r.status == RepairStatus.delivered).toList();

  RepairProvider() {
    loadRepairs();
  }

  Future<void> loadRepairs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _repairs = await DatabaseHelper.instance.getAllRepairs();
    } catch (e) {
      debugPrint('Error loading repairs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterStatus(RepairStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterTechnician(String tech) {
    _filterTechnician = tech;
    notifyListeners();
  }

  Future<void> createRepairJob(RepairJob job) async {
    await DatabaseHelper.instance.insertRepair(job);
    if (job.advancePaid > 0) {
      final pay = PaymentRecord(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        receiptNumber: 'REC-ADV-${job.jobId}',
        type: 'repair_advance',
        referenceId: job.jobId,
        entityId: job.customerId,
        entityName: job.customerName,
        amount: job.advancePaid,
        paymentMethod: job.paymentMethod,
        notes: 'Advance deposit for Repair Job #${job.jobId}',
        collectedBy: job.technicianName,
      );
      await DatabaseHelper.instance.recordPayment(pay);
    }
    await loadRepairs();
  }

  Future<void> updateRepairStatus({
    required String repairId,
    required RepairStatus newStatus,
    required String changedBy,
    String notes = '',
  }) async {
    final idx = _repairs.indexWhere((r) => r.id == repairId);
    if (idx != -1) {
      final current = _repairs[idx];
      final newHist = List<RepairStatusHistory>.from(current.history)
        ..add(
          RepairStatusHistory(
            id: 'RSH-${DateTime.now().millisecondsSinceEpoch}',
            repairId: current.id,
            status: newStatus,
            changedBy: changedBy,
            notes: notes,
          ),
        );

      final updated = current.copyWith(
        status: newStatus,
        history: newHist,
        deliveredAt: newStatus == RepairStatus.delivered ? DateTime.now() : current.deliveredAt,
      );

      await DatabaseHelper.instance.updateRepair(updated);
      await loadRepairs();
    }
  }

  Future<void> addPartToRepair({
    required String repairId,
    required Product partProduct,
    required int quantity,
    required double sellingPrice,
    required String technicianName,
  }) async {
    final idx = _repairs.indexWhere((r) => r.id == repairId);
    if (idx != -1) {
      final current = _repairs[idx];
      final newPart = RepairPart(
        id: 'RP-${DateTime.now().millisecondsSinceEpoch}',
        productId: partProduct.id,
        partName: partProduct.name,
        quantity: quantity,
        costPrice: partProduct.purchasePrice,
        sellingPrice: sellingPrice,
      );

      final updatedParts = List<RepairPart>.from(current.partsUsed)..add(newPart);
      final newPartsTotal = updatedParts.fold(0.0, (s, p) => s + p.totalSellingPrice);
      final newFinalTotal = (current.laborCharges + newPartsTotal + current.otherCharges) - current.discount;
      final newDue = (newFinalTotal - current.advancePaid).clamp(0.0, double.infinity);

      final updated = current.copyWith(
        partsUsed: updatedParts,
        finalTotal: newFinalTotal,
        remainingDue: newDue,
      );

      await DatabaseHelper.instance.updateRepair(updated);

      // Deduct inventory
      await DatabaseHelper.instance.adjustProductStock(
        partProduct.id,
        -quantity,
        'Consumed in Repair Job #${current.jobId}',
        technicianName,
      );

      await loadRepairs();
    }
  }

  Future<void> updateCosts({
    required String repairId,
    required double labor,
    required double other,
    required double discount,
  }) async {
    final idx = _repairs.indexWhere((r) => r.id == repairId);
    if (idx != -1) {
      final current = _repairs[idx];
      final partsTotal = current.partsUsed.fold(0.0, (s, p) => s + p.totalSellingPrice);
      final newFinalTotal = (labor + partsTotal + other) - discount;
      final newDue = (newFinalTotal - current.advancePaid).clamp(0.0, double.infinity);

      final updated = current.copyWith(
        laborCharges: labor,
        otherCharges: other,
        discount: discount,
        finalTotal: newFinalTotal,
        remainingDue: newDue,
      );

      await DatabaseHelper.instance.updateRepair(updated);
      await loadRepairs();
    }
  }

  Future<void> deliverAndSettle({
    required String repairId,
    required double paymentAmount,
    required String paymentMethod,
    required String deliveredBy,
  }) async {
    final idx = _repairs.indexWhere((r) => r.id == repairId);
    if (idx != -1) {
      final current = _repairs[idx];
      final newRemaining = (current.remainingDue - paymentAmount).clamp(0.0, double.infinity);

      final newHist = List<RepairStatusHistory>.from(current.history)
        ..add(
          RepairStatusHistory(
            id: 'RSH-${DateTime.now().millisecondsSinceEpoch}',
            repairId: current.id,
            status: RepairStatus.delivered,
            changedBy: deliveredBy,
            notes: 'Delivered to customer. Received remaining balance Rs. $paymentAmount via $paymentMethod',
          ),
        );

      final updated = current.copyWith(
        status: RepairStatus.delivered,
        remainingDue: newRemaining,
        deliveredAt: DateTime.now(),
        history: newHist,
      );

      await DatabaseHelper.instance.updateRepair(updated);

      if (paymentAmount > 0) {
        final pay = PaymentRecord(
          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
          receiptNumber: 'REC-BAL-${current.jobId}',
          type: 'repair_balance',
          referenceId: current.jobId,
          entityId: current.customerId,
          entityName: current.customerName,
          amount: paymentAmount,
          paymentMethod: paymentMethod,
          notes: 'Settled remaining balance for Repair Job #${current.jobId}',
          collectedBy: deliveredBy,
        );
        await DatabaseHelper.instance.recordPayment(pay);
      }

      await loadRepairs();
    }
  }
}
