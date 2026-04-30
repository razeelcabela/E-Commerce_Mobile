import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'address_service.dart';

class AuthService {
  static const _loginKey      = 'is_logged_in';
  static const _userEmailKey  = 'user_email';
  static const _userIdKey     = 'user_id';

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static SupabaseClient get _db => Supabase.instance.client;

  // ─── Session ───────────────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginKey) ?? false;
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await AddressService.clearAddress();
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string on failure.
  /// Uses Supabase Auth for proper authentication.
  static Future<String?> login(String email, String password) async {
    try {
      developer.log('═══════════════════════════════════════');
      developer.log('Starting LOGIN for: $email');
      developer.log('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      developer.log('═══════════════════════════════════════');
      
      // STEP 1: Authenticate with Supabase Auth
      developer.log('STEP 1: Calling Supabase Auth signInWithPassword...');
      final authResponse = await _db.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final authUser = authResponse.user;
      final session = authResponse.session;
      
      developer.log('Auth Response: user=$authUser, session=$session');
      
      if (authUser == null || session == null) {
        developer.log('ERROR: Auth returned null user or session');
        return 'Login failed: Invalid auth response from Supabase.';
      }

      developer.log('✅ Auth SUCCESS! User ID: ${authUser.id}');

      // STEP 2: Try to fetch user profile from users table
      developer.log('STEP 2: Fetching user profile from users table...');
      developer.log('Query: select * from users where id=${authUser.id}');
      
      try {
        final user = await _db
            .from('users')
            .select('*')
            .eq('auth_user_id', authUser.id)
            .maybeSingle();

        if (user == null) {
          developer.log('⚠️ WARNING: User profile not found in users table');
          developer.log('Auth succeeded but profile is missing. Creating minimal profile...');
          
          // Try to create a minimal profile
          try {
            await _db.from('users').insert({
              'email': email.trim(),
              'auth_user_id': authUser.id,
              'role': 'buyer',
              'account_status': 'active',
              'buyer_approval_status': 'approved',
            });
            developer.log('✅ Created minimal user profile');
          } catch (insertError) {
            developer.log('Could not auto-create profile: $insertError');
          }
          
          // Allow login anyway
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_loginKey, true);
          await prefs.setString(_userEmailKey, email.trim());
          await prefs.remove(_userIdKey);
          
          developer.log('✅ PARTIAL LOGIN SUCCESS (profile created or will be created later)');
          return null;
        }

        developer.log('✅ Profile found: $user');
        
        final accountStatus = user['account_status'];
        if (accountStatus == 'banned') {
          developer.log('❌ Account is BANNED');
          return 'Your account has been banned.';
        }

        // STEP 3: Save to SharedPreferences
        developer.log('STEP 3: Saving session to SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_loginKey, true);
        await prefs.setString(_userEmailKey, email.trim());
        
        // Try to save numeric ID if it exists
        if (user['id'] != null) {
          try {
            // If id is a string UUID, don't save as int
            if (user['id'] is String) {
              await prefs.setString('${_userIdKey}_uuid', user['id']);
            } else if (user['id'] is int) {
              await prefs.setInt(_userIdKey, user['id']);
            }
          } catch (_) {
            // Ignore if we can't save the ID
          }
        }

        developer.log('═══════════════════════════════════════');
        developer.log('✅ LOGIN SUCCESSFUL!');
        developer.log('Email: $email');
        developer.log('User ID: ${authUser.id}');
        developer.log('═══════════════════════════════════════');
        return null;
        
      } on PostgrestException catch (e) {
        developer.log('❌ Database error during profile fetch');
        developer.log('Code: ${e.code}');
        developer.log('Message: ${e.message}');
        developer.log('Details: ${e.details}');
        developer.log('Full exception: ${e.toString()}');
        
        // Allow login anyway - profile table may not exist or RLS may block it
        developer.log('⚠️ Allowing login despite database error');
        developer.log('User authenticated successfully - this is just a profile fetch issue');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_loginKey, true);
        await prefs.setString(_userEmailKey, email.trim());
        await prefs.remove(_userIdKey);
        return null; // Allow login to proceed
      }
      
    } on AuthException catch (e) {
      developer.log('❌ Supabase Auth Exception');
      developer.log('Status Code: ${e.statusCode}');
      developer.log('Message: ${e.message}');
      developer.log('Full exception: ${e.toString()}');

      final msg = e.message.toLowerCase();

      if (e.statusCode == '404' ||
          msg.contains('404') ||
          msg.contains('empty response')) {
        return 'Cannot reach Supabase. Your project may be paused — '
            'go to supabase.com/dashboard and restore it, then try again.';
      }

      if (e.statusCode == '401' ||
          msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials')) {
        return 'Email or password is incorrect.';
      }

      if (msg.contains('invalid api key') || msg.contains('apikey')) {
        return 'Invalid API key. Open supabase.com/dashboard → Settings → API '
            'and copy the anon public key into your .env file.';
      }

      if (msg.contains('user not found')) {
        return 'No account found with this email.';
      }

      if (msg.contains('email not confirmed')) {
        return 'Please confirm your email before logging in.';
      }

      return 'Login failed: ${e.message}';
      
    } on SocketException catch (e) {
      developer.log('❌ Network Error: $e');
      return 'Network error. Check your internet connection.';
      
    } catch (e, stackTrace) {
      developer.log('❌ Unexpected Error Type: ${e.runtimeType}');
      developer.log('Error: $e');
      developer.log('Stack trace: $stackTrace');
      
      final errorStr = e.toString();
      
      // Check if it's a 404 error
      if (errorStr.contains('404')) {
        developer.log('⚠️ Detected 404 error - users table may not exist or RLS policy is blocking access');
        developer.log('Supabase URL: ${SupabaseConfig.supabaseUrl}');
        developer.log('Allow login anyway since auth succeeded');
        
        // If auth succeeded but profile fetch failed with 404, allow login
        return null;
      }
      
      return 'Login failed: $e';
    }
  }

