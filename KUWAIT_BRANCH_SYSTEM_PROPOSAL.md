# Kuwait Branch Taxi Operations System Proposal

## 1. Executive Summary
+
+This document turns the conversation brief into a structured system proposal for a taxi association operations platform, starting with one association and one branch: **Kuwait Branch**.
+
+The goal is to replace informal/manual marshal logging with a secure digital system that:
+
+- records taxi loads by route, rank, and time
+- improves fairness between operators
+- gives management live operational visibility
+- produces daily and monthly owner reports
+- prepares the association for QR scanning, patrol workflows, and future expansion
+
+The recommended delivery approach is:
+
+1. Start with a **web-based system** that works on phones and office computers.
+2. Use it to test one association and one branch first.
+3. Add QR scanning, patrol features, and owner automation next.
+4. Only build a dedicated APK after the core system is stable.
+
## 2. Problem Statement
+
+The association currently depends on manual rank processes that can create:
+
+- disputes over who loaded first
+- unfair overloading by some taxis
+- poor visibility into total loads by taxi, route, and rank
+- weak owner reporting
+- limited evidence for discipline, maintenance, and planning
+
+A digital system is needed to centralize this information and make operations more transparent, fair, and measurable.
+
## 3. Scope for Phase 1
+
+Phase 1 focuses on the **local Kuwait Branch system** only.
+
+Included in scope:
+
+- one association
+- Kuwait Branch
+- ranks/sub-ranks `A` to `F`
+- multiple routes under the branch
+- marshal login and load recording
+- route-based summaries
+- owner and vehicle registration
+- management dashboard/reporting
+
+Not included yet:
+
+- full national rollout
+- long-distance ticketing
+- full hardware scanner network across routes
+- advanced driver mobile app workflows
+
## 4. Core Business Goal
+
+The system must ensure that every recorded load contributes to:
+
+- fairness between taxis on the same route
+- traceability of where and when a taxi loaded
+- accurate owner reporting
+- management visibility of busy and quiet pickup points
+- future revenue billing based on loads
+
## 5. Users and Roles
+
+### 5.1 Marshals
+
+Marshals work at ranks or pickup points.
+
+They must be able to:
+
+- log in
+- choose their working location
+- work only on their assigned route
+- record a taxi load quickly
+- optionally add a comment/report
+- see whether a vehicle already reached its daily load limit
+
+### 5.2 Patrollers
+
+Patrollers check vehicles and drivers on the road.
+
+They must be able to:
+
+- log in to a separate interface
+- scan the vehicle QR code
+- identify the active driver
+- record behavior complaints
+- record vehicle defects
+- attach a photo when needed
+
+### 5.3 Management
+
+Management needs full operational visibility.
+
+They must be able to:
+
+- manage routes, ranks, owners, vehicles, and users
+- view live movement/load summaries
+- enable or disable inspection forms
+- review complaints and inspection issues
+- generate monthly owner reports
+- control system settings
+
+### 5.4 Super Admins
+
+Only two trusted users should have full control of the entire system, including configuration and security-sensitive actions.
+
## 6. Operational Model
+
+### 6.1 Branch Structure
+
+The first branch is **Kuwait Branch**, which contains:
+
+- one main branch
+- six operating ranks or sub-ranks: `A`, `B`, `C`, `D`, `E`, `F`
+- many routes shared across these ranks
+
+A route may appear in more than one pickup location.
+
+### 6.2 Route Logic
+
+Each marshal belongs to a route or works for a specific route on a given day.
+
+Example:
+
+- Cape Town route loads should be recorded separately from Claremont, Wynberg, Fish Hoek, or other routes.
+- A marshal for one route should not record loads for unrelated routes.
+
+### 6.3 Load Recording Logic
+
+A load event records:
+
+- vehicle number plate
+- route
+- pickup rank/location
+- direction
+- timestamp
+- marshal identity
+- optional notes
+
+The system must support:
+
+- township to town loads
+- town back to township loads
+- multiple pickup points in a day for the same vehicle
+
+### 6.4 Fairness Control
+
+The system must show how many loads a vehicle already has for the day.
+
+This helps marshals stop overloading by a single operator and give other taxis a fair chance.
+
+Example rule:
+
+- daily cap of `8` loads per vehicle, configurable by management
+
## 7. Required Features
+
+### 7.1 Marshal Workflow
+
+On login, a marshal should:
+
+1. identify themselves
+2. confirm assigned route
+3. confirm pickup spot or rank
+4. start capturing loads quickly
+
+Fast capture fields:
+
+- number plate or QR scan
+- submit
+
+Optional fields:
+
+- comment
+- incident/behavior note
+
+### 7.2 Owner and Vehicle Registration
+
+Owners must be registered with:
+
+- name
+- surname
+- date of birth
+- ID number
+- contact details
+- email
+- branch
+- route
+
+Vehicles must be registered with:
+
+- number plate
+- make
+- model
+- seat capacity
+- owner link
+- route
+- branch
+
+The system should generate:
+
+- a unique owner ID
+- owner identification card details
+- QR sticker data per vehicle
+
+### 7.3 QR Sticker Requirements
+
+Each vehicle QR sticker should contain or resolve to:
+
+- route identifier
+- owner identifier
+- number plate
+- vehicle capacity
+- branch/office identity
+
+Branding note:
+
+- include `CODETA` around the sticker in a circular layout if required by the association design
+
+### 7.4 Daily Summary
+
+The system must produce a daily summary showing:
+
+- total loads per route
+- total loads per rank
+- total loads per vehicle
+- timestamps of each load
+- total township-to-town loads
+- total town-to-township return loads
+
+Example insight:
+
+- Vehicle `1808WP` loaded at Somerset twice, Site B once, and Kweza once.
+
+### 7.5 Monthly Owner Reporting
+
+A monthly report should be generated for each owner and sent on the agreed reporting cycle.
+
+Recommended cycle:
+
+- generate at the start of each month for the previous month
+
+Each report should include:
+
+- owner identity
+- registered vehicles
+- total loads per vehicle
+- loads by rank
+- route summary
+- vehicle issues raised
+- patrol comments/discipline notes where applicable
+
+### 7.6 Patrol and Inspection Module
+
+Patrollers must be able to record:
+
+- driver behavior incidents
+- vehicle condition issues
+- supporting notes
+- photos
+
+Examples of inspection items:
+
+- windscreen damaged
+- left light not working
+- unsafe vehicle condition
+
+Management should be able to turn this inspection form on or off depending on operational needs.
+
+### 7.7 Live Operations Dashboard
+
+The office should be able to display:
+
+- a map or layout of pickup points
+- which spots are busiest today
+- route-by-route movement
+- daily and monthly analysis
+
+Display recommendations:
+
+- one main office summary screen for overall branch movement
+- route-specific screens for route managers/owners
+
+### 7.8 Alerts and Trend Analysis
+
+The system should help management identify:
+
+- high-demand pickup spots
+- low-demand pickup spots
+- repeated vehicle defects
+- repeated driver behavior issues
+- vehicles exceeding fair-load thresholds
+
## 8. Non-Functional Requirements
+
+The system should be:
+
+- secure
+- always online for core use
+- usable from phones
+- lightweight for marshals
+- role-based
+- auditable
+- expandable to other associations later
+
+Security requirements:
+
+- HTTPS in production
+- role-based access control
+- password hashing
+- activity logs
+- backups
+- only two super admins with full system power
+
## 9. Recommended Technical Approach
+
+### 9.1 Best First Step
+
+Build the first version as a **web system** instead of a full mobile app.
+
+Why:
+
+- faster to deliver
+- easier to update
+- works on phones via browser
+- ideal for testing the business process first
+
+### 9.2 Architecture
+
+Recommended architecture:
+
+- **Frontend:** responsive web interface
+- **Backend:** API + business rules
+- **Database:** central cloud database
+- **Hosting:** secure cloud deployment
+
+### 9.3 Practical Stack
+
+Good Phase 1 stack:
+
+- Flask or Django backend
+- PostgreSQL database for production
+- responsive web frontend
+- QR code generation library
+- PDF reporting service
+
+Alternative low-code option:
+
+- Oracle APEX
+
+### 9.4 Hosting Recommendation
+
+Do not store the core system on one phone or one laptop.
+
+Use central hosting such as:
+
+- AWS
+- Google Cloud
+- Microsoft Azure
+
## 10. Suggested Database Entities
+
+Main entities:
+
+- Branch
+- Rank
+- Route
+- Owner
+- Vehicle
+- Marshal
+- Patroller
+- LoadRecord
+- InspectionReport
+- BehaviorReport
+- MonthlyReport
+- Device
+- UserRole
+
+Important relationships:
+
+- one owner has many vehicles
+- one route has many vehicles
+- one rank records many loads
+- one marshal records many load events
+- one vehicle can have many load records in a day
+
## 11. Phase Delivery Plan
+
+### Phase 1: Foundation
+
+- owner registration
+- vehicle registration
+- marshal login
+- route-based load capture
+- daily summary
+- management dashboard
+
+### Phase 2: Operational Control
+
+- QR sticker generation
+- QR scanning
+- patrol module
+- monthly PDF owner reports
+- fairness/load limit logic refinement
+
+### Phase 3: Expansion
+
+- map/projector dashboard
+- route-level live analytics
+- device restrictions
+- association-to-association rollout
+
+### Phase 4: Advanced Extensions
+
+- long-distance module
+- ticketing/cane system
+- checkpoint scanning
+- broader regional/national scaling
+
## 12. Revenue Model Estimate
+
+If the business charges **R1.50 per load**:
+
+- to make **R1,000,000** total revenue, you need about **666,667 loads**
+- over **6 months**, that is about **111,112 loads per month**
+- that is about **3,704 loads per day** on a 30-day month
+
+Formula:
+
+`required loads = target revenue / price per load`
+
+This is gross revenue only and does not subtract hosting, development, support, admin, devices, printing, or field operations.
+
## 13. Risks and Controls
+
+Key risks:
+
+- marshals bypassing the system
+- wrong route assignment
+- duplicate or fake vehicle records
+- unauthorized admin access
+- poor internet at busy ranks
+- owner mistrust if reports are inaccurate
+
+Controls:
+
+- route-based permissions
+- activity logs
+- unique QR stickers
+- daily backups
+- audit reports
+- configurable offline capture later if needed
+
## 14. Clear MVP Recommendation
+
+The first working version should do only these things extremely well:
+
+- user login
+- owner registration
+- vehicle registration
+- route-based load capture
+- daily summaries
+- monthly report generation
+- admin visibility
+
+This gives immediate business value and creates a strong foundation for QR scanning and patrol workflows.
+
## 15. Conclusion
+
+This system is viable and valuable if built in stages.
+
+The strongest approach is to treat it as a **central online operations system** first, not just a phone app. The marshal interface should stay simple, while the backend handles fairness, visibility, summaries, and reporting.
+
+The best next move is to finalize the data model and complete a solid Phase 1 web system for one association before expanding into full scanning hardware, patrol automation, and multi-association rollout.

