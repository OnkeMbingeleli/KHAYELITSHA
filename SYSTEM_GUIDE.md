# Taxi Management System - Complete Guide

## System Overview
This is a comprehensive taxi management system designed for taxi associations (specifically tested on Kuwait branch with 6 ranks). The system allows marshals to record vehicle pickups by location, manages daily limits, provides real-time summaries, and generates reports for owners.

## Current Status
✅ **System is LIVE and RUNNING** on http://127.0.0.1:5000

### Core Features Implemented:
1. **Marshal Authentication** - Secure login system
2. **Pickup Recording** - Record vehicle pickups at different ranks
3. **Daily Limits** - Enforce 8 pickup limit per vehicle per day
4. **Real-time Summaries** - View pickups grouped by rank
5. **Daily Reports** - Detailed reports showing owner information
6. **Owner Management** - Register owners and their vehicles
7. **Route-based Access Control** - Marshals only see their route data

## Architecture

### Backend (Flask)
- **Location**: `backend/app.py`
- **Database**: SQLite (`taxi_system.db`)
- **Port**: 5000

#### Database Models:
```
- Marshal: User accounts for marshals
- Owner: Vehicle owners with contact info
- Vehicle: Vehicles with number plates, capacity, routes
- Pickup: Pickup records with timestamp, rank, route
```

### Frontend (Vanilla HTML/CSS/JS)
- **Location**: `frontend/index.html`
- **Features**: Responsive design, tab-based navigation
- **API Communication**: Fetch API with CORS support

## How to Use

### 1. Access the System
```
URL: Open frontend/index.html in browser
OR: Live at http://127.0.0.1:5000 (if configured)
```

### 2. Login Credentials (Demo)
```
Marshal 1:
  Username: marshal1
  Password: pass
  Route: Cape Town
  
Marshal 2:
  Username: marshal2
  Password: pass
  Route: Durban
```

### 3. Record a Pickup
1. Login with marshal credentials
2. Click "Record Pickup" tab
3. Enter vehicle number plate (e.g., CA123WP)
4. Enter rank/location (e.g., Somerset, Kweza, Site B)
5. Click "Record Pickup"

### 4. View Summary
Click "Summary" tab to see:
- Total loads for the day
- Pickups grouped by rank
- Vehicle owner information
- List of all pickups with timestamps

### 5. View Daily Report
Click "Daily Report" tab to see:
- Detailed breakdown by vehicle
- Owner information
- Number of loads per rank per vehicle
- Total system loads

## API Endpoints

### Authentication
```
POST /api/login
Body: {"username": "marshal1", "password": "pass"}
Response: {"message": "Logged in", "user_id": 1}
```

### Record Pickup
```
POST /api/record
Headers: Authorization (session-based)
Body: {"number_plate": "CA123WP", "rank": "Somerset"}
Response: {"message": "Pickup recorded"}
```

### Get Summary
```
GET /api/summary
Response: {
  "pickups": [...],
  "rank_summary": {...},
  "total_loads": 15,
  "route": "Cape Town"
}
```

### Get Daily Report
```
GET /api/daily-report
Response: {
  "route": "Cape Town",
  "date": "2024-01-15T...",
  "vehicles": {...},
  "total_system_loads": 50
}
```

### Register Owner
```
POST /api/owner/register
Body: {
  "name": "Mr.",
  "surname": "X",
  "email": "mrx@email.com",
  "contact": "0123456789",
  "vehicles": [
    {
      "number_plate": "CA123WP",
      "route": "Cape Town",
      "capacity": 15,
      "make": "Toyota",
      "model": "Hiace"
    }
  ]
}
Response: {"message": "Owner registered successfully", "owner_id": 1}
```

### Get Vehicles by Route
```
GET /api/vehicles/<route>
Response: {
  "vehicles": [
    {
      "number_plate": "CA123WP",
      "owner": "Mr. X",
      "capacity": 15,
      "loads_today": 5,
      "make": "Toyota",
      "model": "Hiace"
    }
  ]
}
```

## Features Explained

### Daily Limits
- Each vehicle has a **limit of 8 pickups per day**
- Prevents greedy operators from overloading
- Marshal gets feedback when limit is reached
- Resets automatically at midnight

### Rank-Based Tracking
- All pickups are recorded by rank/location
- System tracks:
  - Somerset rank pickups
  - Kweza rank pickups
  - Site B rank pickups
  - And any other rank

