CREATE OR REPLACE VIEW renter_bookings AS
SELECT id, vehicle_id, start_date, end_date, total_price, status
FROM bookings
WHERE renter_id = current_setting('myapp.user_id')::int;
CREATE OR REPLACE VIEW renter_payments AS
SELECT id, amount, payment_date, status
FROM payments
WHERE booking_id IN (SELECT id FROM bookings WHERE renter_id = current_setting('myapp.user_id')::int);
CREATE OR REPLACE VIEW user_details AS
SELECT id AS user_id, account_name, email, role
FROM users;
CREATE OR REPLACE VIEW vehicle_details AS
SELECT id AS vehicle_id, make, model, year, price_per_day, status AS vehicle_status, description
FROM vehicles;
CREATE OR REPLACE VIEW booking_details AS
SELECT id AS booking_id, vehicle_id, renter_id, start_date, end_date, total_price, status AS booking_status
FROM bookings;
CREATE OR REPLACE VIEW payment_details AS
SELECT id AS payment_id, booking_id, amount, payment_date, status AS payment_status
FROM payments;
CREATE OR REPLACE VIEW full_user_vehicle_booking_payment AS
SELECT 
    u.id AS user_id, u.account_name, u.email, u.role,
    v.id AS vehicle_id, v.make, v.model, v.year, v.price_per_day, v.status AS vehicle_status, v.description AS vehicle_description,
    b.id AS booking_id, b.start_date, b.end_date, b.total_price, b.status AS booking_status,
    p.id AS payment_id, p.amount AS payment_amount, p.payment_date, p.status AS payment_status
FROM users u
LEFT JOIN bookings b ON u.id = b.renter_id
LEFT JOIN vehicles v ON b.vehicle_id = v.id
LEFT JOIN payments p ON b.id = p.booking_id;