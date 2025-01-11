CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (action_type, table_name, user_name, new_data)
        VALUES ('INSERT', TG_TABLE_NAME, current_user, row_to_json(NEW));
        RETURN NEW;
    END IF;

    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (action_type, table_name, user_name, old_data, new_data)
        VALUES ('UPDATE', TG_TABLE_NAME, current_user, row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    END IF;

    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (action_type, table_name, user_name, old_data)
        VALUES ('DELETE', TG_TABLE_NAME, current_user, row_to_json(OLD));
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_trigger_users
AFTER INSERT OR UPDATE OR DELETE ON "users"
FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_trigger_vehicles
AFTER INSERT OR UPDATE OR DELETE ON "vehicles"
FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_trigger_bookings
AFTER INSERT OR UPDATE OR DELETE ON "bookings"
FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_trigger_payments
AFTER INSERT OR UPDATE OR DELETE ON "payments"
FOR EACH ROW EXECUTE FUNCTION log_audit();