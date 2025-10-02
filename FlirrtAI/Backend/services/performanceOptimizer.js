/**
 * Performance Optimizer Service
 *
 * Handles advanced performance optimization for the dual-model AI pipeline:
 * - Intelligent caching strategies
 * - Request prioritization and queuing
 * - Resource allocation optimization
 * - Response time monitoring and optimization
 * - Adaptive timeout strategies
 * - Smart batching and parallelization
 */

const { logger } = require('./logger');
const redisService = require('./redis');

class PerformanceOptimizer {
    constructor() {
        this.metrics = {
            totalRequests: 0,
            fastRequests: 0,
            standardRequests: 0,
            comprehensiveRequests: 0,
            avgLatencyByStrategy: {
                fast: 0,
                standard: 0,
                comprehensive: 0
            },
            cacheHitRate: 0,
            optimizationSavings: 0
        };

        // Performance thresholds
        this.thresholds = {
            fast: 5000,        // 5 seconds
            standard: 15000,   // 15 seconds
            comprehensive: 30000, // 30 seconds
            critical: 45000    // 45 seconds - absolute max
        };

        // Optimization strategies
        this.strategies = new Map();
        this.initializeStrategies();

        logger.info('Performance Optimizer initialized', {
            thresholds: this.thresholds
        });
    }

    /**
     * Initialize optimization strategies
     */
    initializeStrategies() {
        // Strategy for keyboard extensions - need ultra-fast responses
        this.strategies.set('keyboard', {
            name: 'keyboard',
            maxLatency: 3000,
            cacheFirst: true,
            parallelProcessing: false,
            fallbackThreshold: 0.3,
            geminiTimeout: 5000,
            grokTimeout: 8000,
            priority: 'high'
        });

        // Strategy for simple profile photos
        this.strategies.set('fast', {
            name: 'fast',
            maxLatency: 8000,
            cacheFirst: true,
            parallelProcessing: true,
            fallbackThreshold: 0.5,
            geminiTimeout: 6000,
            grokTimeout: 10000,
            priority: 'medium'
        });

        // Strategy for standard requests
        this.strategies.set('standard', {
            name: 'standard',
            maxLatency: 15000,
            cacheFirst: false,
            parallelProcessing: true,
            fallbackThreshold: 0.7,
            geminiTimeout: 12000,
            grokTimeout: 18000,
            priority: 'medium'
        });

        // Strategy for complex analysis requiring high accuracy
        this.strategies.set('comprehensive', {
            name: 'comprehensive',
            maxLatency: 25000,
            cacheFirst: false,
            parallelProcessing: false, // Sequential for better context
            fallbackThreshold: 0.8,
            geminiTimeout: 20000,
            grokTimeout: 25000,
            priority: 'low'
        });
    }

    /**
     * Determine optimal strategy based on request characteristics
     * @param {Object} request - Incoming request
     * @returns {Object} Optimization strategy
     */
    async determineOptimalStrategy(request) {
        const startTime = Date.now();

        try {
            // Quick strategy for keyboard extensions
            if (request.isKeyboardExtension) {
                this.metrics.fastRequests++;
                return this.strategies.get('keyboard');
            }

            // Analyze request complexity
            const complexityScore = await this.calculateComplexityScore(request);

            // Check current system load
            const systemLoad = await this.getCurrentSystemLoad();

            // Determine base strategy
            let strategyName;
            if (complexityScore <= 0.3 || systemLoad > 0.8) {
                strategyName = 'fast';
                this.metrics.fastRequests++;
            } else if (complexityScore <= 0.7) {
                strategyName = 'standard';
                this.metrics.standardRequests++;
            } else {
                strategyName = 'comprehensive';
                this.metrics.comprehensiveRequests++;
            }

            const strategy = { ...this.strategies.get(strategyName) };

            // Adapt strategy based on current conditions
            strategy.adaptedTimeouts = await this.adaptTimeouts(strategy, systemLoad);
            strategy.systemLoad = systemLoad;
            strategy.complexityScore = complexityScore;

            logger.debug('Strategy determined', {
                correlationId: request.correlationId,
                strategy: strategyName,
                complexityScore,
                systemLoad,
                isKeyboard: request.isKeyboardExtension,
                determineTime: Date.now() - startTime
            });

            return strategy;

        } catch (error) {
            logger.error('Failed to determine optimal strategy', {
                correlationId: request.correlationId,
                error: error.message
            });

            // Return safe default
            return this.strategies.get('standard');
        }
    }

