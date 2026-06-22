'use client'
import { usePathname, useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

const LINKS = [
  { href: '/dashboard', label: '📊 Tổng quan' },
  { href: '/products', label: '🍤 Sản phẩm' },
  { href: '/orders', label: '🧾 Đơn hàng' },
  { href: '/vouchers', label: '🎁 Voucher' },
]

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  async function handleLogout() {
    await supabase.auth.signOut()
    router.replace('/login')
  }

  return (
    <aside className="sidebar">
      <div className="brand">🌿 Nem Admin</div>
      <nav>
        {LINKS.map((l) => (
          <a key={l.href} href={l.href} className={pathname === l.href ? 'active' : ''}>
            {l.label}
          </a>
        ))}
      </nav>
      <div style={{ marginTop: 32 }}>
        <a onClick={handleLogout} style={{ cursor: 'pointer', fontSize: 13, color: '#C99' }}>
          ⎋ Đăng xuất
        </a>
      </div>
    </aside>
  )
}
