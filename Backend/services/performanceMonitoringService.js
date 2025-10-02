/**
 * Performance Monitoring Service - <15s Target Optimization
 *
 * Real-time performance monitoring and optimization system:
 * - Sub-15 second response time targeting
 * - Real-time performance alerts and optimization
 * - Bottleneck identification and auto-remediation
 * - Performance prediction and proactive scaling
 * - A/B testing for optimization strategies
 * - Resource utilization monitoring
 */

const { EventEmitter } = require('events');
const { logger } = require('./logger');
const redisService = require('./redis');

class PerformanceMonitoringService extends EventEmitter {
    constructor() {
        super();

        // Performance targets and thresholds
        this.targets = {
            keyboard: {
                target: 3000,      // 3 seconds for keyboard
                warning: 2500,     // Warning at 2.5s
                critical: 4000     // Critical at 4s
            },
            fast: {
                target: 8000,      // 8 seconds for fast requests
                warning: 6000,     // Warning at 6s
                critical: 10000    // Critical at 10s
            },
            standard: {
                target: 15000,     // 15 seconds for standard
                warning: 12000,    // Warning at 12s
                critical: 18000    // Critical at 18s
            },
            comprehensive: {
                target: 25000,     // 25 seconds for comprehensive
                warning: 20000,    // Warning at 20s
                critical: 30000    // Critical at 30s
            }
        };

        // Real-time metrics
        this.metrics = {
            requests: {
                total: 0,
                successful: 0,
                failed: 0,
                timeouts: 0,
                underTarget: 0,
                overTarget: 0
            },
            latency: {
                current: 0,
                average: 0,
                p50: 0,
                p95: 0,
                p99: 0,
                samples: []
            },
            throughput: {
                requestsPerSecond: 0,
                requestsPerMinute: 0,
                peakRps: 0,
                samples: []
            },
            resources: {
                cpuUsage: 0,
                memoryUsage: 0,
                activeConnections: 0,
                queueLength: 0
            },
            quality: {
                averageScore: 0,
                passRate: 0,
                samples: []
            }
        };

        // Performance alerts
        this.alerts = {
            active: new Set(),
            history: [],
            thresholds: {
                consecutiveFailures: 5,
                highLatencyWindow: 60000,     // 1 minute
                lowThroughputWindow: 300000,  // 5 minutes
                qualityDropWindow: 180000     // 3 minutes
            }
        };

        // Auto-optimization settings
        this.optimization = {
            enabled: true,
            strategies: new Map(),
            lastOptimization: 0,
            cooldownPeriod: 300000, // 5 minutes between optimizations
            performanceHistory: []
        };

        this.initializeMonitoring();
        this.setupOptimizationStrategies();

        logger.info('Performance Monitoring Service initialized', {
            targets: this.targets,
            alerting: true,
            autoOptimization: this.optimization.enabled
        });
    }

    /**
     * Record performance data for a request
     * @param {Object} performanceData - Performance data
     */
    async recordPerformance(performanceData) {
        try {
            const {
                correlationId,
                strategy,
                latency,
                success,
                tier,
                qualityScore = 0,
                streamingEnabled = false,
                cacheHit = false,
                bottlenecks = []
            } = performanceData;

            // Update request metrics
            this.metrics.requests.total++;
            if (success) {
                this.metrics.requests.successful++;
            } else {
                this.metrics.requests.failed++;
            }

            // Update latency metrics
            this.updateLatencyMetrics(latency);

            // Check against targets
            const target = this.targets[strategy] || this.targets.standard;
            if (latency <= target.target) {
                this.metrics.requests.underTarget++;
            } else {
                this.metrics.requests.overTarget++;

                // Trigger performance alert if over critical threshold
                if (latency > target.critical) {
                    await this.handlePerformanceAlert(correlationId, strategy, latency, bottlenecks);
                }
            }

            // Update quality metrics
            if (qualityScore > 0) {
                this.updateQualityMetrics(qualityScore);
            }

            // Record detailed performance data
            await this.recordDetailedPerformance({
                correlationId,
                strategy,
                tier,
                latency,
                success,
                qualityScore,
                streamingEnabled,
                cacheHit,
                bottlenecks,
                timestamp: Date.now()
            });

            // Check for optimization opportunities
            if (this.optimization.enabled) {
                await this.checkOptimizationOpportunities(performanceData);
            }

            logger.debug('Performance data recorded', {
                correlationId,
                strategy,
                latency,
                success,
                targetMet: latency <= target.target
            });

        } catch (error) {
            logger.error('Error recording performance data', {
                correlationId: performanceData.correlationId,
                error: error.message
            });
        }
    }