    /**
     * Calculate request complexity score
     * @param {Object} request - Request object
     * @returns {Promise<number>} Complexity score 0-1
     */
    async calculateComplexityScore(request) {
        let score = 0.3; // Base complexity

        try {
            // Image size complexity
            if (request.imageData) {
                const base64Data = request.imageData.replace(/^data:image\/[a-z]+;base64,/, '');
                const imageSizeKB = (base64Data.length * 3/4) / 1024;

                if (imageSizeKB > 500) score += 0.2;
                else if (imageSizeKB > 200) score += 0.1;
            }

            // Context complexity
            if (request.context) {
                const contextLength = request.context.length;
                if (contextLength > 500) score += 0.15;
                else if (contextLength > 200) score += 0.1;

                // Check for complex indicators
                const complexWords = ['conversation', 'relationship', 'complicated', 'complex', 'detailed'];
                const hasComplexWords = complexWords.some(word =>
                    request.context.toLowerCase().includes(word)
                );
                if (hasComplexWords) score += 0.1;
            }

            // User preferences complexity
            if (request.user_preferences) {
                const prefCount = Object.keys(request.user_preferences).length;
                if (prefCount > 5) score += 0.1;
                else if (prefCount > 2) score += 0.05;
            }

            // Strategy override
            if (request.strategy === 'comprehensive') score = Math.max(score, 0.8);
            else if (request.strategy === 'fast') score = Math.min(score, 0.3);

            return Math.min(1.0, score);

        } catch (error) {
            logger.warn('Error calculating complexity score', { error: error.message });
            return 0.5; // Default medium complexity
        }
    }

    /**
     * Get current system load
     * @returns {Promise<number>} Load score 0-1
     */
    async getCurrentSystemLoad() {
        try {
            // Check recent request metrics
            const metricsKey = 'performance_metrics:load';
            const loadMetrics = await redisService.get(metricsKey) || {
                activeRequests: 0,
                avgResponseTime: 0,
                errorRate: 0
            };

            let loadScore = 0;

            // Active requests load
            if (loadMetrics.activeRequests > 20) loadScore += 0.4;
            else if (loadMetrics.activeRequests > 10) loadScore += 0.2;
            else if (loadMetrics.activeRequests > 5) loadScore += 0.1;

            // Response time load
            if (loadMetrics.avgResponseTime > 20000) loadScore += 0.3;
            else if (loadMetrics.avgResponseTime > 10000) loadScore += 0.2;
            else if (loadMetrics.avgResponseTime > 5000) loadScore += 0.1;

            // Error rate load
            if (loadMetrics.errorRate > 0.2) loadScore += 0.3;
            else if (loadMetrics.errorRate > 0.1) loadScore += 0.2;
            else if (loadMetrics.errorRate > 0.05) loadScore += 0.1;

            return Math.min(1.0, loadScore);

        } catch (error) {
            logger.warn('Error getting system load', { error: error.message });
            return 0.5; // Default medium load
        }
    }

    /**
     * Adapt timeouts based on current conditions
     * @param {Object} strategy - Base strategy
     * @param {number} systemLoad - Current system load
     * @returns {Promise<Object>} Adapted timeouts
     */
    async adaptTimeouts(strategy, systemLoad) {
        const baseTimeouts = {
            gemini: strategy.geminiTimeout,
            grok: strategy.grokTimeout,
            total: strategy.maxLatency
        };

        // Adjust based on system load
        const loadMultiplier = 1 + (systemLoad * 0.5); // Up to 50% increase under load

        // But also consider recent performance
        const recentPerformance = await this.getRecentPerformance(strategy.name);
        const performanceMultiplier = recentPerformance > baseTimeouts.total ? 1.2 : 0.9;

        return {
            gemini: Math.round(baseTimeouts.gemini * loadMultiplier * performanceMultiplier),
            grok: Math.round(baseTimeouts.grok * loadMultiplier * performanceMultiplier),
            total: Math.round(baseTimeouts.total * loadMultiplier * performanceMultiplier)
        };
    }

    /**
     * Get recent performance for a strategy
     * @param {string} strategyName - Strategy name
     * @returns {Promise<number>} Average latency
     */
    async getRecentPerformance(strategyName) {
        try {
            const perfKey = `performance:${strategyName}:recent`;
            const recentPerf = await redisService.get(perfKey) || { avgLatency: 0 };
            return recentPerf.avgLatency || this.thresholds[strategyName] || 10000;

        } catch (error) {
            return this.thresholds[strategyName] || 10000;
        }
    }

