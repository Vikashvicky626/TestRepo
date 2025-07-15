# ☁️ Cloud Deployment Guide - Global Access

This guide walks you through deploying the Student Attendance System on a cloud VM instance for global accessibility with SSL/TLS security.

## 🎯 Overview

This deployment provides:
- **Global accessibility** via HTTPS
- **SSL/TLS encryption** with Let's Encrypt certificates
- **Production-ready** security and performance
- **Auto-scaling** capabilities
- **Automated backups** and monitoring
- **Domain name** support

## 🚀 Quick Start

### Prerequisites
- Domain name pointing to your server
- Cloud VM instance (2GB RAM, 20GB storage minimum)
- SSH access to the server
- Email address for SSL certificates

### One-Command Deployment
```bash
# Clone repository and deploy
git clone https://github.com/Vikashvicky626/TestRepo.git
cd TestRepo
cp .env.production.example .env.production
nano .env.production  # Edit with your configuration
chmod +x deploy-cloud.sh
./deploy-cloud.sh
```

## 🌐 Cloud Provider Setup

### Amazon Web Services (AWS)
1. **Launch EC2 Instance**:
   - Instance Type: `t3.medium` (2 vCPU, 4GB RAM)
   - AMI: Ubuntu 22.04 LTS
   - Storage: 20GB GP3
   - Security Group: Allow HTTP (80), HTTPS (443), SSH (22)

2. **Configure Elastic IP**:
   ```bash
   # Associate Elastic IP to your instance
   aws ec2 associate-address --instance-id i-1234567890abcdef0 --public-ip 203.0.113.1
   ```

3. **Set up DNS**:
   ```bash
   # Point your domain to the Elastic IP
   # A record: yourdomain.com -> 203.0.113.1
   # CNAME record: www.yourdomain.com -> yourdomain.com
   ```

### Google Cloud Platform (GCP)
1. **Create Compute Engine Instance**:
   ```bash
   gcloud compute instances create attendance-server \
     --image-family=ubuntu-2204-lts \
     --image-project=ubuntu-os-cloud \
     --machine-type=e2-standard-2 \
     --boot-disk-size=20GB \
     --tags=http-server,https-server
   ```

2. **Configure Firewall**:
   ```bash
   gcloud compute firewall-rules create allow-attendance-http \
     --allow tcp:80,tcp:443 \
     --source-ranges 0.0.0.0/0 \
     --target-tags http-server,https-server
   ```

3. **Set up DNS**:
   ```bash
   # Get external IP
   gcloud compute instances describe attendance-server --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   
   # Configure DNS records
   gcloud dns record-sets transaction start --zone=yourzone
   gcloud dns record-sets transaction add 203.0.113.1 --name=yourdomain.com. --ttl=300 --type=A --zone=yourzone
   gcloud dns record-sets transaction execute --zone=yourzone
   ```

### Microsoft Azure
1. **Create Virtual Machine**:
   ```bash
   az vm create \
     --resource-group attendance-rg \
     --name attendance-server \
     --image UbuntuLTS \
     --size Standard_B2s \
     --admin-username azureuser \
     --generate-ssh-keys
   ```

2. **Configure Network Security Group**:
   ```bash
   az network nsg rule create \
     --resource-group attendance-rg \
     --nsg-name attendance-serverNSG \
     --name allow-web \
     --protocol tcp \
     --priority 100 \
     --destination-port-range 80 443 \
     --access allow
   ```

### DigitalOcean
1. **Create Droplet**:
   ```bash
   # Via web interface or CLI
   doctl compute droplet create attendance-server \
     --image ubuntu-22-04-x64 \
     --size s-2vcpu-4gb \
     --region nyc3 \
     --ssh-keys your-ssh-key-id
   ```

2. **Configure Firewall**:
   ```bash
   doctl compute firewall create \
     --name attendance-firewall \
     --inbound-rules "protocol:tcp,ports:22,sources:addresses:0.0.0.0/0 protocol:tcp,ports:80,sources:addresses:0.0.0.0/0 protocol:tcp,ports:443,sources:addresses:0.0.0.0/0"
   ```

## 🔧 Configuration

### Environment Variables (.env.production)
```bash
# Domain Configuration
DOMAIN_NAME=yourdomain.com
ENVIRONMENT=production

# Database Configuration
DB_NAME=attendance_production
DB_USER=attendance_user
DB_PASSWORD=your_secure_database_password_here

# Security Keys (Generate strong random keys)
JWT_SECRET_KEY=your_jwt_secret_key_here_make_it_long_and_random
KEYCLOAK_SECRET=your_keycloak_secret_here

# Keycloak Admin Configuration
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=your_secure_admin_password

# Redis Configuration
REDIS_PASSWORD=your_redis_password

# SSL Configuration
SSL_EMAIL=your-email@domain.com
SSL_PROVIDER=letsencrypt

# Security Configuration
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Generate Secure Keys
```bash
# Generate JWT secret key
openssl rand -base64 64

# Generate Keycloak secret
openssl rand -base64 32

# Generate Redis password
openssl rand -base64 32

