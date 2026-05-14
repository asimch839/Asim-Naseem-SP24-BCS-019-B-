class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
  });
}

final List<Product> dummyProducts = [
  Product(
    id: 'p1',
    name: 'Classic White T-Shirt',
    description: 'A comfortable and stylish white t-shirt made from 100% cotton. Perfect for everyday wear.',
    price: 19.99,
    imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.5,
  ),
  Product(
    id: 'p2',
    name: 'Blue Denim Jeans',
    description: 'Durable blue denim jeans with a classic fit and premium feel. Built to last.',
    price: 49.99,
    imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.2,
  ),
  Product(
    id: 'p3',
    name: 'Running Shoes',
    description: 'Lightweight running shoes with excellent cushioning and breathable mesh upper.',
    price: 89.99,
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.8,
  ),
  Product(
    id: 'p4',
    name: 'Leather Wallet',
    description: 'Genuine leather wallet with multiple card slots and a sleek, slim design.',
    price: 29.99,
    imageUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.0,
  ),
  Product(
    id: 'p5',
    name: 'Digital Watch',
    description: 'Water-resistant digital watch with backlight, stopwatch, and alarm functions.',
    price: 35.50,
    imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.3,
  ),
  Product(
    id: 'p6',
    name: 'Wireless Headphones',
    description: 'Noise-canceling wireless headphones with high-fidelity sound and long battery life.',
    price: 129.99,
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.7,
  ),
  Product(
    id: 'p7',
    name: 'Canvas Backpack',
    description: 'Sturdy canvas backpack with a dedicated laptop compartment and multiple pockets.',
    price: 45.00,
    imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.4,
  ),
  Product(
    id: 'p8',
    name: 'Sunglasses',
    description: 'Polarized sunglasses with a stylish frame and UV400 protection.',
    price: 24.99,
    imageUrl: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    rating: 4.1,
  ),
];