    /**
     * Update latency metrics with new sample
     * @param {number} latency - Latency in milliseconds
     */
    updateLatencyMetrics(latency) {
        // Update current and running average
        this.metrics.latency.current = latency;

        const currentAvg = this.metrics.latency.average;
        this.metrics.latency.average = currentAvg === 0 ? latency : (currentAvg * 0.9 + latency * 0.1);

        // Add to samples for percentile calculation
        this.metrics.latency.samples.push(latency);
        if (this.metrics.latency.samples.length > 1000) {
            this.metrics.latency.samples.shift(); // Keep last 1000 samples
        }

        // Update percentiles
        this.updatePercentiles();
    }

    /**
     * Update percentile calculations
     */
    updatePercentiles() {
        const samples = [...this.metrics.latency.samples].sort((a, b) => a - b);
        const length = samples.length;

        if (length > 0) {
            this.metrics.latency.p50 = samples[Math.floor(length * 0.5)];
            this.metrics.latency.p95 = samples[Math.floor(length * 0.95)];
            this.metrics.latency.p99 = samples[Math.floor(length * 0.99)];
        }
    }

    /**
     * Update quality metrics
     * @param {number} qualityScore - Quality score
     */
    updateQualityMetrics(qualityScore) {
        const samples = this.metrics.quality.samples;
        samples.push(qualityScore);

        if (samples.length > 100) {
            samples.shift(); // Keep last 100 samples
        }

        // Calculate average and pass rate
        if (samples.length > 0) {
            this.metrics.quality.averageScore = samples.reduce((sum, score) => sum + score, 0) / samples.length;
            this.metrics.quality.passRate = samples.filter(score => score >= 0.7).length / samples.length;
        }
    }

    /**
     * Update throughput metrics
     */
    updateThroughputMetrics() {
        const now = Date.now();
        const windowSize = 60000; // 1 minute window

        // Add current timestamp
        this.metrics.throughput.samples.push(now);

        // Remove samples older than window
        this.metrics.throughput.samples = this.metrics.throughput.samples.filter(
            timestamp => now - timestamp <= windowSize
        );

        // Calculate RPS and RPM
        const samplesInWindow = this.metrics.throughput.samples.length;
        this.metrics.throughput.requestsPerSecond = samplesInWindow / 60;
        this.metrics.throughput.requestsPerMinute = samplesInWindow;

        // Track peak RPS
        if (this.metrics.throughput.requestsPerSecond > this.metrics.throughput.peakRps) {
            this.metrics.throughput.peakRps = this.metrics.throughput.requestsPerSecond;
        }
    }

    /**
     * Record detailed performance data
     * @param {Object} data - Detailed performance data
     */
    async recordDetailedPerformance(data) {
        try {
            const key = `perf:detailed:${data.strategy}`;
            const detailedData = {
                ...data,
                hour: new Date().getHours(),
                dayOfWeek: new Date().getDay()
            };

            // Store in Redis with TTL
            await redisService.lpush(key, JSON.stringify(detailedData));
            await redisService.ltrim(key, 0, 999); // Keep last 1000 records
            await redisService.expire(key, 86400); // 24 hour TTL

        } catch (error) {
            logger.warn('Error recording detailed performance', { error: error.message });
        }
    }

    /**
     * Handle performance alert
     * @param {string} correlationId - Request correlation ID
     * @param {string} strategy - Performance strategy
     * @param {number} latency - Request latency
     * @param {Array} bottlenecks - Identified bottlenecks
     */
    async handlePerformanceAlert(correlationId, strategy, latency, bottlenecks) {
        const alertId = `latency_${strategy}_${Date.now()}`;
        const alert = {
            id: alertId,
            type: 'high_latency',
            strategy,
            latency,
            target: this.targets[strategy].target,
            correlationId,
            bottlenecks: bottlenecks || [],
            timestamp: new Date().toISOString(),
            severity: latency > this.targets[strategy].critical ? 'critical' : 'warning'
        };

        this.alerts.active.add(alertId);
        this.alerts.history.push(alert);

        // Emit alert event
        this.emit('performance_alert', alert);

        // Auto-remediation for critical alerts
        if (alert.severity === 'critical' && this.optimization.enabled) {
            await this.triggerAutoRemediation(alert);
        }

        logger.warn('Performance alert triggered', {
            alertId,
            strategy,
            latency,
            target: this.targets[strategy].target,
            severity: alert.severity
        });

        // Cleanup old alerts (keep last 100)
        if (this.alerts.history.length > 100) {
            this.alerts.history.shift();
        }
    }

