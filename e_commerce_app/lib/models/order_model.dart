import 'cart_item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String status;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    this.status = 'Processing',
  });
}

class OrderManager {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  void addOrder(List<CartItem> items, double total) {
    _orders.insert(
      0,
      Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: items,
        totalAmount: total,
        date: DateTime.now(),
      ),
    );
  }
}
