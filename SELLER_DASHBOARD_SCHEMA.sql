-- ============================================================================
-- SELLER DASHBOARD DATABASE SCHEMA
-- ============================================================================
-- This schema provides the complete table structure for a multi-seller
-- e-commerce platform with products, inventory, orders, and reviews.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. USERS & SELLER PROFILES
-- ────────────────────────────────────────────────────────────────────────────

-- auth.users is managed by Supabase Auth
-- Additional seller profile information
CREATE TABLE IF NOT EXISTS sellers (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  store_name VARCHAR(255) NOT NULL,
  business_name VARCHAR(255),
  description TEXT,
  phone VARCHAR(20),
  address TEXT,
  avatar_url TEXT,
  banner_url TEXT,
  rating DECIMAL(3,2) DEFAULT 0,
  total_sales INT DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'pending', 'suspended', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sellers_user_id (user_id),
  INDEX idx_sellers_status (status),
  INDEX idx_sellers_created_at (created_at)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. CATEGORIES
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS categories (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name VARCHAR(255) UNIQUE NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  parent_id BIGINT REFERENCES categories(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  position INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_categories_slug (slug),
  INDEX idx_categories_is_active (is_active),
  INDEX idx_categories_parent_id (parent_id)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 3. PRODUCTS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS products (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  seller_id BIGINT NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  category_id BIGINT REFERENCES categories(id) ON DELETE SET NULL,
  name VARCHAR(500) NOT NULL,
  slug VARCHAR(500) UNIQUE NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  sku VARCHAR(100),
  approval_status VARCHAR(50) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  is_active BOOLEAN DEFAULT true,
  archive_status VARCHAR(50) DEFAULT 'active' CHECK (archive_status IN ('active', 'archived')),
  visibility VARCHAR(50) DEFAULT 'public' CHECK (visibility IN ('public', 'private')),
  metadata JSONB, -- For extensibility (color, size, specs, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_products_seller_id (seller_id),
  INDEX idx_products_category_id (category_id),
  INDEX idx_products_approval_status (approval_status),
  INDEX idx_products_is_active (is_active),
  INDEX idx_products_created_at (created_at),
  INDEX idx_products_slug (slug)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 4. PRODUCT IMAGES
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS product_images (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL, -- Path in Supabase Storage
  position INT DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,
  alt_text VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_product_images_product_id (product_id),
  INDEX idx_product_images_is_primary (is_primary)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 5. INVENTORY TRANSACTIONS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS inventory_transactions (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  seller_id BIGINT NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  quantity_change INT NOT NULL,
  reason VARCHAR(100) NOT NULL CHECK (reason IN ('add', 'sale', 'return', 'adjustment', 'damaged')),
  reference_id BIGINT, -- order_id, return_id, etc.
  reference_type VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_inventory_product_id (product_id),
  INDEX idx_inventory_seller_id (seller_id),
  INDEX idx_inventory_created_at (created_at)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 6. CARTS (for buyers)
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS carts (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS cart_items (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  cart_id BIGINT NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(cart_id, product_id),
  INDEX idx_cart_items_cart_id (cart_id)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 7. ORDERS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  seller_id BIGINT NOT NULL REFERENCES sellers(id) ON DELETE RESTRICT,
  total_amount DECIMAL(12,2) NOT NULL,
  tax DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(12,2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
  payment_status VARCHAR(50) DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
  payment_method VARCHAR(100),
  tracking_number VARCHAR(255),
  shipping_address TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_orders_user_id (user_id),
  INDEX idx_orders_seller_id (seller_id),
  INDEX idx_orders_status (status),
  INDEX idx_orders_created_at (created_at)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 8. ORDER ITEMS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS order_items (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE SET NULL,
  product_name VARCHAR(500) NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_order_items_order_id (order_id)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 9. REVIEWS & RATINGS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  order_item_id BIGINT REFERENCES order_items(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  comment TEXT,
  helpful_count INT DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_reviews_product_id (product_id),
  INDEX idx_reviews_user_id (user_id),
  INDEX idx_reviews_status (status),
  INDEX idx_reviews_created_at (created_at)
);

-- ────────────────────────────────────────────────────────────────────────────
-- 10. SELLER ANALYTICS (denormalized for performance)
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS seller_daily_stats (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  seller_id BIGINT NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  orders_count INT DEFAULT 0,
  sales_amount DECIMAL(12,2) DEFAULT 0,
  views_count INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(seller_id, date),
  INDEX idx_seller_daily_stats_seller_id (seller_id),
  INDEX idx_seller_daily_stats_date (date)
);

-- ════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ════════════════════════════════════════════════════════════════════════════

-- Update product updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_updated_at_trigger
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_product_updated_at();

-- Update seller updated_at timestamp
CREATE OR REPLACE FUNCTION update_seller_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER seller_updated_at_trigger
BEFORE UPDATE ON sellers
FOR EACH ROW
EXECUTE FUNCTION update_seller_updated_at();

-- ════════════════════════════════════════════════════════════════════════════
-- NOTES
-- ════════════════════════════════════════════════════════════════════════════
-- 1. All timestamps use "TIMESTAMP WITH TIME ZONE" for proper timezone handling
-- 2. Indexes created on frequently queried columns for performance
-- 3. Foreign keys include ON DELETE CASCADE/RESTRICT/SET NULL as appropriate
-- 4. CHECKs ensure data integrity (e.g., price >= 0, rating BETWEEN 1 AND 5)
-- 5. This schema supports multi-seller, multi-category e-commerce
-- 6. See SELLER_DASHBOARD_RLS_POLICIES.sql for row-level security
