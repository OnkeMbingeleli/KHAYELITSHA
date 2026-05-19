
CREATE TABLE public.subhead_offices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL UNIQUE,
  branch_id uuid NOT NULL,
  name text NOT NULL,
  town text,
  lat double precision NOT NULL DEFAULT -26.2041,
  lng double precision NOT NULL DEFAULT 28.0473,
  access_code_hash text NOT NULL,
  access_code_salt text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.subhead_offices ENABLE ROW LEVEL SECURITY;

CREATE POLICY so_admin_all ON public.subhead_offices
  FOR ALL TO authenticated
  USING (has_role(auth.uid(),'super_admin'))
  WITH CHECK (has_role(auth.uid(),'super_admin'));

CREATE POLICY so_staff_read ON public.subhead_offices
  FOR SELECT TO authenticated
  USING (is_staff(auth.uid()));

CREATE TABLE public.subhead_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES public.subhead_offices(id) ON DELETE CASCADE,
  device_token text NOT NULL UNIQUE,
  user_agent text,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_subhead_sessions_office ON public.subhead_sessions(office_id, last_seen_at DESC);

ALTER TABLE public.subhead_sessions ENABLE ROW LEVEL SECURITY;

-- Sessions are server-managed only; admin can view
CREATE POLICY ss_admin_all ON public.subhead_sessions
  FOR ALL TO authenticated
  USING (has_role(auth.uid(),'super_admin'))
  WITH CHECK (has_role(auth.uid(),'super_admin'));
