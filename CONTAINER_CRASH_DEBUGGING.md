# Container Crash Debugging Guide

## 🔍 Current Status
- ✅ **Database**: Healthy and running
- ✅ **Backend**: Starting up (health: starting)
- ✅ **Keycloak**: Starting up (health: starting)
- ❌ **Nginx**: Restarting (crashing)
- ❌ **Frontend**: Restarting (crashing)
- ❌ **Redis**: Restarting (crashing)

## 🚀 Step 1: Check Container Logs

Run these commands to see why containers are crashing:

```bash
# Check nginx crash logs
sudo docker logs attendance-nginx

# Check frontend crash logs
sudo docker logs attendance-frontend

# Check redis crash logs
sudo docker logs attendance-redis

# Check backend logs (should be starting)
sudo docker logs attendance-backend

# Check keycloak logs
sudo docker logs attendance-keycloak
```

## 🔧 Step 2: Common Fixes

### Fix 1: Redis Container (Most Common Issue)
```bash
# Redis might be failing due to permission issues
sudo docker-compose -f docker-compose.production.yml stop redis
sudo docker-compose -f docker-compose.production.yml rm redis
sudo docker-compose -f docker-compose.production.yml up -d redis

# Check if redis is now running
sudo docker ps | grep redis
```

### Fix 2: Frontend Container
```bash
# Check if frontend is built correctly
sudo docker images | grep frontend

# If frontend image is missing or broken, rebuild it
sudo docker-compose -f docker-compose.production.yml build frontend
sudo docker-compose -f docker-compose.production.yml up -d frontend

# Check frontend logs
sudo docker logs attendance-frontend
```

### Fix 3: Nginx Container
```bash
# Nginx is likely crashing due to missing SSL certificates
# Let's check the ssl directory exists
ls -la ssl/

# Create SSL directory and certificates if missing
mkdir -p ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=securetechsquad.com"

# Restart nginx
sudo docker-compose -f docker-compose.production.yml restart nginx
```

## 🛠️ Step 3: Environment Variable Issues

### Check Environment Variables
```bash
# Verify .env.production exists and has correct values
cat .env.production

# Check if environment variables are being loaded
sudo docker-compose -f docker-compose.production.yml config
```

### Fix Environment Variables
```bash
# If .env.production is missing or wrong, create it
cp .env.production.example .env.production  # if exists
# OR manually create with correct values

# Restart services with new environment
sudo docker-compose -f docker-compose.production.yml down
sudo docker-compose -f docker-compose.production.yml up -d
```

## 🔍 Step 4: Detailed Debugging

### Check Frontend Container Issues
```bash
# Check if frontend can be accessed directly
curl -I http://localhost:3000

# Check if frontend container has correct ports
sudo docker port attendance-frontend

# Try running frontend manually to see errors
sudo docker run -it --rm testrepo-frontend sh
```

### Check Redis Container Issues
```bash
# Check redis data directory permissions
ls -la /var/lib/docker/volumes/

# Try running redis manually
sudo docker run -it --rm redis:alpine redis-cli ping
```

### Check Network Issues
```bash
# Check if containers can communicate
sudo docker exec attendance-backend ping attendance-db
sudo docker exec attendance-backend ping attendance-redis

# Check Docker network
sudo docker network ls
sudo docker network inspect attendance-network
```

## 🚨 Step 5: Emergency Fixes

### Fix 1: Complete Reset
```bash
# Stop everything
sudo docker-compose -f docker-compose.production.yml down -v

# Remove all containers and volumes
sudo docker system prune -a --volumes

# Rebuild everything from scratch
sudo docker-compose -f docker-compose.production.yml build --no-cache
sudo docker-compose -f docker-compose.production.yml up -d

# Check status
sudo docker ps
```

### Fix 2: Start Services One by One
```bash
# Start database first
sudo docker-compose -f docker-compose.production.yml up -d db

# Wait for database to be ready
sleep 10

# Start redis
sudo docker-compose -f docker-compose.production.yml up -d redis

# Start backend
sudo docker-compose -f docker-compose.production.yml up -d backend

# Start frontend
sudo docker-compose -f docker-compose.production.yml up -d frontend

# Start nginx last
sudo docker-compose -f docker-compose.production.yml up -d nginx

# Check status
sudo docker ps
```

### Fix 3: Use Alternative Images
```bash
# If containers keep crashing, try different base images
# Edit docker-compose.production.yml and change:
# redis:alpine to redis:7
# nginx:alpine to nginx:stable
# postgres:14 to postgres:13

# Then restart
sudo docker-compose -f docker-compose.production.yml down
sudo docker-compose -f docker-compose.production.yml up -d
```

## 📋 Common Error Solutions

### Error: "Permission denied"
```bash
# Fix permissions on volumes
sudo chown -R 1000:1000 ssl/
sudo chown -R 999:999 postgres-data/  # if exists
sudo chmod 755 ssl/
```

### Error: "Port already in use"
```bash
# Check what's using the ports
sudo lsof -i :80
sudo lsof -i :3000
sudo lsof -i :5432

# Stop conflicting services
sudo systemctl stop nginx  # if system nginx is running
sudo systemctl stop postgresql  # if system postgres is running
```

### Error: "Image not found"
```bash
# Rebuild all images
sudo docker-compose -f docker-compose.production.yml build --no-cache

# Pull base images
sudo docker pull nginx:alpine
sudo docker pull redis:alpine
sudo docker pull postgres:14
```

## 🎯 Expected Results

After fixing, you should see:
```bash
sudo docker ps
# All containers showing "Up X seconds" or "healthy"
# No "Restarting" status
```

## 🔧 Quick Health Check

```bash
# Check all services are healthy
sudo docker-compose -f docker-compose.production.yml ps

# Test frontend directly
curl -I http://localhost:3000

# Test nginx
curl -I http://localhost:80

# Test external access
curl -I http://securetechsquad.com
```

## 📞 Next Steps

1. **Check logs first**: Run the log commands to see crash reasons
2. **Fix SSL certificates**: Create missing SSL files
3. **Rebuild if needed**: Rebuild crashing containers
4. **Test connectivity**: Verify all services can communicate
5. **Check website**: Test http://securetechsquad.com

---

**Primary Issue**: Multiple containers crashing and restarting  
**Solution**: Check logs, fix underlying issues, rebuild if necessary