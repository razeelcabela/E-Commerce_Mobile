# Supabase Setup Guide for E-Commerce App

## 🔴 CRITICAL: Configure Your Supabase Credentials First!

Your app cannot work until you configure the Supabase credentials. Follow these steps:

### Step 1: Get Your Credentials from Supabase

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click on your project
3. Go to **Settings → API** (left sidebar)
4. You'll see:
   - **Project URL** (e.g., `https://abc123def456.supabase.co`)
   - **Project API Keys** section with two keys:
     - `anon` (public) key ← Use this one
     - `service_role` key (keep secret, don't use in app)

### Step 2: Update Configuration

Edit `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
}
```

Replace:
- `YOUR_PROJECT_URL_HERE` with your Project URL
- `YOUR_ANON_KEY_HERE` with your anon public key

### Step 3: Create the `users` Table

In your Supabase Dashboard:

1. Go to **SQL Editor**
2. Create a new query
3. Paste this SQL:

```sql
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  email text UNIQUE NOT NULL,
  first_name text,
  last_name text,
  phone text,
  role text DEFAULT 'buyer',
  account_status text DEFAULT 'active',
  buyer_approval_status text DEFAULT 'approved',
  created_at timestamp DEFAULT NOW(),
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Allow users to read their own profile
CREATE POLICY "Users can read their own profile"
ON users FOR SELECT
USING (auth.uid() = id);
```

4. Click **Run**

### Step 4: Enable Email Confirmation (Optional but Recommended)

1. Go to **Authentication → Providers**
2. Click **Email** (should be enabled by default)
3. Scroll down to **Email Templates**
4. Configure your email confirmation settings

### Step 5: Test the App

1. Rebuild the app:
   ```bash
   flutter pub get
   flutter run
   ```

2. Try signing up in the app

3. **Check the Flutter console** for detailed logs:
   - Open Flutter DevTools (usually shown in IDE)
   - Look for messages starting with "Starting signup for:"
   - If there's an error, you'll see the real error message now

## 🐛 Debugging Errors

### Error: "An account with this email already exists"
- The email is already registered in Supabase Auth
- Try a different email

### Error: "Password is too weak"
- Your password must be at least 6 characters
- Try a stronger password

### Error: "Invalid email format"
- Your email address is invalid
- Check the email format

### Error: "Network error. Check your internet connection"
- You're offline
- Check your internet connection

### Error: "Failed to create user profile"
- The database insert failed (RLS issue, missing table, etc.)
- Check Supabase table permissions
- Verify the `users` table exists with all required columns
- Check Row Level Security (RLS) policies

### Error: "FATAL: database "postgres" does not exist" or similar database errors
- Your Supabase project might not be properly initialized
- Check if you created the table in the right database

## 📋 Checking Console Logs

When signup happens, you should see logs like:

```
Starting signup for: user@example.com
Auth signup successful for: user@example.com
Creating profile for user: 550e8400-e29b-41d4-a716-446655440000
Profile created successfully for: user@example.com
Signup completed successfully for: user@example.com
```

If there's an error, it will show:
```
Auth signup error: User already registered (code: 400)
```
or
```
Network error during signup: SocketException: Failed host lookup
```

## 🔗 Useful Links

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Email Configuration](https://supabase.com/docs/guides/auth/auth-smtp)

## ✅ Troubleshooting Checklist

- [ ] Project URL is filled in (not placeholder)
- [ ] Anon key is filled in (not placeholder)
- [ ] `users` table exists in Supabase
- [ ] `users` table has all required columns
- [ ] Row Level Security is enabled
- [ ] Email column is UNIQUE
- [ ] Foreign key from `users.id` to `auth.users.id` exists
- [ ] Internet connection is working
- [ ] Using valid email format
- [ ] Password is at least 6 characters
- [ ] Checking Flutter console for real error messages
