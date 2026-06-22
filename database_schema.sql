-- ============================================================
-- DATABASE SCHEMA – DỰ ÁN APP QUÁN NEM
-- ★ Copy TOÀN BỘ file này, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Bật tiện ích tạo UUID
create extension if not exists "uuid-ossp";

-- ============== USERS (mở rộng từ auth.users) ==============
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  email text,
  avatar text,
  birthday date,
  gender text,
  address text,
  level text default 'Thành viên',
  points int default 0,
  role text default 'customer', -- customer | staff | kitchen | shipper | admin
  created_at timestamp with time zone default now()
);

-- ============== CATEGORIES ==============
create table public.categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  icon text
);

-- ============== PRODUCTS ==============
create table public.products (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  price numeric not null default 0,
  sale_price numeric,
  image text,
  category_id uuid references public.categories(id),
  stock int default 0,
  is_hot boolean default false,
  is_new boolean default false,
  created_at timestamp with time zone default now()
);

-- ============== CARTS ==============
create table public.carts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id) on delete cascade,
  created_at timestamp with time zone default now()
);

-- ============== CART_ITEMS ==============
create table public.cart_items (
  id uuid primary key default uuid_generate_v4(),
  cart_id uuid references public.carts(id) on delete cascade,
  product_id uuid references public.products(id),
  quantity int default 1,
  note text
);

-- ============== ORDERS ==============
create table public.orders (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  total_amount numeric not null default 0,
  shipping_fee numeric default 0,
  discount_amount numeric default 0,
  payment_method text,
  status text default 'pending', -- pending | cooking | delivering | done | cancelled
  address text,
  phone text,
  created_at timestamp with time zone default now()
);

-- ============== ORDER_ITEMS ==============
create table public.order_items (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  quantity int default 1,
  price numeric not null
);

-- ============== REVIEWS ==============
create table public.reviews (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  product_id uuid references public.products(id),
  rating int check (rating between 1 and 5),
  content text,
  image text,
  created_at timestamp with time zone default now()
);

-- ============== POSTS (cộng đồng) ==============
create table public.posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  content text,
  image text,
  likes int default 0,
  created_at timestamp with time zone default now()
);

-- ============== COMMENTS ==============
create table public.comments (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.users(id),
  content text,
  created_at timestamp with time zone default now()
);

-- ============== FAVORITES ==============
create table public.favorites (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  product_id uuid references public.products(id)
);

-- ============== NOTIFICATIONS ==============
create table public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  title text,
  content text,
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

-- ============== VOUCHERS ==============
create table public.vouchers (
  id uuid primary key default uuid_generate_v4(),
  code text unique not null,
  discount_type text, -- percent | amount
  discount_value numeric,
  expired_at timestamp with time zone
);

-- ============== USER_VOUCHERS ==============
create table public.user_vouchers (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  voucher_id uuid references public.vouchers(id),
  used boolean default false
);

-- ============== DAILY_REWARDS ==============
create table public.daily_rewards (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  reward_type text,
  reward_value text,
  created_at timestamp with time zone default now()
);

-- ============== SPIN_HISTORY ==============
create table public.spin_history (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  reward text,
  created_at timestamp with time zone default now()
);

-- ============== ACHIEVEMENTS ==============
create table public.achievements (
  id uuid primary key default uuid_generate_v4(),
  name text,
  description text,
  icon text
);

-- ============== USER_ACHIEVEMENTS ==============
create table public.user_achievements (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  achievement_id uuid references public.achievements(id),
  created_at timestamp with time zone default now()
);

-- ============================================================
-- ★ TỰ ĐỘNG TẠO HÀNG TRONG public.users KHI CÓ NGƯỜI ĐĂNG KÝ
-- ============================================================
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, full_name, role)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name', 'customer');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- ★ ROW LEVEL SECURITY (RLS) – BẢO MẬT DỮ LIỆU
-- ============================================================
alter table public.products enable row level security;
alter table public.categories enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.users enable row level security;

-- Ai cũng xem được sản phẩm/danh mục (cho app khách hàng)
create policy "Public can view products" on public.products for select using (true);
create policy "Public can view categories" on public.categories for select using (true);

-- Chỉ admin/staff (đăng nhập qua web admin) mới được thêm/sửa/xóa sản phẩm
create policy "Admin manage products" on public.products for all
  using (auth.role() = 'authenticated');

create policy "Admin manage categories" on public.categories for all
  using (auth.role() = 'authenticated');

-- Người dùng chỉ xem đơn hàng của chính họ; admin (authenticated) xem tất cả
create policy "Users view own orders" on public.orders for select
  using (auth.uid() = user_id or auth.role() = 'authenticated');

create policy "Admin manage orders" on public.orders for update
  using (auth.role() = 'authenticated');

create policy "Users view own profile" on public.users for select
  using (auth.uid() = id or auth.role() = 'authenticated');

-- ============================================================
-- ★ DỮ LIỆU MẪU ĐỂ TEST (xóa sau khi có dữ liệu thật)
-- ============================================================
insert into public.categories (name, icon) values
  ('Nem chua', '🥟'),
  ('Nem rán', '🍤'),
  ('Nem nướng', '🔥'),
  ('Combo', '🍱'),
  ('Đồ uống', '🥤');

insert into public.products (name, description, price, sale_price, category_id, stock, is_hot, is_new)
select 'Nem chua Thanh Hóa', 'Vị chua nhẹ, cay thơm đặc trưng', 35000, 29000, id, 100, true, false
from public.categories where name = 'Nem chua';

insert into public.products (name, description, price, category_id, stock, is_new)
select 'Nem nướng Nha Trang', 'Nem nướng thơm, ăn kèm bánh tráng', 45000, id, 80, true
from public.categories where name = 'Nem nướng';
