-- =============================================
-- TAXI SYSTEM DATABASE SEED DATA
-- =============================================
-- Comprehensive seed data for the Taxi Management System
-- Includes sample branches, users, owners, vehicles, and operational data

BEGIN TRANSACTION;

-- =============================================
-- BRANCH DATA
-- =============================================

INSERT OR IGNORE INTO branches (code, name, description)
VALUES
    ('KWT', 'Kuwait Branch', 'Pilot branch for the local taxi association system'),
    ('CTN', 'Cape Town Central', 'Main Cape Town branch covering central areas'),
    ('KHL', 'Khayelitsha Branch', 'Khayelitsha township branch');

-- =============================================
-- RANK DATA (Pickup Points)
-- =============================================

-- Kuwait Branch Ranks
INSERT OR IGNORE INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'A', 'Rank A - Site C', 'pickup' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'B', 'Rank B - Harare', 'pickup' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'C', 'Rank C - Makaza', 'pickup' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'D', 'Rank D - Town Centre', 'pickup' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'E', 'Rank E - Lingelethu', 'pickup' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'F', 'Rank F - Monwabisi', 'pickup' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'TOWN', 'Town Main Rank', 'town' FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'RETURN', 'Return Point', 'return_point' FROM branches WHERE code = 'KWT';

-- Cape Town Central Ranks
INSERT OR IGNORE INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'CT1', 'Cape Town Station', 'town' FROM branches WHERE code = 'CTN'
UNION ALL
SELECT id, 'CT2', 'Strand Street', 'town' FROM branches WHERE code = 'CTN'
UNION ALL
SELECT id, 'CT3', 'Adderley Street', 'town' FROM branches WHERE code = 'CTN';

-- =============================================
-- ROUTE DATA
-- =============================================

INSERT OR IGNORE INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'CTN', 'Cape Town Direct', 'Township to Cape Town CBD', 8 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'CLR', 'Claremont Route', 'Township to Claremont', 8 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'WYN', 'Wynberg Route', 'Township to Wynberg', 8 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'FSH', 'Fish Hoek Route', 'Township to Fish Hoek', 8 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'SEA', 'Sea Point Route', 'Township to Sea Point', 8 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'DBN', 'Durban Route', 'Township to Durban', 8 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'BEL', 'Bellville Route', 'Township to Bellville', 6 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'PAR', 'Parow Route', 'Township to Parow', 6 FROM branches WHERE code = 'KWT';

-- =============================================
-- ROUTE-RANK ASSIGNMENTS
-- =============================================

-- Assign pickup ranks to routes
INSERT OR IGNORE INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'pickup', 1
FROM routes r
CROSS JOIN ranks k
WHERE r.branch_id = k.branch_id
  AND r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN', 'BEL', 'PAR')
  AND k.code IN ('A', 'B', 'C', 'D', 'E', 'F')
  AND k.rank_type = 'pickup';

-- Assign town ranks to routes
INSERT OR IGNORE INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'town', 2
FROM routes r
JOIN ranks k ON r.branch_id = k.branch_id
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN', 'BEL', 'PAR')
  AND k.code = 'TOWN';

-- Assign return points to routes
INSERT OR IGNORE INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'return_point', 3
FROM routes r
JOIN ranks k ON r.branch_id = k.branch_id
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN', 'BEL', 'PAR')
  AND k.code = 'RETURN';

-- =============================================
-- USER DATA (System Users)
-- =============================================

INSERT OR IGNORE INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'superadmin1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'super_admin', 'Onke', 'Mbingeleli', '8001010000001', '0710000001', 'admin@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'superadmin2', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'super_admin', 'Backup', 'Admin', '8001010000002', '0710000002', 'backup@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'manager_kwt', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'management', 'Thabo', 'Mthembu', '8505120000001', '0721111111', 'manager.kwt@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'marshal_ctn_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'marshal', 'Sipho', 'Mahlangu', '9001010000001', '0722222222', 'sipho.mahlangu@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'marshal_clr_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'marshal', 'Zanele', 'Dlamini', '9001010000002', '0723333333', 'zanele.dlamini@taxiproject.co.za', id
UNION ALL
SELECT 'marshal_wyn_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'marshal', 'Thabo', 'Nene', '9001010000003', '0724444444', 'thabo.nene@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'patrol_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'patroller', 'Lerato', 'Khumalo', '9001010000004', '0725555555', 'lerato.khumalo@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'patrol_2', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'patroller', 'Ayanda', 'Nkosi', '9001010000005', '0726666666', 'ayanda.nkosi@taxiproject.co.za', id
FROM branches WHERE code = 'KWT';

