'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'
import { StatusBadge } from '@/app/dashboard/page'

const STATUSES = [
  { value: 'pending', label: 'Chờ xác nhận' },
  { value: 'cooking', label: 'Đang làm món' },
  { value: 'delivering', label: 'Đang giao' },
  { value: 'done', label: 'Hoàn tất' },
  { value: 'cancelled', label: 'Đã hủy' },
]

export default function OrdersPage() {
  const [orders, setOrders] = useState([])
  const [filter, setFilter] = useState('all')

  useEffect(() => { load() }, [])

  async function load() {
    const { data } = await supabase.from('orders').select('*').order('created_at', { ascending: false })
    setOrders(data || [])
  }

  async function updateStatus(id, status) {
    await supabase.from('orders').update({ status }).eq('id', id)
    load()
  }

  const fmt = (n) => Number(n || 0).toLocaleString('vi-VN') + 'đ'
  const visible = filter === 'all'
    ? orders.filter((o) => o.status !== 'done')   // ★ Đơn hoàn thành tự ẩn khỏi danh sách chính
    : orders.filter((o) => o.status === filter)
  const doneCount = orders.filter((o) => o.status === 'done').length

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar">
          <h1 style={{ fontSize: 26 }}>Đơn hàng</h1>
        </div>

        <div style={{ marginBottom: 8, display: 'flex', gap: 8 }}>
          <button className={`btn ${filter === 'all' ? '' : 'secondary'}`} onClick={() => setFilter('all')}>Đang xử lý</button>
          {STATUSES.map((s) => (
            <button key={s.value} className={`btn ${filter === s.value ? '' : 'secondary'}`} onClick={() => setFilter(s.value)}>
              {s.label}{s.value === 'done' && doneCount > 0 ? ` (${doneCount})` : ''}
            </button>
          ))}
        </div>
        <p style={{ fontSize: 12, color: '#8A7158', marginBottom: 16 }}>
          ★ Đơn "Hoàn tất" tự ẩn khỏi danh sách chính cho gọn — xem lại bằng nút "Hoàn tất" ở trên.
        </p>

        <div className="card">
          <table>
            <thead>
              <tr>
                <th>Mã đơn</th><th>SĐT</th><th>Địa chỉ</th><th>Tổng tiền</th><th>Trạng thái</th><th>Đổi trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {visible.length === 0 && (
                <tr><td colSpan={6} style={{ color: '#8A7158' }}>Không có đơn hàng nào ở trạng thái này.</td></tr>
              )}
              {visible.map((o) => (
                <tr key={o.id}>
                  <td>#{o.id.slice(0, 8)}</td>
                  <td>{o.phone || '—'}</td>
                  <td>{o.address || '—'}</td>
                  <td>{fmt(o.total_amount)}</td>
                  <td><StatusBadge status={o.status} /></td>
                  <td>
                    <select value={o.status} onChange={(e) => updateStatus(o.id, e.target.value)}>
                      {STATUSES.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  )
}
