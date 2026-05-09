import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProduct {
  final dynamic id;
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
  String approvalStatus;
  String? rejectionReason;
  String deliveryOptions;
  String condition;

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
    this.approvalStatus = 'pending',
    this.rejectionReason,
    this.deliveryOptions = 'delivery',
    this.condition = 'new',
  });

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
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      deliveryOptions: json['delivery_options'] as String? ?? 'delivery',
      condition: json['condition'] as String? ?? 'new',
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
