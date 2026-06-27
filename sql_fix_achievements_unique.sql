-- ★ Chạy đoạn này TRƯỚC, sau đó chạy lại sql_patch_rank_badges.sql như cũ
create unique index if not exists achievements_name_idx on public.achievements(name);
