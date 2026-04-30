import 'package:shared_preferences/shared_preferences.dart';

class RiderApplicationService {
  static const String _rolePrefix = 'rider_role_';

  static const String roleUser = 'user';
  static const String roleRider = 'rider';

  static Future<String> getRole(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_rolePrefix$email') ?? roleUser;
  }

  /// Call after successful registration to grant rider access immediately.
  static Future<void> syncRole(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_rolePrefix$email', role);
  }
}
