-- ============================================================
-- ★ BƯỚC A — GÁN QUYỀN ADMIN cho tài khoản bạn dùng để vào web quản trị
-- Thay 'admin@quannem.com' bằng đúng email bạn dùng đăng nhập web admin
-- ============================================================
update public.users
set role = 'admin'
where email = 'admin@quannem.com';

-- Kiểm tra lại: dòng dưới phải trả về role = 'admin'
select id, email, role from public.users where email = 'admin@quannem.com';


-- ============================================================
-- ★ BƯỚC B — TẮT yêu cầu xác nhận email (để tránh bị kẹt lần sau)
-- Việc này phải làm trong giao diện, KHÔNG làm được bằng SQL:
-- Vào Supabase > Authentication > Providers > Email
-- > tắt (toggle OFF) mục "Confirm email" > Save
-- ============================================================


-- ============================================================
-- ★ BƯỚC C — MỞ KHÓA các tài khoản khách đang bị kẹt "chưa xác nhận"
-- Chạy đoạn này SAU KHI đã tắt "Confirm email" ở Bước B.
-- Lệnh này xác nhận TẤT CẢ tài khoản hiện có (an toàn cho giai đoạn mới chạy thử).
-- ============================================================
update auth.users
set email_confirmed_at = now(),
    confirmed_at = now()
where email_confirmed_at is null;

-- Kiểm tra lại: liệt kê danh sách user và trạng thái xác nhận
select email, email_confirmed_at, confirmed_at from auth.users;