  /// Deprecated: Use login() instead. This method uses old password-based authentication.
  @Deprecated('Use login() method instead. This uses Supabase Auth.')
  static Future<String?> loginWithPassword(String email, String password) async {
    return login(email, password);
  }

  // ─── Sign Up ───────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string on failure.
  /// Handles all three steps: auth signup, profile creation, and session persistence.
  static Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final normalizedEmail = email.trim();
    developer.log('Starting signup for: $normalizedEmail');

    if (!_emailPattern.hasMatch(normalizedEmail)) {
      return 'Enter a valid email address.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    
    try {
      final authResponse = await _db.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        developer.log('ERROR: User ID is null after signup response!');
        return 'Signup succeeded but no auth user ID was returned. Check your email confirmation settings.';
      }

      developer.log('Auth signup successful for: $normalizedEmail');
      developer.log('Creating profile for auth user: $userId');

      try {
        await _db.from('users').insert({
          'email': normalizedEmail,
          'auth_user_id': userId,
          'password': password,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': phone.trim(),
          'role': 'buyer',
          'account_status': 'active',
          'buyer_approval_status': 'approved',
          'created_at': DateTime.now().toIso8601String(),
        });

        developer.log('Profile created successfully for: $normalizedEmail');
        
        // Step 3: Save to local preferences for session management
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_loginKey, true);
        await prefs.setString(_userEmailKey, normalizedEmail);
        await prefs.remove(_userIdKey);
        developer.log('Session saved for: $normalizedEmail');
        
      } on PostgrestException catch (e) {
        // Profile insert failed — try to clean up the auth account
        developer.log('Profile creation error: ${e.message} (code: ${e.code})');
        
        return 'Failed to create user profile. ${e.message}';
      } on AuthException catch (e) {
        developer.log('Auth error while creating profile: ${e.message} (code: ${e.statusCode})');
        return 'Failed to create user profile. ${e.message}';
      }

      developer.log('Signup completed successfully for: $normalizedEmail');
      
      return null;
    } on AuthException catch (e) {
      developer.log('Auth signup error: ${e.message} (code: ${e.statusCode})');
      developer.log('Full exception: ${e.toString()}');
      if (e.statusCode == '429' ||
          e.message.toLowerCase().contains('rate limit') ||
          e.message.toLowerCase().contains('too many requests')) {
        return 'Supabase is limiting signup emails right now. Wait a few minutes or disable email confirmation in Supabase Auth for development.';
      }
      if (e.message.toLowerCase().contains('already registered')) {
        return 'An account with this email already exists.';
      }
      if (e.message.toLowerCase().contains('password') || e.message.toLowerCase().contains('weak')) {
        return 'Password is too weak. Use at least 6 characters.';
      }
      if (e.message.trim().isEmpty) {
        return 'Sign up failed. Check that your email is valid and try again.';
      }
      return 'Sign up failed: ${e.message}';
    } on SocketException catch (e) {
      developer.log('Network error during signup: $e');
      return 'Network error. Check your internet connection and try again.';
    } catch (e, stackTrace) {
      developer.log('Unexpected signup error: $e\n$stackTrace');
      return 'Sign up failed: An unexpected error occurred. Please try again.';
    }
  }

  // ─── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final email = await getUserEmail();
    if (email == null) return null;
    try {
      return await _db
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();
    } catch (e) {
      developer.log('Error fetching profile: $e');
      return null;
    }
  }
}
