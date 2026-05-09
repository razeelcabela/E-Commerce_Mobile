import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final _client = Supabase.instance.client;

  // In-memory cache: category_id → name
  static Map<int, String>? _categoryCache;

  static Future<Map<int, String>> _categoryMap() async {
    if (_categoryCache != null) return _categoryCache!;
    try {
      final rows = await _client
          .from('categories')
          .select('id, name')
          .eq('is_active', 1)
          .order('name');
      _categoryCache = {
        for (final r in (rows as List))
          (r['id'] as int): (r['name'] as String),
      };
    } catch (e) {
      debugPrint('❌ Error loading category map: $e');
      _categoryCache = {};
    }
    return _categoryCache!;
  }

  // The Supabase Storage bucket where product images are stored.
  // Change this if your bucket has a different name.
  static const _imageBucket = 'products';

  /// Converts a stored path to a full public URL.
  /// Handles legacy web-server paths like "/static/images/products/file.png"
  /// by extracting just the filename before calling getPublicUrl.
  static String _toPublicUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    // Strip any leading directory path — only the filename is used in Storage
    final filename = raw.contains('/') ? raw.split('/').last : raw;
    return _client.storage.from(_imageBucket).getPublicUrl(filename);
  }

  /// Batch-fetch first image URL per product. Returns map product_id → url.
  static Future<Map<dynamic, String>> _imageMap(List<dynamic> ids) async {
    if (ids.isEmpty) {
      debugPrint('🖼️ _imageMap: no product IDs passed in');
      return {};
    }
    debugPrint('🖼️ _imageMap: fetching images for ${ids.length} products, bucket="$_imageBucket"');
    try {
      final rows = await _client
          .from('product_images')
          .select('product_id, image_url')
          .inFilter('product_id', ids);
      debugPrint('🖼️ product_images rows returned: ${(rows as List).length}');
      final map = <dynamic, String>{};
      for (final r in rows) {
        final pid = r['product_id'];
        if (!map.containsKey(pid)) {
          final raw = r['image_url'] as String? ?? '';
          final url = raw.isEmpty ? '' : _toPublicUrl(raw);
          map[pid] = url;
          debugPrint('🖼️ product $pid | raw: "$raw" | url: "$url"');
        }
      }
      debugPrint('🖼️ mapped ${map.length} of ${ids.length} products');
      return map;
    } catch (e) {
      debugPrint('❌ Error loading image map: $e');
      return {};
    }
  }

  static Map<String, dynamic> _enrich(
    Map<String, dynamic> json,
    Map<int, String> categories,
    Map<dynamic, String> images,
  ) {
    final catId = json['category_id'];
    final catName = catId != null ? categories[catId as int] : null;
    return {
      ...json,
      'category': catName ?? 'Uncategorized',
      'image_url': images[json['id']] ?? '',
    };
  }

  /// Fetch all approved products.
  static Future<List<Product>> getAllProducts() async {
    try {
      final catMap = await _categoryMap();
      final rows = await _client
          .from('products')
          .select()
          .eq('approval_status', 'approved')
          .eq('is_active', 1)
          .eq('archive_status', 'active')
          .order('created_at', ascending: false);

      final list = rows as List;
      final imgMap = await _imageMap(list.map((r) => r['id']).toList());

      return list
          .map((r) => Product.fromJson(_enrich(r as Map<String, dynamic>, catMap, imgMap)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      return [];
    }
  }

  /// Fetch approved products for a given category name.
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final catMap = await _categoryMap();
      final entry = catMap.entries.where((e) => e.value == category).firstOrNull;
      if (entry == null) return [];

      final rows = await _client
          .from('products')
          .select()
          .eq('category_id', entry.key)
          .eq('approval_status', 'approved')
          .eq('is_active', 1)
          .order('created_at', ascending: false);

      final list = rows as List;
      final imgMap = await _imageMap(list.map((r) => r['id']).toList());

      return list
          .map((r) => Product.fromJson(_enrich(r as Map<String, dynamic>, catMap, imgMap)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching products by category: $e');
      return [];
    }
  }

  /// Returns sorted list of active category names.
  static Future<List<String>> getCategories() async {
    final map = await _categoryMap();
    final names = map.values.toList()..sort();
    return names;
  }

  /// Fetch a single product by ID.
  static Future<Product?> getProductById(dynamic productId) async {
    try {
      final catMap = await _categoryMap();
      final row = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (row == null) return null;
      final imgMap = await _imageMap([productId]);
      return Product.fromJson(_enrich(row, catMap, imgMap));
    } catch (e) {
      debugPrint('❌ Error fetching product: $e');
      return null;
    }
  }

  /// Clears the category cache (call after admin changes categories).
  static void clearCategoryCache() => _categoryCache = null;
}
