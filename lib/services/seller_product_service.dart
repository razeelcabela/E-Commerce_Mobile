import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller_product.dart';
import '../models/seller_dashboard_stats.dart';
import '../models/product_variant.dart';
import 'seller_auth_service.dart';

class SellerProductService {
  static final _client = Supabase.instance.client;
  static const _bucket = 'products';

  // ── Category cache ────────────────────────────────────────────────────────

  static Map<int, String>? _categoryCache;

  static Future<Map<int, String>> _categoryMap() async {
    if (_categoryCache != null && _categoryCache!.isNotEmpty) return _categoryCache!;
    try {
      final rows = await _client
          .from('categories')
          .select('id, name')
          .order('name');
      final list = rows as List;
      debugPrint('✅ Categories fetched: ${list.length} rows → $list');
      final map = {
        for (final r in list)
          (r['id'] as num).toInt(): (r['name'] as String),
      };
      if (map.isNotEmpty) _categoryCache = map;
      return map;
    } catch (e, st) {
      debugPrint('❌ Seller category map error: $e\n$st');
      return {};
    }
  }

  /// Returns [{id, name}] list for category picker UI.
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final map = await _categoryMap();
    return map.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList()
      ..sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));
  }

  // ── Image helpers ─────────────────────────────────────────────────────────

  static Future<Map<dynamic, String>> _imageMap(List<dynamic> ids) async {
    if (ids.isEmpty) return {};
    try {
      final rows = await _client
          .from('product_images')
          .select('product_id, image_url')
          .inFilter('product_id', ids);
      final map = <dynamic, String>{};
      for (final r in (rows as List)) {
        final pid = r['product_id'];
        if (!map.containsKey(pid)) {
          final raw = r['image_url'] as String? ?? '';
          map[pid] = SellerProduct.resolveImageUrl(raw);
        }
      }
      return map;
    } catch (e) {
      debugPrint('❌ Seller image map error: $e');
      return {};
    }
  }

  static Map<String, dynamic> _enrich(
    Map<String, dynamic> json,
    Map<int, String> categories,
    Map<dynamic, String> images,
  ) {
    final catId = json['category_id'];
    return {
      ...json,
      'category': catId != null ? (categories[catId as int] ?? 'Uncategorized') : 'Uncategorized',
      'image_url': images[json['id']] ?? '',
    };
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Fetch all products for the current seller from Supabase.
  static Future<List<SellerProduct>> getByCurrentSeller() async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return [];
    try {
      final catMap = await _categoryMap();
      final rows = await _client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final list = rows as List;
      final imgMap = await _imageMap(list.map((r) => r['id']).toList());

      return list
          .map((r) => SellerProduct.fromSupabase(
              _enrich(r as Map<String, dynamic>, catMap, imgMap)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching seller products: $e');
      return [];
    }
  }

  /// Kept for backward compatibility with existing screens.
  static Future<List<SellerProduct>> getByEmail(String email) =>
      getByCurrentSeller();

  /// Generates a URL-safe slug from a product name + timestamp (guaranteed unique).
  static String _slugify(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${base.isEmpty ? 'product' : base}-$timestamp';
  }

  /// Insert a new product into Supabase. Returns the new product ID, or null.
  static Future<int?> add(SellerProduct product) async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) {
      debugPrint('❌ add: no seller_id in session');
      return null;
    }
    try {
      final row = await _client.from('products').insert({
        'seller_id': sellerId,
        'name': product.name,
        'slug': _slugify(product.name),
        'description': product.description,
        'price': product.price,
        'stock': product.stock,
        'category_id': product.categoryId,
        'approval_status': 'pending',
        'is_active': 1,
        'archive_status': 'active',
        'visibility': 'public',
        'delivery_options': product.deliveryOptions,
        'condition': product.condition,
      }).select('id').single();
      return row['id'] as int?;
    } catch (e) {
      debugPrint('❌ Error adding product: $e');
      return null;
    }
  }

  /// Update an existing product in Supabase.
  static Future<void> update(SellerProduct product) async {
    try {
      await _client.from('products').update({
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'stock': product.stock,
        'category_id': product.categoryId,
      }).eq('id', product.id);
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
    }
  }

  /// Delete a product and all its images from Supabase.
  static Future<void> delete(dynamic productId) async {
    try {
      await _client
          .from('product_images')
          .delete()
          .eq('product_id', productId);
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
    }
  }

  // ── Stock Management ─────────────────────────────────────────────────────────

  /// Update stock for a product.
  static Future<bool> updateStock(dynamic productId, int newStock) async {
    try {
      await _client.from('products').update({
        'stock': newStock,
      }).eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating stock: $e');
      return false;
    }
  }

  /// Adjust stock by delta (positive or negative).
  static Future<bool> adjustStock(dynamic productId, int delta, {String reason = 'adjustment'}) async {
    try {
      final sellerId = await SellerAuthService.getCurrentSellerId();
      if (sellerId == null) return false;

      // Update product stock
      await _client.rpc('increment', params: {'x': delta, 'row_id': productId});

      // Log transaction
      await _client.from('inventory_transactions').insert({
        'product_id': productId,
        'seller_id': sellerId,
        'quantity_change': delta,
        'reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error adjusting stock: $e');
      return false;
    }
  }

  /// Get a single product by ID.
  static Future<SellerProduct?> getById(dynamic productId) async {
    try {
      final catMap = await _categoryMap();
      final row = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .single();
      
      final imgMap = await _imageMap([productId]);
      return SellerProduct.fromSupabase(
        _enrich(row, catMap, imgMap),
      );
    } catch (e) {
      debugPrint('❌ Error fetching product by ID: $e');
      return null;
    }
  }

  /// Get products by approval status.
  static Future<List<SellerProduct>> getByStatus(String status) async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return [];
    try {
      final catMap = await _categoryMap();
      final rows = await _client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .eq('approval_status', status)
          .order('created_at', ascending: false);

      final list = rows as List;
      final imgMap = await _imageMap(list.map((r) => r['id']).toList());

      return list
          .map((r) => SellerProduct.fromSupabase(
              _enrich(r as Map<String, dynamic>, catMap, imgMap)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching products by status: $e');
      return [];
    }
  }

  /// Get low-stock products (stock below threshold).
  static Future<List<SellerProduct>> getLowStockProducts({int threshold = 10}) async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return [];
    try {
      final catMap = await _categoryMap();
      final rows = await _client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_active', 1)
          .lt('stock', threshold)
          .order('stock', ascending: true);

      final list = rows as List;
      final imgMap = await _imageMap(list.map((r) => r['id']).toList());

      return list
          .map((r) => SellerProduct.fromSupabase(
              _enrich(r as Map<String, dynamic>, catMap, imgMap)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching low-stock products: $e');
      return [];
    }
  }

  /// Toggle product active status.
  static Future<bool> toggleActive(dynamic productId, bool isActive) async {
    try {
      await _client.from('products').update({
        'is_active': isActive ? 1 : 0,
      }).eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('❌ Error toggling product: $e');
      return false;
    }
  }

  /// Archive or unarchive a product.
  static Future<bool> setArchiveStatus(dynamic productId, String status) async {
    if (!['active', 'archived'].contains(status)) return false;
    try {
      await _client.from('products').update({
        'archive_status': status,
      }).eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('❌ Error archiving product: $e');
      return false;
    }
  }

  // ── Dashboard Statistics ──────────────────────────────────────────────────

  /// Fetch dashboard statistics for the current seller.
  static Future<SellerDashboardStats> getDashboardStats() async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return SellerDashboardStats.empty();

    try {
      // Fetch all seller products
      final products = await _client
          .from('products')
          .select()
          .eq('seller_id', sellerId);

      final prodList = products as List;
      final totalProducts = prodList.length;
      final activeProducts = prodList.where((p) => p['is_active'] == 1 && p['approval_status'] == 'approved').length;
      final pendingProducts = prodList.where((p) => p['approval_status'] == 'pending').length;
      final archivedProducts = prodList.where((p) => p['archive_status'] == 'archived').length;
      final lowStockProducts = prodList.where((p) => (p['stock'] as int) < 10).length;

      // Fetch orders and revenue
      final orders = await _client
          .from('orders')
          .select()
          .eq('seller_id', sellerId);

      final orderList = orders as List;
      final totalOrders = orderList.length;
      final totalRevenue = orderList.fold<double>(
        0.0,
        (sum, order) => sum + ((order['total_amount'] as num?)?.toDouble() ?? 0.0),
      );
      final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      // Fetch daily stats for last 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final stats = await _client
          .from('seller_daily_stats')
          .select()
          .eq('seller_id', sellerId)
          .gte('date', sevenDaysAgo.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      final statsList = stats as List;
      final revenueData = statsList
          .map((s) => DailyRevenue.fromJson(s as Map<String, dynamic>))
          .toList();

      return SellerDashboardStats(
        totalProducts: totalProducts,
        activeProducts: activeProducts,
        pendingApprovalProducts: pendingProducts,
        archivedProducts: archivedProducts,
        lowStockProducts: lowStockProducts,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        avgOrderValue: avgOrderValue,
        totalEarnings: totalRevenue,
        topProductId: 0,
        topProductName: null,
        topProductSales: 0,
        revenueLastSevenDays: revenueData,
      );
    } catch (e) {
      debugPrint('❌ Error fetching dashboard stats: $e');
      return SellerDashboardStats.empty();
    }
  }

  // ── Image upload ──────────────────────────────────────────────────────────

  /// Upload image bytes to Storage and record path in product_images table.
  static Future<void> uploadImage(
    dynamic productId,
    Uint8List bytes,
    String ext,
  ) async {
    final path = '${productId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _client.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      await _client.from('product_images').insert({
        'product_id': productId,
        'image_url': path,
      });
    } catch (e) {
      debugPrint('❌ Image upload error: $e');
    }
  }

  /// Upload multiple images for a product.
  static Future<int> uploadMultipleImages(
    dynamic productId,
    List<Map<String, dynamic>> imageData,
  ) async {
    int uploadCount = 0;
    for (final img in imageData) {
      final bytes = img['bytes'] as Uint8List;
      final ext = img['ext'] as String;
      try {
        await uploadImage(productId, bytes, ext);
        uploadCount++;
      } catch (e) {
        debugPrint('❌ Error uploading image: $e');
      }
    }
    return uploadCount;
  }

  static void clearCategoryCache() => _categoryCache = null;

  // ── Variants ──────────────────────────────────────────────────────────────

  static Future<List<ProductVariant>> getVariants(dynamic productId) async {
    try {
      final rows = await _client
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .order('id');
      return (rows as List)
          .map((r) => ProductVariant.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching variants: $e');
      return [];
    }
  }

  /// Delete all existing variants then insert the new list.
  /// Pass an empty list to clear all variants for a product.
  static Future<void> saveVariants(
      dynamic productId, List<ProductVariant> variants) async {
    try {
      await _client
          .from('product_variants')
          .delete()
          .eq('product_id', productId);
      if (variants.isNotEmpty) {
        await _client
            .from('product_variants')
            .insert(variants.map((v) => v.toInsert(productId)).toList());
      }
    } catch (e) {
      debugPrint('❌ Error saving variants: $e');
    }
  }
}
