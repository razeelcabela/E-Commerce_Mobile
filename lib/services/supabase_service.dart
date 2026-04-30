import 'package:supabase_flutter/supabase_flutter.dart';

// Access this anywhere in the app:
// final db = SupabaseService.client;
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await client
        .from('users')
        .select()
        .eq('email', email)
        .eq('password', password) // NOTE: use hashed passwords in production
        .eq('role', role)
        .maybeSingle();
    return result;
  }

  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    return await client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // ─── PRODUCTS ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getApprovedProducts() async {
    return await client
        .from('products')
        .select('*, product_images(*), product_variants(*), sellers(store_name)')
        .eq('approval_status', 'approved')
        .eq('is_active', true)
        .eq('archive_status', 'active')
        .order('created_at', ascending: false);
  }

  static Future<Map<String, dynamic>?> getProductById(int productId) async {
    return await client
        .from('products')
        .select('*, product_images(*), product_variants(*), sellers(store_name, logo_url)')
        .eq('id', productId)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(int categoryId) async {
    return await client
        .from('products')
        .select('*, product_images(*)')
        .eq('category_id', categoryId)
        .eq('approval_status', 'approved')
        .eq('is_active', true);
  }

  static Future<List<Map<String, dynamic>>> getSellerProducts(int sellerId) async {
    return await client
        .from('products')
        .select('*, product_images(*), product_variants(*)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
  }

  // ─── CATEGORIES ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCategories() async {
    return await client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('name');
  }

  // ─── CART ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCart(int userId) async {
    return await client
        .from('cart')
        .select('*, products(name, price, product_images(image_url)), product_variants(size, color)')
        .eq('user_id', userId);
  }

  static Future<void> addToCart({
    required int userId,
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    // Check if item already in cart
    final existing = await client
        .from('cart')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .eq('variant_id', variantId ?? 0)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('cart')
          .update({'quantity': existing['quantity'] + quantity})
          .eq('id', existing['id']);
    } else {
      await client.from('cart').insert({
        'user_id': userId,
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      });
    }
  }

  static Future<void> removeFromCart(int cartItemId) async {
    await client.from('cart').delete().eq('id', cartItemId);
  }

  // ─── ORDERS ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrdersByUser(int userId) async {
    return await client
        .from('orders')
        .select('*, order_items(*), sellers(store_name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getOrdersBySeller(int sellerId) async {
    return await client
        .from('orders')
        .select('*, order_items(*), users(first_name, last_name, email)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
  }

  static Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    return await client
        .from('orders')
        .select('*, order_items(*, products(name)), sellers(store_name), users(first_name, last_name)')
        .eq('id', orderId)
        .maybeSingle();
  }

  // ─── ADDRESSES ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUserAddresses(int userId) async {
    return await client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);
  }

  // ─── REVIEWS ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    return await client
        .from('reviews')
        .select('*, users(first_name, last_name, profile_image)')
        .eq('product_id', productId)
        .eq('is_approved', true)
        .order('created_at', ascending: false);
  }

  // ─── SELLERS ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getSellerByUserId(int userId) async {
    return await client
        .from('sellers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  // ─── REALTIME ──────────────────────────────────────────────────────────────

  // Listen for order status changes in real time
  static RealtimeChannel listenToOrderStatus({
    required int orderId,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return client
        .channel('order_status_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }
}
