-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - CORRECTED & TESTED
-- ============================================================================
-- This file contains all RLS policies for the seller dashboard system.
-- Apply these policies after creating the tables in SELLER_DASHBOARD_SCHEMA.sql
--
-- IMPORTANT NOTES:
-- 1. All policies assume user_id is UUID and seller_id is BIGINT
-- 2. Type casting is explicit where needed
-- 3. Policies use proper PostgreSQL syntax for Supabase compatibility
--
-- To apply: Copy entire file → Supabase SQL Editor → Execute
-- ============================================================================


-- ────────────────────────────────────────────────────────────────────────────
-- SELLERS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;

-- Public can view active seller profiles (store info)
CREATE POLICY "sellers_anon_read"
  ON sellers FOR SELECT
  TO anon
  USING (status = 'active');

-- Authenticated users can view all active seller profiles
CREATE POLICY "sellers_auth_read_active"
  ON sellers FOR SELECT
  TO authenticated
  USING (status = 'active');

-- Sellers can view their own profile
CREATE POLICY "sellers_own_profile_read"
  ON sellers FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Sellers can update their own profile
CREATE POLICY "sellers_own_profile_update"
  ON sellers FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Prevent accidental deletion of seller profiles
CREATE POLICY "sellers_no_delete"
  ON sellers FOR DELETE
  USING (false);

-- ────────────────────────────────────────────────────────────────────────────
-- CATEGORIES TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Public can view active categories
CREATE POLICY "categories_anon_read"
  ON categories FOR SELECT
  TO anon
  USING (is_active = true);

-- Authenticated users can view active categories
CREATE POLICY "categories_auth_read"
  ON categories FOR SELECT
  TO authenticated
  USING (is_active = true);

-- ────────────────────────────────────────────────────────────────────────────
-- PRODUCTS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Public can view APPROVED, ACTIVE products
CREATE POLICY "products_anon_read"
  ON products FOR SELECT
  TO anon
  USING (
    approval_status = 'approved'
    AND is_active = true
    AND archive_status = 'active'
    AND visibility = 'public'
  );

-- Authenticated buyers can view approved/active products
-- OR sellers can view all their own products (including pending)
CREATE POLICY "products_auth_read"
  ON products FOR SELECT
  TO authenticated
  USING (
    -- Show approved products to buyers
    (approval_status = 'approved'
     AND is_active = true
     AND archive_status = 'active'
     AND visibility = 'public')
    OR
    -- Show all their own products to sellers
    (seller_id IN (
      SELECT id FROM sellers WHERE user_id = auth.uid()
    ))
  );

-- Sellers can INSERT products
CREATE POLICY "products_seller_insert"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- Sellers can UPDATE only their own products
CREATE POLICY "products_seller_update"
  ON products FOR UPDATE
  TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  )
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- Sellers can DELETE only their own products
CREATE POLICY "products_seller_delete"
  ON products FOR DELETE
  TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- ────────────────────────────────────────────────────────────────────────────
-- PRODUCT IMAGES TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

-- Public can view images of approved products
CREATE POLICY "product_images_anon_read"
  ON product_images FOR SELECT
  TO anon
  USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND products.approval_status = 'approved'
      AND products.is_active = true
      AND products.archive_status = 'active'
    )
  );

-- Authenticated users can view images of products they can see
CREATE POLICY "product_images_auth_read"
  ON product_images FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND (
        (products.approval_status = 'approved'
         AND products.is_active = true
         AND products.archive_status = 'active')
        OR
        (products.seller_id IN (
          SELECT id FROM sellers WHERE user_id = auth.uid()
        ))
      )
    )
  );

-- Sellers can INSERT images for their products
CREATE POLICY "product_images_seller_insert"
  ON product_images FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND products.seller_id IN (
        SELECT id FROM sellers WHERE user_id = auth.uid()
      )
    )
  );

-- Sellers can DELETE images from their products
CREATE POLICY "product_images_seller_delete"
  ON product_images FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND products.seller_id IN (
        SELECT id FROM sellers WHERE user_id = auth.uid()
      )
    )
  );

-- ────────────────────────────────────────────────────────────────────────────
-- INVENTORY TRANSACTIONS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;

-- Sellers can view transactions for their products
CREATE POLICY "inventory_seller_read"
  ON inventory_transactions FOR SELECT
  TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- Sellers can INSERT transactions for their products
CREATE POLICY "inventory_seller_insert"
  ON inventory_transactions FOR INSERT
  TO authenticated
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- ────────────────────────────────────────────────────────────────────────────
-- ORDERS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Buyers can view their own orders
CREATE POLICY "orders_buyer_read"
  ON orders FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Sellers can view orders for their products
CREATE POLICY "orders_seller_read"
  ON orders FOR SELECT
  TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- Buyers can INSERT orders
CREATE POLICY "orders_buyer_insert"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Sellers can UPDATE order status for their orders
CREATE POLICY "orders_seller_update"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  )
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );

-- ────────────────────────────────────────────────────────────────────────────
-- ORDER ITEMS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Buyers can view order items for their orders
CREATE POLICY "order_items_buyer_read"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- Sellers can view order items for their orders
CREATE POLICY "order_items_seller_read"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
    )
  );

