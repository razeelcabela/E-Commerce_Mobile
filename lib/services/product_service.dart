import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final _client = Supabase.instance.client;

  /// Fetch all approved products from Supabase
  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('approval_status', 'approved')
          .eq('is_active', 1)  // Try 1 instead of true if smallint
          .eq('archive_status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// Fetch products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('category', category)
          .eq('approval_status', 'approved')
          .eq('is_active', 1)  // Try 1 instead of true if smallint
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching products by category: $e');
      return [];
    }
  }

  /// Get distinct categories
  static Future<List<String>> getCategories() async {
    try {
      final response = await _client
          .from('products')
          .select('category')
          .eq('approval_status', 'approved')
          .eq('is_active', true);

      final categories = <String>{};
      for (var item in (response as List)) {
        final category = item['category'];
        if (category != null && category.isNotEmpty) {
          categories.add(category as String);
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  /// Fetch single product by ID
  static Future<Product?> getProductById(dynamic productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching product: $e');
      return null;
    }
  }
}
