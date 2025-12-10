#!/bin/bash

#############################################################################
# Automated Canary Analysis & Promotion Script
# 
# This script demonstrates AIOps by:
# 1. Monitoring canary deployment health
# 2. Making intelligent promotion/rollback decisions
# 3. Executing actions automatically
#############################################################################

set -e

# Configuration
CANARY_IMAGE="${1:-dhruvk321/infin8:v1.1}"
STABLE_IMAGE="${2:-dhruvk321/infin8:latest}"
MONITOR_DURATION=60  # Monitor for 60 seconds
CHECK_INTERVAL=5     # Check every 5 seconds
ERROR_THRESHOLD=10   # Max 10% error rate

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🤖 Automated Canary Deployment System${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

#############################################################################
# Step 1: Deploy Canary
#############################################################################
echo -e "${YELLOW}[STEP 1] Deploying Canary Version...${NC}"
echo "Canary Image: $CANARY_IMAGE"
echo "Stable Image: $STABLE_IMAGE"
echo ""

kubectl set image deployment/infin8-canary infin8-app=$CANARY_IMAGE

echo "⏳ Waiting for Canary rollout to complete..."
if ! kubectl rollout status deployment/infin8-canary --timeout=300s; then
    echo -e "${RED}❌ Canary deployment failed!${NC}"
    echo "Checking pod status..."
    kubectl get pods -l app=infin8-app,track=canary
    kubectl describe pods -l app=infin8-app,track=canary | grep -A 10 "Events:"
    echo ""
    echo "Common issues:"
    echo "1. Image doesn't exist - run './build_canary_image.sh' first"
    echo "2. Image pull error - check Docker Hub credentials"
    echo "3. Application crash - check logs with 'kubectl logs -l track=canary'"
    exit 1
fi

echo -e "${GREEN}✅ Canary deployed successfully${NC}"
echo ""

#############################################################################
# Step 2: Monitor Canary Health
#############################################################################
echo -e "${YELLOW}[STEP 2] Monitoring Canary Health for ${MONITOR_DURATION}s...${NC}"
echo ""

TOTAL_CHECKS=0
SUCCESS_COUNT=0
ERROR_COUNT=0
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -ge $MONITOR_DURATION ]; then
        break
    fi
    
    # Check 1: HTTP Health Check
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/login/ 2>/dev/null || echo "000")
    
    # Check 2: Pod Readiness
    CANARY_READY=$(kubectl get deployment infin8-canary -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    CANARY_DESIRED=$(kubectl get deployment infin8-canary -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$HTTP_STATUS" = "200" ] && [ "$CANARY_READY" = "$CANARY_DESIRED" ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        STATUS_ICON="✅"
        STATUS_TEXT="${GREEN}HEALTHY${NC}"
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        STATUS_ICON="❌"
        STATUS_TEXT="${RED}UNHEALTHY${NC}"
    fi
    
    ERROR_RATE=$((ERROR_COUNT * 100 / TOTAL_CHECKS))
    REMAINING=$((MONITOR_DURATION - ELAPSED))
    
    echo -e "[${ELAPSED}s/$MONITOR_DURATION s] $STATUS_ICON HTTP:$HTTP_STATUS Ready:$CANARY_READY/$CANARY_DESIRED | Error Rate: ${ERROR_RATE}% | Status: $STATUS_TEXT | Remaining: ${REMAINING}s"
    
    sleep $CHECK_INTERVAL
done

echo ""
echo -e "${BLUE}📊 Monitoring Complete${NC}"
echo "Total Checks: $TOTAL_CHECKS"
echo "Successful: $SUCCESS_COUNT"
echo "Failed: $ERROR_COUNT"
ERROR_RATE=$((ERROR_COUNT * 100 / TOTAL_CHECKS))
echo "Error Rate: ${ERROR_RATE}%"
echo ""

#############################################################################
# Step 3: Intelligent Decision
#############################################################################
echo -e "${YELLOW}[STEP 3] Making Decision...${NC}"
echo ""

if [ $ERROR_RATE -le $ERROR_THRESHOLD ]; then
    DECISION="PROMOTE"
    echo -e "${GREEN}✅ DECISION: PROMOTE TO STABLE${NC}"
    echo "Reason: Error rate (${ERROR_RATE}%) is below threshold (${ERROR_THRESHOLD}%)"
    echo "Action: Rolling out new version to 100% of users"
else
    DECISION="ROLLBACK"
    echo -e "${RED}❌ DECISION: ROLLBACK${NC}"
    echo "Reason: Error rate (${ERROR_RATE}%) exceeds threshold (${ERROR_THRESHOLD}%)"
    echo "Action: Reverting Canary to stable version"
fi

echo ""

#############################################################################
# Step 4: Execute Decision
#############################################################################
echo -e "${YELLOW}[STEP 4] Executing: $DECISION${NC}"
echo ""

if [ "$DECISION" = "PROMOTE" ]; then
    echo "🚀 Promoting Canary to Stable..."
    echo "Updating deployment/infin8-app to: $CANARY_IMAGE"
    
    kubectl set image deployment/infin8-app infin8-app=$CANARY_IMAGE
    
    echo "⏳ Waiting for Stable rollout (may take a few minutes)..."
    kubectl rollout status deployment/infin8-app --timeout=300s
    
    echo ""
    echo -e "${GREEN}🎉 SUCCESS! New version promoted to 100% of users${NC}"
    echo ""
    echo "Verify by refreshing browser - all requests should now show new version"
    
else
    echo "🔄 Rolling back Canary to Stable version..."
    echo "Reverting deployment/infin8-canary to: $STABLE_IMAGE"
    
    kubectl set image deployment/infin8-canary infin8-app=$STABLE_IMAGE
    
    echo "⏳ Waiting for Canary rollback..."
    kubectl rollout status deployment/infin8-canary --timeout=120s
    
    echo ""
    echo -e "${GREEN}🛡️ ROLLBACK COMPLETE! Crisis averted${NC}"
    echo ""
    echo "All traffic now routed to stable version"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}✅ Automated Deployment Complete${NC}"
echo -e "${BLUE}========================================${NC}"
