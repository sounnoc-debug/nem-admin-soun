'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'

const EMPTY = { name: '', description: '', price: '', sale_price: '', image: '', stock: '', category_id: '', is_hot: false, is_new: false }

export default function ProductsPage() {
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [form, setForm] = useState(EMPTY)
  const [editingId, setEditingId] = useState(null)
  const [showForm, setShowForm] = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    const { data: p } = await supabase.from('products').select('*').order('created_at', { ascending: false })
    const { data: c } = await supabase.from('categories').select('*')
    setProducts(p || [])
    setCategories(c || [])
  }

  function startCreate() {
    setForm(EMPTY)
    setEditingId(null)
    setShowForm(true)
  }

  function startEdit(p) {
    setForm({
      name: p.name, description: p.description || '', price: p.price, sale_price: p.sale_price || '',
      image: p.image || '', stock: p.stock, category_id: p.category_id || '', is_hot: p.is_hot, is_new: p.is_new,
    })
    setEditingId(p.id)
    setShowForm(true)
  }

  async function handleSubmit(e) {
    e.preventDefault()
    const payload = {
      ...form,
      price: Number(form.price) || 0,
      sale_price: form.sale_price ? Number(form.sale_price) : null,
      stock: Number(form.stock) || 0,
      category_id: form.category_id || null,
    }
    if (editingId) {
      await supabase.from('products').update(payload).eq('id', editingId)
    } else {
      await supabase.from('products').insert(payload)
    }
    setShowForm(false)
    load()
  }

  async function handleDelete(id) {
    if (!confirm('Xóa sản phẩm này?')) return
    await supabase.from('products').delete().eq('id', id)
    load()
  }

  const fmt = (n) => Number(n || 0).toLocaleString('vi-VN') + 'đ'

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar">
          <h1 style={{ fontSize: 26 }}>Sản phẩm</h1>
          <button className="btn" onClick={startCreate}>+ Thêm sản phẩm</button>
        </div>

        {showForm && (
          <div className="card" style={{ marginBottom: 20 }}>
            <h3 style={{ marginTop: 0 }}>{editingId ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'}</h3>
            <form onSubmit={handleSubmit}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
                <div>
                  <label style={{ fontSize: 13 }}>Tên món</label>
                  <input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
                </div>
                <div>
                  <label style={{ fontSize: 13 }}>Danh mục</label>
                  <select value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })}>
                    <option value="">— Chọn —</option>
                    {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </div>
                <div>
                  <label style={{ fontSize: 13 }}>Giá gốc (đ)</label>
                  <input required type="number" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} />
                </div>
                <div>
                  <label style={{ fontSize: 13 }}>Giá khuyến mãi (đ, để trống nếu không có)</label>
                  <input type="number" value={form.sale_price} onChange={(e) => setForm({ ...form, sale_price: e.target.value })} />
                </div>
                <div>
                  <label style={{ fontSize: 13 }}>Số lượng tồn kho</label>
                  <input type="number" value={form.stock} onChange={(e) => setForm({ ...form, stock: e.target.value })} />
                </div>
                <div>
                  <label style={{ fontSize: 13 }}>Link hình ảnh (URL)</label>
                  <input value={form.image} onChange={(e) => setForm({ ...form, image: e.target.value })} placeholder="https://..." />
                </div>
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ fontSize: 13 }}>Mô tả</label>
                <textarea rows={2} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
              </div>
              <div style={{ display: 'flex', gap: 16, marginBottom: 16, fontSize: 14 }}>
                <label><input type="checkbox" checked={form.is_hot} onChange={(e) => setForm({ ...form, is_hot: e.target.checked })} /> Món bán chạy</label>
                <label><input type="checkbox" checked={form.is_new} onChange={(e) => setForm({ ...form, is_new: e.target.checked })} /> Món mới</label>
              </div>
              <button className="btn">{editingId ? 'Lưu thay đổi' : 'Thêm sản phẩm'}</button>{' '}
              <button type="button" className="btn secondary" onClick={() => setShowForm(false)}>Hủy</button>
            </form>
          </div>
        )}

        <div className="card">
          <table>
            <thead>
              <tr>
                <th>Tên món</th><th>Danh mục</th><th>Giá</th><th>Tồn kho</th><th>Nhãn</th><th></th>
              </tr>
            </thead>
            <tbody>
              {products.length === 0 && (
                <tr><td colSpan={6} style={{ color: '#8A7158' }}>Chưa có sản phẩm. Bấm "+ Thêm sản phẩm" để bắt đầu.</td></tr>
              )}
              {products.map((p) => (
                <tr key={p.id}>
                  <td>{p.name}</td>
                  <td>{categories.find((c) => c.id === p.category_id)?.name || '—'}</td>
                  <td>{p.sale_price ? <><s style={{ color: '#8A7158' }}>{fmt(p.price)}</s> {fmt(p.sale_price)}</> : fmt(p.price)}</td>
                  <td>{p.stock}</td>
                  <td>{p.is_hot && '🔥 '}{p.is_new && '✨'}</td>
                  <td>
                    <a onClick={() => startEdit(p)} style={{ cursor: 'pointer', marginRight: 12 }}>Sửa</a>
                    <a onClick={() => handleDelete(p.id)} style={{ cursor: 'pointer', color: 'var(--chili)' }}>Xóa</a>
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
