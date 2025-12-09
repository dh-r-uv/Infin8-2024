#!/bin/bash
URL=${1:-"http://localhost:8081"}

echo "Checking traffic distribution on $URL..."
echo "Press Ctrl+C to stop."

COUNT_STABLE=0
COUNT_CANARY=0

while true; do
    # Curl the page and look for the Canary Banner text
    RESPONSE=$(curl -s "$URL")
    
    if echo "$RESPONSE" | grep -q "CANARY VERSION"; then
        echo -e "\033[0;33m[CANARY]\033[0m Hit Canary Pod!"
        ((COUNT_CANARY++))
    else
        echo -e "\033[0;36m[STABLE]\033[0m Hit Stable Pod."
        ((COUNT_STABLE++))
    fi
    
    TOTAL=$((COUNT_STABLE + COUNT_CANARY))
    CANARY_PERCENT=$(( 100 * COUNT_CANARY / TOTAL ))
    
    echo "Stats: Stable=$COUNT_STABLE, Canary=$COUNT_CANARY ($CANARY_PERCENT%)"
    echo "----------------------------------------"
    
    sleep 1
done
