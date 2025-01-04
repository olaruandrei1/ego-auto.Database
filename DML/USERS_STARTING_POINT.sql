INSERT INTO users (account_name, email, password, role)
VALUES 
    ('AdminUser', 'admin@example.com', crypt('adminpassword', gen_salt('bf')), 'Admin'),
    ('RenterUser', 'renter@example.com', crypt('renterpassword', gen_salt('bf')), 'Renter'),
    ('SupportUser', 'support@example.com', crypt('supportpassword', gen_salt('bf')), 'Support'),
    ('GuestUser', 'guest@example.com', crypt('guestpassword', gen_salt('bf')), 'Guest'),
	('AdminUser1', 'admin1@example.com', crypt('adminpassword1', gen_salt('bf')), 'Admin'),
    ('AdminUser2', 'admin2@example.com', crypt('adminpassword2', gen_salt('bf')), 'Admin');

DO $$ 
DECLARE
    user_record RECORD; 
BEGIN
    FOR user_record IN SELECT account_name, role FROM users LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = user_record.account_name) THEN
            EXECUTE format('CREATE ROLE "%s";', user_record.account_name);
        END IF;

        IF user_record.role = 'Admin' THEN
            EXECUTE format('GRANT admin_role TO "%s";', user_record.account_name);
        ELSIF user_record.role = 'Renter' THEN
            EXECUTE format('GRANT renter_role TO "%s";', user_record.account_name);
        ELSIF user_record.role = 'Support' THEN
            EXECUTE format('GRANT support_role TO "%s";', user_record.account_name);
        ELSIF user_record.role = 'Guest' THEN
            EXECUTE format('GRANT guest_role TO "%s";', user_record.account_name);
        END IF;
    END LOOP;
END $$;