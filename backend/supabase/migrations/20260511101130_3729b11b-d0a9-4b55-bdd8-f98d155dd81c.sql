
-- Harden function search paths (idempotent recreate)
CREATE OR REPLACE FUNCTION public.set_owner_code()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status = 'approved' AND NEW.owner_code IS NULL THEN
    NEW.owner_code := 'CDT-' || upper(substr(replace(NEW.id::text,'-',''), 1, 8));
    NEW.approved_at := now();
  END IF;
  RETURN NEW;
END;
$$;

-- Lock down EXECUTE on helper functions
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, app_role) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_staff(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.set_owner_code() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- Tighten vehicle public insert: only when owner is still pending
DROP POLICY IF EXISTS "vehicles_public_insert" ON public.vehicles;
CREATE POLICY "vehicles_public_insert" ON public.vehicles FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.owners o WHERE o.id = vehicles.owner_id AND o.status = 'pending'));

-- ============ SEED ============
INSERT INTO public.branches (name, code) VALUES ('Kuwait', 'KWT') ON CONFLICT DO NOTHING;

WITH b AS (SELECT id FROM public.branches WHERE code='KWT')
INSERT INTO public.ranks (branch_id, name, code, is_main)
SELECT b.id, n.name, n.code, n.is_main FROM b,
(VALUES
  ('Rank A','RA',true),
  ('Rank B','RB',false),
  ('Rank C','RC',false),
  ('Rank D','RD',false),
  ('Rank E','RE',false),
  ('Rank F','RF',false),
  ('Somerset Spot','SS',false),
  ('Site B Spot','SB',false),
  ('Kweza Spot','KZ',false)
) AS n(name,code,is_main)
ON CONFLICT DO NOTHING;

WITH b AS (SELECT id FROM public.branches WHERE code='KWT')
INSERT INTO public.routes (branch_id, name, code)
SELECT b.id, r.name, r.code FROM b,
(VALUES
  ('Cape Town','CT'),
  ('Claremont','CL'),
  ('Wynberg','WY'),
  ('Fish Hoek','FH'),
  ('Sea Point','SP'),
  ('Mowbray','MO'),
  ('Bellville','BV'),
  ('Mitchells Plain','MP'),
  ('Retreat','RT'),
  ('Plumstead','PL'),
  ('Kenilworth','KN'),
  ('Lansdowne','LD'),
  ('Hanover Park','HP'),
  ('Athlone','AT'),
  ('Manenberg','MN'),
  ('Gugulethu','GU'),
  ('Nyanga','NY'),
  ('Phillipi','PH'),
  ('Eerste River','ER'),
  ('Strand','ST'),
  ('Somerset West','SW')
) AS r(name,code)
ON CONFLICT DO NOTHING;

-- map every route to every rank by default (admin can prune later)
INSERT INTO public.rank_routes (rank_id, route_id)
SELECT ra.id, ro.id
FROM public.ranks ra
JOIN public.routes ro ON ro.branch_id = ra.branch_id
ON CONFLICT DO NOTHING;
