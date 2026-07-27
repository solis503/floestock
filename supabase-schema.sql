-- =====================================================
-- FLOWSTOCK PRO v3 - Esquema Completo para Supabase
-- =====================================================
-- EJECUTA ESTE ARCHIVO COMPLETO EN EL SQL EDITOR DE SUPABASE
-- =====================================================

-- 1. NEGOCIOS
CREATE TABLE IF NOT EXISTS businesses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  name TEXT NOT NULL,
  currency_symbol TEXT DEFAULT '$',
  tax_percentage DECIMAL(5,2) DEFAULT 13.00,
  loyalty_points_rate DECIMAL(5,2) DEFAULT 10.00,
  loyalty_discount DECIMAL(5,2) DEFAULT 10.00,
  loyalty_points_for_discount INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. SUCURSALES
CREATE TABLE IF NOT EXISTS branches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PERFILES / ROLES
CREATE TABLE IF NOT EXISTS profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  role TEXT NOT NULL DEFAULT 'seller' CHECK (role IN ('owner','manager','seller')),
  full_name TEXT,
  email TEXT,
  phone TEXT,
  language TEXT DEFAULT 'es' CHECK (language IN ('es','en')),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, business_id)
);

-- 4. CATEGORÍAS
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. PRODUCTOS (con tipos: simple, insumo, receta)
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  cost DECIMAL(10,2) DEFAULT 0,
  stock DECIMAL(10,2) NOT NULL DEFAULT 0,
  min_stock DECIMAL(10,2) DEFAULT 5,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  unit TEXT DEFAULT 'piezas' CHECK (unit IN ('piezas','kg','litros','cajas')),
  product_type TEXT DEFAULT 'simple' CHECK (product_type IN ('simple','insumo','receta')),
  is_sellable BOOLEAN DEFAULT TRUE,
  barcode TEXT,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. RECETAS (ingredientes de un producto compuesto)
CREATE TABLE IF NOT EXISTS recipe_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  ingredient_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  quantity DECIMAL(10,3) NOT NULL DEFAULT 1,
  unit TEXT DEFAULT 'piezas',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. PROVEEDORES
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT,
  email TEXT,
  category TEXT,
  notes TEXT,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. ÓRDENES DE COMPRA
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pendiente' CHECK (status IN ('pendiente','recibida','cancelada')),
  total DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES purchase_orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  received BOOLEAN DEFAULT FALSE
);

-- 9. CLIENTES
CREATE TABLE IF NOT EXISTS clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  loyalty_points INTEGER DEFAULT 0,
  credit_balance DECIMAL(10,2) DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. VENTAS
CREATE TABLE IF NOT EXISTS sales (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  total DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('efectivo','tarjeta','transferencia')),
  amount_paid DECIMAL(10,2),
  change_amount DECIMAL(10,2) DEFAULT 0,
  points_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. DETALLES DE VENTA
CREATE TABLE IF NOT EXISTS sale_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  product_name TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- 12. MOVIMIENTOS DE INVENTARIO
CREATE TABLE IF NOT EXISTS inventory_movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('entrada','salida','venta','transferencia')),
  quantity DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. GASTOS
CREATE TABLE IF NOT EXISTS expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  concept TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category TEXT DEFAULT 'Otros',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. NOTIFICACIONES
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('stock_low','sale','expense','system')),
  title TEXT NOT NULL,
  message TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- SEGURIDAD: Row Level Security
-- =====================================================
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Función helper: obtener IDs de negocio del usuario
CREATE OR REPLACE FUNCTION get_user_business_ids(p_user_id UUID)
RETURNS TABLE(business_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT b.id FROM businesses b WHERE b.owner_id = p_user_id
  UNION
  SELECT p.business_id FROM profiles p WHERE p.user_id = p_user_id AND p.active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Políticas para TODAS las tablas (acceso por negocio)
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['branches','categories','products','suppliers','purchase_orders','clients','sales','inventory_movements','expenses','notifications']
  LOOP
    EXECUTE format('CREATE POLICY "Miembros ven %I" ON %I FOR ALL USING (business_id IN (SELECT get_user_business_ids(auth.uid())))', tbl, tbl);
  END LOOP;
END $$;

-- Políticas especiales
CREATE POLICY "Usuarios ven su negocio" ON businesses FOR ALL USING (
  auth.uid() = owner_id OR auth.uid() IN (SELECT user_id FROM profiles WHERE business_id = businesses.id AND active = TRUE)
);
CREATE POLICY "Miembros ven perfiles" ON profiles FOR ALL USING (
  business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid()) OR user_id = auth.uid()
);
CREATE POLICY "Miembros ven recetas" ON recipe_items FOR ALL USING (
  product_id IN (SELECT id FROM products WHERE business_id IN (SELECT get_user_business_ids(auth.uid())))
);
CREATE POLICY "Miembros ven items venta" ON sale_items FOR ALL USING (
  sale_id IN (SELECT id FROM sales WHERE business_id IN (SELECT get_user_business_ids(auth.uid())))
);
CREATE POLICY "Miembros ven items orden" ON purchase_order_items FOR ALL USING (
  order_id IN (SELECT id FROM purchase_orders WHERE business_id IN (SELECT get_user_business_ids(auth.uid())))
);

-- =====================================================
-- FUNCIONES
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Crear negocio + sucursal + perfil owner al registrarse
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE new_biz UUID; new_branch UUID;
BEGIN
  INSERT INTO businesses (owner_id, name) VALUES (NEW.id, 'Mi Negocio') RETURNING id INTO new_biz;
  INSERT INTO branches (business_id, name) VALUES (new_biz, 'Sucursal Principal') RETURNING id INTO new_branch;
  INSERT INTO profiles (user_id, business_id, branch_id, role, full_name, email)
  VALUES (NEW.id, new_biz, new_branch, 'owner', COALESCE(NEW.raw_user_meta_data->>'full_name',''), NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Decrementar stock
CREATE OR REPLACE FUNCTION decrement_stock(p_product_id UUID, p_quantity DECIMAL)
RETURNS VOID AS $$ BEGIN
  UPDATE products SET stock = stock - p_quantity WHERE id = p_product_id AND stock >= p_quantity;
END; $$ LANGUAGE plpgsql;

-- Decrementar receta recursivamente
CREATE OR REPLACE FUNCTION decrement_recipe(p_product_id UUID, p_multiplier DECIMAL)
RETURNS VOID AS $$
DECLARE ing RECORD;
BEGIN
  FOR ing IN SELECT ingredient_id, quantity FROM recipe_items WHERE product_id = p_product_id
  LOOP
    PERFORM decrement_stock(ing.ingredient_id, ing.quantity * p_multiplier);
    -- Recursivo si el ingrediente es también receta
    IF EXISTS (SELECT 1 FROM products WHERE id = ing.ingredient_id AND product_type = 'receta') THEN
      PERFORM decrement_recipe(ing.ingredient_id, ing.quantity * p_multiplier);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Obtener rol del usuario
CREATE OR REPLACE FUNCTION get_user_role(p_user_id UUID, p_business_id UUID)
RETURNS TEXT AS $$
DECLARE v_role TEXT;
BEGIN
  IF EXISTS (SELECT 1 FROM businesses WHERE id = p_business_id AND owner_id = p_user_id) THEN RETURN 'owner'; END IF;
  SELECT role INTO v_role FROM profiles WHERE user_id = p_user_id AND business_id = p_business_id AND active = TRUE;
  RETURN COALESCE(v_role, 'none');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
