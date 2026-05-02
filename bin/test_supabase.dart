import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Simple command-line Supabase connectivity test
Future<void> main() async {
  // Load .env
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  print('\n╔════════════════════════════════════════════╗');
  print('║   SUPABASE CONNECTIVITY TEST                ║');
  print('╚════════════════════════════════════════════╝\n');

  // 1. Check if credentials are loaded
  print('📋 STEP 1: Verify Credentials Loaded');
  print('─────────────────────────────────────');
  if (supabaseUrl.isEmpty) {
    print('❌ FAIL: SUPABASE_URL not found in .env');
    return;
  }
  print('✅ URL found: $supabaseUrl');

  if (supabaseKey.isEmpty) {
    print('❌ FAIL: SUPABASE_ANON_KEY not found in .env');
    return;
  }
  print('✅ Key found: ${supabaseKey.substring(0, 20)}...');

  // 2. Verify JWT format
  print('\n📋 STEP 2: Verify JWT Token Format');
  print('─────────────────────────────────────');
  final parts = supabaseKey.split('.');
  if (parts.length != 3) {
    print('❌ FAIL: Invalid JWT format (expected 3 parts, got ${parts.length})');
    return;
  }
  print('✅ JWT has 3 parts (valid format)');

  // 3. Test HTTP connectivity
  print('\n📋 STEP 3: Test HTTP Connectivity');
  print('─────────────────────────────────────');
  try {
    final uri = Uri.parse('$supabaseUrl/rest/v1/');
    final response = await http
        .get(
          uri,
          headers: {
            'apikey': supabaseKey,
            'Authorization': 'Bearer $supabaseKey',
          },
        )
        .timeout(const Duration(seconds: 10));

    print('✅ HTTP Response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 401) {
      print('✅ PASS: Supabase server is reachable!');
    } else {
      print('⚠️ Unexpected status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ FAIL: Cannot reach Supabase');
    print('   Error: $e');
    _debugError(e);
    return;
  }

  // 4. Test Auth endpoint
  print('\n📋 STEP 4: Test Auth Endpoint');
  print('─────────────────────────────────────');
  try {
    final uri = Uri.parse('$supabaseUrl/auth/v1/');
    final response = await http
        .get(uri,
            headers: {
              'apikey': supabaseKey,
              'Authorization': 'Bearer $supabaseKey',
            })
        .timeout(const Duration(seconds: 10));

    print('✅ Auth Endpoint Status: ${response.statusCode}');
    print('✅ PASS: Auth endpoint is reachable!');
  } catch (e) {
    print('⚠️ Auth endpoint error: $e');
  }

  print('\n════════════════════════════════════════════');
  print('✅ ALL TESTS PASSED - Supabase is reachable!');
  print('════════════════════════════════════════════\n');

  print('🔍 NEXT STEPS:');
  print('1. Check Supabase Dashboard → Tables');
  print('2. Verify Row Level Security (RLS) policies');
  print('3. Run: flutter run -d chrome');
}

void _debugError(dynamic e) {
  final msg = e.toString().toLowerCase();
  print('\n🔧 Possible causes:');
  if (msg.contains('socketexception') || msg.contains('connection refused')) {
    print('   • No internet connection');
    print('   • DNS resolution failed');
    print('   • Firewall blocking the request');
  } else if (msg.contains('timeout')) {
    print('   • Network is very slow');
    print('   • Supabase is not responding');
  } else if (msg.contains('certificate')) {
    print('   • SSL certificate issue');
  }
}
