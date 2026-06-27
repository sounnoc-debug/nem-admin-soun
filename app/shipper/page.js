'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

export default function ShipperPage() {
  const router = useRouter()
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    guardAndLoad()
    const interval = setInterval(load, 15000)
    return () => clearInterval(interval)
  }, [])

  async function guardAndLoad() {
    const { data } = await supabase.auth.getSession()
    if (!data.session) { router.replace('/login'); return }
    const { data: profile } = await supabase.from('users').select('role').eq('id', data.session.user.id).single()
    if (!profile || !['shipper', 'admin'].includes(profile.role)) {
      await supabase.auth.signOut()
      router.replace('/login')
      return
    }
    load()
  }

  async function load() {
    const { data } = await supabase
      .from('orders')
      .select('*')
      .eq('status', 'delivering')
      .order('created_at', { ascending: true })
    setOrders(data || [])
    setLoading(false)
  }

  async function markDelivered(order) {
    await supabase.from('orders').update({ status: 'done' }).eq('id', order.id)
    load()
  }

  async function handleLogout() {
    await supabase.auth.signOut()
    router.replace('/login')
  }

  const fmt = (n) => Number(n || 0).toLocaleString('vi-VN') + 'đ'

  if (loading) return <div style={{ padding: 24 }}>Đang tải...</div>

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)' }}>
      <div style={{ background: 'var(--ink)', color: 'white', padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <img src="/logo.png" alt="Logo" style={{ height: 28 }} />
        <div>
          <span style={{ fontSize: 13, marginRight: 14 }}>🛵 Shipper</span>
          <a onClick={handleLogout} style={{ cursor: 'pointer', fontSize: 13, color: '#E8B4B4' }}>Đăng xuất</a>
        </div>
      </div>

      <div style={{ padding: 16, maxWidth: 700, margin: '0 auto' }}>
        <h1 style={{ fontSize: 22, marginBottom: 4 }}>Đơn cần giao</h1>
        <p style={{ fontSize: 13, color: '#8A7158', marginBottom: 16 }}>Tự cập nhật mỗi 15 giây — {orders.length} đơn đang chờ giao</p>

        {orders.length === 0 && <p style={{ color: '#8A7158', textAlign: 'center', marginTop: 60 }}>🎉 Không còn đơn nào cần giao!</p>}

        {orders.map((o) => (
          <div key={o.id} className="card" style={{ marginBottom: 14, borderLeft: '5px solid var(--herb)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <strong style={{ fontSize: 16 }}>#{o.id.slice(0, 8)}</strong>
              <span style={{ fontWeight: 700, color: 'var(--chili-dark)' }}>{fmt(o.total_amount)}</span>
            </div>
            <p style={{ fontSize: 15, marginBottom: 4 }}>📍 {o.address}</p>
            <p style={{ fontSize: 15, marginBottom: 12 }}>
              📞 <a href={`tel:${o.phone}`} style={{ color: 'var(--chili)', fontWeight: 700, textDecoration: 'underline' }}>{o.phone}</a>
            </p>
            <p style={{ fontSize: 13, color: '#8A7158', marginBottom: 12 }}>
              {o.payment_method === 'cod' ? '💰 Thu tiền khi giao (COD)' : '🏦 Đã chuyển khoản trước'}
            </p>
            <button className="btn" style={{ fontSize: 16, padding: '14px 18px' }} onClick={() => markDelivered(o)}>
              ✅ Đã giao xong
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
