const { Pool } = require('pg');
const { logger, getLoggerHealth } = require('./logger');
const redisService = require('./redis');
const queueService = require('./queueService');
const webSocketService = require('./websocketService');
const circuitBreakerService = require('./circuitBreaker');

class HealthCheckService {
    constructor() {
        this.pool = null;
        this.healthHistory = [];
        this.maxHistorySize = 100;
        this.checks = {
            database: this.checkDatabase.bind(this),
            redis: this.checkRedis.bind(this),
            queues: this.checkQueues.bind(this),
            websocket: this.checkWebSocket.bind(this),
            circuitBreakers: this.checkCircuitBreakers.bind(this),
            externalApis: this.checkExternalApis.bind(this),
            system: this.checkSystem.bind(this),
            logger: this.checkLogger.bind(this)
        };

        this.initializeDatabase();
    }

    initializeDatabase() {
        try {
            this.pool = new Pool({
                host: process.env.DB_HOST,
                port: process.env.DB_PORT,
                database: process.env.DB_NAME,
                user: process.env.DB_USER,
                password: process.env.DB_PASSWORD,
            });
        } catch (error) {
            logger.error('Failed to initialize database pool for health checks:', error.message);
        }
    }

    async performHealthCheck(detailed = false, correlationId = null) {
        const startTime = Date.now();
        const timestamp = new Date().toISOString();

        logger.info('Health check started', { detailed, correlationId });

        const results = {
            status: 'healthy',
            timestamp,
            version: process.env.APP_VERSION || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            uptime: process.uptime(),
            correlationId,
            checks: {}
        };

        // Determine which checks to run
        const checksToRun = detailed ?
            Object.keys(this.checks) :
            ['database', 'system']; // Basic checks only

        // Run all health checks in parallel
        const checkPromises = checksToRun.map(async (checkName) => {
            try {
                const checkStart = Date.now();
                const result = await this.checks[checkName](correlationId);
                const duration = Date.now() - checkStart;

                return {
                    name: checkName,
                    result: {
                        ...result,
                        responseTime: `${duration}ms`
                    }
                };
            } catch (error) {
                logger.error(`Health check failed: ${checkName}`, {
                    error: error.message,
                    correlationId
                });

                return {
                    name: checkName,
                    result: {
                        status: 'error',
                        healthy: false,
                        error: error.message,
                        responseTime: 'timeout'
                    }
                };
            }
        });

        // Wait for all checks to complete
        const checkResults = await Promise.all(checkPromises);

        // Process results
        let overallHealthy = true;
        checkResults.forEach(({ name, result }) => {
            results.checks[name] = result;

            if (!result.healthy) {
                overallHealthy = false;
                if (result.status === 'critical') {
                    results.status = 'critical';
                } else if (results.status !== 'critical' && result.status === 'degraded') {
                    results.status = 'degraded';
                }
            }
        });

        if (!overallHealthy && results.status === 'healthy') {
            results.status = 'degraded';
        }

        // Add performance metrics
        const totalDuration = Date.now() - startTime;
        results.performanceMetrics = {
            totalCheckTime: `${totalDuration}ms`,
            checksPerformed: checkResults.length,
            parallelExecution: true
        };

        // Store in history
        this.addToHistory({
            timestamp,
            status: results.status,
            duration: totalDuration,
            checksPerformed: checkResults.length,
            correlationId
        });

        logger.info('Health check completed', {
            status: results.status,
            duration: `${totalDuration}ms`,
            checksPerformed: checkResults.length,
            correlationId
        });

        return results;
    }

    async checkDatabase(correlationId) {
        if (!this.pool) {
            return {
                status: 'error',
                healthy: false,
                error: 'Database pool not initialized'
            };
        }

        try {
            const start = Date.now();

            // Test basic connectivity
            const client = await this.pool.connect();
            const connectTime = Date.now() - start;

            try {
                // Test query execution
                const queryStart = Date.now();
                await client.query('SELECT 1 as test, NOW() as current_time');
                const queryTime = Date.now() - queryStart;

                // Get connection pool stats
                const poolStats = {
                    totalCount: this.pool.totalCount,
                    idleCount: this.pool.idleCount,
                    waitingCount: this.pool.waitingCount
                };

                return {
                    status: 'healthy',
                    healthy: true,
                    metrics: {
                        connectTime: `${connectTime}ms`,
                        queryTime: `${queryTime}ms`,
                        pool: poolStats
                    }
                };

            } finally {
                client.release();
            }

        } catch (error) {
            const isConnectionError = error.code === 'ECONNREFUSED' ||
                                    error.code === 'ENOTFOUND' ||
                                    error.code === 'ECONNRESET';

            return {
                status: isConnectionError ? 'critical' : 'degraded',
                healthy: false,
                error: error.message,
                errorCode: error.code
            };
        }
    }

