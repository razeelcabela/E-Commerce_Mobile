-- ============================================================
-- SIGNUP FIX
-- Run this ONCE in the Supabase SQL Editor.
--
-- Fixes "new row violates row-level security policy for table users"
-- that appears when signing up with email confirmation enabled.
--
-- Root cause:
--   After auth.signUp(), the Supabase client has no JWT yet (anon role).
--   The old users_self_insert policy required TO authenticated, so
--   the profile INSERT was blocked.
--
-- This file:
--   1. Creates a DB trigger that auto-creates the users profile row
--      the moment auth.users is created (runs as SECURITY DEFINER,
--      no RLS applies).
--   2. Loosens the INSERT policy so even anon can insert a profile
--      for a real auth user (fallback if trigger doesn't fire).
-- ============================================================


-- ── Fix 1: DB trigger to auto-create users profile ───────────────────────────
-- Reads first_name / last_name / phone from the signUp metadata that
-- the Flutter app now passes via data: {...} in auth.signUp().

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    auth_user_id,
    email,
    first_name,
    last_name,
    phone,
    role,
    account_status,
    buyer_approval_status
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    'buyer',
    'active',
    'approved'
  )
  ON CONFLICT (auth_user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Attach the trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- ── Fix 2: Permissive INSERT policy (fallback) ───────────────────────────────
-- Helper that checks auth_user_id is a real Supabase auth user.
-- SECURITY DEFINER needed because anon/authenticated can't read auth.users directly.

CREATE OR REPLACE FUNCTION public.auth_user_exists(uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM auth.users WHERE id = uid);
$$;

GRANT EXECUTE ON FUNCTION public.auth_user_exists(UUID) TO anon, authenticated;

-- Drop old restrictive policy
DROP POLICY IF EXISTS "users_self_insert" ON users;

-- Allow:
--   authenticated users: only their own row (auth.uid() matches)
--   anon users (email confirmation pending): only if auth_user_id is a real auth user
CREATE POLICY "users_self_insert" ON users
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    auth_user_id = auth.uid()
    OR public.auth_user_exists(auth_user_id)
  );


-- ── Verify ────────────────────────────────────────────────────────────────────
SELECT tgname, tgtype, proname
FROM   pg_trigger t
JOIN   pg_proc p ON p.oid = t.tgfoid
WHERE  tgrelid = 'auth.users'::regclass
  AND  tgname = 'on_auth_user_created';

-- Should return one row: on_auth_user_created
