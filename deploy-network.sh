#!/bin/bash

# Network Deployment Script for Student Attendance System
# This script deploys the attendance system with network accessibility

set -e

echo "🚀 Deploying Student Attendance System for Network Access"
echo "========================================================="

# Function to get the host IP address
get_host_ip() {
    # Try different methods to get the host IP
    if command -v hostname >/dev/null 2>&1; then
        # Try hostname -I first (Linux)
        HOST_IP=$(hostname -I | awk '{print $1}' 2>/dev/null)
    fi
    
    # If that doesn't work, try ip route (Linux)
    if [ -z "$HOST_IP" ]; then
        HOST_IP=$(ip route get 1 | awk '{print $7}' 2>/dev/null | head -1)
    fi
    
    # If still empty, try ifconfig (macOS/Linux)
    if [ -z "$HOST_IP" ]; then
        HOST_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
    fi
    
    # If still empty, try a different approach
    if [ -z "$HOST_IP" ]; then
        HOST_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    fi
    
    # Final fallback
    if [ -z "$HOST_IP" ]; then
        HOST_IP="localhost"
        echo "⚠️  Could not detect host IP automatically. Using localhost."
        echo "   You may need to manually set HOST_IP environment variable."
    fi
    
    echo "$HOST_IP"
}

# Get the host IP
HOST_IP=$(get_host_ip)

echo "🔍 Detected Host IP: $HOST_IP"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker or Docker Compose not found!"
    echo "   Please install Docker and Docker Compose first."
    exit 1
fi

# Determine docker-compose command
if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose not found!"
    exit 1
fi

# Stop existing services if running
echo "🛑 Stopping existing services..."
$DOCKER_COMPOSE_CMD -f docker-compose.yml down -v 2>/dev/null || true
$DOCKER_COMPOSE_CMD -f docker-compose.network.yml down -v 2>/dev/null || true

# Set environment variable and start services
echo "🏗️  Building and starting services..."
export HOST_IP=$HOST_IP
$DOCKER_COMPOSE_CMD -f docker-compose.network.yml up --build -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check service status
echo "📊 Checking service status..."
$DOCKER_COMPOSE_CMD -f docker-compose.network.yml ps

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo ""
echo "📍 Access your attendance system at:"
echo "   🌐 Frontend: http://$HOST_IP:3000"
echo "   🔧 Backend API: http://$HOST_IP:5000"
echo "   🔐 Keycloak Admin: http://$HOST_IP:8080 (admin/admin)"
echo ""
echo "👥 Student Login Credentials:"
echo "   Username: student1"
echo "   Password: student123"
echo ""
echo "🔗 Share this URL with students:"
echo "   http://$HOST_IP:3000"
echo ""
echo "🧪 To test the system:"
echo "   python3 test_system.py"
echo ""
echo "📋 To check logs:"
echo "   $DOCKER_COMPOSE_CMD -f docker-compose.network.yml logs -f"
echo ""
echo "🛑 To stop services:"
echo "   $DOCKER_COMPOSE_CMD -f docker-compose.network.yml down"
echo ""

# Run a quick health check
echo "🔍 Running health check..."
sleep 10

# Check if services are responding
if curl -s "http://$HOST_IP:5000/health" >/dev/null 2>&1; then
    echo "✅ Backend is responding"
else
    echo "⚠️  Backend health check failed - may still be starting up"
fi

if curl -s "http://$HOST_IP:3000" >/dev/null 2>&1; then
    echo "✅ Frontend is responding"
else
    echo "⚠️  Frontend health check failed - may still be starting up"
fi

echo ""
echo "🎯 System is ready for network access!"
echo "   Students can now access the system from other devices on the network."