    async checkRedis(correlationId) {
        try {
            const result = await redisService.healthCheck();

            return {
                status: result.connected ? 'healthy' : 'degraded',
                healthy: result.connected,
                metrics: {
                    connected: result.connected,
                    responseTime: result.responseTime || 'N/A',
                    connectionAttempts: result.connectionAttempts || 0
                },
                ...(result.error && { error: result.error })
            };

        } catch (error) {
            return {
                status: 'degraded', // Redis is optional
                healthy: false,
                error: error.message
            };
        }
    }

    async checkQueues(correlationId) {
        try {
            const health = await queueService.getHealthStatus();
            const isHealthy = health.status === 'healthy';

            return {
                status: health.status,
                healthy: isHealthy,
                mode: health.mode,
                metrics: {
                    initialized: health.initialized,
                    queues: health.queues,
                    totalJobs: health.totalJobs || 0,
                    failedJobs: health.failedJobs || 0
                },
                ...(health.stats && { queueStats: health.stats }),
                ...(health.error && { error: health.error }),
                ...(health.message && { message: health.message })
            };

        } catch (error) {
            return {
                status: 'degraded', // Queues degrade to immediate execution
                healthy: false,
                error: error.message
            };
        }
    }

    async checkWebSocket(correlationId) {
        try {
            const health = webSocketService.getHealthStatus();
            const isHealthy = health.status === 'online';

            return {
                status: isHealthy ? 'healthy' : 'degraded',
                healthy: isHealthy,
                metrics: {
                    status: health.status,
                    connections: health.connections,
                    users: health.users
                },
                ...(health.metrics && { performanceMetrics: health.metrics }),
                ...(health.message && { message: health.message })
            };

        } catch (error) {
            return {
                status: 'degraded', // WebSocket is not critical for basic functionality
                healthy: false,
                error: error.message
            };
        }
    }

    async checkCircuitBreakers(correlationId) {
        try {
            const health = circuitBreakerService.getHealthStatus();
            const isHealthy = health.status === 'healthy';

            return {
                status: health.status,
                healthy: isHealthy,
                metrics: {
                    breakerCount: Object.keys(health.breakers).length,
                    breakers: health.breakers
                }
            };

        } catch (error) {
            return {
                status: 'degraded',
                healthy: false,
                error: error.message
            };
        }
    }

    async checkExternalApis(correlationId) {
        const apis = {
            grok: !!process.env.GROK_API_KEY,
            elevenlabs: !!process.env.ELEVENLABS_API_KEY
        };

        const configuredApis = Object.entries(apis).filter(([_, configured]) => configured);
        const missingApis = Object.entries(apis).filter(([_, configured]) => !configured);

        // Basic configuration check - not testing actual connectivity to avoid costs
        const status = configuredApis.length > 0 ? 'healthy' : 'degraded';

        return {
            status,
            healthy: configuredApis.length > 0,
            metrics: {
                configured: configuredApis.map(([name]) => name),
                missing: missingApis.map(([name]) => name),
                totalConfigured: configuredApis.length,
                totalRequired: Object.keys(apis).length
            },
            note: 'Configuration check only - not testing actual API connectivity'
        };
    }

