import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header Navigation
            _buildHeader(),
            
            // Hero Section
            _buildHeroSection(),
            
            // Featured Categories
            _buildCategoriesSection(),
            
            // About Section
            _buildAboutSection(),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Varón',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _scrollToSection(_categoriesKey),
                child: Text(
                  'Browse',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => _scrollToSection(_aboutKey),
                child: Text(
                  'About',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: MediaQuery.of(context).size.height * 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VARÓN / MANILA',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Menswear\nredefined for the\nmodern gentleman.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discover contemporary silhouettes, elevated fabrics,\nand purposeful essentials designed for discerning\nFilipino men. Each drop is hand-curated with local\nateliers and global partners for a seamless wardrobe\nrefresh.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFCCCCCC),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/shop');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Shop Now',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent * 0.5,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Our Story',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('100+', 'CURATED PIECES'),
              _buildStatCard('10', 'PARTNER\nATELIERS'),
              _buildStatCard('24h', 'METRO DELIVERY'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String stat, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: const Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {
        'name': 'All Products',
        'icon': '🛍️',
      },
      {
        'name': 'Tops',
        'icon': '👕',
      },
      {
        'name': 'Bottoms',
        'icon': '👖',
      },
      {
        'name': 'Footwear',
        'icon': '👟',
      },
      {
        'name': 'Accessories',
        'icon': '⌚',
      },
    ];

    return Container(
      key: _categoriesKey,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a category to explore its collection.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEEEEEE),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['icon'] as String,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category['name'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      key: _aboutKey,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT VARÓN',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Crafted in Manila,\ninspired by the world.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A0A0A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Varón began in 2025 with a simple idea: elevate everyday wardrobes without losing the warmth of Filipino craftsmanship. Today, we curate limited capsules with independent ateliers, regional sellers, and textile partners who share our obsession for detail.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF555555),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 32),
          _buildAboutFeature(
            'Responsible Materials',
            'Organic cotton, linen, and recycled blends sourced from certified mills across Luzon and Visayas.',
          ),
          const SizedBox(height: 24),
          _buildAboutFeature(
            'Community First',
            '48+ local partner ateliers and riders ensure every order fuels homegrown livelihoods.',
          ),
          const SizedBox(height: 24),
          _buildAboutFeature(
            'Seamless Experience',
            'Same-day Metro deliveries, curated styling notes, and transparent updates in every package.',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC857),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Varón in numbers',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNumberStat('12 seasonal drops per year'),
                const SizedBox(height: 12),
                _buildNumberStat('98% next-day fulfillment in NCR'),
                const SizedBox(height: 12),
                _buildNumberStat('20k+ verified customer reviews'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutFeature(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '✓',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberStat(String text) {
    return Row(
      children: [
        Text(
          '• ',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF0A0A0A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Varón',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minimal, responsibly-made\napparel. Clean silhouettes and\ntimeless staples.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFAAAAAA),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFooterLink('All Products'),
                  const SizedBox(height: 8),
                  _buildFooterLink('New Arrivals'),
                  const SizedBox(height: 8),
                  _buildFooterLink('Best Sellers'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genres',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFooterLink('Tops'),
                  const SizedBox(height: 8),
                  _buildFooterLink('Bottoms'),
                  const SizedBox(height: 8),
                  _buildFooterLink('Outerwear'),
                  const SizedBox(height: 8),
                  _buildFooterLink('Accessories'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partners',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFooterLink('Register as a seller'),
                  const SizedBox(height: 8),
                  _buildFooterLink('Register as a rider'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(
            color: Color(0xFF333333),
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Varón — Minimal Apparel',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
              Text(
                '© 2025',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}
