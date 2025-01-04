GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;

GRANT SELECT ON vehicles TO renter_role;
GRANT SELECT, INSERT, UPDATE ON bookings TO renter_role;
GRANT SELECT ON payments TO renter_role;

GRANT SELECT ON bookings TO support_role;
GRANT SELECT ON payments TO support_role;
GRANT UPDATE ON bookings TO support_role;

GRANT SELECT ON vehicles TO guest_role;