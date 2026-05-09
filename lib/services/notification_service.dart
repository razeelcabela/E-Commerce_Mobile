import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seller_auth_service.dart';

class NotificationService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getSellerNotifications() async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return [];
    try {
      final data = await _db
          .from('notifications')
          .select('id, type, title, message, product_id, is_read, created_at')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      developer.log('[NotificationService.getSellerNotifications] Error: $e');
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return 0;
    try {
      final data = await _db
          .from('notifications')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('is_read', false);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      developer.log('[NotificationService.markAsRead] Error: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    final sellerId = await SellerAuthService.getCurrentSellerId();
    if (sellerId == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('seller_id', sellerId)
          .eq('is_read', false);
    } catch (e) {
      developer.log('[NotificationService.markAllAsRead] Error: $e');
    }
  }

  static Future<void> notifyProductApproved({
    required int sellerId,
    required int productId,
    required String productName,
  }) async {
    try {
      await _db.from('notifications').insert({
        'seller_id': sellerId,
        'type': 'product_approved',
        'title': 'Product Approved!',
        'message':
            'Your product "$productName" has been approved and is now live in the store.',
        'product_id': productId,
      });
    } catch (e) {
      developer.log('[NotificationService.notifyProductApproved] Error: $e');
    }
  }

  static Future<void> notifyProductRejected({
    required int sellerId,
    required int productId,
    required String productName,
    required String reason,
  }) async {
    try {
      await _db.from('notifications').insert({
        'seller_id': sellerId,
        'type': 'product_rejected',
        'title': 'Product Not Approved',
        'message':
            'Your product "$productName" was not approved. Reason: $reason',
        'product_id': productId,
      });
    } catch (e) {
      developer.log('[NotificationService.notifyProductRejected] Error: $e');
    }
  }
}
