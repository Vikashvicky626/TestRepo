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

-- Create trigger to automatically update updated_at
CREATE TRIGGER IF NOT EXISTS update_attendance_updated_at 
    BEFORE UPDATE ON attendance 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing (optional)
-- INSERT INTO attendance (username, date, status) VALUES 
-- ('student1', '2024-01-15', 'Present'),
-- ('student1', '2024-01-14', 'Absent'),
-- ('student1', '2024-01-13', 'Late')
-- ON CONFLICT (username, date) DO NOTHING;

-- Grant necessary permissions
-- GRANT ALL PRIVILEGES ON TABLE attendance TO user;
-- GRANT USAGE, SELECT ON SEQUENCE attendance_id_seq TO user;