import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  final String? category;

  const ShopScreen({super.key, this.category});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late CartService cartService;
  String selectedCategory = 'All';

  final products = [
    Product(
      id: 1,
      name: 'Classic White Shirt',
      price: 1299.00,
      category: 'Shirts',
      description: 'Premium cotton blend shirt with elegant minimalist design',
      imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop',
    ),
    Product(
      id: 2,
      name: 'Slim Fit Black Pants',
      price: 1899.00,
      category: 'Pants',
      description: 'Sophisticated tailored trousers for refined style',
      imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop',
    ),
    Product(
      id: 3,
      name: 'Premium Cotton T-Shirt',
      price: 599.00,
      category: 'T-Shirts',
      description: 'Comfortable everyday essential in pure cotton',
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop',
    ),
    Product(
      id: 4,
      name: 'Leather Minimalist Belt',
      price: 899.00,
      category: 'Accessories',
      description: 'Timeless leather belt with subtle design',
      imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop',
    ),
    Product(
      id: 5,
      name: 'Navy Blue Polo',
      price: 999.00,
      category: 'Shirts',
      description: 'Versatile classic polo for any occasion',
      imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop&auto=format&crop=faces',
    ),
    Product(
      id: 6,
      name: 'Charcoal Grey Trousers',
      price: 1699.00,
      category: 'Pants',
      description: 'Professional style trousers for work or casual',
      imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop&auto=format&crop=faces',
    ),
    Product(
      id: 7,
      name: 'Organic Cotton Tee',
      price: 699.00,
      category: 'T-Shirts',
      description: 'Sustainable fashion choice in organic material',
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop&auto=format&crop=faces',
    ),
    Product(
      id: 8,
      name: 'Minimalist Wallet',
      price: 499.00,
      category: 'Accessories',
      description: 'Ultra-thin design perfect for everyday carry',
      imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop&auto=format&crop=faces',
    ),
  ];

  @override
  void initState() {
    super.initState();
    cartService = CartService();
    if (widget.category != null) {
      selectedCategory = widget.category!;
    }
  }

  List<Product> getFilteredProducts() {
    if (selectedCategory == 'All') {
      return products;
    }
    return products.where((p) => p.category == selectedCategory).toList();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _addToCart(Product product) {
    cartService.addToCart(product);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    ).then((_) => setState(() {}));
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final filteredProducts = getFilteredProducts();
    final cartCount = cartService.getCartCount();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VARÓN',
              style: TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 6,
              ),
            ),
            if (selectedCategory != 'All')
              Text(
                selectedCategory.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.black),
                    onPressed: _openCart,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 40,
              vertical: isMobile ? 12 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Filter
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._buildCategoryButtons(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                else
                  Row(
                    children: _buildCategoryButtons(),
                  ),

                SizedBox(height: isMobile ? 20 : 32),

                Text(
                  (selectedCategory == 'All'
                          ? 'All Products'
                          : selectedCategory)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 28, height: 1, color: const Color(0xFF0A0A0A)),
                const SizedBox(height: 10),
                Text(
                  '${filteredProducts.length} items',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 32),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = isMobile ? 2 : 4;
                    final itemWidth = (screenWidth - (isMobile ? 24 : 64)) / crossAxisCount;
                    final itemHeight = isMobile ? itemWidth * 1.4 : itemWidth * 1.3;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: isMobile ? 8 : 16,
                        mainAxisSpacing: isMobile ? 12 : 24,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(filteredProducts[index], isMobile);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryButtons() {
    final categories = ['All', 'Shirts', 'Pants', 'T-Shirts', 'Accessories'];
    return categories.map((category) {
      final isSelected = selectedCategory == category;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(category.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => selectedCategory = category);
          },
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF0A0A0A),
          showCheckmark: false,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
            fontWeight: FontWeight.w600,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0xFF0A0A0A), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
    }).toList();
  }

  Widget _buildProductCard(Product product, bool isMobile) {
    final imageHeight = isMobile ? 120.0 : 180.0;
    final fontSize = isMobile ? 11.0 : 13.0;
    final priceFontSize = isMobile ? 12.0 : 14.0;
    final buttonFontSize = isMobile ? 9.0 : 10.0;
    final verticalPadding = isMobile ? 6.0 : 8.0;

    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Flexible(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
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
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            height: imageHeight,
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: isMobile ? 30 : 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      )
                    : SizedBox(
                        height: imageHeight,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: isMobile ? 30 : 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 6 : 10),
          SizedBox(
            height: isMobile ? 24 : 32,
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            product.description,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            '₱${product.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: priceFontSize,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openProductDetail(product),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0A0A0A), width: 1),
                    padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    minimumSize: Size(0, isMobile ? 28 : 36),
                  ),
                  child: Text(
                    'VIEW',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0A0A),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0A0A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    minimumSize: Size(0, isMobile ? 28 : 36),
                  ),
                  child: Text(
                    'ADD',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
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
}