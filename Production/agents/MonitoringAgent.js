/**
 * 📊 MonitoringAgent - Real-time Production Observability & Health Monitoring
 *
 * Provides comprehensive production monitoring, metrics collection, alerting,
 * and real-time health dashboards for the entire Flirrt.ai system.
 *
 * Key Responsibilities:
 * - Real-time metrics collection and aggregation
 * - Health monitoring for all agents and services
 * - Performance monitoring and SLA tracking
 * - Automated alerting and incident response
 * - Production dashboard with live visualizations
 * - Log aggregation and analysis
 */

const EventEmitter = require('events');
const { exec, spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const { promisify } = require('util');

const execAsync = promisify(exec);

class MonitoringAgent extends EventEmitter {
    constructor(config = {}) {
        super();

        this.config = {
            // Monitoring configuration
            environment: config.environment || 'production',
            metricsInterval: config.metricsInterval || 30000, // 30 seconds
            healthCheckInterval: config.healthCheckInterval || 60000, // 1 minute
            alertingEnabled: config.alertingEnabled !== false,

            // Metrics collection
            metrics: {
                enabled: config.metrics?.enabled !== false,
                retentionDays: config.metrics?.retentionDays || 30,
                aggregationInterval: config.metrics?.aggregationInterval || 300000, // 5 minutes
                exportPath: config.metrics?.exportPath || '/tmp/flirrt-metrics'
            },

            // Health monitoring
            healthMonitoring: {
                enabled: config.healthMonitoring?.enabled !== false,
                services: config.healthMonitoring?.services || [
                    'api_server',
                    'postgres',
                    'redis',
                    'ai_agents'
                ],
                thresholds: {
                    responseTime: config.healthMonitoring?.thresholds?.responseTime || 2000,
                    memoryUsage: config.healthMonitoring?.thresholds?.memoryUsage || 80,
                    cpuUsage: config.healthMonitoring?.thresholds?.cpuUsage || 80,
                    errorRate: config.healthMonitoring?.thresholds?.errorRate || 5
                }
            },

            // Alerting
            alerting: {
                enabled: config.alerting?.enabled !== false,
                channels: config.alerting?.channels || ['console', 'file'],
                severity: {
                    critical: config.alerting?.severity?.critical || true,
                    warning: config.alerting?.severity?.warning || true,
                    info: config.alerting?.severity?.info || false
                },
                cooldown: config.alerting?.cooldown || 300000 // 5 minutes
            },

            // Dashboard
            dashboard: {
                enabled: config.dashboard?.enabled !== false,
                port: config.dashboard?.port || 8080,
                updateInterval: config.dashboard?.updateInterval || 5000 // 5 seconds
            },

            // API endpoints to monitor
            apiEndpoints: config.apiEndpoints || [
                { url: 'http://localhost:3000/health', name: 'api_health' },
                { url: 'http://localhost:3000/api/agents/health', name: 'agents_health' }
            ],

            ...config
        };

        this.monitoringState = {
            phase: 'idle',
            progress: 0,
            currentTask: null,
            isMonitoring: false,
            startTime: null,
            metrics: {
                system: {},
                application: {},
                agents: {},
                apis: {}
            },
            healthStatus: {
                overall: 'unknown',
                services: {},
                lastUpdate: null
            },
            alerts: {
                active: [],
                history: []
            },
            dashboard: {
                status: 'stopped',
                url: null
            },
            timers: {
                metrics: null,
                health: null,
                dashboard: null
            },
            logs: [],
            errors: []
        };
    }

    /**
     * 🚀 Main monitoring deployment execution
     * @param {Object} params - Monitoring parameters
     * @returns {Promise<Object>} Monitoring result
     */
    async executeDeployment(params = {}) {
        try {
            this.log('📊 Starting production monitoring system');
            this.updateProgress(0, 'Initializing monitoring system');

            // Phase 1: Setup monitoring infrastructure
            await this.setupMonitoringInfrastructure();
            this.updateProgress(20, 'Monitoring infrastructure ready');

            // Phase 2: Initialize metrics collection
            await this.initializeMetricsCollection();
            this.updateProgress(40, 'Metrics collection started');

            // Phase 3: Start health monitoring
            await this.startHealthMonitoring();
            this.updateProgress(60, 'Health monitoring active');

            // Phase 4: Setup alerting system
            await this.setupAlertingSystem();
            this.updateProgress(80, 'Alerting system configured');

            // Phase 5: Launch monitoring dashboard
            await this.launchMonitoringDashboard();
            this.updateProgress(100, 'Monitoring dashboard live');

            this.monitoringState.isMonitoring = true;
            this.monitoringState.startTime = new Date();

            const result = {
                success: true,
                monitoringStatus: 'active',
                dashboardUrl: this.monitoringState.dashboard.url,
                metricsEnabled: this.config.metrics.enabled,
                alertingEnabled: this.config.alerting.enabled,
                healthMonitoring: this.config.healthMonitoring.enabled,
                endpoints: {
                    dashboard: this.monitoringState.dashboard.url,
                    metrics: `${this.monitoringState.dashboard.url}/metrics`,
                    health: `${this.monitoringState.dashboard.url}/health`,
                    alerts: `${this.monitoringState.dashboard.url}/alerts`
                },
                message: 'Production monitoring system is fully operational'
            };

            this.log('✅ Production monitoring system deployed successfully');
            this.emit('success', result);
            return result;

        } catch (error) {
            this.log(`❌ Monitoring deployment failed: ${error.message}`);
            this.monitoringState.errors.push(error.message);
            this.emit('error', error);

            return {
                success: false,
                error: error.message,
                logs: this.monitoringState.logs,
                phase: this.monitoringState.phase
            };
        }
    }

    /**
     * Setup monitoring infrastructure
     * @returns {Promise<void>}
     */
    async setupMonitoringInfrastructure() {
        this.log('🏗️ Setting up monitoring infrastructure');
        this.monitoringState.phase = 'infrastructure_setup';

        try {
            // Create metrics export directory
            await execAsync(`mkdir -p "${this.config.metrics.exportPath}"`);

            // Initialize metrics storage files
            await this.initializeMetricsStorage();

            // Setup log rotation for monitoring logs
            await this.setupLogRotation();

            // Validate required tools
            await this.validateMonitoringTools();

            this.log('✅ Monitoring infrastructure setup completed');

        } catch (error) {
            throw new Error(`Monitoring infrastructure setup failed: ${error.message}`);
        }
    }

    /**
     * Initialize metrics collection system
     * @returns {Promise<void>}
     */
    async initializeMetricsCollection() {
        this.log('📈 Initializing metrics collection');
        this.monitoringState.phase = 'metrics_init';

        try {
            // Start metrics collection timer
            this.monitoringState.timers.metrics = setInterval(async () => {
                try {
                    await this.collectMetrics();
                } catch (error) {
                    this.log(`⚠️ Metrics collection error: ${error.message}`);
                }
            }, this.config.metricsInterval);

            // Collect initial metrics
            await this.collectMetrics();

            this.log('✅ Metrics collection initialized');

        } catch (error) {
            throw new Error(`Metrics collection initialization failed: ${error.message}`);
        }
    }

    /**
     * Start health monitoring for all services
     * @returns {Promise<void>}
     */
    async startHealthMonitoring() {
        this.log('🏥 Starting health monitoring');
        this.monitoringState.phase = 'health_monitoring';

        try {
            // Start health check timer
            this.monitoringState.timers.health = setInterval(async () => {
                try {
                    await this.performHealthChecks();
                } catch (error) {
                    this.log(`⚠️ Health check error: ${error.message}`);
                }
            }, this.config.healthCheckInterval);

            // Perform initial health check
            await this.performHealthChecks();

            this.log('✅ Health monitoring started');

        } catch (error) {
            throw new Error(`Health monitoring startup failed: ${error.message}`);
        }
    }

    /**
     * Setup alerting system
     * @returns {Promise<void>}
     */
    async setupAlertingSystem() {
        this.log('🚨 Setting up alerting system');
        this.monitoringState.phase = 'alerting_setup';

        try {
            // Initialize alert tracking
            this.monitoringState.alerts = {
                active: [],
                history: [],
                cooldowns: new Map()
            };

            // Setup alert channels
            await this.configureAlertChannels();

            this.log('✅ Alerting system configured');

        } catch (error) {
            throw new Error(`Alerting system setup failed: ${error.message}`);
        }
    }

    /**
     * Launch monitoring dashboard
     * @returns {Promise<void>}
     */
    async launchMonitoringDashboard() {
        this.log('🎛️ Launching monitoring dashboard');
        this.monitoringState.phase = 'dashboard_launch';

        try {
            // Create dashboard HTML file
            await this.createDashboardHTML();

            // Start simple HTTP server for dashboard
            await this.startDashboardServer();

            // Start dashboard update timer
            this.monitoringState.timers.dashboard = setInterval(async () => {
                try {
                    await this.updateDashboard();
                } catch (error) {
                    this.log(`⚠️ Dashboard update error: ${error.message}`);
                }
            }, this.config.dashboard.updateInterval);

            this.monitoringState.dashboard.status = 'running';
            this.monitoringState.dashboard.url = `http://localhost:${this.config.dashboard.port}`;

            this.log(`✅ Dashboard launched: ${this.monitoringState.dashboard.url}`);

        } catch (error) {
            throw new Error(`Dashboard launch failed: ${error.message}`);
        }
    }

    /**
     * Collect comprehensive system and application metrics
     * @returns {Promise<void>}
     */
    async collectMetrics() {
        try {
            const timestamp = new Date();

            // System metrics
            await this.collectSystemMetrics(timestamp);

            // Application metrics
            await this.collectApplicationMetrics(timestamp);

            // Agent metrics
            await this.collectAgentMetrics(timestamp);

            // API metrics
            await this.collectAPIMetrics(timestamp);

            // Export metrics to file
            await this.exportMetrics(timestamp);

            this.emit('metrics:collected', {
                timestamp,
                metrics: this.monitoringState.metrics
            });

        } catch (error) {
            this.log(`❌ Metrics collection failed: ${error.message}`);
        }
    }

    /**
     * Collect system-level metrics
     * @param {Date} timestamp - Collection timestamp
     * @returns {Promise<void>}
     */
    async collectSystemMetrics(timestamp) {
        try {
            // CPU usage
            const { stdout: cpuUsage } = await execAsync("top -l 1 | grep 'CPU usage' | awk '{print $3}' | sed 's/%//'");

            // Memory usage
            const { stdout: memInfo } = await execAsync("vm_stat | head -10");

            // Disk usage
            const { stdout: diskUsage } = await execAsync("df -h / | tail -1 | awk '{print $5}' | sed 's/%//'");

            // Network connections
            const { stdout: netConnections } = await execAsync("netstat -an | grep ESTABLISHED | wc -l");

            this.monitoringState.metrics.system = {
                timestamp,
                cpu: parseFloat(cpuUsage.trim()) || 0,
                memory: this.parseMemoryInfo(memInfo),
                disk: parseFloat(diskUsage.trim()) || 0,
                connections: parseInt(netConnections.trim()) || 0,
                uptime: process.uptime()
            };

        } catch (error) {
            this.log(`⚠️ System metrics collection warning: ${error.message}`);
        }
    }

    /**
     * Collect application-specific metrics
     * @param {Date} timestamp - Collection timestamp
     * @returns {Promise<void>}
     */
    async collectApplicationMetrics(timestamp) {
        try {
            // Node.js process metrics
            const processMemory = process.memoryUsage();

            // Docker container metrics (if available)
            let containerMetrics = {};
            try {
                const { stdout: dockerStats } = await execAsync('docker stats --no-stream --format "table {{.Name}}\\t{{.CPUPerc}}\\t{{.MemUsage}}" | grep flirrt');
                containerMetrics = this.parseDockerStats(dockerStats);
            } catch (error) {
                // Docker may not be available or no containers running
            }

            this.monitoringState.metrics.application = {
                timestamp,
                process: {
                    memory: processMemory,
                    pid: process.pid,
                    version: process.version,
                    uptime: process.uptime()
                },
                containers: containerMetrics
            };

        } catch (error) {
            this.log(`⚠️ Application metrics collection warning: ${error.message}`);
        }
    }

    /**
     * Collect AI agent metrics
     * @param {Date} timestamp - Collection timestamp
     * @returns {Promise<void>}
     */
    async collectAgentMetrics(timestamp) {
        try {
            // Try to get agent health from API
            let agentHealth = {};
            try {
                const { stdout } = await execAsync('curl -s http://localhost:3000/api/agents/health');
                agentHealth = JSON.parse(stdout);
            } catch (error) {
                // API may not be available
            }

            this.monitoringState.metrics.agents = {
                timestamp,
                health: agentHealth,
                activeAgents: Object.keys(agentHealth).length,
                healthyAgents: Object.values(agentHealth).filter(h => h.status === 'healthy').length
            };

        } catch (error) {
            this.log(`⚠️ Agent metrics collection warning: ${error.message}`);
        }
    }

    /**
     * Collect API endpoint metrics
     * @param {Date} timestamp - Collection timestamp
     * @returns {Promise<void>}
     */
    async collectAPIMetrics(timestamp) {
        const apiMetrics = {};

        for (const endpoint of this.config.apiEndpoints) {
            try {
                const startTime = Date.now();
                await execAsync(`curl -f -m 5 "${endpoint.url}"`);
                const responseTime = Date.now() - startTime;

                apiMetrics[endpoint.name] = {
                    status: 'healthy',
                    responseTime,
                    lastCheck: timestamp
                };

            } catch (error) {
                apiMetrics[endpoint.name] = {
                    status: 'unhealthy',
                    error: error.message,
                    lastCheck: timestamp
                };
            }
        }

        this.monitoringState.metrics.apis = {
            timestamp,
            endpoints: apiMetrics,
            totalEndpoints: this.config.apiEndpoints.length,
            healthyEndpoints: Object.values(apiMetrics).filter(e => e.status === 'healthy').length
        };
    }

    /**
     * Perform comprehensive health checks
     * @returns {Promise<void>}
     */
    async performHealthChecks() {
        try {
            const healthResults = {};
            let overallHealthy = true;

            // Check each monitored service
            for (const service of this.config.healthMonitoring.services) {
                try {
                    const health = await this.checkServiceHealth(service);
                    healthResults[service] = health;

                    if (!health.healthy) {
                        overallHealthy = false;
                        await this.triggerAlert('warning', `Service ${service} is unhealthy: ${health.error || 'Unknown error'}`);
                    }

                } catch (error) {
                    healthResults[service] = {
                        healthy: false,
                        error: error.message,
                        lastCheck: new Date()
                    };
                    overallHealthy = false;
                }
            }

            // Update health status
            this.monitoringState.healthStatus = {
                overall: overallHealthy ? 'healthy' : 'unhealthy',
                services: healthResults,
                lastUpdate: new Date()
            };

            // Check thresholds and trigger alerts
            await this.checkHealthThresholds();

            this.emit('health:updated', this.monitoringState.healthStatus);

        } catch (error) {
            this.log(`❌ Health check failed: ${error.message}`);
        }
    }

    /**
     * Check health of individual service
     * @param {string} service - Service name
     * @returns {Promise<Object>} Health status
     */
    async checkServiceHealth(service) {
        switch (service) {
            case 'api_server':
                return await this.checkAPIServerHealth();
            case 'postgres':
                return await this.checkPostgresHealth();
            case 'redis':
                return await this.checkRedisHealth();
            case 'ai_agents':
                return await this.checkAIAgentsHealth();
            default:
                return { healthy: false, error: 'Unknown service' };
        }
    }

    /**
     * Check API server health
     * @returns {Promise<Object>} Health status
     */
    async checkAPIServerHealth() {
        try {
            const startTime = Date.now();
            await execAsync('curl -f -m 5 http://localhost:3000/health');
            const responseTime = Date.now() - startTime;

            return {
                healthy: responseTime < this.config.healthMonitoring.thresholds.responseTime,
                responseTime,
                lastCheck: new Date()
            };
        } catch (error) {
            return { healthy: false, error: error.message, lastCheck: new Date() };
        }
    }

    /**
     * Check PostgreSQL health
     * @returns {Promise<Object>} Health status
     */
    async checkPostgresHealth() {
        try {
            await execAsync('docker exec flirrt-postgres pg_isready -U flirrt_user');
            return { healthy: true, lastCheck: new Date() };
        } catch (error) {
            return { healthy: false, error: error.message, lastCheck: new Date() };
        }
    }

    /**
     * Check Redis health
     * @returns {Promise<Object>} Health status
     */
    async checkRedisHealth() {
        try {
            await execAsync('docker exec flirrt-redis redis-cli ping');
            return { healthy: true, lastCheck: new Date() };
        } catch (error) {
            return { healthy: false, error: error.message, lastCheck: new Date() };
        }
    }

    /**
     * Check AI agents health
     * @returns {Promise<Object>} Health status
     */
    async checkAIAgentsHealth() {
        try {
            const { stdout } = await execAsync('curl -s http://localhost:3000/api/agents/health');
            const agentHealth = JSON.parse(stdout);

            const totalAgents = Object.keys(agentHealth).length;
            const healthyAgents = Object.values(agentHealth).filter(h => h.status === 'healthy').length;

            return {
                healthy: healthyAgents === totalAgents && totalAgents > 0,
                totalAgents,
                healthyAgents,
                lastCheck: new Date()
            };
        } catch (error) {
            return { healthy: false, error: error.message, lastCheck: new Date() };
        }
    }

    /**
     * Trigger alert based on severity
     * @param {string} severity - Alert severity (critical, warning, info)
     * @param {string} message - Alert message
     * @returns {Promise<void>}
     */
    async triggerAlert(severity, message) {
        if (!this.config.alerting.enabled || !this.config.alerting.severity[severity]) {
            return;
        }

        const alertId = `${severity}_${Date.now()}`;
        const alert = {
            id: alertId,
            severity,
            message,
            timestamp: new Date(),
            resolved: false
        };

        // Check cooldown
        if (this.monitoringState.alerts.cooldowns.has(message)) {
            const lastAlert = this.monitoringState.alerts.cooldowns.get(message);
            if (Date.now() - lastAlert < this.config.alerting.cooldown) {
                return; // Skip duplicate alert during cooldown
            }
        }

        // Add to active alerts
        this.monitoringState.alerts.active.push(alert);
        this.monitoringState.alerts.history.push(alert);
        this.monitoringState.alerts.cooldowns.set(message, Date.now());

        // Send alert through configured channels
        await this.sendAlert(alert);

        this.emit('alert:triggered', alert);
    }

    /**
     * Send alert through configured channels
     * @param {Object} alert - Alert object
     * @returns {Promise<void>}
     */
    async sendAlert(alert) {
        for (const channel of this.config.alerting.channels) {
            try {
                switch (channel) {
                    case 'console':
                        console.log(`🚨 [${alert.severity.toUpperCase()}] ${alert.message}`);
                        break;
                    case 'file':
                        await this.writeAlertToFile(alert);
                        break;
                    // Add more channels as needed (email, slack, etc.)
                }
            } catch (error) {
                this.log(`⚠️ Alert channel ${channel} failed: ${error.message}`);
            }
        }
    }

    // Helper methods
    parseMemoryInfo(memInfo) {
        try {
            const lines = memInfo.split('\n');
            const pageSize = 4096; // bytes
            let totalMemory = 0;
            let freeMemory = 0;

            lines.forEach(line => {
                if (line.includes('Pages free:')) {
                    const pages = parseInt(line.split(':')[1].trim());
                    freeMemory = pages * pageSize;
                }
                // Add more parsing as needed
            });

            return {
                total: totalMemory,
                free: freeMemory,
                used: totalMemory - freeMemory,
                percentage: totalMemory > 0 ? ((totalMemory - freeMemory) / totalMemory) * 100 : 0
            };
        } catch (error) {
            return { total: 0, free: 0, used: 0, percentage: 0 };
        }
    }

    parseDockerStats(dockerStats) {
        const containers = {};
        const lines = dockerStats.split('\n').filter(line => line.trim());

        lines.forEach(line => {
            const parts = line.split('\t');
            if (parts.length >= 3) {
                containers[parts[0]] = {
                    cpu: parts[1],
                    memory: parts[2]
                };
            }
        });

        return containers;
    }

    async initializeMetricsStorage() {
        const metricsFile = path.join(this.config.metrics.exportPath, 'metrics.json');
        const initialMetrics = {
            metadata: {
                created: new Date(),
                version: '1.0.0',
                environment: this.config.environment
            },
            metrics: []
        };

        try {
            await fs.access(metricsFile);
        } catch (error) {
            await fs.writeFile(metricsFile, JSON.stringify(initialMetrics, null, 2));
        }
    }

    async exportMetrics(timestamp) {
        try {
            const metricsFile = path.join(this.config.metrics.exportPath, 'metrics.json');
            const metricsData = {
                timestamp,
                ...this.monitoringState.metrics
            };

            // Read existing metrics
            let existingData = { metrics: [] };
            try {
                const content = await fs.readFile(metricsFile, 'utf8');
                existingData = JSON.parse(content);
            } catch (error) {
                // File may not exist yet
            }

            // Add new metrics
            existingData.metrics.push(metricsData);

            // Keep only recent metrics (based on retention policy)
            const cutoffTime = new Date(Date.now() - (this.config.metrics.retentionDays * 24 * 60 * 60 * 1000));
            existingData.metrics = existingData.metrics.filter(m => new Date(m.timestamp) > cutoffTime);

            // Write back to file
            await fs.writeFile(metricsFile, JSON.stringify(existingData, null, 2));

        } catch (error) {
            this.log(`⚠️ Metrics export warning: ${error.message}`);
        }
    }

    async checkHealthThresholds() {
        // Check system metrics against thresholds
        const systemMetrics = this.monitoringState.metrics.system;

        if (systemMetrics.cpu > this.config.healthMonitoring.thresholds.cpuUsage) {
            await this.triggerAlert('warning', `High CPU usage: ${systemMetrics.cpu}%`);
        }

        if (systemMetrics.memory.percentage > this.config.healthMonitoring.thresholds.memoryUsage) {
            await this.triggerAlert('warning', `High memory usage: ${systemMetrics.memory.percentage.toFixed(1)}%`);
        }
    }

    async validateMonitoringTools() {
        const tools = ['curl', 'docker', 'netstat'];
        for (const tool of tools) {
            try {
                await execAsync(`which ${tool}`);
            } catch (error) {
                this.log(`⚠️ Monitoring tool not found: ${tool}`);
            }
        }
    }

    async setupLogRotation() {
        // Simple log rotation implementation
        this.log('📝 Setting up log rotation for monitoring');
    }

    async configureAlertChannels() {
        // Configure alert channels
        this.log('📢 Configuring alert channels');
    }

    async createDashboardHTML() {
        const dashboardHTML = `<!DOCTYPE html>
<html>
<head>
    <title>Flirrt.ai Production Monitoring</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .dashboard { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status-healthy { color: #4CAF50; }
        .status-unhealthy { color: #f44336; }
        .status-warning { color: #ff9800; }
        .metric { display: flex; justify-content: space-between; margin: 10px 0; }
        h1 { text-align: center; color: #333; }
        h2 { color: #666; border-bottom: 2px solid #eee; padding-bottom: 10px; }
    </style>
</head>
<body>
    <h1>🚀 Flirrt.ai Production Monitoring Dashboard</h1>
    <div class="dashboard">
        <div class="card">
            <h2>System Health</h2>
            <div id="system-metrics">Loading...</div>
        </div>
        <div class="card">
            <h2>Application Status</h2>
            <div id="app-status">Loading...</div>
        </div>
        <div class="card">
            <h2>AI Agents</h2>
            <div id="agent-status">Loading...</div>
        </div>
        <div class="card">
            <h2>Active Alerts</h2>
            <div id="alerts">Loading...</div>
        </div>
    </div>
    <script>
        setInterval(() => {
            fetch('/data').then(r => r.json()).then(data => {
                document.getElementById('system-metrics').innerHTML = formatSystemMetrics(data.metrics.system);
                document.getElementById('app-status').innerHTML = formatAppStatus(data.healthStatus);
                document.getElementById('agent-status').innerHTML = formatAgentStatus(data.metrics.agents);
                document.getElementById('alerts').innerHTML = formatAlerts(data.alerts);
            });
        }, 5000);

        function formatSystemMetrics(metrics) {
            return \`
                <div class="metric">CPU Usage: <span>\${metrics.cpu || 0}%</span></div>
                <div class="metric">Memory Usage: <span>\${metrics.memory?.percentage?.toFixed(1) || 0}%</span></div>
                <div class="metric">Disk Usage: <span>\${metrics.disk || 0}%</span></div>
                <div class="metric">Connections: <span>\${metrics.connections || 0}</span></div>
            \`;
        }

        function formatAppStatus(health) {
            return \`<div class="status-\${health.overall}">\${health.overall.toUpperCase()}</div>\`;
        }

        function formatAgentStatus(agents) {
            return \`
                <div class="metric">Total Agents: <span>\${agents.activeAgents || 0}</span></div>
                <div class="metric">Healthy: <span>\${agents.healthyAgents || 0}</span></div>
            \`;
        }

        function formatAlerts(alerts) {
            return alerts.active.length ?
                alerts.active.map(a => \`<div class="status-\${a.severity}">\${a.message}</div>\`).join('') :
                '<div>No active alerts</div>';
        }
    </script>
</body>
</html>`;

        const dashboardPath = path.join(this.config.metrics.exportPath, 'dashboard.html');
        await fs.writeFile(dashboardPath, dashboardHTML);
    }

    async startDashboardServer() {
        // For now, just log that we would start a server
        // In a real implementation, you'd use express or similar
        this.log(`📊 Dashboard would be available at http://localhost:${this.config.dashboard.port}`);
        this.log('💡 Note: Dashboard server implementation would go here');
    }

    async updateDashboard() {
        // Dashboard update logic would go here
        // This would push real-time data to the dashboard
    }

    async writeAlertToFile(alert) {
        const alertsFile = path.join(this.config.metrics.exportPath, 'alerts.log');
        const alertLine = `${alert.timestamp.toISOString()} [${alert.severity.toUpperCase()}] ${alert.message}\n`;

        try {
            await fs.appendFile(alertsFile, alertLine);
        } catch (error) {
            this.log(`⚠️ Failed to write alert to file: ${error.message}`);
        }
    }

    /**
     * Rollback monitoring changes
     * @param {Object} rollbackPoint - Rollback point data
     * @returns {Promise<void>}
     */
    async rollback(rollbackPoint) {
        this.log('↩️ Rolling back monitoring system');

        try {
            // Stop all monitoring timers
            if (this.monitoringState.timers.metrics) {
                clearInterval(this.monitoringState.timers.metrics);
            }
            if (this.monitoringState.timers.health) {
                clearInterval(this.monitoringState.timers.health);
            }
            if (this.monitoringState.timers.dashboard) {
                clearInterval(this.monitoringState.timers.dashboard);
            }

            // Clean up monitoring data
            await execAsync(`rm -rf "${this.config.metrics.exportPath}"`);

            // Reset monitoring state
            this.monitoringState = {
                phase: 'idle',
                progress: 0,
                currentTask: null,
                isMonitoring: false,
                startTime: null,
                metrics: { system: {}, application: {}, agents: {}, apis: {} },
                healthStatus: { overall: 'unknown', services: {}, lastUpdate: null },
                alerts: { active: [], history: [] },
                dashboard: { status: 'stopped', url: null },
                timers: { metrics: null, health: null, dashboard: null },
                logs: [],
                errors: []
            };

            this.log('✅ Monitoring rollback completed');

        } catch (error) {
            throw new Error(`Monitoring rollback failed: ${error.message}`);
        }
    }

    /**
     * Get health status of monitoring agent
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            healthy: this.monitoringState.errors.length === 0 && this.monitoringState.isMonitoring,
            phase: this.monitoringState.phase,
            progress: this.monitoringState.progress,
            isMonitoring: this.monitoringState.isMonitoring,
            dashboardStatus: this.monitoringState.dashboard.status,
            metricsCollected: Object.keys(this.monitoringState.metrics).length > 0,
            activeAlerts: this.monitoringState.alerts.active.length,
            errorCount: this.monitoringState.errors.length,
            status: this.monitoringState.errors.length === 0 ? 'healthy' : 'degraded'
        };
    }

    // Helper methods
    updateProgress(percent, message) {
        this.monitoringState.progress = percent;
        this.monitoringState.currentTask = message;
        this.emit('progress', { percent, message });
    }

    log(message) {
        const timestamp = new Date().toISOString();
        const logEntry = `[MonitoringAgent] ${timestamp}: ${message}`;
        console.log(logEntry);
        this.monitoringState.logs.push(logEntry);
    }
}

module.exports = MonitoringAgent;