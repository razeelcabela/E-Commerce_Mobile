import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _brandFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 0,
            vertical: 48,
          ),
          child: SizedBox(
            width: 420,
            child: Column(
              children: [
                // ── Brand ────────────────────────────────────────────
                FadeTransition(
                  opacity: _brandFade,
                  child: SlideTransition(
                    position: _brandSlide,
                    child: Column(
                      children: [
                        const Text(
                          'VARÓN',
                          style: TextStyle(
                            fontSize: 22,
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
                  ),
                ),
                const SizedBox(height: 48),

                // ── Card ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECT PORTAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 24,
                            height: 1.5,
                            color: const Color(0xFF0A0A0A),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose how you want to access Varón.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(height: 1, color: const Color(0xFFEEEEEE)),
                          const SizedBox(height: 24),

                          _AnimatedRoleCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'BUYER',
                            subtitle: 'Shop, track orders, and manage your profile',
                            delay: 0.3,
                            parentCtrl: _ctrl,
                            onTap: () => Navigator.of(context).pushNamed('/login'),
                          ),
                          const SizedBox(height: 12),

                          _AnimatedRoleCard(
                            icon: Icons.storefront_outlined,
                            title: 'SELLER',
                            subtitle: 'Manage your store, products, and orders',
                            delay: 0.45,
                            parentCtrl: _ctrl,
                            onTap: () => Navigator.of(context).pushNamed('/seller/login'),
                          ),
                          const SizedBox(height: 12),

                          _AnimatedRoleCard(
                            icon: Icons.delivery_dining,
                            title: 'RIDER',
                            subtitle: 'Accept deliveries, track routes, and earn commission',
                            delay: 0.6,
                            parentCtrl: _ctrl,
                            onTap: () => Navigator.of(context).pushNamed('/rider/login'),
                          ),

                          const SizedBox(height: 32),
                          Container(height: 1, color: const Color(0xFFEEEEEE)),
                          const SizedBox(height: 20),

                          const Center(
                            child: Text(
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card with staggered entrance + hover animation
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedRoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double delay;
  final AnimationController parentCtrl;
  final VoidCallback onTap;

  const _AnimatedRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
    required this.parentCtrl,
    required this.onTap,
  });

  @override
  State<_AnimatedRoleCard> createState() => _AnimatedRoleCardState();
}

class _AnimatedRoleCardState extends State<_AnimatedRoleCard> {
  bool _hovered = false;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    final end = (widget.delay + 0.4).clamp(0.0, 1.0);
    _entranceFade = CurvedAnimation(
      parent: widget.parentCtrl,
      curve: Interval(widget.delay, end, curve: Curves.easeOut),
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.parentCtrl,
      curve: Interval(widget.delay, end, curve: Curves.easeOutCubic),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hovered ? const Color(0xFF0A0A0A) : const Color(0xFFF6F6F6),
                border: Border.all(
                  color: _hovered ? const Color(0xFF0A0A0A) : const Color(0xFFEEEEEE),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    color: _hovered ? Colors.white : const Color(0xFF0A0A0A),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: _hovered ? const Color(0xFF0A0A0A) : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: _hovered ? Colors.white : const Color(0xFF0A0A0A),
                          ),
                          child: Text(widget.title),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            fontSize: 11,
                            color: _hovered ? const Color(0xFFAAAAAA) : const Color(0xFF888888),
                            height: 1.4,
                          ),
                          child: Text(widget.subtitle),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: _hovered ? const Color(0xFF888888) : const Color(0xFFCCCCCC),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