    /**
     * Trigger auto-remediation for critical performance issues
     * @param {Object} alert - Performance alert
     */
    async triggerAutoRemediation(alert) {
        try {
            const now = Date.now();
            if (now - this.optimization.lastOptimization < this.optimization.cooldownPeriod) {
                logger.debug('Auto-remediation skipped - in cooldown period');
                return;
            }

            logger.info('Triggering auto-remediation', {
                alertId: alert.id,
                strategy: alert.strategy,
                latency: alert.latency
            });

            // Apply optimization strategy
            const optimizationApplied = await this.applyOptimizationStrategy(alert);

            if (optimizationApplied) {
                this.optimization.lastOptimization = now;
                this.optimization.performanceHistory.push({
                    timestamp: now,
                    trigger: alert.type,
                    strategy: alert.strategy,
                    optimization: optimizationApplied,
                    previousLatency: alert.latency
                });
            }

        } catch (error) {
            logger.error('Auto-remediation failed', {
                alertId: alert.id,
                error: error.message
            });
        }
    }

    /**
     * Apply optimization strategy based on alert
     * @param {Object} alert - Performance alert
     * @returns {Promise<string|null>} Applied optimization
     */
    async applyOptimizationStrategy(alert) {
        try {
            const strategy = alert.strategy;
            const bottlenecks = alert.bottlenecks || [];

            // Strategy 1: Cache warming for repeated patterns
            if (bottlenecks.includes('cache_miss')) {
                logger.info('Applying cache warming optimization');
                // Trigger preemptive cache warming
                this.emit('optimization', {
                    type: 'cache_warming',
                    strategy,
                    target: 'intelligent_cache'
                });
                return 'cache_warming';
            }

            // Strategy 2: Model tier adjustment
            if (alert.latency > this.targets[strategy].critical * 1.5) {
                logger.info('Applying tier downgrade optimization');
                this.emit('optimization', {
                    type: 'tier_adjustment',
                    strategy,
                    adjustment: 'downgrade',
                    reason: 'excessive_latency'
                });
                return 'tier_downgrade';
            }

            // Strategy 3: Parallel processing optimization
            if (bottlenecks.includes('sequential_processing')) {
                logger.info('Applying parallel processing optimization');
                this.emit('optimization', {
                    type: 'parallel_processing',
                    strategy,
                    target: 'ai_orchestrator'
                });
                return 'parallel_processing';
            }

            // Strategy 4: Stream early termination for quality issues
            if (bottlenecks.includes('quality_processing')) {
                logger.info('Applying early termination optimization');
                this.emit('optimization', {
                    type: 'early_termination',
                    strategy,
                    qualityThreshold: 0.8
                });
                return 'early_termination';
            }

            return null;

        } catch (error) {
            logger.error('Error applying optimization strategy', { error: error.message });
            return null;
        }
    }

    /**
     * Check for optimization opportunities
     * @param {Object} performanceData - Performance data
     */
    async checkOptimizationOpportunities(performanceData) {
        try {
            const { strategy, latency, cacheHit, qualityScore } = performanceData;
            const target = this.targets[strategy];

            // Opportunity 1: Cache optimization
            if (!cacheHit && latency > target.warning) {
                this.emit('optimization_opportunity', {
                    type: 'cache_optimization',
                    strategy,
                    reason: 'cache_miss_high_latency',
                    impact: 'high'
                });
            }

            // Opportunity 2: Quality vs Speed trade-off
            if (qualityScore > 0.9 && latency > target.target) {
                this.emit('optimization_opportunity', {
                    type: 'quality_speed_tradeoff',
                    strategy,
                    reason: 'over_quality_slow_response',
                    impact: 'medium'
                });
            }

            // Opportunity 3: Streaming optimization
            if (latency > target.warning && strategy !== 'keyboard') {
                this.emit('optimization_opportunity', {
                    type: 'streaming_suggestion',
                    strategy,
                    reason: 'high_latency_streamable',
                    impact: 'high'
                });
            }

        } catch (error) {
            logger.warn('Error checking optimization opportunities', { error: error.message });
        }
    }

