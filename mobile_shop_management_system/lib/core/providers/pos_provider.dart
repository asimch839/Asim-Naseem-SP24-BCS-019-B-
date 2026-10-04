import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/phone_item.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../models/business_settings.dart';

class HeldSale {
  final String id;
  final DateTime heldAt;
  final Customer? customer;
  final List<SaleItem> items;
  final double discount;
  final String note;

  HeldSale({
    required this.id,
    required this.heldAt,
    this.customer,
    required this.items,
    this.discount = 0.0,
    this.note = '',
  });
}

class PosProvider extends ChangeNotifier {
  List<SaleItem> _cartItems = [];
  Customer? _selectedCustomer;
  double _cartDiscount = 0.0;
  String _paymentMethod = 'Cash';
  double _paidAmount = 0.0;
  String _notes = '';
  Map<String, double> _splitPayments = {};

  final List<HeldSale> _heldSales = [];
  bool _isProcessing = false;

  // Getters
  List<SaleItem> get cartItems => _cartItems;
  Customer? get selectedCustomer => _selectedCustomer;
  double get cartDiscount => _cartDiscount;
  String get paymentMethod => _paymentMethod;
  double get paidAmount => _paidAmount;
  String get notes => _notes;
  Map<String, double> get splitPayments => _splitPayments;
  List<HeldSale> get heldSales => _heldSales;
  bool get isProcessing => _isProcessing;

  double get subtotal => _cartItems.fold(0.0, (s, i) => s + (i.unitPrice * i.quantity));
  double get totalItemDiscounts => _cartItems.fold(0.0, (s, i) => s + i.discount);
  double get grandTotal => (subtotal - totalItemDiscounts - _cartDiscount).clamp(0.0, double.infinity);
  double get remainingDue => (grandTotal - _paidAmount).clamp(0.0, double.infinity);

  void addToCartProduct(Product product, {int qty = 1}) {
    final existingIdx = _cartItems.indexWhere((i) => i.productId == product.id && i.imei.isEmpty);
    if (existingIdx != -1) {
      final current = _cartItems[existingIdx];
      _cartItems[existingIdx] = current.copyWith(
        quantity: current.quantity + qty,
        total: (current.quantity + qty) * current.unitPrice - current.discount,
      );
    } else {
      _cartItems.add(
        SaleItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          productType: product.type.name,
          quantity: qty,
          unitPrice: product.salePrice,
          costPrice: product.purchasePrice,
          discount: 0.0,
          total: product.salePrice * qty,
          warrantyMonths: product.warrantyMonths,
        ),
      );
    }
    _recalculateTotals();
    notifyListeners();
  }

  void addToCartPhone(PhoneItem phone) {
    final existing = _cartItems.any((i) => i.imei == phone.imei1);
    if (existing) return;

    _cartItems.add(
      SaleItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${phone.id}',
        productId: phone.productId,
        productName: '${phone.brand} ${phone.model} (${phone.color})',
        productType: 'phone',
        imei: phone.imei1,
        quantity: 1,
        unitPrice: phone.salePrice,
        costPrice: phone.purchasePrice,
        discount: 0.0,
        total: phone.salePrice,
        warrantyMonths: phone.warrantyPeriod.contains('1 Year') ? 12 : 1,
      ),
    );
    _recalculateTotals();
    notifyListeners();
  }

  void updateQuantity(String itemId, int delta) {
    final idx = _cartItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = _cartItems[idx];
      // Phone items cannot have qty > 1
      if (item.productType == 'phone' && delta > 0) return;

      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(idx);
      } else {
        _cartItems[idx] = item.copyWith(
          quantity: newQty,
          total: (newQty * item.unitPrice) - item.discount,
        );
      }
      _recalculateTotals();
      notifyListeners();
    }
  }

  void updateItemPrice(String itemId, double newPrice) {
    final idx = _cartItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = _cartItems[idx];
      _cartItems[idx] = item.copyWith(
        unitPrice: newPrice,
        total: (item.quantity * newPrice) - item.discount,
      );
      _recalculateTotals();
      notifyListeners();
    }
  }

  void updateItemDiscount(String itemId, double discount) {
    final idx = _cartItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = _cartItems[idx];
      _cartItems[idx] = item.copyWith(
        discount: discount,
        total: (item.quantity * item.unitPrice) - discount,
      );
      _recalculateTotals();
      notifyListeners();
    }
  }

  void removeFromCart(String itemId) {
    _cartItems.removeWhere((i) => i.id == itemId);
    _recalculateTotals();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer = null;
    _cartDiscount = 0.0;
    _paymentMethod = 'Cash';
    _paidAmount = 0.0;
    _notes = '';
    _splitPayments.clear();
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setCartDiscount(double discount) {
    _cartDiscount = discount;
    _recalculateTotals();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    if (method != 'Split') {
      _paidAmount = method == 'Due' ? 0.0 : grandTotal;
      _splitPayments.clear();
    }
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    notifyListeners();
  }

  void setSplitPayments(Map<String, double> split) {
    _splitPayments = Map.from(split);
    _paidAmount = split.values.fold(0.0, (s, a) => s + a);
    notifyListeners();
  }

  void setNotes(String val) {
    _notes = val;
    notifyListeners();
  }

  void _recalculateTotals() {
    if (_paymentMethod != 'Split' && _paymentMethod != 'Due') {
      _paidAmount = grandTotal;
    }
  }

  // Hold Sale
  void holdCurrentSale(String note) {
    if (_cartItems.isEmpty) return;
    _heldSales.add(
      HeldSale(
        id: 'HOLD-${DateTime.now().millisecondsSinceEpoch}',
        heldAt: DateTime.now(),
        customer: _selectedCustomer,
        items: List.from(_cartItems),
        discount: _cartDiscount,
        note: note,
      ),
    );
    clearCart();
  }

  // Resume Sale
  void resumeSale(HeldSale held) {
    _cartItems = List.from(held.items);
    _selectedCustomer = held.customer;
    _cartDiscount = held.discount;
    _heldSales.removeWhere((h) => h.id == held.id);
    _recalculateTotals();
    notifyListeners();
  }

  // Complete Checkout
  Future<Sale> checkout({
    required BusinessSettings settings,
    required String cashierId,
    required String cashierName,
  }) async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty. Please add items before checkout.');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final invoiceNum = '${settings.invoicePrefix}${now.millisecondsSinceEpoch.toString().substring(7)}';

      final finalDue = (grandTotal - _paidAmount).clamp(0.0, double.infinity);

      final sale = Sale(
        id: 'SAL-${now.millisecondsSinceEpoch}',
        invoiceNumber: invoiceNum,
        customerId: _selectedCustomer?.id ?? '',
        customerName: _selectedCustomer?.name ?? 'Walk-in Customer',
        customerPhone: _selectedCustomer?.phone ?? '',
        saleDate: now,
        subtotal: subtotal,
        discount: totalItemDiscounts + _cartDiscount,
        tax: 0.0,
        grandTotal: grandTotal,
        paidAmount: _paidAmount,
        dueAmount: finalDue,
        paymentMethod: _paymentMethod,
        paymentBreakdown: _paymentMethod == 'Split' ? _splitPayments : {_paymentMethod: _paidAmount},
        cashierId: cashierId,
        cashierName: cashierName,
        status: 'Completed',
        notes: _notes,
        items: List.from(_cartItems),
      );

      await DatabaseHelper.instance.insertSale(sale);
      clearCart();
      return sale;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
