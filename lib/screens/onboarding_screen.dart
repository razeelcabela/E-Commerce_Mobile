import 'package:flutter/material.dart';
import '../services/unified_auth_service.dart';

/// Onboarding screen for new users to select their role
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectRole(UserRole role) async {
    // For now, just navigate to the appropriate dashboard
    // In a real implementation, this would update the user's role in the database
    Navigator.of(context).pushReplacementNamed(role.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SizedBox(
                width: 420,
                child: Column(
                  children: [
                    // Brand
                    Column(
                      children: [
                        const Text(
                          'VARÓN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF0A0A0A),
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PREMIUM MINIMALIST FASHION',
                          style: TextStyle(
                            fontSize: 8,
                            color: Color(0xFF999999),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 64),

                    // Title
                    const Text(
                      'HOW WOULD YOU LIKE TO USE VARÓN?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: 32,
                      height: 1.5,
                      color: const Color(0xFF0A0A0A),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Choose how you want to experience our platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Role options
                    _RoleOptionCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'SHOP',
                      subtitle: 'Discover and purchase premium fashion',
                      onTap: () => _selectRole(UserRole.buyer),
                    ),

                    const SizedBox(height: 16),

                    _RoleOptionCard(
                      icon: Icons.storefront_outlined,
                      title: 'SELL',
                      subtitle: 'Showcase and sell your fashion collections',
                      onTap: () => _selectRole(UserRole.seller),
                    ),

                    const SizedBox(height: 16),

                    _RoleOptionCard(
                      icon: Icons.delivery_dining,
                      title: 'DELIVER',
                      subtitle: 'Connect buyers and sellers as a rider',
                      onTap: () => _selectRole(UserRole.rider),
                    ),

                    const SizedBox(height: 64),

                    // Footer
                    const Text(
                      'Varón © 2025',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFBBBBBB),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_RoleOptionCard> createState() => _RoleOptionCardState();
}

class _RoleOptionCardState extends State<_RoleOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF0A0A0A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFCCCCCC),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}