// SERVER-ONLY Supabase client — uses the SECRET/service-role key.
// This bypasses Row Level Security entirely. Never import this file from
// client-side code — the `.server.ts` suffix is this project's convention
// (see eslint.config.js) for modules TanStack Start keeps out of the client bundle.
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL as string;
const supabaseSecretKey = process.env.SUPABASE_SECRET_KEY as string;

if (!supabaseUrl || !supabaseSecretKey) {
  throw new Error(
    "Missing SUPABASE_URL or SUPABASE_SECRET_KEY server environment variables."
  );
}

export const supabaseAdmin = createClient(supabaseUrl, supabaseSecretKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});
