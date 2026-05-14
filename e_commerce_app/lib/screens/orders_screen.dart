import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderData = OrderManager();
    final orders = orderData.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text('No orders placed yet!'),
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final order = orders[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text('Order ID: ${order.id}'),
                    subtitle: Text(
                      'Total: PKR ${order.totalAmount.toStringAsFixed(2)} - ${DateFormat('dd/MM/yyyy hh:mm a').format(order.date)}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(order.status, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(),
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.product.name} x${item.quantity}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'PKR ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
