"""
Admin Dashboard - View and manage the database
"""

from flask import Blueprint, jsonify
from models import db, Marshal, Owner, Vehicle, Pickup
from datetime import datetime

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

@admin_bp.route('/stats', methods=['GET'])
def get_stats():
    """Get database statistics"""
    return jsonify({
        'marshals_count': Marshal.query.count(),
        'owners_count': Owner.query.count(),
        'vehicles_count': Vehicle.query.count(),
        'pickups_count': Pickup.query.count(),
        'total_loads_today': sum(v.loads_today for v in Vehicle.query.all()),
        'timestamp': datetime.now().isoformat()
    })

@admin_bp.route('/marshals', methods=['GET'])
def list_marshals():
    """List all marshals"""
    marshals = Marshal.query.all()
    return jsonify({
        'total': len(marshals),
        'data': [
            {
                'id': m.id,
                'username': m.username,
                'name': m.name,
                'route': m.route,
                'pickups_count': Pickup.query.filter_by(marshal_id=m.id).count()
            }
            for m in marshals
        ]
    })

@admin_bp.route('/owners', methods=['GET'])
def list_owners():
    """List all owners with their vehicles"""
    owners = Owner.query.all()
    return jsonify({
        'total': len(owners),
        'data': [
            {
                'id': o.id,
                'name': f"{o.name} {o.surname}",
                'email': o.email,
                'contact': o.contact,
                'unique_id': o.unique_id,
                'vehicles_count': Vehicle.query.filter_by(owner_id=o.id).count(),
                'total_loads': sum(v.loads_today for v in Vehicle.query.filter_by(owner_id=o.id).all())
            }
            for o in owners
        ]
    })

@admin_bp.route('/vehicles', methods=['GET'])
def list_vehicles():
    """List all vehicles"""
    vehicles = Vehicle.query.all()
    return jsonify({
        'total': len(vehicles),
        'data': [
            {
                'id': v.id,
                'number_plate': v.number_plate,
                'owner': f"{v.owner.name} {v.owner.surname}" if v.owner else "Unknown",
                'route': v.route,
                'capacity': v.capacity,
                'loads_today': v.loads_today,
                'make': v.make,
                'model': v.model,
                'daily_limit': 8,
                'limit_remaining': 8 - v.loads_today
            }
            for v in vehicles
        ]
    })

@admin_bp.route('/pickups', methods=['GET'])
def list_pickups():
    """List all pickups"""
    pickups = Pickup.query.all()
    return jsonify({
        'total': len(pickups),
        'data': [
            {
                'id': p.id,
                'number_plate': p.number_plate,
                'rank': p.rank,
                'route': p.route,
                'timestamp': p.timestamp.isoformat(),
                'marshal': Marshal.query.get(p.marshal_id).username
            }
            for p in pickups
        ]
    })

@admin_bp.route('/vehicles/by-route/<route>', methods=['GET'])
def vehicles_by_route(route):
    """Get vehicles for a specific route"""
    vehicles = Vehicle.query.filter_by(route=route).all()
    return jsonify({
        'route': route,
        'total': len(vehicles),
        'data': [
            {
                'number_plate': v.number_plate,
                'owner': f"{v.owner.name} {v.owner.surname}" if v.owner else "Unknown",
                'capacity': v.capacity,
                'loads_today': v.loads_today,
                'make': v.make,
                'model': v.model
            }
            for v in vehicles
        ]
    })

@admin_bp.route('/pickups/by-rank/<rank>', methods=['GET'])
def pickups_by_rank(rank):
    """Get pickups for a specific rank"""
    pickups = Pickup.query.filter_by(rank=rank).all()
    return jsonify({
        'rank': rank,
        'total': len(pickups),
        'data': [
            {
                'number_plate': p.number_plate,
                'route': p.route,
                'timestamp': p.timestamp.isoformat(),
                'marshal': Marshal.query.get(p.marshal_id).username
            }
            for p in pickups
        ]
    })

@admin_bp.route('/reset-loads', methods=['POST'])
def reset_daily_loads():
    """Reset daily loads (call at end of day)"""
    vehicles = Vehicle.query.all()
    for v in vehicles:
        v.loads_today = 0
    db.session.commit()
    return jsonify({'message': 'Daily loads reset', 'vehicles_reset': len(vehicles)})

@admin_bp.route('/routes', methods=['GET'])
def list_routes():
    """List all unique routes"""
    routes = db.session.query(Vehicle.route).distinct().all()
    route_list = [r[0] for r in routes]
    
    route_stats = []
    for route in route_list:
        vehicles = Vehicle.query.filter_by(route=route).all()
        pickups = Pickup.query.filter_by(route=route).all()
        marshals = db.session.query(Marshal.route).filter_by(route=route).distinct().all()
        
        route_stats.append({
            'name': route,
            'vehicles': len(vehicles),
            'pickups_today': len(pickups),
            'total_loads': sum(v.loads_today for v in vehicles),
            'marshals': len(marshals),
            'ranks': list(set(p.rank for p in pickups))
        })
    
    return jsonify({'total_routes': len(route_list), 'routes': route_stats})

@admin_bp.route('/update-location/marshal/<int:marshal_id>', methods=['POST'])
def update_marshal_location(marshal_id):
    """Update marshal location"""
    from flask import request
    data = request.get_json()
    
    marshal = Marshal.query.get_or_404(marshal_id)
    marshal.latitude = data.get('latitude')
    marshal.longitude = data.get('longitude')
    marshal.location_updated = datetime.now()
    
    db.session.commit()
    return jsonify({'message': 'Marshal location updated', 'marshal_id': marshal_id})

@admin_bp.route('/update-location/vehicle/<number_plate>', methods=['POST'])
def update_vehicle_location(number_plate):
    """Update vehicle location"""
    from flask import request
    data = request.get_json()
    
    vehicle = Vehicle.query.filter_by(number_plate=number_plate).first_or_404()
    vehicle.latitude = data.get('latitude')
    vehicle.longitude = data.get('longitude')
    vehicle.location_updated = datetime.now()
    
    db.session.commit()
    return jsonify({'message': 'Vehicle location updated', 'number_plate': number_plate})

@admin_bp.route('/locations', methods=['GET'])
def get_all_locations():
    """Get all marshal and vehicle locations for live map"""
    marshals = Marshal.query.filter(Marshal.latitude.isnot(None), Marshal.longitude.isnot(None)).all()
    vehicles = Vehicle.query.filter(Vehicle.latitude.isnot(None), Vehicle.longitude.isnot(None)).all()
    
    return jsonify({
        'marshals': [
            {
                'id': m.id,
                'name': m.name,
                'username': m.username,
                'route': m.route,
                'latitude': m.latitude,
                'longitude': m.longitude,
                'location_updated': m.location_updated.isoformat() if m.location_updated else None,
                'type': 'marshal'
            }
            for m in marshals
        ],
        'vehicles': [
            {
                'id': v.id,
                'number_plate': v.number_plate,
                'route': v.route,
                'latitude': v.latitude,
                'longitude': v.longitude,
                'location_updated': v.location_updated.isoformat() if v.location_updated else None,
                'loads_today': v.loads_today,
                'capacity': v.capacity,
                'owner': f"{v.owner.name} {v.owner.surname}" if v.owner else "Unknown",
                'type': 'vehicle'
            }
            for v in vehicles
        ],
        'timestamp': datetime.now().isoformat()
    })
