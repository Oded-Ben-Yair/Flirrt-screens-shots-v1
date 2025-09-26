#!/bin/bash

# FlirrtAI Continuous Monitoring Script

echo "🔍 FlirrtAI Test Monitor"
echo "========================"

API_BASE="http://localhost:8080/api"
INTERVAL=10

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_status() {
    local response=$(curl -s "$API_BASE/status")

    if [ -n "$response" ]; then
        echo -e "\n📊 Current Status:"
        echo "$response" | jq -r '.agents[] | "\(.id): \(.status)"' | while read line; do
            if [[ "$line" == *"passed"* ]] || [[ "$line" == *"fixed"* ]]; then
                echo -e "  ${GREEN}✅ $line${NC}"
            elif [[ "$line" == *"running"* ]]; then
                echo -e "  ${YELLOW}🔄 $line${NC}"
            elif [[ "$line" == *"failed"* ]]; then
                echo -e "  ${RED}❌ $line${NC}"
            else
                echo "  $line"
            fi
        done

        local perfection=$(echo "$response" | jq -r '.perfectionAchieved')
        if [ "$perfection" = "true" ]; then
            echo -e "\n${GREEN}🎉 PERFECTION ACHIEVED!${NC}"
            echo "Triggering master convergence..."
            curl -X POST "$API_BASE/master/converge" -s > /dev/null
            exit 0
        fi
    else
        echo -e "${RED}❌ Orchestrator not responding${NC}"
    fi
}

# Continuous monitoring loop
while true; do
    check_status

    # Check for failed agents and trigger auto-fix
    failed_agents=$(curl -s "$API_BASE/status" | jq -r '.agents[] | select(.status=="failed") | .id')

    for agent in $failed_agents; do
        echo -e "${YELLOW}🔧 Triggering auto-fix for $agent${NC}"
        curl -X POST "$API_BASE/agent/$agent/autofix" -s > /dev/null
    done

    sleep $INTERVAL
done
