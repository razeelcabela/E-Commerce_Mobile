import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/supabase_diagnostic.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/seller/seller_login_screen.dart';
import 'screens/seller/seller_dashboard_screen.dart';
import 'screens/rider/rider_login_screen.dart';
import 'screens/rider/rider_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/seller_auth_service.dart';
import 'services/rider_auth_service.dart';

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

  // STEP 5: Run diagnostics
  debugPrint('\n📡 Running Supabase Connectivity Diagnostics...\n');
  await SupabaseDiagnostic.runAllDiagnostics(url, key);

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
      home: const InitScreen(),
      routes: {
        '/select-role':       (context) => const RoleSelectionScreen(),
        '/home':              (context) => const HomeScreen(),
        '/login':             (context) => const LoginScreen(),
        '/shop':              (context) => const ShopScreen(),
        '/seller/login':      (context) => const SellerLoginScreen(),
        '/seller/dashboard':  (context) => const SellerDashboardScreen(),
        '/rider/login':       (context) => const RiderLoginScreen(),
        '/rider/dashboard':   (context) => const RiderDashboardScreen(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash / Init screen — checks all three auth states before routing
// ─────────────────────────────────────────────────────────────────────────────

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Check all three auth states in parallel
    final results = await Future.wait([
      AuthService.isLoggedIn(),
      SellerAuthService.isLoggedIn(),
      RiderAuthService.isLoggedIn(),
    ]);

    if (!mounted) return;

    final buyerLoggedIn  = results[0];
    final sellerLoggedIn = results[1];
    final riderLoggedIn  = results[2];

    if (buyerLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (sellerLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/seller/dashboard');
    } else if (riderLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/rider/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/select-role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Varón',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Minimalist Fashion',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
