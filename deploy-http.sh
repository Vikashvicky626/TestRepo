#!/bin/bash

# HTTP Deployment Script for Student Attendance System
# This script deploys the attendance system to Vultr cloud instance on port 80

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

echo "🚀 HTTP Deployment Script for Student Attendance System"
echo "======================================================"

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    error ".env.production file not found!"
    echo "The .env.production file has been created with default values."
    echo "Please review and update it with your specific configuration if needed."
    exit 1
fi

# Load environment variables
set -a
source .env.production
set +a

# Verify required variables
if [ -z "$DOMAIN_NAME" ]; then
    error "DOMAIN_NAME is not set in .env.production"
    exit 1
fi

log "Deploying to domain: $DOMAIN_NAME"

# Update system packages
log "Updating system packages..."
sudo apt-get update -y

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    log "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create necessary directories
log "Creating necessary directories..."
mkdir -p ssl nginx/logs db-backups

# Stop any existing containers
log "Stopping existing containers..."
docker-compose -f docker-compose.production.yml down || true

# Remove old images (optional, saves disk space)
log "Cleaning up old Docker images..."
docker system prune -f || true

# Create nginx configuration with actual domain
log "Creating nginx configuration..."
envsubst '$DOMAIN_NAME' < nginx/default.conf > nginx/default.conf.tmp
mv nginx/default.conf.tmp nginx/default.conf

# Configure firewall for HTTP
log "Configuring firewall..."
sudo ufw --force enable || true
sudo ufw allow ssh || true
sudo ufw allow 80 || true
sudo ufw allow 443 || true
sudo ufw --force reload || true

# Build and start containers
log "Building and starting containers..."
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d

# Wait for services to be ready
log "Waiting for services to start..."
sleep 30

# Check service health
log "Checking service health..."
for i in {1..10}; do
    if curl -f http://localhost/health >/dev/null 2>&1; then
        log "✅ Application is healthy and running on port 80"
        break
    fi
    if [ $i -eq 10 ]; then
        warn "Health check failed, but services may still be starting"
    fi
    sleep 5
done

# Display container status
log "Container status:"
docker-compose -f docker-compose.production.yml ps

# Show final information
echo ""
echo "🎉 Deployment completed!"
echo "======================================================"
echo "✅ Application URL: http://$DOMAIN_NAME"
echo "✅ API URL: http://$DOMAIN_NAME/api"
echo "✅ Keycloak URL: http://$DOMAIN_NAME/auth"
echo ""
echo "📊 Default Login Credentials:"
echo "   Admin: admin / admin123"
echo "   Teacher: teacher / teacher123"
echo "   Student: student1 / student123"
echo ""
echo "🔧 Management Commands:"
echo "   View logs: docker-compose -f docker-compose.production.yml logs -f"
echo "   Restart: docker-compose -f docker-compose.production.yml restart"
echo "   Stop: docker-compose -f docker-compose.production.yml down"
echo ""
echo "📝 Next steps:"
echo "1. Test the application at http://$DOMAIN_NAME"
echo "2. Configure your DNS to point to this server"
echo "3. Set up SSL certificates for HTTPS (optional)"
echo "4. Configure backups and monitoring"
echo ""

log "Deployment completed successfully!"