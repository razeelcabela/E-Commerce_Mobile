import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Quick verification script to check .env loading
void main() async {
  print('\n╔════════════════════════════════════════════╗');
  print('║  .ENV LOADING VERIFICATION                 ║');
  print('╚════════════════════════════════════════════╝\n');

  // Test 1: Check if .env file can be loaded
  print('📋 Test 1: Loading .env file...');
  try {
    await dotenv.load(fileName: '.env');
    print('✅ .env file loaded successfully\n');
  } catch (e) {
    print('❌ Failed to load .env: $e');
    print('   Make sure .env file exists in project root\n');
    return;
  }

  // Test 2: Check if SUPABASE_URL exists
  print('📋 Test 2: Checking SUPABASE_URL...');
  final url = dotenv.env['SUPABASE_URL'];
  if (url == null || url.isEmpty) {
    print('❌ SUPABASE_URL not found in .env');
    print('   Add this to .env: SUPABASE_URL=https://your-project.supabase.co\n');
  } else {
    print('✅ SUPABASE_URL found: $url\n');
  }

  // Test 3: Check if SUPABASE_ANON_KEY exists
  print('📋 Test 3: Checking SUPABASE_ANON_KEY...');
  final key = dotenv.env['SUPABASE_ANON_KEY'];
  if (key == null || key.isEmpty) {
    print('❌ SUPABASE_ANON_KEY not found in .env');
    print('   Add this to .env: SUPABASE_ANON_KEY=your-anon-key\n');
  } else {
    print('✅ SUPABASE_ANON_KEY found: ${key.substring(0, 20)}...\n');
  }

  // Test 4: Verify JWT format
  if (key != null && key.isNotEmpty) {
    print('📋 Test 4: Verifying JWT token format...');
    final parts = key.split('.');
    if (parts.length == 3) {
      print('✅ JWT has valid 3-part format\n');
    } else {
      print('❌ JWT malformed - expected 3 parts, got ${parts.length}\n');
    }
  }

  // Test 5: Show all env vars
  print('📋 Test 5: All environment variables:');
  dotenv.env.forEach((key, value) {
    final masked = value.length > 20 ? '${value.substring(0, 20)}...' : value;
    print('   $key = $masked');
  });

  print('\n════════════════════════════════════════════');
  if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
    print('✅ ALL CHECKS PASSED - .env is properly configured!');
  } else {
    print('❌ SOME CHECKS FAILED - Fix the issues above');
  }
  print('════════════════════════════════════════════\n');
}
