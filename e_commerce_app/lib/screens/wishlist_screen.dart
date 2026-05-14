import 'package:flutter/material.dart';
import '../models/wishlist_manager.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final wishlistManager = WishlistManager();

  @override
  Widget build(BuildContext context) {
    final items = wishlistManager.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('Your wishlist is empty!'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final product = items[i];
                return ProductCard(
                  product: product,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/details',
                      arguments: product,
                    );
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
