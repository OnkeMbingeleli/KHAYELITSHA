-- =============================================
-- TAXI SYSTEM SQL REFERENCE QUERIES
-- =============================================
-- Comprehensive collection of useful SQL queries for the Taxi Management System
-- Organized by category for easy reference

-- =============================================
-- DATABASE STATUS & INFO QUERIES
-- =============================================

-- 1. Check database tables and structure
SELECT name, type, sql FROM sqlite_master WHERE type IN ('table', 'view', 'index') ORDER BY type, name;

-- 2. Get table row counts
SELECT
    'branches' AS table_name, COUNT(*) AS row_count FROM branches
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'owners', COUNT(*) FROM owners
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'routes', COUNT(*) FROM routes
UNION ALL
SELECT 'load_records', COUNT(*) FROM load_records
UNION ALL
SELECT 'patrol_reports', COUNT(*) FROM patrol_reports
UNION ALL
SELECT 'vehicle_inspections', COUNT(*) FROM vehicle_inspections
ORDER BY table_name;

-- 3. Database schema version and info
PRAGMA database_list;
PRAGMA foreign_keys;
PRAGMA table_info(branches);

-- =============================================
-- BRANCH & ORGANIZATION QUERIES
-- =============================================

-- 4. List all branches with statistics
SELECT
    b.id,
    b.code,
    b.name,
    b.description,
    b.is_active,
    b.created_at,
    COUNT(DISTINCT r.id) AS total_routes,
    COUNT(DISTINCT o.id) AS total_owners,
    COUNT(DISTINCT v.id) AS total_vehicles,
    COUNT(DISTINCT u.id) AS total_users
FROM branches b
LEFT JOIN routes r ON b.id = r.branch_id
LEFT JOIN owners o ON b.id = o.branch_id
LEFT JOIN vehicles v ON b.id = v.branch_id
LEFT JOIN users u ON b.id = u.branch_id
GROUP BY b.id, b.code, b.name, b.description, b.is_active, b.created_at
ORDER BY b.code;

-- 5. Active routes per branch
SELECT
    b.code AS branch_code,
    b.name AS branch_name,
    r.route_code,
    r.route_name,
    r.direction_label,
    r.daily_load_limit,
    COUNT(DISTINCT v.id) AS active_vehicles
FROM branches b
JOIN routes r ON b.id = r.branch_id AND r.is_active = 1
LEFT JOIN vehicles v ON r.id = v.route_id AND v.status = 'active'
GROUP BY b.code, b.name, r.route_code, r.route_name, r.direction_label, r.daily_load_limit
ORDER BY b.code, r.route_code;

-- =============================================
-- USER MANAGEMENT QUERIES
-- =============================================

-- 6. User summary by role
SELECT
    role,
    COUNT(*) AS user_count,
    COUNT(CASE WHEN is_active = 1 THEN 1 END) AS active_users,
    GROUP_CONCAT(DISTINCT branch_id) AS branch_ids
FROM users
GROUP BY role
ORDER BY user_count DESC;

-- 7. Detailed user information
SELECT
    u.id,
    u.username,
    u.role,
    u.first_name || ' ' || u.last_name AS full_name,
    u.phone,
    u.email,
    b.name AS branch_name,
    u.is_active,
    u.created_at,
    COUNT(DISTINCT ura.route_id) AS assigned_routes,
    COUNT(DISTINCT rd.id) AS registered_devices
FROM users u
LEFT JOIN branches b ON u.branch_id = b.id
LEFT JOIN user_route_assignments ura ON u.id = ura.user_id AND ura.is_primary = 1
LEFT JOIN registered_devices rd ON u.id = rd.user_id
GROUP BY u.id, u.username, u.role, u.first_name, u.last_name, u.phone, u.email, b.name, u.is_active, u.created_at
ORDER BY u.role, u.last_name, u.first_name;

-- =============================================
-- OWNER & VEHICLE QUERIES
-- =============================================

