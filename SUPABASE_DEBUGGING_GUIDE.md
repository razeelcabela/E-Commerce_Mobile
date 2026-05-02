# Complete Supabase Connectivity Debug & Fix Guide

## Quick Status Check

Your app is **running successfully**! The diagnostic code is executing automatically on startup. Check the browser console (F12) to see the output.

---

## WHERE TO FIND DIAGNOSTIC OUTPUT

### Option 1: Browser Console (Recommended)
1. Run: `flutter run -d chrome`
2. Open Browser DevTools: **F12** or **Right-click → Inspect**
3. Go to **Console** tab
4. Look for messages starting with: ✅ ❌ 🔍 📡

### Option 2: VS Code Debug Console
1. Run: `flutter run`
2. Open **Debug Console** in VS Code (View → Debug Console)
3. Filter for "Supabase" messages

---

## STEP-BY-STEP DEBUGGING

### **Step 1: Verify Credentials Are Loaded**

Your **main.dart** now calls `SupabaseConfig.debugPrintConfig()` which prints:
```
=== Supabase Config Debug ===
Platform: Web
URL: https://pzmyfchyzowlkufqabva.supabase.co
ANON KEY parts: 3 (expected 3 for a valid JWT)
ANON KEY prefix: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**✅ If you see this:** Credentials are loaded correctly
**❌ If you see "NOT FOUND":** Check that `.env` file exists and is in `pubspec.yaml` assets

---

### **Step 2: Run Full Diagnostic Test**

Your app automatically runs `SupabaseDiagnostic.runAllDiagnostics()` on startup. This tests:

1. **JWT Token Verification** - Validates token format
2. **HTTP Connectivity Test** - Checks if Supabase server is reachable
3. **Auth Endpoint Test** - Verifies authentication endpoint works
4. **Realtime Connection Test** - Tests WebSocket connection
5. **Database Query Test** - Attempts actual database access
6. **Custom Headers Test** - Tests various header combinations

Look for output like:
```
========== HTTP CONNECTIVITY TEST ==========
🔍 Testing HTTP connection to: https://pzmyfchyzowlkufqabva.supabase.co/rest/v1/
✅ HTTP Response Status: 401
✅ PASS: Supabase server is reachable!
```

---

### **Step 3: Common Error Messages & Fixes**

#### **❌ "Cannot reach Supabase. Your project may be paused"**

**Most Common Cause: Paused Supabase Project**

Fix:
1. Go to [dashboard.supabase.com](https://dashboard.supabase.com)
2. Select your project
3. Click **Settings** → **Billing** → **Pause Project**
4. If paused, click **Resume**

**Verify it worked:** Run diagnostic again - should show ✅ PASS

---

#### **❌ "Row Level Security (RLS) blocking access"**

**Code:** Error `42501` 

**Fix:** Create RLS policies allowing anon access

Go to Supabase Dashboard → **SQL Editor** → Run this:

```sql
-- Allow public read on products table
CREATE POLICY "Allow anon select"
ON products FOR SELECT
TO anon
USING (true);

-- Allow authenticated users to create/update their own data
CREATE POLICY "Allow auth insert/update own"
ON products FOR INSERT, UPDATE
TO authenticated
USING (auth.uid() = user_id);
```

**Or:** Disable RLS entirely (for development only):
1. Dashboard → **Authentication** → Providers
2. Find your table in the list
3. Click **Disable Row Level Security**

---

#### **❌ "Table does not exist"**

**Code:** Error `42P01`

**Fix:**
1. Make sure table name is exactly correct (case-sensitive on Postgres)
2. Verify table exists: Dashboard → **Tables** → should see your table
3. If missing, create it: Dashboard → **SQL Editor** →

```sql
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

#### **❌ "Invalid or expired API key"**