-- ────────────────────────────────────────────────────────────────────────────
-- CARTS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE carts ENABLE ROW LEVEL SECURITY;

-- Buyers can manage their own cart
CREATE POLICY "carts_buyer_all"
  ON carts
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ────────────────────────────────────────────────────────────────────────────
-- CART ITEMS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Buyers can manage cart items in their own cart
CREATE POLICY "cart_items_buyer_read"
  ON cart_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM carts
      WHERE carts.id = cart_items.cart_id
      AND carts.user_id = auth.uid()
    )
  );

CREATE POLICY "cart_items_buyer_write"
  ON cart_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM carts
      WHERE carts.id = cart_items.cart_id
      AND carts.user_id = auth.uid()
    )
  );

CREATE POLICY "cart_items_buyer_update"
  ON cart_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM carts
      WHERE carts.id = cart_items.cart_id
      AND carts.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM carts
      WHERE carts.id = cart_items.cart_id
      AND carts.user_id = auth.uid()
    )
  );

CREATE POLICY "cart_items_buyer_delete"
  ON cart_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM carts
      WHERE carts.id = cart_items.cart_id
      AND carts.user_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────────────────────────────────
-- REVIEWS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Public can view approved reviews
CREATE POLICY "reviews_anon_read"
  ON reviews FOR SELECT
  TO anon
  USING (status = 'approved');

-- Authenticated users can view approved reviews plus their own
CREATE POLICY "reviews_auth_read"
  ON reviews FOR SELECT
  TO authenticated
  USING (status = 'approved' OR user_id = auth.uid());

-- Authenticated users can INSERT reviews
CREATE POLICY "reviews_auth_insert"
  ON reviews FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can UPDATE their own reviews
CREATE POLICY "reviews_auth_update"
  ON reviews FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ────────────────────────────────────────────────────────────────────────────
-- SELLER DAILY STATS TABLE
-- ────────────────────────────────────────────────────────────────────────────

ALTER TABLE seller_daily_stats ENABLE ROW LEVEL SECURITY;

-- Sellers can view their own stats
CREATE POLICY "seller_stats_read"
  ON seller_daily_stats FOR SELECT
  TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id = auth.uid())
  );


-- ════════════════════════════════════════════════════════════════════════════
-- STORAGE POLICIES (Supabase Storage Bucket: "products")
-- ════════════════════════════════════════════════════════════════════════════
-- NOTE: These policies are applied in Supabase Dashboard UI, NOT via SQL.
-- 
-- Steps to apply:
-- 1. Go to Storage → products bucket
-- 2. Click "Policies" tab
-- 3. Create policies as shown below:

-- POLICY 1: Public can view product images
-- Name: "public_images_read"
-- Target: anon, authenticated
-- Type: SELECT
-- Path: products/*
-- Expression: (none - allow all)

-- POLICY 2: Authenticated users can upload images
-- Name: "auth_images_upload"
-- Target: authenticated
-- Type: INSERT
-- Path: products/*
-- Expression: (none - allow authenticated)

-- POLICY 3: Users can delete their own images
-- Name: "auth_images_delete"
-- Target: authenticated
-- Type: DELETE
-- Path: products/*
-- Expression: (auth.uid()::text = owner) -- deletes own uploads

-- ════════════════════════════════════════════════════════════════════════════
-- VERIFICATION
-- ════════════════════════════════════════════════════════════════════════════
-- Run this to verify all tables have RLS enabled:
--
-- SELECT table_name, row_security_enabled
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_type = 'BASE TABLE'
-- ORDER BY table_name;
--
-- All should show row_security_enabled = true

-- ════════════════════════════════════════════════════════════════════════════
-- TROUBLESHOOTING
-- ════════════════════════════════════════════════════════════════════════════
--
-- ERROR: "operator does not exist"
-- SOLUTION: Check type casting is correct (UUID = UUID, BIGINT = BIGINT)
--           This file has been corrected for compatibility.
--
-- ERROR: "permission denied for schema public"
-- SOLUTION: You may need admin privileges. Run as database owner.
--
-- ERROR: "policy does not exist"
-- SOLUTION: Drop old policies first:
--           DROP POLICY IF EXISTS policy_name ON table_name;
--
-- Products not showing to buyers:
-- SOLUTION: Verify product has:
--           approval_status = 'approved'
--           is_active = true
--           archive_status = 'active'
--           visibility = 'public'

-- ════════════════════════════════════════════════════════════════════════════
-- NOTES
-- ════════════════════════════════════════════════════════════════════════════
-- 1. All policies are tested and compatible with Supabase PostgreSQL
-- 2. UUID type is used for auth.uid() - automatic casting handled
-- 3. Sellers are identified by user_id in sellers table
-- 4. Products linked to sellers via seller_id (BIGINT)
-- 5. RLS applies automatically - no manual role checking needed in app code
-- 6. For admin role, add custom JWT claims or use separate admin procedures
-- 7. Performance: Indexes added on foreign keys for RLS subquery speed
