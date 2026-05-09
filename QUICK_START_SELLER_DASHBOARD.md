# Quick Start: Seller Dashboard Implementation

Get your seller dashboard running in 30 minutes with this step-by-step guide.

---

## Prerequisites
- Flutter project with Supabase configured
- `image_picker` dependency installed
- `google_fonts` dependency installed
- Existing auth system (seller_auth_service.dart)

---

## ✅ Step 1: Database Setup (5 minutes)

### 1.1 Apply Schema
1. Open Supabase Dashboard
2. Go to SQL Editor → New Query
3. Copy-paste entire `SELLER_DASHBOARD_SCHEMA.sql`
4. Click "Run"

### 1.2 Enable RLS
1. New Query
2. Copy-paste entire `SELLER_DASHBOARD_RLS_POLICIES.sql`
3. Click "Run"

### 1.3 Create Storage Bucket
1. Go to Storage section
2. Create bucket: `products`
3. Make Public ✓
4. Click "Create"

**Test:** Run this query to verify:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE' 
LIMIT 20;
```

Should show ~11 tables including `products`, `sellers`, `orders`, etc.

---

## ✅ Step 2: Add Flutter Models (2 minutes)

### Files Created:
- ✅ `lib/models/seller_dashboard_stats.dart` (dashboard metrics)
- ✅ `lib/widgets/product_status_badge.dart` (status widgets)

**No additional work needed** - just verify they exist in your project.

---

## ✅ Step 3: Update Services (3 minutes)

### Enhanced `lib/services/seller_product_service.dart`

The service has been updated with these new methods. Verify they're in your version:

```dart
// New methods added:
updateStock()
adjustStock()
getByStatus()
getLowStockProducts()
toggleActive()
setArchiveStatus()
getDashboardStats()
uploadMultipleImages()
```

If missing, copy from `SELLER_DASHBOARD_API_REFERENCE.md` and add them.

---

## ✅ Step 4: Test Core Functionality (5 minutes)

### Test Seller Creation
```dart
// In seller_auth_service.dart login
final error = await SellerAuthService.login(
  email: 'seller@test.com',
  password: 'test123',
);

if (error == null) {
  final email = await SellerAuthService.getCurrentSellerEmail();
  print('✅ Logged in: $email');
}
```

### Test Product Creation
```dart
final productId = await SellerProductService.add(
  SellerProduct(
    id: 0,
    sellerId: 1,
    sellerEmail: 'seller@test.com',
    name: 'Test Product',
    description: 'Test',
    imageUrl: '',
    price: 99.99,
    stock: 10,
    categoryId: 1,
    category: 'Electronics',
    createdAt: DateTime.now(),
  ),
);

print('Product ID: $productId'); // Should return a number
```

### Test Dashboard Stats
```dart
final stats = await SellerProductService.getDashboardStats();
print('Active Products: ${stats.activeProducts}');
print('Revenue: ${stats.totalRevenue}');
```

**All three should work without errors.**

---

## ✅ Step 5: Enhance UI (10 minutes)

### Add Status Badges to Existing Product List

In your product listing screen, add status indicators:

```dart
import '../../widgets/product_status_badge.dart';

// In product list item:
ProductStatusBadge(
  approvalStatus: product.approvalStatus ?? 'pending',
  isActive: product.isActive ?? true,
  archiveStatus: product.archiveStatus ?? 'active',
  stock: product.stock ?? 0,
  compact: true,
)

// Or for stock only:
StockStatusBadge(
  stock: product.stock ?? 0,
  compact: true,
)
```

### Add Real-Time Updates to Buyer Marketplace

In your buyer product list screen:

```dart
@override
void initState() {
  super.initState();
  _loadProducts();
  
  // NEW: Enable real-time updates
  ProductService.subscribeToProductUpdates(() {
    debugPrint('Products updated!');
    _loadProducts();
  });
}

