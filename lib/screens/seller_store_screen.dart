import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class SellerStoreScreen extends StatefulWidget {
  final dynamic sellerId;
  final String sellerName;
  final String sellerLogoUrl;

  const SellerStoreScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerLogoUrl = '',
  });

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  Map<String, dynamic>? _profile;
  List<Product> _all = [];
  List<Product> _filtered = [];
  String _selectedCategory = 'All';
  bool _loading = true;
  late CartService _cart;

  @override
  void initState() {
    super.initState();
    _cart = CartService();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ProductService.getSellerProfile(widget.sellerId),
      ProductService.getProductsBySellerId(widget.sellerId),
    ]);
    if (!mounted) return;

    final profile = results[0] as Map<String, dynamic>?;
    final products = results[1] as List<Product>;

    // If the direct profile fetch failed, extract seller data from the
    // first loaded product that carries a non-empty sellerName.
    Map<String, dynamic>? resolvedProfile = profile;
    if ((resolvedProfile == null || _storeName(resolvedProfile).isEmpty) &&
        products.isNotEmpty) {
      final withName = products.firstWhere(
        (p) => p.sellerName.isNotEmpty,
        orElse: () => products.first,
      );
      if (withName.sellerName.isNotEmpty) {
        resolvedProfile = {
          'store_name': withName.sellerName,
          'logo_url': withName.sellerLogoUrl,
          ...?profile,
        };
      }
    }

    setState(() {
      _profile = resolvedProfile;
      _all = products;
      _filtered = products;
      _loading = false;
    });
  }

  /// Resolves store name from a profile map.
  static String _storeName(Map<String, dynamic> p) =>
      (p['store_name'] as String?)?.trim() ?? '';

  List<String> get _categories {
    final cats = _all.map((p) => p.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  void _filterCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _filtered = cat == 'All'
          ? _all
          : _all
              .where((p) => p.category.toLowerCase() == cat.toLowerCase())
              .toList();
    });
  }

  void _addToCart(Product product) {
    _cart.addToCart(product);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${product.name} added to cart',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      backgroundColor: const Color(0xFF0A0A0A),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final resolvedName = _profile != null ? _storeName(_profile!) : '';
    final storeName = resolvedName.isNotEmpty
        ? resolvedName
        : widget.sellerName.isNotEmpty
            ? widget.sellerName
            : 'Shop #${widget.sellerId}';
    final description = (_profile?['store_description'] as String?) ??
        (_profile?['description'] as String?) ??
        (_profile?['address'] as String?) ??
        '';
    final logoUrl = (_profile?['logo_url'] as String?) ??
        (_profile?['avatar_url'] as String?) ??
        widget.sellerLogoUrl;
    final bannerUrl = (_profile?['banner_url'] as String?) ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0A0A0A), strokeWidth: 1.5),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(storeName, logoUrl, bannerUrl, isMobile),
                SliverToBoxAdapter(
                  child: _buildInfoCard(description, isMobile),
                ),
                SliverToBoxAdapter(
                  child: _buildCategoryChips(isMobile),
                ),
                SliverToBoxAdapter(
                  child: _buildProductsHeader(isMobile),
                ),
                _buildProductsGrid(isMobile),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
    );
  }

  // ── Sliver AppBar with banner ──────────────────────────────────────────────

  Widget _buildSliverAppBar(
      String storeName, String logoUrl, String bannerUrl, bool isMobile) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: isMobile ? 230.0 : 290.0,
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 56),
        title: Text(
          storeName.toUpperCase(),
          style: GoogleFonts.commissioner(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner background
            if (bannerUrl.isNotEmpty)
              Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultBanner(),
              )
            else
              _defaultBanner(),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x440A0A0A),
                    Color(0xDD0A0A0A),
                  ],
                ),
              ),
            ),
            // Logo + store name overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: _buildBannerOverlay(storeName, logoUrl, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF2A2A2A)],
        ),
      ),
    );
  }

  Widget _buildBannerOverlay(String name, String logoUrl, bool isMobile) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'S';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: logoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w300)),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.toUpperCase(),
                        style: GoogleFonts.commissioner(
                          fontSize: isMobile ? 15 : 19,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_all.length} ${_all.length == 1 ? 'product' : 'products'} available',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card (description + stats + follow) ───────────────────────────────

  Widget _buildInfoCard(String description, bool isMobile) {
    final hPad = isMobile ? 12.0 : 24.0;
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 15, color: Color(0xFF888888)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      description,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF555555),
                          height: 1.6),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Stats row
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, description.isNotEmpty ? 16 : 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                      value: '${_all.length}', label: 'PRODUCTS'),
                ),
                Container(
                    width: 1, height: 36, color: const Color(0xFFEEEEEE)),
                Expanded(
                  child: _StatTile(
                    value: _categories.length > 1
                        ? '${_categories.length - 1}'
                        : '—',
                    label: 'CATEGORIES',
                  ),
                ),
                Container(
                    width: 1, height: 36, color: const Color(0xFFEEEEEE)),
                const Expanded(
                  child: _StatTile(value: '4.8 ★', label: 'RATING'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: _FollowButton(),
          ),
        ],
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────

  Widget _buildCategoryChips(bool isMobile) {
    final hPad = isMobile ? 12.0 : 24.0;
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BROWSE BY CATEGORY',
            style: GoogleFonts.commissioner(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 0,
            runSpacing: 8,
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.toUpperCase()),
                  selected: selected,
                  onSelected: (_) => _filterCategory(cat),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF0A0A0A),
                  showCheckmark: false,
                  labelStyle: GoogleFonts.commissioner(
                    color: selected ? Colors.white : const Color(0xFF0A0A0A),
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Color(0xFF0A0A0A), width: 1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Products header ────────────────────────────────────────────────────────

  Widget _buildProductsHeader(bool isMobile) {
    final hPad = isMobile ? 20.0 : 32.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedCategory == 'All'
                ? 'ALL PRODUCTS'
                : _selectedCategory.toUpperCase(),
            style: GoogleFonts.commissioner(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          Text(
            '${_filtered.length} items',
            style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  // ── Products grid ──────────────────────────────────────────────────────────

  Widget _buildProductsGrid(bool isMobile) {
    if (_filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 40, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                Text(
                  'No products in this category',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cols = isMobile ? 2 : 4;
    final hPad = isMobile ? 12.0 : 24.0;
    final gap = isMobile ? 8.0 : 16.0;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _StoreProductCard(
            product: _filtered[i],
            isMobile: isMobile,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: _filtered[i]),
            )),
            onAddToCart: () => _addToCart(_filtered[i]),
          ),
          childCount: _filtered.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: isMobile ? 0.62 : 0.68,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Store product card
// ─────────────────────────────────────────────────────────────────────────────

class _StoreProductCard extends StatefulWidget {
  final Product product;
  final bool isMobile;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _StoreProductCard({
    required this.product,
    required this.isMobile,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  State<_StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<_StoreProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final imgH = widget.isMobile ? 120.0 : 170.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: imgH,
                      child: widget.product.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  height: imgH,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        color: Color(0xFF0A0A0A)),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => SizedBox(
                                height: imgH,
                                child: const Center(
                                  child: Icon(Icons.image_outlined,
                                      size: 28, color: Color(0xFFCCCCCC)),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: imgH,
                              child: const Center(
                                child: Icon(Icons.image_outlined,
                                    size: 28, color: Color(0xFFCCCCCC)),
                              ),
                            ),
                    ),
                    // Hover overlay
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: imgH,
                      width: double.infinity,
                      color: _hovered
                          ? const Color(0xFF0A0A0A).withValues(alpha: 0.05)
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: EdgeInsets.all(widget.isMobile ? 10.0 : 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.category.toUpperCase(),
                      style: GoogleFonts.commissioner(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAAAAAA),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: widget.isMobile ? 30 : 36,
                      child: Text(
                        widget.product.name,
                        style: GoogleFonts.inter(
                          fontSize: widget.isMobile ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A0A0A),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${widget.product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: widget.isMobile ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A0A0A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              vertical: widget.isMobile ? 7 : 9),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'ADD TO CART',
                          style: GoogleFonts.commissioner(
                            fontSize: widget.isMobile ? 8 : 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.commissioner(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.commissioner(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF999999),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatefulWidget {
  const _FollowButton();

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: _following
          ? OutlinedButton.icon(
              onPressed: () => setState(() => _following = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF888888),
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              icon: const Icon(Icons.check, size: 14),
              label: Text(
                'FOLLOWING',
                style: GoogleFonts.commissioner(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => setState(() => _following = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A0A0A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                'FOLLOW STORE',
                style: GoogleFonts.commissioner(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
              ),
            ),
    );
  }
}
