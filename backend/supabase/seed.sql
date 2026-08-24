BEGIN;

-- Seed data for the active React/Supabase schema in the 202605 migrations.
-- Auth users are intentionally not created here; create them through Supabase Auth.

INSERT INTO public.app_settings (key, value)
VALUES ('daily_load_cap', '10'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

INSERT INTO public.branches (name, code)
VALUES ('Kuwait', 'KWT')
ON CONFLICT (code) DO NOTHING;

WITH branch AS (
  SELECT id FROM public.branches WHERE code = 'KWT'
), seed_ranks(name, code, is_main) AS (
  VALUES
    ('Rank A', 'RA', true),
    ('Rank B', 'RB', false),
    ('Rank C', 'RC', false),
    ('Rank D', 'RD', false),
    ('Rank E', 'RE', false),
    ('Rank F', 'RF', false),
    ('Somerset Spot', 'SS', false),
    ('Site B Spot', 'SB', false),
    ('Kweza Spot', 'KZ', false)
)
INSERT INTO public.ranks (branch_id, name, code, is_main)
SELECT branch.id, seed_ranks.name, seed_ranks.code, seed_ranks.is_main
FROM branch CROSS JOIN seed_ranks
ON CONFLICT (branch_id, code) DO NOTHING;

WITH branch AS (
  SELECT id FROM public.branches WHERE code = 'KWT'
), seed_routes(name, code) AS (
  VALUES
    ('Cape Town', 'CT'),
    ('Claremont', 'CL'),
    ('Wynberg', 'WY'),
    ('Fish Hoek', 'FH'),
    ('Sea Point', 'SP'),
    ('Mowbray', 'MO'),
    ('Bellville', 'BV'),
    ('Mitchells Plain', 'MP'),
    ('Retreat', 'RT'),
    ('Plumstead', 'PL'),
    ('Kenilworth', 'KN'),
    ('Lansdowne', 'LD'),
    ('Hanover Park', 'HP'),
    ('Athlone', 'AT'),
    ('Manenberg', 'MN'),
    ('Gugulethu', 'GU'),
    ('Nyanga', 'NY'),
    ('Phillipi', 'PH'),
    ('Eerste River', 'ER'),
    ('Strand', 'ST'),
    ('Somerset West', 'SW')
)
INSERT INTO public.routes (branch_id, name, code)
SELECT branch.id, seed_routes.name, seed_routes.code
FROM branch CROSS JOIN seed_routes
ON CONFLICT (branch_id, code) DO NOTHING;

INSERT INTO public.rank_routes (rank_id, route_id)
SELECT ranks.id, routes.id
FROM public.ranks
JOIN public.routes ON routes.branch_id = ranks.branch_id
JOIN public.branches ON branches.id = ranks.branch_id
WHERE branches.code = 'KWT'
ON CONFLICT DO NOTHING;

COMMIT;
