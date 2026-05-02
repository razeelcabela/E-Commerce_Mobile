import 'package:flutter/material.dart';
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
      // Small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Check if user is authenticated
      final isAuthenticated = await UnifiedAuthService.isAuthenticated();

      if (!mounted) return;

      if (!isAuthenticated) {
        // Not authenticated - go to login
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Get user roles
      final roles = await UnifiedAuthService.getUserRoles();

      if (!mounted) return;

      if (roles.isEmpty) {
        // No roles found - needs onboarding
        Navigator.of(context).pushReplacementNamed('/onboarding');
        return;
      }

      // Determine route based on roles
      final route = await UnifiedAuthService.determineRoute();

      if (!mounted) return;

      // Navigate to appropriate dashboard
      Navigator.of(context).pushReplacementNamed(route);

    } catch (e) {
      // On error, go to login
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
              child: Column(
                children: [
                  const Text(
                    'VARÓN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
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
                      color: Colors.black.withOpacity(0.05),
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