import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

/// Comprehensive Supabase diagnostic tool to debug connectivity issues
class SupabaseDiagnostic {
  
  /// Test if Supabase can be reached via HTTP
  static Future<void> testHttpConnectivity(String supabaseUrl, String anonKey) async {
    debugPrint('\n========== HTTP CONNECTIVITY TEST ==========');
    
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/');
      debugPrint('🔍 Testing HTTP connection to: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('✅ HTTP Response Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 401) {
        debugPrint('✅ PASS: Supabase server is reachable!');
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ FAIL: Cannot reach Supabase server');
      debugPrint('Error: $e');
      _debugConnectionError(e);
    }
  }

  /// Test Supabase auth endpoint
  static Future<void> testAuthEndpoint(String supabaseUrl, String anonKey) async {
    debugPrint('\n========== AUTH ENDPOINT TEST ==========');
    
    try {
      final uri = Uri.parse('$supabaseUrl/auth/v1/');
      debugPrint('🔍 Testing Auth endpoint: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('✅ Auth Endpoint Status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 500) {
        debugPrint('✅ PASS: Auth endpoint is reachable!');
      }
    } catch (e) {
      debugPrint('❌ FAIL: Cannot reach Auth endpoint');
      debugPrint('Error: $e');
    }
  }

  /// Test realtime connection
  static Future<void> testRealtimeConnection() async {
    debugPrint('\n========== REALTIME CONNECTION TEST ==========');
    
    try {
      final client = Supabase.instance.client;
      debugPrint('🔍 Testing Realtime connection...');
      
      // Realtime is optional - just verify the client can create channels
      final channel = client.channel('test-channel');
      debugPrint('✅ PASS: Realtime channel object created successfully');
      
    } catch (e) {
      debugPrint('⚠️ Realtime test skipped: $e');
      debugPrint('   (Realtime is optional - REST API will still work)');
    }
  }

  /// Verify JWT token structure
  static void verifyJwtToken(String anonKey) {
    debugPrint('\n========== JWT TOKEN VERIFICATION ==========');
    
    final parts = anonKey.split('.');
    debugPrint('🔍 JWT Parts: ${parts.length} (expected 3)');
    
    if (parts.length != 3) {
      debugPrint('❌ FAIL: Invalid JWT format (should have 3 parts)');
      return;
    }
    
    try {
      // Decode header
      final header = _decodeBase64(parts[0]);
      debugPrint('✅ Header: $header');
      
      // Decode payload
      final payload = _decodeBase64(parts[1]);
      debugPrint('✅ Payload: $payload');
      
      debugPrint('✅ PASS: JWT token is valid!');
    } catch (e) {
      debugPrint('❌ FAIL: Cannot decode JWT: $e');
    }
  }

  /// Test actual database query (example: get from public table)
  static Future<void> testDatabaseQuery() async {
    debugPrint('\n========== DATABASE QUERY TEST ==========');
    
    try {
      final client = Supabase.instance.client;
      debugPrint('🔍 Attempting to query a table...');
      
      // Try to fetch from auth.users (should work with anon key)
      final response = await client.from('users').select().limit(1);
      
      debugPrint('✅ Query successful!');
      debugPrint('Response: $response');
      debugPrint('✅ PASS: Database is accessible!');
    } catch (e) {
      debugPrint('⚠️ Query failed: $e');
      _analyzeQueryError(e);
    }
  }

  /// Test with custom headers (advanced debugging)
  static Future<void> testWithCustomHeaders(String supabaseUrl, String anonKey) async {
    debugPrint('\n========== CUSTOM HEADERS TEST ==========');
    
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/');
      debugPrint('🔍 Testing with various header combinations...');
      
      final response = await http.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-Supabase-Diagnostic/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('✅ Response Headers: ${response.headers}');
      debugPrint('Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('⚠️ Error: $e');
    }
  }

