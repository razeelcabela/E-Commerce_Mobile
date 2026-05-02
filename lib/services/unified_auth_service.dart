import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the different user roles in the system
enum UserRole {
  buyer,
  seller,
  rider,
  none;

  String get displayName {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.rider:
        return 'Rider';
      case UserRole.none:
        return 'None';
    }
  }

  String get route {
    switch (this) {
      case UserRole.buyer:
        return '/home';
      case UserRole.seller:
        return '/seller/dashboard';
      case UserRole.rider:
        return '/rider/dashboard';
      case UserRole.none:
        return '/onboarding';
    }
  }
}

/// Unified authentication service for Varón platform
/// Handles role determination and routing automatically
class UnifiedAuthService {
  static const _userRoleKey = 'user_role';
  static const _userEmailKey = 'user_email';
  static const _userIdKey = 'user_id';
  static const _lastActiveRoleKey = 'last_active_role';

  static SupabaseClient get _db => Supabase.instance.client;

  /// Check if user is currently authenticated
  static Future<bool> isAuthenticated() async {
    final session = _db.auth.currentSession;
    return session != null && session.user != null;
  }

  /// Get the current user's role from database
  static Future<UserRole> getUserRole() async {
    try {
      final session = _db.auth.currentSession;
      if (session?.user == null) {
        developer.log('No active session found');
        return UserRole.none;
      }

      final userId = session!.user!.id;
      developer.log('Determining role for user: $userId');

      // Query user profile to get role
      final userProfile = await _db
          .from('users')
          .select('role, account_status')
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (userProfile == null) {
        developer.log('No user profile found - user needs onboarding');
        return UserRole.none;
      }

      final accountStatus = userProfile['account_status'];
      if (accountStatus == 'banned') {
        developer.log('User account is banned');
        return UserRole.none;
      }

      final roleString = userProfile['role'] as String?;
      if (roleString == null) {
        developer.log('No role found in user profile');
        return UserRole.none;
      }

      // Convert string to enum
      switch (roleString.toLowerCase()) {
        case 'buyer':
          return UserRole.buyer;
        case 'seller':
          return UserRole.seller;
        case 'rider':
          return UserRole.rider;
        default:
          developer.log('Unknown role: $roleString');
          return UserRole.none;
      }
    } catch (e) {
      developer.log('Error determining user role: $e');
      return UserRole.none;
    }
  }

  /// Get user's available roles (for users with multiple roles)
  static Future<List<UserRole>> getUserRoles() async {
    try {
      final session = _db.auth.currentSession;
      if (session?.user == null) return [];

      final userId = session!.user!.id;
      final roles = <UserRole>[];

      // Check if user has buyer role
      try {
        final buyerProfile = await _db
            .from('users')
            .select('role')
            .eq('auth_user_id', userId)
            .eq('role', 'buyer')
            .maybeSingle();

        if (buyerProfile != null) {
          roles.add(UserRole.buyer);
        }
      } catch (e) {
        // Ignore errors - role might not exist
      }

      // Check if user has seller role
      try {
        final sellerProfile = await _db
            .from('sellers')
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (sellerProfile != null) {
          roles.add(UserRole.seller);
        }
      } catch (e) {
        // Ignore errors - table might not exist
      }

      // Check if user has rider role
      try {
        final riderProfile = await _db
            .from('riders')
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (riderProfile != null) {
          roles.add(UserRole.rider);
        }
      } catch (e) {
        // Ignore errors - table might not exist
      }

      return roles;
    } catch (e) {
      developer.log('Error getting user roles: $e');
      return [];
    }
  }

  /// Get the last active role for users with multiple roles
  static Future<UserRole?> getLastActiveRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_lastActiveRoleKey);

    if (roleString == null) return null;

    switch (roleString.toLowerCase()) {
      case 'buyer':
        return UserRole.buyer;
      case 'seller':
        return UserRole.seller;
      case 'rider':
        return UserRole.rider;
      default:
        return null;
    }
  }

  /// Set the last active role
  static Future<void> setLastActiveRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveRoleKey, role.name);
  }

  /// Determine the appropriate route for the current user
  static Future<String> determineRoute() async {
    final roles = await getUserRoles();

    if (roles.isEmpty) {
      return '/onboarding';
    }

    if (roles.length == 1) {
      final role = roles.first;
      await setLastActiveRole(role);
      return role.route;
    }

    // Multiple roles - use last active role or default to buyer
    final lastActive = await getLastActiveRole();
    if (lastActive != null && roles.contains(lastActive)) {
      return lastActive.route;
    }

    // Default to buyer if no last active role
    await setLastActiveRole(UserRole.buyer);
    return UserRole.buyer.route;
  }

  /// Logout from all roles
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_lastActiveRoleKey);

    // Also logout from Supabase
    await _db.auth.signOut();
  }

  /// Save user session info
  static Future<void> saveSession(UserRole role, String email, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role.name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userIdKey, userId);
    await setLastActiveRole(role);
  }
}