    /**
     * Optimize cache strategy for request
     * @param {Object} request - Request object
     * @param {Object} strategy - Optimization strategy
     * @returns {Object} Cache configuration
     */
    optimizeCacheStrategy(request, strategy) {
        const cacheConfig = {
            enabled: true,
            checkFirst: strategy.cacheFirst,
            ttl: 3600, // Base TTL 1 hour
            keyFactors: ['imageHash', 'tone', 'suggestionType']
        };

        // Adjust TTL based on request type
        if (request.isKeyboardExtension) {
            cacheConfig.ttl = 7200; // 2 hours for keyboard
            cacheConfig.checkFirst = true;
        }

        // Include more factors for complex requests
        if (strategy.name === 'comprehensive') {
            cacheConfig.keyFactors.push('userPreferences', 'context');
            cacheConfig.ttl = 1800; // 30 minutes for complex
        }

        // Fast requests get longer cache
        if (strategy.name === 'fast') {
            cacheConfig.ttl = 14400; // 4 hours for fast/simple
        }

        return cacheConfig;
    }

    /**
     * Optimize request for parallel processing
     * @param {Object} request - Request object
     * @param {Object} strategy - Optimization strategy
     * @returns {Object} Parallelization configuration
     */
    optimizeParallelProcessing(request, strategy) {
        if (!strategy.parallelProcessing) {
            return {
                enabled: false,
                reason: 'Strategy requires sequential processing'
            };
        }

        // Check if we can run Gemini and Grok in parallel
        const canParallelize = this.canParallelizeRequest(request);

        return {
            enabled: canParallelize,
            geminiFirst: !canParallelize, // Run Gemini first if can't parallelize
            concurrency: canParallelize ? 2 : 1,
            reason: canParallelize ? 'Parallel processing enabled' : 'Requires sequential processing'
        };
    }

    /**
     * Check if request can be parallelized
     * @param {Object} request - Request object
     * @returns {boolean} Whether request can be parallelized
     */
    canParallelizeRequest(request) {
        // Simple requests can often be parallelized with pre-analysis
        if (request.isKeyboardExtension) return false; // Keep simple for keyboard

        // If we have cached analysis, we can parallelize
        if (request.cachedAnalysis) return true;

        // For new requests, check complexity
        return request.complexityScore <= 0.7;
    }

    /**
     * Record performance metrics
     * @param {Object} metrics - Performance metrics
     */
    async recordPerformance(metrics) {
        try {
            const {
                correlationId,
                strategy,
                latency,
                success,
                cacheHit,
                geminiLatency = 0,
                grokLatency = 0
            } = metrics;

            // Update strategy-specific metrics
            if (this.metrics.avgLatencyByStrategy[strategy]) {
                const current = this.metrics.avgLatencyByStrategy[strategy];
                this.metrics.avgLatencyByStrategy[strategy] =
                    current === 0 ? latency : (current * 0.9 + latency * 0.1);
            }

            // Update cache hit rate
            if (cacheHit !== undefined) {
                const currentHitRate = this.metrics.cacheHitRate;
                this.metrics.cacheHitRate = currentHitRate * 0.95 + (cacheHit ? 0.05 : 0);
            }

            // Store detailed metrics in Redis
            const perfKey = `performance:${strategy}:recent`;
            const existingPerf = await redisService.get(perfKey) || {
                requests: 0,
                totalLatency: 0,
                successCount: 0,
                avgLatency: 0,
                successRate: 0
            };

            existingPerf.requests += 1;
            existingPerf.totalLatency += latency;
            if (success) existingPerf.successCount += 1;

            existingPerf.avgLatency = existingPerf.totalLatency / existingPerf.requests;
            existingPerf.successRate = existingPerf.successCount / existingPerf.requests;

            await redisService.set(perfKey, existingPerf, 3600); // Store for 1 hour

            // Update total metrics
            this.metrics.totalRequests += 1;

            logger.debug('Performance recorded', {
                correlationId,
                strategy,
                latency,
                success,
                cacheHit,
                avgLatency: existingPerf.avgLatency
            });

        } catch (error) {
            logger.error('Failed to record performance metrics', {
                error: error.message,
                correlationId: metrics.correlationId
            });
        }
    }

