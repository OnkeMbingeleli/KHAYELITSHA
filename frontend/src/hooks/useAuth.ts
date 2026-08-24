import { useEffect, useState } from 'react'
import { supabase } from '../integrations/supabase/client'
import type { User } from '@supabase/supabase-js'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let mounted = true

    supabase.auth.getSession().then(({ data: { session }, error }) => {
      if (!mounted) return
      if (error) setError(error.message)
      setUser(session?.user ?? null)
      setLoading(false)
    })

    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!mounted) return
      setUser(session?.user ?? null)
      setLoading(false)
    })

    return () => {
      mounted = false
      data.subscription.unsubscribe()
    }
  }, [])

  const login = async (email: string, password: string) => {
    setError(null)
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (error) {
      setError(error.message)
      throw error
    }
    return data
  }

  const logout = async () => {
    const { error } = await supabase.auth.signOut()
    if (error) {
      setError(error.message)
      throw error
    }
    setUser(null)
  }

  return { user, loading, error, login, logout }
}
