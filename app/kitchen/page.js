'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

export default function KitchenPage() {
  const router = useRouter()
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    guardAndLoad()
    const interval = setInterval(load, 15000) // tự cập nhật mỗi 15s
    return () => clearInterval(interval)
  }, [])

  async function guardAndLoad() {
    const { data } = await supabase.auth.getSession()
    if (!data.session) { router.replace('/login'); return }
    const { data: profile } = await supabase.from('users').select('role').eq('id', data.session.user.id).single()
    if (!profile || !['kitchen', 'admin'].includes(profile.role)) {
      await supabase.auth.signOut()
      router.replace('/login')
      return
    }
    load()
  }

  async function load() {
    const { data } = await supabase
      .from('orders')
      .select('*, order_items(quantity, note, products(name))')
      .in('status', ['pending', 'cooking'])
      .order('created_at', { ascending: true })
    setOrders(data || [])
    setLoading(false)
  }

  async function advance(order) {
    const nextStatus = order.status === 'pending' ? 'cooking' : 'delivering'
    await supabase.from('orders').update({ status: nextStatus }).eq('id', order.id)
    load()
  }

  async function handleLogout() {
    await supabase.auth.signOut()
    router.replace('/login')
  }

  if (loading) return <div style={{ padding: 24 }}>Đang tải...</div>

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)' }}>
      <div style={{ background: 'var(--ink)', color: 'white', padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <img src="/logo.png" alt="Logo" style={{ height: 28 }} />
        <div>
          <span style={{ fontSize: 13, marginRight: 14 }}>👨‍🍳 Bếp</span>
          <a onClick={handleLogout} style={{ cursor: 'pointer', fontSize: 13, color: '#E8B4B4' }}>Đăng xuất</a>
        </div>
      </div>

      <div style={{ padding: 16, maxWidth: 700, margin: '0 auto' }}>
        <h1 style={{ fontSize: 22, marginBottom: 4 }}>Đơn cần làm</h1>
        <p style={{ fontSize: 13, color: '#8A7158', marginBottom: 16 }}>Tự cập nhật mỗi 15 giây — {orders.length} đơn đang chờ/đang làm</p>

        {orders.length === 0 && <p style={{ color: '#8A7158', textAlign: 'center', marginTop: 60 }}>🎉 Không còn đơn nào cần làm!</p>}

        {orders.map((o) => (
          <div key={o.id} className="card" style={{ marginBottom: 14, borderLeft: `5px solid ${o.status === 'pending' ? 'var(--pending)' : 'var(--chili)'}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <strong style={{ fontSize: 16 }}>#{o.id.slice(0, 8)}</strong>
              <span className={`ticket-status ${o.status === 'pending' ? 'status-pending' : 'status-cooking'}`}>
                {o.status === 'pending' ? 'Chờ xác nhận' : 'Đang làm'}
              </span>
            </div>
            <ul style={{ margin: '0 0 12px', paddingLeft: 20, fontSize: 15 }}>
              {o.order_items?.map((it, idx) => (
                <li key={idx}>
                  <strong>{it.quantity}x</strong> {it.products?.name}
                  {it.note && <span style={{ color: 'var(--chili)' }}> — ghi chú: {it.note}</span>}
                </li>
              ))}
            </ul>
            <button className="btn" style={{ fontSize: 16, padding: '14px 18px' }} onClick={() => advance(o)}>
              {o.status === 'pending' ? '🔥 Bắt đầu làm' : '✅ Xong, chuyển sang giao'}
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
