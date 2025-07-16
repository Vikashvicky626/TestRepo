# Nginx Frontend Connectivity Fix

## 🔍 Problem Analysis

**Error**: `nginx: [emerg] host not found in upstream "frontend"`  
**Root Cause**: Frontend container is not running or not accessible to nginx

## 🚀 Immediate Fix Commands

### Step 1: Check Current Container Status
```bash
# Check which containers are running
sudo docker ps

# Check all containers (including stopped ones)
sudo docker ps -a

# Check Docker Compose status
sudo docker-compose -f docker-compose.production.yml ps
```

### Step 2: Stop All Containers and Clean Up
```bash
# Stop all containers
sudo docker-compose -f docker-compose.production.yml down

# Remove all containers and networks
sudo docker system prune -f

# Remove any conflicting networks
sudo docker network prune -f
```

### Step 3: Start All Services Together
```bash
# Start all services in correct order
sudo docker-compose -f docker-compose.production.yml up -d

# Check if all containers are running
sudo docker ps
```

### Step 4: Verify Network Connectivity
```bash
# Check Docker networks
sudo docker network ls

# Check if containers are on the same network
sudo docker network inspect attendance-network

# Test connectivity from nginx to frontend
sudo docker exec attendance-nginx ping frontend
```

### Step 5: Alternative Manual Container Start
If docker-compose doesn't work, start containers manually:

```bash
# Start database first
sudo docker run -d --name attendance-db --network attendance-network \
  -e POSTGRES_DB=attendance_production \
  -e POSTGRES_USER=attendance_user \
  -e POSTGRES_PASSWORD=SecureAttendanceDB2024! \
  postgres:13

# Start redis
sudo docker run -d --name attendance-redis --network attendance-network \
  -e REDIS_PASSWORD=RedisSecurePass2024 \
  redis:7-alpine

# Start backend
sudo docker run -d --name attendance-backend --network attendance-network \
  -e DB_HOST=attendance-db \
  -e REDIS_HOST=attendance-redis \
  --env-file .env.production \
  your-backend-image

# Start frontend
sudo docker run -d --name attendance-frontend --network attendance-network \
  -p 3000:3000 \
  your-frontend-image

# Start nginx last
sudo docker run -d --name attendance-nginx --network attendance-network \
  -p 80:80 -p 443:443 \
  -v ./nginx/default.conf:/etc/nginx/conf.d/default.conf \
  -v ./ssl:/etc/nginx/ssl \
  nginx:alpine
```

## 🔧 Quick Fix Alternative

### Option A: Restart Only Frontend Container
```bash
# Build and start frontend container
sudo docker-compose -f docker-compose.production.yml up -d frontend

# Check if frontend is running
sudo docker ps | grep frontend

# Restart nginx to reconnect
sudo docker-compose -f docker-compose.production.yml restart nginx
```

### Option B: Fix Docker Network
```bash
# Create the network if it doesn't exist
sudo docker network create attendance-network

# Start services with explicit network
sudo docker-compose -f docker-compose.production.yml up -d --force-recreate
```

## 🔍 Debugging Commands

### Check Container Health
```bash
# Check frontend container logs
sudo docker logs attendance-frontend

# Check nginx container logs
sudo docker logs attendance-nginx

# Check if frontend is accessible
curl http://localhost:3000
```

### Check Network Connectivity
```bash
# Test from nginx to frontend
sudo docker exec attendance-nginx nslookup frontend

# Test from nginx to frontend port
sudo docker exec attendance-nginx telnet frontend 3000

# Check exposed ports
sudo docker port attendance-frontend
```

### Check Service Discovery
```bash
# Check if services can find each other
sudo docker exec attendance-nginx ping attendance-frontend
sudo docker exec attendance-nginx ping frontend

# Check Docker DNS
sudo docker exec attendance-nginx cat /etc/resolv.conf
```

## 🛠️ Configuration Fixes

### Fix 1: Update Nginx Configuration (if needed)
```bash
# Check current nginx config
sudo docker exec attendance-nginx cat /etc/nginx/conf.d/default.conf

# If frontend service name is wrong, update it
# Edit nginx/default.conf and change:
# proxy_pass http://frontend:3000;
# to:
# proxy_pass http://attendance-frontend:3000;
```

### Fix 2: Update Docker Compose Service Names
Ensure in docker-compose.production.yml:
```yaml
services:
  frontend:
    container_name: attendance-frontend
    # ... other config
    
  nginx:
    container_name: attendance-nginx
    depends_on:
      - frontend
    # ... other config
```

## 📋 Expected Results

After fixing, you should see:
1. **All containers running**: `sudo docker ps` shows 6 containers
2. **Network connectivity**: nginx can reach frontend
3. **HTTP 200 response**: `curl http://localhost` returns success
4. **Website accessible**: `http://securetechsquad.com` loads properly

## 🎯 Test Commands

```bash
# Test 1: All containers running
sudo docker ps | wc -l  # Should show 6+ containers

# Test 2: Frontend accessible
curl -I http://localhost:3000

# Test 3: Nginx can reach frontend
sudo docker exec attendance-nginx wget -q -O - http://frontend:3000

# Test 4: External access works
curl -I http://securetechsquad.com
```

## 🚨 Emergency Recovery

If nothing works:
```bash
# Nuclear option - complete reset
sudo docker system prune -a --volumes
sudo docker-compose -f docker-compose.production.yml up -d --build --force-recreate

# Check status
sudo docker ps
sudo docker logs attendance-nginx
```

---

**Primary Issue**: Frontend container not running or not accessible to nginx  
**Solution**: Start all containers together with proper network configuration