import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_application.dart';

class SellerApplicationService {
  static const String _applicationsKey = 'seller_applications';
  static const String _rolePrefix = 'user_role_';

  // Valid role values — matches what web admin will read/write
  static const String roleUser = 'user';
  static const String rolePending = 'pending';
  static const String roleSeller = 'seller';

  static Future<List<SellerApplication>> _getAll(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_applicationsKey);
    if (raw == null) return [];
    return SellerApplication.listFromJson(raw);
  }

  /// Submit a new seller application. Sets the user's role to [rolePending].
  static Future<void> submit(SellerApplication application) async {
    final prefs = await SharedPreferences.getInstance();
    final apps = await _getAll(prefs);

    // Replace any previous application from the same email
    apps.removeWhere((a) => a.userEmail == application.userEmail);
    apps.add(application);

    await prefs.setString(_applicationsKey, SellerApplication.listToJson(apps));
    await prefs.setString(
        '$_rolePrefix${application.userEmail}', rolePending);
  }

  /// Returns the application for [email], or null if none exists.
  static Future<SellerApplication?> getByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final apps = await _getAll(prefs);
    try {
      return apps.firstWhere((a) => a.userEmail == email);
    } catch (_) {
      return null;
    }
  }

  /// Returns the current role for [email]: 'user', 'pending', or 'seller'.
  static Future<String> getRole(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_rolePrefix$email') ?? roleUser;
  }

  /// Called on login/refresh so the app reflects any external role change
  /// (e.g., web admin approved the seller). Pass the new role from your
  /// backend response and it will be persisted locally.
  static Future<void> syncRole(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_rolePrefix$email', role);
  }

  /// Returns all applications (used by future admin integration).
  static Future<List<SellerApplication>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }
}
