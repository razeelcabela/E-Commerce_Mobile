-- ============================================================
-- BUYER-SELLER VISIBILITY FIX
-- Run this ONCE in the Supabase SQL Editor.
--
-- ROOT CAUSE:
--   ADMIN_RLS_MIGRATION.sql dropped all public SELECT policies on
--   the sellers table and replaced them with sellers_own_profile_read
--   (auth_user_id = auth.uid() OR is_admin()).
--   Buyers have neither — so every sellers query from the buyer app
--   returns 0 rows silently. Seller names/stores are always blank.
--
-- THIS FILE:
--   1. Adds a public-read policy so buyers can see seller store info.
--   2. Adds missing optional profile columns (logo_url, banner_url,
--      store_description) if they don't already exist.
--   3. Back-fills logo_url from avatar_url where applicable.
-- ============================================================


-- ── Step 1: Add optional seller profile columns ──────────────────────────────
-- Harmless if columns already exist (IF NOT EXISTS guard).

ALTER TABLE sellers ADD COLUMN IF NOT EXISTS logo_url          TEXT;
ALTER TABLE sellers ADD COLUMN IF NOT EXISTS banner_url         TEXT;
ALTER TABLE sellers ADD COLUMN IF NOT EXISTS store_description  TEXT;

-- Back-fill logo_url from avatar_url (schema naming inconsistency fix)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sellers' AND column_name = 'avatar_url'
  ) THEN
    UPDATE sellers
    SET    logo_url = avatar_url
    WHERE  logo_url IS NULL AND avatar_url IS NOT NULL;
  END IF;
END $$;


-- ── Step 2: Drop stale anon/public read policies ─────────────────────────────

DROP POLICY IF EXISTS "sellers_public_read"     ON sellers;
DROP POLICY IF EXISTS "sellers_anon_read"        ON sellers;
DROP POLICY IF EXISTS "sellers_auth_read_active" ON sellers;


-- ── Step 3: Add public read policy (THE CRITICAL FIX) ────────────────────────
-- Allows buyers (authenticated) and unauthenticated users (anon) to read
-- seller store profiles. Required for the buyer marketplace to show store
-- names, logos, and store pages.

CREATE POLICY "sellers_public_read" ON sellers
  FOR SELECT
  TO anon, authenticated
  USING (true);


-- ── Step 4: Verify ────────────────────────────────────────────────────────────
SELECT policyname, roles::text, cmd, qual
FROM   pg_policies
WHERE  schemaname = 'public'
  AND  tablename  = 'sellers'
ORDER  BY policyname;

-- Expected output should include "sellers_public_read" with roles {anon,authenticated}
