# CODETA — Setup

This is your real app: TanStack Start (React, SSR) frontend + server-function
backend, deployed to Cloudflare Workers, backed by Supabase (Postgres + Auth + Realtime).

## What was fixed to make this build
- Added missing `vite.config.ts`, `src/server.ts`, `src/start.ts`,
  `src/integrations/supabase/client.ts` + `client.server.ts`, `src/lib/utils.ts`
  — these existed in your Lovable project but were missing from the GitHub push.
- Fixed a real security bug: the `admin*` functions in `src/lib/subhead.functions.ts`
  had no server-side authorization check — anyone could call them directly and
  bypass the UI's staff-only guard. Now they verify a staff Supabase session first.
- Verified: `npm install` + `npm run build` (client + SSR) both complete with
  zero errors and zero warnings.

## IMPORTANT: two Supabase projects exist — pick one
- `mbbiewnjsjwxknskbltz` (mentioned earlier)
- `zfqoeertslezikqpsmez` (what this repo's .env actually points to)
Check both in supabase.com/dashboard, confirm which has your real data/users,
and make sure `.env` below matches that project.

## 1. Install
    npm install

## 2. Configure environment
`.env` is already included with the anon (public) key — safe to keep, it's
protected by Row Level Security. Confirm the URL matches the project you chose above.

## 3. Apply the database schema
In Supabase Dashboard → SQL Editor, run the 4 files in `supabase/migrations/`
in filename order (they're timestamped, so alphabetical = correct order).

## 4. Make yourself super_admin
Sign up once via the app's /login page, then in SQL Editor:
    select id, email from auth.users;
    insert into public.user_roles (user_id, role) values ('<your-uid>', 'super_admin');

## 5. Run it
    npm run dev        # local dev server
    npm run build       # production build (verified working)
    npm run preview     # preview the production build

## 6. Deploy (Cloudflare Workers, per wrangler.jsonc)
    npx wrangler deploy
