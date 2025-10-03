#!/bin/bash

# FlirrtAI Parallel Testing Setup Script
# Sets up Git worktrees and environment for parallel agent testing

set -e

echo "🚀 FlirrtAI Parallel Testing Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PARALLEL_DIR="$BASE_DIR/parallel-tests"

# Create directory structure
echo -e "\n${YELLOW}📁 Creating directory structure...${NC}"
mkdir -p "$PARALLEL_DIR"/{ui,api,perf,logs,reports}

# Function to create worktree
create_worktree() {
    local agent_id=$1
    local branch_name=$2
    local worktree_path="$PARALLEL_DIR/$agent_id"

    # Remove existing worktree if it exists
    if [ -d "$worktree_path" ]; then
        echo -e "  ${YELLOW}Removing existing worktree: $agent_id${NC}"
        git worktree remove "$worktree_path" --force 2>/dev/null || true
    fi

    # Create new worktree
    echo -e "  ${GREEN}Creating worktree: $agent_id → $branch_name${NC}"
    git worktree add -b "$branch_name" "$worktree_path" 2>/dev/null || \
    git worktree add "$worktree_path" "$branch_name" 2>/dev/null || \
    (git branch -D "$branch_name" 2>/dev/null; git worktree add -b "$branch_name" "$worktree_path")

    # Initialize the worktree
    cd "$worktree_path"

    # For iOS worktrees, ensure dependencies are set up
    if [[ "$agent_id" == ui-* ]] || [[ "$agent_id" == perf-* ]]; then
        if [ -f "iOS/Package.swift" ]; then
            cd iOS
            swift package resolve 2>/dev/null || true
            cd ..
        fi
    fi

    # For API worktrees, ensure npm dependencies
    if [[ "$agent_id" == api-* ]]; then
        if [ -f "Backend/package.json" ]; then
            cd Backend
            npm install --silent 2>/dev/null || true
            cd ..
        fi
    fi

    cd "$BASE_DIR"
}

# Set up Git worktrees for each agent
echo -e "\n${YELLOW}🌳 Setting up Git worktrees...${NC}"

# UI Agents
create_worktree "ui-1" "ui/keyboard"
create_worktree "ui-2" "ui/voice"
create_worktree "ui-3" "ui/onboarding"
create_worktree "ui-4" "ui/screenshot"

# API Agents
create_worktree "api-1" "api/auth"
create_worktree "api-2" "api/ai"
create_worktree "api-3" "api/validation"

# Performance Agents
create_worktree "perf-1" "perf/memory"
create_worktree "perf-2" "perf/network"

# Install orchestrator dependencies
echo -e "\n${YELLOW}📦 Installing orchestrator dependencies...${NC}"
cd "$BASE_DIR"

# Create package.json if it doesn't exist
if [ ! -f "package.json" ]; then
    cat > package.json << 'EOF'
{
  "name": "flirrtai-orchestrator",
  "version": "1.0.0",
  "description": "FlirrtAI Parallel Testing Orchestrator",
  "main": "orchestrator.js",
  "scripts": {
    "start": "node orchestrator.js",
    "monitor": "bash monitor.sh",
    "dashboard": "open http://localhost:8080"
  },
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.14.2",
    "axios": "^1.5.1"
  }
}
EOF
fi

npm install --silent

# Create monitoring script
echo -e "\n${YELLOW}📊 Creating monitoring script...${NC}"
cat > monitor.sh << 'EOF'
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
EOF

chmod +x monitor.sh