  /// Run all diagnostics
  static Future<void> runAllDiagnostics(String supabaseUrl, String anonKey) async {
    debugPrint('\n\n╔═══════════════════════════════════════════╗');
    debugPrint('║  SUPABASE COMPREHENSIVE DIAGNOSTIC TEST  ║');
    debugPrint('╚═══════════════════════════════════════════╝\n');
    
    // Validate inputs
    if (supabaseUrl.isEmpty || anonKey.isEmpty) {
      debugPrint('❌ ERROR: supabaseUrl or anonKey is empty!');
      return;
    }
    
    // Run tests in sequence
    verifyJwtToken(anonKey);
    await testHttpConnectivity(supabaseUrl, anonKey);
    await testAuthEndpoint(supabaseUrl, anonKey);
    await testRealtimeConnection();
    await testDatabaseQuery();
    await testWithCustomHeaders(supabaseUrl, anonKey);
    
    debugPrint('\n═════════════════════════════════════════════');
    debugPrint('✅ DIAGNOSTIC TEST COMPLETE');
    debugPrint('═════════════════════════════════════════════\n');
  }

  // ─── HELPER METHODS ─────────────────────────────────────────────────

  static String _decodeBase64(String input) {
    final padded = input.padRight(input.length + (4 - input.length % 4) % 4, '=');
    return String.fromCharCodes(_base64Decode(padded));
  }

  static List<int> _base64Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final output = <int>[];
    var i = 0;

    while (i < input.length) {
      var b = 0;
      var nChars = 0;

      for (var j = 0; j < 4 && i < input.length; j++, i++) {
        final c = input[i];
        if (c == '=') break;

        final index = alphabet.indexOf(c);
        if (index == -1) throw FormatException('Invalid character in base64: $c');

        b = (b << 6) | index;
        nChars++;
      }

      if (nChars == 0) break;

      b <<= 6 * (4 - nChars);
      if (nChars == 2) {
        output.add((b >> 10) & 0xFF);
      } else if (nChars == 3) {
        output.add((b >> 16) & 0xFF);
        output.add((b >> 8) & 0xFF);
      } else if (nChars == 4) {
        output.add((b >> 16) & 0xFF);
        output.add((b >> 8) & 0xFF);
        output.add(b & 0xFF);
      }
    }

    return output;
  }

  static void _debugConnectionError(dynamic e) {
    debugPrint('\n🔧 Possible causes:');
    if (e.toString().contains('SocketException')) {
      debugPrint('   • No internet connection');
      debugPrint('   • DNS resolution failed');
      debugPrint('   • Firewall/proxy blocking request');
    } else if (e.toString().contains('Connection refused')) {
      debugPrint('   • Supabase server is down');
      debugPrint('   • Wrong URL/port');
    } else if (e.toString().contains('timeout')) {
      debugPrint('   • Network is very slow');
      debugPrint('   • Supabase is not responding');
    } else if (e.toString().contains('Certificate')) {
      debugPrint('   • SSL certificate issue');
      debugPrint('   • Man-in-the-middle attack possible');
    }
  }

  static void _analyzeQueryError(dynamic e) {
    debugPrint('\n🔧 Query error analysis:');
    final errorStr = e.toString().toLowerCase();
    
    if (errorStr.contains('row level security')) {
      debugPrint('   ❌ Row Level Security (RLS) is blocking the request');
      debugPrint('   → Go to Supabase dashboard → SQL Editor');
      debugPrint('   → Verify RLS policies allow anon role access');
    } else if (errorStr.contains('permission')) {
      debugPrint('   ❌ Permission denied');
      debugPrint('   → Check if table RLS policies are enabled');
      debugPrint('   → Verify anon role has SELECT permission');
    } else if (errorStr.contains('not found')) {
      debugPrint('   ⚠️ Table not found');
      debugPrint('   → Check if table exists in your schema');
    } else if (errorStr.contains('unauthorized')) {
      debugPrint('   ❌ Unauthorized - token issue');
      debugPrint('   → Verify SUPABASE_ANON_KEY is correct');
    }
  }
}
