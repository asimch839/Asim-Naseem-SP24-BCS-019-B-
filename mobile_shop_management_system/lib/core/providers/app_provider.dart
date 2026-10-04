import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/business_settings.dart';
import '../models/product.dart';
import '../models/repair_job.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/audit_log.dart';
import '../models/expense.dart';
import '../database/sample_data.dart';

class AppProvider extends ChangeNotifier {
  int _currentNavIndex = 0;
  AppUser _currentUser = SampleData.users.first; // Default to Shop Owner
  List<AppUser> _allUsers = [];
  BusinessSettings _settings = BusinessSettings();
  bool _isLoading = true;

  // Alerts & Notifications
  List<Product> _lowStockProducts = [];
  List<Product> _outOfStockProducts = [];
  List<RepairJob> _pendingRepairs = [];
  List<RepairJob> _readyRepairs = [];
  List<Customer> _customersWithDues = [];
  List<Supplier> _suppliersWithDues = [];
  List<AuditLog> _recentAuditLogs = [];
  List<Expense> _recentExpenses = [];

  // Getters
  int get currentNavIndex => _currentNavIndex;
  AppUser get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  BusinessSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _settings.isDarkMode;

  List<Product> get lowStockProducts => _lowStockProducts;
  List<Product> get outOfStockProducts => _outOfStockProducts;
  List<RepairJob> get pendingRepairs => _pendingRepairs;
  List<RepairJob> get readyRepairs => _readyRepairs;
  List<Customer> get customersWithDues => _customersWithDues;
  List<Supplier> get suppliersWithDues => _suppliersWithDues;
  List<AuditLog> get recentAuditLogs => _recentAuditLogs;
  List<Expense> get recentExpenses => _recentExpenses;

  int get totalNotificationsCount =>
      _lowStockProducts.length +
      _outOfStockProducts.length +
      _readyRepairs.length +
      _customersWithDues.length;

  AppProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      _settings = await db.getSettings();
      _allUsers = await db.getAllUsers();
      if (_allUsers.isNotEmpty && !_allUsers.any((u) => u.id == _currentUser.id)) {
        _currentUser = _allUsers.first;
      }

      await refreshAlerts();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAlerts() async {
    final db = DatabaseHelper.instance;
    final products = await db.getAllProducts();
    _lowStockProducts = products.where((p) => p.isLowStock).toList();
    _outOfStockProducts = products.where((p) => p.isOutOfStock).toList();

    final repairs = await db.getAllRepairs();
    _pendingRepairs = repairs.where((r) => !r.status.isTerminal && r.status != RepairStatus.readyForDelivery).toList();
    _readyRepairs = repairs.where((r) => r.status == RepairStatus.readyForDelivery).toList();

    final customers = await db.getAllCustomers();
    _customersWithDues = customers.where((c) => c.totalDue > 0).toList();

    final suppliers = await db.getAllSuppliers();
    _suppliersWithDues = suppliers.where((s) => s.dueAmount > 0).toList();

    _recentAuditLogs = (await db.getAllAuditLogs()).take(10).toList();
    _recentExpenses = (await db.getAllExpenses()).take(10).toList();
    notifyListeners();
  }

  void setNavIndex(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  void switchUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await DatabaseHelper.instance.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> updateSettings(BusinessSettings newSettings) async {
    _settings = newSettings;
    await DatabaseHelper.instance.updateSettings(newSettings);
    notifyListeners();
  }

  Future<void> reloadAll() async {
    await loadInitialData();
  }
}
