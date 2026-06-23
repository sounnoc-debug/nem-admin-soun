'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

export default function Home() {
  const router = useRouter()
  useEffect(() => {
    check()
  }, [router])

  async function check() {
    const { data } = await supabase.auth.getSession()
    if (!data.session) {
      router.replace('/login')
      return
    }
    const { data: profile } = await supabase
      .from('users')
      .select('role')
      .eq('id', data.session.user.id)
      .single()

    const allowedRoles = ['admin', 'staff', 'kitchen', 'shipper']
    if (!profile || !allowedRoles.includes(profile.role)) {
      await supabase.auth.signOut()
      router.replace('/login')
      return
    }
    router.replace('/dashboard')
  }
  return null
}