-- 8. Owner summary with vehicle counts
SELECT
    o.id,
    o.owner_code,
    o.first_name || ' ' || o.last_name AS owner_name,
    o.phone,
    o.email,
    o.status,
    b.name AS branch_name,
    COUNT(DISTINCT v.id) AS total_vehicles,
    COUNT(DISTINCT CASE WHEN v.status = 'active' THEN v.id END) AS active_vehicles,
    GROUP_CONCAT(DISTINCT r.route_name) AS routes
FROM owners o
LEFT JOIN branches b ON o.branch_id = b.id
LEFT JOIN owner_route_memberships orm ON o.id = orm.owner_id AND orm.is_active = 1
LEFT JOIN routes r ON orm.route_id = r.id
LEFT JOIN vehicles v ON o.id = v.owner_id
GROUP BY o.id, o.owner_code, o.first_name, o.last_name, o.phone, o.email, o.status, b.name
ORDER BY o.owner_code;

-- 9. Vehicle fleet overview
SELECT
    v.id,
    v.number_plate,
    v.make,
    v.model,
    v.seat_capacity,
    v.status,
    o.first_name || ' ' || o.last_name AS owner_name,
    r.route_name,
    b.name AS branch_name,
    v.registered_at,
    v.loads_today,
    CASE
        WHEN v.location_updated IS NOT NULL THEN
            ROUND(julianday('now') - julianday(v.location_updated)) || ' days ago'
        ELSE 'Never'
    END AS last_location_update
FROM vehicles v
JOIN owners o ON v.owner_id = o.id
JOIN routes r ON v.route_id = r.id
JOIN branches b ON v.branch_id = b.id
ORDER BY v.status, v.number_plate;

-- 10. Vehicles by status
SELECT
    status,
    COUNT(*) AS vehicle_count,
    ROUND(AVG(seat_capacity), 1) AS avg_capacity,
    GROUP_CONCAT(number_plate) AS plates
FROM vehicles
GROUP BY status
ORDER BY vehicle_count DESC;

-- =============================================
-- OPERATIONAL QUERIES
-- =============================================

-- 11. Today's load records summary
SELECT
    date(lr.recorded_at) AS load_date,
    COUNT(*) AS total_records,
    SUM(lr.load_count) AS total_loads,
    SUM(lr.passenger_count) AS total_passengers,
    AVG(lr.load_count) AS avg_loads_per_record,
    COUNT(DISTINCT lr.vehicle_id) AS vehicles_used,
    COUNT(DISTINCT lr.marshal_user_id) AS marshals_active
FROM load_records lr
WHERE date(lr.recorded_at) = date('now')
GROUP BY date(lr.recorded_at);

-- 12. Load records by route (last 7 days)
SELECT
    r.route_name,
    date(lr.recorded_at) AS load_date,
    COUNT(*) AS record_count,
    SUM(lr.load_count) AS total_loads,
    SUM(lr.passenger_count) AS total_passengers,
    ROUND(AVG(lr.load_count), 2) AS avg_load_per_record
FROM load_records lr
JOIN routes r ON lr.route_id = r.id
WHERE lr.recorded_at >= datetime('now', '-7 days')
GROUP BY r.route_name, date(lr.recorded_at)
ORDER BY r.route_name, load_date DESC;

-- 13. Vehicle performance (loads per day)
SELECT
    v.number_plate,
    v.make || ' ' || v.model AS vehicle_model,
    date(lr.recorded_at) AS load_date,
    COUNT(*) AS records_count,
    SUM(lr.load_count) AS total_loads,
    SUM(lr.passenger_count) AS total_passengers
FROM vehicles v
LEFT JOIN load_records lr ON v.id = lr.vehicle_id
    AND lr.recorded_at >= datetime('now', '-30 days')
GROUP BY v.id, v.number_plate, v.make, v.model, date(lr.recorded_at)
ORDER BY v.number_plate, load_date DESC;

-- =============================================
-- PATROL & INSPECTION QUERIES
-- =============================================

-- 14. Patrol reports summary
SELECT
    pr.report_category,
    pr.severity,
    COUNT(*) AS report_count,
    GROUP_CONCAT(DISTINCT u.first_name || ' ' || u.last_name) AS patrollers,
    MAX(pr.reported_at) AS latest_report
