-- ============================================================
-- ★ BẢN VÁ — Thêm ảnh bìa danh mục + dọn category trùng lặp
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- ============================================================

-- Thêm cột lưu ảnh bìa cho từng danh mục
alter table public.categories add column if not exists image text;

-- Nếu có sản phẩm nào đang gắn vào category "Đồ uống" cũ (trùng với "Nước uống" mới)
-- thì chuyển hết sang "Nước uống" trước khi xóa, để không mất dữ liệu
update public.products
set category_id = (select id from public.categories where name = 'Nước uống')
where category_id = (select id from public.categories where name = 'Đồ uống');

-- Xóa category "Đồ uống" cũ (trùng chức năng với "Nước uống")
delete from public.categories where name = 'Đồ uống';

-- Category "Combo" cũ (rời rạc, không dùng) — gộp sản phẩm nếu có, rồi xóa
update public.products
set category_id = (select id from public.categories where name = 'Combo Gia đình')
where category_id = (select id from public.categories where name = 'Combo');

delete from public.categories where name = 'Combo';
