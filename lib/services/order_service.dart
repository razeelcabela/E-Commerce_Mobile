import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class OrderService {
  static const _key = 'orders';

  static Future<List<Order>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      final orders = <Order>[];
      for (var item in list) {
        try {
          orders.add(Order.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          developer.log('[OrderService._all] Skipping malformed order: $e');
        }
      }
      return orders;
    } catch (e) {
      developer.log('[OrderService._all] JSON decode error: $e');
      return [];
    }
  }

  static Future<void> _save(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(orders.map((o) => o.toJson()).toList()));
  }

  static Future<void> place(Order order) async {
    final all = await _all();
    all.add(order);
    await _save(all);
  }

  static Future<void> updateStatus(String orderId, String newStatus) async {
    final all = await _all();
    final idx = all.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      all[idx].status = newStatus;
      await _save(all);
    }
  }

  static Future<List<Order>> getByBuyer(String buyerEmail) async {
    final all = await _all();
    return all.where((o) => o.buyerEmail == buyerEmail).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<Order>> getBySeller(String sellerEmail) async {
    final all = await _all();
    return all.where((o) => o.sellerEmail == sellerEmail).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<Map<String, int>> sellerStatusCounts(
      String sellerEmail) async {
    final orders = await getBySeller(sellerEmail);
    return {
      Order.toPay:     orders.where((o) => o.status == Order.toPay).length,
      Order.toShip:    orders.where((o) => o.status == Order.toShip).length,
      Order.shipped:   orders.where((o) => o.status == Order.shipped).length,
      Order.toReceive: orders.where((o) => o.status == Order.toReceive).length,
      Order.completed: orders.where((o) => o.status == Order.completed).length,
    };
  }

  static Future<double> sellerRevenue(String sellerEmail) async {
    final orders = await getBySeller(sellerEmail);
    return orders
        .where((o) => o.status == Order.completed)
        .fold<double>(0.0, (sum, o) => sum + o.total);
  }

  // ── Rider methods ────────────────────────────────────────────────────────

  /// Orders available for any rider to accept (seller has packaged them).
  static Future<List<Order>> getAvailableForRider() async {
    final all = await _all();
    return all
        .where((o) => o.status == Order.toShip && o.riderEmail == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Assign [riderEmail] to [orderId] and set status to riderAccepted.
  static Future<void> acceptOrder(String orderId, String riderEmail) async {
    final all = await _all();
    final idx = all.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      all[idx].riderEmail = riderEmail;
      all[idx].status = Order.riderAccepted;
      await _save(all);
    }
  }

  /// All orders assigned to this rider, newest first.
  static Future<List<Order>> getByRider(String riderEmail) async {
    final all = await _all();
    return all.where((o) => o.riderEmail == riderEmail).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Active deliveries (in-progress rider statuses, excluding delivered).
  static Future<List<Order>> getActiveDeliveriesByRider(
      String riderEmail) async {
    final all = await _all();
    const active = {
      Order.riderAccepted,
      Order.pickedUp,
      Order.inTransit,
      Order.nearLocation,
    };
    return all
        .where((o) => o.riderEmail == riderEmail && active.contains(o.status))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Number of orders successfully delivered by this rider.
  static Future<int> riderCompletedCount(String riderEmail) async {
    final orders = await getByRider(riderEmail);
    return orders.where((o) => o.status == Order.delivered).length;
  }

  /// Total commission earned by this rider (15% of delivered order totals).
  static Future<double> riderEarnings(String riderEmail) async {
    final orders = await getByRider(riderEmail);
    return orders
        .where((o) => o.status == Order.delivered)
        .fold<double>(0.0, (sum, o) => sum + o.commission);
  }
}
