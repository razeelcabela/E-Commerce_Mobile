import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/seller/seller_dashboard_screen.dart';
import 'screens/rider/rider_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Always try to load .env (works on all platforms)
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint('⚠️ .env file not found or error loading: $e');
  }

  // STEP 2: Show platform info
  debugPrint('Platform: ${kIsWeb ? '🌐 WEB' : '📱 NATIVE'}');

  // STEP 3: Get and validate Supabase credentials
  debugPrint('\n=== CHECKING SUPABASE CREDENTIALS ===');
  SupabaseConfig.debugPrintConfig();

  final url = SupabaseConfig.supabaseUrl;
  final key = SupabaseConfig.supabaseAnonKey;

  if (url.isEmpty || key.isEmpty) {
    debugPrint('\n❌ CRITICAL ERROR: Supabase credentials are empty!');
    debugPrint('\n📋 HOW TO FIX:');
    if (kIsWeb) {
      debugPrint('For Flutter Web, you have two options:\n');
      debugPrint('OPTION 1: Use --dart-define flags (recommended for production)');
      debugPrint('  flutter run -d chrome \\');
      debugPrint('    --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\');
      debugPrint('    --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY\n');
      debugPrint('OPTION 2: Use .env file (for development, requires web_entrypoint)');
      debugPrint('  1. Make sure .env exists in project root');
      debugPrint('  2. Verify pubspec.yaml has: assets: [.env]');
      debugPrint('  3. Run: flutter run -d chrome');
    } else {
      debugPrint('For Flutter Native:\n');
      debugPrint('1. Create .env file in project root:');
      debugPrint('   SUPABASE_URL=https://YOUR_PROJECT.supabase.co');
      debugPrint('   SUPABASE_ANON_KEY=YOUR_ANON_KEY\n');
      debugPrint('2. Verify pubspec.yaml has: assets: [.env]\n');
      debugPrint('3. Run: flutter run');
    }
    throw Exception('Supabase credentials not configured!');
  }

  debugPrint('\n✅ Credentials loaded successfully');

  // STEP 4: Initialize Supabase
  debugPrint('\n=== INITIALIZING SUPABASE ===');
  try {
    await Supabase.initialize(
      url: url,
      anonKey: key,
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Varón',
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: const LoginScreen(),
      routes: {
        '/auth-loading':      (context) => const AuthLoadingScreen(),
        '/login':             (context) => const LoginScreen(),
        '/onboarding':        (context) => const OnboardingScreen(),
        '/home':              (context) => const HomeScreen(),
        '/shop':              (context) => const ShopScreen(),
        '/seller/dashboard':  (context) => const SellerDashboardScreen(),
        '/rider/dashboard':   (context) => const RiderDashboardScreen(),
      },
    );
  }
}
