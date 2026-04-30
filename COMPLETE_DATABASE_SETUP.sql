-- =============================================
-- TAXI SYSTEM COMPLETE DATABASE SETUP
-- =============================================
-- This script creates the complete taxi management system database
-- Run this script to set up everything from scratch

-- For SQLite (recommended for development):
-- sqlite3 taxi_system.db < COMPLETE_DATABASE_SETUP.sql

-- For MySQL/MariaDB (production):
-- mysql -u username -p < COMPLETE_DATABASE_SETUP.sql

-- =============================================
-- DATABASE CREATION
-- =============================================

-- SQLite version
-- CREATE DATABASE IF NOT EXISTS taxi_system;

-- MySQL/MariaDB version (uncomment if using MySQL)
-- CREATE DATABASE IF NOT EXISTS taxi_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE taxi_system;

-- =============================================
-- SCHEMA DEFINITION
-- =============================================

-- Enable foreign key constraints (SQLite)
PRAGMA foreign_keys = ON;

-- MySQL/MariaDB equivalent:
-- SET FOREIGN_KEY_CHECKS = 1;

BEGIN TRANSACTION;

-- Core organization structure
CREATE TABLE IF NOT EXISTS branches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ranks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_id INTEGER NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    rank_type TEXT NOT NULL DEFAULT 'pickup'
        CHECK (rank_type IN ('pickup', 'town', 'return_point', 'checkpoint', 'other')),
    parent_rank_id INTEGER,
    latitude REAL,
    longitude REAL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id, code),
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_rank_id) REFERENCES ranks(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS routes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_id INTEGER NOT NULL,
    route_code TEXT NOT NULL,
    route_name TEXT NOT NULL,
    direction_label TEXT,
    is_long_distance INTEGER NOT NULL DEFAULT 0 CHECK (is_long_distance IN (0, 1)),
    daily_load_limit INTEGER NOT NULL DEFAULT 8 CHECK (daily_load_limit > 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id, route_code),
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS route_rank_assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    route_id INTEGER NOT NULL,
    rank_id INTEGER NOT NULL,
    assignment_type TEXT NOT NULL DEFAULT 'pickup'
        CHECK (assignment_type IN ('pickup', 'dropoff', 'town', 'return_point', 'checkpoint')),
    sequence_no INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE(route_id, rank_id, assignment_type),
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
    FOREIGN KEY (rank_id) REFERENCES ranks(id) ON DELETE CASCADE
);

-- Users and access control
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('super_admin', 'management', 'marshal', 'patroller', 'owner')),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    id_number TEXT,
    phone TEXT,
    email TEXT,
    branch_id INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS user_route_assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    assignment_start TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assignment_end TEXT,
    is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
    UNIQUE(user_id, route_id, assignment_start),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS registered_devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_name TEXT NOT NULL,
    device_identifier TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL CHECK (device_type IN ('phone', 'tablet', 'desktop', 'scanner', 'display')),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    last_seen_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Owner and vehicle registration
CREATE TABLE IF NOT EXISTS owners (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_id INTEGER NOT NULL,
    owner_code TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth TEXT,
    id_number TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    preferred_report_day INTEGER DEFAULT 1 CHECK (preferred_report_day BETWEEN 1 AND 28),
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'suspended', 'inactive')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS owner_route_memberships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE(owner_id, route_id, joined_at),
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vehicles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    number_plate TEXT NOT NULL UNIQUE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    seat_capacity INTEGER NOT NULL CHECK (seat_capacity > 0),
    qr_code_value TEXT NOT NULL UNIQUE,
    qr_sticker_label TEXT,
    office_label TEXT,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'maintenance', 'written_off', 'removed', 'stolen', 'inactive')),
    registered_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    removed_at TEXT,
    notes TEXT,
    loads_today INTEGER NOT NULL DEFAULT 0,
    latitude REAL,
    longitude REAL,
    location_updated TEXT,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE RESTRICT,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS vehicle_status_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id INTEGER NOT NULL,
    old_status TEXT,
    new_status TEXT NOT NULL,
    changed_by_user_id INTEGER,
    reason TEXT,
    changed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Operational sessions and load recording
