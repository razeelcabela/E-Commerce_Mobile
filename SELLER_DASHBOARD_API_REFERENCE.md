# Seller Dashboard API Reference

Quick reference for all seller dashboard operations available through the Flutter services.

---

## SellerProductService

### Product CRUD Operations

#### Create Product
```dart
final sellerId = await SellerAuthService.getCurrentSellerId();
final productId = await SellerProductService.add(
  SellerProduct(
    id: 0,
    sellerId: sellerId ?? 0,
    sellerEmail: 'seller@example.com',
    name: 'Awesome Product',
    description: 'Product details',
    imageUrl: '',
    price: 99.99,
    stock: 100,
    categoryId: 5,
    category: 'Electronics',
    createdAt: DateTime.now(),
  ),
);
// Returns: product_id (int?) or null on error
```

#### Read Products
```dart
// Get all products for current seller
final products = await SellerProductService.getByCurrentSeller();

// Get products by approval status
final pending = await SellerProductService.getByStatus('pending');
final approved = await SellerProductService.getByStatus('approved');

// Get low stock products
final lowStock = await SellerProductService.getLowStockProducts(threshold: 10);

// Get all available categories
final categories = await SellerProductService.getCategories();
// Returns: [{'id': 1, 'name': 'Electronics'}, ...]
```

#### Update Product
```dart
await SellerProductService.update(
  SellerProduct(
    id: productId,
    sellerId: 1,
    sellerEmail: 'seller@example.com',
    name: 'Updated Name',
    description: 'Updated description',
    imageUrl: 'https://...',
    price: 79.99,
    stock: 50,
    categoryId: 5,
    category: 'Electronics',
    createdAt: DateTime.now(),
  ),
);
```

#### Delete Product
```dart
await SellerProductService.delete(productId);
// Deletes product and all associated images
```

---

### Stock Management

#### Update Stock
```dart
// Set stock to exact value
final success = await SellerProductService.updateStock(productId, 100);
```

#### Adjust Stock
```dart
// Increment stock by 10
await SellerProductService.adjustStock(productId, 10, reason: 'add');

// Decrement stock by 5
await SellerProductService.adjustStock(productId, -5, reason: 'sale');

// Other reasons: 'return', 'adjustment', 'damaged'
```

---

### Product Status Management

#### Toggle Active Status
```dart
// Activate product
await SellerProductService.toggleActive(productId, true);

// Deactivate product
await SellerProductService.toggleActive(productId, false);
```

#### Archive/Unarchive
```dart
// Archive product (hidden from buyers, kept in DB)
await SellerProductService.setArchiveStatus(productId, 'archived');

// Restore product
await SellerProductService.setArchiveStatus(productId, 'active');
```

---

### Image Management

#### Upload Single Image
```dart
// bytes: image data as Uint8List
// ext: file extension ('jpg', 'png', 'webp', etc.)
await SellerProductService.uploadImage(productId, bytes, 'jpg');
```

#### Upload Multiple Images
```dart
final imageData = [
  {'bytes': imageBytes1, 'ext': 'jpg'},
  {'bytes': imageBytes2, 'ext': 'jpg'},
  {'bytes': imageBytes3, 'ext': 'png'},
];

final uploadCount = await SellerProductService.uploadMultipleImages(
  productId,
  imageData,
);
// Returns: number of successfully uploaded images
```

---

### Dashboard & Analytics

#### Get Dashboard Statistics
```dart
final stats = await SellerProductService.getDashboardStats();

// Access stats
print('Total Products: ${stats.totalProducts}');
print('Active Products: ${stats.activeProducts}');
print('Pending Review: ${stats.pendingApprovalProducts}');
print('Archived: ${stats.archivedProducts}');
print('Low Stock: ${stats.lowStockProducts}');
print('Total Orders: ${stats.totalOrders}');
print('Total Revenue: ₹${stats.totalRevenue}');
print('Avg Order Value: ₹${stats.avgOrderValue}');
print('Total Earnings: ₹${stats.totalEarnings}');

// Revenue breakdown (last 7 days)
for (final daily in stats.revenueLastSevenDays) {
  print('${daily.date}: ₹${daily.amount} (${daily.orderCount} orders)');
}
```

