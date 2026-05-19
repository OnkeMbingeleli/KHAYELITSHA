BEGIN TRANSACTION;

INSERT INTO branches (code, name, description)
VALUES ('KWT', 'Kuwait Branch', 'Pilot branch for the local taxi association system');

INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'A', 'Rank A', 'pickup' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'B', 'Rank B', 'pickup' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'C', 'Rank C', 'pickup' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'D', 'Rank D', 'pickup' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'E', 'Rank E', 'pickup' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'F', 'Rank F', 'pickup' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'TOWN', 'Town Main Rank', 'town' FROM branches WHERE code = 'KWT';
INSERT INTO ranks (branch_id, code, name, rank_type)
SELECT id, 'RETURN', 'Return Point', 'return_point' FROM branches WHERE code = 'KWT';

INSERT INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'CTN', 'Cape Town', 'Township to Cape Town', 8 FROM branches WHERE code = 'KWT';
INSERT INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'CLR', 'Claremont', 'Township to Claremont', 8 FROM branches WHERE code = 'KWT';
INSERT INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'WYN', 'Wynberg', 'Township to Wynberg', 8 FROM branches WHERE code = 'KWT';
INSERT INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'FSH', 'Fish Hoek', 'Township to Fish Hoek', 8 FROM branches WHERE code = 'KWT';
INSERT INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'SEA', 'Sea Point', 'Township to Sea Point', 8 FROM branches WHERE code = 'KWT';
INSERT INTO routes (branch_id, route_code, route_name, direction_label, daily_load_limit)
SELECT id, 'DBN', 'Durban', 'Township to Durban', 8 FROM branches WHERE code = 'KWT';

INSERT INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'pickup', 1
FROM routes r
CROSS JOIN ranks k
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN')
  AND k.code IN ('A', 'B', 'C', 'D', 'E', 'F');

INSERT INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'town', 2
FROM routes r
JOIN ranks k ON k.code = 'TOWN'
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN');

INSERT INTO route_rank_assignments (route_id, rank_id, assignment_type, sequence_no)
SELECT r.id, k.id, 'return_point', 3
FROM routes r
JOIN ranks k ON k.code = 'RETURN'
WHERE r.route_code IN ('CTN', 'CLR', 'WYN', 'FSH', 'SEA', 'DBN');

INSERT INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'superadmin1', 'CHANGE_ME', 'super_admin', 'Onke', 'Admin', '8001010000001', '0710000001', 'admin1@example.com', id
FROM branches WHERE code = 'KWT';
INSERT INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'superadmin2', 'CHANGE_ME', 'super_admin', 'Backup', 'Admin', '8001010000002', '0710000002', 'admin2@example.com', id
FROM branches WHERE code = 'KWT';
INSERT INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'marshal_ctn_1', 'CHANGE_ME', 'marshal', 'Sipho', 'Mahlangu', '9001010000001', '0721111111', 'sipho@example.com', id
FROM branches WHERE code = 'KWT';
INSERT INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'marshal_clr_1', 'CHANGE_ME', 'marshal', 'Zanele', 'Dlamini', '9001010000002', '0722222222', 'zanele@example.com', id
FROM branches WHERE code = 'KWT';
INSERT INTO users (username, password_hash, role, first_name, last_name, id_number, phone, email, branch_id)
SELECT 'patrol_1', 'CHANGE_ME', 'patroller', 'Thabo', 'Nene', '9001010000003', '0723333333', 'thabo@example.com', id
FROM branches WHERE code = 'KWT';

INSERT INTO user_route_assignments (user_id, route_id, is_primary)
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'CTN'
WHERE u.username = 'marshal_ctn_1';

INSERT INTO user_route_assignments (user_id, route_id, is_primary)
SELECT u.id, r.id, 1
FROM users u
JOIN routes r ON r.route_code = 'CLR'
WHERE u.username = 'marshal_clr_1';

INSERT INTO owners (branch_id, owner_code, first_name, last_name, date_of_birth, id_number, phone, email)
SELECT id, 'OWN-KWT-001', 'Mandla', 'Nkosi', '1980-01-01', '8001015009087', '0731111111', 'mandla@example.com'
FROM branches WHERE code = 'KWT';
INSERT INTO owners (branch_id, owner_code, first_name, last_name, date_of_birth, id_number, phone, email)
SELECT id, 'OWN-KWT-002', 'Ayanda', 'Khumalo', '1983-05-12', '8305125009087', '0732222222', 'ayanda@example.com'
FROM branches WHERE code = 'KWT';

INSERT INTO owner_route_memberships (owner_id, route_id, is_active)
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'CTN'
WHERE o.owner_code = 'OWN-KWT-001';

INSERT INTO owner_route_memberships (owner_id, route_id, is_active)
SELECT o.id, r.id, 1
FROM owners o
JOIN routes r ON r.route_code = 'CLR'
WHERE o.owner_code = 'OWN-KWT-002';

INSERT INTO vehicles (owner_id, route_id, branch_id, number_plate, make, model, seat_capacity, qr_code_value, qr_sticker_label, office_label, status)
SELECT o.id, r.id, b.id, 'CA123WP', 'Toyota', 'Hiace', 15, 'QR-KWT-CA123WP', 'CODETA|CTN|CA123WP|OWN-KWT-001|15', 'Kuwait Branch', 'active'
FROM owners o
JOIN routes r ON r.route_code = 'CTN'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-001';

INSERT INTO vehicles (owner_id, route_id, branch_id, number_plate, make, model, seat_capacity, qr_code_value, qr_sticker_label, office_label, status)
SELECT o.id, r.id, b.id, 'CA456WP', 'Toyota', 'Quantum', 16, 'QR-KWT-CA456WP', 'CODETA|CTN|CA456WP|OWN-KWT-001|16', 'Kuwait Branch', 'active'
FROM owners o
JOIN routes r ON r.route_code = 'CTN'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-001';

INSERT INTO vehicles (owner_id, route_id, branch_id, number_plate, make, model, seat_capacity, qr_code_value, qr_sticker_label, office_label, status)
SELECT o.id, r.id, b.id, 'CY789WP', 'Nissan', 'Impilo', 15, 'QR-KWT-CY789WP', 'CODETA|CLR|CY789WP|OWN-KWT-002|15', 'Kuwait Branch', 'active'
FROM owners o
JOIN routes r ON r.route_code = 'CLR'
JOIN branches b ON b.code = 'KWT'
WHERE o.owner_code = 'OWN-KWT-002';

COMMIT;
