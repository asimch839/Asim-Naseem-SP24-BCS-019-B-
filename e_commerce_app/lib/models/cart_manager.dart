import 'package:flutter/material.dart';
import 'cart_item.dart';
import 'product.dart';

class CartManager {
  // Singleton Pattern
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> items = [];
  
  // ValueNotifier for real-time updates across the app
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  void addItem(Product product, int quantity, String shippingMethod) {
    int index = items.indexWhere((item) => 
      item.product.id == product.id && item.shippingMethod == shippingMethod
    );
    
    if (index >= 0) {
      items[index].quantity += quantity;
    } else {
      items.add(CartItem(
        product: product, 
        quantity: quantity, 
        shippingMethod: shippingMethod
      ));
    }
    _notify();
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      _notify();
    }
  }

  void updateQuantity(int index, int delta) {
    if (index >= 0 && index < items.length) {
      items[index].quantity += delta;
      if (items[index].quantity <= 0) {
        items.removeAt(index);
      }
      _notify();
    }
  }

  void clearCart() {
    items.clear();
    _notify();
  }

  void _notify() {
    cartCountNotifier.value = totalItemCount;
  }

  double get subtotal => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  
  double get shippingTotal {
    return items.fold(0, (sum, item) {
      if (item.shippingMethod == 'Express Delivery') return sum + 15.0;
      if (item.shippingMethod == 'Same Day Delivery') return sum + 25.0;
      return sum + 5.0; // Standard
    });
  }

  double get grandTotal => subtotal + shippingTotal;

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