# Generate database password
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
```

## 🔒 Security Features

### SSL/TLS Configuration
- **Let's Encrypt** certificates with auto-renewal
- **TLS 1.2/1.3** support only
- **HSTS** headers for security
- **Strong cipher suites**

### Application Security
- **Rate limiting** on API endpoints
- **CORS protection**
- **Security headers** (XSS, CSRF, etc.)
- **Input validation** and sanitization
- **Session management** with secure tokens

### Network Security
- **Firewall** configuration
- **Non-root** container execution
- **Private networking** between services
- **Database access** restricted to application

### Monitoring & Logging
- **Health checks** for all services
- **Audit logging** for attendance changes
- **Error tracking** and alerting
- **Performance monitoring**

## 📊 Architecture

```
Internet → CloudFlare/CDN → Load Balancer → Nginx → Services
                                            ↓
                                        Frontend (React)
                                            ↓
                                        Backend (FastAPI)
                                            ↓
                                        Database (PostgreSQL)
                                            ↓
                                        Authentication (Keycloak)
```

## 🛠️ Deployment Process

### 1. Server Preparation
```bash
# Connect to your server
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install git
sudo apt install -y git
```

### 2. Clone and Configure
```bash
# Clone repository
git clone https://github.com/Vikashvicky626/TestRepo.git
cd TestRepo

# Copy and edit configuration
cp .env.production.example .env.production
nano .env.production  # Edit with your values
```

### 3. DNS Configuration
```bash
# Ensure your domain points to the server
# A record: yourdomain.com → your-server-ip
# CNAME record: www.yourdomain.com → yourdomain.com

# Verify DNS propagation
dig yourdomain.com
nslookup yourdomain.com
```

### 4. Deploy
```bash
# Make script executable
chmod +x deploy-cloud.sh

# Run deployment
./deploy-cloud.sh
```

### 5. Verify Deployment
```bash
# Check service status
./monitor.sh

# Check SSL certificate
curl -I https://yourdomain.com

# Test application
curl -k https://yourdomain.com/api/health
```

## 📋 Management Commands

### Service Management
```bash
# Check status
docker-compose -f docker-compose.production.yml ps

# View logs
docker-compose -f docker-compose.production.yml logs -f

# Restart services
docker-compose -f docker-compose.production.yml restart

# Stop services
docker-compose -f docker-compose.production.yml down

# Update application
git pull origin main
docker-compose -f docker-compose.production.yml up --build -d
```

### Backup and Restore
```bash
# Create backup
./backup.sh

# Restore from backup
docker-compose exec -T db psql -U $DB_USER -d $DB_NAME < backup.sql

# List backups
ls -la db-backups/
```

### SSL Certificate Management
```bash
# Check certificate status
certbot certificates

# Renew certificates manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

## 🔧 Troubleshooting

### Common Issues

#### SSL Certificate Issues
```bash
# Check certificate expiry
openssl x509 -in ./ssl/cert.pem -text -noout | grep "Not After"

# Regenerate certificate
sudo certbot delete --cert-name yourdomain.com
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

#### Service Not Starting
```bash
# Check logs
docker-compose logs service-name

# Check disk space
df -h

# Check memory
free -h

# Restart specific service
docker-compose restart service-name
```

#### Database Connection Issues
```bash
# Check database logs
docker-compose logs db

# Connect to database
docker-compose exec db psql -U $DB_USER -d $DB_NAME

# Reset database
docker-compose down -v
docker-compose up -d db
```

### Performance Optimization

#### Database Optimization
```bash
# Connect to database
docker-compose exec db psql -U $DB_USER -d $DB_NAME

# Run maintenance
SELECT maintenance_tasks();

# Check database size
SELECT pg_size_pretty(pg_database_size('attendance_production'));
```

#### Nginx Optimization
```bash
# Edit nginx configuration
nano nginx/nginx.conf

# Test configuration
docker-compose exec nginx nginx -t

# Reload configuration
docker-compose exec nginx nginx -s reload
```

## 📈 Scaling Considerations

### Horizontal Scaling
- **Load balancer** setup
- **Multi-instance** deployment
- **Database replication**
- **Session storage** in Redis

### Vertical Scaling
- **Increase server** resources
- **Optimize database** queries
- **Enable caching** layers
- **CDN integration**

### Monitoring and Alerting
- **Prometheus** metrics
- **Grafana** dashboards
- **Alert manager** setup
- **Log aggregation**

## 🎯 Success Criteria

After deployment, you should have:
- ✅ **Global accessibility** via HTTPS
- ✅ **SSL certificate** properly configured
- ✅ **All services** running and healthy
- ✅ **Database** properly initialized
- ✅ **Authentication** working correctly
- ✅ **Automatic backups** configured
- ✅ **Monitoring** in place

## 🔗 URLs After Deployment

- **Main Application**: https://yourdomain.com
- **Keycloak Admin**: https://yourdomain.com/auth/admin
- **Health Check**: https://yourdomain.com/api/health
- **API Documentation**: https://yourdomain.com/api/docs

## 📞 Support

For deployment issues:
1. Check the logs: `docker-compose logs -f`
2. Run health check: `./monitor.sh`
3. Review troubleshooting section
4. Check cloud provider documentation

---

**🌍 Your attendance system is now globally accessible with enterprise-grade security!**