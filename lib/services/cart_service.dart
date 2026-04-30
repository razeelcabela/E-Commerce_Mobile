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

  // Add product to cart (increase quantity if exists)
  void addToCart(Product product) {
    final existingItem = _cartItems.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product),
    );

    if (_cartItems.contains(existingItem)) {
      existingItem.quantity++;
    } else {
      _cartItems.add(existingItem);
    }
  }

  // Remove product from cart
  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
  }

  // Update quantity
  void updateQuantity(int productId, int quantity) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product(
        id: -1,
        name: '',
        price: 0,
        description: '',
        category: '',
        imageUrl: '',
      )),
    );

    if (item.product.id != -1) {
      if (quantity <= 0) {
        removeFromCart(productId);
      } else {
        item.quantity = quantity;
      }
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