import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced Supabase operations with comprehensive error handling and diagnostics
class SupabaseServiceEnhanced {
  static final SupabaseClient client = Supabase.instance.client;

  /// Test basic connectivity with proper error handling
  static Future<bool> testConnectivity() async {
    try {
      debugPrint('🔍 Testing Supabase connectivity...');

      // Try to get current session
      final session = client.auth.currentSession;
      debugPrint('✅ Supabase client is initialized');

      // Attempt a real query to verify connection
      try {
        final result = await client.from('users').select().limit(1);
        debugPrint('✅ Database connection successful - query returned');
        return true;
      } on PostgrestException catch (e) {
        // RLS might block this, but connection worked if we get here
        if (e.code == '42501') {
          debugPrint('✅ Connection OK (RLS blocking - see below)');
          debugPrint('   Error: Row Level Security is restricting access');
          return true;
        }
        debugPrint('⚠️ Query error: ${e.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Connectivity test failed: $e');
      return false;
    }
  }

  /// Safe query with detailed error handling
  static Future<List<Map<String, dynamic>>> safeQuery(
    String table, {
    String select = '*',
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('📊 Querying table: $table');

      var query = client.from(table).select(select);

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      debugPrint('✅ Query successful, rows: ${response.length}');
      return response;
    } on PostgrestException catch (e) {
      _handlePostgrestError(table, e);
      return [];
    } catch (e) {
      debugPrint('❌ Query error on $table: $e');
      return [];
    }
  }

  /// Handle Postgrest-specific errors with detailed diagnostics
  static void _handlePostgrestError(String table, PostgrestException error) {
    debugPrint('\n❌ POSTGREST ERROR on "$table":');
    debugPrint('   Code: ${error.code}');
    debugPrint('   Message: ${error.message}');
    if (error.details != null) debugPrint('   Details: ${error.details}');
    if (error.hint != null) debugPrint('   Hint: ${error.hint}');

    // Detailed error analysis
    if (error.code == '42P01') {
      debugPrint('\n🔧 FIX: Table "$table" does not exist');
      debugPrint('   → Check if table name is correct');
      debugPrint('   → Verify table exists in Supabase dashboard');
    } else if (error.code == '42501') {
      debugPrint('\n🔧 FIX: Row Level Security (RLS) blocking access');
      debugPrint('   Steps to fix:');
      debugPrint('   1. Go to Supabase Dashboard → SQL Editor');
      debugPrint('   2. Find table "$table" in Tables list');
      debugPrint('   3. Either:');
      debugPrint('      a) Disable RLS (not recommended for production)');
      debugPrint('      b) Create RLS policy allowing anon role:');
      debugPrint('         CREATE POLICY "Allow anon select"');
      debugPrint('         ON $table FOR SELECT');
      debugPrint('         TO anon');
      debugPrint('         USING (true);');
    } else if (error.code == '42000') {
      debugPrint('\n🔧 FIX: Permission denied');
      debugPrint('   → Check RLS policies');
      debugPrint('   → Verify user role has access');
    } else if (error.message.toLowerCase().contains('connection')) {
      debugPrint('\n🔧 FIX: Connection issue');
      debugPrint('   → Check internet connection');
      debugPrint('   → Verify Supabase is not paused');
      debugPrint('   → Check API URL is correct');
    } else if (error.message.toLowerCase().contains('invalid')) {
      debugPrint('\n🔧 FIX: Invalid request');
      debugPrint('   → Check filter syntax');
      debugPrint('   → Verify column names exist');
    }
  }

  /// Insert with comprehensive error handling
  static Future<bool> insert(String table, Map<String, dynamic> data) async {
    try {
      debugPrint('➕ Inserting into $table: $data');
      await client.from(table).insert([data]);
      debugPrint('✅ Insert successful');
      return true;
    } on PostgrestException catch (e) {
      _handlePostgrestError(table, e);
      return false;
    } catch (e) {
      debugPrint('❌ Insert failed: $e');
      return false;
    }
  }

  /// Get auth status with detailed info
  static Future<void> printAuthStatus() async {
    final user = client.auth.currentUser;
    final session = client.auth.currentSession;

    debugPrint('\n========== AUTH STATUS ==========');
    if (user != null) {
      debugPrint('✅ User logged in');
      debugPrint('   ID: ${user.id}');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Role: ${user.role}');
    } else {
      debugPrint('ℹ️ Anonymous access (no user logged in)');
    }

    if (session != null) {
      debugPrint('✅ Valid session exists');
      debugPrint('   Expires at: ${session.expiresAt}');
    } else {
      debugPrint('ℹ️ No active session');
    }
    debugPrint('================================\n');
  }
}
