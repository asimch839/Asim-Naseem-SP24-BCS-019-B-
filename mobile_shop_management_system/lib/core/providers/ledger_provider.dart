import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/payment_record.dart';
import '../models/expense.dart';
import '../models/warranty.dart';

class LedgerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  List<Sale> _sales = [];
  List<Purchase> _purchases = [];
  List<PaymentRecord> _payments = [];
  List<Expense> _expenses = [];
  List<WarrantyRecord> _warranties = [];
  bool _isLoading = false;

  // Getters
  List<Customer> get customers => _customers;
  List<Supplier> get suppliers => _suppliers;
  List<Sale> get sales => _sales;
  List<Purchase> get purchases => _purchases;
  List<PaymentRecord> get payments => _payments;
  List<Expense> get expenses => _expenses;
  List<WarrantyRecord> get warranties => _warranties;
  bool get isLoading => _isLoading;

  double get totalCustomerDues => _customers.fold(0.0, (s, c) => s + c.totalDue);
  double get totalSupplierDues => _suppliers.fold(0.0, (s, sup) => s + sup.dueAmount);
  double get totalExpenses => _expenses.fold(0.0, (s, e) => s + e.amount);

  LedgerProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      _customers = await db.getAllCustomers();
      _suppliers = await db.getAllSuppliers();
      _sales = await db.getAllSales();
      _purchases = await db.getAllPurchases();
      _payments = await db.getAllPayments();
      _expenses = await db.getAllExpenses();
      _warranties = await db.getAllWarranties();
    } catch (e) {
      debugPrint('Error loading ledger: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Customer Actions
  Future<void> addCustomer(Customer customer) async {
    await DatabaseHelper.instance.insertCustomer(customer);
    await loadAll();
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    await loadAll();
  }

  Future<void> deleteCustomer(String id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    await loadAll();
  }

  Future<Customer?> findCustomerByPhone(String phone) async {
    return await DatabaseHelper.instance.findCustomerByPhone(phone);
  }

  // Supplier Actions
  Future<void> addSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.insertSupplier(supplier);
    await loadAll();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.updateSupplier(supplier);
    await loadAll();
  }

  Future<void> deleteSupplier(String id) async {
    await DatabaseHelper.instance.deleteSupplier(id);
    await loadAll();
  }

  // Settle Customer Due
  Future<PaymentRecord> receiveCustomerDue({
    required Customer customer,
    required double amount,
    required String paymentMethod,
    String referenceId = '',
    String notes = '',
    required String collectedBy,
  }) async {
    final receiptNum = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final payment = PaymentRecord(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      receiptNumber: receiptNum,
      type: 'customer_due_payment',
      referenceId: referenceId,
      entityId: customer.id,
      entityName: customer.name,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes.isNotEmpty ? notes : 'Due payment collected from ${customer.name}',
      collectedBy: collectedBy,
    );

    await DatabaseHelper.instance.recordPayment(payment);
    await loadAll();
    return payment;
  }

  // Settle Supplier Due
  Future<PaymentRecord> paySupplierDue({
    required Supplier supplier,
    required double amount,
    required String paymentMethod,
    String referenceId = '',
    String notes = '',
    required String collectedBy,
  }) async {
    final receiptNum = 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final payment = PaymentRecord(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      receiptNumber: receiptNum,
      type: 'supplier_due_payment',
      referenceId: referenceId,
      entityId: supplier.id,
      entityName: supplier.name,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes.isNotEmpty ? notes : 'Payment paid to ${supplier.company}',
      collectedBy: collectedBy,
    );

    await DatabaseHelper.instance.recordPayment(payment);
    await loadAll();
    return payment;
  }

  // Purchases
  Future<void> addPurchase(Purchase purchase) async {
    await DatabaseHelper.instance.insertPurchase(purchase);
    await loadAll();
  }

  // Expenses
  Future<void> addExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
    await loadAll();
  }

  Future<void> deleteExpense(String id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    await loadAll();
  }

  // Warranty
  Future<void> addWarranty(WarrantyRecord war) async {
    await DatabaseHelper.instance.insertWarranty(war);
    await loadAll();
  }

  Future<void> addWarrantyClaim({
    required String warrantyId,
    required String issue,
    required String resolution,
    required String status,
    required String technicianNotes,
  }) async {
    final idx = _warranties.indexWhere((w) => w.id == warrantyId);
    if (idx != -1) {
      final current = _warranties[idx];
      final claim = WarrantyClaim(
        id: 'CLM-${DateTime.now().millisecondsSinceEpoch}',
        warrantyId: current.id,
        reportedIssue: issue,
        resolution: resolution,
        status: status,
        technicianNotes: technicianNotes,
      );
      final updatedClaims = List<WarrantyClaim>.from(current.claims)..add(claim);
      final updated = current.copyWith(claims: updatedClaims, status: 'Claimed');
      await DatabaseHelper.instance.updateWarranty(updated);
      await loadAll();
    }
  }
}
