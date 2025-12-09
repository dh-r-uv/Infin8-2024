#!/bin/bash
URL=${1:-"http://127.0.0.1"}

echo "Checking traffic distribution on $URL..."
echo "Press Ctrl+C to stop."

COUNT_STABLE=0
COUNT_CANARY=0

while true; do
    # Fetch response with status code (no silent mode to see errors)
    RESPONSE=$(curl -i "$URL" 2>&1)
    STATUS=$(echo "$RESPONSE" | grep "HTTP/" | awk '{print $2}')
    BODY=$(echo "$RESPONSE" | sed -n '/^\r$/,$p')
    
    # Check if curl failed (empty response)
    if [ -z "$RESPONSE" ]; then
         echo -e "${CYAN}[ERROR] Curl returned nothing. Is minikube tunnel running?${NC}"
         sleep 2
         continue
    fi

    if echo "$BODY" | grep -q "CANARY VERSION"; then
        echo -e "\033[0;33m[CANARY]\033[0m Hit Canary Pod! (Status: $STATUS)"
        ((COUNT_CANARY++))
    else
        echo -e "\033[0;36m[STABLE]\033[0m Hit Stable (or Error). Status: $STATUS"
        echo "Exerpt: $(echo "$BODY" | head -n 3)"
        ((COUNT_STABLE++))
    fi
    
    TOTAL=$((COUNT_STABLE + COUNT_CANARY))
    CANARY_PERCENT=$(( 100 * COUNT_CANARY / TOTAL ))
    
    echo "Stats: Stable=$COUNT_STABLE, Canary=$COUNT_CANARY ($CANARY_PERCENT%)"
    echo "----------------------------------------"
    
    sleep 1
done
