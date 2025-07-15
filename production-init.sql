-- Production Database initialization script
-- Security-focused setup for attendance system

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create attendance table with enhanced security
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Present', 'Absent', 'Late')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    UNIQUE(username, date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_username ON attendance(username);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_created_at ON attendance(created_at);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);

-- Create audit log table
CREATE TABLE IF NOT EXISTS attendance_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    user_id VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_attendance_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO attendance_audit (table_name, operation, old_values, user_id, ip_address)
        VALUES ('attendance', 'DELETE', row_to_json(OLD), OLD.username, OLD.ip_address);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO attendance_audit (table_name, operation, old_values, new_values, user_id, ip_address)
        VALUES ('attendance', 'UPDATE', row_to_json(OLD), row_to_json(NEW), NEW.username, NEW.ip_address);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO attendance_audit (table_name, operation, new_values, user_id, ip_address)
        VALUES ('attendance', 'INSERT', row_to_json(NEW), NEW.username, NEW.ip_address);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create audit trigger
DROP TRIGGER IF EXISTS attendance_audit_trigger ON attendance;
CREATE TRIGGER attendance_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON attendance
    FOR EACH ROW EXECUTE FUNCTION audit_attendance_changes();

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;
CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create sessions table for session management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create session indexes
CREATE INDEX IF NOT EXISTS idx_sessions_username ON user_sessions(username);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON user_sessions(expires_at);

-- Create function to clean expired sessions
CREATE OR REPLACE FUNCTION clean_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_sessions WHERE expires_at < CURRENT_TIMESTAMP;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create rate limiting table
CREATE TABLE IF NOT EXISTS rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    count INTEGER DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    UNIQUE(identifier, action)
);

-- Create rate limiting indexes
CREATE INDEX IF NOT EXISTS idx_rate_limits_identifier ON rate_limits(identifier);
CREATE INDEX IF NOT EXISTS idx_rate_limits_expires ON rate_limits(expires_at);

-- Create security settings table
CREATE TABLE IF NOT EXISTS security_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_name VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert default security settings
INSERT INTO security_settings (setting_name, setting_value, description) VALUES
('max_login_attempts', '5', 'Maximum login attempts before lockout'),
('lockout_duration', '900', 'Lockout duration in seconds (15 minutes)'),
('session_timeout', '3600', 'Session timeout in seconds (1 hour)'),
('password_min_length', '8', 'Minimum password length'),
('require_https', 'true', 'Require HTTPS for all requests')
ON CONFLICT (setting_name) DO NOTHING;

-- Create database statistics view
CREATE OR REPLACE VIEW attendance_statistics AS
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT username) as unique_users,
    COUNT(*) FILTER (WHERE status = 'Present') as present_count,
    COUNT(*) FILTER (WHERE status = 'Absent') as absent_count,
    COUNT(*) FILTER (WHERE status = 'Late') as late_count,
    DATE_TRUNC('month', created_at) as month
FROM attendance
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- Set up row level security (RLS) for attendance table
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Create policy for users to only see their own records
CREATE POLICY attendance_user_policy ON attendance
    FOR ALL
    TO PUBLIC
    USING (username = current_user);

-- Create backup function
CREATE OR REPLACE FUNCTION create_backup()
RETURNS TEXT AS $$
DECLARE
    backup_file TEXT;
BEGIN
    backup_file := '/backups/attendance_backup_' || to_char(now(), 'YYYY_MM_DD_HH24_MI_SS') || '.sql';
    EXECUTE format('COPY (SELECT * FROM attendance) TO %L WITH CSV HEADER', backup_file);
    RETURN backup_file;
END;
$$ LANGUAGE plpgsql;

-- Grant appropriate permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON attendance TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON attendance_audit TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_sessions TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON rate_limits TO PUBLIC;
GRANT SELECT, UPDATE ON security_settings TO PUBLIC;
GRANT SELECT ON attendance_statistics TO PUBLIC;

-- Create maintenance function to be run periodically
CREATE OR REPLACE FUNCTION maintenance_tasks()
RETURNS TEXT AS $$
DECLARE
    result TEXT := '';
    cleaned_sessions INTEGER;
    cleaned_rate_limits INTEGER;
BEGIN
    -- Clean expired sessions
    SELECT clean_expired_sessions() INTO cleaned_sessions;
    result := result || 'Cleaned ' || cleaned_sessions || ' expired sessions. ';
    
    -- Clean expired rate limits
    DELETE FROM rate_limits WHERE expires_at < CURRENT_TIMESTAMP;
    GET DIAGNOSTICS cleaned_rate_limits = ROW_COUNT;
    result := result || 'Cleaned ' || cleaned_rate_limits || ' expired rate limits. ';
    
    -- Update statistics
    ANALYZE attendance;
    ANALYZE attendance_audit;
    result := result || 'Updated table statistics.';
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Log initialization completion
INSERT INTO attendance_audit (table_name, operation, new_values, user_id) 
VALUES ('system', 'INIT', '{"message": "Database initialized successfully"}', 'system');

-- End of production initialization script