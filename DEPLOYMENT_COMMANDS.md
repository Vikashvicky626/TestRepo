# Deployment Commands for securetechsquad.com

## 🎯 Current Status
- ✅ **DNS**: securetechsquad.com → 139.84.222.64 (Working)
- ✅ **Server**: Ping successful (Server reachable)
- ✅ **Web Server**: Running (HTTP 404 response)
- ❌ **Application**: Not deployed/configured

## 🚀 Step-by-Step Deployment

### Step 1: Connect to Your Vultr Server
```bash
# SSH into your Vultr server
ssh root@139.84.222.64
# OR if you have a different username:
ssh your-username@139.84.222.64
```

### Step 2: Clone/Update Your Repository
```bash
# If repository doesn't exist, clone it:
git clone https://github.com/Vikashvicky626/TestRepo.git
cd TestRepo

# If repository exists, update it:
cd TestRepo
git pull origin main
```

### Step 3: Make Deployment Script Executable
```bash
# Make the deployment script executable
chmod +x deploy-http.sh
```

### Step 4: Run the Deployment Script
```bash
# Deploy the application
./deploy-http.sh
```

### Step 5: Check Docker Containers
```bash
# Verify all containers are running
sudo docker ps

# You should see containers like:
# - attendance-nginx
# - attendance-frontend  
# - attendance-backend
# - attendance-db
# - attendance-keycloak
# - attendance-redis
```

### Step 6: Check Application Logs
```bash
# Check nginx logs
sudo docker logs attendance-nginx

# Check frontend logs
sudo docker logs attendance-frontend

# Check backend logs
sudo docker logs attendance-backend
```

### Step 7: Test Local Access
```bash
# Test if the application responds locally
curl -I http://localhost
curl -I http://localhost:80
```

### Step 8: Check Port 80 Status
```bash
# Check if port 80 is listening
sudo netstat -tlnp | grep :80
# OR
sudo ss -tlnp | grep :80
```

### Step 9: Configure Firewall (if needed)
```bash
# Allow HTTP traffic
sudo ufw allow 80/tcp
sudo ufw reload
sudo ufw status
```

## 🔧 Alternative Manual Deployment

If the script doesn't work, try manual deployment:

```bash
# Stop any existing containers
sudo docker-compose -f docker-compose.production.yml down

# Remove old containers and images
sudo docker system prune -a

# Build and start the application
sudo docker-compose -f docker-compose.production.yml up -d --build

# Check status
sudo docker-compose -f docker-compose.production.yml ps
```

## 🔍 Troubleshooting Commands

### Check What's Running on Port 80
```bash
# Check what service is using port 80
sudo lsof -i :80
sudo netstat -tlnp | grep :80
```

### Check Current Web Server Content
```bash
# See what's being served
curl -v http://localhost
curl -v http://139.84.222.64
```

### Check Nginx Configuration
```bash
# If nginx is running outside Docker
sudo nginx -t
sudo systemctl status nginx

# If you need to stop system nginx
sudo systemctl stop nginx
sudo systemctl disable nginx
```

### Check Docker Network
```bash
# Check Docker networks
sudo docker network ls
sudo docker network inspect attendance-network
```

## 🎯 Expected Results

After successful deployment, you should see:

1. **Docker Containers Running:**
   ```bash
   sudo docker ps
   # Should show: nginx, frontend, backend, database, keycloak, redis
   ```

2. **Port 80 Listening:**
   ```bash
   sudo netstat -tlnp | grep :80
   # Should show: docker-proxy listening on port 80
   ```

3. **Application Responding:**
   ```bash
   curl -I http://localhost
   # Should return: HTTP/1.1 200 OK
   ```

4. **External Access Working:**
   ```bash
   # From your computer:
   curl http://securetechsquad.com
   # Should return: HTML content (not 404)
   ```

## 🆘 Common Issues & Solutions

### Issue 1: Port 80 Already in Use
```bash
# Check what's using port 80
sudo lsof -i :80

# If it's system nginx, stop it
sudo systemctl stop nginx
sudo systemctl disable nginx
```

### Issue 2: Docker Permission Denied
```bash
# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker-compose -f docker-compose.production.yml up -d
```

### Issue 3: Application Not Starting
```bash
# Check logs for errors
sudo docker logs attendance-nginx
sudo docker logs attendance-frontend
sudo docker logs attendance-backend

# Restart containers
sudo docker-compose -f docker-compose.production.yml restart
```

### Issue 4: Database Connection Issues
```bash
# Check if database is running
sudo docker logs attendance-db

# Check network connectivity
sudo docker exec attendance-backend ping attendance-db
```

## 📞 Next Steps

1. **SSH into your server**: `ssh root@139.84.222.64`
2. **Run deployment script**: `./deploy-http.sh`
3. **Check containers**: `sudo docker ps`
4. **Test locally**: `curl -I http://localhost`
5. **Test externally**: Try `http://securetechsquad.com` from your browser

## 🎉 Success Indicators

✅ **Docker containers running**  
✅ **Port 80 listening**  
✅ **curl http://localhost returns 200 OK**  
✅ **securetechsquad.com loads in browser**  

---

**Status**: Server reachable, web server running, application needs deployment