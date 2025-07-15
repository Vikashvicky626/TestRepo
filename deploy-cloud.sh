#!/bin/bash

# Cloud Deployment Script for Student Attendance System
# This script deploys the attendance system to a cloud VM with SSL and security

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
   exit 1
fi

echo "🚀 Cloud Deployment Script for Student Attendance System"
echo "=========================================================="

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    error ".env.production file not found!"
    echo "Please create .env.production with your configuration:"
    echo "cp .env.production.example .env.production"
    echo "Then edit .env.production with your actual values"
    exit 1
fi

# Load environment variables
set -a
source .env.production
set +a

# Validate required environment variables
required_vars=("DOMAIN_NAME" "DB_PASSWORD" "JWT_SECRET_KEY" "KEYCLOAK_ADMIN_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        error "Required environment variable $var is not set"
        exit 1
    fi
done

log "Domain: $DOMAIN_NAME"
log "Environment: $ENVIRONMENT"

# Update system packages
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    log "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create necessary directories
log "Creating directories..."
sudo mkdir -p /etc/letsencrypt
sudo mkdir -p ./ssl
sudo mkdir -p ./nginx/logs
sudo mkdir -p ./db-backups
sudo mkdir -p ./logs

# Set proper permissions
sudo chown -R $USER:$USER ./ssl ./nginx/logs ./db-backups ./logs

# Install Certbot for SSL certificates
if ! command -v certbot &> /dev/null; then
    log "Installing Certbot..."
    sudo apt install -y certbot python3-certbot-nginx
fi

# Generate SSL certificates
log "Generating SSL certificates for $DOMAIN_NAME..."
if [ "$SSL_PROVIDER" = "letsencrypt" ]; then
    # Stop any existing nginx to free up port 80
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Generate certificate
    sudo certbot certonly --standalone \
        --email $SSL_EMAIL \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN_NAME \
        -d www.$DOMAIN_NAME || {
        warn "Failed to generate SSL certificate. Creating self-signed certificate..."
        
        # Create self-signed certificate as fallback
        sudo openssl req -x509 -nodes -days 365 \
            -newkey rsa:2048 \
            -keyout ./ssl/key.pem \
            -out ./ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME"
    }
    
    # Copy certificates to ssl directory
    if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
        sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem ./ssl/cert.pem
        sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem ./ssl/key.pem
        sudo chown $USER:$USER ./ssl/cert.pem ./ssl/key.pem
    fi
else
    warn "Using self-signed certificates (not recommended for production)"
    # Create self-signed certificate
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout ./ssl/key.pem \
        -out ./ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME"
fi

# Configure firewall
log "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force reload

# Generate secure random keys if not provided
if [ "$JWT_SECRET_KEY" = "your_jwt_secret_key_here_make_it_long_and_random" ]; then
    log "Generating secure JWT secret key..."
    JWT_SECRET_KEY=$(openssl rand -base64 64)
    sed -i "s/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$JWT_SECRET_KEY/" .env.production
fi

# Create nginx configuration with actual domain
log "Creating nginx configuration..."
envsubst '$DOMAIN_NAME' < nginx/default.conf > nginx/default.conf.tmp
mv nginx/default.conf.tmp nginx/default.conf

# Update production requirements
log "Updating production requirements..."
echo "gunicorn==21.2.0" >> backend/requirements.txt

# Create production keycloak realm configuration
log "Creating production Keycloak realm..."
mkdir -p keycloak
cat > keycloak/production-realm.json << EOF
{
  "realm": "school",
  "enabled": true,
  "sslRequired": "external",
  "clients": [
    {
      "clientId": "frontend",
      "publicClient": true,
      "redirectUris": [
        "https://$DOMAIN_NAME/*",
        "https://www.$DOMAIN_NAME/*"
      ],
      "webOrigins": [
        "https://$DOMAIN_NAME",
        "https://www.$DOMAIN_NAME"
      ],
      "standardFlowEnabled": true,
      "frontchannelLogout": true
    }
  ],
  "users": [
    {
      "username": "student1",
      "enabled": true,
      "credentials": [
        {
          "type": "password",
          "value": "student123"
        }
      ]
    }
  ],
  "roles": {
    "realm": [
      {
        "name": "student",
        "description": "Student role"
      },
      {
        "name": "teacher",
        "description": "Teacher role"
      }
    ]
  }
}
EOF

# Create frontend nginx configuration
log "Creating frontend nginx configuration..."
cat > frontend/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 3000;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # Gzip compression
        gzip on;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

        location / {
            try_files \$uri \$uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Create monitoring script
log "Creating monitoring script..."
cat > monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script for the attendance system

check_service() {
    service=$1
    if docker-compose ps | grep -q "$service.*Up"; then
        echo "✅ $service is running"
    else
        echo "❌ $service is not running"
        docker-compose logs --tail=20 $service
    fi
}

echo "📊 Attendance System Health Check"
echo "================================="
echo "Time: $(date)"
echo ""

# Check all services
services=("nginx" "frontend" "backend" "db" "keycloak" "redis")
for service in "${services[@]}"; do
    check_service $service
done

# Check SSL certificate expiry
echo ""
echo "🔒 SSL Certificate Status:"
openssl x509 -in ./ssl/cert.pem -text -noout | grep "Not After" || echo "❌ Could not check certificate"

# Check disk space
echo ""
echo "💾 Disk Usage:"
df -h / | tail -1

# Check memory usage
echo ""
echo "🧠 Memory Usage:"
free -h | grep Mem

# Check logs for errors
echo ""
echo "📋 Recent Errors:"
docker-compose logs --tail=10 --since=1h 2>&1 | grep -i error || echo "No recent errors found"
EOF

chmod +x monitor.sh

# Create backup script
log "Creating backup script..."
cat > backup.sh << 'EOF'
#!/bin/bash
# Backup script for the attendance system

BACKUP_DIR="./db-backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/attendance_backup_$DATE.sql"

echo "📦 Creating backup: $BACKUP_FILE"

# Create database backup
docker-compose exec -T db pg_dump -U $DB_USER -d $DB_NAME > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

# Clean old backups (keep last 30 days)
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "✅ Backup completed: $BACKUP_FILE.gz"
EOF

chmod +x backup.sh

# Create systemd service for auto-start
log "Creating systemd service..."
sudo tee /etc/systemd/system/attendance-system.service > /dev/null << EOF
[Unit]
Description=Student Attendance System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable attendance-system.service

# Set up log rotation
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/attendance-system > /dev/null << EOF
$(pwd)/nginx/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}

$(pwd)/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

# Create cron job for backups
log "Setting up automated backups..."
(crontab -l 2>/dev/null; echo "$BACKUP_SCHEDULE cd $(pwd) && ./backup.sh") | crontab -

# Create cron job for SSL certificate renewal
log "Setting up SSL certificate renewal..."
(crontab -l 2>/dev/null; echo "0 0 1 * * certbot renew --quiet && docker-compose restart nginx") | crontab -

# Stop any existing containers
log "Stopping existing containers..."
docker-compose -f docker-compose.production.yml down 2>/dev/null || true

# Build and start the application
log "Building and starting the application..."
docker-compose -f docker-compose.production.yml up --build -d

# Wait for services to start
log "Waiting for services to start..."
sleep 30

# Check service health
log "Checking service health..."
./monitor.sh

echo ""
echo "🎉 Deployment completed successfully!"
echo "=========================================="
echo ""
echo "📍 Your attendance system is now accessible at:"
echo "   🌐 https://$DOMAIN_NAME"
echo "   🌐 https://www.$DOMAIN_NAME"
echo ""
echo "🔐 Keycloak Admin Console:"
echo "   🌐 https://$DOMAIN_NAME/auth/admin"
echo "   👤 Username: $KEYCLOAK_ADMIN_USER"
echo "   🔑 Password: $KEYCLOAK_ADMIN_PASSWORD"
echo ""
echo "👥 Student Login:"
echo "   👤 Username: student1"
echo "   🔑 Password: student123"
echo ""
echo "🔧 Management Commands:"
echo "   📊 Health Check: ./monitor.sh"
echo "   📦 Backup: ./backup.sh"
echo "   🔄 Restart: docker-compose -f docker-compose.production.yml restart"
echo "   🛑 Stop: docker-compose -f docker-compose.production.yml down"
echo ""
echo "📋 Important Notes:"
echo "   - SSL certificates will auto-renew monthly"
echo "   - Database backups run daily at 2:00 AM"
echo "   - Service starts automatically on boot"
echo "   - Logs are rotated daily"
echo ""
echo "🎯 Next Steps:"
echo "   1. Test the system at https://$DOMAIN_NAME"
echo "   2. Change default passwords in Keycloak admin"
echo "   3. Configure DNS to point to this server"
echo "   4. Review logs: docker-compose logs -f"
echo ""
echo "✅ Deployment complete! Your attendance system is ready for global access."