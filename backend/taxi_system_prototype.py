import datetime

# Prototype Taxi Management System
# Simulates core features: Marshal login, pickup recording, daily limits, and summaries

class TaxiSystem:
    def __init__(self):
        self.marshals = {
            "marshal1": {"name": "John Doe", "route": "Cape Town"},
            "marshal2": {"name": "Jane Smith", "route": "Durban"}
        }
        self.vehicles = {
            "CA123WP": {"owner": "Mr. X", "route": "Cape Town", "capacity": 15, "loads_today": 0},
            "DB456WP": {"owner": "Mr. Y", "route": "Durban", "capacity": 16, "loads_today": 0}
        }
        self.daily_limit = 8
        self.pickups = []  # List of pickup records
        self.logged_in_marshal = None

    def login(self, marshal_id):
        if marshal_id in self.marshals:
            self.logged_in_marshal = marshal_id
            print(f"Logged in as {self.marshals[marshal_id]['name']} for route {self.marshals[marshal_id]['route']}")
            return True
        else:
            print("Invalid marshal ID")
            return False

    def record_pickup(self, number_plate, rank):
        if not self.logged_in_marshal:
            print("Please login first")
            return

        if number_plate not in self.vehicles:
            print("Vehicle not registered")
            return

        vehicle = self.vehicles[number_plate]
        marshal_route = self.marshals[self.logged_in_marshal]['route']

        if vehicle['route'] != marshal_route:
            print("Vehicle not in your route")
            return

        if vehicle['loads_today'] >= self.daily_limit:
            print(f"Vehicle has reached daily limit of {self.daily_limit} loads")
            return

        timestamp = datetime.datetime.now()
        pickup = {
            "number_plate": number_plate,
            "rank": rank,
            "route": vehicle['route'],
            "timestamp": timestamp.isoformat(),
            "marshal": self.logged_in_marshal
        }
        self.pickups.append(pickup)
        vehicle['loads_today'] += 1
        print(f"Pickup recorded: {number_plate} at {rank} on {timestamp}")

    def view_daily_summary(self):
        if not self.logged_in_marshal:
            print("Please login first")
            return

        route = self.marshals[self.logged_in_marshal]['route']
        route_pickups = [p for p in self.pickups if p['route'] == route]
        print(f"Daily Summary for {route} route:")
        for pickup in route_pickups:
            print(f"- {pickup['number_plate']} at {pickup['rank']} at {pickup['timestamp']}")

        total_loads = sum(v['loads_today'] for v in self.vehicles.values() if v['route'] == route)
        print(f"Total loads today: {total_loads}")

    def logout(self):
        self.logged_in_marshal = None
        print("Logged out")

# Main function for CLI
def main():
    system = TaxiSystem()
    while True:
        if not system.logged_in_marshal:
            command = input("Enter command (login <id>, exit): ").strip()
            if command.startswith("login "):
                marshal_id = command.split()[1]
                system.login(marshal_id)
            elif command == "exit":
                break
            else:
                print("Invalid command")
        else:
            command = input("Enter command (record <plate> <rank>, summary, logout, exit): ").strip()
            if command.startswith("record "):
                parts = command.split()
                if len(parts) == 3:
                    plate, rank = parts[1], parts[2]
                    system.record_pickup(plate, rank)
                else:
                    print("Usage: record <plate> <rank>")
            elif command == "summary":
                system.view_daily_summary()
            elif command == "logout":
                system.logout()
            elif command == "exit":
                break
            else:
                print("Invalid command")

if __name__ == "__main__":
    main()
