import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/phone_item.dart';
import '../models/stock_movement.dart';

class InventoryProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<PhoneItem> _phones = [];
  List<StockMovement> _movements = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  ProductType? _selectedType;
  String _stockFilter = 'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'

  // Getters
  List<Product> get products => _products;
  List<PhoneItem> get phones => _phones;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  ProductType? get selectedType => _selectedType;
  String get stockFilter => _stockFilter;

  List<Product> get filteredProducts {
    return _products.where((p) {
      if (_selectedType != null && p.type != _selectedType) return false;
      if (_selectedCategory != 'All' && p.category != _selectedCategory) return false;

      if (_stockFilter == 'Low Stock' && !p.isLowStock) return false;
      if (_stockFilter == 'Out of Stock' && !p.isOutOfStock) return false;
      if (_stockFilter == 'In Stock' && p.isOutOfStock) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  List<PhoneItem> get filteredPhones {
    return _phones.where((ph) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = ph.brand.toLowerCase().contains(q) ||
            ph.model.toLowerCase().contains(q) ||
            ph.imei1.contains(q) ||
            ph.imei2.contains(q) ||
            ph.serialNumber.toLowerCase().contains(q) ||
            ph.color.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  List<String> get categories {
    final set = {'All', ..._products.map((p) => p.category)};
    return set.toList();
  }

  InventoryProvider() {
    loadInventory();
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      _products = await db.getAllProducts();
      _phones = await db.getAllPhoneItems();
      _movements = await db.getAllStockMovements();
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSelectedCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setSelectedType(ProductType? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setStockFilter(String filter) {
    _stockFilter = filter;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    await loadInventory();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await loadInventory();
  }

  Future<void> deleteProduct(String id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await loadInventory();
  }

  Future<void> addPhoneItem(PhoneItem phone) async {
    await DatabaseHelper.instance.insertPhoneItem(phone);
    await loadInventory();
  }

  Future<void> updatePhoneItem(PhoneItem phone) async {
    await DatabaseHelper.instance.updatePhoneItem(phone);
    await loadInventory();
  }

  Future<void> adjustStock({
    required String productId,
    required int delta,
    required String reason,
    required String performedBy,
  }) async {
    await DatabaseHelper.instance.adjustProductStock(productId, delta, reason, performedBy);
    await loadInventory();
  }

  Future<PhoneItem?> findByImei(String imei) async {
    return await DatabaseHelper.instance.findPhoneByImei(imei);
  }
}
