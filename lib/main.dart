import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
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

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✅ .env file loaded successfully');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not load .env file: $e');
    }
  } else {
    debugPrint('ℹ️ Running on Flutter Web - using dart-define Supabase config');
  }

  // Check if Supabase is configured
  SupabaseConfig.debugPrintConfig();
  
  if (!SupabaseConfig.isConfigured()) {
    debugPrint('❌ ERROR: Supabase credentials are not configured!');
    if (!kIsWeb) {
      debugPrint('   Create a .env file in the project root');
      debugPrint('   Add SUPABASE_URL and SUPABASE_ANON_KEY');
    } else {
      debugPrint('   For web, set environment variables during build:');
      debugPrint('   flutter run -d chrome --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx');
    }
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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
