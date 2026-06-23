import { createClient } from '@supabase/supabase-js'

// Fallback giả để Vercel KHÔNG bị lỗi khi build (build chạy trên server, không có internet thật).
// Trên trình duyệt thật, biến môi trường bạn khai trong Vercel Settings sẽ thay thế giá trị này.
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://placeholder.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'placeholder-anon-key'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
