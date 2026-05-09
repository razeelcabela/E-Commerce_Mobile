## 🔍 VARON E-COMMERCE: PRODUCT SYNC TROUBLESHOOTING GUIDE

### **Problem Summary**
Products migrated from MySQL→Supabase are not showing in the mobile app.

---

### **Root Causes Identified**

✅ **FIXED:** ShopScreen was using hardcoded products instead of Supabase
✅ **UPDATED:** Product model now supports UUID IDs  
✅ **CREATED:** ProductService for fetching from Supabase
✅ **UPDATED:** ShopScreen now has loading states and error handling

---

### **Step 1: Verify Supabase Connection**

Your `.env` file should exist at:
```
c:\Users\razeel\Documents\e_commerce_mobile\.env
```

And contain:
```
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
```

**To find these values:**
1. Go to [app.supabase.com](https://app.supabase.com)
2. Select your project
3. Go to **Settings > API**
4. Copy `Project URL` and `anon public` key

---

### **Step 2: Verify Supabase Table Structure**

Go to Supabase Dashboard → **SQL Editor** and run:

```sql
-- 1. Check if products table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'products';

-- 2. Check table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- 3. Count products
SELECT COUNT(*) as total_products FROM products;

-- 4. Check for approved products (what the app fetches)
SELECT COUNT(*) as approved_products 
FROM products 
WHERE approval_status = 'approved' 
  AND is_active = true 
  AND archive_status = 'active';

-- 5. See sample data
SELECT id, name, price, category, approval_status, is_active 
FROM products 
LIMIT 5;
```

**Your table MUST have these columns (minimum):**
```
id          - BIGINT or UUID (primary key)
name        - VARCHAR/TEXT
price       - NUMERIC/DECIMAL
description - TEXT
category    - VARCHAR
image_url   - VARCHAR
approval_status - VARCHAR (values: 'approved', 'pending', 'rejected')
is_active   - BOOLEAN (true/false)
archive_status - VARCHAR (values: 'active', 'archived')
seller_id   - BIGINT/UUID (foreign key to users)
created_at  - TIMESTAMP
```

---

### **Step 3: Check if Migration Data is Missing**

If Step 2 shows 0 products, your MySQL data **wasn't migrated**.

**Solutions:**

**Option A: Use Supabase Migration Tool**
1. Go to Supabase Dashboard
2. Select your project
3. Go to **Tools > Migrations**
4. Follow the guided migration wizard

**Option B: Manual SQL Migration**
If you have the migrated SQL dump:
1. Go to **SQL Editor**
2. Paste your SQL dump
3. Run

**Option C: Add Test Data Manually**
For testing, add a sample product:
```sql
INSERT INTO products (name, price, description, category, image_url, approval_status, is_active, archive_status)
VALUES (
  'Test Product',
  999.00,
  'This is a test product',
  'Test',
  'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop',
  'approved',
  true,
  'active'
);
```

---

### **Step 4: Check Row-Level Security (RLS) Policies**

RLS policies might be blocking read access.

**Check if RLS is enabled:**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'products';
```

If `rowsecurity` is `true`, check policies:
```sql
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'products';
```

**If RLS is blocking (temporary fix for testing):**
```sql
-- DISABLE for testing ONLY
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
```

**Proper RLS policy (allow anyone to read approved products):**
```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read approved products"
  ON products FOR SELECT
  USING (approval_status = 'approved' AND is_active = true);
```

---

### **Step 5: Verify Column Names Match Mobile App**

The mobile app queries for:
```dart
.eq('approval_status', 'approved')
.eq('is_active', true)
.eq('archive_status', 'active')
```

**Your Supabase table MUST have these exact column names.** If your migration used different names, you have options:

**Option 1: Rename columns in Supabase**
```sql
ALTER TABLE products RENAME COLUMN old_name TO approval_status;
ALTER TABLE products RENAME COLUMN old_name TO is_active;
ALTER TABLE products RENAME COLUMN old_name TO archive_status;
```

**Option 2: Update the mobile app queries**
Edit `lib/services/product_service.dart` and change the filter conditions to match your column names.

---

### **Step 6: Test the Mobile App**

Now run the mobile app:
```bash
cd c:\Users\razeel\Documents\e_commerce_mobile
flutter run -d chrome  # or your device
```

**What to look for:**
- ✅ "✅ Loaded X products from Supabase" in console
- ✅ Products display on shop screen
- ❌ "⚠️ Loading from fallback data" = Supabase returning 0 products
- ❌ "❌ Connection error" = Network/auth issue

---

### **Step 7: Debug Logs**

**Open browser DevTools (F12)** and check the console for:

```
✅ supabaseUrl loaded from dotenv
✅ supabaseAnonKey loaded from dotenv
✅ Supabase initialized successfully
✅ Loaded 24 products from Supabase
```

If you don't see these, Supabase isn't configured correctly.

---

### **Troubleshooting Checklist**

| Issue | Cause | Solution |
|-------|-------|----------|
| "Loading from fallback data" | 0 products in Supabase | Check MySQL migration was successful |
| Blank page / crashes | Products table missing | Create table using SQL from Step 2 |
| Wrong column error | Column names don't match | Rename columns or update queries |
| RLS error | Row-level security blocking | Disable RLS or add proper policies |
| "Connection refused" | Wrong Supabase URL | Verify .env file has correct URL |
| Empty cart / no checkout | Cart/order tables missing | Create additional tables needed |

---

### **Files Modified**

- ✅ `lib/models/product.dart` - Updated to support UUID IDs
- ✅ `lib/services/product_service.dart` - NEW file for Supabase queries
- ✅ `lib/screens/shop_screen.dart` - Now fetches from Supabase

---

### **Next Steps**

1. Run the diagnostic SQL queries from **Step 2**
2. Report which queries return 0 or errors
3. Apply fixes from Steps 3-5 as needed
4. Test the app again
5. Report any remaining issues

---

### **Emergency Fallback**

If Supabase isn't working, the app will automatically show hardcoded test products:
```dart
// In shop_screen.dart
final fallbackProducts = [ /* hardcoded test data */ ]
```

This allows the app to function while you fix the database issues.

---

**Need help?** Check:
- Supabase Status: [status.supabase.com](https://status.supabase.com)
- Firebase vs Supabase: Both work the same way (cloud database)
- CORS issues: Configure in Supabase Settings
