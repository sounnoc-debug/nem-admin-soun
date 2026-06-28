-- ============================================================
-- ★★★ VÁ BẢO MẬT KHẨN CẤP — chạy ngay, càng sớm càng tốt ★★★
-- Sửa lỗi: nhiều luật bảo mật trước đây dùng auth.role()='authenticated'
-- để chỉ định "admin", nhưng điều kiện đó đúng với MỌI khách đã đăng
-- nhập, không riêng admin. Bản vá này thay bằng kiểm tra ĐÚNG vai trò.
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Hàm kiểm tra: người gọi có đúng là admin không
create or replace function public.is_admin()
returns boolean as $$
  select exists (select 1 from public.users where id = auth.uid() and role = 'admin');
$$ language sql security definer stable;

-- Hàm kiểm tra: người gọi có thuộc nhóm vận hành đơn hàng không
-- (admin/staff/kitchen/shipper — những vai trò cần xem/đổi trạng thái đơn)
create or replace function public.is_order_staff()
returns boolean as $$
  select exists (select 1 from public.users where id = auth.uid() and role in ('admin','staff','kitchen','shipper'));
$$ language sql security definer stable;

-- ============================================================
-- SẢN PHẨM — chỉ admin được thêm/sửa/xóa
-- ============================================================
drop policy if exists "Admin manage products" on public.products;
create policy "Admin manage products" on public.products for all
  using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- DANH MỤC — chỉ admin được thêm/sửa/xóa
-- ============================================================
drop policy if exists "Admin manage categories" on public.categories;
create policy "Admin manage categories" on public.categories for all
  using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- VOUCHER — chỉ admin được tạo/sửa/xóa
-- ============================================================
drop policy if exists "Admin manage vouchers" on public.vouchers;
create policy "Admin manage vouchers" on public.vouchers for all
  using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- BẬC HẠNG — chỉ admin được sửa
-- ============================================================
drop policy if exists "Admin manage rank_tiers" on public.rank_tiers;
create policy "Admin manage rank_tiers" on public.rank_tiers for all
  using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- ĐƠN HÀNG — chỉ chủ đơn hoặc nhóm vận hành (admin/staff/kitchen/
-- shipper) mới XEM được; chỉ nhóm vận hành mới ĐỔI được trạng thái
-- ============================================================
drop policy if exists "Users view own orders" on public.orders;
create policy "Users view own orders" on public.orders for select
  using (auth.uid() = user_id or public.is_order_staff());

drop policy if exists "Admin manage orders" on public.orders;
create policy "Staff update orders" on public.orders for update
  using (public.is_order_staff()) with check (public.is_order_staff());

-- ============================================================
-- ORDER_ITEMS — chỉ chủ đơn hoặc nhóm vận hành mới XEM được
-- ============================================================
drop policy if exists "Customers view own order_items" on public.order_items;
create policy "View own or staff order_items" on public.order_items for select
  using (
    exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
    or public.is_order_staff()
  );

-- ============================================================
-- HỒ SƠ KHÁCH HÀNG — chỉ chính chủ hoặc ADMIN (không phải mọi
-- người đã đăng nhập) mới xem được hồ sơ người khác
-- ============================================================
drop policy if exists "Users view own profile" on public.users;
create policy "Users view own profile" on public.users for select
  using (auth.uid() = id or public.is_admin());

-- ============================================================
-- CHẶN TỰ NÂNG QUYỀN / TỰ DUYỆT — khách không được tự đổi role,
-- hạng, điểm, dấu Passport, hoặc tự đặt trạng thái xác minh sinh
-- viên thành "approved". Vẫn cho khách tự nộp hồ sơ (chuyển sang
-- "pending") và các trigger nội bộ (Nem Passport, tính hạng...)
-- vẫn hoạt động bình thường.
-- ============================================================
create or replace function public.protect_sensitive_user_fields()
returns trigger as $$
declare
  caller_role text;
begin
  -- Nếu lệnh này đang chạy TỪ BÊN TRONG 1 trigger khác (vd: hàm tự
  -- động tính hạng/Passport khi đơn hoàn tất) thì luôn cho phép.
  if pg_trigger_depth() > 0 then
    return NEW;
  end if;

  -- Lệnh chạy trong SQL Editor / service role (không có người dùng
  -- đăng nhập cụ thể) -> tin tưởng, không chặn
  if auth.uid() is null then
    return NEW;
  end if;

  select role into caller_role from public.users where id = auth.uid();

  if caller_role is distinct from 'admin' then
    NEW.role := OLD.role;
    NEW.level := OLD.level;
    NEW.points := OLD.points;
    NEW.passport_stamps := OLD.passport_stamps;
    NEW.passport_total_completed := OLD.passport_total_completed;

    -- Cho khách tự nộp xác minh (chuyển sang "pending"), nhưng
    -- KHÔNG cho tự đặt thành "approved"
    if NEW.student_verification_status = 'approved' and OLD.student_verification_status is distinct from 'approved' then
      NEW.student_verification_status := OLD.student_verification_status;
      NEW.student_verification_note := OLD.student_verification_note;
    end if;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_user_fields on public.users;
create trigger trg_protect_user_fields
  before update on public.users
  for each row execute procedure public.protect_sensitive_user_fields();
