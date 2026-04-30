from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_cors import CORS
from datetime import datetime
import os

# Import models and db
from models import db, Marshal, Owner, Vehicle, Pickup

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend
app.config['SECRET_KEY'] = 'your-secret-key'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///taxi_system.db'

# Initialize db with app
db.init_app(app)

# Setup Flask-Login
login_manager = LoginManager(app)
login_manager.login_view = 'login'

# Import admin blueprint
from admin import admin_bp
app.register_blueprint(admin_bp)

@login_manager.user_loader
def load_user(user_id):
    return Marshal.query.get(int(user_id))

@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        marshal = Marshal.query.filter_by(username=username).first()
        if marshal and marshal.password == password:  # In production, use hashed passwords
            login_user(marshal)
            return redirect(url_for('index'))
        flash('Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/record', methods=['GET', 'POST'])
@login_required
def record():
    if request.method == 'POST':
        number_plate = request.form.get('number_plate')
        rank = request.form.get('rank')
        vehicle = Vehicle.query.filter_by(number_plate=number_plate).first()
        if vehicle and vehicle.route == current_user.route:
            if vehicle.loads_today < 8:  # Daily limit
                pickup = Pickup(number_plate=number_plate, rank=rank, route=vehicle.route, marshal_id=current_user.id)
                db.session.add(pickup)
                vehicle.loads_today += 1
                db.session.commit()
                flash('Pickup recorded')
            else:
                flash('Vehicle has reached daily limit')
        else:
            flash('Invalid vehicle or not in your route')
    return render_template('record.html')

@app.route('/summary')
@login_required
def summary():
    pickups = Pickup.query.filter_by(route=current_user.route).all()
    total_loads = sum(v.loads_today for v in Vehicle.query.filter_by(route=current_user.route).all())
    return render_template('summary.html', pickups=pickups, total_loads=total_loads)

# API Endpoints for Frontend
from flask import jsonify

@app.route('/api/login', methods=['POST'])
def api_login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    marshal = Marshal.query.filter_by(username=username).first()
    if marshal and marshal.password == password:
        login_user(marshal)
        return jsonify({'message': 'Logged in', 'user_id': marshal.id})
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/record', methods=['POST'])
@login_required
def api_record():
    data = request.get_json()
    number_plate = data.get('number_plate')
    rank = data.get('rank')
    vehicle = Vehicle.query.filter_by(number_plate=number_plate).first()
    if vehicle and vehicle.route == current_user.route:
        if vehicle.loads_today < 8:
            pickup = Pickup(number_plate=number_plate, rank=rank, route=vehicle.route, marshal_id=current_user.id)
            db.session.add(pickup)
            vehicle.loads_today += 1
            db.session.commit()
            return jsonify({'message': 'Pickup recorded'})
        else:
            return jsonify({'error': 'Daily limit reached'}), 400
    return jsonify({'error': 'Invalid vehicle'}), 400

@app.route('/api/summary')
@login_required
def api_summary():
    pickups = Pickup.query.filter_by(route=current_user.route).all()
    
    # Group pickups by rank
    rank_summary = {}
    for pickup in pickups:
        if pickup.rank not in rank_summary:
            rank_summary[pickup.rank] = 0
        rank_summary[pickup.rank] += 1
    
    # Get vehicle details with owner info
    pickup_details = []
    for pickup in pickups:
        vehicle = Vehicle.query.filter_by(number_plate=pickup.number_plate).first()
        owner = Owner.query.get(vehicle.owner_id) if vehicle else None
        pickup_details.append({
            'number_plate': pickup.number_plate,
            'rank': pickup.rank,
            'timestamp': pickup.timestamp.isoformat(),
            'owner_name': f"{owner.name} {owner.surname}" if owner else "Unknown",
            'vehicle_capacity': vehicle.capacity if vehicle else 0
        })
    
    total_loads = sum(v.loads_today for v in Vehicle.query.filter_by(route=current_user.route).all())
    
    return jsonify({
        'pickups': pickup_details,
        'rank_summary': rank_summary,
        'total_loads': total_loads,
        'route': current_user.route
    })

