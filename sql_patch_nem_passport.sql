-- ============================================================
-- ★ NEM PASSPORT — Mỗi đơn hoàn tất = 1 con dấu. Đủ 10 dấu = tự
-- động tặng 1 voucher 30.000đ, sau đó đếm lại từ đầu.
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Thêm cột lưu số dấu hiện tại + tổng số đơn đã hoàn tất (lịch sử)
alter table public.users add column if not exists passport_stamps int default 0;
alter table public.users add column if not exists passport_total_completed int default 0;

-- ============================================================
-- Hàm tự động chạy mỗi khi 1 đơn hàng được đổi trạng thái
-- ============================================================
create or replace function public.handle_order_done()
returns trigger as $$
declare
  current_stamps int;
  new_voucher_id uuid;
  voucher_code text;
begin
  -- Chỉ chạy khi đơn vừa được chuyển SANG "done" (không chạy lại nếu đã done từ trước)
  if NEW.status = 'done' and (OLD.status is distinct from 'done') then

    update public.users
    set passport_stamps = passport_stamps + 1,
        passport_total_completed = passport_total_completed + 1
    where id = NEW.user_id
    returning passport_stamps into current_stamps;

    -- Đủ 10 dấu → tặng quà + reset lại
    if current_stamps >= 10 then
      voucher_code := 'PASSPORT' || to_char(now(), 'YYYYMMDDHH24MISS') || substr(NEW.user_id::text, 1, 4);

      insert into public.vouchers (code, discount_type, discount_value, expired_at)
      values (voucher_code, 'amount', 30000, now() + interval '30 days')
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

drop trigger if exists on_order_done on public.orders;
create trigger on_order_done
  after update on public.orders
  for each row execute procedure public.handle_order_done();

-- Cho phép khách xem voucher + thông báo của chính họ (nếu chưa có policy)
alter table public.notifications enable row level security;
drop policy if exists "Users view own notifications" on public.notifications;
create policy "Users view own notifications" on public.notifications for select
  using (auth.uid() = user_id);
drop policy if exists "Users update own notifications" on public.notifications;
create policy "Users update own notifications" on public.notifications for update
  using (auth.uid() = user_id);

drop policy if exists "Users view own user_vouchers" on public.user_vouchers;
alter table public.user_vouchers enable row level security;
create policy "Users view own user_vouchers" on public.user_vouchers for select
  using (auth.uid() = user_id);
