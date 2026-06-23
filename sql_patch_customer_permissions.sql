-- ============================================================
-- ★ BẢN VÁ BỔ SUNG — chạy sau khi đã chạy database_schema.sql
-- Mục đích: cho phép KHÁCH HÀNG (không chỉ admin) tự tạo đơn hàng,
-- xem sản phẩm, và quản lý giỏ hàng/yêu thích của chính họ.
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Khách đã đăng nhập được TẠO đơn hàng cho chính họ
create policy "Customers create own orders" on public.orders for insert
  with check (auth.uid() = user_id);

-- Khách đã đăng nhập được THÊM order_items cho đơn của chính họ
alter table public.order_items enable row level security;
create policy "Customers create own order_items" on public.order_items for insert
  with check (
    exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
  );
create policy "Customers view own order_items" on public.order_items for select
  using (
    exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
    or auth.role() = 'authenticated'
  );

-- Giỏ hàng: mỗi người chỉ thấy/sửa giỏ của chính mình
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
create policy "Users manage own carts" on public.carts for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own cart_items" on public.cart_items for all
  using (exists (select 1 from public.carts c where c.id = cart_id and c.user_id = auth.uid()));

-- Yêu thích: mỗi người chỉ thấy/sửa mục yêu thích của chính mình
alter table public.favorites enable row level security;
create policy "Users manage own favorites" on public.favorites for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Đánh giá: ai cũng xem được, chỉ chủ đánh giá mới được tạo/sửa
alter table public.reviews enable row level security;
create policy "Public view reviews" on public.reviews for select using (true);
create policy "Customers create own reviews" on public.reviews for insert
  with check (auth.uid() = user_id);

-- Vouchers: ai cũng xem được để áp dụng mã khi thanh toán
alter table public.vouchers enable row level security;
create policy "Public view vouchers" on public.vouchers for select using (true);

-- Bài đăng cộng đồng (nếu dùng tới sau này)
alter table public.posts enable row level security;
alter table public.comments enable row level security;
create policy "Public view posts" on public.posts for select using (true);
create policy "Customers create own posts" on public.posts for insert with check (auth.uid() = user_id);
create policy "Public view comments" on public.comments for select using (true);
create policy "Customers create own comments" on public.comments for insert with check (auth.uid() = user_id);
