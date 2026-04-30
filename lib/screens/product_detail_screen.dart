import 'package:flutter/material.dart';
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
  late CartService cartService;

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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0A0A0A), size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'VARÓN',
          style: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 6,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: double.infinity,
              height: isMobile ? 320 : 480,
              color: const Color(0xFFF2F2F2),
              child: widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            strokeWidth: 1.5,
                            color: const Color(0xFF0A0A0A),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.image_outlined,
                            size: isMobile ? 56 : 80,
                            color: const Color(0xFFCCCCCC)),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_outlined,
                          size: isMobile ? 56 : 80,
                          color: const Color(0xFFCCCCCC)),
                    ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 48,
                vertical: isMobile ? 28 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    widget.product.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Product name
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF0A0A0A),
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    '₱${widget.product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A0A0A),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.7,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: isMobile ? 28 : 36),

                  // Quantity label
                  const Text(
                    'QUANTITY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF888888),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity selector
                  Container(
                    width: 120,
                    decoration: const BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFFDDDDDD), width: 1),
                      ),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                        ),
                        _qtyButton(
                            Icons.add, () => setState(() => quantity++)),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 28 : 36),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _addToCart,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF0A0A0A), width: 1),
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text(
                            'ADD TO CART',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A0A0A),
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
                                vertical: isMobile ? 14 : 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text(
                            'BUY NOW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
