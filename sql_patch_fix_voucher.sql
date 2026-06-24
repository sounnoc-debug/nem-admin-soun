-- ============================================================
-- ★ FIX LỖI — Không tạo được voucher
-- Nguyên nhân: bảng vouchers đã bật RLS (Row Level Security) ở bản
-- vá trước nhưng chỉ có quyền XEM (select), CHƯA có quyền TẠO (insert)
-- cho admin — nên mọi lần bấm "Tạo" đều bị từ chối thầm lặng.
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

create policy "Admin manage vouchers" on public.vouchers for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Kiểm tra: lệnh dưới phải hiện đủ các policy của bảng vouchers
select policyname, cmd from pg_policies where tablename = 'vouchers';
