## Subhead Offices — per-route view-only dashboard

Each route gets a "subhead office" (destination office) that anyone with the shared password can sign into to watch the route's activity on a live map. View-only. Max 2 devices logged in at the same time per office.

### What you'll get

1. **Subhead office per route** — admin sets name, town, GPS point, and a shared 4–8 char access code per office.
2. **Shared login page** at `/subhead` — pick your route, enter the access code. No personal account needed.
3. **2-device cap** — each office tracks active sessions; a 3rd device is refused with "Maximum 2 devices already signed in".
4. **Live map view** — OpenStreetMap (no API key) centred on the branch, with a coloured pin for every route's subhead office:
   - 🟢 Green — active in the last 15 min (loads being recorded)
   - 🟠 Orange — quiet (15–60 min since last load)
   - 🔴 Red — no activity in the last 60 min
   - Pin click → today's load count, last load time, last plate, overload count.
5. **Realtime** — pins recolour automatically as marshals log new loads (uses the existing `loads` realtime channel).

### Technical details

**Database (new tables):**
- `subhead_offices` — `route_id`, `branch_id`, `name`, `town`, `lat`, `lng`, `access_code_hash` (bcrypt-style hash, never plain text), `created_at`. Unique on `route_id`.
- `subhead_sessions` — `office_id`, `device_token` (random uuid stored in browser localStorage), `user_agent`, `last_seen_at`. Used to enforce the 2-device cap.
- RLS: super_admin manages offices; offices/sessions read via a server function (no direct client access for code/hash).

**Auth model:**
- Not a Supabase auth user — the subhead login is a lightweight token-based session handled by a `createServerFn` (`subheadLogin`, `subheadHeartbeat`, `subheadLogout`). The server validates the access code, prunes stale sessions (>30 min idle), enforces the 2-device limit, and returns a `device_token`.
- Browser stores `{office_id, device_token}` in localStorage; heartbeat every 60s keeps the slot alive.

**Map:**
- Library: `react-leaflet` + `leaflet` (free, OSM tiles, no API key).
- Each route's office uses its `lat/lng`. Marker colour computed from the latest `loads.recorded_at` for that route.

**Admin:**
- New page `/admin/subheads` — list/create/edit offices, set/reset access code (shown once on creation), view active sessions, force-logout a device.

**Routes added:**
- `src/routes/subhead.tsx` — login + map view (single route, switches between login form and map after auth).
- `src/routes/admin/subheads.tsx` — admin CRUD.
- Server fns in `src/lib/subhead.functions.ts`.

**Notes:**
- "GIS map" is an interactive Leaflet map, not satellite imagery (which needs a paid key like Mapbox/Google). If you want satellite later, we can swap tile providers.
- Lat/lng entry: admin form accepts decimal coords; we'll prefill with the Kuwait branch centre and let admin drag the pin or paste coords from Google Maps.
