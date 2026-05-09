# Buyer Marketplace Real-Time Integration

This guide shows how to integrate real-time product updates in the buyer-facing marketplace so customers see newly added products instantly.

---

## Part 1: Real-Time Subscriptions

### Enable Real-Time in ProductService

Add this to `lib/services/product_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  static final _client = Supabase.instance.client;
  
  // Real-time channel reference
  static RealtimeChannel? _productsChannel;
  static RealtimeChannel? _imagesChannel;

  /// Subscribe to new and updated products
  /// Calls [onUpdate] whenever a product changes
  static void subscribeToProductUpdates(VoidCallback onUpdate) {
    // Only subscribe once
    if (_productsChannel != null) return;

    _productsChannel = _client.channel('products_realtime');

    // Listen for NEW approved products
    _productsChannel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'products',
            filter: 'approval_status=eq.approved,is_active=eq.true,archive_status=eq.active',
          ),
          (payload, [_]) {
            debugPrint('🆕 New product added: ${payload["new"]["name"]}');
            onUpdate();
          },
        )
        // Listen for UPDATED products (stock changes, etc.)
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'products',
            filter: 'approval_status=eq.approved,is_active=eq.true,archive_status=eq.active',
          ),
          (payload, [_]) {
            final productName = payload["new"]["name"];
            final oldStock = payload["old"]["stock"];
            final newStock = payload["new"]["stock"];
            debugPrint('📝 Product updated: $productName (stock: $oldStock → $newStock)');
            onUpdate();
          },
        )
        .subscribe((status, err) {
          if (status == RealtimeSubscriptionStatus.subscribed) {
            debugPrint('✅ Real-time products subscription active');
          } else if (status == RealtimeSubscriptionStatus.closed) {
            debugPrint('⚠️ Real-time products subscription closed');
          }
          if (err != null) {
            debugPrint('❌ Real-time error: $err');
          }
        });
  }

  /// Subscribe to product image changes
  static void subscribeToImageUpdates(VoidCallback onUpdate) {
    if (_imagesChannel != null) return;

    _imagesChannel = _client.channel('images_realtime');

    _imagesChannel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'product_images',
          ),
          (payload, [_]) {
            debugPrint('🖼️ Product image changed');
            onUpdate();
          },
        )
        .subscribe((status, err) {
          if (status == RealtimeSubscriptionStatus.subscribed) {
            debugPrint('✅ Real-time images subscription active');
          }
        });
  }

  /// Unsubscribe from real-time updates
  static Future<void> unsubscribeFromProductUpdates() async {
    if (_productsChannel != null) {
      await _productsChannel!.unsubscribe();
      _productsChannel = null;
    }
  }

  static Future<void> unsubscribeFromImageUpdates() async {
    if (_imagesChannel != null) {
      await _imagesChannel!.unsubscribe();
      _imagesChannel = null;
    }
  }
}
```

---

## Part 2: Product List Screen with Real-Time

### Buyer Product List Screen

Create or update your product listing screen:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class BuyerProductListScreen extends StatefulWidget {
  const BuyerProductListScreen({super.key});

  @override
  State<BuyerProductListScreen> createState() => _BuyerProductListScreenState();
}

