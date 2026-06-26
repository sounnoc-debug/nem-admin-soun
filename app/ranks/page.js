'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'

export default function RanksPage() {
  const [tiers, setTiers] = useState([])
  const [editing, setEditing] = useState({})
  const [granting, setGranting] = useState('')
  const [resultMsg, setResultMsg] = useState('')

  useEffect(() => { load() }, [])

  async function load() {
    const { data } = await supabase.from('rank_tiers').select('*').order('sort_order')
    setTiers(data || [])
    const map = {}
    ;(data || []).forEach((t) => { map[t.id] = { min_spend: t.min_spend, weekly_voucher_value: t.weekly_voucher_value, monthly_voucher_value: t.monthly_voucher_value } })
    setEditing(map)
  }

  async function handleSave(id) {
    await supabase.from('rank_tiers').update(editing[id]).eq('id', id)
    setResultMsg('')
    load()
  }

  async function handleGrant(period) {
    setGranting(period)
    setResultMsg('')
    const { data, error } = await supabase.rpc('grant_period_vouchers', { p_period: period })
    setGranting('')
    if (error) { setResultMsg('Lỗi: ' + error.message); return }
    setResultMsg(`✓ Đã phát voucher cho ${data} khách hàng (${period === 'week' ? 'theo tuần' : 'theo tháng'}).`)
  }

  const fmt = (n) => Number(n || 0).toLocaleString('vi-VN') + 'đ'

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar"><h1 style={{ fontSize: 26 }}>Hạng & Huy hiệu</h1></div>

        <div className="card" style={{ marginBottom: 20 }}>
          <h3 style={{ marginTop: 0 }}>Phát voucher theo hạng</h3>
          <p style={{ fontSize: 13, color: '#8A7158', marginBottom: 12 }}>
            ★ Bấm tay 1 lần/tuần và 1 lần/tháng (không tự động) — mỗi khách đang giữ hạng có voucher &gt; 0đ sẽ tự nhận 1 voucher cá nhân tương ứng.
          </p>
          <div style={{ display: 'flex', gap: 10 }}>
            <button className="btn" style={{ width: 'auto' }} disabled={granting === 'week'} onClick={() => handleGrant('week')}>
              {granting === 'week' ? 'Đang phát...' : '🗓️ Phát voucher TUẦN này'}
            </button>
            <button className="btn" style={{ width: 'auto' }} disabled={granting === 'month'} onClick={() => handleGrant('month')}>
              {granting === 'month' ? 'Đang phát...' : '📅 Phát voucher THÁNG này'}
            </button>
          </div>
          {resultMsg && <p style={{ fontSize: 13, marginTop: 10, color: 'var(--herb)' }}>{resultMsg}</p>}
        </div>

        <div className="card">
          <h3 style={{ marginTop: 0 }}>Bậc hạng (chi tiêu lũy kế đơn đã hoàn tất)</h3>
          <table>
            <thead><tr><th>Hạng</th><th>Cần chi tiêu từ</th><th>Voucher / tuần</th><th>Voucher / tháng</th><th></th></tr></thead>
            <tbody>
              {tiers.map((t) => (
                <tr key={t.id}>
                  <td>{t.icon} {t.name}</td>
                  <td><input type="number" value={editing[t.id]?.min_spend ?? ''} onChange={(e) => setEditing({ ...editing, [t.id]: { ...editing[t.id], min_spend: Number(e.target.value) } })} style={{ width: 130 }} /></td>
                  <td><input type="number" value={editing[t.id]?.weekly_voucher_value ?? ''} onChange={(e) => setEditing({ ...editing, [t.id]: { ...editing[t.id], weekly_voucher_value: Number(e.target.value) } })} style={{ width: 110 }} /></td>
                  <td><input type="number" value={editing[t.id]?.monthly_voucher_value ?? ''} onChange={(e) => setEditing({ ...editing, [t.id]: { ...editing[t.id], monthly_voucher_value: Number(e.target.value) } })} style={{ width: 110 }} /></td>
                  <td><button className="btn secondary" style={{ width: 'auto' }} onClick={() => handleSave(t.id)}>Lưu</button></td>
                </tr>
              ))}
            </tbody>
          </table>
          <p style={{ fontSize: 12, color: '#8A7158', marginTop: 10 }}>
            ★ Khoảng cách giữa các hạng nên nới rộng dần (không tăng đều) để hạng cao thật sự khó đạt — mặc định: 0 → 500k → 1.5tr → 4tr → 10tr.
          </p>
        </div>
      </main>
    </div>
  )
}
