-- SQL reference for backend database setup and queries
-- Initialize the SQLite database with the schema:
--   sqlite3 taxi_system.db < kuwait_branch_schema.sql
-- Seed the database with sample data:
--   sqlite3 taxi_system.db < kuwait_branch_seed.sql

-- 1. See all branches
SELECT id, code, name, description, is_active, created_at
FROM branches
ORDER BY code;

-- 2. List all active routes in a branch
SELECT r.id, r.route_code, r.route_name, r.direction_label, r.daily_load_limit
FROM routes r
JOIN branches b ON r.branch_id = b.id
WHERE b.code = 'KWT' AND r.is_active = 1
ORDER BY r.route_code;

-- 3. Get active vehicles with owner and route details
SELECT v.number_plate,
       v.make,
       v.model,
       v.seat_capacity,
       v.status,
       o.first_name || ' ' || o.last_name AS owner_name,
       ru.route_name
FROM vehicles v
JOIN owners o ON v.owner_id = o.id
JOIN routes ru ON v.route_id = ru.id
WHERE v.status = 'active'
ORDER BY v.number_plate;

-- 4. Fetch recent load records with marshal info
SELECT lr.id,
       lr.recorded_at,
       v.number_plate,
       u.username AS marshal_username,
       ru.route_name,
       rk.name AS rank_name,
       lr.load_count,
       lr.passenger_count
FROM load_records lr
JOIN vehicles v ON lr.vehicle_id = v.id
JOIN users u ON lr.marshal_user_id = u.id
JOIN routes ru ON lr.route_id = ru.id
JOIN ranks rk ON lr.rank_id = rk.id
ORDER BY lr.recorded_at DESC
LIMIT 100;

-- 5. Daily route summary for dashboards
SELECT lr.route_id,
       ru.route_name,
       date(lr.recorded_at) AS report_date,
       COUNT(*) AS record_count,
       SUM(lr.load_count) AS total_loads
FROM load_records lr
JOIN routes ru ON lr.route_id = ru.id
GROUP BY lr.route_id, date(lr.recorded_at)
ORDER BY report_date DESC, ru.route_code;
