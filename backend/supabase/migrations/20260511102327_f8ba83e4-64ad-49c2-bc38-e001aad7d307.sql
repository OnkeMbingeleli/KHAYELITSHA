
-- Enums for patrol module
CREATE TYPE public.patrol_report_type AS ENUM ('overload','misconduct','roadworthy','marshal_oversight');
CREATE TYPE public.patrol_severity AS ENUM ('low','medium','high');
CREATE TYPE public.patrol_status AS ENUM ('open','reviewed','resolved');

-- Helper function: is this user a patroller?
CREATE OR REPLACE FUNCTION public.is_patroller(_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = 'patroller')
$$;

-- Patroller assignments (which ranks/routes a patroller covers)
CREATE TABLE public.patroller_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  branch_id uuid NOT NULL,
  rank_id uuid,
  route_id uuid,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.patroller_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY pa_admin_manage ON public.patroller_assignments
  FOR ALL TO authenticated
  USING (has_role(auth.uid(),'super_admin'))
  WITH CHECK (has_role(auth.uid(),'super_admin'));

CREATE POLICY pa_read_own ON public.patroller_assignments
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR is_staff(auth.uid()));

-- Patrol reports
CREATE TABLE public.patrol_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patroller_id uuid NOT NULL,
  branch_id uuid NOT NULL,
  rank_id uuid,
  route_id uuid,
  number_plate text,
  vehicle_id uuid,
  related_load_id uuid,
  report_type public.patrol_report_type NOT NULL,
  severity public.patrol_severity NOT NULL DEFAULT 'medium',
  pass_fail boolean,
  description text NOT NULL,
  status public.patrol_status NOT NULL DEFAULT 'open',
  resolution_note text,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by uuid
);
ALTER TABLE public.patrol_reports ENABLE ROW LEVEL SECURITY;

-- Patrollers can insert their own reports
CREATE POLICY pr_patroller_insert ON public.patrol_reports
  FOR INSERT TO authenticated
  WITH CHECK (patroller_id = auth.uid() AND is_patroller(auth.uid()));

-- Patrollers see their own reports; staff see all
CREATE POLICY pr_read ON public.patrol_reports
  FOR SELECT TO authenticated
  USING (patroller_id = auth.uid() OR is_staff(auth.uid()));

-- Staff can update (review/resolve)
CREATE POLICY pr_staff_update ON public.patrol_reports
  FOR UPDATE TO authenticated
  USING (is_staff(auth.uid()))
  WITH CHECK (is_staff(auth.uid()));

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.patrol_reports;

CREATE INDEX idx_patrol_reports_recorded_at ON public.patrol_reports(recorded_at DESC);
CREATE INDEX idx_patrol_reports_status ON public.patrol_reports(status);
