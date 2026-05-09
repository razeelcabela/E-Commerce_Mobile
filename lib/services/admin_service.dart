import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class AdminService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ─── Platform Stats ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      final results = await Future.wait([
        _db.from('users').select('id, role, account_status'),
        _db.from('orders').select('id, status'),
        _db.from('products').select('id, approval_status, is_active'),
        _db.from('sellers').select('id, status'),
        _db.from('riders').select('id, status'),
      ]);

      final users    = results[0] as List;
      final orders   = results[1] as List;
      final products = results[2] as List;
      final sellers  = results[3] as List;
      final riders   = results[4] as List;

      final totalRevenue = await _getTotalRevenue();

      return {
        'total_users':        users.length,
        'total_buyers':       users.where((u) => u['role'] == 'buyer').length,
        'total_sellers':      sellers.length,
        'total_riders':       riders.length,
        'active_sellers':     sellers.where((s) => s['status'] == 'approved').length,
        'pending_sellers':    sellers.where((s) => s['status'] == 'pending').length,
        'pending_riders':     riders.where((r) => r['status'] == 'pending').length,
        'total_orders':       orders.length,
        'pending_orders':     orders.where((o) => o['status'] == 'toPay' || o['status'] == 'toShip').length,
        'completed_orders':   orders.where((o) => o['status'] == 'completed').length,
        'total_products':     products.length,
        'pending_products':   products.where((p) => p['approval_status'] == 'pending').length,
        'approved_products':  products.where((p) => p['approval_status'] == 'approved').length,
        'total_revenue':      totalRevenue,
      };
    } catch (e) {
      developer.log('[AdminService.getPlatformStats] Error: $e');
      return {};
    }
  }

  static Future<double> _getTotalRevenue() async {
    try {
      final completedOrders = await _db
          .from('orders')
          .select('total_amount')
          .eq('status', 'completed');
      return (completedOrders as List).fold<double>(
        0.0,
        (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (_) {
      return 0.0;
    }
  }

  // ─── User Management ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllUsers({String? roleFilter}) async {
    try {
      var query = _db
          .from('users')
          .select('id, email, first_name, last_name, phone, role, account_status, created_at');
      if (roleFilter != null) {
        query = query.eq('role', roleFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      developer.log('[AdminService.getAllUsers] Error: $e');
      return [];
    }
  }

  static Future<String?> setUserStatus(int userId, String status) async {
    try {
      await _db
          .from('users')
          .update({'account_status': status})
          .eq('id', userId);
      return null;
    } catch (e) {
      developer.log('[AdminService.setUserStatus] Error: $e');
      return e.toString();
    }
  }

  // ─── Seller Management ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSellers({String? statusFilter}) async {
    try {
      var query = _db.from('sellers').select(
        'id, store_name, contact_email, address, status, commission_rate, created_at, '
        'users(first_name, last_name, email, account_status)',
      );
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      developer.log('[AdminService.getSellers] Error: $e');
      return [];
    }
  }

  static Future<String?> setSellerStatus(int sellerId, String status) async {
    try {
      await _db.from('sellers').update({'status': status}).eq('id', sellerId);
      return null;
    } catch (e) {
      developer.log('[AdminService.setSellerStatus] Error: $e');
      return e.toString();
    }
  }

  // ─── Rider Management ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getRiders({String? statusFilter}) async {
    try {
      var query = _db.from('riders').select(
        'id, license_number, vehicle_type, address, status, created_at, '
        'users(first_name, last_name, email, account_status)',
      );
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      developer.log('[AdminService.getRiders] Error: $e');
      return [];
    }
  }

  static Future<String?> setRiderStatus(int riderId, String status) async {
    try {
      await _db.from('riders').update({'status': status}).eq('id', riderId);
      return null;
    } catch (e) {
      developer.log('[AdminService.setRiderStatus] Error: $e');
      return e.toString();
    }
  }

  // ─── Order Management ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllOrders({String? statusFilter}) async {
    try {
      var query = _db.from('orders').select(
        'id, status, created_at, '
        'users(first_name, last_name, email), '
        'sellers(store_name)',
      );
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      developer.log('[AdminService.getAllOrders] Error: $e');
      return [];
    }
  }

  static Future<String?> setOrderStatus(int orderId, String status) async {
    try {
      await _db.from('orders').update({'status': status}).eq('id', orderId);
      return null;
    } catch (e) {
      developer.log('[AdminService.setOrderStatus] Error: $e');
      return e.toString();
    }
  }

  // ─── Product Management ────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProducts({String? approvalFilter}) async {
    try {
      var query = _db.from('products').select(
        'id, name, description, price, stock, approval_status, rejection_reason, '
        'delivery_options, condition, is_active, archive_status, created_at, category_id, '
        'sellers(id, store_name), '
        'categories(name), '
        'product_images(image_url)',
      );
      if (approvalFilter != null) {
        query = query.eq('approval_status', approvalFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      developer.log('[AdminService.getProducts] Error: $e');
      return [];
    }
  }

  static Future<String?> approveProduct(int productId) async {
    try {
      final row = await _db
          .from('products')
          .select('name, seller_id')
          .eq('id', productId)
          .single();

      await _db.from('products').update({
        'approval_status': 'approved',
        'rejection_reason': null,
        'is_active': 1,
      }).eq('id', productId);

      await NotificationService.notifyProductApproved(
        sellerId: row['seller_id'] as int,
        productId: productId,
        productName: row['name'] as String,
      );
      return null;
    } catch (e) {
      developer.log('[AdminService.approveProduct] Error: $e');
      return e.toString();
    }
  }

  static Future<String?> rejectProduct(int productId, String reason) async {
    try {
      final row = await _db
          .from('products')
          .select('name, seller_id')
          .eq('id', productId)
          .single();

      await _db.from('products').update({
        'approval_status': 'rejected',
        'rejection_reason': reason,
        'is_active': 0,
      }).eq('id', productId);

      await NotificationService.notifyProductRejected(
        sellerId: row['seller_id'] as int,
        productId: productId,
        productName: row['name'] as String,
        reason: reason,
      );
      return null;
    } catch (e) {
      developer.log('[AdminService.rejectProduct] Error: $e');
      return e.toString();
    }
  }

  // Kept for backward compatibility.
  static Future<String?> setProductApproval(int productId, String status) async {
    if (status == 'approved') return approveProduct(productId);
    return rejectProduct(productId, 'No reason provided');
  }
}
