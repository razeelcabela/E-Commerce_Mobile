-- ============================================================
-- Product Approval System Migration
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Add new columns to the products table
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS rejection_reason  TEXT,
  ADD COLUMN IF NOT EXISTS delivery_options  TEXT NOT NULL DEFAULT 'delivery',
  ADD COLUMN IF NOT EXISTS condition         TEXT NOT NULL DEFAULT 'new';

-- 2. Create the notifications table for seller alerts
CREATE TABLE IF NOT EXISTS notifications (
  id          BIGSERIAL    PRIMARY KEY,
  seller_id   BIGINT       NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  type        TEXT         NOT NULL DEFAULT 'info',
  title       TEXT         NOT NULL,
  message     TEXT         NOT NULL,
  product_id  BIGINT       REFERENCES products(id) ON DELETE SET NULL,
  is_read     BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 3. Enable Row-Level Security on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 4. Sellers can read their own notifications
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications'
      AND policyname = 'sellers_read_own_notifications'
  ) THEN
    CREATE POLICY sellers_read_own_notifications ON notifications
      FOR SELECT TO authenticated
      USING (
        seller_id IN (
          SELECT id FROM sellers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- 5. Any authenticated user (admin) can insert notifications
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications'
      AND policyname = 'authenticated_insert_notifications'
  ) THEN
    CREATE POLICY authenticated_insert_notifications ON notifications
      FOR INSERT TO authenticated
      WITH CHECK (true);
  END IF;
END $$;

-- 6. Sellers can update (mark as read) their own notifications
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications'
      AND policyname = 'sellers_update_own_notifications'
  ) THEN
    CREATE POLICY sellers_update_own_notifications ON notifications
      FOR UPDATE TO authenticated
      USING (
        seller_id IN (
          SELECT id FROM sellers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- 7. Index for fast seller notification lookups
CREATE INDEX IF NOT EXISTS idx_notifications_seller_id
  ON notifications(seller_id, created_at DESC);
