# Revert to Port 3000 Configuration

## 🎯 Goal
Revert back to the original working configuration where the frontend is accessible on port 3000, eliminating SSL certificate issues and complex nginx configurations.

## 🔧 Step 1: Stop All Containers
```bash
# Stop all running containers
sudo docker-compose -f docker-compose.production.yml down

# Clean up any stuck containers
sudo docker system prune -f
```

## 🔧 Step 2: Simplify Docker Compose Configuration

Update `docker-compose.production.yml` to expose port 3000:

```yaml
version: '3.8'

services:
  frontend:
    build: 
      context: ./frontend
      dockerfile: Dockerfile.production
    container_name: attendance-frontend
    ports:
      - "3000:3000"  # Expose port 3000 directly
    environment:
      - REACT_APP_API_URL=http://${DOMAIN_NAME}:5000/api
      - REACT_APP_KEYCLOAK_URL=http://${DOMAIN_NAME}:8080/auth
      - REACT_APP_FRONTEND_URL=http://${DOMAIN_NAME}:3000
    depends_on:
      - backend
      - keycloak
    restart: unless-stopped
    networks:
      - attendance-network

  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.production
    container_name: attendance-backend
    ports:
      - "5000:5000"  # Expose backend on port 5000
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - attendance-network

  db:
    image: postgres:14
    container_name: attendance-db
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - attendance-network

  redis:
    image: redis:alpine
    container_name: attendance-redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    restart: unless-stopped
    networks:
      - attendance-network

  keycloak:
    image: quay.io/keycloak/keycloak:24.0.1
    container_name: attendance-keycloak
    ports:
      - "8080:8080"  # Expose keycloak on port 8080
    environment:
      - KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN_USER}
      - KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
      - KC_DB=postgres
      - KC_DB_URL=jdbc:postgresql://db:5432/${DB_NAME}
      - KC_DB_USERNAME=${DB_USER}
      - KC_DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - db
    restart: unless-stopped
    networks:
      - attendance-network

volumes:
  postgres_data:

networks:
  attendance-network:
    driver: bridge
```

## 🔧 Step 3: Update Environment Variables

Update `.env.production` to use port 3000:

```bash
# Domain Configuration
DOMAIN_NAME=securetechsquad.com
ENVIRONMENT=production

# Database Configuration
DB_NAME=attendance_production
DB_USER=attendance_user
DB_PASSWORD=SecureAttendanceDB2024!

# Security Keys
JWT_SECRET_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9LCJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ
KEYCLOAK_SECRET=k8sSecretKeyForKeycloak2024Security

# Keycloak Admin Configuration
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=AdminPass2024!

# Redis Configuration
REDIS_PASSWORD=RedisSecurePass2024

# Security Configuration
ALLOWED_HOSTS=securetechsquad.com:3000,www.securetechsquad.com:3000
CORS_ALLOWED_ORIGINS=http://securetechsquad.com:3000,http://www.securetechsquad.com:3000
```

## 🔧 Step 4: Remove Nginx Configuration

Since we're going direct to port 3000, we don't need nginx:

```bash
# Remove nginx from docker-compose (it's already removed in the config above)
# We'll access the frontend directly on port 3000
```

## 🔧 Step 5: Update Frontend Configuration

Make sure the frontend serves on port 3000 in `frontend/Dockerfile.production`:

```dockerfile
FROM node:18-alpine as builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built app
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 3000
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

Update `frontend/nginx.conf`:

```nginx
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
        index index.html index.htm;

        # Handle client-side routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

## 🚀 Step 6: Deploy the Simplified Configuration

```bash
# Start the services
sudo docker-compose -f docker-compose.production.yml up -d --build

# Check status
sudo docker ps

# Test the frontend
curl -I http://localhost:3000

# Test external access
curl -I http://securetechsquad.com:3000
```

## 🔧 Step 7: Configure Firewall for Port 3000

```bash
# Allow port 3000 through firewall
sudo ufw allow 3000/tcp
sudo ufw reload
sudo ufw status
```

## 🎯 Expected Results

After reverting, you should be able to access:
- **Frontend**: `http://securetechsquad.com:3000`
- **Backend API**: `http://securetechsquad.com:5000/api`
- **Keycloak**: `http://securetechsquad.com:8080/auth`

## 📋 Testing Commands

```bash
# Test frontend
curl -I http://securetechsquad.com:3000

# Test backend
curl -I http://securetechsquad.com:5000/api/health

# Test keycloak
curl -I http://securetechsquad.com:8080/auth

# Check all containers are running
sudo docker ps
```

## 🔧 Quick Commands to Execute

```bash
# 1. Stop current containers
sudo docker-compose -f docker-compose.production.yml down

# 2. Update docker-compose.production.yml (copy the config above)
# 3. Update .env.production (copy the config above)
# 4. Update frontend nginx.conf (copy the config above)

# 5. Start services
sudo docker-compose -f docker-compose.production.yml up -d --build

# 6. Allow port 3000
sudo ufw allow 3000/tcp

# 7. Test access
curl -I http://securetechsquad.com:3000
```

## 🎉 Benefits of This Approach

✅ **No SSL certificates needed**  
✅ **No complex nginx configuration**  
✅ **Direct access to frontend**  
✅ **Simpler debugging**  
✅ **Eliminates container crashes**  
✅ **Back to working configuration**  

---

**Access URL**: `http://securetechsquad.com:3000`  
**Configuration**: Simplified, direct port access  
**Status**: Ready for immediate deployment