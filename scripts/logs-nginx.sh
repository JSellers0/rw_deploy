# ~/projects/rw_deploy/scripts/logs-nginx.sh
#!/bin/bash
echo "📋 Nginx Logs:"
echo "1. Access logs"
echo "2. Error logs" 
echo "3. SSL logs"
echo "4. API logs"
echo "5. Follow live"
echo -n "Choice: "
read choice

case $choice in
    1) tail -f ${HOME}/data/logs/nginx/rockwillow-access.log ;;
    2) tail -f ${HOME}/data/logs/nginx/rockwillow-error.log ;;
    3) tail -f ${HOME}/data/logs/nginx/rockwillow-ssl-access.log ;;
    4) tail -f ${HOME}/data/logs/nginx/api-access.log ;;
    5) tail -f ${HOME}/data/logs/nginx/*.log ;;
    *) echo "Invalid choice" ;;
esac