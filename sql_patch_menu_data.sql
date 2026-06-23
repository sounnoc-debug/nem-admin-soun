-- ============================================================
-- ★ BẢN VÁ MENU — thêm đầy đủ món & combo theo file
-- "Menu và bảng kế hoạch bán nem ONLINE"
-- Copy toàn bộ, dán vào Supabase > SQL Editor > Run
-- (Chạy 1 lần. Nếu chạy lại sẽ bị trùng dữ liệu.)
-- ============================================================

-- ============== DANH MỤC MỚI ==============
insert into public.categories (name, icon) values
  ('Nem phần/cuốn', '🥢'),
  ('Đồ ăn thêm', '➕'),
  ('Nước uống', '🥤'),
  ('Combo Sinh viên', '🎓'),
  ('Combo Gia đình', '👨‍👩‍👧'),
  ('Combo Theo đoàn', '🎉')
on conflict do nothing;

-- ============================================================
-- NEM PHẦN / CUỐN
-- ============================================================
insert into public.products (name, description, price, category_id, stock, is_hot)
select 'Nem phần', 'Một phần nem đầy đủ, ăn kèm bún và rau sống', 50000, id, 200, true
from public.categories where name = 'Nem phần/cuốn';

insert into public.products (name, description, price, category_id, stock)
select 'Nem cuốn (1 cuốn)', 'Cuốn nem tươi cuốn tay, ăn kèm nước chấm', 10000, id, 300
from public.categories where name = 'Nem phần/cuốn';

insert into public.products (name, description, price, category_id, stock, is_hot)
select 'Nem chua (1 cái)', 'Nem chua truyền thống, vị chua nhẹ đặc trưng', 5000, id, 300, true
from public.categories where name = 'Nem phần/cuốn';

-- ============================================================
-- ĐỒ ĂN THÊM
-- ============================================================
insert into public.products (name, description, price, category_id, stock)
select 'Nem thêm', 'Thêm 1 cái nem cho phần ăn', 4000, id, 999
from public.categories where name = 'Đồ ăn thêm';

insert into public.products (name, description, price, category_id, stock)
select 'Chả ram thêm (2 cái)', 'Thêm 2 cái chả ram giòn rụm', 5000, id, 999
from public.categories where name = 'Đồ ăn thêm';

insert into public.products (name, description, price, category_id, stock)
select 'Bánh tráng thêm', 'Thêm bánh tráng cuốn', 7000, id, 999
from public.categories where name = 'Đồ ăn thêm';

insert into public.products (name, description, price, category_id, stock)
select 'Bún thêm', 'Thêm phần bún tươi', 3000, id, 999
from public.categories where name = 'Đồ ăn thêm';

-- ============================================================
-- NƯỚC UỐNG
-- ============================================================
insert into public.products (name, description, price, category_id, stock)
select 'Nước lọc', 'Nước lọc đóng chai', 12000, id, 999
from public.categories where name = 'Nước uống';

insert into public.products (name, description, price, category_id, stock, is_hot)
select 'Nước ngọt (các loại)', 'Coca, Pepsi, 7Up, Sting... (tùy quán còn món nào)', 15000, id, 999, true
from public.categories where name = 'Nước uống';

-- ============================================================
-- COMBO SINH VIÊN
-- ============================================================
insert into public.products (name, description, price, category_id, stock, is_hot) values
  ('Combo Sinh viên 50k', '1 phần nem + 1 nước. Giá 45k nếu là sinh viên trường STU.', 50000, (select id from public.categories where name='Combo Sinh viên'), 999, true),
  ('Combo Sinh viên 60k', '1 phần nem + 1 nước + thịt thêm', 60000, (select id from public.categories where name='Combo Sinh viên'), 999, false),
  ('Combo Sinh viên 70k', '1 phần nem + 2 nước + thịt, chả thêm', 70000, (select id from public.categories where name='Combo Sinh viên'), 999, false),
  ('Combo Sinh viên Mở Tiệc 99k', '2 phần nem + thêm ít rau', 99000, (select id from public.categories where name='Combo Sinh viên'), 999, false),
  ('Combo Sinh viên Mở Tiệc 119k', '2 phần nem + 2 nước', 119000, (select id from public.categories where name='Combo Sinh viên'), 999, false),
  ('Combo Sinh viên Mở Tiệc 139k', '2 phần nem + 2 nước + thịt, chả thêm', 139000, (select id from public.categories where name='Combo Sinh viên'), 999, false),
  ('Combo Sinh viên Mở Tiệc 169k', '3 phần nem + 3 nước + thịt, chả, bánh tráng thêm', 169000, (select id from public.categories where name='Combo Sinh viên'), 999, false);