CREATE TABLE IF NOT EXISTS marshal_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    marshal_user_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    rank_id INTEGER NOT NULL,
    device_id INTEGER,
    started_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    FOREIGN KEY (marshal_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (rank_id) REFERENCES ranks(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_id) REFERENCES registered_devices(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS load_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    rank_id INTEGER NOT NULL,
    marshal_user_id INTEGER NOT NULL,
    marshal_session_id INTEGER,
    direction TEXT NOT NULL CHECK (direction IN ('town_to_township', 'township_to_town', 'return_trip', 'other')),
    load_count INTEGER NOT NULL DEFAULT 1 CHECK (load_count > 0),
    passenger_count INTEGER,
    is_full_load INTEGER NOT NULL DEFAULT 1 CHECK (is_full_load IN (0, 1)),
    overload_count INTEGER NOT NULL DEFAULT 0 CHECK (overload_count >= 0),
    recorded_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comment_text TEXT,
    source_method TEXT NOT NULL DEFAULT 'manual'
        CHECK (source_method IN ('manual', 'qr_scan', 'checkpoint_scan', 'import')),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (rank_id) REFERENCES ranks(id) ON DELETE RESTRICT,
    FOREIGN KEY (marshal_user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (marshal_session_id) REFERENCES marshal_sessions(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS checkpoint_scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    rank_id INTEGER NOT NULL,
    scanned_by_user_id INTEGER,
    scan_type TEXT NOT NULL CHECK (scan_type IN ('quarter', 'midpoint', 'return_point', 'patrol', 'other')),
    scanned_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
    FOREIGN KEY (rank_id) REFERENCES ranks(id) ON DELETE CASCADE,
    FOREIGN KEY (scanned_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Behavior, inspections, and patrol operations
CREATE TABLE IF NOT EXISTS patrol_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patroller_user_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    rank_id INTEGER,
    driver_name TEXT,
    driver_id_number TEXT,
    driver_photo_path TEXT,
    report_category TEXT NOT NULL
        CHECK (report_category IN ('behavior', 'vehicle_condition', 'compliance', 'discipline', 'other')),
    severity TEXT NOT NULL DEFAULT 'medium'
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    report_text TEXT NOT NULL,
    reported_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patroller_user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (rank_id) REFERENCES ranks(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS vehicle_inspections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id INTEGER NOT NULL,
    patroller_user_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    rank_id INTEGER,
    windscreen_ok INTEGER CHECK (windscreen_ok IN (0, 1)),
    left_light_ok INTEGER CHECK (left_light_ok IN (0, 1)),
    right_light_ok INTEGER CHECK (right_light_ok IN (0, 1)),
    tires_ok INTEGER CHECK (tires_ok IN (0, 1)),
    brakes_ok INTEGER CHECK (brakes_ok IN (0, 1)),
    roadworthy_status TEXT NOT NULL DEFAULT 'attention_required'
        CHECK (roadworthy_status IN ('pass', 'attention_required', 'fail')),
    inspection_notes TEXT,
    inspected_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT,
    FOREIGN KEY (patroller_user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (rank_id) REFERENCES ranks(id) ON DELETE SET NULL
);

-- Reporting and billing
CREATE TABLE IF NOT EXISTS monthly_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    report_month TEXT NOT NULL, -- format YYYY-MM
    generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_loads INTEGER NOT NULL DEFAULT 0 CHECK (total_loads >= 0),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    report_file_path TEXT,
    delivery_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (delivery_status IN ('pending', 'generated', 'sent', 'failed')),
    UNIQUE(owner_id, route_id, report_month),
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS billing_rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_id INTEGER NOT NULL,
    rate_name TEXT NOT NULL,
    amount_per_load NUMERIC(10,2) NOT NULL CHECK (amount_per_load >= 0),
    effective_from TEXT NOT NULL,
    effective_to TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS association_invoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_id INTEGER NOT NULL,
    invoice_month TEXT NOT NULL, -- format YYYY-MM
    total_loads INTEGER NOT NULL DEFAULT 0 CHECK (total_loads >= 0),
    amount_due NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    payment_status TEXT NOT NULL DEFAULT 'unpaid'
        CHECK (payment_status IN ('unpaid', 'part_paid', 'paid', 'disputed')),
    issued_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_at TEXT,
    paid_at TEXT,
    UNIQUE(branch_id, invoice_month),
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

-- Audit trail
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    action_type TEXT NOT NULL,
    entity_name TEXT NOT NULL,
    entity_id INTEGER,
    action_details TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ranks_branch_id ON ranks(branch_id);
CREATE INDEX IF NOT EXISTS idx_routes_branch_id ON routes(branch_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_vehicles_owner_id ON vehicles(owner_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_route_id ON vehicles(route_id);
CREATE INDEX IF NOT EXISTS idx_load_records_vehicle_id ON load_records(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_load_records_route_id ON load_records(route_id);
CREATE INDEX IF NOT EXISTS idx_load_records_rank_id ON load_records(rank_id);
CREATE INDEX IF NOT EXISTS idx_load_records_recorded_at ON load_records(recorded_at);
CREATE INDEX IF NOT EXISTS idx_patrol_reports_vehicle_id ON patrol_reports(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_inspections_vehicle_id ON vehicle_inspections(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_monthly_reports_owner_month ON monthly_reports(owner_id, report_month);

-- Summary views for dashboards and reports
CREATE VIEW IF NOT EXISTS v_daily_route_loads AS
SELECT
    lr.route_id,
    date(lr.recorded_at) AS load_date,
    COUNT(*) AS total_records,
    SUM(lr.load_count) AS total_loads
FROM load_records lr
GROUP BY lr.route_id, date(lr.recorded_at);

CREATE VIEW IF NOT EXISTS v_daily_rank_loads AS
SELECT
    lr.rank_id,
    lr.route_id,
    date(lr.recorded_at) AS load_date,
    COUNT(*) AS total_records,
    SUM(lr.load_count) AS total_loads
FROM load_records lr
GROUP BY lr.rank_id, lr.route_id, date(lr.recorded_at);

CREATE VIEW IF NOT EXISTS v_vehicle_daily_loads AS
SELECT
    lr.vehicle_id,
    lr.route_id,
    date(lr.recorded_at) AS load_date,
    COUNT(*) AS total_records,
    SUM(lr.load_count) AS total_loads
FROM load_records lr
GROUP BY lr.vehicle_id, lr.route_id, date(lr.recorded_at);

COMMIT;

-- =============================================
-- SEED DATA
-- =============================================

BEGIN TRANSACTION;

-- Branches
INSERT OR IGNORE INTO branches (code, name, description)
VALUES
    ('KWT', 'Kuwait Branch', 'Pilot branch for the local taxi association system'),
    ('CTN', 'Cape Town Central', 'Main Cape Town branch covering central areas'),
    ('KHL', 'Khayelitsha Branch', 'Khayelitsha township branch');

-- Ranks for Kuwait Branch
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

-- Routes
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

-- Route-Rank Assignments
INSERT OR IGNORE INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'pickup', 1
FROM routes r
CROSS JOIN ranks k
WHERE r.branch_id = k.branch_id
  AND r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN', 'BEL', 'PAR')
  AND k.code IN ('A', 'B', 'C', 'D', 'E', 'F')
  AND k.rank_type = 'pickup';

INSERT OR IGNORE INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'town', 2
FROM routes r
JOIN ranks k ON r.branch_id = k.branch_id
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN', 'BEL', 'PAR')
  AND k.code = 'TOWN';

INSERT OR IGNORE INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'return_point', 3
FROM routes r
JOIN ranks k ON r.branch_id = k.branch_id
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN', 'BEL', 'PAR')
  AND k.code = 'RETURN';

-- Users
INSERT OR IGNORE INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'superadmin1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'super_admin', 'Onke', 'Mbingeleli', '8001010000001', '0710000001', 'admin@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'marshal_ctn_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'marshal', 'Sipho', 'Mahlangu', '9001010000001', '0722222222', 'sipho.mahlangu@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'marshal_clr_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'marshal', 'Zanele', 'Dlamini', '9001010000002', '0723333333', 'zanele.dlamini@taxiproject.co.za', id
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT 'patrol_1', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6fMmiP0Zm', 'patroller', 'Lerato', 'Khumalo', '9001010000004', '0725555555', 'lerato.khumalo@taxiproject.co.za', id
FROM branches WHERE code = 'KWT';

-- User Route Assignments
INSERT OR IGNORE INTO user_route_assignments (user_id, route_id, is_primary)
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'CTN'
WHERE u.username = 'marshal_ctn_1'
UNION ALL
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'CLR'
WHERE u.username = 'marshal_clr_1';

-- Owners
INSERT OR IGNORE INTO owners (branch_id, owner_code, first_name, last_name, date_of_birth, id_number, phone, email, address, preferred_report_day)
SELECT id, 'OWN-KWT-001', 'Mandla', 'Nkosi', '1980-01-01', '8001015009087', '0731111111', 'mandla.nkosi@email.co.za', '123 Main Street, Khayelitsha', 15
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'OWN-KWT-002', 'Ayanda', 'Khumalo', '1983-05-12', '8305125009087', '0732222222', 'ayanda.khumalo@email.co.za', '456 Oak Avenue, Khayelitsha', 20
FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'OWN-KWT-003', 'Thabo', 'Mthembu', '1975-08-20', '7508205009087', '0733333333', 'thabo.mthembu@email.co.za', '789 Pine Road, Khayelitsha', 10
FROM branches WHERE code = 'KWT';

-- Owner Route Memberships
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
WHERE o.owner_code = 'OWN-KWT-003';

-- Vehicles
INSERT OR IGNORE INTO vehicles (owner_id, route_id, branch_id, number_plate, make, model, seat_capacity, qr_code_value, qr_sticker_label, office_label, status, notes)
SELECT o.id, r.id, b.id, 'CA123WP', 'Toyota', 'Hiace', 15, 'QR-KWT-CA123WP', 'CODETA|CTN|CA123WP|OWN-KWT-001|15', 'Kuwait Branch', 'active', 'Well maintained vehicle'
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
WHERE o.owner_code = 'OWN-KWT-003';

-- Billing Rates
INSERT OR IGNORE INTO billing_rates (branch_id, rate_name, amount_per_load, effective_from, is_active)
SELECT id, 'Standard Rate', 25.00, '2024-01-01', 1 FROM branches WHERE code = 'KWT'
UNION ALL
SELECT id, 'Premium Rate', 30.00, '2024-01-01', 1 FROM branches WHERE code = 'KWT';

-- Registered Devices
INSERT OR IGNORE INTO registered_devices (user_id, device_name, device_identifier, device_type, is_active)
SELECT u.id, 'Marshal Phone 1', 'DEVICE-ANDROID-001', 'phone', 1
FROM users u WHERE u.username = 'marshal_ctn_1'
UNION ALL
SELECT u.id, 'Marshal Tablet 1', 'DEVICE-TABLET-001', 'tablet', 1
FROM users u WHERE u.username = 'marshal_clr_1'
UNION ALL
SELECT u.id, 'Patrol Phone 1', 'DEVICE-ANDROID-002', 'phone', 1
FROM users u WHERE u.username = 'patrol_1';

COMMIT;

-- =============================================
-- SETUP COMPLETE
-- =============================================

SELECT 'Taxi System Database setup completed successfully!' AS status;
SELECT 'Run COMPREHENSIVE_SQL_REFERENCE.sql for useful queries' AS next_step;

-- =============================================
-- END OF COMPLETE SETUP
-- =============================================