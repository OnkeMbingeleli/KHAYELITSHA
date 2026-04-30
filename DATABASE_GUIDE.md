# SQL Database Setup & Test Data Guide

## Database Overview

The system uses **SQLite3** for data persistence with a fully relational schema supporting:
- User authentication (Marshals)
- Owner management
- Vehicle fleet tracking
- Pickup recording with timestamps
- Route-based data organization

## Database Location
```
📁 backend/instance/taxi_system.db
```

## Database Schema

### Tables Created

#### 1. **marshal** (Login Accounts)
```sql
CREATE TABLE marshal (
    id INTEGER PRIMARY KEY,
    username VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(150) NOT NULL,
    name VARCHAR(150) NOT NULL,
    route VARCHAR(150) NOT NULL
);
```
**Purpose**: Store marshal/user accounts for login authentication

---

#### 2. **owner** (Vehicle Owners)
```sql
CREATE TABLE owner (
    id INTEGER PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    surname VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    contact VARCHAR(20) NOT NULL,
    unique_id VARCHAR(50) UNIQUE NOT NULL
);
```
**Purpose**: Store vehicle owner information for reporting and management

---

#### 3. **vehicle** (Vehicle Fleet)
```sql
CREATE TABLE vehicle (
    id INTEGER PRIMARY KEY,
    number_plate VARCHAR(20) UNIQUE NOT NULL,
    owner_id INTEGER FOREIGN KEY,
    route VARCHAR(150) NOT NULL,
    capacity INTEGER NOT NULL,
    loads_today INTEGER DEFAULT 0,
    make VARCHAR(50),
    model VARCHAR(50)
);
```
**Purpose**: Track all vehicles, their capacity, current loads, and specifications

---

#### 4. **pickup** (Pickup Records)
```sql
CREATE TABLE pickup (
    id INTEGER PRIMARY KEY,
    number_plate VARCHAR(20) FOREIGN KEY,
    rank VARCHAR(50) NOT NULL,
    route VARCHAR(150) NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    marshal_id INTEGER FOREIGN KEY
);
```
**Purpose**: Log all pickup events with location, time, and responsible marshal

---

## Test Data Overview

### Total Records Seeded
- **8 Marshals** across 4 routes
- **9 Owners** (vehicle owners)
- **12 Vehicles** in the fleet
- **25 Sample Pickups** from the last 3 hours

---

## 🔐 Test Login Credentials

All test marshals use password: **`pass123`**

### Cape Town Route
```
Username: marshal1
Password: pass123
Name: John

Username: marshal_ct2
Password: pass123
Name: Peter

Username: marshal_ct3
Password: pass123
Name: Paul
```

### Durban Route
```
Username: marshal2
Password: pass123
Name: Jane

Username: marshal_dur2
Password: pass123
Name: Sarah
```

### Johannesburg Route
```
Username: marshal_jnb
Password: pass123
Name: Mike

Username: marshal_jnb2
Password: pass123
Name: David
```

### Port Elizabeth Route
```
Username: marshal_pe
Password: pass123
Name: James
```

---

## 🚗 Test Vehicles by Route

### Cape Town (6 vehicles)
| Plate | Owner | Capacity | Make | Model |
|-------|-------|----------|------|-------|
| CA123WP | Mandla Nkosi | 15 | Toyota | Hiace |
| CA456WP | Mandla Nkosi | 16 | Ford | Transit |
| CA789WP | Thabo Mthembu | 14 | Mercedes | Sprinter |
| CA101WP | Sipho Dlamini | 15 | Toyota | Quantum |
| CA202WP | Lindiwe Ndaba | 16 | Nissan | Impilo |
| CA303WP | Thabo Mthembu | 15 | Toyota | Hiace |

### Durban (3 vehicles)
| Plate | Owner | Capacity | Make | Model |
|-------|-------|----------|------|-------|
| DB456WP | Ayanda Khumalo | 16 | Ford | Transit |
| DB789WP | Ayanda Khumalo | 15 | Toyota | Hiace |
| DB101WP | Buhle Ngubane | 14 | Nissan | Impilo |

### Johannesburg (2 vehicles)
| Plate | Owner | Capacity | Make | Model |
|-------|-------|----------|------|-------|
| JB123WP | Lerato Mokoena | 15 | Toyota | Hiace |
| JB456WP | Themba Shezi | 16 | Ford | Transit |

### Port Elizabeth (1 vehicle)
| Plate | Owner | Capacity | Make | Model |
|-------|-------|----------|------|-------|
| PE789WP | Naledi Bosman | 15 | Toyota | Hiace |

---

## 👥 Test Owners

| Owner ID | Name | Surname | Email | Contact | Unique ID |
|----------|------|---------|-------|---------|-----------|
| 1 | Mandla | Nkosi | mandla@email.com | 0712345678 | OWNER_CT_001 |
| 2 | Thabo | Mthembu | thabo@email.com | 0723456789 | OWNER_CT_002 |
| 3 | Sipho | Dlamini | sipho@email.com | 0734567890 | OWNER_CT_003 |
| 4 | Lindiwe | Ndaba | lindiwe@email.com | 0745678901 | OWNER_CT_004 |
| 5 | Ayanda | Khumalo | ayanda@email.com | 0756789012 | OWNER_DUR_001 |
| 6 | Buhle | Ngubane | buhle@email.com | 0767890123 | OWNER_DUR_002 |
| 7 | Lerato | Mokoena | lerato@email.com | 0778901234 | OWNER_JNB_001 |
| 8 | Themba | Shezi | themba@email.com | 0789012345 | OWNER_JNB_002 |
| 9 | Naledi | Bosman | naledi@email.com | 0790123456 | OWNER_PE_001 |

