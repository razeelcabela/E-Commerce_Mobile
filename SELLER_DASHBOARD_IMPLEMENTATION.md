# Seller Dashboard Implementation Guide

This guide walks you through implementing the complete seller dashboard system with real-time product management, inventory tracking, and marketplace integration.

---

## Part 1: Database Setup

### Step 1: Apply the Schema
1. Open Supabase Dashboard → SQL Editor
2. Copy-paste the entire contents of `SELLER_DASHBOARD_SCHEMA.sql`
3. Execute the SQL

**Verification:**
```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
```

Expected tables: `sellers`, `categories`, `products`, `product_images`, `inventory_transactions`, `orders`, `order_items`, `reviews`, `carts`, `cart_items`, `seller_daily_stats`

### Step 2: Enable Row Level Security (RLS)
1. Copy-paste `SELLER_DASHBOARD_RLS_POLICIES.sql` into SQL Editor
2. Execute the entire file

**Note:** If you encounter any errors, see `RLS_POLICIES_CORRECTED.md` for troubleshooting and step-by-step guidance.

**Verification:**
```sql
-- Check RLS is enabled on products table
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'products';
-- Should return: "products" | true
```

### Step 3: Create Storage Bucket
1. Go to Supabase Dashboard → Storage
2. Create a new bucket named `products`
3. Make it public (uncheck "Use private URLs")
4. Apply storage policies (use SQL Editor):

```sql
-- Public can view product images
CREATE POLICY "public_product_images_select"
ON storage.objects FOR SELECT
USING (bucket_id = 'products');

-- Authenticated users can upload
CREATE POLICY "auth_product_images_insert"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'products' AND auth.role() = 'authenticated');

-- Users can delete their own images
CREATE POLICY "auth_product_images_delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'products' AND auth.uid()::text = owner);
```

---

## Part 2: Flutter Model Updates

### Already Created:
- ✅ `lib/models/seller_dashboard_stats.dart` - Dashboard metrics
- ✅ `lib/widgets/product_status_badge.dart` - Status badges

### Enhance Existing Models:

**Update `lib/models/product.dart`:**
```dart
// Add these fields to track status
class Product {
  final dynamic id;
  final int? sellerId;
  final String name;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String approvalStatus;  // NEW
  final bool isActive;           // NEW
  final String archiveStatus;    // NEW
  final int stock;               // NEW
  // ... existing fields ...
}
```

---

## Part 3: Service Layer Enhancements

### Enhanced `lib/services/seller_product_service.dart`:

**Already Added Methods:**
- `updateStock(productId, newStock)` - Update stock quantity
- `adjustStock(productId, delta, reason)` - Increment/decrement with logging
- `getByStatus(status)` - Get products by approval status
- `getLowStockProducts(threshold)` - Get low-stock alerts
- `toggleActive(productId, isActive)` - Enable/disable product
- `setArchiveStatus(productId, status)` - Archive/restore
- `getDashboardStats()` - Fetch dashboard metrics
- `uploadMultipleImages()` - Upload multiple images at once

**Usage Examples:**

```dart
// Get dashboard stats
final stats = await SellerProductService.getDashboardStats();
print('Active products: ${stats.activeProducts}');
print('Revenue: ₹${stats.totalRevenue}');

// Update stock
await SellerProductService.updateStock(productId, 50);

// Get low stock products
final lowStock = await SellerProductService.getLowStockProducts(threshold: 10);

// Upload multiple images
await SellerProductService.uploadMultipleImages(productId, [
  {'bytes': imageBytes1, 'ext': 'jpg'},
  {'bytes': imageBytes2, 'ext': 'jpg'},
]);
```

---

## Part 4: UI Screens Implementation

### Screen 1: Seller Dashboard
**Location:** `lib/screens/seller/seller_dashboard_screen.dart`

**Features:**
- Overview metrics (products, orders, revenue)
- Status alerts (pending approval, low stock)
- Quick action buttons
- Low stock product list
- Link to detailed product management

