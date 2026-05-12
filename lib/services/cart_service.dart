import '../models/product.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  final List<CartItem> _cartItems = [];

  CartService._internal();

  factory CartService() {
    return _instance;
  }

  // Get all cart items
  List<CartItem> getCartItems() {
    return _cartItems;
  }

  // Add product to cart, deduplicating by product+variant combination
  void addToCart(Product product,
      {String? selectedSize, String? selectedColor}) {
    final newItem = CartItem(
      product: product,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
    );
    final idx =
        _cartItems.indexWhere((item) => item.variantKey == newItem.variantKey);
    if (idx >= 0) {
      _cartItems[idx].quantity++;
    } else {
      _cartItems.add(newItem);
    }
  }

  // Remove by product ID (removes first match — use removeByVariantKey for precision)
  void removeFromCart(dynamic productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
  }

  // Remove the exact variant entry
  void removeByVariantKey(String key) {
    _cartItems.removeWhere((item) => item.variantKey == key);
  }

  // Update quantity by variant key
  void updateQuantityByVariant(String key, int quantity) {
    final idx = _cartItems.indexWhere((item) => item.variantKey == key);
    if (idx < 0) return;
    if (quantity <= 0) {
      _cartItems.removeAt(idx);
    } else {
      _cartItems[idx].quantity = quantity;
    }
  }

  // Get total cart count
  int getCartCount() {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total price
  double getTotalPrice() {
    return _cartItems.fold(0, (sum, item) => sum + item.getTotal());
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
  }

  // Check if product is in cart
  bool isInCart(int productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }
}