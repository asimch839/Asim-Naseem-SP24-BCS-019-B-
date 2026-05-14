import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String shippingMethod;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.shippingMethod = 'Standard Delivery',
  });
}
