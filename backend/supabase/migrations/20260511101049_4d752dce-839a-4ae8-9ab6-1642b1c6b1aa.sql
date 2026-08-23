
-- ============ ENUMS ============
CREATE TYPE public.app_role AS ENUM ('super_admin', 'management', 'marshal', 'patroller');
CREATE TYPE public.owner_status AS ENUM ('pending', 'approved', 'suspended');
CREATE TYPE public.load_direction AS ENUM ('outbound', 'inbound'); -- outbound=township->town, inbound=town->township

-- ============ PROFILES ============
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  surname TEXT,
  id_number TEXT,
  contact TEXT,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============ USER ROLES ============
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

-- helper: any staff role (admin or management) can read all
CREATE OR REPLACE FUNCTION public.is_staff(_user_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role IN ('super_admin','management')
  )
$$;

-- ============ BRANCHES / RANKS / ROUTES ============
CREATE TABLE public.branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.ranks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  is_main BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (branch_id, code)
);
ALTER TABLE public.ranks ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (branch_id, code)
);
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- which routes are served from which ranks
CREATE TABLE public.rank_routes (
  rank_id UUID NOT NULL REFERENCES public.ranks(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  PRIMARY KEY (rank_id, route_id)
);
ALTER TABLE public.rank_routes ENABLE ROW LEVEL SECURITY;

-- ============ OWNERS / VEHICLES ============
CREATE TABLE public.owners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES public.branches(id),
  full_name TEXT NOT NULL,
  surname TEXT NOT NULL,
  date_of_birth DATE,
  id_number TEXT NOT NULL,
  contact TEXT NOT NULL,
  email TEXT NOT NULL,
  status owner_status NOT NULL DEFAULT 'pending',
  owner_code TEXT UNIQUE, -- generated on approval
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_at TIMESTAMPTZ
);
ALTER TABLE public.owners ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.owners(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES public.branches(id),
  primary_route_id UUID REFERENCES public.routes(id),
  number_plate TEXT NOT NULL UNIQUE,
  make TEXT,
  model TEXT,
  seats INTEGER NOT NULL DEFAULT 15,
  qr_token TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(12), 'hex'),
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- ============ MARSHAL ASSIGNMENTS ============
CREATE TABLE public.marshal_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES public.branches(id),
  route_id UUID NOT NULL REFERENCES public.routes(id),
  rank_id UUID REFERENCES public.ranks(id),
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.marshal_assignments ENABLE ROW LEVEL SECURITY;

-- ============ LOADS ============
CREATE TABLE public.loads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES public.vehicles(id),
  number_plate TEXT NOT NULL,
  branch_id UUID NOT NULL REFERENCES public.branches(id),
  rank_id UUID NOT NULL REFERENCES public.ranks(id),
  route_id UUID NOT NULL REFERENCES public.routes(id),
  direction load_direction NOT NULL DEFAULT 'outbound',
  seats_loaded INTEGER NOT NULL DEFAULT 15,
  overload BOOLEAN NOT NULL DEFAULT false,
  comment TEXT,
  marshal_id UUID REFERENCES auth.users(id),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.loads ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_loads_vehicle_day ON public.loads (vehicle_id, recorded_at);
CREATE INDEX idx_loads_rank_day ON public.loads (rank_id, recorded_at);
CREATE INDEX idx_loads_route_day ON public.loads (route_id, recorded_at);

-- ============ SETTINGS ============
CREATE TABLE public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
INSERT INTO public.app_settings (key, value) VALUES ('daily_load_cap', '10'::jsonb);

-- ============ TRIGGERS ============
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, surname, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name',''),
    COALESCE(NEW.raw_user_meta_data->>'surname',''),
    NEW.email
  );
  -- default role: marshal (admins promote later)
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'marshal');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- generate owner_code on approval
CREATE OR REPLACE FUNCTION public.set_owner_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'approved' AND NEW.owner_code IS NULL THEN
    NEW.owner_code := 'CDT-' || upper(substr(replace(NEW.id::text,'-',''), 1, 8));
    NEW.approved_at := now();
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_set_owner_code BEFORE UPDATE ON public.owners
FOR EACH ROW EXECUTE FUNCTION public.set_owner_code();

-- ============ RLS POLICIES ============
-- profiles: own + staff
CREATE POLICY "profiles_self_read" ON public.profiles FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_staff(auth.uid()));
CREATE POLICY "profiles_self_update" ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid());
CREATE POLICY "profiles_admin_all" ON public.profiles FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- user_roles: read self, admin manages
CREATE POLICY "roles_self_read" ON public.user_roles FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_staff(auth.uid()));
CREATE POLICY "roles_admin_manage" ON public.user_roles FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- branches/ranks/routes: public read, admin write
CREATE POLICY "branches_read" ON public.branches FOR SELECT USING (true);
CREATE POLICY "branches_admin" ON public.branches FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "ranks_read" ON public.ranks FOR SELECT USING (true);
CREATE POLICY "ranks_admin" ON public.ranks FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "routes_read" ON public.routes FOR SELECT USING (true);
CREATE POLICY "routes_admin" ON public.routes FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "rank_routes_read" ON public.rank_routes FOR SELECT USING (true);
CREATE POLICY "rank_routes_admin" ON public.rank_routes FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- owners: anyone can submit (insert), staff reads, admin manages
CREATE POLICY "owners_public_insert" ON public.owners FOR INSERT WITH CHECK (status = 'pending');
CREATE POLICY "owners_staff_read" ON public.owners FOR SELECT TO authenticated
  USING (public.is_staff(auth.uid()) OR status = 'approved');
CREATE POLICY "owners_admin_manage" ON public.owners FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- vehicles: anyone can submit during owner registration; authed reads active+approved
CREATE POLICY "vehicles_public_insert" ON public.vehicles FOR INSERT WITH CHECK (true);
CREATE POLICY "vehicles_authed_read" ON public.vehicles FOR SELECT TO authenticated USING (true);
CREATE POLICY "vehicles_admin_manage" ON public.vehicles FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- marshal_assignments: marshal reads own; admin manages
CREATE POLICY "ma_read_own" ON public.marshal_assignments FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_staff(auth.uid()));
CREATE POLICY "ma_admin_manage" ON public.marshal_assignments FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- loads: marshals insert own; staff reads all; marshal reads own
CREATE POLICY "loads_marshal_insert" ON public.loads FOR INSERT TO authenticated
  WITH CHECK (marshal_id = auth.uid());
CREATE POLICY "loads_read" ON public.loads FOR SELECT TO authenticated
  USING (marshal_id = auth.uid() OR public.is_staff(auth.uid()));

-- settings: read all authed, admin write
CREATE POLICY "settings_read" ON public.app_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "settings_admin_write" ON public.app_settings FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin')) WITH CHECK (public.has_role(auth.uid(),'super_admin'));

-- realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.loads;
