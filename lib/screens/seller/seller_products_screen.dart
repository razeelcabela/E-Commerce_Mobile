import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/seller_product.dart';
import '../../services/seller_auth_service.dart';
import '../../services/seller_product_service.dart';
import 'seller_add_product_screen.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  List<SellerProduct> _products = [];
  bool _loading = true;
  String? _email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await SellerAuthService.getCurrentSellerEmail();
    if (email == null) return;
    final products = await SellerProductService.getByEmail(email);
    if (!mounted) return;
    setState(() {
      _email = email;
      _products = products;
      _loading = false;
    });
  }

  Future<void> _delete(SellerProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Remove product?',
          style: GoogleFonts.commissioner(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        content: Text(
          'Delete "${product.name}" from your listings?',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SellerProductService.delete(product.id);
      _load();
    }
  }

  void _openAdd() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => SellerAddProductScreen(sellerEmail: _email ?? ''),
        ))
        .then((_) => _load());
  }

  void _openEdit(SellerProduct product) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => SellerAddProductScreen(
            sellerEmail: _email ?? '',
            existing: product,
          ),
        ))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'MY PRODUCTS',
          style: GoogleFonts.commissioner(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _openAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'ADD',
                      style: GoogleFonts.commissioner(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0A0A0A),
              ),
            )
          : _products.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF0A0A0A),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _productCard(_products[i]),
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 36, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 20),
          Text(
            'NO PRODUCTS YET',
            style: GoogleFonts.commissioner(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFAAAAAA),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first product listing',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _openAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'ADD PRODUCT',
              style: GoogleFonts.commissioner(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(SellerProduct product) {
    final inStock = product.stock > 0;
    final status = product.approvalStatus;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'LIVE';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'REJECTED';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'UNDER REVIEW';
        statusIcon = Icons.pending_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == 'rejected'
            ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3))
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF2F2F2),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_outlined,
                            color: Color(0xFFCCCCCC),
                            size: 26,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Color(0xFFCCCCCC),
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A0A0A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.category.toUpperCase(),
                      style: GoogleFonts.commissioner(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF999999),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₱${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.commissioner(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: inStock
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            inStock
                                ? 'Stock: ${product.stock}'
                                : 'Out of stock',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: inStock
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (status != 'pending')
                    _iconBtn(
                      Icons.edit_outlined,
                      const Color(0xFF555555),
                      () => _openEdit(product),
                    ),
                  if (status != 'pending') const SizedBox(height: 8),
                  _iconBtn(
                    Icons.delete_outline,
                    const Color(0xFFEF4444),
                    () => _delete(product),
                  ),
                ],
              ),
            ],
          ),
          // Status banner
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: GoogleFonts.commissioner(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 1.2,
                  ),
                ),
                if (status == 'rejected' &&
                    product.rejectionReason != null &&
                    product.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '· ${product.rejectionReason}',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: statusColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