-- =============================================
-- USER ROUTE ASSIGNMENTS
-- =============================================

INSERT OR IGNORE INTO user_route_assignments (user_id, route_id, is_primary)
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'CTN'
WHERE u.username = 'marshal_ctn_1'
UNION ALL
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'CLR'
WHERE u.username = 'marshal_clr_1'
UNION ALL
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'WYN'
WHERE u.username = 'marshal_wyn_1';

-- =============================================
-- OWNER DATA
-- =============================================

INSERT OR IGNORE INTO owners (branch_id, owner_code, first_name, last_name, date_of_birth, id_number, phone, email, address, preferred_report_day)
SELECT id, 'OWN-KWT-001', 'Mandla', 'Nkosi', '1980-01-01', '8001015009087', '0731111111', 'mandla.nkosi@email.co.za', '123 Main Street, Khayelitsha', 15
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'OWN-KWT-002', 'Ayanda', 'Khumalo', '1983-05-12', '8305125009087', '0732222222', 'ayanda.khumalo@email.co.za', '456 Oak Avenue, Khayelitsha', 20
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'OWN-KWT-003', 'Thabo', 'Mthembu', '1975-08-20', '7508205009087', '0733333333', 'thabo.mthembu@email.co.za', '789 Pine Road, Khayelitsha', 10
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'OWN-KWT-004', 'Zanele', 'Dlamini', '1988-12-05', '8812055009087', '0734444444', 'zanele.dlamini@email.co.za', '321 Elm Street, Khayelitsha', 25
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'OWN-KWT-005', 'Sipho', 'Mahlangu', '1978-03-15', '7803155009087', '0735555555', 'sipho.mahlangu@email.co.za', '654 Cedar Lane, Khayelitsha', 5
FROM branches WHERE code = 'KWT';

-- =============================================
-- OWNER ROUTE MEMBERSHIPS
-- =============================================

INSERT OR IGNORE INTO owner_route_memberships (owner_id, route_id, is_active)
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'CTN'
WHERE o.owner_code = 'OWN-KWT-001'
UNION ALL
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'CLR'
WHERE o.owner_code = 'OWN-KWT-002'
UNION ALL
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'WYN'
WHERE o.owner_code = 'OWN-KWT-003'
UNION ALL
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'FSH'
WHERE o.owner_code = 'OWN-KWT-004'
UNION ALL
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'SEA'
WHERE o.owner_code = 'OWN-KWT-005';

-- =============================================
-- VEHICLE DATA
-- =============================================

INSERT OR IGNORE INTO vehicles (owner_id, route_id, branch_id, number_plate, make, model, seat_capacity, qr_code_value, qr_sticker_label, office_label, status, notes)
SELECT o.id, r.id, b.id, 'CA123WP', 'Toyota', 'Hiace', 15, 'QR-KWT-CA123WP', 'CODETA|CTN|CA123WP|OWN-KWT-001|15', 'Kuwait Branch', 'active', 'Well maintained vehicle'
FROM owners o
JOIN routes r ON r.route_code = 'CTN'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-001'
UNION ALL
SELECT o.id, r.id, b.id, 'CA456WP', 'Toyota', 'Quantum', 16, 'QR-KWT-CA456WP', 'CODETA|CTN|CA456WP|OWN-KWT-001|16', 'Kuwait Branch', 'active', 'New vehicle'
FROM owners o
JOIN routes r ON r.route_code = 'CTN'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-001'
UNION ALL
SELECT o.id, r.id, b.id, 'CY789WP', 'Nissan', 'Impilo', 15, 'QR-KWT-CY789WP', 'CODETA|CLR|CY789WP|OWN-KWT-002|15', 'Kuwait Branch', 'active', 'Recently serviced'
FROM owners o
JOIN routes r ON r.route_code = 'CLR'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-002'
UNION ALL
SELECT o.id, r.id, b.id, 'CZ101WP', 'Ford', 'Ranger', 14, 'QR-KWT-CZ101WP', 'CODETA|WYN|CZ101WP|OWN-KWT-003|14', 'Kuwait Branch', 'active', 'Good condition'
FROM owners o
JOIN routes r ON r.route_code = 'WYN'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-003'
UNION ALL
SELECT o.id, r.id, b.id, 'CA202WP', 'Mercedes-Benz', 'Sprinter', 17, 'QR-KWT-CA202WP', 'CODETA|FSH|CA202WP|OWN-KWT-004|17', 'Kuwait Branch', 'maintenance', 'Under maintenance'
FROM owners o
JOIN routes r ON r.route_code = 'FSH'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-004'
UNION ALL
SELECT o.id, r.id, b.id, 'CB303WP', 'Volkswagen', 'Crafter', 16, 'QR-KWT-CB303WP', 'CODETA|SEA|CB303WP|OWN-KWT-005|16', 'Kuwait Branch', 'active', 'Excellent condition'
FROM owners o
JOIN routes r ON r.route_code = 'SEA'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-005';

