-- ============================================================
-- ★ HẠNG KHÁCH HÀNG + HUY HIỆU + VOUCHER THEO TUẦN/THÁNG
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- ============================================================
-- BẢNG BẬC HẠNG — khoảng cách giữa các hạng CỐ Ý nới rộng dần
-- (không tăng đều) để hạng cao thật sự khó đạt, không phải ai
-- cũng lên hạng dễ dàng. Admin chỉnh số tiền tại đây hoặc qua
-- trang "Hạng & Huy hiệu" trong web admin.
-- ============================================================
create table if not exists public.rank_tiers (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  min_spend numeric not null,        -- tổng chi tiêu lũy kế (đơn đã hoàn tất) để đạt hạng này
  icon text,
  weekly_voucher_value numeric default 0,   -- giá trị voucher được tặng MỖI TUẦN nếu đang giữ hạng này
  monthly_voucher_value numeric default 0,  -- giá trị voucher được tặng MỖI THÁNG nếu đang giữ hạng này
  sort_order int default 0
);

insert into public.rank_tiers (name, min_spend, icon, weekly_voucher_value, monthly_voucher_value, sort_order) values
  ('Thành viên',   0,         '🥉', 0,      0,      1),
  ('Thân thiết',   500000,    '🥈', 10000,  30000,  2),   -- cách hạng trước: 500k
  ('Vàng',         1500000,   '🥇', 20000,  60000,  3),   -- cách hạng trước: 1 triệu (gấp 2x khoảng trước)
  ('Kim Cương',    4000000,   '💎', 40000,  120000, 4),   -- cách hạng trước: 2.5 triệu
  ('Huyền thoại',  10000000,  '👑', 80000,  250000, 5)    -- cách hạng trước: 6 triệu — rất khó đạt
on conflict (name) do nothing;

alter table public.rank_tiers enable row level security;
drop policy if exists "Public view rank_tiers" on public.rank_tiers;
create policy "Public view rank_tiers" on public.rank_tiers for select using (true);
drop policy if exists "Admin manage rank_tiers" on public.rank_tiers;
create policy "Admin manage rank_tiers" on public.rank_tiers for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================================
-- HUY HIỆU MẶC ĐỊNH
-- ============================================================
insert into public.achievements (name, description, icon) values
  ('Người yêu nem', 'Hoàn tất đơn hàng đầu tiên', '🥟'),
  ('Fan cứng', 'Hoàn tất 10 đơn hàng', '🔥'),
  ('Khách thân thiết', 'Đạt hạng Thân thiết', '🥈'),
  ('Khách Vàng', 'Đạt hạng Vàng', '🥇'),
  ('Khách Kim Cương', 'Đạt hạng Kim Cương', '💎'),
  ('Huyền thoại quán nem', 'Đạt hạng Huyền thoại — cấp bậc cao nhất', '👑')
on conflict (name) do nothing;

alter table public.achievements enable row level security;
drop policy if exists "Public view achievements" on public.achievements;
create policy "Public view achievements" on public.achievements for select using (true);

alter table public.user_achievements enable row level security;
drop policy if exists "Users view own user_achievements" on public.user_achievements;
create policy "Users view own user_achievements" on public.user_achievements for select
  using (auth.uid() = user_id);

-- ============================================================
-- HÀM TÍNH LẠI HẠNG dựa trên tổng chi tiêu (đơn đã hoàn tất)
-- ============================================================
create or replace function public.recompute_user_rank(p_user_id uuid)
returns text as $$
declare
  total_spend numeric;
  tier_name text;
begin
  select coalesce(sum(total_amount), 0) into total_spend
  from public.orders where user_id = p_user_id and status = 'done';

  select name into tier_name
  from public.rank_tiers
  where min_spend <= total_spend
  order by min_spend desc
  limit 1;

  update public.users set level = tier_name where id = p_user_id;
  return tier_name;
end;
$$ language plpgsql security definer;

-- ============================================================
-- HÀM TẶNG HUY HIỆU (không tặng lại nếu đã có)
-- ============================================================
create or replace function public.grant_achievement(p_user_id uuid, p_name text)
returns void as $$
declare
  ach_id uuid;
begin
  select id into ach_id from public.achievements where name = p_name;
  if ach_id is not null then
    insert into public.user_achievements (user_id, achievement_id)
    select p_user_id, ach_id
    where not exists (
      select 1 from public.user_achievements where user_id = p_user_id and achievement_id = ach_id
    );
  end if;
end;
$$ language plpgsql security definer;

-- ============================================================
-- CẬP NHẬT LẠI HÀM XỬ LÝ "ĐƠN HOÀN TẤT" — gộp chung: Nem Passport
-- (đã có từ trước) + tính lại hạng + tự tặng huy hiệu mốc
-- ============================================================
create or replace function public.handle_order_done()
returns trigger as $$
declare
  current_stamps int;
  new_voucher_id uuid;
  voucher_code text;
  total_completed int;
  new_level text;
