# 🔧 Database Troubleshooting Guide

## ❌ Problem: Database Container Fails to Start
```
✘ Container testrepo-db-1 Error
dependency failed to start: container testrepo-db-1 is unhealthy
```

## 🔍 Quick Diagnosis Steps

### 1. Check Container Status
```bash
# Check all containers
docker ps -a

# Check specific database container
docker ps -a | grep db
```

### 2. View Database Logs
```bash
# View database logs
docker-compose logs db
# or
docker logs testrepo-db-1
```

### 3. Check if Database Port is Available
```bash
# Check if port 5432 is already in use
netstat -tulpn | grep 5432
# or
lsof -i :5432
```

## 🛠️ Solution Steps

### Solution 1: Clean Restart (Recommended)
```bash
# Stop all containers
docker-compose down

# Remove volumes (this will delete database data)
docker-compose down -v

# Remove any orphaned containers
docker system prune -f

# Start fresh
docker-compose up --build -d
```

### Solution 2: Use Simplified Database Setup
If the above doesn't work, try this minimal approach:

```bash
# Stop everything
docker-compose down -v

# Start only the database first
docker-compose up -d db

# Wait for database to be ready (check logs)
docker-compose logs -f db

# Once healthy, start other services
docker-compose up -d
```

### Solution 3: Alternative Init Script
If `init.sql` is causing issues, create a minimal version:

```sql
-- minimal-init.sql
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(username, date)
);
```

Then update `docker-compose.yml`:
```yaml
volumes:
  - ./minimal-init.sql:/docker-entrypoint-initdb.d/init.sql
```

### Solution 4: Skip Init Script Temporarily
Comment out the init script in `docker-compose.yml`:
```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
  # - ./init.sql:/docker-entrypoint-initdb.d/init.sql
```

## 🔍 Common Issues and Fixes

### Issue 1: Port Already in Use
```bash
# Kill process using port 5432
sudo lsof -t -i:5432 | xargs sudo kill -9

# Or use different port in docker-compose.yml
ports:
  - "5433:5432"  # Change external port
```

### Issue 2: Permission Issues
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker-compose up --build -d
```

### Issue 3: Init Script Timeout
The database might be taking too long to initialize. Increase timeout:

```yaml
# In docker-compose.yml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U user -d attendance_db"]
  interval: 30s
  timeout: 10s
  retries: 10  # Increased from 5
  start_period: 60s  # Increased from 30s
```

### Issue 4: Memory Issues
```bash
# Check available memory
free -h

# Increase Docker memory limit if needed
# Docker Desktop: Settings > Resources > Memory
```

## 🧪 Test Database Manually

If you need to test the database separately:

```bash
# Run PostgreSQL container manually
docker run --name test-postgres \
  -e POSTGRES_DB=attendance_db \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=pass \
  -p 5432:5432 \
  -d postgres:14

# Wait a moment, then test connection
docker exec -it test-postgres psql -U user -d attendance_db

# Clean up
docker stop test-postgres && docker rm test-postgres
```

## 🚀 Complete Reset Procedure

If nothing works, try this complete reset:

```bash
# 1. Stop everything
docker-compose down -v

# 2. Remove all Docker containers and images
docker system prune -a -f

# 3. Remove volumes
docker volume prune -f

# 4. Start fresh with logs
docker-compose up --build

# 5. Watch logs in real-time
docker-compose logs -f
```

## 📊 Health Check Commands

```bash
# Check if database is ready
docker-compose exec db pg_isready -U user -d attendance_db

# Connect to database
docker-compose exec db psql -U user -d attendance_db

# Check tables
docker-compose exec db psql -U user -d attendance_db -c "\dt"
```

## 🔧 Alternative: Manual Database Setup

If automated setup fails, set up manually:

```bash
# 1. Start database without init script
docker-compose up -d db

# 2. Wait for database to be ready
sleep 10

# 3. Create table manually
docker-compose exec db psql -U user -d attendance_db -c "
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(username, date)
);
"

# 4. Start other services
docker-compose up -d
```

## 📋 Prevention Tips

1. **Regular Cleanup**: Run `docker system prune -f` periodically
2. **Monitor Resources**: Check disk space and memory
3. **Use Volumes**: Always use named volumes for data persistence
4. **Backup Important Data**: Export database before major changes
5. **Test Changes**: Test database changes in development first

## 🆘 Still Having Issues?

If the problem persists:

1. **Check Docker Version**: `docker --version`
2. **Check System Resources**: `df -h` and `free -h`
3. **Try Docker Desktop Restart**: Restart Docker Desktop completely
4. **Check Logs**: Look for specific error messages in database logs
5. **Use Simple Setup**: Remove all complex features and use minimal config

## 🎯 Quick Fix Commands

```bash
# One-liner to reset everything
docker-compose down -v && docker system prune -f && docker-compose up --build -d

# Check if it worked
docker-compose ps && docker-compose logs db
```

---

**💡 Tip**: Always check the database logs first - they usually contain the exact error message that helps identify the issue!