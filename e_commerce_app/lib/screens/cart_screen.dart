import 'package:flutter/material.dart';
import '../models/cart_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartManager();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Shopping'),
                  )
                ],
              ),
            )
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildCartList()),
                          Expanded(flex: 1, child: SingleChildScrollView(child: _buildSummarySection())),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildCartList()),
                          _buildSummarySection(),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final item = cart.items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isSmall = constraints.maxWidth < 400;
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.product.imageUrl,
                        width: isSmall ? 60 : 100,
                        height: isSmall ? 60 : 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 14 : 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.shippingMethod,
                            style: TextStyle(color: Colors.blueAccent[700], fontSize: 12),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'PKR ${item.product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                          onPressed: () => setState(() => cart.removeItem(i)),
                        ),
                        Row(
                          children: [
                            _qtyBtn(Icons.remove, () => setState(() => cart.updateQuantity(i, -1))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _qtyBtn(Icons.add, () => setState(() => cart.updateQuantity(i, 1))),
                          ],
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _summaryRow('Subtotal', cart.subtotal),
          _summaryRow('Shipping', cart.shippingTotal),
          const Divider(height: 30),
          _summaryRow('Total', cart.grandTotal, isBold: true),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: const Text('PROCEED TO CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('PKR ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.green : Colors.black)),
        ],
      ),
    );
  }
}