---

## ProductService

### Buyer-Facing Operations

#### Get All Products (for marketplace)
```dart
final products = await ProductService.getAllProducts();
// Returns approved, active, not archived products
```

#### Get Products by Category
```dart
final products = await ProductService.getProductsByCategory('Electronics');
```

#### Get Single Product
```dart
final product = await ProductService.getProductById(productId);
```

#### Get Categories
```dart
final categories = await ProductService.getCategories();
// Returns: ['Electronics', 'Clothing', 'Books', ...]
```

#### Subscribe to Real-Time Updates
```dart
ProductService.subscribeToProductUpdates(() {
  // Called whenever new products are added or updated
  debugPrint('📦 Marketplace updated!');
  _reloadProducts();
});

// Don't forget to unsubscribe on dispose
ProductService.unsubscribeFromProductUpdates();
```

---

## SellerAuthService

### Authentication Operations

#### Register New Seller
```dart
final error = await SellerAuthService.register(
  email: 'seller@example.com',
  password: 'securePassword123',
  storeName: 'My Store',
  businessName: 'My Business Inc.',
);

if (error != null) {
  print('❌ Registration failed: $error');
} else {
  print('✅ Registration successful');
}
```

#### Login Seller
```dart
final error = await SellerAuthService.login(
  email: 'seller@example.com',
  password: 'securePassword123',
);

if (error == null) {
  print('✅ Logged in as ${await SellerAuthService.getCurrentSellerEmail()}');
}
```

#### Logout
```dart
await SellerAuthService.logout();
// Clears session and user data
```

#### Get Current Seller Info
```dart
final email = await SellerAuthService.getCurrentSellerEmail();
final sellerId = await SellerAuthService.getCurrentSellerId();
final userId = await SellerAuthService.getCurrentSellerUserId();

if (email == null) {
  print('No seller logged in');
}
```

#### Check if Logged In
```dart
final isLoggedIn = await SellerAuthService.isLoggedIn();
if (!isLoggedIn) {
  Navigator.of(context).pushReplacementNamed('/login');
}
```

#### Sync Session (for app startup)
```dart
final status = await SellerAuthService.syncSession();
// Returns seller info or null if session invalid
```

---

## Models Reference

### SellerDashboardStats
```dart
final stats = await SellerProductService.getDashboardStats();

// Properties:
stats.totalProducts;            // int
stats.activeProducts;           // int
stats.pendingApprovalProducts;  // int
stats.archivedProducts;         // int
stats.lowStockProducts;         // int
stats.totalOrders;              // int
stats.totalRevenue;             // double
stats.avgOrderValue;            // double
stats.totalEarnings;            // double
stats.topProductId;             // int
stats.topProductName;           // String?
stats.topProductSales;          // int
stats.revenueLastSevenDays;     // List<DailyRevenue>
```

### DailyRevenue
```dart
final daily = stats.revenueLastSevenDays.first;

// Properties:
daily.date;         // String (YYYY-MM-DD)
daily.amount;       // double
daily.orderCount;   // int
```

### SellerProduct
```dart
// Key fields:
product.id;
product.sellerId;
product.name;
product.description;
product.price;
product.stock;
product.categoryId;
product.category;
product.imageUrl;
product.createdAt;
```

### Product
```dart
// Buyer-facing product:
product.id;
product.name;
product.price;
product.description;
product.category;
product.imageUrl;
```

---

## Widgets Reference

### ProductStatusBadge
```dart
ProductStatusBadge(
  approvalStatus: 'approved',  // 'pending', 'approved', 'rejected'
  isActive: true,
  archiveStatus: 'active',     // 'active', 'archived'
  stock: 25,
  compact: false,  // true for smaller display
)

// Shows: Active, Pending Review, Archived, Rejected, Out of Stock
```

