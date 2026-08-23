import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Check frontend/.env or .env.example')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type Database = {
  public: {
    Tables: {
      branches: {
        Row: { id: string; name: string; code: string; created_at: string }
        Insert: { id?: string; name: string; code: string }
        Update: { id?: string; name?: string; code?: string }
      }
      // Extend with routes, vehicles, load_records, users, etc.
    }
  }
}
