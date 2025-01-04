CREATE OR REPLACE PROCEDURE upsert_user(
    p_account_name VARCHAR,
    p_email VARCHAR,
    p_password TEXT,
    p_role VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO users AS target
    USING (SELECT p_email AS email, p_account_name AS account_name, crypt(p_password, gen_salt('bf')) AS password, p_role AS role) AS source
    ON target.email = source.email
    WHEN MATCHED THEN
        UPDATE SET account_name = source.account_name, password = source.password
    WHEN NOT MATCHED THEN
        INSERT (account_name, email, password, role) 
        VALUES (source.account_name, source.email, source.password, source.role);
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_account_name) THEN
        EXECUTE format('CREATE ROLE "%s";', p_account_name);
    END IF;

    IF p_role = 'Admin' THEN
        EXECUTE format('GRANT admin_role TO "%s";', p_account_name);
    ELSIF p_role = 'Renter' THEN
        EXECUTE format('GRANT renter_role TO "%s";', p_account_name);
    ELSIF p_role = 'Support' THEN
        EXECUTE format('GRANT support_role TO "%s";', p_account_name);
    ELSIF p_role = 'Guest' THEN
        EXECUTE format('GRANT guest_role TO "%s";', p_account_name);
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE upsert_booking(
    p_vehicle_id INT,
    p_renter_id INT,
    p_start_date DATE,
    p_end_date DATE,
    p_total_price DECIMAL(10, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_start_date >= p_end_date THEN
        RAISE EXCEPTION 'Data de inceput trebuie sa fie mai mica decat data de final.';
    END IF;

    MERGE INTO bookings AS target
    USING (SELECT p_vehicle_id AS vehicle_id, p_renter_id AS renter_id, p_start_date AS start_date, p_end_date AS end_date, p_total_price AS total_price, 'Pending' AS status) AS source
    ON target.vehicle_id = source.vehicle_id AND target.renter_id = source.renter_id AND target.start_date = source.start_date
    WHEN MATCHED THEN
        UPDATE SET end_date = source.end_date, total_price = source.total_price
    WHEN NOT MATCHED THEN
        INSERT (vehicle_id, renter_id, start_date, end_date, total_price, status)
        VALUES (source.vehicle_id, source.renter_id, source.start_date, source.end_date, source.total_price, source.status);
END;
$$;

CREATE OR REPLACE PROCEDURE process_payment(
    p_booking_id INT,
    p_amount DECIMAL(10, 2),
    p_payment_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO payments AS target
    USING (SELECT p_booking_id AS booking_id, p_amount AS amount, CURRENT_DATE AS payment_date, p_payment_status AS status) AS source
    ON target.booking_id = source.booking_id AND target.payment_date = source.payment_date
    WHEN MATCHED THEN
        UPDATE SET amount = source.amount, status = source.status
    WHEN NOT MATCHED THEN
        INSERT (booking_id, amount, payment_date, status)
        VALUES (source.booking_id, source.amount, source.payment_date, source.status);
END;
$$;

CREATE OR REPLACE PROCEDURE upsert_vehicle(
    p_vehicle_id INT,
    p_make VARCHAR,
    p_model VARCHAR,
    p_year INT,
    p_price_per_day DECIMAL(10, 2),
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM vehicles WHERE id = p_vehicle_id) THEN
        IF NOT EXISTS (SELECT 1 FROM vehicles WHERE id = p_vehicle_id AND status = 'Available') THEN
            RAISE EXCEPTION 'Vehiculul trebuie să fie în statusul "Available" pentru a putea fi actualizat.';
        END IF;
    END IF;

    MERGE INTO vehicles v
    USING (SELECT p_vehicle_id AS id) AS source
    ON v.id = source.id
    WHEN MATCHED THEN
        UPDATE SET 
            make = p_make, 
            model = p_model, 
            year = p_year, 
            price_per_day = p_price_per_day, 
            description = p_description
    WHEN NOT MATCHED THEN
        INSERT (id, make, model, year, price_per_day, status, description) 
        VALUES (p_vehicle_id, p_make, p_model, p_year, p_price_per_day, 'Available', p_description);
END;
$$;

CREATE OR REPLACE PROCEDURE delete_user(
    p_email VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RAISE EXCEPTION 'Nu exista utilizator cu acest email: %', p_email;
    END IF;

    EXECUTE format('REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "%s";', p_email);

    DELETE FROM users WHERE email = p_email;
END;
$$;

CREATE OR REPLACE PROCEDURE setup_row_level_security()
LANGUAGE plpgsql
AS $$
BEGIN
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
    ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
    ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
    ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

    CREATE POLICY user_view_policy
    ON users
    FOR SELECT
    USING (current_setting('myapp.role') = 'Admin' OR id = current_setting('myapp.user_id')::int);

    CREATE POLICY user_update_policy
    ON users
    FOR UPDATE
    USING (current_setting('myapp.role') = 'Admin' OR id = current_setting('myapp.user_id')::int);

    CREATE POLICY vehicle_view_policy
    ON vehicles
    FOR SELECT
    USING (current_setting('myapp.role') IN ('Admin', 'Support', 'Renter', 'Guest'));

    CREATE POLICY booking_view_policy
    ON bookings
    FOR SELECT
    USING (renter_id = current_setting('myapp.user_id')::int OR current_setting('myapp.role') IN ('Admin', 'Support'));

    CREATE POLICY booking_update_policy
    ON bookings
    FOR UPDATE
    USING (renter_id = current_setting('myapp.user_id')::int OR current_setting('myapp.role') IN ('Admin', 'Support'));

    CREATE POLICY payment_view_policy
    ON payments
    FOR SELECT
    USING (booking_id IN (SELECT id FROM bookings WHERE renter_id = current_setting('myapp.user_id')::int)
           OR current_setting('myapp.role') IN ('Admin', 'Support'));
END;
$$;