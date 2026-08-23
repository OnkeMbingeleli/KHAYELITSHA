Supabase integration (backend)
==============================

Steps to prepare backend for Supabase server usage:

1. Install dependency locally (run in backend/):

```bash
cd backend
npm install @supabase/server
```

2. Copy `.env.example` to `.env` and fill secrets. Keep `.env` out of git.

3. Useful Supabase CLI commands:

```bash
# login locally
supabase login

# init a local supabase directory (if not present)
supabase init

# link this folder to your project ref
supabase link --project-ref mbbiewnjsjwxknskbltz

# run migrations
supabase migration status
supabase db push # or supabase db reset depending on workflow
```

4. Use `@supabase/server` in Edge Functions or Node.js scripts for admin actions. Keep service role key only in CI/secure env.
