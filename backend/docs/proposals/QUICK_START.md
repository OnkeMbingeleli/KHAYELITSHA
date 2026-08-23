# Quick Start Guide - Taxi Management System

## 🚀 System is LIVE!

### Backend Server Status: ✅ RUNNING
- **URL**: http://127.0.0.1:5000
- **Port**: 5000
- **Database**: SQLite (backend/instance/taxi_system.db)

---

## 📋 Quick Links

| Component | Location | Access |
|-----------|----------|--------|
| **Marshal App** | frontend/index.html | Open in browser |
| **Admin Dashboard** | admin.html | Open in browser |
| **API Docs** | See DATABASE_GUIDE.md | API endpoints |
| **Database Seeder** | backend/seed_database.py | `python seed_database.py` |
| **Config** | backend/app.py | Flask configuration |

---

## 🔓 Test Credentials (Password: pass123)

```
Cape Town:      marshal1, marshal_ct2, marshal_ct3
Durban:         marshal2, marshal_dur2
Johannesburg:   marshal_jnb, marshal_jnb2
Port Elizabeth: marshal_pe
```

---

## 🗄️ Database Quick Stats

```
Marshals:  8
Owners:    9
Vehicles:  12
Pickups:   25
Routes:    4
```

---

## 🎯 Test Scenarios

### Scenario 1: Record a Pickup
```
1. Go to frontend/index.html
2. Login: marshal1 / pass123
3. Record Pickup tab
4. Plate: CA123WP
5. Rank: Somerset
6. Click Record
```

### Scenario 2: View Admin Dashboard
```
1. Open admin.html
2. View real-time stats
3. Click tabs to see marshals, vehicles, routes
4. Auto-refreshes every 10 seconds
```

### Scenario 3: Test Route Isolation
```
1. Login as marshal1 (Cape Town)
2. Record pickup for CA123WP
3. Logout
4. Login as marshal2 (Durban)
5. Cannot see CA123WP (different route)
```

---

## 📊 API Endpoints

### Public Endpoints
- `POST /api/login` - Marshal login
- `POST /api/record` - Record pickup (requires login)
- `GET /api/summary` - Get summary (requires login)
- `GET /api/daily-report` - Get detailed report (requires login)

### Admin Endpoints
- `GET /admin/stats` - Database statistics
- `GET /admin/marshals` - List marshals
- `GET /admin/owners` - List owners
- `GET /admin/vehicles` - List vehicles
- `GET /admin/pickups` - List pickups
- `GET /admin/routes` - Routes overview
- `GET /admin/vehicles/by-route/<route>` - Vehicles by route
- `POST /admin/reset-loads` - Reset daily loads

---

## 🚗 Sample Test Vehicles

| Route | Plate | Owner | Capacity |
|-------|-------|-------|----------|
| Cape Town | CA123WP | Mandla Nkosi | 15 |
| Cape Town | CA456WP | Mandla Nkosi | 16 |
| Durban | DB456WP | Ayanda Khumalo | 16 |
| Johannesburg | JB123WP | Lerato Mokoena | 15 |
| Port Elizabeth | PE789WP | Naledi Bosman | 15 |

---

## 🔧 Troubleshooting

### Backend Not Running
```bash
cd backend
source .venv/Scripts/activate
python app.py
```

### Admin Dashboard Shows "Loading..."
```bash
Wait 3-5 seconds for auto-load
Or click "Refresh" button on each tab
```

### Database Not Found
```bash
cd backend
python seed_database.py
# Creates database and seeds test data
```

### Port 5000 Already in Use
```bash
# Find process using port 5000
netstat -ano | findstr :5000

# Kill process
taskkill /PID <PID> /F
```

---

## 📁 Project Structure

```
System/
├── backend/
│   ├── app.py                 ← Main Flask app
│   ├── models.py              ← Database models
│   ├── admin.py               ← Admin API routes
│   ├── seed_database.py       ← Test data seeder
│   ├── requirements.txt
│   ├── instance/
│   │   └── taxi_system.db     ← SQLite database
│   └── templates/
│
├── frontend/
│   ├── index.html             ← Marshal interface
│   ├── script.js              ← Frontend logic
│   └── style.css              ← Styling
│
├── admin.html                 ← Admin dashboard
├── DATABASE_GUIDE.md          ← Full database docs
├── SYSTEM_GUIDE.md            ← Complete guide
└── README.md                  ← Project overview
```

---

## 🎓 Learning Resources

### For Developers
- Read [SYSTEM_GUIDE.md](SYSTEM_GUIDE.md) for complete system overview
- Read [DATABASE_GUIDE.md](DATABASE_GUIDE.md) for database schema and API
- Check `backend/app.py` for Flask routes
- Check `backend/models.py` for data structure
- Check `frontend/script.js` for API calls

### For Testing
- Use `admin.html` for real-time database monitoring
- Use `frontend/index.html` for user interface testing
- Use test credentials provided above

### For Integration
- All API endpoints documented in DATABASE_GUIDE.md
- CORS enabled for frontend communication
- Session-based auth (can be upgraded to JWT)

---

## ✅ System Features Implemented

- ✅ Marshal authentication (login/logout)
- ✅ Pickup recording with rank/location
- ✅ Daily limit enforcement (8 pickups/vehicle)
- ✅ Real-time summaries
- ✅ Detailed daily reports
- ✅ Route-based access control
- ✅ Owner management
- ✅ Vehicle fleet tracking
- ✅ Admin dashboard
- ✅ Comprehensive API
- ✅ Responsive design
- ✅ Database seeding with dummy data

---

## 🚀 Next Steps

1. **Explore Admin Dashboard**: Open `admin.html` to see current database state
2. **Test Marshal App**: Open `frontend/index.html` and login with test credentials
3. **Try Recording Pickups**: Use test vehicles and ranks to record data
4. **View Reports**: Check summary and daily report features
5. **Review Documentation**: Read SYSTEM_GUIDE.md and DATABASE_GUIDE.md

---

## 💬 Support

| Issue | Solution |
|-------|----------|
| App won't start | Check port 5000 is free |
| Can't login | Use credentials from this guide |
| Dashboard shows "Loading" | Wait 5 seconds or click Refresh |
| Database empty | Run `python seed_database.py` |

---

**Last Updated**: April 2026  
**Status**: ✅ FULLY OPERATIONAL  
**Version**: 1.0
