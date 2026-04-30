# Taxi Management System - Backend

## Overview
This is the backend for the Taxi Management System, built with Flask. It provides API endpoints for marshals to record pickups, view summaries, and manage data securely.

## Features
- User authentication (marshals)
- Pickup recording with validation
- Daily summaries
- SQLite database for development (upgrade to PostgreSQL for production)

## Setup
1. Install dependencies: `pip install -r requirements.txt`
2. Run: `python app.py`
3. Access at http://localhost:5000

## SQL Initialization
If you want to build the database directly from SQL, use these files:
- `kuwait_branch_schema.sql` — creates the full relational schema
- `kuwait_branch_seed.sql` — inserts sample branch, rank, route, user, owner, and vehicle data
- `sql_reference.sql` — sample SELECT queries for the schema

Run these commands from the `backend` folder:
```bash
sqlite3 taxi_system.db < kuwait_branch_schema.sql
sqlite3 taxi_system.db < kuwait_branch_seed.sql
```

## Security Notes
- Use HTTPS in production
- Hash passwords (currently plain for demo)
- Deploy to cloud (AWS/GCP/Azure)

## API Endpoints
- /login: POST for login
- /record: POST to record pickup
- /summary: GET for daily summary
