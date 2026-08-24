# Taxi System Database Scripts

This directory contains comprehensive SQL scripts for setting up and managing the Taxi Management System database.

## 📁 Available Scripts

### 1. `COMPLETE_DATABASE_SETUP.sql`
**Purpose**: Complete one-stop database setup
- Creates database schema (all tables, indexes, views)
- Seeds with comprehensive sample data
- Ready for immediate use

**Usage**:
```bash
# SQLite
sqlite3 taxi_system.db < COMPLETE_DATABASE_SETUP.sql

# MySQL/MariaDB
mysql -u username -p < COMPLETE_DATABASE_SETUP.sql
```

### 2. `ENHANCED_SEED_DATA.sql`
**Purpose**: Comprehensive sample data
- Multiple branches, users, owners, vehicles
- Sample operational data (load records, inspections, reports)
- Realistic test data for development

### 3. `COMPREHENSIVE_SQL_REFERENCE.sql`
**Purpose**: Essential queries for system operation
- 30+ categorized SQL queries
- Dashboard analytics, reporting, maintenance
- Search, export, and utility queries

### 4. `CREATE_DATABASE_BASIC.sql`
**Purpose**: Minimal database creation
- Basic `CREATE DATABASE` and `USE` statements
- Reference for custom schema implementation

### 5. `DATABASE_SETUP_GUIDE.sql`
**Purpose**: Step-by-step setup instructions
- Detailed setup process
- SQLite and MySQL/MariaDB compatibility
- Verification queries

## 🚀 Quick Start

### Option 1: Complete Setup (Recommended)
```bash
# Creates everything in one command
sqlite3 taxi_system.db < COMPLETE_DATABASE_SETUP.sql
```

### Option 2: Step-by-Step Setup
```bash
# 1. Create database with schema
sqlite3 taxi_system.db < COMPLETE_DATABASE_SETUP.sql

# 2. Add sample data
sqlite3 taxi_system.db < ENHANCED_SEED_DATA.sql
```

## 📊 Database Structure

### Core Tables
- `branches` - Organization branches
- `ranks` - Pickup/drop-off locations
- `routes` - Taxi routes
- `users` - System users (marshals, patrollers, admins)
- `owners` - Vehicle owners
- `vehicles` - Registered taxis
- `load_records` - Daily load tracking
- `patrol_reports` - Patrol observations
- `vehicle_inspections` - Safety inspections

### Supporting Tables
- `route_rank_assignments` - Route-to-rank mappings
- `user_route_assignments` - User-to-route assignments
- `owner_route_memberships` - Owner-to-route memberships
- `registered_devices` - Mobile device tracking
- `monthly_reports` - Owner billing reports
- `billing_rates` - Pricing configuration
- `association_invoices` - Branch invoicing

## 🔍 Sample Data Included

### Default Login Credentials
- **Super Admin**: `superadmin1` / `CHANGE_ME`
- **Marshal**: `marshal_ctn_1` / `CHANGE_ME`
- **Patroller**: `patrol_1` / `CHANGE_ME`

### Sample Entities
- **3 Branches**: Kuwait, Cape Town Central, Khayelitsha
- **8 Routes**: CTN, CLR, WYN, FSH, SEA, DBN, BEL, PAR
- **6 Ranks**: A-F (pickup), Town, Return Point
- **4 Users**: 1 admin, 2 marshals, 1 patroller
- **3 Owners**: With contact details and addresses
- **3 Vehicles**: Toyota, Nissan, Ford models
- **Sample Load Records**: Past 7 days of operational data

## 📈 Useful Queries

### Check Database Status
```sql
-- View all tables
.schema

-- Count records per table
SELECT name FROM sqlite_master WHERE type='table';

-- Verify data integrity
PRAGMA integrity_check;
```

### Common Operations
```sql
-- Active vehicles by route
SELECT r.route_name, COUNT(v.id) as active_vehicles
FROM routes r
LEFT JOIN vehicles v ON r.id = v.route_id AND v.status = 'active'
GROUP BY r.route_name;

-- Today's load summary
SELECT COUNT(*) as loads_today,
       SUM(load_count) as total_loads
FROM load_records
WHERE date(recorded_at) = date('now');
```

## 🔧 Database Maintenance

### Backup Database
```bash
# SQLite backup
sqlite3 taxi_system.db ".backup taxi_system_backup.db"

# Or export to SQL
sqlite3 taxi_system.db .dump > taxi_system_backup.sql
```

### Performance Optimization
```sql
-- Analyze query performance
EXPLAIN QUERY PLAN SELECT * FROM load_records WHERE recorded_at > '2024-01-01';

-- Rebuild indexes
REINDEX;
```

### Data Cleanup
```sql
-- Remove old load records (older than 2 years)
DELETE FROM load_records WHERE recorded_at < datetime('now', '-2 years');

-- Vacuum database (SQLite)
VACUUM;
```

## 🐛 Troubleshooting

### Common Issues

1. **Foreign Key Errors**
   ```sql
   -- Check foreign key violations
   PRAGMA foreign_key_check;
   ```

2. **Permission Errors**
   ```bash
   # Ensure write permissions
   chmod 664 taxi_system.db
   ```

3. **Corrupted Database**
   ```bash
   # Recover from backup
   sqlite3 taxi_system.db ".restore taxi_system_backup.db"
   ```

## 📝 Notes

- All scripts use SQLite syntax by default
- MySQL/MariaDB compatibility notes included in comments
- Password hashes use bcrypt (change in production)
- Sample data is for development/testing only
- Regular backups recommended for production use

## 📞 Support

For issues with database setup or queries, refer to:
- `COMPREHENSIVE_SQL_REFERENCE.sql` for query examples
- `DATABASE_SETUP_GUIDE.sql` for detailed setup instructions

---

**Last Updated**: April 2026
**Database Version**: 1.0
**Tested With**: SQLite 3.37+, Python 3.8+