-- ============================================================
-- COMBO GIA ĐÌNH VUI VẺ
-- ============================================================
insert into public.products (name, description, price, category_id, stock, is_hot) values
  ('Combo Gia đình 109k', '2 phần nem + nước', 109000, (select id from public.categories where name='Combo Gia đình'), 999, true),
  ('Combo Gia đình 119k', '2 phần nem + 2 nước + bánh tráng thêm', 119000, (select id from public.categories where name='Combo Gia đình'), 999, false),
  ('Combo Gia đình 139k', '2 phần nem + 2 nước + thịt, bún thêm', 139000, (select id from public.categories where name='Combo Gia đình'), 999, false),
  ('Combo Gia đình 169k', '3 phần nem + 2 nước + thịt, chả, bún thêm', 169000, (select id from public.categories where name='Combo Gia đình'), 999, false),
  ('Combo Gia đình 189k', '3 phần nem + 3 nước + thịt, chả, bún, bánh tráng thêm. KHUYẾN MÃI 1 chai nước lọc', 189000, (select id from public.categories where name='Combo Gia đình'), 999, true),
  ('Combo Gia đình 219k', '4 phần nem + 2 nước', 219000, (select id from public.categories where name='Combo Gia đình'), 999, false),
  ('Combo Gia đình 239k', '4 phần nem + 4 nước + bún thêm', 239000, (select id from public.categories where name='Combo Gia đình'), 999, false),
  ('Combo Gia đình 269k', '5 phần nem + 3 nước + thịt, chả thêm', 269000, (select id from public.categories where name='Combo Gia đình'), 999, false),
  ('Combo Gia đình 289k', '5 phần nem + 4 nước + thịt, chả, bánh tráng, bún thêm', 289000, (select id from public.categories where name='Combo Gia đình'), 999, false);

-- ============================================================
-- COMBO THEO ĐOÀN
-- ============================================================
insert into public.products (name, description, price, category_id, stock, is_hot) values
  ('Combo Theo đoàn 279k', '5 phần nem + 2 nước', 279000, (select id from public.categories where name='Combo Theo đoàn'), 999, true),
  ('Combo Theo đoàn 329k', '6 phần nem + 2 nước + thịt, chả thêm', 329000, (select id from public.categories where name='Combo Theo đoàn'), 999, false),
  ('Combo Theo đoàn 369k', '7 phần nem + 2 nước + thịt, chả thêm', 369000, (select id from public.categories where name='Combo Theo đoàn'), 999, false),
  ('Combo Theo đoàn 389k', '7 phần nem + 3 nước + thịt, chả, bún thêm', 389000, (select id from public.categories where name='Combo Theo đoàn'), 999, false),
  ('Combo Theo đoàn 429k', '8 phần nem + 2 nước + thịt, chả thêm', 429000, (select id from public.categories where name='Combo Theo đoàn'), 999, false),
  ('Combo Theo đoàn 439k', '8 phần nem + 3 nước + bún thêm', 439000, (select id from public.categories where name='Combo Theo đoàn'), 999, false),
  ('Combo Theo đoàn 469k', '9 phần nem + 2 nước + thịt, chả thêm', 469000, (select id from public.categories where name='Combo Theo đoàn'), 999, false);

-- ============================================================
-- ★ GHI CHÚ VỀ PHÍ SHIP (không lưu vào bảng products vì đây là
-- quy tắc tính phí giao hàng, không phải món ăn — tham khảo để
-- bạn tự áp vào phần "shipping_fee" khi tạo đơn thực tế, hoặc
-- báo tôi để lập trình tính phí ship tự động theo khoảng cách):
--
-- Combo Sinh viên / Sinh viên Mở Tiệc : 1km đầu = 5.000đ, từ 5–15km
-- Combo Theo đoàn                      : 1km đầu = 7.000đ, > 15km
-- Combo Gia đình                       : 1km đầu = 7.000đ (theo bảng gốc)
-- ============================================================
