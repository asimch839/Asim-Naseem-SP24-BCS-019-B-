import 'product.dart';

class WishlistManager {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Product> _wishlistItems = [];

  List<Product> get items => [..._wishlistItems];

  void toggleWishlist(Product product) {
    final isExist = _wishlistItems.any((item) => item.id == product.id);
    if (isExist) {
      _wishlistItems.removeWhere((item) => item.id == product.id);
    } else {
      _wishlistItems.add(product);
    }
  }

  bool isWishlisted(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }
}
