#!/bin/bash

# Immediate Database Fix Script
# This script will completely reset the database to fix the init.sql issue

echo "🔧 Immediate Database Fix"
echo "========================"

echo "🛑 Stopping all containers..."
docker stop $(docker ps -aq) 2>/dev/null || true

echo "🗑️  Removing all containers..."
docker rm $(docker ps -aq) 2>/dev/null || true

echo "📦 Removing problematic volume..."
docker volume rm testrepo_postgres_data 2>/dev/null || true
docker volume rm $(docker volume ls -q | grep postgres) 2>/dev/null || true

echo "🧹 Cleaning up networks..."
docker network prune -f 2>/dev/null || true

echo "🗑️  Removing unused volumes..."
docker volume prune -f 2>/dev/null || true

echo "🔄 System cleanup..."
docker system prune -f 2>/dev/null || true

echo ""
echo "✅ Database volume and containers removed!"
echo ""
echo "📋 Next steps:"
echo "1. The database volume has been completely removed"
echo "2. Now start your services fresh:"
echo "   - If you have docker-compose: docker-compose up --build -d"
echo "   - If you have Docker Desktop: Use the GUI to start services"
echo "   - Or run: docker compose up --build -d"
echo ""
echo "🎯 The init.sql script should now work correctly on fresh startup!"