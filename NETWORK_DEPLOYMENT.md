# 🌐 Network Deployment Guide - Student Attendance System

This guide explains how to deploy the attendance system for network access, allowing students to access it from different devices on the same network.

## 🚀 Quick Network Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Run the automated deployment script
./deploy-network.sh
```

This script will:
- 🔍 Automatically detect your host IP address
- 🏗️ Build and start all services with network configuration
- 🧪 Run health checks
- 📋 Display access URLs for students

### Option 2: Manual Deployment

```bash
# Find your host IP address
hostname -I | awk '{print $1}'  # Linux
# or
ifconfig | grep "inet " | grep -v 127.0.0.1  # macOS/Linux

# Set the HOST_IP environment variable
export HOST_IP=192.168.1.100  # Replace with your actual IP

# Deploy with network configuration
docker-compose -f docker-compose.network.yml up --build -d
```

## 📋 What Changes for Network Access

### 1. **Environment Variables**
- `REACT_APP_API_URL`: Points to your host IP instead of localhost
- `REACT_APP_KEYCLOAK_URL`: Keycloak URL with your host IP
- `REACT_APP_FRONTEND_URL`: Frontend URL with your host IP

### 2. **Keycloak Configuration**
- Extended redirect URIs to support various IP ranges
- Wildcard web origins for CORS
- Network-friendly hostname settings

### 3. **Docker Configuration**
- Host IP passed as environment variable
- Keycloak configured for network access
- All services accessible from network

## 🔧 Configuration Files

### Network-Specific Files Created:
- `docker-compose.network.yml` - Network-accessible Docker Compose configuration
- `keycloak/school-realm-network.json` - Keycloak realm with network redirect URIs
- `deploy-network.sh` - Automated deployment script

### Modified Files:
- `frontend/src/App.js` - Uses environment variables for URLs

## 🌍 Access URLs

After deployment, the system will be accessible at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | `http://YOUR_IP:3000` | Main student interface |
| **Backend API** | `http://YOUR_IP:5000` | API endpoints |
| **Keycloak Admin** | `http://YOUR_IP:8080` | Authentication server |

## 👥 Student Access

Students can access the system from any device on the same network:

1. **Share the URL**: `http://YOUR_IP:3000`
2. **Login Credentials**: 
   - Username: `student1`
   - Password: `student123`

## 🔐 Security Considerations

### Network Security:
- ✅ System is accessible within your local network
- ⚠️ **Not exposed to the internet** (good for classroom use)
- ⚠️ **No HTTPS** (suitable for trusted networks only)

### Production Considerations:
- Use HTTPS in production environments
- Configure proper authentication policies
- Set up network firewalls
- Consider using a reverse proxy

## 🧪 Testing Network Access

### From Another Device:
1. Connect to the same network
2. Open browser and go to `http://YOUR_IP:3000`
3. Login with student credentials
4. Submit attendance

### Troubleshooting:
```bash
# Check if services are running
docker-compose -f docker-compose.network.yml ps

# Check service logs
docker-compose -f docker-compose.network.yml logs -f

# Test API directly
curl http://YOUR_IP:5000/health

# Check network connectivity
ping YOUR_IP
```

## 📱 Multi-Device Testing

The system works on:
- 💻 **Desktop computers** (Windows, macOS, Linux)
- 📱 **Mobile devices** (iOS, Android)
- 📟 **Tablets** (iPad, Android tablets)

## 🔧 Common Issues and Solutions

### Issue 1: Services Not Accessible from Network
```bash
# Check if ports are blocked by firewall
sudo ufw status  # Linux
# or
sudo firewall-cmd --list-all  # CentOS/RHEL

# Open ports if needed
sudo ufw allow 3000  # Linux
sudo ufw allow 5000
sudo ufw allow 8080
```

### Issue 2: Wrong IP Address Detected
```bash
# Manually set the IP address
export HOST_IP=192.168.1.100
docker-compose -f docker-compose.network.yml up --build -d
```

### Issue 3: Keycloak Redirect Issues
- Ensure the redirect URI in Keycloak matches your host IP
- Check that the realm configuration includes your IP range

### Issue 4: CORS Issues
- The backend is configured to allow all origins (`*`)
- If issues persist, check browser developer tools for CORS errors

## 📊 Monitoring

### Check Service Health:
```bash
# Backend health
curl http://YOUR_IP:5000/health

# Frontend accessibility
curl http://YOUR_IP:3000

# Keycloak health
curl http://YOUR_IP:8080/health
```

### View Service Logs:
```bash
# All services
docker-compose -f docker-compose.network.yml logs -f

# Specific service
docker-compose -f docker-compose.network.yml logs -f frontend
```

## 🛑 Stopping Network Services

```bash
# Stop all services
docker-compose -f docker-compose.network.yml down

# Stop and remove volumes
docker-compose -f docker-compose.network.yml down -v
```

## 🔄 Switching Between Local and Network Mode

### Switch to Network Mode:
```bash
# Stop local services
docker-compose down

# Start network services
./deploy-network.sh
```

### Switch to Local Mode:
```bash
# Stop network services
docker-compose -f docker-compose.network.yml down

# Start local services
docker-compose up --build -d
```

## 📝 Environment Variables Reference

| Variable | Description | Default | Network Value |
|----------|-------------|---------|---------------|
| `REACT_APP_API_URL` | Backend API URL | `http://localhost:5000` | `http://YOUR_IP:5000` |
| `REACT_APP_KEYCLOAK_URL` | Keycloak server URL | `http://localhost:8080` | `http://YOUR_IP:8080` |
| `REACT_APP_FRONTEND_URL` | Frontend URL | `http://localhost:3000` | `http://YOUR_IP:3000` |
| `HOST_IP` | Host IP address | `localhost` | Auto-detected IP |

## 🎯 Best Practices

1. **Use the automated script** for easy deployment
2. **Test on multiple devices** before classroom use
3. **Keep credentials secure** in production
4. **Monitor service logs** for issues
5. **Have a backup plan** (local deployment)

## 🆘 Support

If you encounter issues:
1. Check the logs: `docker-compose -f docker-compose.network.yml logs -f`
2. Verify network connectivity: `ping YOUR_IP`
3. Test health endpoints: `curl http://YOUR_IP:5000/health`
4. Check firewall settings
5. Restart services: `./deploy-network.sh`

---

**🌐 Your attendance system is now ready for network access!**