class _BuyerProductListScreenState extends State<BuyerProductListScreen> {
  List<Product> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _loading = true;
  bool _isRealTimeActive = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _enableRealTime();
  }

  Future<void> _loadInitialData() async {
    try {
      final products = await ProductService.getAllProducts();
      final categories = await ProductService.getCategories();

      if (!mounted) return;

      setState(() {
        _products = products;
        _categories = ['All', ...categories];
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to load products');
      }
    }
  }

  void _enableRealTime() {
    // Subscribe to real-time updates
    ProductService.subscribeToProductUpdates(() async {
      debugPrint('🔄 Real-time update triggered, reloading products...');
      await _loadInitialData();
    });

    if (mounted) {
      setState(() => _isRealTimeActive = true);
    }
  }

  @override
  void dispose() {
    // Important: Unsubscribe when leaving screen
    ProductService.unsubscribeFromProductUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Marketplace',
          style: GoogleFonts.commissioner(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Real-time status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRealTimeActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRealTimeActive ? 'Live' : 'Offline',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _isRealTimeActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category filter
                _buildCategoryFilter(),
                
                // Product grid
                Expanded(
                  child: _products.isEmpty
                      ? _buildEmptyState()
                      : _buildProductGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _categories
            .map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProductGrid() {
    final filtered = _selectedCategory == 'All'
        ? _products
        : _products
            .where((p) => p.category == _selectedCategory)
            .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildProductCard(filtered[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: product.imageUrl.isEmpty
                    ? const Icon(Icons.image_not_supported)
                    : Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.error_outline),
                      ),
              ),
            ),
            
            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Product detail screen
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final product = await ProductService.getProductById(widget.product.id);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product ?? widget.product;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: double.infinity,
              height: 300,
              color: const Color(0xFFE5E5E5),
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.image_not_supported)
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
            
            // Product details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.commissioner(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.commissioner(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: GoogleFonts.commissioner(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Add to Cart',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    );
  }

  void _addToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_quantity}x ${_product?.name ?? widget.product.name} to cart'),
      ),
    );
    Navigator.of(context).pop();
  }
}
```

---

## Part 3: Real-Time Notifications

### Show Toast When New Products Arrive

```dart
class ProductListScreen extends StatefulWidget {
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  void initState() {
    super.initState();
    ProductService.subscribeToProductUpdates(() {
      _showNewProductNotification();
      _reloadProducts();
    });
  }

  void _showNewProductNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.new_releases, color: Colors.white),
            const SizedBox(width: 8),
            const Text('New products added!'),
            const Spacer(),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

---

## Part 4: Performance Optimization

### Debounce Updates to Avoid Flickering

```dart
class ProductListScreen extends StatefulWidget {
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Timer? _updateTimer;
  bool _pendingUpdate = false;

  @override
  void initState() {
    super.initState();
    ProductService.subscribeToProductUpdates(_onProductUpdate);
  }

  void _onProductUpdate() {
    // Mark that update is needed
    _pendingUpdate = true;

    // Debounce: wait 1 second before actually reloading
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(seconds: 1), () {
      if (_pendingUpdate) {
        _reloadProducts();
        _pendingUpdate = false;
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    ProductService.unsubscribeFromProductUpdates();
    super.dispose();
  }
}
```

---

## Part 5: Filtering & Sorting

### Advanced Product Filtering

```dart
class ProductListScreen extends StatefulWidget {
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _allProducts = [];
  String _sortBy = 'newest'; // newest, price_low, price_high, popular
  double _minPrice = 0;
  double _maxPrice = 100000;

  List<Product> get _filteredProducts {
    var filtered = _allProducts;

    // Apply price filter
    filtered = filtered
        .where((p) => p.price >= _minPrice && p.price <= _maxPrice)
        .toList();

    // Apply sort
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
        // Sort by popularity (would need additional field)
        break;
      case 'newest':
      default:
        // Already sorted by creation time from DB
        break;
    }

    return filtered;
  }

  Widget _buildSortOptions() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _sortBy = value);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'newest', child: Text('Newest First')),
        const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
        const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
      ],
      child: const Chip(label: Text('Sort')),
    );
  }
}
```

---

## Part 6: Testing Checklist

- [ ] Real-time subscription starts on screen init
- [ ] New products appear automatically without manual refresh
- [ ] Stock updates reflect in real-time
- [ ] Archived/inactive products hidden from buyers
- [ ] Category filtering works
- [ ] Price range filtering works
- [ ] Sorting options work
- [ ] "Live" indicator shows connection status
- [ ] Unsubscribe called on screen dispose
- [ ] No duplicate products shown
- [ ] Images load properly
- [ ] Empty state shown when no products
- [ ] Error handling works (network down, etc.)

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Products not updating in real-time | Not subscribed | Call `subscribeToProductUpdates()` in `initState()` |
| Duplicate products showing | Multiple subscriptions | Check for multiple `initState()` calls |
| Connection shows "Offline" | WebSocket issue | Check network, restart app |
| Old products still showing | Filter not working | Verify RLS filters on products table |
| Updates very slow | Debouncing too high | Reduce timer duration from 1s to 500ms |

---

## Summary

The buyer marketplace now:
- ✅ Shows approved products instantly
- ✅ Updates in real-time when sellers add/modify products
- ✅ Hides archived and inactive products automatically
- ✅ Supports filtering by category and price
- ✅ Shows connection status
- ✅ Optimized to avoid excessive UI updates

Sellers can manage inventory and see immediate impact on the marketplace!