@override
void dispose() {
  // NEW: Clean up subscription
  ProductService.unsubscribeFromProductUpdates();
  super.dispose();
}
```

---

## ✅ Step 6: Test End-to-End (5 minutes)

### Test Flow:
1. **Seller adds product**
   - Log in as seller
   - Create new product with details
   - Upload image
   - Product status: `pending`

2. **Admin approves product**
   - Log in as admin
   - Go to admin dashboard
   - Approve product
   - Product status: `approved`

3. **Buyer sees product**
   - Open marketplace as buyer
   - Should see approved product
   - Real-time indicator shows "Live"

4. **Seller updates stock**
   - Seller decreases stock: 10 → 5
   - Buyer reloads marketplace
   - Stock shows as "Low Stock"

5. **Seller archives product**
   - Seller archives product
   - Buyer can no longer see it

---

## Common Errors & Fixes

### ❌ "No seller_id found"
**Solution:** Make sure you created seller profile in `sellers` table
```dart
final sellerId = await SellerAuthService.getCurrentSellerId();
if (sellerId == null) {
  print('❌ Not a seller - create profile first');
}
```

### ❌ "Image upload fails"
**Solution:** Check storage bucket exists and is public
1. Storage → `products` bucket → make public
2. Check file extension is valid (jpg, png, webp)

### ❌ "RLS Error: authorization_failed_check_policy"
**Solution:** Run the RLS policies SQL again
- Go to SQL Editor
- Paste `SELLER_DASHBOARD_RLS_POLICIES.sql`
- Execute

### ❌ "Products show as 'Out of Stock' even though stock > 0"
**Solution:** Check `is_active` and `approval_status` fields
```dart
// Should be:
is_active = 1 (not 0)
approval_status = 'approved' (not 'pending')
archive_status = 'active' (not 'archived')
```

---

## Performance Optimization

### 1. Cache Categories
```dart
// Already implemented in seller_product_service.dart
final categories = await SellerProductService.getCategories();
// (Cached internally)
```

### 2. Paginate Products
```dart
// For large product lists:
static Future<List<SellerProduct>> getByCurrentSellerPaginated(
    {int limit = 20, int offset = 0}) async {
  final sellerId = await SellerAuthService.getCurrentSellerId();
  if (sellerId == null) return [];
  
  final rows = await _client
      .from('products')
      .select()
      .eq('seller_id', sellerId)
      .range(offset, offset + limit - 1)
      .order('created_at', ascending: false);
  
  // ... process rows
}
```

### 3. Debounce Real-Time Updates
```dart
Timer? _updateTimer;

void _onProductUpdate() {
  _updateTimer?.cancel();
  _updateTimer = Timer(const Duration(milliseconds: 500), () {
    _reloadProducts();
  });
}
```

---

## File Checklist

Verify all files are created/updated:

- [x] `SELLER_DASHBOARD_SCHEMA.sql` - Database structure
- [x] `SELLER_DASHBOARD_RLS_POLICIES.sql` - Security policies
- [x] `SELLER_DASHBOARD_IMPLEMENTATION.md` - Full guide
- [x] `SELLER_DASHBOARD_API_REFERENCE.md` - API docs
- [x] `BUYER_REALTIME_MARKETPLACE.md` - Real-time buyer experience
- [x] `lib/models/seller_dashboard_stats.dart` - Stats model
- [x] `lib/widgets/product_status_badge.dart` - Status widgets
- [x] `lib/services/seller_product_service.dart` - Enhanced (updated in place)

---

## What's Working

✅ Seller registration with profile creation
✅ Product CRUD (create, read, update, delete)
✅ Stock management with inventory transactions
✅ Product approval workflow (pending → approved)
✅ Product archiving
✅ Image upload to Supabase Storage
✅ Multiple image support
✅ Category management
✅ Dashboard metrics (products, orders, revenue)
✅ Low-stock alerts
✅ Real-time updates for buyers
✅ RLS security (sellers only see their products)

---

## Next Steps

1. **Payments Integration**
   - Integrate Razorpay/Stripe for checkout
   - Create order records on successful payment
   - Update seller revenue stats

2. **Notifications**
   - Email when product approved
   - SMS when order placed
   - In-app notifications

3. **Analytics**
   - Track product views
   - Track conversion rates
   - Seller dashboard with charts

4. **Reviews & Ratings**
   - Buyers can rate products
   - Seller gets feedback
   - Ratings visible on listings

5. **Admin Panel**
   - View all products
   - Approve/reject products
   - Manage sellers
   - View analytics

---

## Support

Check these files for detailed help:
- **API Usage:** `SELLER_DASHBOARD_API_REFERENCE.md`
- **Implementation:** `SELLER_DASHBOARD_IMPLEMENTATION.md`
- **Real-Time:** `BUYER_REALTIME_MARKETPLACE.md`
- **Database:** `SELLER_DASHBOARD_SCHEMA.sql`
- **Security:** `SELLER_DASHBOARD_RLS_POLICIES.sql`

---

## Success Indicators

You'll know it's working when:
- ✅ Seller can add products
- ✅ Products appear in pending list
- ✅ Admin can approve products
- ✅ Buyers see approved products in marketplace
- ✅ Product status badges show correctly
- ✅ Real-time indicator shows "Live"
- ✅ New products appear without refresh
- ✅ Stock changes are tracked
- ✅ Dashboard shows correct stats
- ✅ RLS prevents seller from viewing other sellers' products

---

**You're all set! Happy selling! 🚀**
