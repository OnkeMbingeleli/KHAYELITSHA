"""
Database Seeder Script
Populates the database with comprehensive dummy data for testing
"""

from app import app
from models import db, Marshal, Owner, Vehicle, Pickup
from datetime import datetime, timedelta
import random

def seed_database():
    """Seed the database with realistic test data"""
    
    with app.app_context():
        # Clear existing data (optional - comment out to keep existing data)
        db.drop_all()
        db.create_all()
        
        print("🌱 Starting database seeding...")
        
        # 1. Create Marshals (different ranks and routes)
        marshals_data = [
            # Cape Town Route Marshals
            {"username": "marshal1", "password": "pass123", "name": "John", "route": "Cape Town"},
            {"username": "marshal_ct2", "password": "pass123", "name": "Peter", "route": "Cape Town"},
            {"username": "marshal_ct3", "password": "pass123", "name": "Paul", "route": "Cape Town"},
            
            # Durban Route Marshals
            {"username": "marshal2", "password": "pass123", "name": "Jane", "route": "Durban"},
            {"username": "marshal_dur2", "password": "pass123", "name": "Sarah", "route": "Durban"},
            
            # Johannesburg Route Marshals
            {"username": "marshal_jnb", "password": "pass123", "name": "Mike", "route": "Johannesburg"},
            {"username": "marshal_jnb2", "password": "pass123", "name": "David", "route": "Johannesburg"},
            
            # Port Elizabeth Route Marshals
            {"username": "marshal_pe", "password": "pass123", "name": "James", "route": "Port Elizabeth"},
        ]
        
        existing_marshals = {m.username: m for m in Marshal.query.all()}
        for m_data in marshals_data:
            if m_data["username"] not in existing_marshals:
                marshal = Marshal(**m_data)
                db.session.add(marshal)
                print(f"✓ Added Marshal: {m_data['username']} ({m_data['route']})")
        
        db.session.commit()
        print(f"\n✓ {len([m for m in marshals_data if m['username'] not in existing_marshals])} Marshals added\n")
        
        # 2. Create Owners
        owners_data = [
            # Cape Town Owners
            {"name": "Mandla", "surname": "Nkosi", "email": "mandla@email.com", "contact": "0712345678", "unique_id": "OWNER_CT_001"},
            {"name": "Thabo", "surname": "Mthembu", "email": "thabo@email.com", "contact": "0723456789", "unique_id": "OWNER_CT_002"},
            {"name": "Sipho", "surname": "Dlamini", "email": "sipho@email.com", "contact": "0734567890", "unique_id": "OWNER_CT_003"},
            {"name": "Lindiwe", "surname": "Ndaba", "email": "lindiwe@email.com", "contact": "0745678901", "unique_id": "OWNER_CT_004"},
            
            # Durban Owners
            {"name": "Ayanda", "surname": "Khumalo", "email": "ayanda@email.com", "contact": "0756789012", "unique_id": "OWNER_DUR_001"},
            {"name": "Buhle", "surname": "Ngubane", "email": "buhle@email.com", "contact": "0767890123", "unique_id": "OWNER_DUR_002"},
            
            # Johannesburg Owners
            {"name": "Lerato", "surname": "Mokoena", "email": "lerato@email.com", "contact": "0778901234", "unique_id": "OWNER_JNB_001"},
            {"name": "Themba", "surname": "Shezi", "email": "themba@email.com", "contact": "0789012345", "unique_id": "OWNER_JNB_002"},
            
            # Port Elizabeth Owners
            {"name": "Naledi", "surname": "Bosman", "email": "naledi@email.com", "contact": "0790123456", "unique_id": "OWNER_PE_001"},
        ]
        
        existing_owners = {o.unique_id: o for o in Owner.query.all()}
        owners_map = {}
        for o_data in owners_data:
            if o_data["unique_id"] not in existing_owners:
                owner = Owner(**o_data)
                db.session.add(owner)
                owners_map[o_data["unique_id"]] = owner
                print(f"✓ Added Owner: {o_data['name']} {o_data['surname']} ({o_data['unique_id']})")
            else:
                owners_map[o_data["unique_id"]] = existing_owners[o_data["unique_id"]]
        
        db.session.commit()
        print(f"\n✓ {len(owners_map)} Owners added/found\n")
        
        # 3. Create Vehicles
        vehicles_data = [
            # Cape Town Vehicles
            {"number_plate": "CA123WP", "route": "Cape Town", "capacity": 15, "make": "Toyota", "model": "Hiace", "owner_id_ref": "OWNER_CT_001"},
            {"number_plate": "CA456WP", "route": "Cape Town", "capacity": 16, "make": "Ford", "model": "Transit", "owner_id_ref": "OWNER_CT_001"},
            {"number_plate": "CA789WP", "route": "Cape Town", "capacity": 14, "make": "Mercedes", "model": "Sprinter", "owner_id_ref": "OWNER_CT_002"},
            {"number_plate": "CA101WP", "route": "Cape Town", "capacity": 15, "make": "Toyota", "model": "Quantum", "owner_id_ref": "OWNER_CT_003"},
            {"number_plate": "CA202WP", "route": "Cape Town", "capacity": 16, "make": "Nissan", "model": "Impilo", "owner_id_ref": "OWNER_CT_004"},
            {"number_plate": "CA303WP", "route": "Cape Town", "capacity": 15, "make": "Toyota", "model": "Hiace", "owner_id_ref": "OWNER_CT_002"},
            
            # Durban Vehicles
            {"number_plate": "DB456WP", "route": "Durban", "capacity": 16, "make": "Ford", "model": "Transit", "owner_id_ref": "OWNER_DUR_001"},
            {"number_plate": "DB789WP", "route": "Durban", "capacity": 15, "make": "Toyota", "model": "Hiace", "owner_id_ref": "OWNER_DUR_001"},
            {"number_plate": "DB101WP", "route": "Durban", "capacity": 14, "make": "Nissan", "model": "Impilo", "owner_id_ref": "OWNER_DUR_002"},
            
            # Johannesburg Vehicles
            {"number_plate": "JB123WP", "route": "Johannesburg", "capacity": 15, "make": "Toyota", "model": "Hiace", "owner_id_ref": "OWNER_JNB_001"},
            {"number_plate": "JB456WP", "route": "Johannesburg", "capacity": 16, "make": "Ford", "model": "Transit", "owner_id_ref": "OWNER_JNB_002"},
            
            # Port Elizabeth Vehicles
            {"number_plate": "PE789WP", "route": "Port Elizabeth", "capacity": 15, "make": "Toyota", "model": "Hiace", "owner_id_ref": "OWNER_PE_001"},
        ]
        
        existing_vehicles = {v.number_plate: v for v in Vehicle.query.all()}
        vehicles_map = {}
        for v_data in vehicles_data:
            if v_data["number_plate"] not in existing_vehicles:
                v_copy = v_data.copy()
                owner_ref = v_copy.pop("owner_id_ref")
                v_copy["owner_id"] = owners_map[owner_ref].id
                vehicle = Vehicle(**v_copy)
                db.session.add(vehicle)
                vehicles_map[v_data["number_plate"]] = vehicle
                print(f"✓ Added Vehicle: {v_data['number_plate']} ({v_data['route']}) - Owner: {v_data['owner_id_ref']}")
            else:
                vehicles_map[v_data["number_plate"]] = existing_vehicles[v_data["number_plate"]]
        
        db.session.commit()
        print(f"\n✓ {len(vehicles_map)} Vehicles added/found\n")
        
        # 4. Create Sample Pickups (for demo data)
        ranks = ["Somerset", "Kweza", "Site B", "Makaha", "Harare", "Saipan", "Claremont", "Weinberg", "Fish Hook", "Sea Point"]
        
        # Add sample pickups for the last 3 hours
        existing_pickups_count = Pickup.query.count()
        
        if existing_pickups_count == 0:
            print("🚕 Adding sample pickup records...\n")
            marshals = Marshal.query.all()
            
            for i in range(25):  # Add 25 sample pickups
                # Select random marshal and vehicle from same route
                marshal = random.choice(marshals)
                vehicles = Vehicle.query.filter_by(route=marshal.route).all()
                
                if vehicles:
                    vehicle = random.choice(vehicles)
                    rank = random.choice(ranks)
                    
                    # Random time in last 3 hours
                    time_offset = random.randint(0, 180)
                    pickup_time = datetime.now() - timedelta(minutes=time_offset)
                    
                    pickup = Pickup(
                        number_plate=vehicle.number_plate,
                        rank=rank,
                        route=marshal.route,
                        timestamp=pickup_time,
                        marshal_id=marshal.id
                    )
                    
                    db.session.add(pickup)
                    vehicle.loads_today += 1
                    print(f"✓ Pickup: {vehicle.number_plate} at {rank} by {marshal.username}")
            
            db.session.commit()
            print(f"\n✓ 25 sample pickups added\n")
        
        print("=" * 60)
        print("✅ DATABASE SEEDING COMPLETE!")
        print("=" * 60)
        print("\n📊 SUMMARY:")
        print(f"  • Marshals: {Marshal.query.count()}")
        print(f"  • Owners: {Owner.query.count()}")
        print(f"  • Vehicles: {Vehicle.query.count()}")
        print(f"  • Pickups: {Pickup.query.count()}")
        print("\n🔑 TEST CREDENTIALS:")
        print("  • marshal1 / pass123 (Cape Town)")
        print("  • marshal2 / pass123 (Durban)")
        print("  • marshal_jnb / pass123 (Johannesburg)")
        print("  • marshal_pe / pass123 (Port Elizabeth)")
        print("\n💡 TIP: All passwords are 'pass123'")
        print("=" * 60)

if __name__ == "__main__":
    seed_database()