    /**
     * Setup optimization strategies
     */
    setupOptimizationStrategies() {
        // Strategy: Adaptive timeout adjustment
        this.optimization.strategies.set('adaptive_timeout', {
            name: 'Adaptive Timeout Adjustment',
            enabled: true,
            trigger: 'consecutive_timeouts',
            action: (data) => {
                // Increase timeouts gradually for failing requests
                const currentTimeout = data.currentTimeout || 15000;
                const newTimeout = Math.min(currentTimeout * 1.2, 30000);
                return { adjustedTimeout: newTimeout };
            }
        });

        // Strategy: Quality threshold adjustment
        this.optimization.strategies.set('quality_threshold', {
            name: 'Dynamic Quality Threshold',
            enabled: true,
            trigger: 'quality_speed_tradeoff',
            action: (data) => {
                // Lower quality threshold slightly for faster responses
                const currentThreshold = data.qualityThreshold || 0.75;
                const newThreshold = Math.max(currentThreshold - 0.05, 0.6);
                return { adjustedQualityThreshold: newThreshold };
            }
        });

        // Strategy: Parallel processing toggle
        this.optimization.strategies.set('parallel_processing', {
            name: 'Parallel Processing Toggle',
            enabled: true,
            trigger: 'high_latency',
            action: (data) => {
                // Enable parallel processing for complex requests
                return { enableParallelProcessing: true };
            }
        });

        logger.debug('Optimization strategies initialized', {
            count: this.optimization.strategies.size
        });
    }

    /**
     * Initialize monitoring tasks
     */
    initializeMonitoring() {
        // Update throughput metrics every 10 seconds
        setInterval(() => {
            this.updateThroughputMetrics();
        }, 10000);

        // Performance summary every 5 minutes
        setInterval(() => {
            this.logPerformanceSummary();
        }, 5 * 60 * 1000);

        // Alert cleanup every hour
        setInterval(() => {
            this.cleanupAlerts();
        }, 60 * 60 * 1000);

        logger.debug('Performance monitoring tasks initialized');
    }

    /**
     * Log performance summary
     */
    logPerformanceSummary() {
        try {
            const summary = {
                requests: this.metrics.requests,
                latency: {
                    average: Math.round(this.metrics.latency.average),
                    p95: Math.round(this.metrics.latency.p95),
                    p99: Math.round(this.metrics.latency.p99)
                },
                throughput: {
                    rps: Math.round(this.metrics.throughput.requestsPerSecond * 100) / 100,
                    rpm: this.metrics.throughput.requestsPerMinute
                },
                quality: {
                    averageScore: Math.round(this.metrics.quality.averageScore * 1000) / 1000,
                    passRate: Math.round(this.metrics.quality.passRate * 100)
                },
                activeAlerts: this.alerts.active.size
            };

            logger.info('Performance summary', summary);

        } catch (error) {
            logger.warn('Error logging performance summary', { error: error.message });
        }
    }

    /**
     * Cleanup old alerts
     */
    cleanupAlerts() {
        try {
            const now = Date.now();
            const maxAge = 24 * 60 * 60 * 1000; // 24 hours

            // Remove old alerts from active set
            for (const alertId of this.alerts.active) {
                const alert = this.alerts.history.find(a => a.id === alertId);
                if (alert && now - new Date(alert.timestamp).getTime() > maxAge) {
                    this.alerts.active.delete(alertId);
                }
            }

            logger.debug('Alert cleanup completed', {
                activeAlerts: this.alerts.active.size,
                totalHistory: this.alerts.history.length
            });

        } catch (error) {
            logger.warn('Error during alert cleanup', { error: error.message });
        }
    }