**Integration:**
```dart
// Use in your main seller navigation
SellerDashboardScreen(),

// Refresh on return from product management
.then((_) => _load())
```

### Screen 2: Enhanced Add Product Form
**Location:** `lib/screens/seller/seller_add_product_screen.dart`

**Current Features:**
- Single image upload
- Product details (name, description, price, stock)
- Category selection

**To Add:**
```dart
// Multiple image support
final List<Uint8List> _imageBytes = [];
final List<String> _imageExts = [];

// Image picker for multiple files
Future<void> _pickMultipleImages() async {
  final picker = ImagePicker();
  final files = await picker.pickMultiImage(imageQuality: 80);
  
  for (final file in files) {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    setState(() {
      _imageBytes.add(bytes);
      _imageExts.add(ext);
    });
  }
}

// Upload all images after product creation
if (productId != null && _imageBytes.isNotEmpty) {
  final uploadCount = await SellerProductService.uploadMultipleImages(
    productId,
    List.generate(
      _imageBytes.length,
      (i) => {'bytes': _imageBytes[i], 'ext': _imageExts[i]},
    ),
  );
  debugPrint('✅ Uploaded $uploadCount images');
}
```

### Screen 3: Product List with Filters
**Location:** `lib/screens/seller/seller_products_screen.dart`

**Enhancements:**
```dart
// Add filter tabs
List<Widget> _buildFilterTabs() {
  return [
    _FilterTab(label: 'All', onTap: () => _filter = null),
    _FilterTab(label: 'Active', onTap: () => _filter = 'active'),
    _FilterTab(label: 'Pending', onTap: () => _filter = 'pending'),
    _FilterTab(label: 'Low Stock', onTap: () => _filter = 'low_stock'),
    _FilterTab(label: 'Archived', onTap: () => _filter = 'archived'),
  ];
}

// Filter products
List<SellerProduct> _getFilteredProducts() {
  final products = _allProducts;
  
  if (_filter == null) return products;
  if (_filter == 'active') {
    return products.where((p) => p.isActive && p.approvalStatus == 'approved').toList();
  }
  // ... other filters
  
  return products;
}
```

---

## Part 5: Real-Time Updates for Buyers

### Enable Real-Time for Marketplace
**Location:** `lib/services/product_service.dart`

```dart
// Subscribe to product changes
static RealtimeChannel? _productsChannel;

static void subscribeToProductUpdates(VoidCallback onUpdate) {
  _productsChannel = _client.channel('products');
  
  _productsChannel!
    .on(RealtimeListenTypes.postgresChanges, ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'products',
      filter: 'approval_status=eq.approved',
    ), (payload, [_]) {
      debugPrint('🆕 New product added: ${payload['new']['name']}');
      onUpdate();
    })
    .on(RealtimeListenTypes.postgresChanges, ChannelFilter(
      event: 'UPDATE',
      schema: 'public',
      table: 'products',
    ), (payload, [_]) {
      debugPrint('📝 Product updated: ${payload['new']['name']}');
      onUpdate();
    })
    .subscribe();
}

static void unsubscribeFromProductUpdates() {
  _productsChannel?.unsubscribe();
  _productsChannel = null;
}
```

**Usage in Product Listing:**
```dart
@override
void initState() {
  super.initState();
  _loadProducts();
  ProductService.subscribeToProductUpdates(_reloadProducts);
}

@override
void dispose() {
  ProductService.unsubscribeFromProductUpdates();
  super.dispose();
}

Future<void> _reloadProducts() async {
  final products = await ProductService.getAllProducts();
  if (!mounted) return;
  setState(() => _products = products);
}
```

---

## Part 6: Seller Onboarding Flow

### Create Seller Profile on First Login

