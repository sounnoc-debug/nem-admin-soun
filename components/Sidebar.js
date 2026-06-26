'use client'
import { usePathname, useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { supabase } from '@/lib/supabaseClient'

const LINKS = [
  { href: '/dashboard', label: '📊 Tổng quan' },
  { href: '/products', label: '🍤 Sản phẩm' },
  { href: '/categories', label: '🖼️ Danh mục (ảnh bìa)' },
  { href: '/students', label: '🎓 Duyệt sinh viên' },
  { href: '/ranks', label: '🏆 Hạng & Huy hiệu' },
  { href: '/orders', label: '🧾 Đơn hàng' },
  { href: '/vouchers', label: '🎁 Voucher' },
]

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  useEffect(() => {
    guardAccess()
  }, [])

  async function guardAccess() {
    const { data } = await supabase.auth.getSession()
    if (!data.session) {
      router.replace('/login')
      return
    }
    const { data: profile } = await supabase
      .from('users')
      .select('role')
      .eq('id', data.session.user.id)
      .single()
    const allowedRoles = ['admin', 'staff', 'kitchen', 'shipper']
    if (!profile || !allowedRoles.includes(profile.role)) {
      await supabase.auth.signOut()
      router.replace('/login')
    }
  }

  async function handleLogout() {
    await supabase.auth.signOut()
    router.replace('/login')
  }

  return (
    <aside className="sidebar">
      <div className="brand"><img src="/logo.png" alt="Logo" style={{ height: 28 }} /></div>
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