FROM patrol_reports pr
JOIN users u ON pr.patroller_user_id = u.id
GROUP BY pr.report_category, pr.severity
ORDER BY pr.report_category, pr.severity;

-- 15. Vehicle inspection results
SELECT
    v.number_plate,
    vi.roadworthy_status,
    COUNT(*) AS inspection_count,
    MAX(vi.inspected_at) AS last_inspection,
    ROUND(AVG(CASE WHEN vi.windscreen_ok = 1 THEN 1 ELSE 0 END) * 100, 1) || '%' AS windscreen_pass_rate,
    ROUND(AVG(CASE WHEN vi.tires_ok = 1 THEN 1 ELSE 0 END) * 100, 1) || '%' AS tires_pass_rate,
    ROUND(AVG(CASE WHEN vi.brakes_ok = 1 THEN 1 ELSE 0 END) * 100, 1) || '%' AS brakes_pass_rate
FROM vehicle_inspections vi
JOIN vehicles v ON vi.vehicle_id = v.id
GROUP BY v.id, v.number_plate, vi.roadworthy_status
ORDER BY v.number_plate;

-- =============================================
-- FINANCIAL & REPORTING QUERIES
-- =============================================

-- 16. Billing rates by branch
SELECT
    b.name AS branch_name,
    br.rate_name,
    br.amount_per_load,
    br.effective_from,
    br.effective_to,
    br.is_active
FROM billing_rates br
JOIN branches b ON br.branch_id = b.id
ORDER BY b.name, br.effective_from DESC;

-- 17. Monthly owner reports
SELECT
    o.owner_code,
    o.first_name || ' ' || o.last_name AS owner_name,
    mr.report_month,
    mr.total_loads,
    mr.total_amount,
    mr.delivery_status,
    mr.generated_at
FROM monthly_reports mr
JOIN owners o ON mr.owner_id = o.id
ORDER BY mr.report_month DESC, o.owner_code;

-- 18. Association invoices
SELECT
    b.name AS branch_name,
    ai.invoice_month,
    ai.total_loads,
    ai.amount_due,
    ai.payment_status,
    ai.issued_at,
    ai.due_at,
    ai.paid_at
FROM association_invoices ai
JOIN branches b ON ai.branch_id = b.id
ORDER BY ai.invoice_month DESC, b.name;

-- =============================================
-- DASHBOARD & ANALYTICS QUERIES
-- =============================================

-- 19. Daily load summary (last 30 days)
SELECT
    date(lr.recorded_at) AS load_date,
    COUNT(DISTINCT lr.vehicle_id) AS vehicles_used,
    COUNT(DISTINCT lr.route_id) AS routes_active,
    COUNT(*) AS total_records,
    SUM(lr.load_count) AS total_loads,
    SUM(lr.passenger_count) AS total_passengers,
    ROUND(AVG(lr.load_count), 2) AS avg_load_per_record
FROM load_records lr
WHERE lr.recorded_at >= datetime('now', '-30 days')
GROUP BY date(lr.recorded_at)
ORDER BY load_date DESC;

-- 20. Route performance comparison
SELECT
    r.route_name,
    COUNT(DISTINCT v.id) AS total_vehicles,
    COUNT(lr.id) AS total_load_records,
    SUM(lr.load_count) AS total_loads,
    ROUND(AVG(lr.load_count), 2) AS avg_load_per_record,
    MAX(lr.recorded_at) AS last_activity
FROM routes r
LEFT JOIN vehicles v ON r.id = v.route_id AND v.status = 'active'
LEFT JOIN load_records lr ON r.id = lr.route_id
    AND lr.recorded_at >= datetime('now', '-30 days')
GROUP BY r.id, r.route_name
ORDER BY total_loads DESC;

-- 21. Top performing vehicles (by load count)
SELECT
    v.number_plate,
    v.make || ' ' || v.model AS vehicle_model,
    o.first_name || ' ' || o.last_name AS owner_name,
    r.route_name,
    COUNT(lr.id) AS total_records,
    SUM(lr.load_count) AS total_loads,
    SUM(lr.passenger_count) AS total_passengers,
    ROUND(AVG(lr.load_count), 2) AS avg_load_per_record,
    MAX(lr.recorded_at) AS last_load