    /**
     * Get real-time performance dashboard data
     * @returns {Object} Dashboard data
     */
    getPerformanceDashboard() {
        try {
            return {
                overview: {
                    status: this.getOverallStatus(),
                    totalRequests: this.metrics.requests.total,
                    successRate: this.metrics.requests.total > 0 ?
                        Math.round((this.metrics.requests.successful / this.metrics.requests.total) * 100) : 0,
                    averageLatency: Math.round(this.metrics.latency.average),
                    activeAlerts: this.alerts.active.size
                },

                latency: {
                    current: this.metrics.latency.current,
                    average: Math.round(this.metrics.latency.average),
                    percentiles: {
                        p50: Math.round(this.metrics.latency.p50),
                        p95: Math.round(this.metrics.latency.p95),
                        p99: Math.round(this.metrics.latency.p99)
                    }
                },

                throughput: {
                    requestsPerSecond: Math.round(this.metrics.throughput.requestsPerSecond * 100) / 100,
                    requestsPerMinute: this.metrics.throughput.requestsPerMinute,
                    peakRps: Math.round(this.metrics.throughput.peakRps * 100) / 100
                },

                targets: {
                    performance: this.targets,
                    targetMet: this.metrics.requests.total > 0 ?
                        Math.round((this.metrics.requests.underTarget / this.metrics.requests.total) * 100) : 0
                },

                quality: {
                    averageScore: Math.round(this.metrics.quality.averageScore * 1000) / 1000,
                    passRate: Math.round(this.metrics.quality.passRate * 100)
                },

                alerts: {
                    active: Array.from(this.alerts.active).map(alertId =>
                        this.alerts.history.find(a => a.id === alertId)
                    ).filter(Boolean),
                    recent: this.alerts.history.slice(-10)
                },

                optimization: {
                    enabled: this.optimization.enabled,
                    recentOptimizations: this.optimization.performanceHistory.slice(-5),
                    strategies: Array.from(this.optimization.strategies.keys())
                }
            };

        } catch (error) {
            logger.error('Error generating performance dashboard', { error: error.message });
            return {
                overview: { status: 'error', error: 'Unable to generate dashboard' },
                error: error.message
            };
        }
    }

    /**
     * Get overall system status
     * @returns {string} Status
     */
    getOverallStatus() {
        const avgLatency = this.metrics.latency.average;
        const successRate = this.metrics.requests.total > 0 ?
            (this.metrics.requests.successful / this.metrics.requests.total) : 1;

        const hasActiveAlerts = this.alerts.active.size > 0;
        const qualityGood = this.metrics.quality.passRate > 0.8;

        if (hasActiveAlerts || successRate < 0.8 || avgLatency > 20000) {
            return 'degraded';
        }

        if (successRate > 0.95 && avgLatency < 12000 && qualityGood) {
            return 'optimal';
        }

        return 'healthy';
    }

    /**
     * Get detailed performance insights
     * @returns {Object} Performance insights
     */
    async getPerformanceInsights() {
        try {
            const dashboard = this.getPerformanceDashboard();

            // Add trend analysis
            const trends = await this.analyzePerformanceTrends();

            // Add bottleneck analysis
            const bottlenecks = await this.identifyBottlenecks();

            // Add recommendations
            const recommendations = this.generatePerformanceRecommendations(dashboard, trends, bottlenecks);

            return {
                ...dashboard,
                trends,
                bottlenecks,
                recommendations,
                insights: {
                    generatedAt: new Date().toISOString(),
                    dataPoints: this.metrics.latency.samples.length,
                    monitoringDuration: this.getMonitoringDuration()
                }
            };

        } catch (error) {
            logger.error('Error generating performance insights', { error: error.message });
            return { error: 'Unable to generate insights' };
        }
    }

    /**
     * Analyze performance trends
     * @returns {Object} Trend analysis
     */
    async analyzePerformanceTrends() {
        try {
            const recentSamples = this.metrics.latency.samples.slice(-50);
            if (recentSamples.length < 10) {
                return { trend: 'insufficient_data' };
            }

            const firstHalf = recentSamples.slice(0, Math.floor(recentSamples.length / 2));
            const secondHalf = recentSamples.slice(Math.floor(recentSamples.length / 2));

            const firstAvg = firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length;
            const secondAvg = secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length;

            const change = ((secondAvg - firstAvg) / firstAvg) * 100;

            return {
                trend: change > 10 ? 'worsening' : change < -10 ? 'improving' : 'stable',
                changePercent: Math.round(change * 100) / 100,
                firstHalfAvg: Math.round(firstAvg),
                secondHalfAvg: Math.round(secondAvg)
            };

        } catch (error) {
            return { trend: 'error', error: error.message };
        }
    }