---

## 🗺️ Test Routes Available

```
1. Cape Town     - 6 vehicles, 3 marshals
2. Durban        - 3 vehicles, 2 marshals
3. Johannesburg  - 2 vehicles, 2 marshals
4. Port Elizabeth- 1 vehicle,  1 marshal
```

---

## 📍 Test Pickup Ranks

The following ranks are pre-loaded in sample data:
- Somerset
- Kweza
- Site B
- Makaha
- Harare
- Saipan
- Claremont
- Weinberg
- Fish Hook
- Sea Point

---

## 🚀 Database Operations

### View Database Contents (Admin API)

#### Get Stats
```bash
curl http://127.0.0.1:5000/admin/stats
```
Response:
```json
{
  "marshals_count": 8,
  "owners_count": 9,
  "vehicles_count": 12,
  "pickups_count": 25,
  "total_loads_today": 45
}
```

#### List All Marshals
```bash
curl http://127.0.0.1:5000/admin/marshals
```

#### List All Owners
```bash
curl http://127.0.0.1:5000/admin/owners
```

#### List All Vehicles
```bash
curl http://127.0.0.1:5000/admin/vehicles
```

#### List All Pickups
```bash
curl http://127.0.0.1:5000/admin/pickups
```

#### Get Routes Overview
```bash
curl http://127.0.0.1:5000/admin/routes
```

#### Get Vehicles by Route
```bash
curl http://127.0.0.1:5000/admin/vehicles/by-route/Cape%20Town
```

#### Reset Daily Loads
```bash
curl -X POST http://127.0.0.1:5000/admin/reset-loads
```

---

## 📊 Admin Dashboard

A full-featured admin dashboard is available at:
```
📄 admin.html
```

**Features**:
- Real-time database statistics
- View/manage marshals
- View/manage owners
- Monitor vehicle fleet
- View pickup history
- Route analytics
- Auto-refresh every 10 seconds

**Access**: Open `admin.html` in browser (no login required for dashboard)

---

## 🔄 Seeding the Database

### Initial Setup
The database is **automatically created and seeded** when the Flask app starts.

### Manual Re-seed
To reload test data:
```bash
cd backend
python seed_database.py
```

Output:
```
🌱 Starting database seeding...
✓ Added Marshal: marshal_ct2 (Cape Town)
✓ Added Owner: Mandla Nkosi (OWNER_CT_001)
✓ Added Vehicle: CA456WP (Cape Town)
✓ Pickup: PE789WP at Saipan by marshal_pe
...
============================================================
✅ DATABASE SEEDING COMPLETE!
============================================================

📊 SUMMARY:
  • Marshals: 8
  • Owners: 11
  • Vehicles: 12
  • Pickups: 25
```

---

## 💾 Database Maintenance

### Backup Database
```bash
cp backend/instance/taxi_system.db backup/taxi_system.db.backup
```

### Clear All Data
```bash
rm backend/instance/taxi_system.db
# App will recreate on next startup
```

### View Specific Queries

#### All pickups for marshal1
```sql
SELECT p.*, m.name FROM pickup p 
JOIN marshal m ON p.marshal_id = m.id 
WHERE m.username = 'marshal1';
```

#### All vehicles for Cape Town route
```sql
SELECT v.*, o.name, o.surname FROM vehicle v
JOIN owner o ON v.owner_id = o.id
WHERE v.route = 'Cape Town';
```

#### Total loads per owner
```sql
SELECT o.name, o.surname, SUM(v.loads_today) as total
FROM owner o
LEFT JOIN vehicle v ON o.id = v.owner_id
GROUP BY o.id;
```

---

## 🔒 Security Notes

### Development Only
- Passwords are stored in **plaintext** (use bcrypt in production)
- No HTTPS (use SSL/TLS in production)
- SQLite only (use PostgreSQL in production)

### For Production
1. Hash passwords with `werkzeug.security.generate_password_hash()`
2. Enable HTTPS/SSL certificates
3. Migrate to PostgreSQL
4. Implement role-based access control
5. Add audit logging
6. Use environment variables for secrets

---

## 📈 Usage Scenarios

### Test Login Flow
```
1. Open admin.html
2. Click "Marshals" tab
3. Find any marshal (e.g., marshal1)
4. Go to frontend/index.html
5. Login with username: marshal1, password: pass123
6. Record pickups, view summaries
```

### Test Pickup Recording
```
1. Login as marshal1 (Cape Town route)
2. Go to "Record Pickup" tab
3. Enter plate: CA123WP
4. Enter rank: Somerset
5. Click "Record Pickup"
6. Repeat up to 8 times (daily limit)
7. View "Summary" to see all pickups
```

### Test Multi-Route Isolation
```
1. Login as marshal1 (Cape Town) - can only see CA, CA456, CA789, etc.
2. Logout, login as marshal2 (Durban) - can only see DB456, DB789, etc.
3. Data is completely isolated by route
```

---

## 📞 Support

For database issues:
1. Check `admin.html` for current state
2. Review Flask terminal for errors
3. Reseed database if needed: `python seed_database.py`
4. Check backend/instance/taxi_system.db file exists

---

**Last Updated**: April 2026  
**System Status**: ✅ FULLY OPERATIONAL  
**Database Version**: SQLite 3.x
