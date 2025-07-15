-- Database initialization script for attendance system
-- This script creates the necessary tables and indexes

-- Create attendance table
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(username, date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_username ON attendance(username);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_created_at ON attendance(created_at);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at using DO block for safety
DO $$
BEGIN
    -- Drop trigger if it exists
    DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;
    
    -- Create the trigger
    CREATE TRIGGER update_attendance_updated_at 
        BEFORE UPDATE ON attendance 
        FOR EACH ROW 
        EXECUTE FUNCTION update_updated_at_column();
        
    RAISE NOTICE 'Trigger update_attendance_updated_at created successfully';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error creating trigger: %', SQLERRM;
END;
$$;

-- Verify table creation
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance') THEN
        RAISE NOTICE 'Table attendance created successfully';
    ELSE
        RAISE WARNING 'Table attendance was not created';
    END IF;
END;
$$;

-- Insert some sample data for testing (optional - uncomment if needed)
/*
INSERT INTO attendance (username, date, status) VALUES 
('student1', '2024-01-15', 'Present'),
('student1', '2024-01-14', 'Absent'),
('student1', '2024-01-13', 'Late')
ON CONFLICT (username, date) DO NOTHING;
*/

-- Grant necessary permissions (uncomment if needed)
/*
GRANT ALL PRIVILEGES ON TABLE attendance TO user;
GRANT USAGE, SELECT ON SEQUENCE attendance_id_seq TO user;
*/