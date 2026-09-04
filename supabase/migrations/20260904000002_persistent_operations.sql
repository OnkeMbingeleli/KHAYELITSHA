-- Persist operational alerts so route offices and head office can review them.
CREATE TABLE IF NOT EXISTS public.route_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  marshal_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
  number_plate TEXT NOT NULL,
  assigned_route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
  attempted_route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_route_alerts_branch_created
  ON public.route_alerts (branch_id, created_at DESC);

ALTER TABLE public.route_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS route_alerts_insert_own ON public.route_alerts;
CREATE POLICY route_alerts_insert_own ON public.route_alerts
  FOR INSERT TO authenticated WITH CHECK (marshal_id = auth.uid());

DROP POLICY IF EXISTS route_alerts_read_own_or_staff ON public.route_alerts;
CREATE POLICY route_alerts_read_own_or_staff ON public.route_alerts
  FOR SELECT TO authenticated
  USING (marshal_id = auth.uid() OR public.is_staff(auth.uid()));

DROP POLICY IF EXISTS route_alerts_staff_update ON public.route_alerts;
CREATE POLICY route_alerts_staff_update ON public.route_alerts
  FOR UPDATE TO authenticated
  USING (public.is_staff(auth.uid()))
  WITH CHECK (public.is_staff(auth.uid()));

CREATE TABLE IF NOT EXISTS public.emergency_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rank_id UUID REFERENCES public.ranks(id) ON DELETE SET NULL,
  route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
  category TEXT NOT NULL,
  detail TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_emergency_reports_branch_created
  ON public.emergency_reports (branch_id, created_at DESC);

ALTER TABLE public.emergency_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS emergency_reports_insert_own ON public.emergency_reports;
CREATE POLICY emergency_reports_insert_own ON public.emergency_reports
  FOR INSERT TO authenticated WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS emergency_reports_read_own_or_staff ON public.emergency_reports;
CREATE POLICY emergency_reports_read_own_or_staff ON public.emergency_reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid() OR public.is_staff(auth.uid()));

DROP POLICY IF EXISTS emergency_reports_staff_update ON public.emergency_reports;
CREATE POLICY emergency_reports_staff_update ON public.emergency_reports
  FOR UPDATE TO authenticated
  USING (public.is_staff(auth.uid()))
  WITH CHECK (public.is_staff(auth.uid()));

ALTER PUBLICATION supabase_realtime ADD TABLE public.route_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.emergency_reports;