**Fix:**
1. Go to Dashboard → **Settings** → **API**
2. Copy the exact **anon** key (not service_role key)
3. Update `.env`:
   ```
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
4. Save and restart app

---

#### **❌ "Internet/Network issue"**

**Symptoms:** Timeout, connection refused, SocketException

**Fix:**
1. Verify internet works: Can you open supabase.com in browser?
2. Check firewall: Some corporate firewalls block external APIs
3. Try from different network (mobile hotspot)
4. Increase timeout in code:

```dart
final response = await http.get(uri).timeout(Duration(seconds: 30)); // was 10
```

---

## MANUAL TESTING WITH CODE

### **Test 1: Simple Connectivity Check**

Add this to your InitScreen:

```dart
class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    _testSupabase(); // Add this
    _checkAuthStatus();
  }

  Future<void> _testSupabase() async {
    final success = await SupabaseServiceEnhanced.testConnectivity();
    debugPrint(success ? '✅ Supabase OK' : '❌ Supabase Failed');
  }
```

**Expected output in console:** `✅ Supabase OK`

---

### **Test 2: Check Auth Status**

```dart
Future<void> _checkAuth() async {
  await SupabaseServiceEnhanced.printAuthStatus();
  // Output will show:
  // ✅ User logged in / ℹ️ Anonymous access
  // ✅ Valid session exists / ℹ️ No active session
}
```

---

### **Test 3: Try a Real Query**

```dart
Future<void> _testQuery() async {
  final users = await SupabaseServiceEnhanced.safeQuery('users');
  debugPrint('Found ${users.length} users');
}
```

**Expected:** Either returns data or specific error message with fix

---

## VERIFICATION CHECKLIST

Before assuming Supabase is broken, verify:

| Item | Check | Status |
|------|-------|--------|
| **Project Paused?** | Dashboard → Billing | ⬜ |
| **URL Correct?** | Matches `pzmyfchyzowlkufqabva.supabase.co` | ⬜ |
| **Key Correct?** | From Dashboard → Settings → API → anon key | ⬜ |
| **.env Loaded?** | Console shows "✅ .env file loaded successfully" | ⬜ |
| **Credentials Printed?** | Debug output shows URL and key prefix | ⬜ |
| **HTTP Reachable?** | Diagnostic shows `✅ PASS: Supabase server is reachable!` | ⬜ |
| **RLS Not Blocking?** | Query works OR proper RLS policies exist | ⬜ |
| **Auth Configured?** | Dashboard → Authentication → Providers enabled | ⬜ |

---

## IF STILL NOT WORKING

### **Option A: Check Service Status**

Visit [status.supabase.com](https://status.supabase.com) to see if Supabase is having outages.

### **Option B: Test with cURL**

Open PowerShell and run:

```powershell
$headers = @{
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  # Your anon key
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Invoke-WebRequest -Uri "https://pzmyfchyzowlkufqabva.supabase.co/rest/v1/" -Headers $headers
```

If this works, the issue is in Flutter code. If this fails, Supabase is unreachable.

### **Option C: Check RLS Policies**

```sql
-- Run in Supabase SQL Editor
SELECT * FROM pg_policies WHERE tablename = 'products';
```

If no results, RLS policies aren't set up. Create them using the SQL above.

---

## PRODUCTION-READY CODE

For production, use this pattern:

```dart
class ProductService {
  static final _client = Supabase.instance.client;

  static Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Product.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('❌ Product query error: ${e.message}');
      // Proper RLS policies should prevent this
      return [];
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return [];
    }
  }

  static Future<bool> addProduct(Product product) async {
    try {
      await _client.from('products').insert([product.toMap()]);
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        debugPrint('❌ RLS blocking insert - check policies');
      }
      return false;
    }
  }
}
```

---

## NEXT STEPS

1. **Run the app:** `flutter run -d chrome`
2. **Open browser console:** F12 → Console
3. **Look for diagnostic output:** Search for "✅" or "❌"
4. **Check status:** Note which tests pass/fail
5. **Apply fixes above:** Based on which tests fail
6. **Re-run:** Restart app after any changes

---

## FILES CREATED FOR YOU

- **[lib/config/supabase_diagnostic.dart](lib/config/supabase_diagnostic.dart)** - Comprehensive diagnostic tool
- **[lib/services/supabase_service_enhanced.dart](lib/services/supabase_service_enhanced.dart)** - Error-aware Supabase service
- **[lib/main.dart](lib/main.dart)** - Updated with automatic diagnostics

All files are production-ready and include detailed error messages.

---

## QUESTIONS?

Share the error message you see in the console and I'll provide the exact fix!