### StockStatusBadge
```dart
StockStatusBadge(
  stock: 5,
  lowStockThreshold: 10,
  compact: false,  // true for smaller display
)

// Shows: In Stock, Low Stock, Out of Stock
```

---

## Error Handling Examples

### Safe Product Creation
```dart
try {
  if (_name.isEmpty || _price <= 0 || _stock < 0) {
    throw Exception('Invalid product data');
  }
  
  final product = SellerProduct(
    id: 0,
    sellerId: sellerId!,
    sellerEmail: email!,
    name: _name,
    description: _description,
    imageUrl: '',
    price: _price,
    stock: _stock,
    categoryId: _categoryId,
    category: _categoryName,
    createdAt: DateTime.now(),
  );
  
  final productId = await SellerProductService.add(product);
  
  if (productId == null) {
    throw Exception('Failed to create product');
  }
  
  // Upload images
  if (_imageBytes.isNotEmpty) {
    await SellerProductService.uploadMultipleImages(
      productId,
      List.generate(
        _imageBytes.length,
        (i) => {'bytes': _imageBytes[i], 'ext': _imageExts[i]},
      ),
    );
  }
  
  _showSnack('✅ Product created successfully');
} catch (e) {
  _showSnack('❌ Error: ${e.toString()}');
}
```

### Safe Dashboard Load
```dart
Future<void> _loadDashboard() async {
  try {
    setState(() => _loading = true);
    
    final stats = await SellerProductService.getDashboardStats();
    final lowStock = await SellerProductService.getLowStockProducts();
    
    if (!mounted) return;
    
    setState(() {
      _stats = stats;
      _lowStockProducts = lowStock;
      _loading = false;
    });
  } catch (e) {
    debugPrint('Dashboard load error: $e');
    if (mounted) {
      setState(() => _loading = false);
      _showSnack('Failed to load dashboard');
    }
  }
}
```

---

## Common Workflows

### Add New Product with Images
```dart
// 1. Validate inputs
if (!_validateInputs()) return;

// 2. Create product
final productId = await SellerProductService.add(_buildProduct());
if (productId == null) {
  _showSnack('❌ Failed to create product');
  return;
}

// 3. Upload images
if (_pickedImagesList.isNotEmpty) {
  final count = await SellerProductService.uploadMultipleImages(
    productId,
    _buildImageData(),
  );
  _showSnack('✅ Uploaded $count images');
}

// 4. Refresh product list
await _loadProducts();
```

### Manage Stock
```dart
// Decrease stock when order is placed
await SellerProductService.adjustStock(
  productId,
  -quantity,
  reason: 'sale',
);

// Increase stock when item is returned
await SellerProductService.adjustStock(
  productId,
  quantity,
  reason: 'return',
);

// Manual adjustment
await SellerProductService.adjustStock(
  productId,
  10,
  reason: 'adjustment',
);
```

### Check Dashboard and Alert if Low Stock
```dart
final stats = await SellerProductService.getDashboardStats();

if (stats.lowStockProducts > 0) {
  _showAlert(
    'Low Stock Alert!',
    '${stats.lowStockProducts} product(s) need restocking.',
  );
}
```

---

## Data Flow Diagram

```
Seller App
    ↓
SellerAuthService (login/register)
    ↓
SellerProductService (CRUD, stats, images)
    ↓
Supabase DB
    ├── products table
    ├── product_images table
    ├── sellers table
    ├── orders table (from buyers)
    └── inventory_transactions table
    ↓
Supabase Storage
    └── products bucket (images)

Buyer App
    ↓
ProductService (read-only)
    ↓
Supabase (via RLS - sees only approved products)
    ↓
Real-time subscription
    └── Notified of new products
```

---

## Notes

- All timestamps are returned as `DateTime` objects (timezone aware)
- Image URLs are resolved automatically to public Supabase URLs
- RLS ensures sellers can only manage their own products
- Stock changes are logged for audit trails
- Dashboard stats are calculated real-time (consider caching for performance)
- Real-time updates use Supabase Realtime (websocket-based)
