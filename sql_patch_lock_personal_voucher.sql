-- ============================================================
-- ★ KHÓA VOUCHER PASSPORT — chỉ đúng người được tặng mới áp dụng được
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Thêm cờ đánh dấu voucher "cá nhân" (do hệ thống tự tặng) khác với
-- voucher "công khai" (admin tạo tay cho mọi người dùng)
alter table public.vouchers add column if not exists is_personal boolean default false;

-- Cập nhật hàm Nem Passport: đánh dấu voucher tạo ra là is_personal = true
create or replace function public.handle_order_done()
returns trigger as $$
declare
  current_stamps int;
  new_voucher_id uuid;
  voucher_code text;
begin
  if NEW.status = 'done' and (OLD.status is distinct from 'done') then

    update public.users
    set passport_stamps = passport_stamps + 1,
        passport_total_completed = passport_total_completed + 1
    where id = NEW.user_id
    returning passport_stamps into current_stamps;

    if current_stamps >= 10 then
      voucher_code := 'PASSPORT' || to_char(now(), 'YYYYMMDDHH24MISS') || substr(NEW.user_id::text, 1, 4);

      insert into public.vouchers (code, discount_type, discount_value, expired_at, is_personal)
      values (voucher_code, 'amount', 30000, now() + interval '30 days', true)
      returning id into new_voucher_id;

      insert into public.user_vouchers (user_id, voucher_id, used)
      values (NEW.user_id, new_voucher_id, false);

      insert into public.notifications (user_id, title, content, is_read)
      values (
        NEW.user_id,
        '🎉 Bạn đã hoàn thành Nem Passport!',
        'Cảm ơn bạn đã đồng hành! Bạn nhận được voucher ' || voucher_code || ' giảm 30.000đ cho đơn tiếp theo.',
        false
      );

      update public.users set passport_stamps = 0 where id = NEW.user_id;
    end if;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

-- Cho phép khách hàng tự đánh dấu "đã dùng" voucher của chính họ
-- (cần để web khách hàng cập nhật trạng thái sau khi đặt hàng dùng voucher)
drop policy if exists "Users update own user_vouchers" on public.user_vouchers;
create policy "Users update own user_vouchers" on public.user_vouchers for update
  using (auth.uid() = user_id);
