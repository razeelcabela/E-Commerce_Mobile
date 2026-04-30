class SellerProduct {
  final String id;
  final String sellerEmail;
  String name;
  String description;
  String imageUrl;
  double price;
  int stock;
  String category;
  final DateTime createdAt;

  SellerProduct({
    required this.id,
    required this.sellerEmail,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.category,
    required this.createdAt,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) => SellerProduct(
        id: json['id'] as String,
        sellerEmail: json['sellerEmail'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        category: json['category'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerEmail': sellerEmail,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'stock': stock,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };
}
