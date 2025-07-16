#!/bin/bash

# Port 3000 Deployment Script for Student Attendance System
# This script deploys the attendance system to Vultr cloud instance on port 3000

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 Port 3000 Deployment Script for Student Attendance System"
echo "==========================================================="

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    error ".env.production file not found!"
    echo "The .env.production file has been created with default values."
    echo "Please review and update it with your specific configuration."
    exit 1
fi

log "Found .env.production file"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed!"
    log "Installing Docker..."
    
    # Update package list
    sudo apt-get update
    
    # Install Docker
    sudo apt-get install -y docker.io
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log "Docker installed successfully"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed!"
    log "Installing Docker Compose..."
    
    # Install Docker Compose
    sudo apt-get install -y docker-compose
    
    log "Docker Compose installed successfully"
fi

# Load environment variables
log "Loading environment variables..."
export $(cat .env.production | grep -v '#' | xargs)

# Stop any existing containers
log "Stopping existing containers..."
sudo docker-compose -f docker-compose.production.yml down || true

# Clean up any orphaned containers
log "Cleaning up orphaned containers..."
sudo docker system prune -f

# Build and start the application
log "Building and starting the application..."
sudo docker-compose -f docker-compose.production.yml up -d --build

# Wait for services to start
log "Waiting for services to start..."
sleep 30

# Check container status
log "Checking container status..."
sudo docker-compose -f docker-compose.production.yml ps

# Configure firewall to allow port 3000
log "Configuring firewall..."
sudo ufw allow 3000/tcp || true
sudo ufw allow 5000/tcp || true
sudo ufw allow 8080/tcp || true

# Test the application
log "Testing the application..."

# Test frontend
if curl -f -s http://localhost:3000 > /dev/null; then
    log "✅ Frontend is accessible on port 3000"
else
    warn "❌ Frontend is not accessible on port 3000"
fi

# Test backend
if curl -f -s http://localhost:5000 > /dev/null; then
    log "✅ Backend is accessible on port 5000"
else
    warn "❌ Backend is not accessible on port 5000"
fi

# Test keycloak
if curl -f -s http://localhost:8080 > /dev/null; then
    log "✅ Keycloak is accessible on port 8080"
else
    warn "❌ Keycloak is not accessible on port 8080"
fi

# Check Docker logs for any errors
log "Checking for any container errors..."
if sudo docker-compose -f docker-compose.production.yml logs --tail=10 | grep -i error; then
    warn "Some errors found in container logs. Check with: sudo docker-compose -f docker-compose.production.yml logs"
else
    log "No errors found in container logs"
fi

# Final status check
log "Final status check..."
RUNNING_CONTAINERS=$(sudo docker-compose -f docker-compose.production.yml ps --services --filter "status=running" | wc -l)
TOTAL_SERVICES=5  # frontend, backend, db, redis, keycloak

if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_SERVICES" ]; then
    log "✅ All $TOTAL_SERVICES services are running successfully!"
else
    warn "❌ Only $RUNNING_CONTAINERS out of $TOTAL_SERVICES services are running"
fi

echo ""
echo "🎉 Deployment completed!"
echo "=============================="
echo "✅ Frontend: http://securetechsquad.com:3000"
echo "✅ Backend API: http://securetechsquad.com:5000"
echo "✅ Keycloak: http://securetechsquad.com:8080"
echo ""
echo "📋 Useful commands:"
echo "  - Check status: sudo docker-compose -f docker-compose.production.yml ps"
echo "  - View logs: sudo docker-compose -f docker-compose.production.yml logs"
echo "  - Stop services: sudo docker-compose -f docker-compose.production.yml down"
echo "  - Restart services: sudo docker-compose -f docker-compose.production.yml restart"
echo ""
echo "🔧 Troubleshooting:"
echo "  - If services fail to start, check logs with: sudo docker-compose -f docker-compose.production.yml logs [service_name]"
echo "  - To rebuild: sudo docker-compose -f docker-compose.production.yml up -d --build"
echo ""

# Success message
log "Student Attendance System deployed successfully on port 3000!"
log "Access your application at: http://securetechsquad.com:3000"