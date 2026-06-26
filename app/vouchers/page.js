'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'

export default function VouchersPage() {
  const [vouchers, setVouchers] = useState([])
  const [form, setForm] = useState({ code: '', discount_type: 'percent', discount_value: '', expired_at: '' })

  useEffect(() => { load() }, [])

  async function load() {
    const { data } = await supabase.from('vouchers').select('*').order('expired_at', { ascending: true })
    setVouchers(data || [])
  }

  async function handleSubmit(e) {
    e.preventDefault()
    await supabase.from('vouchers').insert({
      code: form.code.toUpperCase(),
      discount_type: form.discount_type,
      discount_value: Number(form.discount_value),
      expired_at: form.expired_at || null,
    })
    setForm({ code: '', discount_type: 'percent', discount_value: '', expired_at: '' })
    load()
  }

  async function handleDelete(id) {
    if (!confirm('Xóa voucher này?')) return
    await supabase.from('vouchers').delete().eq('id', id)
    load()
  }

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar"><h1 style={{ fontSize: 26 }}>Voucher</h1></div>

        <div className="card" style={{ marginBottom: 20 }}>
          <h3 style={{ marginTop: 0 }}>Tạo mã giảm giá mới</h3>
          <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr auto', gap: 12, alignItems: 'end' }}>
            <div>
              <label style={{ fontSize: 13 }}>Mã code</label>
              <input required value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} placeholder="NEM10" />
            </div>
            <div>
              <label style={{ fontSize: 13 }}>Loại</label>
              <select value={form.discount_type} onChange={(e) => setForm({ ...form, discount_type: e.target.value })}>
                <option value="percent">Giảm theo %</option>
                <option value="amount">Giảm số tiền</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: 13 }}>Giá trị</label>
              <input required type="number" value={form.discount_value} onChange={(e) => setForm({ ...form, discount_value: e.target.value })} />
            </div>
            <div>
              <label style={{ fontSize: 13 }}>Ngày hết hạn</label>
              <input type="date" value={form.expired_at} onChange={(e) => setForm({ ...form, expired_at: e.target.value })} />
            </div>
            <button className="btn">Tạo</button>
          </form>
        </div>

        <div className="card">
          <table>
            <thead><tr><th>Mã</th><th>Loại</th><th>Giá trị</th><th>Hết hạn</th><th>Phạm vi</th><th></th></tr></thead>
            <tbody>
              {vouchers.length === 0 && <tr><td colSpan={6} style={{ color: '#8A7158' }}>Chưa có voucher nào.</td></tr>}
              {vouchers.map((v) => (
                <tr key={v.id}>
                  <td><strong>{v.code}</strong></td>
                  <td>{v.discount_type === 'percent' ? 'Phần trăm' : 'Số tiền'}</td>
                  <td>{v.discount_type === 'percent' ? `${v.discount_value}%` : `${Number(v.discount_value).toLocaleString('vi-VN')}đ`}</td>
                  <td>{v.expired_at ? new Date(v.expired_at).toLocaleDateString('vi-VN') : '—'}</td>
                  <td>{v.is_personal ? <span className="ticket-status status-pending">🔒 Cá nhân</span> : <span className="ticket-status status-done">🌐 Công khai</span>}</td>
                  <td><a onClick={() => handleDelete(v.id)} style={{ cursor: 'pointer', color: 'var(--chili)' }}>Xóa</a></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  )
}
