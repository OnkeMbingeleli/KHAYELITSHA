-- =============================================
-- TAXI SYSTEM DATABASE SETUP SCRIPT
-- =============================================
-- This script shows how to create and initialize the taxi system database
-- using SQLite commands.

-- Step 1: Create the database (SQLite will create the file automatically)
-- sqlite3 taxi_system.db

-- Step 2: Run the schema creation
-- Within SQLite shell, run:
-- .read kuwait_branch_schema.sql

-- Or from command line:
-- sqlite3 taxi_system.db < kuwait_branch_schema.sql

-- Step 3: (Optional) Seed with sample data
-- sqlite3 taxi_system.db < kuwait_branch_seed.sql

-- =============================================
-- ALTERNATIVE: Single command setup
-- =============================================
-- To create everything at once:
-- sqlite3 taxi_system.db < kuwait_branch_schema.sql && sqlite3 taxi_system.db < kuwait_branch_seed.sql

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check if database was created successfully
-- sqlite3 taxi_system.db "SELECT name FROM sqlite_master WHERE type='table';"

-- Check branch data
-- sqlite3 taxi_system.db "SELECT * FROM branches;"

-- Check route data
-- sqlite3 taxi_system.db "SELECT route_code, route_name FROM routes;"

-- =============================================
-- MySQL/MariaDB Version (if needed)
-- =============================================

-- For MySQL/MariaDB, use these commands instead:
--
-- CREATE DATABASE taxi_system;
-- USE taxi_system;
--
-- Then run the schema file with MySQL syntax adjustments needed for:
-- - AUTOINCREMENT → AUTO_INCREMENT
-- - TEXT → VARCHAR or LONGTEXT
-- - REAL → DOUBLE or DECIMAL
-- - Some constraint syntax differences

-- =============================================
-- SETUP COMPLETE
-- =============================================