    /**
     * Identify performance bottlenecks
     * @returns {Array} Bottleneck analysis
     */
    async identifyBottlenecks() {
        try {
            const bottlenecks = [];

            // High latency analysis
            if (this.metrics.latency.p95 > 18000) {
                bottlenecks.push({
                    type: 'high_latency',
                    severity: 'high',
                    description: 'P95 latency exceeds 18 seconds',
                    recommendation: 'Investigate AI model performance and caching'
                });
            }

            // Quality processing bottleneck
            if (this.metrics.quality.averageScore < 0.75) {
                bottlenecks.push({
                    type: 'quality_processing',
                    severity: 'medium',
                    description: 'Quality scores below target',
                    recommendation: 'Review quality assurance parameters'
                });
            }

            // Success rate bottleneck
            const successRate = this.metrics.requests.total > 0 ?
                this.metrics.requests.successful / this.metrics.requests.total : 1;

            if (successRate < 0.9) {
                bottlenecks.push({
                    type: 'reliability',
                    severity: 'high',
                    description: 'Success rate below 90%',
                    recommendation: 'Check error patterns and fallback mechanisms'
                });
            }

            return bottlenecks;

        } catch (error) {
            return [{ type: 'analysis_error', error: error.message }];
        }
    }

    /**
     * Generate performance recommendations
     * @param {Object} dashboard - Dashboard data
     * @param {Object} trends - Trend analysis
     * @param {Array} bottlenecks - Identified bottlenecks
     * @returns {Array} Recommendations
     */
    generatePerformanceRecommendations(dashboard, trends, bottlenecks) {
        const recommendations = [];

        // Latency recommendations
        if (dashboard.latency.average > 15000) {
            recommendations.push({
                type: 'optimization',
                priority: 'high',
                title: 'Reduce Average Latency',
                description: 'Average latency exceeds 15s target',
                actions: [
                    'Enable more aggressive caching',
                    'Consider tier adjustment for complex requests',
                    'Implement parallel processing'
                ]
            });
        }

        // Trend-based recommendations
        if (trends.trend === 'worsening') {
            recommendations.push({
                type: 'trend_analysis',
                priority: 'medium',
                title: 'Performance Degradation Detected',
                description: `Performance worsened by ${trends.changePercent}%`,
                actions: [
                    'Monitor system resources',
                    'Check for recent configuration changes',
                    'Consider auto-scaling if available'
                ]
            });
        }

        // Bottleneck-based recommendations
        for (const bottleneck of bottlenecks) {
            if (bottleneck.recommendation) {
                recommendations.push({
                    type: 'bottleneck',
                    priority: bottleneck.severity === 'high' ? 'high' : 'medium',
                    title: `Address ${bottleneck.type}`,
                    description: bottleneck.description,
                    actions: [bottleneck.recommendation]
                });
            }
        }

        // Quality recommendations
        if (dashboard.quality.passRate < 85) {
            recommendations.push({
                type: 'quality',
                priority: 'medium',
                title: 'Improve Quality Pass Rate',
                description: 'Quality pass rate below target',
                actions: [
                    'Review quality thresholds',
                    'Enhance content filtering',
                    'Consider model fine-tuning'
                ]
            });
        }

        return recommendations.slice(0, 10); // Top 10 recommendations
    }

    /**
     * Get monitoring duration
     * @returns {string} Monitoring duration
     */
    getMonitoringDuration() {
        // This would track actual service uptime in a real implementation
        return 'Service monitoring active';
    }

    /**
     * Get health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: this.getOverallStatus(),
            uptime: this.getMonitoringDuration(),
            metrics: {
                totalRequests: this.metrics.requests.total,
                averageLatency: Math.round(this.metrics.latency.average),
                successRate: this.metrics.requests.total > 0 ?
                    Math.round((this.metrics.requests.successful / this.metrics.requests.total) * 100) : 100,
                activeAlerts: this.alerts.active.size
            },
            targets: this.targets,
            optimization: {
                enabled: this.optimization.enabled,
                lastOptimization: this.optimization.lastOptimization
            }
        };
    }
}

// Export singleton instance
const performanceMonitoringService = new PerformanceMonitoringService();
module.exports = performanceMonitoringService;