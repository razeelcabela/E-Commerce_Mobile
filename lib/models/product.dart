class Product {
  final dynamic id; // Support both int and String (UUID)
  final String name;
  final double price;
  final String description;
  final String category;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  // Factory constructor to create from Supabase JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      price: (json['price'] is int) ? (json['price'] as int).toDouble() : (json['price'] as double?) ?? 0.0,
      description: json['description'] ?? '',
      category: json['category'] as String? ?? 'Uncategorized',
      imageUrl: _firstImageUrl(json),
    );
  }

  static String _firstImageUrl(Map<String, dynamic> json) {
    return json['image_url'] as String? ?? '';
  }

  Product copyWith({
    dynamic id,
    String? name,
    double? price,
    String? description,
    String? category,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double getTotal() {
    return product.price * quantity;
  }
}
