-- ============================================================
-- SELLER ACCESS FIX
-- Run this in Supabase SQL Editor to fix "No seller profile found" error
--
-- Root cause: sellers table had a broken RLS policy comparing
--   sellers.user_id (BIGINT) to auth.uid() (UUID) — always throws a type error,
--   blocking ALL reads from the sellers table for every authenticated user.
-- ============================================================


-- Step 1: Drop ALL existing SELECT policies on sellers (regardless of name)
DO $$
DECLARE
  pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'sellers'
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON sellers', pol);
  END LOOP;
END $$;


-- Step 2: Create correct sellers read policy (auth_user_id is UUID — matches auth.uid())
CREATE POLICY "sellers_own_profile_read" ON sellers
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());


-- Step 3: Backfill sellers.auth_user_id from users table for any existing sellers
--         where auth_user_id was never set (NULL)
UPDATE sellers s
SET auth_user_id = u.auth_user_id
FROM users u
WHERE s.user_id = u.id
  AND s.auth_user_id IS NULL;


-- Step 4: Ensure users table read policy works (needed for role determination)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_self_read" ON users;

CREATE POLICY "users_self_read" ON users
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());


-- Verify — run after the above to confirm policies are in place:
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('sellers', 'users')
ORDER BY tablename, cmd, policyname;
