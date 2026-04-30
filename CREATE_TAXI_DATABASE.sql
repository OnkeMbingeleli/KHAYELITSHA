-- =============================================
-- TAXI SYSTEM DATABASE CREATION SCRIPT
-- =============================================
-- This script creates the complete taxi management system database
-- including schema, tables, indexes, and views.

-- Create the main taxi system database
CREATE DATABASE IF NOT EXISTS taxi_system;

-- Use the taxi system database
USE taxi_system;

-- =============================================
-- SCHEMA DEFINITION
-- =============================================

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

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

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

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

-- =============================================
-- SUMMARY VIEWS FOR DASHBOARDS AND REPORTS
-- =============================================

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

-- =============================================
-- DATABASE CREATION COMPLETE
-- =============================================

COMMIT;

-- Display success message
SELECT 'Taxi System Database created successfully!' AS status;