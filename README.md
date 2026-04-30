# Taxi Management System
A taxi association management platform for route, vehicle, and operational load tracking in Cape Town and Khayelitsha.

## Project Overview
A full-stack web application for managing taxi operations in associations, ensuring fair distribution of pickups and providing secure data management.

## Architecture
- **Backend**: Flask (Python) with SQLite database, API endpoints
- **Frontend**: Vanilla HTML/CSS/JS single-page application
- **Security**: Session-based auth, role-based access

## Folder Structure
```
/
├── backend/          # Flask server, database, API
│   ├── app.py        # Main Flask app with routes
│   ├── templates/    # HTML templates for server-side rendering
│   ├── requirements.txt  # Python dependencies
│   └── README.md     # Backend docs
├── frontend/         # Client-side app
│   ├── index.html    # Main page
│   ├── style.css     # Styling
│   ├── script.js     # JavaScript logic
│   └── README.md     # Frontend docs
└── README.md         # This file
```

## Setup Instructions
1. **Backend**:
   - `cd backend`
   - `pip install -r requirements.txt`
   - `python app.py` (runs on http://127.0.0.1:5000)

2. **Frontend**:
   - Open `frontend/index.html` in browser
   - Ensure backend is running

## Features
- Marshal authentication
- Pickup recording with daily limits
- Route-based access control
- Real-time summaries
- Mobile-friendly interface

## Security Considerations
- Use HTTPS in production
- Hash passwords (currently demo)
- Deploy to cloud (AWS/GCP/Azure)
- Enable CORS for frontend-backend communication

## Future Enhancements
- QR code scanning
- Push notifications
- Admin dashboard
- Mobile app (React Native)
- Cloud database migration

## Demo Credentials
- Username: marshal1, Password: pass (Cape Town route)
- Username: marshal2, Password: pass (Durban route)