-- =============================================
-- BILLING RATES
-- =============================================

INSERT OR IGNORE INTO billing_rates (branch_id, rate_name, amount_per_load, effective_from, is_active)
SELECT id, 'Standard Rate', 25.00, '2024-01-01', 1 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'Premium Rate', 30.00, '2024-01-01', 1 FROM branches WHERE code = 'KWT';

-- =============================================
-- REGISTERED DEVICES
-- =============================================

INSERT OR IGNORE INTO registered_devices (user_id, device_name, device_identifier, device_type, is_active)
SELECT u.id, 'Marshal Phone 1', 'DEVICE-ANDROID-001', 'phone', 1
FROM users u WHERE u.username = 'marshal_ctn_1'
UNION ALL
SELECT u.id, 'Marshal Tablet 1', 'DEVICE-TABLET-001', 'tablet', 1
FROM users u WHERE u.username = 'marshal_clr_1'
UNION ALL
SELECT u.id, 'Patrol Phone 1', 'DEVICE-ANDROID-002', 'phone', 1
FROM users u WHERE u.username = 'patrol_1';

-- =============================================
-- SAMPLE LOAD RECORDS (for testing)
-- =============================================

-- Insert some sample load records for the past 7 days
INSERT OR IGNORE INTO load_records (vehicle_id, route_id, rank_id, marshal_user_id, direction, load_count, passenger_count, is_full_load, recorded_at, source_method)
SELECT
    v.id,
    v.route_id,
    ra.rank_id,
    u.id,
    'township_to_town',
    CASE WHEN RANDOM() % 2 = 0 THEN 1 ELSE 2 END,
    CASE WHEN RANDOM() % 3 = 0 THEN 14 ELSE 15 END,
    1,
    datetime('now', '-' || (RANDOM() % 7) || ' days', '-' || (RANDOM() % 24) || ' hours'),
    'manual'
FROM vehicles v
JOIN users u ON u.username LIKE 'marshal_%'
JOIN route_rank_assignments ra ON ra.route_id = v.route_id AND ra.assignment_type = 'pickup'
WHERE v.status = 'active'
LIMIT 50;

-- =============================================
-- SAMPLE PATROL REPORTS
-- =============================================

INSERT OR IGNORE INTO patrol_reports (patroller_user_id, vehicle_id, route_id, report_category, severity, report_text, reported_at)
SELECT
    u.id,
    v.id,
    v.route_id,
    'vehicle_condition',
    'low',
    'Vehicle appears to be in good condition, no issues noted.',
    datetime('now', '-' || (RANDOM() % 3) || ' days')
FROM users u
CROSS JOIN vehicles v
WHERE u.role = 'patroller' AND v.status = 'active'
LIMIT 10;

-- =============================================
-- SAMPLE VEHICLE INSPECTIONS
-- =============================================

INSERT OR IGNORE INTO vehicle_inspections (vehicle_id, patroller_user_id, route_id, windscreen_ok, left_light_ok, right_light_ok, tires_ok, brakes_ok, roadworthy_status, inspection_notes, inspected_at)
SELECT
    v.id,
    u.id,
    v.route_id,
    1, 1, 1, 1, 1,
    'pass',
    'All systems checked and passed inspection.',
    datetime('now', '-' || (RANDOM() % 7) || ' days')
FROM vehicles v
JOIN users u ON u.role = 'patroller'
WHERE v.status = 'active'
LIMIT 15;

COMMIT;

-- =============================================
-- SEED DATA COMPLETE
-- =============================================

SELECT 'Taxi System Database seeded successfully!' AS status;
SELECT COUNT(*) || ' branches created' AS branches FROM branches;
SELECT COUNT(*) || ' users created' AS users FROM users;
SELECT COUNT(*) || ' owners created' AS owners FROM owners;
SELECT COUNT(*) || ' vehicles created' AS vehicles FROM vehicles;
SELECT COUNT(*) || ' load records created' AS load_records FROM load_records;