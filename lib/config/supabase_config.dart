import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // For web: try dart-define first
  static const String _webSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _webSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Reads Supabase credentials from multiple sources (in priority order):
  /// 1. Dart define values via --dart-define (best for web/deployment)
  /// 2. dotenv.env (works if dotenv is loaded first - all platforms)
  /// 3. Empty string if not found (will trigger error message)
  static String get supabaseUrl {
    // Try dart-define first (web and native)
    if (_webSupabaseUrl.isNotEmpty) {
      debugPrint('✅ supabaseUrl loaded from dart-define');
      return _webSupabaseUrl;
    }

    // Try dotenv (all platforms after dotenv.load is called)
    try {
      final fromDotenv = dotenv.env['SUPABASE_URL'];
      if (fromDotenv != null && fromDotenv.isNotEmpty) {
        debugPrint('✅ supabaseUrl loaded from dotenv');
        return fromDotenv;
      }
    } catch (e) {
      debugPrint('⚠️ dotenv not ready yet or error: $e');
    }

    debugPrint('❌ supabaseUrl NOT FOUND - check .env file or use --dart-define');
    return '';
  }

  static String get supabaseAnonKey {
    // Try dart-define first (web and native)
    if (_webSupabaseAnonKey.isNotEmpty) {
      debugPrint('✅ supabaseAnonKey loaded from dart-define');
      return _webSupabaseAnonKey;
    }

    // Try dotenv (all platforms after dotenv.load is called)
    try {
      final fromDotenv = dotenv.env['SUPABASE_ANON_KEY'];
      if (fromDotenv != null && fromDotenv.isNotEmpty) {
        debugPrint('✅ supabaseAnonKey loaded from dotenv');
        return fromDotenv;
      }
    } catch (e) {
      debugPrint('⚠️ dotenv not ready yet or error: $e');
    }

    debugPrint('❌ supabaseAnonKey NOT FOUND - check .env file or use --dart-define');
    return '';
  }

  static bool isConfigured() {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    
    if (url.isEmpty || key.isEmpty) {
      return false;
    }

    if (!url.startsWith('https://')) {
      return false;
    }

    return true;
  }

  static void debugPrintConfig() {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    debugPrint('=== Supabase Config Debug ===');
    debugPrint('Platform: ${kIsWeb ? 'Web' : 'Native'}');
    debugPrint('URL: ${url.isEmpty ? 'NOT FOUND' : url}');
    // Print key prefix so you can verify it matches the dashboard without exposing the full secret
    if (key.isEmpty) {
      debugPrint('ANON KEY: NOT FOUND — check .env file or dart-define flags');
    } else {
      final parts = key.split('.');
      debugPrint('ANON KEY parts: ${parts.length} (expected 3 for a valid JWT)');
      if (parts.length == 3) {
        debugPrint('ANON KEY prefix: ${key.substring(0, key.length < 40 ? key.length : 40)}...');
        // Decode payload to verify role and ref
        try {
          final payload = parts[1];
          final padded = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
          final decoded = String.fromCharCodes(
            _base64Decode(padded),
          );
          debugPrint('ANON KEY payload: $decoded');
        } catch (_) {
          debugPrint('ANON KEY payload: (could not decode)');
        }
      } else {
        debugPrint('ANON KEY: MALFORMED — not a 3-part JWT. Check for missing characters.');
      }
    }
    debugPrint('Is configured: ${isConfigured()}');
    debugPrint('=============================');
  }

  static List<int> _base64Decode(String s) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    // Convert base64url to base64
    final b64 = s.replaceAll('-', '+').replaceAll('_', '/');
    final bytes = <int>[];
    for (var i = 0; i < b64.length; i += 4) {
      final chunk = b64.substring(i, i + 4 > b64.length ? b64.length : i + 4).padRight(4, '=');
      final n = (chars.indexOf(chunk[0]) << 18) |
                (chars.indexOf(chunk[1]) << 12) |
                (chunk[2] == '=' ? 0 : chars.indexOf(chunk[2]) << 6) |
                (chunk[3] == '=' ? 0 : chars.indexOf(chunk[3]));
      bytes.add((n >> 16) & 0xff);
      if (chunk[2] != '=') bytes.add((n >> 8) & 0xff);
      if (chunk[3] != '=') bytes.add(n & 0xff);
    }
    return bytes;
  }
}
