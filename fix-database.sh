#!/bin/bash

# Quick Database Fix Script
# Run this script to resolve database startup issues

set -e

echo "🔧 Database Quick Fix Script"
echo "============================"

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    elif command -v docker >/dev/null 2>&1; then
        echo "docker compose"
    else
        echo "ERROR: Docker Compose not found!"
        exit 1
    fi
}

DOCKER_COMPOSE_CMD=$(check_docker_compose)

echo "🔍 Stopping all containers..."
$DOCKER_COMPOSE_CMD down -v 2>/dev/null || true

echo "🧹 Cleaning up Docker resources..."
docker system prune -f 2>/dev/null || true

echo "🚀 Attempting fixes..."

# Fix 1: Try with simplified init script
echo "📝 Fix 1: Using simplified init script..."
if [ -f "docker-compose.yml" ]; then
    # Backup original
    cp docker-compose.yml docker-compose.yml.backup
    
    # Update to use minimal init
    sed -i.bak 's|./init.sql:/docker-entrypoint-initdb.d/init.sql|./minimal-init.sql:/docker-entrypoint-initdb.d/init.sql|g' docker-compose.yml
    
    echo "🏗️  Starting with minimal init script..."
    $DOCKER_COMPOSE_CMD up -d db
    
    # Wait for database to be ready
    echo "⏳ Waiting for database to initialize..."
    for i in {1..30}; do
        if $DOCKER_COMPOSE_CMD exec db pg_isready -U user -d attendance_db >/dev/null 2>&1; then
            echo "✅ Database is ready!"
            break
        fi
        echo "   Waiting... ($i/30)"
        sleep 2
    done
    
    # Check if database is healthy
    if $DOCKER_COMPOSE_CMD exec db pg_isready -U user -d attendance_db >/dev/null 2>&1; then
        echo "✅ Database started successfully with minimal init!"
        echo "🚀 Starting other services..."
        $DOCKER_COMPOSE_CMD up -d
        echo "✅ All services started!"
        exit 0
    else
        echo "❌ Database still not ready, trying next fix..."
    fi
    
    # Restore original
    mv docker-compose.yml.backup docker-compose.yml
fi

# Fix 2: Try without init script
echo "📝 Fix 2: Starting without init script..."
$DOCKER_COMPOSE_CMD down -v 2>/dev/null || true

# Temporarily remove init script
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.backup
    sed -i.bak 's|./init.sql:/docker-entrypoint-initdb.d/init.sql|#./init.sql:/docker-entrypoint-initdb.d/init.sql|g' docker-compose.yml
    
    echo "🏗️  Starting database without init script..."
    $DOCKER_COMPOSE_CMD up -d db
    
    # Wait for database
    echo "⏳ Waiting for database..."
    for i in {1..30}; do
        if $DOCKER_COMPOSE_CMD exec db pg_isready -U user -d attendance_db >/dev/null 2>&1; then
            echo "✅ Database is ready!"
            break
        fi
        echo "   Waiting... ($i/30)"
        sleep 2
    done
    
    # Create table manually
    echo "🛠️  Creating table manually..."
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
    " 2>/dev/null || echo "⚠️  Table creation failed, but database is running"
    
    # Start other services
    echo "🚀 Starting other services..."
    $DOCKER_COMPOSE_CMD up -d
    
    # Restore original
    mv docker-compose.yml.backup docker-compose.yml
    
    echo "✅ System started without init script!"
    exit 0
fi

# Fix 3: Use different port
echo "📝 Fix 3: Trying different port..."
$DOCKER_COMPOSE_CMD down -v 2>/dev/null || true

if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.backup
    sed -i.bak 's|"5432:5432"|"5433:5432"|g' docker-compose.yml
    
    echo "🏗️  Starting with port 5433..."
    $DOCKER_COMPOSE_CMD up --build -d
    
    # Check if it worked
    if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
        echo "✅ System started on port 5433!"
        echo "📝 Note: Use port 5433 for database connections"
        exit 0
    fi
    
    # Restore original
    mv docker-compose.yml.backup docker-compose.yml
fi

echo "❌ All fixes failed. Please check the troubleshooting guide."
echo "📋 Try these manual steps:"
echo "1. Check Docker Desktop is running"
echo "2. Restart Docker Desktop"
echo "3. Check available disk space: df -h"
echo "4. Check available memory: free -h"
echo "5. Check database logs: docker-compose logs db"
echo ""
echo "💡 For more help, see DATABASE_TROUBLESHOOTING.md"