FROM vehicles v
JOIN owners o ON v.owner_id = o.id
JOIN routes r ON v.route_id = r.id
LEFT JOIN load_records lr ON v.id = lr.vehicle_id
    AND lr.recorded_at >= datetime('now', '-30 days')
GROUP BY v.id, v.number_plate, v.make, v.model, o.first_name, o.last_name, r.route_name
ORDER BY total_loads DESC
LIMIT 20;

-- 22. System health check
SELECT
    'Total Branches' AS metric, COUNT(*) AS value FROM branches
UNION ALL
SELECT 'Active Branches', COUNT(*) FROM branches WHERE is_active = 1
UNION ALL
SELECT 'Total Users', COUNT(*) FROM users
UNION ALL
SELECT 'Active Users', COUNT(*) FROM users WHERE is_active = 1
UNION ALL
SELECT 'Total Owners', COUNT(*) FROM owners
UNION ALL
SELECT 'Active Owners', COUNT(*) FROM owners WHERE status = 'active'
UNION ALL
SELECT 'Total Vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'Active Vehicles', COUNT(*) FROM vehicles WHERE status = 'active'
UNION ALL
SELECT 'Total Routes', COUNT(*) FROM routes
UNION ALL
SELECT 'Active Routes', COUNT(*) FROM routes WHERE is_active = 1
UNION ALL
SELECT 'Load Records (30 days)', COUNT(*) FROM load_records WHERE recorded_at >= datetime('now', '-30 days')
UNION ALL
SELECT 'Patrol Reports (30 days)', COUNT(*) FROM patrol_reports WHERE reported_at >= datetime('now', '-30 days')
UNION ALL
SELECT 'Vehicle Inspections (30 days)', COUNT(*) FROM vehicle_inspections WHERE inspected_at >= datetime('now', '-30 days');

-- =============================================
-- MAINTENANCE & CLEANUP QUERIES
-- =============================================

-- 23. Find orphaned records (should return empty in healthy database)
SELECT 'Orphaned vehicles' AS issue, COUNT(*) AS count
FROM vehicles v
LEFT JOIN owners o ON v.owner_id = o.id
WHERE o.id IS NULL
UNION ALL
SELECT 'Orphaned load records', COUNT(*)
FROM load_records lr
LEFT JOIN vehicles v ON lr.vehicle_id = v.id
WHERE v.id IS NULL
UNION ALL
SELECT 'Orphaned user assignments', COUNT(*)
FROM user_route_assignments ura
LEFT JOIN users u ON ura.user_id = u.id
WHERE u.id IS NULL;

-- 24. Data cleanup - remove old audit logs (older than 1 year)
-- DELETE FROM audit_logs WHERE created_at < datetime('now', '-1 year');

-- 25. Archive old load records (older than 2 years)
-- INSERT INTO load_records_archive SELECT * FROM load_records WHERE recorded_at < datetime('now', '-2 years');
-- DELETE FROM load_records WHERE recorded_at < datetime('now', '-2 years');

-- =============================================
-- USEFUL UTILITY QUERIES
-- =============================================

-- 26. Search vehicles by number plate
-- SELECT * FROM vehicles WHERE number_plate LIKE '%SEARCH_TERM%';

-- 27. Find users by name or email
-- SELECT * FROM users WHERE first_name || ' ' || last_name LIKE '%SEARCH_TERM%' OR email LIKE '%SEARCH_TERM%';

-- 28. Get route details with assigned ranks
SELECT
    r.route_code,
    r.route_name,
    r.direction_label,
    rk.code AS rank_code,
    rk.name AS rank_name,
    rk.rank_type,
    ra.assignment_type,
    ra.sequence_no
FROM routes r
JOIN route_rank_assignments ra ON r.id = ra.route_id
JOIN ranks rk ON ra.rank_id = rk.id
ORDER BY r.route_code, ra.sequence_no;

-- 29. Export data for backup
-- .output backup_$(date +%Y%m%d).sql
-- .dump
-- .output stdout

-- 30. Database integrity check
PRAGMA integrity_check;

-- =============================================
-- END OF SQL REFERENCE
-- =============================================