import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  String? _selectedSize;
  String? _selectedColor;
  late CartService cartService;

  // Sample sizes and colors — in production these come from product_variants
  static const _sizes  = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _colors = [
    {'label': 'Black',  'hex': 0xFF0A0A0A},
    {'label': 'White',  'hex': 0xFFF5F5F5},
    {'label': 'Navy',   'hex': 0xFF1E2D55},
    {'label': 'Khaki',  'hex': 0xFFB5A898},
    {'label': 'Olive',  'hex': 0xFF6B6B47},
  ];

  @override
  void initState() {
    super.initState();
    cartService = CartService();
  }

  void _addToCart() {
    for (int i = 0; i < quantity; i++) {
      cartService.addToCart(widget.product);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 14),
            const SizedBox(width: 10),
            Text(
              '${widget.product.name} added to cart',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _buyNow() {
    for (int i = 0; i < quantity; i++) {
      cartService.addToCart(widget.product);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0A0A0A), size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'VARÓN',
          style: GoogleFonts.commissioner(
            color: const Color(0xFF0A0A0A),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 6,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ───────────────────────────────────────────────
            _ProductImageGallery(
              imageUrl: widget.product.imageUrl,
              isMobile: isMobile,
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 48,
                vertical: isMobile ? 28 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label
                  Text(
                    widget.product.category.toUpperCase(),
                    style: GoogleFonts.commissioner(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF999999),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Product name — Playfair Display
                  Text(
                    widget.product.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0A0A0A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Star rating placeholder
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < 4 ? Icons.star : Icons.star_half,
                        size: 14,
                        color: const Color(0xFF0A0A0A),
                      )),
                      const SizedBox(width: 8),
                      Text(
                        '4.5 (24 reviews)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    '₱${widget.product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    widget.product.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF555555),
                      height: 1.75,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Color selection ───────────────────────────────────────
                  _SectionLabel(label: 'COLOR', trailing: _selectedColor),
                  const SizedBox(height: 14),
                  Row(
                    children: _colors.map((c) {
                      final label = c['label'] as String;
                      final hex   = c['hex'] as int;
                      final selected = _selectedColor == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedColor = label),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(hex),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF0A0A0A)
                                        : const Color(0xFFDDDDDD),
                                    width: selected ? 2.5 : 1,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF0A0A0A)
                                                .withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: selected
                                    ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: hex == 0xFFF5F5F5
                                            ? const Color(0xFF0A0A0A)
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Size selection ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel(label: 'SIZE', trailing: _selectedSize),
                      GestureDetector(
                        onTap: () => _showSizeGuide(context),
                        child: Text(
                          'SIZE GUIDE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: const Color(0xFF888888),
                            letterSpacing: 1.5,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sizes.map((size) {
                      final selected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0A0A0A)
                                : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF0A0A0A)
                                  : const Color(0xFFDDDDDD),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              size,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF0A0A0A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Quantity ──────────────────────────────────────────────
                  const _SectionLabel(label: 'QUANTITY'),
                  const SizedBox(height: 14),
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFDDDDDD), width: 1),
                    ),
                    child: Row(
                      children: [
                        _qtyButton(
                          Icons.remove,
                          quantity > 1 ? () => setState(() => quantity--) : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$quantity',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                        ),
                        _qtyButton(Icons.add, () => setState(() => quantity++)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Action buttons ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _addToCart,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF0A0A0A), width: 1),
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 15 : 17),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            'ADD TO CART',
                            style: GoogleFonts.commissioner(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0A0A),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _buyNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 15 : 17),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            'BUY NOW',
                            style: GoogleFonts.commissioner(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── Product details accordion ──────────────────────────────
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  const _DetailRow(label: 'MATERIAL', value: '100% Premium Cotton'),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  const _DetailRow(label: 'CARE',     value: 'Machine wash cold, tumble dry low'),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  const _DetailRow(label: 'FIT',      value: 'Regular fit — model wears size M'),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  const SizedBox(height: 40),

                  // ── Reviews section ────────────────────────────────────────
                  Text(
                    'CUSTOMER REVIEWS',
                    style: GoogleFonts.commissioner(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0A0A),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(width: 28, height: 1, color: const Color(0xFF0A0A0A)),
                  const SizedBox(height: 24),
                  ..._buildSampleReviews(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSizeGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIZE GUIDE',
              style: GoogleFonts.commissioner(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: const Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            _sizeRow('SIZE', 'CHEST', 'WAIST', 'HIP', isHeader: true),
            _sizeRow('XS',   '32–34"', '26–28"', '34–36"'),
            _sizeRow('S',    '34–36"', '28–30"', '36–38"'),
            _sizeRow('M',    '37–39"', '31–33"', '39–41"'),
            _sizeRow('L',    '40–42"', '34–36"', '42–44"'),
            _sizeRow('XL',   '43–45"', '37–39"', '45–47"'),
            _sizeRow('XXL',  '46–48"', '40–42"', '48–50"'),
          ],
        ),
      ),
    );
  }

  Widget _sizeRow(String s, String c, String w, String h,
      {bool isHeader = false}) {
    final style = isHeader
        ? GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 1.5,
          )
        : GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0A0A0A));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(s, style: style)),
          Expanded(child: Text(c, style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(w, style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(h, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  List<Widget> _buildSampleReviews() {
    final reviews = [
      {'author': 'J. Santos',    'rating': 5, 'text': 'Perfect fit and exceptional quality. The fabric feels premium and the stitching is flawless.'},
      {'author': 'M. Reyes',     'rating': 4, 'text': 'Great minimalist piece. Runs slightly large — suggest sizing down for a fitted look.'},
      {'author': 'A. Dela Cruz', 'rating': 5, 'text': 'Exactly as described. Fast delivery and well packaged. Will order again.'},
    ];
    return reviews.map((r) => _ReviewCard(
      author: r['author'] as String,
      rating: r['rating'] as int,
      text:   r['text'] as String,
    )).toList();
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          size: 14,
          color: onTap != null
              ? const Color(0xFF0A0A0A)
              : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? trailing;

  const _SectionLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 2,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            '— $trailing',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: const Color(0xFF0A0A0A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatefulWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  State<_DetailRow> createState() => _DetailRowState();
}

class _DetailRowState extends State<_DetailRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.commissioner(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                Icon(
                  _expanded ? Icons.remove : Icons.add,
                  size: 14,
                  color: const Color(0xFF0A0A0A),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF555555),
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String author;
  final int rating;
  final String text;

  const _ReviewCard({
    required this.author,
    required this.rating,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  size: 13,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                author,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF555555),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image gallery with thumbnail strip
// ─────────────────────────────────────────────────────────────────────────────

class _ProductImageGallery extends StatefulWidget {
  final String imageUrl;
  final bool isMobile;

  const _ProductImageGallery({
    required this.imageUrl,
    required this.isMobile,
  });

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Simulate multiple angles from the same image
    final images = List.generate(4, (_) => widget.imageUrl);
    final mainH  = widget.isMobile ? 340.0 : 500.0;
    final thumbH = widget.isMobile ? 56.0  : 72.0;

    return Column(
      children: [
        // Main image
        Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: mainH,
              child: _NetImage(url: images[_activeIndex], fit: BoxFit.cover),
            ),
            // Subtle gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Image counter
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.white.withValues(alpha: 0.85),
                child: Text(
                  '${_activeIndex + 1} / ${images.length}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF0A0A0A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Thumbnail strip
        Container(
          color: const Color(0xFFF6F6F6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: List.generate(images.length, (i) {
              final active = _activeIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _activeIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: thumbH,
                  height: thumbH,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFDDDDDD),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: _NetImage(url: images[i], fit: BoxFit.cover),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _NetImage({required this.url, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFCCCCCC)),
      );
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF0A0A0A),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}
