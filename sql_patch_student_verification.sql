-- ============================================================
-- ★ XÁC MINH SINH VIÊN — chặn đặt "Combo Sinh viên" nếu chưa
-- được admin duyệt thẻ sinh viên + tuổi. Chặn ở tầng DATABASE
-- nên không thể bị lách qua bằng cách gọi API trực tiếp.
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Thêm cột lưu trạng thái xác minh + đường dẫn ảnh thẻ sinh viên
alter table public.users add column if not exists student_verification_status text default 'none';
-- Giá trị: 'none' (chưa nộp) | 'pending' (đang chờ duyệt) | 'approved' (đã duyệt) | 'rejected' (bị từ chối)
alter table public.users add column if not exists student_id_image text;
alter table public.users add column if not exists student_verification_note text; -- lý do từ chối (nếu có)

-- ============================================================
-- TẠO BUCKET LƯU ẢNH THẺ SINH VIÊN (riêng tư, không công khai)
-- ============================================================
insert into storage.buckets (id, name, public)
values ('student-ids', 'student-ids', false)
on conflict (id) do nothing;

-- Khách chỉ được upload vào đúng thư mục mang tên user_id của chính họ
drop policy if exists "Users upload own student id" on storage.objects;
create policy "Users upload own student id" on storage.objects for insert
  with check (
    bucket_id = 'student-ids'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Khách xem được ảnh của chính họ; Admin xem được ảnh của tất cả (để duyệt)
drop policy if exists "View own or admin student id" on storage.objects;
create policy "View own or admin student id" on storage.objects for select
  using (
    bucket_id = 'student-ids'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (select 1 from public.users u where u.id = auth.uid() and u.role = 'admin')
    )
  );

-- ============================================================
-- CHẶN THẬT — không cho thêm "Combo Sinh viên" vào đơn hàng nếu
-- tài khoản chưa được duyệt (status khác 'approved')
-- ============================================================
create or replace function public.check_student_combo_order()
returns trigger as $$
declare
  cat_name text;
  user_status text;
begin
  select c.name into cat_name
  from public.products p
  join public.categories c on c.id = p.category_id
  where p.id = NEW.product_id;

  if cat_name = 'Combo Sinh viên' then
    select u.student_verification_status into user_status
    from public.orders o
    join public.users u on u.id = o.user_id
    where o.id = NEW.order_id;

    if user_status is distinct from 'approved' then
      raise exception 'STUDENT_VERIFICATION_REQUIRED';
    end if;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_check_student_combo on public.order_items;
create trigger trg_check_student_combo
  before insert on public.order_items
  for each row execute procedure public.check_student_combo_order();

-- Cho phép khách tự cập nhật hồ sơ của chính họ (nộp ảnh thẻ, ngày sinh)
drop policy if exists "Users update own profile" on public.users;
create policy "Users update own profile" on public.users for update
  using (auth.uid() = id);
