'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'

export default function Dashboard() {
  const [stats, setStats] = useState({ revenueToday: 0, ordersToday: 0, newCustomers: 0, totalProducts: 0 })
  const [recentOrders, setRecentOrders] = useState([])

  useEffect(() => {
    loadStats()
  }, [])

  async function loadStats() {
    const startOfDay = new Date()
    startOfDay.setHours(0, 0, 0, 0)

    const { data: ordersToday } = await supabase
      .from('orders')
      .select('id, total_amount, created_at')
      .gte('created_at', startOfDay.toISOString())

    const { data: products } = await supabase.from('products').select('id')

    const { data: customers } = await supabase
      .from('users')
      .select('id')
      .gte('created_at', startOfDay.toISOString())

    const { data: recent } = await supabase
      .from('orders')
      .select('id, total_amount, status, phone, created_at')
      .order('created_at', { ascending: false })
      .limit(8)

    const revenue = (ordersToday || []).reduce((sum, o) => sum + Number(o.total_amount || 0), 0)

    setStats({
      revenueToday: revenue,
      ordersToday: ordersToday?.length || 0,
      newCustomers: customers?.length || 0,
      totalProducts: products?.length || 0,
    })
    setRecentOrders(recent || [])
  }

  const fmt = (n) => Number(n || 0).toLocaleString('vi-VN') + 'đ'

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar">
          <h1 style={{ fontSize: 26 }}>Tổng quan</h1>
        </div>

        <div className="stat-grid">
          <div className="stat-card">
            <div className="label">Doanh thu hôm nay</div>
            <div className="value">{fmt(stats.revenueToday)}</div>
          </div>
          <div className="stat-card">
            <div className="label">Đơn hôm nay</div>
            <div className="value">{stats.ordersToday}</div>
          </div>
          <div className="stat-card">
            <div className="label">Khách mới hôm nay</div>
            <div className="value">{stats.newCustomers}</div>
          </div>
          <div className="stat-card">
            <div className="label">Tổng sản phẩm</div>
            <div className="value">{stats.totalProducts}</div>
          </div>
        </div>

        <div className="card">
          <h3 style={{ marginTop: 0 }}>Đơn hàng gần đây</h3>
          <table>
            <thead>
              <tr>
                <th>Mã đơn</th>
                <th>SĐT</th>
                <th>Tổng tiền</th>
                <th>Trạng thái</th>
                <th>Thời gian</th>
              </tr>
            </thead>
            <tbody>
              {recentOrders.length === 0 && (
                <tr><td colSpan={5} style={{ color: '#8A7158' }}>Chưa có đơn hàng nào. Đơn từ app khách hàng sẽ hiện ở đây.</td></tr>
              )}
              {recentOrders.map((o) => (
                <tr key={o.id}>
                  <td>#{o.id.slice(0, 8)}</td>
                  <td>{o.phone || '—'}</td>
                  <td>{fmt(o.total_amount)}</td>
                  <td><StatusBadge status={o.status} /></td>
                  <td>{new Date(o.created_at).toLocaleString('vi-VN')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  )
}

export function StatusBadge({ status }) {
  const map = {
    pending: ['Chờ xác nhận', 'status-pending'],
    cooking: ['Đang làm món', 'status-cooking'],
    delivering: ['Đang giao', 'status-delivering'],
    done: ['Hoàn tất', 'status-done'],
    cancelled: ['Đã hủy', 'status-cancelled'],
  }
  const [label, cls] = map[status] || ['Không rõ', 'status-pending']
  return <span className={`ticket-status ${cls}`}>{label}</span>
}