# Create dashboard HTML
echo -e "\n${YELLOW}🎨 Creating web dashboard...${NC}"
mkdir -p dashboard
cat > dashboard/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FlirrtAI Parallel Testing Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        h1 {
            color: white;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }

        .metrics {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }

        .metric-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            text-align: center;
        }

        .metric-value {
            font-size: 3em;
            font-weight: bold;
            color: #667eea;
        }

        .metric-label {
            color: #666;
            margin-top: 10px;
        }

        .agents-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }

        .agent-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }

        .agent-card:hover {
            transform: translateY(-5px);
        }

        .agent-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .agent-id {
            font-weight: bold;
            color: #333;
        }

        .agent-status {
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }

        .status-pending {
            background: #f0f0f0;
            color: #666;
        }

        .status-running {
            background: #fff3cd;
            color: #856404;
            animation: pulse 2s infinite;
        }

        .status-passed, .status-fixed {
            background: #d4edda;
            color: #155724;
        }

        .status-failed {
            background: #f8d7da;
            color: #721c24;
        }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
        }

        .agent-focus {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 10px;
        }

        .progress-bar {
            width: 100%;
            height: 10px;
            background: #f0f0f0;
            border-radius: 5px;
            overflow: hidden;
            margin-top: 10px;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            transition: width 0.5s ease;
        }

        .convergence-section {
            background: white;
            border-radius: 10px;
            padding: 30px;
            margin-top: 30px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .convergence-button {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 15px 40px;
            border-radius: 50px;
            font-size: 1.1em;
            cursor: pointer;
            transition: transform 0.2s ease;
            margin-top: 20px;
        }

        .convergence-button:hover {
            transform: scale(1.05);
        }

        .convergence-button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .timer {
            font-size: 1.2em;
            color: #666;
            margin-top: 20px;
        }

        .perfection-indicator {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            margin: 20px auto;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 3em;
        }

        .perfection-pending {
            background: #f0f0f0;
        }

        .perfection-achieved {
            background: #d4edda;
            animation: celebrate 1s ease infinite;
        }

        @keyframes celebrate {
            0%, 100% { transform: scale(1) rotate(0deg); }
            25% { transform: scale(1.1) rotate(5deg); }
            75% { transform: scale(1.1) rotate(-5deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 FlirrtAI Parallel Testing Dashboard</h1>

        <div class="metrics">
            <div class="metric-card">
                <div class="metric-value" id="total-agents">9</div>
                <div class="metric-label">Total Agents</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" id="passed-count">0</div>
                <div class="metric-label">Tests Passed</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" id="elapsed-time">00:00</div>
                <div class="metric-label">Elapsed Time</div>
            </div>
        </div>

        <div class="agents-grid" id="agents-grid">
            <!-- Agent cards will be dynamically inserted here -->
        </div>

        <div class="convergence-section">
            <h2>Master Branch Convergence</h2>
            <div class="perfection-indicator perfection-pending" id="perfection-indicator">
                ⏳
            </div>
            <div id="convergence-status">Waiting for all tests to pass...</div>
            <button class="convergence-button" id="convergence-button" onclick="convergeToMaster()" disabled>
                Converge to Master
            </button>
            <div class="timer" id="timer">Target: Under 4 hours</div>
        </div>
    </div>

    <script>
        let ws;
        let startTime;
        let timerInterval;

        function connectWebSocket() {
            ws = new WebSocket('ws://localhost:8080');

            ws.onopen = () => {
                console.log('Connected to orchestrator');
            };

            ws.onmessage = (event) => {
                const data = JSON.parse(event.data);
                updateDashboard(data);
            };

            ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };

            ws.onclose = () => {
                console.log('Disconnected from orchestrator');
                setTimeout(connectWebSocket, 5000); // Reconnect after 5 seconds
            };
        }

        function updateDashboard(data) {
            if (data.event === 'start') {
                startTime = data.timestamp;
                startTimer();
            }

            // Update status from API
            if (data.agents) {
                updateAgents(data.agents);
                updateMetrics(data);
                checkPerfection(data.perfectionAchieved);
            }

            // Handle real-time events
            if (data.event === 'agent-start' || data.event === 'agent-complete') {
                fetchStatus();
            }
        }

        function updateAgents(agents) {
            const grid = document.getElementById('agents-grid');
            grid.innerHTML = '';

            agents.forEach(agent => {
                const card = document.createElement('div');
                card.className = 'agent-card';
                card.innerHTML = `
                    <div class="agent-header">
                        <span class="agent-id">${agent.id.toUpperCase()}</span>
                        <span class="agent-status status-${agent.status}">${agent.status}</span>
                    </div>
                    <div class="agent-focus">Focus: ${agent.focus.replace(/-/g, ' ')}</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${getProgress(agent)}%"></div>
                    </div>
                `;
                grid.appendChild(card);
            });
        }

        function getProgress(agent) {
            switch(agent.status) {
                case 'pending': return 0;
                case 'running': return 50;
                case 'passed':
                case 'fixed': return 100;
                case 'failed': return 75;
                default: return 0;
            }
        }

        function updateMetrics(data) {
            const passedCount = data.agents.filter(a =>
                a.status === 'passed' || a.status === 'fixed'
            ).length;

            document.getElementById('passed-count').textContent = passedCount;
        }

        function checkPerfection(achieved) {
            const indicator = document.getElementById('perfection-indicator');
            const status = document.getElementById('convergence-status');
            const button = document.getElementById('convergence-button');

            if (achieved) {
                indicator.className = 'perfection-indicator perfection-achieved';
                indicator.textContent = '🎉';
                status.textContent = 'All tests passed! Ready to converge.';
                button.disabled = false;
            } else {
                indicator.className = 'perfection-indicator perfection-pending';
                indicator.textContent = '⏳';
                status.textContent = 'Waiting for all tests to pass...';
                button.disabled = true;
            }
        }

        function startTimer() {
            timerInterval = setInterval(() => {
                const elapsed = Date.now() - startTime;
                const minutes = Math.floor(elapsed / 60000);
                const seconds = Math.floor((elapsed % 60000) / 1000);

                const timeString = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
                document.getElementById('elapsed-time').textContent = timeString;

                // Update timer message
                const hours = minutes / 60;
                if (hours < 4) {
                    document.getElementById('timer').textContent = `Target: Under 4 hours (${(4 - hours).toFixed(1)}h remaining)`;
                } else {
                    document.getElementById('timer').textContent = 'Target exceeded - Optimize agents!';
                }
            }, 1000);
        }

        async function convergeToMaster() {
            const response = await fetch('/api/master/converge', {
                method: 'POST'
            });
            const result = await response.json();

            if (result.merged) {
                alert(`Successfully merged ${result.merged} branches to master!`);
            }
        }

        async function fetchStatus() {
            try {
                const response = await fetch('/api/status');
                const data = await response.json();
                updateDashboard(data);
            } catch (error) {
                console.error('Failed to fetch status:', error);
            }
        }

        // Initialize
        connectWebSocket();
        fetchStatus();

        // Refresh status every 5 seconds
        setInterval(fetchStatus, 5000);
    </script>
</body>
</html>
EOF

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo -e "\n${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Start the backend server:"
echo -e "     ${GREEN}cd Backend && npm start${NC}"
echo -e ""
echo -e "  2. Run the orchestrator:"
echo -e "     ${GREEN}npm start${NC}"
echo -e ""
echo -e "  3. Open the dashboard:"
echo -e "     ${GREEN}open http://localhost:8080${NC}"
echo -e ""
echo -e "  4. Monitor progress:"
echo -e "     ${GREEN}./monitor.sh${NC}"
echo -e ""
echo -e "${YELLOW}🎯 Goal: Achieve perfection in under 4 hours!${NC}"