    /**
     * Get performance insights and recommendations
     * @returns {Promise<Object>} Performance insights
     */
    async getPerformanceInsights() {
        try {
            const insights = {
                overall: {
                    totalRequests: this.metrics.totalRequests,
                    cacheHitRate: Math.round(this.metrics.cacheHitRate * 100),
                    optimizationSavings: this.metrics.optimizationSavings
                },
                strategies: {},
                recommendations: []
            };

            // Get strategy-specific insights
            for (const [name, strategy] of this.strategies) {
                const perfKey = `performance:${name}:recent`;
                const perf = await redisService.get(perfKey) || {};

                insights.strategies[name] = {
                    avgLatency: perf.avgLatency || 0,
                    successRate: Math.round((perf.successRate || 0) * 100),
                    threshold: strategy.maxLatency,
                    status: perf.avgLatency > strategy.maxLatency ? 'degraded' : 'healthy'
                };

                // Generate recommendations
                if (perf.avgLatency > strategy.maxLatency) {
                    insights.recommendations.push({
                        strategy: name,
                        issue: 'High latency',
                        recommendation: 'Consider increasing timeouts or optimizing processing'
                    });
                }

                if (perf.successRate < 0.9) {
                    insights.recommendations.push({
                        strategy: name,
                        issue: 'Low success rate',
                        recommendation: 'Check error patterns and fallback mechanisms'
                    });
                }
            }

            // Cache hit rate recommendations
            if (this.metrics.cacheHitRate < 0.3) {
                insights.recommendations.push({
                    issue: 'Low cache hit rate',
                    recommendation: 'Review cache key strategy and TTL settings'
                });
            }

            return insights;

        } catch (error) {
            logger.error('Failed to get performance insights', { error: error.message });
            return {
                overall: { error: 'Failed to load insights' },
                strategies: {},
                recommendations: []
            };
        }
    }

    /**
     * Optimize request priority in queue
     * @param {Object} request - Request object
     * @param {Object} strategy - Optimization strategy
     * @returns {number} Priority score (higher = more priority)
     */
    calculateRequestPriority(request, strategy) {
        let priority = 50; // Base priority

        // Keyboard extensions get highest priority
        if (request.isKeyboardExtension) priority += 40;

        // Strategy-based priority
        switch (strategy.priority) {
            case 'high': priority += 20; break;
            case 'medium': priority += 10; break;
            case 'low': priority += 0; break;
        }

        // User-based priority (if premium user, etc.)
        if (request.user?.premium) priority += 15;

        // Time-based priority (older requests get higher priority)
        const age = Date.now() - new Date(request.requestTimestamp).getTime();
        priority += Math.min(20, age / 1000); // Up to 20 points for age in seconds

        return priority;
    }

    /**
     * Update system load tracking
     * @param {string} operation - Operation type (start/end)
     * @param {Object} metadata - Request metadata
     */
    async updateSystemLoad(operation, metadata = {}) {
        try {
            const loadKey = 'performance_metrics:load';
            const load = await redisService.get(loadKey) || {
                activeRequests: 0,
                totalRequests: 0,
                totalLatency: 0,
                errorCount: 0,
                avgResponseTime: 0,
                errorRate: 0
            };

            if (operation === 'start') {
                load.activeRequests += 1;
            } else if (operation === 'end') {
                load.activeRequests = Math.max(0, load.activeRequests - 1);
                load.totalRequests += 1;

                if (metadata.latency) {
                    load.totalLatency += metadata.latency;
                    load.avgResponseTime = load.totalLatency / load.totalRequests;
                }

                if (metadata.error) {
                    load.errorCount += 1;
                }

                load.errorRate = load.errorCount / load.totalRequests;
            }

            await redisService.set(loadKey, load, 300); // Store for 5 minutes

        } catch (error) {
            logger.warn('Failed to update system load', { error: error.message });
        }
    }

    /**
     * Get current performance status
     * @returns {Object} Performance status
     */
    getPerformanceStatus() {
        return {
            status: 'operational',
            metrics: { ...this.metrics },
            thresholds: { ...this.thresholds },
            strategies: Array.from(this.strategies.keys()),
            timestamp: new Date().toISOString()
        };
    }
}

// Export singleton instance
const performanceOptimizer = new PerformanceOptimizer();
module.exports = performanceOptimizer;