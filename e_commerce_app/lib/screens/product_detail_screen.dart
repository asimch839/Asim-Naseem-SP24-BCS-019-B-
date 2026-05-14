import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_manager.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String _selectedShipping = 'Standard Delivery';
  final List<String> _shippingMethods = [
    'Standard Delivery',
    'Express Delivery',
    'Same Day Delivery'
  ];

  final cartManager = CartManager();

  @override
  Widget build(BuildContext context) {
    // Safe argument extraction
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    
    if (args == null || args is! Product) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 10),
              const Text('Product information not found!'),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              )
            ],
          ),
        ),
      );
    }

    final Product product = args;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          // Instant updating badge in AppBar
          ValueListenableBuilder<int>(
            valueListenable: cartManager.cartCountNotifier,
            builder: (context, count, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Safe Image Loading
            Hero(
              tag: 'product-${product.id}',
              child: Image.network(
                product.imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('PKR ${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(product.description, style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5)),
                  const SizedBox(height: 30),
                  
                  const Text('Select Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQtyAction(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('$_quantity', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      _buildQtyAction(Icons.add, () => setState(() => _quantity++)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  const Text('Shipping Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedShipping,
                        items: _shippingMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setState(() => _selectedShipping = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          onPressed: () {
            cartManager.addItem(product, _quantity, _selectedShipping);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart!'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(label: 'VIEW CART', onPressed: () => Navigator.pushNamed(context, '/cart')),
              ),
            );
          },
          child: const Text('ADD TO CART', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildQtyAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blueAccent),
      ),
    );
  }
}
