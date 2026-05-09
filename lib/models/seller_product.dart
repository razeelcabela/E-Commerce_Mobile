import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProduct {
  final dynamic id; // int from Supabase
  final int sellerId;
  final String sellerEmail;
  String name;
  String description;
  String imageUrl;
  double price;
  int stock;
  int? categoryId;
  String category;
  final DateTime createdAt;

  SellerProduct({
    required this.id,
    required this.sellerId,
    required this.sellerEmail,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stock,
    this.categoryId,
    required this.category,
    required this.createdAt,
  });

  /// Parse a Supabase products row.
  /// Expects `image_url` and `category` to be injected by the service layer.
  factory SellerProduct.fromSupabase(Map<String, dynamic> json) {
    return SellerProduct(
      id: json['id'],
      sellerId: json['seller_id'] as int? ?? 0,
      sellerEmail: json['seller_email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      categoryId: json['category_id'] as int?,
      category: json['category'] as String? ?? 'Uncategorized',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static String _toPublicUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final filename = raw.contains('/') ? raw.split('/').last : raw;
    return Supabase.instance.client.storage
        .from('products')
        .getPublicUrl(filename);
  }

  static String resolveImageUrl(String raw) =>
      raw.isEmpty ? '' : _toPublicUrl(raw);
}
