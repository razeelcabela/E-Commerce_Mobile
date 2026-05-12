-- ============================================================
-- SCHEMA FIXES
-- Run this ONCE in the Supabase SQL Editor.
--
-- Fixes:
--   1. Adds missing auth_user_id column to sellers table
--   2. Backfills auth_user_id from the users table
--   3. Creates product_variants table (for seller variant feature)
--
-- Safe to re-run — all statements use IF NOT EXISTS / ON CONFLICT guards.
-- ============================================================


-- ── Fix 1: Add auth_user_id to sellers ──────────────────────────────────────
-- This column was missing, causing "column s.auth_user_id does not exist"
-- in SELLER_ACCESS_FIX.sql and ADMIN_RLS_MIGRATION.sql.

ALTER TABLE sellers
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id);


-- ── Fix 2: Backfill auth_user_id from the users table ───────────────────────
-- For any existing seller rows where auth_user_id was never written,
-- pull the UUID from the matching users row via the user_id FK.

UPDATE sellers s
SET    auth_user_id = u.auth_user_id
FROM   users u
WHERE  s.user_id       = u.id
  AND  s.auth_user_id  IS NULL;


-- ── Fix 3: Add insert policy for sellers (needed for applyAsSeller) ──────────
-- Without this, INSERT into sellers is blocked by RLS for authenticated users.

DROP POLICY IF EXISTS "sellers_self_insert" ON sellers;

CREATE POLICY "sellers_self_insert" ON sellers
  FOR INSERT TO authenticated
  WITH CHECK (auth_user_id = auth.uid());


-- ── Fix 4: Create product_variants table ────────────────────────────────────
-- Stores per-variant stock (color, size, or combination).
-- Cascades delete when the parent product is deleted.

CREATE TABLE IF NOT EXISTS product_variants (
  id         BIGSERIAL PRIMARY KEY,
  product_id BIGINT      NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  color      TEXT,
  size       TEXT,
  stock      INTEGER     NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, color, size)
);

-- Index so lookups by product_id are fast
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id
  ON product_variants(product_id);


-- ── Fix 5: RLS for product_variants ─────────────────────────────────────────

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Buyers / public: read variants of approved products
DROP POLICY IF EXISTS "variants_public_read" ON product_variants;
CREATE POLICY "variants_public_read" ON product_variants
  FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM products p
      WHERE  p.id              = product_variants.product_id
        AND  p.approval_status = 'approved'
        AND  p.is_active       = true
        AND  p.archive_status  = 'active'
    )
    OR EXISTS (
      SELECT 1 FROM products p
      JOIN   sellers s ON s.id = p.seller_id
      WHERE  p.id          = product_variants.product_id
        AND  s.auth_user_id = auth.uid()
    )
  );

-- Sellers: insert / update / delete their own variants
DROP POLICY IF EXISTS "variants_seller_write" ON product_variants;
CREATE POLICY "variants_seller_write" ON product_variants
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM products p
      JOIN   sellers s ON s.id = p.seller_id
      WHERE  p.id          = product_variants.product_id
        AND  s.auth_user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM products p
      JOIN   sellers s ON s.id = p.seller_id
      WHERE  p.id          = product_variants.product_id
        AND  s.auth_user_id = auth.uid()
    )
  );


-- ── Verify ────────────────────────────────────────────────────────────────────
-- After running, confirm with:

SELECT column_name, data_type
FROM   information_schema.columns
WHERE  table_name = 'sellers'
  AND  column_name = 'auth_user_id';

-- Should return one row: auth_user_id | uuid

SELECT tablename, policyname, cmd
FROM   pg_policies
WHERE  schemaname = 'public'
  AND  tablename IN ('sellers', 'product_variants')
ORDER  BY tablename, policyname;
