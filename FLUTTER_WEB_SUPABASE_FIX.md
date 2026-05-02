# Flutter Web + Supabase: Complete Debugging Guide

## 🔴 Your Error Explained

You're seeing these errors:
```
ERROR: supabaseUrl or anonKey is empty!
POST http://localhost:52791/auth/v1/token 404
Cannot reach Supabase. Your project may be paused...
```

**Root cause:** The app is trying to POST to `localhost:52791/auth/v1/token` instead of Supabase because the URL is empty.

---

## ✅ Quick Fix (5 minutes)

### Step 1: Verify `.env` file exists

In the project root (same level as `pubspec.yaml`), check you have:
```
c:\Users\razeel\Documents\e_commerce\.env
```

**Content should be:**
```
SUPABASE_URL=https://pzmyfchyzowlkufqabva.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6bXlmY2h5em93bGt1ZnFhYnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MzQ0MDEsImV4cCI6MjA5MzIxMDQwMX0.m_h41vyc8pBaiBDeUS7LKXft2R5EUnhmII2EoqmmV_w
```

**✅ Correct format:**
- No quotes around values
- Exact key names: `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- No spaces around `=`

### Step 2: Verify `pubspec.yaml` has assets

Open [pubspec.yaml](pubspec.yaml) and confirm:
```yaml
flutter:
  uses-material-design: true
  assets:
    - .env  # ← This line must exist!
```

### Step 3: Clean and rebuild

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Step 4: Check browser console

1. Run the app: `flutter run -d chrome`
2. Open browser: Press **F12**
3. Go to **Console** tab
4. Look for messages starting with ✅ or ❌

---

## 📋 Complete Verification Checklist

| # | Check | Status | How to Verify |
|---|-------|--------|---------------|
| 1 | `.env` file exists | ⬜ | File exists at project root |
| 2 | `.env` format correct | ⬜ | No quotes, no spaces around `=` |
| 3 | `SUPABASE_URL` starts with `https://` | ⬜ | Not `http://`, not `localhost` |
| 4 | `SUPABASE_ANON_KEY` is not empty | ⬜ | 3-part JWT token |
| 5 | `.env` in `pubspec.yaml` assets | ⬜ | See Step 2 above |
| 6 | `flutter clean && flutter pub get` | ⬜ | Rebuild from scratch |
| 7 | Browser console shows ✅ messages | ⬜ | F12 → Console → Look for "✅" |
| 8 | `debugPrintConfig()` output looks right | ⬜ | URL and key shown in console |
| 9 | No "localhost" in error messages | ⬜ | Should say "pzmyfchyzowlkufqabva.supabase.co" |
| 10 | Supabase project is NOT paused | ⬜ | Dashboard → Settings → Check status |

---

## 🔧 Specific Problems & Fixes

### Problem 1: "supabaseUrl or anonKey is empty!"

**Cause:** `.env` file not loading on web

**Fix #1 (Recommended for development):**
```bash
flutter run -d chrome
```
Your app now automatically loads `.env` from all platforms.

**Fix #2 (For production builds):**
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://pzmyfchyzowlkufqabva.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Fix #3 (If .env still not loading):**
- Delete `.env` (don't include it)
- Always use `--dart-define` flags
- This is the standard for Flutter web

---

### Problem 2: "POST http://localhost:52791/auth/v1/token 404"

**Cause:** Supabase URL is empty, so it defaults to `localhost` (the dev server)

**Fix:**
1. Check `.env` file has correct `SUPABASE_URL`
2. Verify it starts with `https://pzmyfchyzowlkufqabva.supabase.co`
3. NOT `https://localhost:...`
4. Run: `flutter clean && flutter pub get && flutter run -d chrome`

---

### Problem 3: App shows "Cannot reach Supabase. Your project may be paused"

**This happens when URL is loaded but Supabase is unreachable.**

**Check in order:**

1. **Is Supabase project paused?**
   - Go to [dashboard.supabase.com](https://dashboard.supabase.com)
   - Click your project
   - Settings → Billing
   - If paused, click **Resume**

2. **Is URL correct?**
   - Dashboard → Settings → API
   - Copy the exact URL
   - Make sure it's `https://pzmyfchyzowlkufqabva.supabase.co`
   - NOT any variation or missing characters

3. **Is network working?**
   - Can you open supabase.com in browser?
   - Try different network (mobile hotspot)?
   - Check if corporate firewall blocks APIs

4. **Test directly with cURL:**
   ```powershell
   Invoke-WebRequest `
     -Uri "https://pzmyfchyzowlkufqabva.supabase.co/rest/v1/" `
     -Headers @{apikey="YOUR_ANON_KEY"; Authorization="Bearer YOUR_ANON_KEY"}
   ```

---

## 🎯 Step-by-Step Debugging

### Step 1: Print what's actually loaded

After running the app, check browser console (F12) for messages like:
```
=== Supabase Config Debug ===
Platform: 🌐 WEB
URL: https://pzmyfchyzowlkufqabva.supabase.co
ANON KEY parts: 3 (expected 3 for a valid JWT)
ANON KEY prefix: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Is configured: true
```

**✅ If you see this:** Your credentials are loaded correctly
**❌ If you see "NOT FOUND":** Fix Step 1-2 from Quick Fix

### Step 2: Check authentication endpoint

Console should show:
```
========== AUTH ENDPOINT TEST ==========
✅ Auth Endpoint Status: 200
✅ PASS: Auth endpoint is reachable!
```

### Step 3: Verify database connection

Console should show:
```
========== DATABASE QUERY TEST ==========
✅ Query successful, rows: 5
✅ PASS: Database is accessible!
```

If you see error `42501`, that's Row Level Security (RLS) blocking - see solution below.

---

## 🛡️ RLS (Row Level Security) Issues

**Error:** `new row violates row-level security policy`

**Fix:** In Supabase Dashboard, go to **SQL Editor** and run:

```sql
-- For development: disable RLS on all tables
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- For production: create proper policies
CREATE POLICY "Allow anon read" ON products
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow auth insert" ON products
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

---

## 📝 Correct Files Setup

### `.env` (Project Root)
```
SUPABASE_URL=https://pzmyfchyzowlkufqabva.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6bXlmY2h5em93bGt1ZnFhYnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MzQ0MDEsImV4cCI6MjA5MzIxMDQwMX0.m_h41vyc8pBaiBDeUS7LKXft2R5EUnhmII2EoqmmV_w
```

### `pubspec.yaml` (Excerpt)
```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

### `lib/main.dart` (Initialization)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env FIRST
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded');
  } catch (e) {
    debugPrint('⚠️ .env error: $e');
  }

  // THEN check credentials
  SupabaseConfig.debugPrintConfig();

  // THEN initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}
```

---

## 🚀 Quick Commands

```bash
# Clean rebuild
flutter clean
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Chrome with explicit credentials (if .env not working)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://pzmyfchyzowlkufqabva.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY

# Hot reload in dev (press 'r' in terminal)
# Full restart (press 'R' in terminal)
```

---

## ✅ Success Indicators

When everything is working, you'll see:
1. ✅ Console shows URL and key are loaded
2. ✅ No errors in browser console
3. ✅ 404 errors on `localhost` are gone
4. ✅ App successfully authenticates or shows correct error

---

## 🆘 Still Not Working?

1. **Share the exact error message** from browser console (F12)
2. **Confirm `.env` file exists** and has correct format
3. **Run `flutter clean && flutter pub get`**
4. **Restart browser** (close all Chrome windows and reopen)
5. **Check Supabase dashboard** for any issues

The error message will tell us exactly what's wrong!
