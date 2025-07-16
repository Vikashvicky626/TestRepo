# Vultr Cloud Deployment Fixes for securetechsquad.com

## 🔧 Issues Fixed

### 1. **Missing .env.production File**
**Problem**: The deployment script expected a `.env.production` file that didn't exist.
**Fix**: Created `.env.production` with proper configuration for `securetechsquad.com` domain.

### 2. **Port Configuration (3000 → 80)**
**Problem**: Application was configured to redirect HTTP (port 80) to HTTPS only.
**Fix**: 
- Modified nginx configuration to serve directly on port 80
- Kept HTTPS as optional for future SSL setup
- Frontend now serves on port 80 (externally) while running on port 3000 (internally)

### 3. **SSL Certificate Issues**
**Problem**: All services were hardcoded to require SSL certificates.
**Fix**: 
- Made SSL certificates optional
- Created placeholder self-signed certificates
- Configured services to work with HTTP

### 4. **Domain Configuration**
**Problem**: Services were not properly configured for the specific domain.
**Fix**: 
- Updated all environment variables for `securetechsquad.com`
- Configured CORS and allowed hosts properly
- Updated Keycloak realm configuration

### 5. **Keycloak HTTP Support**
**Problem**: Keycloak was configured for HTTPS-only mode.
**Fix**: 
- Enabled HTTP mode for Keycloak
- Updated realm configuration for HTTP URLs
- Fixed health check endpoints

### 6. **Missing Required Directories**
**Problem**: Several directories were missing causing volume mount errors.
**Fix**: Created necessary directories:
- `ssl/` - for SSL certificates
- `nginx/logs/` - for nginx logs
- `db-backups/` - for database backups
- `keycloak/` - for realm configuration

## 📁 Files Created/Modified

### New Files:
- ✅ `.env.production` - Production environment configuration
- ✅ `deploy-http.sh` - Simplified HTTP deployment script
- ✅ `frontend/nginx.conf` - Frontend nginx configuration
- ✅ `keycloak/production-realm.json` - Keycloak realm configuration
- ✅ `ssl/cert.pem` & `ssl/key.pem` - Placeholder SSL certificates

### Modified Files:
- ✅ `docker-compose.production.yml` - Updated for HTTP deployment
- ✅ `nginx/default.conf` - Configured for port 80 serving
- ✅ `nginx/nginx.conf` - Added rate limiting and security

## 🚀 Deployment Instructions

### Option 1: HTTP Deployment (Recommended for quick setup)
```bash
# Clone/upload your repository to Vultr instance
git clone <your-repo-url>
cd <your-repo-directory>

# Review and update configuration if needed
nano .env.production

# Run the HTTP deployment script
./deploy-http.sh
```

### Option 2: Full Production Deployment with SSL
```bash
# Use the original deployment script for SSL setup
./deploy-cloud.sh
```

## 🌐 Access URLs

After deployment, your application will be available at:
- **Main Application**: `http://securetechsquad.com`
- **API Endpoints**: `http://securetechsquad.com/api`
- **Keycloak Auth**: `http://securetechsquad.com/auth`
- **Health Check**: `http://securetechsquad.com/health`

## 👥 Default Login Credentials

| Role | Username | Password |
|------|----------|----------|
| Admin | admin | admin123 |
| Teacher | teacher | teacher123 |
| Student | student1 | student123 |

## 🔒 Security Notes

### Current Setup (HTTP)
- ✅ Rate limiting enabled
- ✅ Security headers configured
- ✅ Input validation
- ✅ CORS protection
- ⚠️ No SSL encryption (HTTP only)

### For Production (HTTPS)
- Run `./deploy-cloud.sh` to set up SSL certificates
- Configure Let's Encrypt for automatic certificate renewal
- Enable HTTPS redirects

## 🛠️ Management Commands

```bash
# View application logs
docker-compose -f docker-compose.production.yml logs -f

# Restart all services
docker-compose -f docker-compose.production.yml restart

# Stop all services
docker-compose -f docker-compose.production.yml down

# View container status
docker-compose -f docker-compose.production.yml ps

# Access database
docker exec -it attendance-db psql -U attendance_user -d attendance_production
```

## 🔍 Troubleshooting

### Common Issues:

1. **Port 80 already in use**
   ```bash
   sudo systemctl stop nginx
   sudo systemctl stop apache2
   ```

2. **Docker permission issues**
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

3. **Services not starting**
   ```bash
   docker-compose -f docker-compose.production.yml logs
   ```

4. **Database connection issues**
   ```bash
   docker-compose -f docker-compose.production.yml restart db
   ```

## 📋 Pre-deployment Checklist

- [ ] DNS A record points to your Vultr instance IP
- [ ] Firewall allows ports 80, 443, and 22
- [ ] Docker and Docker Compose installed
- [ ] Sufficient disk space (>5GB recommended)
- [ ] `.env.production` file configured
- [ ] Domain name configured correctly

## 🎯 Next Steps

1. **Test the application**: Visit `http://securetechsquad.com`
2. **Configure DNS**: Point your domain to the server IP
3. **Set up SSL**: Run `./deploy-cloud.sh` for HTTPS
4. **Configure backups**: Set up database backups
5. **Monitor**: Set up logging and monitoring
6. **Customize**: Update branding and configuration as needed

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Review the logs using the management commands
3. Ensure all prerequisites are met
4. Verify your domain DNS configuration