"""
Database Models
Defines all database tables for the Taxi Management System
"""

from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from datetime import datetime

db = SQLAlchemy()

class Marshal(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    name = db.Column(db.String(150), nullable=False)
    route = db.Column(db.String(150), nullable=False)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    location_updated = db.Column(db.DateTime, nullable=True)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    location_updated = db.Column(db.DateTime, nullable=True)

class Owner(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    surname = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), nullable=False)
    contact = db.Column(db.String(20), nullable=False)
    unique_id = db.Column(db.String(50), unique=True, nullable=False)

class Vehicle(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number_plate = db.Column(db.String(20), unique=True, nullable=False)
    owner_id = db.Column(db.Integer, db.ForeignKey('owner.id'), nullable=False)
    route = db.Column(db.String(150), nullable=False)
    capacity = db.Column(db.Integer, nullable=False)
    loads_today = db.Column(db.Integer, default=0)
    make = db.Column(db.String(50), nullable=True)
    model = db.Column(db.String(50), nullable=True)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    location_updated = db.Column(db.DateTime, nullable=True)
    
    owner = db.relationship('Owner', backref='vehicles')

class Pickup(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number_plate = db.Column(db.String(20), db.ForeignKey('vehicle.number_plate'), nullable=False)
    rank = db.Column(db.String(50), nullable=False)
    route = db.Column(db.String(150), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    marshal_id = db.Column(db.Integer, db.ForeignKey('marshal.id'), nullable=False)
    
    marshal = db.relationship('Marshal', backref='pickups')
    vehicle = db.relationship('Vehicle', backref='pickups')