### Route-Based Access
- Marshals can only see/record data for their route
- Cape Town marshals only see Cape Town vehicles
- Durban marshals only see Durban vehicles
- Prevents cross-contamination of data

### Owner Information
- Each vehicle is linked to an owner
- Owner details included in reports
- Monthly reports can be generated for owners
- System tracks all vehicles per owner

## Data Schema

### Marshals Table
```sql
- id (Primary Key)
- username (Unique)
- password (plaintext - hash in production)
- name
- route
```

### Owners Table
```sql
- id (Primary Key)
- name
- surname
- email
- contact
- unique_id (Unique)
```

### Vehicles Table
```sql
- id (Primary Key)
- number_plate (Unique)
- owner_id (Foreign Key)
- route
- capacity
- loads_today
- make
- model
```

### Pickups Table
```sql
- id (Primary Key)
- number_plate (Foreign Key)
- rank
- route
- timestamp
- marshal_id (Foreign Key)
```

## Security Considerations

### Current (Development)
⚠️ **NOT FOR PRODUCTION**
- Passwords stored in plaintext
- No HTTPS
- Session-based auth
- CORS enabled for localhost

### For Production:
1. **Hash Passwords**: Use bcrypt or werkzeug.security
2. **Use HTTPS**: Deploy with SSL certificates
3. **JWT Tokens**: Replace sessions with JWT
4. **Database**: Migrate to PostgreSQL
5. **Cloud Hosting**: Deploy to AWS/GCP/Azure
6. **Rate Limiting**: Prevent brute force attacks
7. **Audit Logs**: Track all system changes
8. **Two-Factor Auth**: For admin users

## Testing the System

### Quick Test Flow:
1. Start backend: `python app.py`
2. Open frontend: `frontend/index.html`
3. Login as marshal1 (password: pass)
4. Record a pickup:
   - Plate: CA123WP
   - Rank: Somerset
5. View summary
6. View daily report
7. Try recording 8 more pickups (should hit limit)

### Sample Data
```
Vehicles:
- CA123WP (Cape Town) - Mr. X's vehicle
- DB456WP (Durban) - Mr. Y's vehicle

Ranks (tested):
- Somerset
- Kweza
- Site B
- Makaha
- Harare
- Saipan
```

## Enhancing the System

### Phase 2 Features (Planned):
- [ ] QR code scanning for vehicles
- [ ] Patroller interface for vehicle inspections
- [ ] Monthly PDF reports to owners
- [ ] Push notifications for pickups
- [ ] Location tracking (GPS)
- [ ] Mobile app (React Native)
- [ ] Admin dashboard
- [ ] Payment tracking
- [ ] Multiple branch support

### Phase 3 Features:
- [ ] Long-distance routes management
- [ ] Ticket booking system
- [ ] Revenue tracking (R1.50 per load)
- [ ] Performance analytics
- [ ] Grievance management
- [ ] Driver behavior tracking
- [ ] Vehicle inspection reports
- [ ] Real-time occupancy tracking

## Troubleshooting

### Backend Won't Start
```bash
# Check if port 5000 is in use
# Delete database and restart
rm backend/instance/taxi_system.db
python app.py
```

### Frontend Can't Connect to Backend
- Ensure backend is running on http://127.0.0.1:5000
- Check browser console for CORS errors
- Verify CORS is enabled in Flask app

### Database Schema Issues
- Delete `taxi_system.db`
- Restart Flask app to recreate tables
- Re-seed sample data

## File Structure
```
System/
├── backend/
│   ├── app.py                 # Main Flask application
│   ├── instance/              # Database storage
│   │   └── taxi_system.db
│   ├── requirements.txt        # Python dependencies
│   └── README.md
├── frontend/
│   ├── index.html             # Main UI
│   ├── script.js              # JavaScript logic
│   ├── style.css              # Styling
│   └── README.md
├── taxi_system_prototype.py    # Original prototype
├── README.md                   # Project overview
└── SYSTEM_GUIDE.md            # This file
```

## Key Metrics
- **Daily Limit**: 8 pickups per vehicle
- **Revenue**: R1.50 per load (for billing)
- **Break-even**: ~667 loads per vehicle per month
- **Fairness**: Equal opportunity for all operators

## Contact & Support
For issues or feature requests, contact the system administrator.

---
**Last Updated**: April 2026
**Status**: ✅ LIVE AND TESTED
