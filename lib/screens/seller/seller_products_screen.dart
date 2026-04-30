import 'package:flutter/material.dart';
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.white,
        title: const Text(
          'DELETE PRODUCT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Color(0xFF0A0A0A),
          ),
        ),
        content: Text(
          'Remove "${product.name}" from your listings?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Color(0xFF0A0A0A),
                  fontWeight: FontWeight.w700),
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0A0A0A), size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MY PRODUCTS',
          style: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _openAdd,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: const Color(0xFF0A0A0A),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                '+ ADD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 48,
                      vertical: isMobile ? 20 : 32,
                    ),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _productCard(_products[i], isMobile),
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 20),
          const Text(
            'NO PRODUCTS YET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFAAAAAA),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first product listing',
            style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: _openAdd,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0A0A0A)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            child: const Text(
              'ADD PRODUCT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A),
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(SellerProduct product, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: isMobile ? 64 : 80,
            height: isMobile ? 64 : 80,
            color: const Color(0xFFF2F2F2),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      color: Color(0xFFCCCCCC),
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: Color(0xFFCCCCCC),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF999999),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₱${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      color: product.stock > 0
                          ? const Color(0xFFF0F0F0)
                          : const Color(0xFF0A0A0A),
                      child: Text(
                        product.stock > 0
                            ? 'STOCK: ${product.stock}'
                            : 'OUT OF STOCK',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: product.stock > 0
                              ? const Color(0xFF555555)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () => _openEdit(product),
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF555555)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 12),
              IconButton(
                onPressed: () => _delete(product),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
