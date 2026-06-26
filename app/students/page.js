'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from '@/components/Sidebar'

export default function StudentVerificationPage() {
  const [users, setUsers] = useState([])
  const [imageUrls, setImageUrls] = useState({})
  const [rejectNote, setRejectNote] = useState({})
  const [filter, setFilter] = useState('pending')

  useEffect(() => { load() }, [filter])

  async function load() {
    let query = supabase.from('users').select('*').not('student_verification_status', 'eq', 'none')
    if (filter !== 'all') query = query.eq('student_verification_status', filter)
    const { data } = await query.order('created_at', { ascending: false })
    setUsers(data || [])

    // Lấy link tạm để xem ảnh thẻ (bucket riêng tư)
    const urls = {}
    for (const u of data || []) {
      if (u.student_id_image) {
        const { data: signed } = await supabase.storage.from('student-ids').createSignedUrl(u.student_id_image, 300)
        if (signed) urls[u.id] = signed.signedUrl
      }
    }
    setImageUrls(urls)
  }

  function calcAge(birthday) {
    if (!birthday) return null
    const b = new Date(birthday)
    const now = new Date()
    let age = now.getFullYear() - b.getFullYear()
    if (now.getMonth() < b.getMonth() || (now.getMonth() === b.getMonth() && now.getDate() < b.getDate())) age--
    return age
  }

  async function handleApprove(id) {
    await supabase.from('users').update({ student_verification_status: 'approved', student_verification_note: null }).eq('id', id)
    load()
  }

  async function handleReject(id) {
    const note = rejectNote[id] || 'Ảnh thẻ không hợp lệ hoặc không rõ thông tin, vui lòng nộp lại.'
    await supabase.from('users').update({ student_verification_status: 'rejected', student_verification_note: note }).eq('id', id)
    load()
  }

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <div className="topbar"><h1 style={{ fontSize: 26 }}>Duyệt sinh viên</h1></div>
        <p style={{ color: '#8A7158', fontSize: 13, marginBottom: 16 }}>
          ★ Khách chỉ đặt được "Combo Sinh viên" sau khi được duyệt ở đây. Kiểm tra kỹ ảnh thẻ + tuổi trước khi bấm Duyệt.
        </p>

        <div style={{ marginBottom: 16, display: 'flex', gap: 8 }}>
          {[['pending', 'Đang chờ'], ['approved', 'Đã duyệt'], ['rejected', 'Đã từ chối'], ['all', 'Tất cả']].map(([v, l]) => (
            <button key={v} className={`btn ${filter === v ? '' : 'secondary'}`} onClick={() => setFilter(v)}>{l}</button>
          ))}
        </div>

        {users.length === 0 && <p style={{ color: '#8A7158' }}>Không có yêu cầu nào.</p>}

        {users.map((u) => {
          const age = calcAge(u.birthday)
          return (
            <div key={u.id} className="card" style={{ marginBottom: 14, display: 'flex', gap: 16 }}>
              {imageUrls[u.id] ? (
                <img src={imageUrls[u.id]} style={{ width: 160, height: 110, objectFit: 'cover', borderRadius: 8, border: '1px solid var(--line)' }} />
              ) : (
                <div style={{ width: 160, height: 110, background: '#EFE2CF', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, color: '#8A7158' }}>
                  Chưa có ảnh
                </div>
              )}

              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700 }}>{u.full_name || u.email}</div>
                <div style={{ fontSize: 13, color: '#8A7158' }}>{u.email} {u.phone && `• ${u.phone}`}</div>
                <div style={{ fontSize: 13, marginTop: 4 }}>
                  Ngày sinh: {u.birthday ? new Date(u.birthday).toLocaleDateString('vi-VN') : 'chưa khai'}
                  {age != null && <span style={{ marginLeft: 6, fontWeight: 700, color: age < 16 ? 'var(--chili)' : 'var(--herb)' }}>({age} tuổi)</span>}
                </div>
                <div style={{ marginTop: 6 }}>
                  Trạng thái:{' '}
                  {u.student_verification_status === 'pending' && <span className="ticket-status status-pending">Đang chờ duyệt</span>}
                  {u.student_verification_status === 'approved' && <span className="ticket-status status-done">Đã duyệt</span>}
                  {u.student_verification_status === 'rejected' && <span className="ticket-status status-cancelled">Đã từ chối</span>}
                </div>
                {u.student_verification_note && <p style={{ fontSize: 12, color: 'var(--chili)', marginTop: 4 }}>Ghi chú: {u.student_verification_note}</p>}

                {u.student_verification_status === 'pending' && (
                  <div style={{ marginTop: 10, display: 'flex', gap: 8 }}>
                    <button className="btn" style={{ width: 'auto' }} onClick={() => handleApprove(u.id)}>✓ Duyệt</button>
                    <input
                      placeholder="Lý do từ chối (không bắt buộc)"
                      style={{ width: 220 }}
                      value={rejectNote[u.id] || ''}
                      onChange={(e) => setRejectNote({ ...rejectNote, [u.id]: e.target.value })}
                    />
                    <button className="btn secondary" style={{ width: 'auto' }} onClick={() => handleReject(u.id)}>✕ Từ chối</button>
                  </div>
                )}
              </div>
            </div>
          )
        })}
      </main>
    </div>
  )
}
