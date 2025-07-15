#!/bin/bash

# Manual Database Setup Script
# Run this after starting docker-compose-no-init.yml

echo "🔧 Manual Database Setup"
echo "========================"

echo "⏳ Waiting for database to be ready..."
sleep 5

echo "🏗️  Creating attendance table..."

# Check if docker-compose is available
if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose not found! Please use Docker Desktop GUI."
    echo "📋 Manual steps:"
    echo "1. Open Docker Desktop"
    echo "2. Go to Containers tab"
    echo "3. Click on testrepo-db-1 container"
    echo "4. Click 'Exec' tab"
    echo "5. Run: psql -U user -d attendance_db"
    echo "6. Run this SQL:"
    echo "   CREATE TABLE IF NOT EXISTS attendance ("
    echo "       id SERIAL PRIMARY KEY,"
    echo "       username VARCHAR(255) NOT NULL,"
    echo "       date DATE NOT NULL,"
    echo "       status VARCHAR(50) NOT NULL,"
    echo "       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
    echo "       UNIQUE(username, date)"
    echo "   );"
    exit 1
fi

# Create the table
$DOCKER_COMPOSE_CMD exec db psql -U user -d attendance_db -c "
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(username, date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_username ON attendance(username);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Database table created successfully!"
    echo "🎯 Your attendance system is now ready to use!"
    echo "📍 Access at: http://localhost:3000"
else
    echo "❌ Failed to create table. Please check if database is running."
    echo "💡 Try: $DOCKER_COMPOSE_CMD ps"
fi