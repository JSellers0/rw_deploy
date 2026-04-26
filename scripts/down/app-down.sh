#!/bin/bash
# ~/projects/rw_deploy/scripts/deploy-infra.sh


set -e

cd ~/projects/rw_deploy

echo " Tearing Down Rock Willow Applications"
echo "======================================="

podman-compose -f app-compose.yml stop 
podman rm rw_app_budget_api rw_app_budget