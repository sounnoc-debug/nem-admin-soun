'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'

export default function CategoriesPage() {
  const [categories, setCategories] = useState([])
  const [editing, setEditing] = useState({}) // { [id]: imageUrl }

  useEffect(() => { load() }, [])

  async function load() {
    const { data } = await supabase.from('categories').select('*').order('name')
    setCategories(data || [])
    const map = {}
    ;(data || []).forEach((c) => { map[c.id] = c.image || '' })
    setEditing(map)
  }

  async function handleSave(id) {
    await supabase.from('categories').update({ image: editing[id] || null }).eq('id', id)
    load()
  }

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar"><h1 style={{ fontSize: 26 }}>Danh mục — Ảnh bìa</h1></div>
        <p style={{ color: '#8A7158', fontSize: 13, marginBottom: 16 }}>
          Dán link ảnh (URL) cho từng danh mục. Ảnh này sẽ hiện làm ảnh bìa ở đầu mỗi nhóm món trên web khách hàng.
        </p>

        {categories.map((c) => (
          <div key={c.id} className="card" style={{ marginBottom: 12, display: 'flex', gap: 16, alignItems: 'center' }}>
            <img
              src={editing[c.id] || 'https://placehold.co/120x80?text=Chưa+có+ảnh'}
              style={{ width: 120, height: 80, objectFit: 'cover', borderRadius: 8, background: '#EFE2CF' }}
            />
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, marginBottom: 6 }}>{c.icon} {c.name}</div>
              <input
                value={editing[c.id] || ''}
                onChange={(e) => setEditing({ ...editing, [c.id]: e.target.value })}
                placeholder="https://..."
              />
            </div>
            <button className="btn" style={{ width: 'auto' }} onClick={() => handleSave(c.id)}>Lưu</button>
          </div>
        ))}
      </main>
    </div>
  )
}
