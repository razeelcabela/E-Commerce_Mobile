-- ============================================================
-- ADMIN RLS MIGRATION
-- Run this in Supabase SQL Editor AFTER SELLER_DASHBOARD_RLS_POLICIES.sql
--
-- What this fixes:
--   1. Drops broken seller policies that used sellers.user_id = auth.uid()
--      (sellers.user_id is BIGINT → users.id, NOT the auth UUID)
--   2. Creates correct policies using sellers.auth_user_id = auth.uid()
--   3. Adds admin full-read/write access to all tables
--   4. Enables RLS on the users profile table with self-read + admin-read
-- ============================================================


-- ── Step 1: Admin helper function ─────────────────────────────────────────────
-- Uses SECURITY DEFINER so it bypasses RLS when reading the users table.
-- This prevents the circular dependency of "need admin to check if admin".

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE auth_user_id = auth.uid()
      AND role = 'admin'
      AND account_status = 'active'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ── Step 2: Drop broken policies ──────────────────────────────────────────────
-- These used sellers.user_id = auth.uid() which fails because
-- sellers.user_id is a BIGINT FK to users.id, not a UUID.

DROP POLICY IF EXISTS "products_auth_read"            ON products;
DROP POLICY IF EXISTS "products_seller_insert"        ON products;
DROP POLICY IF EXISTS "products_seller_update"        ON products;
DROP POLICY IF EXISTS "products_seller_delete"        ON products;
DROP POLICY IF EXISTS "product_images_auth_read"      ON product_images;
DROP POLICY IF EXISTS "product_images_seller_insert"  ON product_images;
DROP POLICY IF EXISTS "product_images_seller_delete"  ON product_images;
DROP POLICY IF EXISTS "sellers_own_profile_read"      ON sellers;
DROP POLICY IF EXISTS "sellers_own_profile_update"    ON sellers;
DROP POLICY IF EXISTS "sellers_no_delete"             ON sellers;
DROP POLICY IF EXISTS "inventory_seller_read"         ON inventory_transactions;
DROP POLICY IF EXISTS "inventory_seller_insert"       ON inventory_transactions;
DROP POLICY IF EXISTS "orders_buyer_read"             ON orders;
DROP POLICY IF EXISTS "orders_seller_read"            ON orders;
DROP POLICY IF EXISTS "orders_seller_update"          ON orders;
DROP POLICY IF EXISTS "order_items_buyer_read"        ON order_items;
DROP POLICY IF EXISTS "order_items_seller_read"       ON order_items;
DROP POLICY IF EXISTS "seller_stats_read"             ON seller_daily_stats;


-- ── Step 3: Fixed sellers table policies ──────────────────────────────────────

-- Sellers can read/update their own profile; admins can read/update all
CREATE POLICY "sellers_own_profile_read" ON sellers
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid() OR public.is_admin());

CREATE POLICY "sellers_own_profile_update" ON sellers
  FOR UPDATE TO authenticated
  USING    (auth_user_id = auth.uid() OR public.is_admin())
  WITH CHECK (auth_user_id = auth.uid() OR public.is_admin());

CREATE POLICY "sellers_no_delete" ON sellers
  FOR DELETE USING (false);


-- ── Step 4: Fixed products table policies ─────────────────────────────────────

-- Admins see ALL products (including pending/rejected)
-- Sellers see all their own products (including pending/rejected)
-- Everyone else only sees approved + active + public products
CREATE POLICY "products_auth_read" ON products
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
    OR (
      approval_status = 'approved'
      AND is_active    = true
      AND archive_status = 'active'
    )
  );

-- Sellers can insert products for their own store
CREATE POLICY "products_seller_insert" ON products
  FOR INSERT TO authenticated
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );

-- Sellers can update their own products; admins can update any product
CREATE POLICY "products_seller_update" ON products
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  )
  WITH CHECK (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );

-- Only the owning seller can delete their product
CREATE POLICY "products_seller_delete" ON products
  FOR DELETE TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );


-- ── Step 5: Fixed product_images policies ─────────────────────────────────────

CREATE POLICY "product_images_auth_read" ON product_images
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM products p
      WHERE p.id = product_images.product_id
        AND (
          p.seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
          OR (p.approval_status = 'approved' AND p.is_active = true AND p.archive_status = 'active')
        )
    )
  );

CREATE POLICY "product_images_seller_insert" ON product_images
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM products p
      WHERE p.id = product_images.product_id
        AND p.seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
    )
  );

CREATE POLICY "product_images_seller_delete" ON product_images
  FOR DELETE TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM products p
      WHERE p.id = product_images.product_id
        AND p.seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
    )
  );


-- ── Step 6: Fixed inventory_transactions policies ─────────────────────────────

CREATE POLICY "inventory_seller_read" ON inventory_transactions
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );

CREATE POLICY "inventory_seller_insert" ON inventory_transactions
  FOR INSERT TO authenticated
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );


-- ── Step 7: Fixed orders policies ─────────────────────────────────────────────

-- Buyers see their own, sellers see their store orders, admins see all
CREATE POLICY "orders_buyer_read" ON orders
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR user_id = auth.uid()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );

-- Sellers and admins can update order status
CREATE POLICY "orders_seller_update" ON orders
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  )
  WITH CHECK (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );


-- ── Step 8: Fixed order_items policies ───────────────────────────────────────

CREATE POLICY "order_items_buyer_read" ON order_items
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_items.order_id
        AND (
          o.user_id = auth.uid()
          OR o.seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
        )
    )
  );


-- ── Step 9: Fixed seller_daily_stats policies ─────────────────────────────────

CREATE POLICY "seller_stats_read" ON seller_daily_stats
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR seller_id IN (SELECT id FROM sellers WHERE auth_user_id = auth.uid())
  );


-- ── Step 10: users profile table policies ─────────────────────────────────────
-- The users table stores role, account_status, etc.
-- Each user reads their own row; admins read/update all.

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_self_read"    ON users;
DROP POLICY IF EXISTS "users_admin_read"   ON users;
DROP POLICY IF EXISTS "users_self_update"  ON users;
DROP POLICY IF EXISTS "users_admin_update" ON users;

-- Every authenticated user can read their own profile
CREATE POLICY "users_self_read" ON users
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid() OR public.is_admin());

-- Users can update their own profile; admins can update any
CREATE POLICY "users_self_update" ON users
  FOR UPDATE TO authenticated
  USING    (auth_user_id = auth.uid() OR public.is_admin())
  WITH CHECK (auth_user_id = auth.uid() OR public.is_admin());

-- Allow insert during registration (user creates their own row)
CREATE POLICY "users_self_insert" ON users
  FOR INSERT TO authenticated
  WITH CHECK (auth_user_id = auth.uid());


-- ── Step 11: Verify ───────────────────────────────────────────────────────────
-- After running, confirm with:
--
--   SELECT tablename, policyname, roles, cmd
--   FROM pg_policies
--   WHERE schemaname = 'public'
--   ORDER BY tablename, policyname;
--
-- Then test with a seller account: submit a product.
-- Test with admin account on web: check Products tab → pending products visible.
-- Test with admin account on mobile: should be blocked at login.
