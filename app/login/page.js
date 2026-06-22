'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleLogin(e) {
    e.preventDefault()
    setLoading(true)
    setError('')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    setLoading(false)
    if (error) {
      setError('Sai email hoặc mật khẩu. Vui lòng thử lại.')
      return
    }
    router.replace('/dashboard')
  }

  return (
    <div className="login-wrap">
      <div className="login-box">
        <h1 style={{ fontSize: 22, marginBottom: 4 }}>🌿 Nem Admin</h1>
        <p style={{ fontSize: 13, color: '#8A7158', marginBottom: 24 }}>
          Đăng nhập để quản lý quán
        </p>
        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: 14 }}>
            <label style={{ fontSize: 13, display: 'block', marginBottom: 6 }}>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              placeholder="admin@quannem.com"
            />
          </div>
          <div style={{ marginBottom: 14 }}>
            <label style={{ fontSize: 13, display: 'block', marginBottom: 6 }}>Mật khẩu</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="••••••••"
            />
          </div>
          {error && <p className="error-text">{error}</p>}
          <button className="btn" style={{ width: '100%', marginTop: 8 }} disabled={loading}>
            {loading ? 'Đang đăng nhập...' : 'Đăng nhập'}
          </button>
        </form>
        <p style={{ fontSize: 12, color: '#8A7158', marginTop: 18 }}>
          ★ Tạo tài khoản admin đầu tiên trong Supabase &gt; Authentication &gt; Add user.
        </p>
      </div>
    </div>
  )
}
