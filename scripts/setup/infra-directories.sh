#!/bin/bash
# ~/projects/rw_deploy/scripts/setup/infra-directories.sh

echo "📁 Setting up Rock Willow directories..."

# Create directories on external drive (via symlinks)
mkdir -p ${HOME}/projects/rw_deploy/{nginx/conf.d,nginx/ssl,nginx/html,db,scripts,configs}
mkdir -p ${HOME}/data/{mariadb,logs/{nginx,mariadb},backups}


# Create Log Files if they don't exist.
touch ${HOME}/data/nginx/logs/rockwillow-access.log
touch ${HOME}/data/nginx/logs/rockwillow-error.log
touch ${HOME}/data/nginx/logs/rockwillow-ssl-access.log
touch ${HOME}/data/nginx/logs/rockwillow-ssl-error.log
touch ${HOME}/data/nginx/logs/api-access.log
touch ${HOME}/data/nginx/logs/app-access.log

# Set permissions for Podman rootless
echo "🔐 Setting Podman permissions..."

# MariaDB needs mysql user (999) ownership via podman unshare
if command -v podman &> /dev/null; then
  podman unshare chown -R 999:999 ${HOME}/data/mariadb 2>/dev/null || true
  podman unshare chown -R 101:101 ${HOME}/data/logs/nginx 2>/dev/null || true
else
  echo "⚠️  Podman not found, setting basic permissions"
  chmod 755 ${HOME}/data/mariadb
  chmod 755 ${HOME}/data/logs/nginx
fi

# Create minimal Nginx config if missing
if [ ! -f ${HOME}/projects/rw_deploy/nginx/conf.d/app.conf ]; then
  cat > ${HOME}/projects/rw_deploy/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        return 200 'Rock Willow Infrastructure Ready\n';
        add_header Content-Type text/plain;
    }
    
    location /health {
        return 200 'healthy\n';
        add_header Content-Type text/plain;
        access_log off;
    }
}
EOF
  echo "✅ Created default Nginx config"
fi

# Create db init script if missing
if [ ! -f ${HOME}/projects/rw_deploy/db/init.sql ]; then
  cat > ${HOME}/projects/rw_deploy/db/init.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS rw_budget_dev;
EOF
  echo "✅ Created database initialization script"
fi

echo "✅ Directory setup complete!"
echo ""
echo "📋 Path summary:"
echo "   Config: ${HOME}/projects/rw_deploy/"
echo "   Data:   ${HOME}/data/"
echo "   Logs:   ${HOME}/data/logs/"