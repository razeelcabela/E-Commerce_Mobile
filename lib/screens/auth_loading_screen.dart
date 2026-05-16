import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/rider_auth_service.dart';
import '../services/seller_auth_service.dart';
import '../services/unified_auth_service.dart';

/// Premium loading screen for Varón authentication flow
/// Shows while determining user role and routing to appropriate dashboard
class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.repeat(reverse: true);

    // Start role determination
    _determineUserRole();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _determineUserRole() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      final isAuthenticated = await UnifiedAuthService.isAuthenticated();
      if (!mounted) return;

      if (!isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Single source of truth: read role from users.role column
      final role = await UnifiedAuthService.getUserRole();
      if (!mounted) return;

      if (role == UserRole.none) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      // Admin dashboard is web-only — block admin accounts on mobile
      if (role == UserRole.admin && !kIsWeb) {
        await UnifiedAuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/unauthorized',
          arguments: 'Admin access is only available on the web dashboard.\nPlease use a web browser to access the admin panel.',
        );
        return;
      }

      // Sync role-specific session keys and check approval status
      if (role == UserRole.seller) {
        final status = await SellerAuthService.syncSession();
        if (!mounted) return;
        if (status == null) {
          // syncSession returns null ONLY when there is no Supabase session at all.
          // A seller who is authenticated will always get a non-null status.
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
        if (status == 'pending') {
          Navigator.of(context).pushReplacementNamed(
            '/pending',
            arguments: 'seller',
          );
          return;
        }
        if (status == 'suspended') {
          Navigator.of(context).pushReplacementNamed(
            '/unauthorized',
            arguments: 'Your seller account has been suspended.',
          );
          return;
        }
      } else if (role == UserRole.rider) {
        final status = await RiderAuthService.syncSession();
        if (!mounted) return;
        if (status == null) {
          // Same logic: null means no session, not missing rider profile.
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
        if (status == 'pending') {
          Navigator.of(context).pushReplacementNamed(
            '/pending',
            arguments: 'rider',
          );
          return;
        }
        if (status == 'suspended') {
          Navigator.of(context).pushReplacementNamed(
            '/unauthorized',
            arguments: 'Your rider account has been suspended.',
          );
          return;
        }
      }

      // Persist role in SharedPreferences for fast dashboard guard checks
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await UnifiedAuthService.saveSession(
          role,
          session.user.email ?? '',
          session.user.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(role.route);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    'VARÓN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: 10,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'PREMIUM MINIMALIST FASHION',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF999999),
                      letterSpacing: 5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // Loading indicator
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Loading text
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Authenticating...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 80),

            // Footer
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Varón © 2025',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFBBBBBB),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}