begin
  if NEW.status = 'done' and (OLD.status is distinct from 'done') then

    -- ---- Nem Passport (giữ nguyên logic cũ) ----
    update public.users
    set passport_stamps = passport_stamps + 1,
        passport_total_completed = passport_total_completed + 1
    where id = NEW.user_id
    returning passport_stamps, passport_total_completed into current_stamps, total_completed;

    if current_stamps >= 10 then
      voucher_code := 'PASSPORT' || to_char(now(), 'YYYYMMDDHH24MISS') || substr(NEW.user_id::text, 1, 4);
      insert into public.vouchers (code, discount_type, discount_value, expired_at, is_personal)
      values (voucher_code, 'amount', 30000, now() + interval '30 days', true)
      returning id into new_voucher_id;
      insert into public.user_vouchers (user_id, voucher_id, used) values (NEW.user_id, new_voucher_id, false);
      insert into public.notifications (user_id, title, content, is_read)
      values (NEW.user_id, '🎉 Bạn đã hoàn thành Nem Passport!',
        'Bạn nhận voucher ' || voucher_code || ' giảm 30.000đ.', false);
      update public.users set passport_stamps = 0 where id = NEW.user_id;
    end if;

    -- ---- Huy hiệu theo số đơn ----
    if total_completed = 1 then perform public.grant_achievement(NEW.user_id, 'Người yêu nem'); end if;
    if total_completed = 10 then perform public.grant_achievement(NEW.user_id, 'Fan cứng'); end if;

    -- ---- Tính lại hạng theo tổng chi tiêu ----
    new_level := public.recompute_user_rank(NEW.user_id);

    -- ---- Huy hiệu theo hạng đạt được ----
    if new_level = 'Thân thiết' then perform public.grant_achievement(NEW.user_id, 'Khách thân thiết'); end if;
    if new_level = 'Vàng' then perform public.grant_achievement(NEW.user_id, 'Khách Vàng'); end if;
    if new_level = 'Kim Cương' then perform public.grant_achievement(NEW.user_id, 'Khách Kim Cương'); end if;
    if new_level = 'Huyền thoại' then perform public.grant_achievement(NEW.user_id, 'Huyền thoại quán nem'); end if;

  end if;

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_done on public.orders;
create trigger on_order_done
  after update on public.orders
  for each row execute procedure public.handle_order_done();

-- ============================================================
-- HÀM PHÁT VOUCHER THEO HẠNG — admin bấm tay 1 lần/tuần & 1 lần/tháng
-- (xem ghi chú lý do KHÔNG tự động chạy theo lịch ở file hướng dẫn)
-- ============================================================
create or replace function public.grant_period_vouchers(p_period text)
returns int as $$
declare
  r record;
  v_value numeric;
  v_id uuid;
  v_code text;
  granted_count int := 0;
  expire_days int;
begin
  if not exists (select 1 from public.users where id = auth.uid() and role = 'admin') then
    raise exception 'PERMISSION_DENIED: chỉ admin mới được phát voucher';
  end if;

  expire_days := case when p_period = 'week' then 7 else 30 end;

  for r in
    select u.id as user_id, u.level, t.weekly_voucher_value, t.monthly_voucher_value
    from public.users u
    join public.rank_tiers t on t.name = u.level
    where (p_period = 'week' and t.weekly_voucher_value > 0)
       or (p_period = 'month' and t.monthly_voucher_value > 0)
  loop
    v_value := case when p_period = 'week' then r.weekly_voucher_value else r.monthly_voucher_value end;
    v_code := upper(p_period) || to_char(now(), 'YYYYMMDD') || substr(r.user_id::text, 1, 6);

    insert into public.vouchers (code, discount_type, discount_value, expired_at, is_personal)
    values (v_code, 'amount', v_value, now() + (expire_days || ' days')::interval, true)
    returning id into v_id;

    insert into public.user_vouchers (user_id, voucher_id, used) values (r.user_id, v_id, false);

    insert into public.notifications (user_id, title, content, is_read)
    values (r.user_id, '🏆 Quà thưởng hạng ' || r.level,
      'Bạn nhận voucher ' || v_code || ' giảm ' || v_value::text || 'đ vì đang giữ hạng ' || r.level || '!', false);

    granted_count := granted_count + 1;
  end loop;

  return granted_count;
end;
$$ language plpgsql security definer;

grant execute on function public.grant_period_vouchers(text) to authenticated;

-- ============================================================
-- HÀM LẤY BẢNG XẾP HẠNG (chỉ trả về thông tin an toàn, không lộ
-- email/SĐT) — dùng cho trang "Bảng xếp hạng" của khách hàng
-- ============================================================
create or replace function public.get_leaderboard(limit_n int default 10)
returns table(full_name text, level text, total_spend numeric) as $$
  select coalesce(u.full_name, 'Khách ẩn danh'), u.level, coalesce(sum(o.total_amount), 0) as total_spend
  from public.users u
  left join public.orders o on o.user_id = u.id and o.status = 'done'
  group by u.id, u.full_name, u.level
  order by total_spend desc
  limit limit_n;
$$ language sql security definer;

grant execute on function public.get_leaderboard(int) to authenticated;

-- ============================================================
-- Tính lại hạng cho TẤT CẢ khách hiện có (chạy 1 lần ngay sau khi
-- cài đặt, để các đơn cũ trước đây cũng được tính vào hạng)
-- ============================================================
do $$
declare u record;
begin
  for u in select id from public.users loop
    perform public.recompute_user_rank(u.id);
  end loop;
end $$;
