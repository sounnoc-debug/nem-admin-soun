-- ============================================================
-- ★ GỠ BỎ TÍNH NĂNG DUYỆT THẺ SINH VIÊN BẰNG ẢNH
-- Không còn chặn đặt "Combo Sinh viên" ở tầng database nữa —
-- thay bằng thông báo xác nhận khi đặt hàng (xử lý ở web khách hàng).
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

drop trigger if exists trg_check_student_combo on public.order_items;
drop function if exists public.check_student_combo_order();

-- Giữ lại cột student_verification_status/student_id_image trong bảng users
-- (không xóa, không gây hại nếu để đó, tránh lỗi nếu có chỗ khác tham chiếu)
-- — nhưng từ nay web không dùng các cột này nữa.
