import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_product.dart';

class SellerProductService {
  static const _key = 'seller_products';

  static Future<List<SellerProduct>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => SellerProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _save(List<SellerProduct> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(products.map((p) => p.toJson()).toList()));
  }

  static Future<List<SellerProduct>> getByEmail(String sellerEmail) async {
    final all = await _all();
    return all.where((p) => p.sellerEmail == sellerEmail).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> add(SellerProduct product) async {
    final all = await _all();
    all.add(product);
    await _save(all);
  }

  static Future<void> update(SellerProduct updated) async {
    final all = await _all();
    final idx = all.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _save(all);
    }
  }

  static Future<void> delete(String id) async {
    final all = await _all();
    all.removeWhere((p) => p.id == id);
    await _save(all);
  }

  static Future<SellerProduct?> getById(String id) async {
    final all = await _all();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<SellerProduct>> getAllPublic() async => _all();
}