    async checkSystem(correlationId) {
        try {
            const memUsage = process.memoryUsage();
            const cpuUsage = process.cpuUsage();

            // Convert memory usage to MB
            const memoryMetrics = {
                rss: Math.round(memUsage.rss / 1024 / 1024),
                heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
                heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
                external: Math.round(memUsage.external / 1024 / 1024)
            };

            // Check for memory issues
            const heapUsagePercent = (memUsage.heapUsed / memUsage.heapTotal) * 100;
            const memoryStatus = heapUsagePercent > 90 ? 'critical' :
                               heapUsagePercent > 75 ? 'degraded' : 'healthy';

            return {
                status: memoryStatus,
                healthy: memoryStatus === 'healthy',
                metrics: {
                    uptime: Math.round(process.uptime()),
                    memory: memoryMetrics,
                    memoryUsagePercent: Math.round(heapUsagePercent),
                    nodeVersion: process.version,
                    platform: process.platform,
                    pid: process.pid
                }
            };

        } catch (error) {
            return {
                status: 'error',
                healthy: false,
                error: error.message
            };
        }
    }

    async checkLogger(correlationId) {
        try {
            const health = getLoggerHealth();

            return {
                status: health.status === 'healthy' ? 'healthy' : 'degraded',
                healthy: health.status === 'healthy',
                metrics: {
                    logLevel: health.logLevel,
                    logDirectory: health.logDirectory,
                    files: health.files
                },
                ...(health.error && { error: health.error })
            };

        } catch (error) {
            return {
                status: 'degraded',
                healthy: false,
                error: error.message
            };
        }
    }

    addToHistory(entry) {
        this.healthHistory.push(entry);

        // Keep only the most recent entries
        if (this.healthHistory.length > this.maxHistorySize) {
            this.healthHistory = this.healthHistory.slice(-this.maxHistorySize);
        }
    }

    getHealthHistory(limit = 10) {
        return this.healthHistory
            .slice(-limit)
            .reverse(); // Most recent first
    }

    getHealthTrends() {
        const recentHistory = this.healthHistory.slice(-20); // Last 20 checks

        if (recentHistory.length === 0) {
            return {
                trend: 'unknown',
                averageResponseTime: null,
                successRate: null,
                recentChecks: 0
            };
        }

        const totalChecks = recentHistory.length;
        const healthyChecks = recentHistory.filter(h => h.status === 'healthy').length;
        const averageResponseTime = Math.round(
            recentHistory.reduce((sum, h) => sum + h.duration, 0) / totalChecks
        );

        const successRate = Math.round((healthyChecks / totalChecks) * 100);

        // Determine trend
        let trend = 'stable';
        if (recentHistory.length >= 5) {
            const recent5 = recentHistory.slice(-5);
            const older5 = recentHistory.slice(-10, -5);

            if (older5.length === 5) {
                const recentHealthy = recent5.filter(h => h.status === 'healthy').length;
                const olderHealthy = older5.filter(h => h.status === 'healthy').length;

                if (recentHealthy > olderHealthy) {
                    trend = 'improving';
                } else if (recentHealthy < olderHealthy) {
                    trend = 'degrading';
                }
            }
        }

        return {
            trend,
            averageResponseTime,
            successRate,
            recentChecks: totalChecks,
            healthyChecks,
            degradedChecks: recentHistory.filter(h => h.status === 'degraded').length,
            criticalChecks: recentHistory.filter(h => h.status === 'critical').length
        };
    }

    // Quick health check for load balancers
    async quickCheck() {
        try {
            // Just check if the service is responding
            const systemCheck = await this.checkSystem();

            return {
                status: systemCheck.healthy ? 'healthy' : 'unhealthy',
                timestamp: new Date().toISOString(),
                uptime: process.uptime()
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                timestamp: new Date().toISOString(),
                error: error.message
            };
        }
    }

    // Readiness check for Kubernetes
    async readinessCheck() {
        try {
            // Check critical dependencies
            const [dbCheck, systemCheck] = await Promise.all([
                this.checkDatabase(),
                this.checkSystem()
            ]);

            const ready = dbCheck.healthy && systemCheck.healthy;

            return {
                status: ready ? 'ready' : 'not_ready',
                timestamp: new Date().toISOString(),
                checks: {
                    database: dbCheck.healthy,
                    system: systemCheck.healthy
                }
            };
        } catch (error) {
            return {
                status: 'not_ready',
                timestamp: new Date().toISOString(),
                error: error.message
            };
        }
    }

    // Liveness check for Kubernetes
    async livenessCheck() {
        // Simple check - if we can respond, we're alive
        return {
            status: 'alive',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            pid: process.pid
        };
    }
}

// Export singleton instance
const healthCheckService = new HealthCheckService();

module.exports = healthCheckService;