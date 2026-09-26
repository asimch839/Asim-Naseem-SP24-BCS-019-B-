import 'package:get/get.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../dashboard/dashboard_controller.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepo = ExpenseRepository();

  final expenses = <ExpenseModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final categoryFilter = 'All'.obs;

  late DateTime fromDate;
  late DateTime toDate;
  final dateLabel = 'This Month'.obs;

  final categoryTotals = <String, double>{}.obs;
  final totalExpensesSum = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    fetchExpenses();
  }

  void updateDateRange(DateTime from, DateTime to, String label) {
    fromDate = from;
    toDate = to;
    dateLabel.value = label;
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    isLoading.value = true;
    try {
      final startIso = DateFormatter.toIsoDate(fromDate);
      final endIso = DateFormatter.toIsoDate(toDate);

      expenses.value = await _expenseRepo.getExpenses(
        search: searchQuery.value,
        categoryFilter: categoryFilter.value,
        startDate: startIso,
        endDate: endIso,
      );

      categoryTotals.value = await _expenseRepo.getCategoryWiseExpenses(startIso, endIso);
      totalExpensesSum.value = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load expenses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveExpense({
    int? id,
    required String title,
    required String category,
    required double amount,
    required String expenseDate,
    required String paymentMethod,
    String? description,
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      if (id == null) {
        final newExp = ExpenseModel(
          title: title.trim(),
          category: category,
          amount: amount,
          expenseDate: expenseDate,
          paymentMethod: paymentMethod,
          description: description?.trim(),
          notes: notes?.trim(),
          createdAt: now,
        );
        await _expenseRepo.addExpense(newExp);
        if (Get.isDialogOpen == true) Get.back();
        Get.snackbar('Success', 'Expense recorded successfully!');
      } else {
        final existing = expenses.firstWhere((e) => e.id == id);
        final updated = existing.copyWith(
          title: title.trim(),
          category: category,
          amount: amount,
          expenseDate: expenseDate,
          paymentMethod: paymentMethod,
          description: description?.trim(),
          notes: notes?.trim(),
        );
        await _expenseRepo.updateExpense(updated);
        if (Get.isDialogOpen == true) Get.back();
        Get.snackbar('Success', 'Expense updated successfully!');
      }

      await fetchExpenses();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshData();
      }
    } catch (e) {
      Get.snackbar('Operation Failed', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteExpense(ExpenseModel exp) async {
    try {
      if (exp.id != null) {
        await _expenseRepo.deleteExpense(exp.id!, exp.title);
        Get.snackbar('Deleted', 'Expense "${exp.title}" deleted.');
        await fetchExpenses();
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshData();
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
