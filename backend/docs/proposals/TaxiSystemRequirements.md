# Taxi Management System Requirements

## System Overview
This system is designed for taxi associations in South Africa (RSA), specifically starting with the Kuwait branch. It manages taxi operations across multiple ranks and routes to ensure fair distribution of pickups and provide reporting for owners and management.

## Key Components
- **Marshals**: Record pickups at ranks.
- **Routes**: Various routes under the Kuwait branch, e.g., Cape Town, Durban, etc.
- **Ranks**: Sub-divisions within the branch (A to F).
- **Owners**: Taxi owners with registered vehicles.
- **Management**: Oversees operations, generates reports.

## Features

### Pickup Recording
- Marshals log vehicle number plates when taxis load passengers at ranks.
- Records include timestamp, rank, and route.
- Prevents overloading by limiting pickups per vehicle per day (e.g., 8-10 loads).
- Tracks pickups from township to town and returns.

### Reporting
- Daily summaries: Total loads per vehicle, per rank, per route.
- Monthly reports: Sent to owners on the 1st of each month.
- Includes timestamps, locations, and totals.
- Management reports for fairness and analysis.

### QR Code Integration
- Vehicles have QR codes with route, number plate, owner ID, passenger capacity.
- Marshals can scan instead of manual entry.
- Patrollers scan vehicles and drivers for compliance.

### Patrollers
- Monitor routes, scan vehicles, report issues (behavior, vehicle condition).
- Send reports to route executives for discipline and maintenance.

### Long Distance Routes
- Separate system for long-distance travel with ticket booking.
- Track tickets sold, scanners at checkpoints.

### Security and Access
- Offline system communicating with 3 management computers.
- Limited access: Only authorized personnel can edit data.
- Owner registration via online form, generates ID and QR codes.

### Revenue Model
- Charge per load (e.g., 150 cents per load) to associations.
- Monthly billing based on total loads.

## Additional Notes
- Start with local Kuwait branch, expand later.
- Include maps for visualization of pickups and movements.
- Monthly analysis of issues (e.g., vehicle problems, driver behavior).    
Onke Mbingeleli
15:58 (1 minute ago)
to me

You’re thinking in the right direction — before building the marshal app, you must secure the core system (backend + data). That’s the “brain” of everything.

You want something like an “MR app style” → meaning:

Always online
Accessible from phones
Central control
Secure
Let’s structure the safest and simplest way to do this 👇

☁️ 1. WHERE TO KEEP THE SYSTEM (CORE)
You don’t keep it on a phone or one computer.

👉 You keep it on cloud hosting (online servers)

✔ Best beginner-friendly options:
Amazon Web Services (AWS)
Google Cloud Platform
Microsoft Azure
✔ Easier (low-code option you were told before):
Oracle APEX
👉 This one is very good for:

Forms (owner registration)
Database
Reports
Fast setup
🧠 2. WHAT “CORE SYSTEM” MEANS
Your core system includes:

Database (owners, vehicles, loads, reports)
API (connects app ↔ system)
Admin dashboard (management side)
👉 This lives in the cloud, not on devices.

📱 3. BEFORE THE APP (IMPORTANT STRATEGY)
Don’t rush to build the app first.

✔ Phase 1 (Smart move):
Use:

Web system (browser-based)
Marshals can even use:

Phone browser (Chrome)
👉 Scan + submit from web first

✔ Phase 2:
Then build Android APK

🔐 4. HOW TO KEEP IT SAFE
This is critical because your system controls money + operations.

🔹 A. LOGIN SECURITY
Username + strong password
Role-based access (marshal, patrol, admin)
Only 2 super admins (you already planned this ✔)
🔹 B. HTTPS (VERY IMPORTANT)
Your system must use:

👉 Secure connection (https://)

✔ Prevents data interception

🔹 C. DATABASE SECURITY
Only server can access database
No direct public access
Regular backups (daily)
🔹 D. ACTIVITY LOGS
Track everything:

Who logged in
What they did
When
🔹 E. DEVICE CONTROL (OPTIONAL LATER)
Only registered devices can log in
Helps prevent unauthorized access
📡 5. “MR APP STYLE” EXPLAINED
What you mean is:

👉 Central system + many users connecting

That is called:

Client-Server Architecture

✔ How it works:
Server (cloud) → stores everything
Phones → connect to server
Data updates in real-time
🧱 6. SIMPLE ARCHITECTURE (YOUR SYSTEM)
🔹 BACKEND (cloud)
Database
Logic
Security
🔹 FRONTEND
Web dashboard (management)
Mobile app (marshals & patrols later)
🔹 USERS
Marshals
Patrollers
Management
⚠️ 7. WHAT NOT TO DO
❌ Don’t store data only on phones
❌ Don’t use WhatsApp or Excel as main system
❌ Don’t run system from one laptop only

👉 You’ll lose data or get hacked

💡 8. BEST STARTING STACK (REALISTIC FOR YOU)
Since you want something practical:

✔ Option 1 (FASTEST START)
Oracle APEX
Cloud hosting included
Build forms + reports quickly
✔ Option 2 (MORE CONTROL)
Backend: Node.js / Django
Database: PostgreSQL
Hosting: AWS / Google Cloud
🚀 9. STEP-BY-STEP (WHAT YOU SHOULD DO NOW)
Step 1:
Build database + web system

Step 2:
Host it online (cloud)

Step 3:
Test with:

Owner registration form
QR system
Basic load logging
Step 4:
Then build mobile app
