#!/bin/bash
URL=${1:-"http://localhost:8081"}

echo "Checking connectivity to $URL..."
echo "Press Ctrl+C to stop."

while true; do
    # Get HTTP status code
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    
    # Get current time
    TIME=$(date +"%H:%M:%S")
    
    if [ "$STATUS" -eq 200 ]; then
        echo -e "[$TIME] \033[0;32mSUCCESS (200 OK)\033[0m - App is LIVE"
    else
        echo -e "[$TIME] \033[0;31mFAILURE ($STATUS)\033[0m - App is DOWN"
    fi
    
    sleep 0.5
done
