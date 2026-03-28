#!/bin/bash
# ~/projects/rw_deploy/scripts/deploy-infra.sh

set -e

echo "🚀 Deploying Rock Willow Infrastructure"
echo "======================================="

cd "$(dirname "$0")/../.."

# Check if podman-compose is available
if ! command -v podman-compose &> /dev/null; then
    echo "❌ podman-compose not found. Installing via apt..."
    
    # Try apt first
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y podman-compose
    else
        echo "❌ Could not install podman-compose. Please install manually:"
        echo "   sudo apt install podman-compose"
        exit 1
    fi
fi

# Load environment
if [ -f .env ]; then
    source .env
    echo "✅ Loaded environment variables"
else
    echo "⚠️  No .env file found, using defaults"
    # Set defaults for Podman
    export DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-ChangeMe123!}
fi

# Podman needs correct permissions for rootless containers
podman unshare chown -R 999:mysql ${HOME}/data/mariadb 2>/dev/null || true
podman unshare chown -R 101:101 ${HOME}/data/logs/nginx 2>/dev/null || true


echo "🔨 Building containers with Podman (using cache)..."
podman-compose -f infra-compose.yml build --pull

# Deploy infrastructure
echo "▶️  Starting Podman containers..."
podman-compose -f infra-compose.yml up -d

# Podman-specific: wait for containers to start
echo "⏳ Waiting for Podman containers to start..."
for i in {1..30}; do
    if podman-compose ps | grep -q "Up"; then
        break
    fi
    sleep 2
    echo -n "."
done
echo ""

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