@app.route('/api/owner/register', methods=['POST'])
def register_owner():
    """Register a new owner and their vehicles"""
    data = request.get_json()
    
    try:
        # Create owner
        owner = Owner(
            name=data.get('name'),
            surname=data.get('surname'),
            email=data.get('email'),
            contact=data.get('contact'),
            unique_id=data.get('unique_id', f"OWNER_{datetime.now().timestamp()}")
        )
        db.session.add(owner)
        db.session.commit()
        
        # Add vehicles for this owner
        vehicles_data = data.get('vehicles', [])
        for v in vehicles_data:
            vehicle = Vehicle(
                number_plate=v.get('number_plate'),
                owner_id=owner.id,
                route=v.get('route'),
                capacity=v.get('capacity', 15),
                make=v.get('make'),
                model=v.get('model')
            )
            db.session.add(vehicle)
        
        db.session.commit()
        return jsonify({'message': 'Owner registered successfully', 'owner_id': owner.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 400

@app.route('/api/vehicles/<route>', methods=['GET'])
@login_required
def get_vehicles_by_route(route):
    """Get all vehicles for a specific route"""
    vehicles = Vehicle.query.filter_by(route=route).all()
    vehicle_list = []
    for v in vehicles:
        owner = Owner.query.get(v.owner_id)
        vehicle_list.append({
            'number_plate': v.number_plate,
            'owner': f"{owner.name} {owner.surname}" if owner else "Unknown",
            'capacity': v.capacity,
            'loads_today': v.loads_today,
            'make': v.make,
            'model': v.model
        })
    return jsonify({'vehicles': vehicle_list})

@app.route('/api/daily-report', methods=['GET'])
@login_required
def daily_report():
    """Get detailed daily report for the logged-in marshal's route"""
    route = current_user.route
    pickups = Pickup.query.filter_by(route=route).all()
    
    # Group by vehicle and rank
    vehicle_details = {}
    for pickup in pickups:
        if pickup.number_plate not in vehicle_details:
            vehicle = Vehicle.query.filter_by(number_plate=pickup.number_plate).first()
            owner = Owner.query.get(vehicle.owner_id) if vehicle else None
            vehicle_details[pickup.number_plate] = {
                'owner': f"{owner.name} {owner.surname}" if owner else "Unknown",
                'ranks': {},
                'total_loads': 0
            }
        
        if pickup.rank not in vehicle_details[pickup.number_plate]['ranks']:
            vehicle_details[pickup.number_plate]['ranks'][pickup.rank] = 0
        
        vehicle_details[pickup.number_plate]['ranks'][pickup.rank] += 1
        vehicle_details[pickup.number_plate]['total_loads'] += 1
    
    return jsonify({
        'route': route,
        'date': datetime.now().isoformat(),
        'vehicles': vehicle_details,
        'total_system_loads': sum(v.loads_today for v in Vehicle.query.filter_by(route=route).all())
    })

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        # Add sample data
        if not Marshal.query.first():
            db.session.add(Marshal(username='marshal1', password='pass', name='John Doe', route='Cape Town'))
            db.session.add(Marshal(username='marshal2', password='pass', name='Jane Smith', route='Durban'))
            db.session.commit()
        
        if not Owner.query.first():
            owner1 = Owner(name='Mr.', surname='X', email='mrx@email.com', contact='0123456789', unique_id='OWNER_001')
            owner2 = Owner(name='Mr.', surname='Y', email='mry@email.com', contact='0987654321', unique_id='OWNER_002')
            db.session.add(owner1)
            db.session.add(owner2)
            db.session.commit()
            
            # Now add vehicles with owner references
            db.session.add(Vehicle(number_plate='CA123WP', owner_id=owner1.id, route='Cape Town', capacity=15, make='Toyota', model='Hiace'))
            db.session.add(Vehicle(number_plate='DB456WP', owner_id=owner2.id, route='Durban', capacity=16, make='Ford', model='Transit'))
            db.session.commit()
    app.run(debug=True)
