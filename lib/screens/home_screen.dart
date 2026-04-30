import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/rider_application_service.dart';
import '../services/seller_application_service.dart';
import 'buyer_orders_screen.dart';
import 'rider_application_form_screen.dart';
import 'rider/rider_dashboard_screen.dart';
import 'seller_application_form_screen.dart';
import 'shop_screen.dart';
import 'cart_screen.dart';
import 'seller/seller_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _shopNow() {
    Navigator.of(context).pushNamed('/shop');
  }

  void _navigateToScreen(String label, BuildContext context) {
    switch (label.toLowerCase()) {
      case 'home':
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 'shop':
        Navigator.of(context).pushNamed('/shop');
        break;
      case 'shirts':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ShopScreen(category: 'Shirts'),
          ),
        );
        break;
      case 'pants':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ShopScreen(category: 'Pants'),
          ),
        );
        break;
      case 'cart':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CartScreen(),
          ),
        );
        break;
      case 'profile':
        _showProfileSheet(context);
        break;
    }
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _ProfileSheet(onLogout: _logout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, isMobile),
              _buildHeroSection(context, isMobile),
              _buildCategoriesSection(context, isMobile),
              _buildFeaturedProducts(context, isMobile),
              _buildFooter(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: 22,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VARÓN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: 7,
                ),
              ),

              if (!isMobile)
                Row(
                  children: [
                    _navLink('HOME'),
                    _navLink('SHOP'),
                    _navLink('SHIRTS'),
                    _navLink('PANTS'),
                    _navLink('CART'),
                    PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'logout') _logout();
                        if (result == 'profile') _showProfileSheet(context);
                      },
                      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Text('Profile'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Logout'),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: Icon(Icons.account_circle_outlined, color: Color(0xFF0A0A0A), size: 20),
                            onPressed: null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF0A0A0A), size: 20),
                  onPressed: () {},
                ),
            ],
          ),

          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Wrap(
                spacing: 2,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  _mobileNavLink('HOME'),
                  _mobileNavLink('SHOP'),
                  _mobileNavLink('SHIRTS'),
                  _mobileNavLink('PANTS'),
                  _mobileNavLink('CART'),
                  _mobileNavLink('PROFILE'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _navLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextButton(
        onPressed: () => _navigateToScreen(label, context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _mobileNavLink(String label) {
    return TextButton(
      onPressed: () => _navigateToScreen(label, context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: Colors.transparent,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0A0A0A),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F6F6),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 80 : 128,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Elevate Your Style\nwith Varón',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 36 : 64,
              fontWeight: FontWeight.w200,
              color: const Color(0xFF0A0A0A),
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PREMIUM MINIMALIST FASHION',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF888888),
              letterSpacing: 5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _shopNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 56,
                vertical: 18,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            child: const Text(
              'SHOP NOW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A0A0A),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 28,
          height: 1,
          color: const Color(0xFF0A0A0A),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context, bool isMobile) {
    final categories = [
      {'name': 'Shirts', 'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop'},
      {'name': 'Pants', 'image': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop'},
      {'name': 'T-Shirts', 'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop'},
      {'name': 'Accessories', 'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop'},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: isMobile ? 48 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('SHOP BY CATEGORY'),
          SizedBox(height: isMobile ? 28 : 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isMobile ? 2 : 4;
              final spacing = isMobile ? 10.0 : 16.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;
              final itemHeight = isMobile ? itemWidth * 1.25 : itemWidth * 1.15;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(
                    categories[index]['name']!,
                    categories[index]['image']!,
                    isMobile,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, String imageUrl, bool isMobile) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShopScreen(category: category),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SizedBox(
                width: double.infinity,
                height: isMobile ? 110 : 150,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: isMobile ? 110 : 150,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 1,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      height: isMobile ? 110 : 150,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: isMobile ? 24 : 32,
                          color: const Color(0xFFCCCCCC),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 10 : 14,
                isMobile ? 10 : 12,
                isMobile ? 10 : 14,
                isMobile ? 10 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0A0A),
                      letterSpacing: 2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 2 : 3),
                  Text(
                    'Explore collection',
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10,
                      color: const Color(0xFF999999),
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(BuildContext context, bool isMobile) {
    final products = [
      {
        'name': 'Classic White Shirt',
        'price': '₱1,299',
        'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop',
      },
      {
        'name': 'Slim Fit Black Pants',
        'price': '₱1,899',
        'image': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop',
      },
      {
        'name': 'Premium Cotton T-Shirt',
        'price': '₱599',
        'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop',
      },
      {
        'name': 'Leather Minimalist Belt',
        'price': '₱899',
        'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop',
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F6F6),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: isMobile ? 48 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('FEATURED PRODUCTS'),
          SizedBox(height: isMobile ? 28 : 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isMobile ? 2 : 4;
              final spacing = isMobile ? 10.0 : 16.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;
              final itemHeight = isMobile ? itemWidth * 1.75 : itemWidth * 1.55;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(
                    products[index]['name']!,
                    products[index]['price']!,
                    products[index]['image']!,
                    isMobile,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    String name,
    String price,
    String imageUrl,
    bool isMobile,
  ) {
    final imageHeight = isMobile ? 130.0 : 180.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ShopScreen(),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: imageHeight,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: imageHeight,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 1,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: imageHeight,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: isMobile ? 28 : 36,
                        color: const Color(0xFFCCCCCC),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            SizedBox(
              height: isMobile ? 28 : 34,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A0A0A),
                  letterSpacing: 0.2,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              price,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: const Color(0xFF0A0A0A),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name added to cart'),
                      backgroundColor: const Color(0xFF0A0A0A),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0A0A0A), width: 1),
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  minimumSize: Size(0, isMobile ? 30 : 38),
                ),
                child: Text(
                  'ADD TO CART',
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0A),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 48 : 72,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VARÓN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 7,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'PREMIUM MINIMALIST FASHION',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF666666),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (!isMobile)
                Row(
                  children: [
                    _footerIcon(Icons.facebook),
                    _footerIcon(Icons.photo_camera_outlined),
                    _footerIcon(Icons.share_outlined),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 48),
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _footerIcon(Icons.facebook),
                _footerIcon(Icons.photo_camera_outlined),
                _footerIcon(Icons.share_outlined),
              ],
            ),
            const SizedBox(height: 40),
          ],
          Container(height: 1, color: const Color(0xFF1E1E1E)),
          const SizedBox(height: 28),
          const Text(
            '© 2024 VARÓN. ALL RIGHTS RESERVED.',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF555555),
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: Icon(icon, color: const Color(0xFF666666), size: 17),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSheet extends StatefulWidget {
  final VoidCallback onLogout;
  const _ProfileSheet({required this.onLogout});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  String? _email;
  Map<String, int> _counts = {};
  String _role = SellerApplicationService.roleUser;
  String _riderRole = RiderApplicationService.roleUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await AuthService.getUserEmail();
    if (email == null || !mounted) return;
    final results = await Future.wait([
      OrderService.getByBuyer(email),
      SellerApplicationService.getRole(email),
      RiderApplicationService.getRole(email),
    ]);
    if (!mounted) return;
    final orders = results[0] as List;
    setState(() {
      _email = email;
      _role = results[1] as String;
      _riderRole = results[2] as String;
      _counts = {
        'purchased': orders.length,
        Order.toPay:     orders.where((o) => o.status == Order.toPay).length,
        Order.toShip:    orders.where((o) => o.status == Order.toShip).length,
        Order.toReceive: orders.where((o) => o.status == Order.toReceive).length,
      };
    });
  }

  Future<void> _openApplicationForm() async {
    Navigator.of(context).pop();
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SellerApplicationFormScreen()),
    );
    if (submitted == true && mounted) {
      setState(() => _role = SellerApplicationService.roleSeller);
    }
  }

  Future<void> _openRiderApplicationForm() async {
    Navigator.of(context).pop();
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => const RiderApplicationFormScreen()),
    );
    if (submitted == true && mounted) {
      setState(() => _riderRole = RiderApplicationService.roleRider);
    }
  }

  Widget _buildSellerSection() {
    if (_role == SellerApplicationService.roleSeller) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0A0A0A),
          child: const Row(
            children: [
              Icon(Icons.storefront_outlined, size: 16, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'SELLER DASHBOARD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF888888)),
            ],
          ),
        ),
      );
    }

    if (_role == SellerApplicationService.rolePending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFFFF8E1),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_outlined,
                size: 16, color: Color(0xFFB8860B)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPLICATION PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Color(0xFFB8860B),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Your seller application is under review.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // roleUser — show apply button
    return GestureDetector(
      onTap: _openApplicationForm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF6F6F6),
        child: const Row(
          children: [
            Icon(Icons.storefront_outlined,
                size: 16, color: Color(0xFF0A0A0A)),
            SizedBox(width: 12),
            Text(
              'APPLY AS SELLER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFF0A0A0A),
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 11, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderSection() {
    if (_riderRole == RiderApplicationService.roleRider) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const RiderDashboardScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1A2E),
          child: const Row(
            children: [
              Icon(Icons.delivery_dining, size: 16, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'RIDER DASHBOARD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Icon(Icons.arrow_forward_ios,
                  size: 11, color: Color(0xFF888888)),
            ],
          ),
        ),
      );
    }

    // roleUser — show apply button
    return GestureDetector(
      onTap: _openRiderApplicationForm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF6F6F6),
        child: const Row(
          children: [
            Icon(Icons.delivery_dining, size: 16, color: Color(0xFF0A0A0A)),
            SizedBox(width: 12),
            Text(
              'APPLY AS RIDER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFF0A0A0A),
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 11, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = (_email != null && _email!.isNotEmpty)
        ? _email!.substring(0, 1).toUpperCase()
        : '?';

    final orderItems = <Map<String, dynamic>>[
      {'icon': Icons.shopping_bag_outlined,   'label': 'PURCHASED', 'count': '${_counts['purchased'] ?? 0}'},
      {'icon': Icons.credit_card_outlined,    'label': 'TO PAY',    'count': '${_counts[Order.toPay] ?? 0}'},
      {'icon': Icons.local_shipping_outlined, 'label': 'TO SHIP',   'count': '${_counts[Order.toShip] ?? 0}'},
      {'icon': Icons.move_to_inbox_outlined,  'label': 'TO RECEIVE','count': '${_counts[Order.toReceive] ?? 0}'},
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 4),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MY ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // User info row
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFF0A0A0A),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCOUNT',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999999),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email ?? '—',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0A0A0A),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // Order status
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER STATUS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 24, height: 1, color: const Color(0xFF0A0A0A)),
                const SizedBox(height: 24),
                Row(
                  children: orderItems.map((item) {
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            item['count'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            item['icon'] as IconData,
                            size: 20,
                            color: const Color(0xFF0A0A0A),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF888888),
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // View orders link
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const BuyerOrdersScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF6F6F6),
                child: const Row(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 16, color: Color(0xFF0A0A0A)),
                    SizedBox(width: 12),
                    Text(
                      'VIEW ALL ORDERS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 11, color: Color(0xFFAAAAAA)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // Seller section
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: _buildSellerSection(),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // Rider section
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: _buildRiderSection(),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // Sign out
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLogout();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0A0A0A), width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