**In `seller_auth_service.dart`:**
```dart
static Future<bool> createSellerProfile({
  required String storeName,
  required String businessName,
  String? description,
  String? phone,
}) async {
  final userId = _db.auth.currentUser?.id;
  if (userId == null) return false;
  
  try {
    // Get seller_id from linked seller profile
    final sellerId = await getCurrentSellerId();
    if (sellerId == null) {
      // Create new seller profile
      final result = await _db.from('sellers').insert({
        'user_id': userId,
        'store_name': storeName,
        'business_name': businessName,
        'description': description,
        'phone': phone,
        'status': 'active',
      }).select('id').single();
      
      return result['id'] != null;
    }
    return true;
  } catch (e) {
    debugPrint('❌ Error creating seller profile: $e');
    return false;
  }
}
```

---

## Part 7: Admin Approval Workflow

### Approve/Reject Products

**In `lib/services/admin_service.dart`:**
```dart
static Future<bool> approveProduct(int productId) async {
  try {
    await _client.from('products').update({
      'approval_status': 'approved',
      'is_active': 1,
    }).eq('id', productId);
    
    // Notify seller via email/notification
    await _notifySeller(productId, 'Your product was approved!');
    return true;
  } catch (e) {
    debugPrint('❌ Error approving product: $e');
    return false;
  }
}

static Future<bool> rejectProduct(int productId, String reason) async {
  try {
    await _client.from('products').update({
      'approval_status': 'rejected',
    }).eq('id', productId);
    
    await _notifySeller(productId, 'Your product was rejected: $reason');
    return true;
  } catch (e) {
    debugPrint('❌ Error rejecting product: $e');
    return false;
  }
}
```

---

## Part 8: Performance Optimization

### Image Optimization
```dart
// Before uploading, optimize image
import 'package:image/image.dart' as img;

Future<Uint8List> _optimizeImage(Uint8List imageBytes) async {
  img.Image? image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes;
  
  // Resize if too large
  if (image.width > 1200) {
    image = img.copyResize(image, width: 1200);
  }
  
  // Encode as JPEG with quality 85
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}
```

### Caching
```dart
// Cache category list
static Map<int, String>? _categoryCache;

// Cache product list with expiry
static List<SellerProduct>? _cachedProducts;
static DateTime? _cacheTime;
static const _cacheMaxAge = Duration(minutes: 5);

static Future<List<SellerProduct>> getByCurrentSellerCached() async {
  if (_cachedProducts != null && 
      DateTime.now().difference(_cacheTime!).inMinutes < 5) {
    return _cachedProducts!;
  }
  
  _cachedProducts = await getByCurrentSeller();
  _cacheTime = DateTime.now();
  return _cachedProducts!;
}
```

---

## Part 9: Testing Checklist

- [ ] Seller registration creates `sellers` profile
- [ ] Product creation auto-assigns `seller_id`
- [ ] RLS prevents sellers from viewing other sellers' products
- [ ] Product status filters work (pending/approved/archived)
- [ ] Stock updates trigger inventory transactions
- [ ] Low-stock alerts display correctly
- [ ] Multiple image uploads work
- [ ] Real-time updates show new products to buyers
- [ ] Dashboard stats calculate correctly
- [ ] Approval workflow triggers notifications
- [ ] Image URL resolution works (Storage → public URL)

---

## Part 10: Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Can't find products" | RLS blocking query | Check user's seller_id in sellers table |
| "Image upload fails" | Storage bucket doesn't exist | Create 'products' bucket and apply policies |
| "Stats showing 0" | Query permissions | Check RLS policies on orders/seller_daily_stats |
| "Approval status not updating" | Missing update permission | Ensure admin can update products |
| "Real-time not working" | Channel not subscribed | Call `subscribeToProductUpdates()` on init |

---

## Next Steps

1. ✅ Apply database schema
2. ✅ Enable RLS policies
3. ✅ Create storage bucket
4. ✅ Test seller registration flow
5. ✅ Implement product CRUD
6. ✅ Test status badges and filters
7. ✅ Enable real-time for marketplace
8. ✅ Add image optimization
9. ✅ Create admin approval UI
10. ✅ Load test with multiple sellers/products
