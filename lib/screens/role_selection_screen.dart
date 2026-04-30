import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
                // Brand
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
                const SizedBox(height: 48),

                // Card
                Container(
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
                          color: const Color(0xFF0A0A0A)),
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
                      Container(
                          height: 1, color: const Color(0xFFEEEEEE)),
                      const SizedBox(height: 24),

                      // ── Buyer ─────────────────────────────────────
                      _RoleCard(
                        icon: Icons.shopping_bag_outlined,
                        title: 'BUYER',
                        subtitle: 'Shop, track orders, and manage your profile',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/login'),
                      ),
                      const SizedBox(height: 12),

                      // ── Seller ────────────────────────────────────
                      _RoleCard(
                        icon: Icons.storefront_outlined,
                        title: 'SELLER',
                        subtitle:
                            'Manage your store, products, and orders',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/seller/login'),
                      ),
                      const SizedBox(height: 12),

                      // ── Rider ─────────────────────────────────────
                      _RoleCard(
                        icon: Icons.delivery_dining,
                        title: 'RIDER',
                        subtitle:
                            'Accept deliveries, track routes, and earn commission',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/rider/login'),
                      ),

                      const SizedBox(height: 32),
                      Container(
                          height: 1, color: const Color(0xFFEEEEEE)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFF6F6F6),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              // Icon block
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                color: _hovered
                    ? Colors.white
                    : const Color(0xFF0A0A0A),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: _hovered
                      ? const Color(0xFF0A0A0A)
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: _hovered
                            ? Colors.white
                            : const Color(0xFF0A0A0A),
                      ),
                      child: Text(widget.title),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontSize: 11,
                        color: _hovered
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF888888),
                        height: 1.4,
                      ),
                      child: Text(widget.subtitle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arrow
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: _hovered
                      ? const Color(0xFF888888)
                      : const Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
