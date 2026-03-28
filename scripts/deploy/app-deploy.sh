#!/bin/bash
# ~/projects/rw_deploy/scripts/deploy-infra.sh

set -e

echo "🚀 Deploying Rock Willow Infrastructure"
echo "======================================="

cd ~/projects/rw_deploy

# Load environment
if [ -f .env ]; then
  source .env
  echo "✅ Loaded environment variables"
else
  echo "⚠️  Using default values (.env not found)"
fi

# Deploy infrastructure
echo "📦 Starting Apps..."
podman-compose -f app-compose.yml up -d --build 

echo "⏳ Waiting for services to start..."
sleep 10

echo "✅ Infrastructure deployed!"
echo ""
echo "🌐 Access points:"
echo "   Nginx HTTP:  http://$(hostname -I | awk '{print $1}'):8080"
echo "   Nginx HTTPS: https://$(hostname -I | awk '{print $1}'):8443"
echo "   MariaDB:     mysql://localhost:3306"
echo ""
echo "🔍 Check status:"
echo "   podman-compose -f infra-compose.yml ps"
echo "   podman-compose -f infra-compose.yml logs"