/**
 * Performance Metrics and Success Rate Validation Service
 * Comprehensive monitoring and validation system for Flirrt.ai
 */

const { logger } = require('./logger');
const redisService = require('./redis');

class PerformanceMetricsService {
    constructor() {
        this.metrics = {
            // Overall system metrics
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            averageResponseTime: 0,

            // Feature-specific metrics
            screenshotAnalysis: {
                total: 0,
                successful: 0,
                averageTime: 0,
                geminiAnalysisUsage: 0,
                fallbackUsage: 0,
                compressionStats: []
            },

            flirtGeneration: {
                total: 0,
                successful: 0,
                averageTime: 0,
                uniqueGenerations: 0,
                keyboardExtensionUsage: 0,
                cacheHitRate: 0,
                qualityScores: []
            },

            voiceSynthesis: {
                total: 0,
                successful: 0,
                averageTime: 0,
                audioGenerations: 0,
                compressionRate: 0
            },

            // Error and recovery metrics
            errorRecovery: {
                totalErrors: 0,
                recoveredErrors: 0,
                fallbackUsage: 0,
                circuitBreakerTrips: 0
            },

            // Quality assurance metrics
            qualityAssurance: {
                duplicatesDetected: 0,
                lowQualityRejected: 0,
                qualityUpgrades: 0,
                averageQualityScore: 0
            },

            // Performance benchmarks
            benchmarks: {
                keyboardResponseTime: [],
                apiResponseTime: [],
                compressionRatio: [],
                memoryUsage: [],
                successRates: []
            }
        };

        this.performanceTargets = {
            successRate: 95.0, // Target 95% success rate
            keyboardResponseTime: 5000, // 5 seconds max for keyboard
            apiResponseTime: 15000, // 15 seconds max for API
            compressionRatio: 0.7, // 70% compression target
            memoryLimit: 60 * 1024 * 1024, // 60MB memory limit
            qualityThreshold: 0.8 // 80% quality threshold
        };

        this.realtimeMetrics = new Map();
        this.historicalData = [];
        this.alertThresholds = {
            errorRate: 10.0, // Alert if error rate > 10%
            responseTime: 20000, // Alert if response time > 20s
            memoryUsage: 50 * 1024 * 1024 // Alert if memory > 50MB
        };

        this.startMetricsCollection();
    }

    /**
     * Start continuous metrics collection
     */
    startMetricsCollection() {
        // Collect metrics every 30 seconds
        setInterval(() => {
            this.collectRealtimeMetrics();
        }, 30000);

        // Generate performance snapshots every 5 minutes
        setInterval(() => {
            this.generatePerformanceSnapshot();
        }, 300000);

        logger.info('Performance metrics collection started');
    }

    /**
     * Record screenshot analysis metrics
     */
    recordScreenshotAnalysis(data) {
        const { success, duration, geminiUsed, fallback, compressionRatio, correlationId } = data;

        this.metrics.screenshotAnalysis.total++;

        if (success) {
            this.metrics.screenshotAnalysis.successful++;
            this.updateAverageTime('screenshotAnalysis', duration);

            if (geminiUsed) {
                this.metrics.screenshotAnalysis.geminiAnalysisUsage++;
            }

            if (fallback) {
                this.metrics.screenshotAnalysis.fallbackUsage++;
            }

            if (compressionRatio) {
                this.metrics.screenshotAnalysis.compressionStats.push(compressionRatio);
                this.metrics.benchmarks.compressionRatio.push(compressionRatio);
            }
        }

        this.recordOverallRequest(success, duration);
        this.checkPerformanceAlerts('screenshotAnalysis', { success, duration }, correlationId);
    }

    /**
     * Record flirt generation metrics
     */
    recordFlirtGeneration(data) {
        const {
            success,
            duration,
            suggestionsCount,
            keyboardExtension,
            cached,
            qualityScore,
            unique,
            correlationId
        } = data;

        this.metrics.flirtGeneration.total++;

        if (success) {
            this.metrics.flirtGeneration.successful++;
            this.updateAverageTime('flirtGeneration', duration);

            if (keyboardExtension) {
                this.metrics.flirtGeneration.keyboardExtensionUsage++;
                this.metrics.benchmarks.keyboardResponseTime.push(duration);
            } else {
                this.metrics.benchmarks.apiResponseTime.push(duration);
            }

            if (cached) {
                this.updateCacheHitRate();
            }

            if (qualityScore) {
                this.metrics.flirtGeneration.qualityScores.push(qualityScore);
                this.updateQualityMetrics(qualityScore);
            }

            if (unique) {
                this.metrics.flirtGeneration.uniqueGenerations++;
            }
        }

        this.recordOverallRequest(success, duration);
        this.checkPerformanceAlerts('flirtGeneration', { success, duration, keyboardExtension }, correlationId);
    }

    /**
     * Record voice synthesis metrics
     */
    recordVoiceSynthesis(data) {
        const { success, duration, audioSize, compressionRate, correlationId } = data;

        this.metrics.voiceSynthesis.total++;

        if (success) {
            this.metrics.voiceSynthesis.successful++;
            this.updateAverageTime('voiceSynthesis', duration);
            this.metrics.voiceSynthesis.audioGenerations++;

            if (compressionRate) {
                this.metrics.voiceSynthesis.compressionRate =
                    (this.metrics.voiceSynthesis.compressionRate + compressionRate) / 2;
            }
        }

        this.recordOverallRequest(success, duration);
        this.checkPerformanceAlerts('voiceSynthesis', { success, duration }, correlationId);
    }

    /**
     * Record error recovery metrics
     */
    recordErrorRecovery(data) {
        const { errorType, recovered, fallbackUsed, circuitBreakerTripped, correlationId } = data;

        this.metrics.errorRecovery.totalErrors++;

        if (recovered) {
            this.metrics.errorRecovery.recoveredErrors++;
        }

        if (fallbackUsed) {
            this.metrics.errorRecovery.fallbackUsage++;
        }

        if (circuitBreakerTripped) {
            this.metrics.errorRecovery.circuitBreakerTrips++;
        }

        logger.info('Error recovery metrics recorded', {
            errorType,
            recovered,
            fallbackUsed,
            correlationId
        });
    }

    /**
     * Record quality assurance metrics
     */
    recordQualityAssurance(data) {
        const { duplicatesDetected, lowQualityRejected, qualityUpgrades, averageQuality, correlationId } = data;

        if (duplicatesDetected > 0) {
            this.metrics.qualityAssurance.duplicatesDetected += duplicatesDetected;
        }

        if (lowQualityRejected > 0) {
            this.metrics.qualityAssurance.lowQualityRejected += lowQualityRejected;
        }

        if (qualityUpgrades > 0) {
            this.metrics.qualityAssurance.qualityUpgrades += qualityUpgrades;
        }

        if (averageQuality) {
            this.updateQualityMetrics(averageQuality);
        }

        logger.debug('Quality assurance metrics recorded', {
            duplicatesDetected,
            lowQualityRejected,
            qualityUpgrades,
            correlationId
        });
    }

    /**
     * Record memory usage
     */
    recordMemoryUsage(memoryBytes, correlationId) {
        this.metrics.benchmarks.memoryUsage.push(memoryBytes);

        // Keep only last 100 measurements
        if (this.metrics.benchmarks.memoryUsage.length > 100) {
            this.metrics.benchmarks.memoryUsage.shift();
        }

        // Check memory alerts
        if (memoryBytes > this.alertThresholds.memoryUsage) {
            logger.warn('High memory usage detected', {
                memoryMB: Math.round(memoryBytes / 1024 / 1024),
                limitMB: Math.round(this.performanceTargets.memoryLimit / 1024 / 1024),
                correlationId
            });
        }
    }

    /**
     * Generate performance snapshot
     */
    generatePerformanceSnapshot() {
        const timestamp = new Date();
        const successRate = this.calculateSuccessRate();
        const averageResponseTime = this.calculateAverageResponseTime();

        const snapshot = {
            timestamp,
            successRate,
            averageResponseTime,
            metrics: JSON.parse(JSON.stringify(this.metrics)),
            performance: {
                meetsSuccessTarget: successRate >= this.performanceTargets.successRate,
                meetsResponseTimeTarget: averageResponseTime <= this.performanceTargets.apiResponseTime,
                keyboardPerformance: this.calculateKeyboardPerformance(),
                qualityMetrics: this.calculateQualityMetrics(),
                compressionEfficiency: this.calculateCompressionEfficiency(),
                errorRecoveryRate: this.calculateErrorRecoveryRate()
            }
        };

        this.historicalData.push(snapshot);

        // Keep only last 24 hours of snapshots (288 snapshots at 5-minute intervals)
        if (this.historicalData.length > 288) {
            this.historicalData.shift();
        }

        // Store snapshot in Redis for dashboard access
        this.storeSnapshotInRedis(snapshot);

        logger.info('Performance snapshot generated', {
            successRate: `${successRate.toFixed(1)}%`,
            avgResponseTime: `${averageResponseTime.toFixed(0)}ms`,
            totalRequests: this.metrics.totalRequests
        });

        return snapshot;
    }

    /**
     * Get comprehensive performance report
     */
    getPerformanceReport() {
        const successRate = this.calculateSuccessRate();
        const currentSnapshot = this.generatePerformanceSnapshot();

        return {
            summary: {
                overall_success_rate: successRate,
                total_requests: this.metrics.totalRequests,
                successful_requests: this.metrics.successfulRequests,
                failed_requests: this.metrics.failedRequests,
                average_response_time: this.calculateAverageResponseTime(),
                report_generated_at: new Date().toISOString()
            },

            feature_performance: {
                screenshot_analysis: {
                    success_rate: this.calculateFeatureSuccessRate('screenshotAnalysis'),
                    average_response_time: this.metrics.screenshotAnalysis.averageTime,
                    gemini_usage_rate: this.calculateGeminiUsageRate(),
                    compression_efficiency: this.calculateCompressionEfficiency()
                },

                flirt_generation: {
                    success_rate: this.calculateFeatureSuccessRate('flirtGeneration'),
                    average_response_time: this.metrics.flirtGeneration.averageTime,
                    keyboard_response_time: this.calculateKeyboardPerformance().averageTime,
                    cache_hit_rate: this.metrics.flirtGeneration.cacheHitRate,
                    quality_score: this.calculateQualityMetrics().averageScore
                },

                voice_synthesis: {
                    success_rate: this.calculateFeatureSuccessRate('voiceSynthesis'),
                    average_response_time: this.metrics.voiceSynthesis.averageTime,
                    compression_rate: this.metrics.voiceSynthesis.compressionRate
                }
            },

            quality_assurance: {
                duplicates_detected: this.metrics.qualityAssurance.duplicatesDetected,
                low_quality_rejected: this.metrics.qualityAssurance.lowQualityRejected,
                quality_upgrades: this.metrics.qualityAssurance.qualityUpgrades,
                average_quality_score: this.metrics.qualityAssurance.averageQualityScore
            },

            error_recovery: {
                total_errors: this.metrics.errorRecovery.totalErrors,
                recovery_rate: this.calculateErrorRecoveryRate(),
                fallback_usage: this.metrics.errorRecovery.fallbackUsage,
                circuit_breaker_trips: this.metrics.errorRecovery.circuitBreakerTrips
            },

            performance_targets: {
                success_rate: {
                    target: this.performanceTargets.successRate,
                    actual: successRate,
                    meets_target: successRate >= this.performanceTargets.successRate
                },
                response_time: {
                    keyboard_target: this.performanceTargets.keyboardResponseTime,
                    api_target: this.performanceTargets.apiResponseTime,
                    keyboard_actual: this.calculateKeyboardPerformance().averageTime,
                    api_actual: this.calculateAverageResponseTime(),
                    meets_keyboard_target: this.calculateKeyboardPerformance().averageTime <= this.performanceTargets.keyboardResponseTime,
                    meets_api_target: this.calculateAverageResponseTime() <= this.performanceTargets.apiResponseTime
                },
                quality: {
                    target: this.performanceTargets.qualityThreshold,
                    actual: this.calculateQualityMetrics().averageScore,
                    meets_target: this.calculateQualityMetrics().averageScore >= this.performanceTargets.qualityThreshold
                }
            },

            trends: this.calculatePerformanceTrends(),

            recommendations: this.generatePerformanceRecommendations()
        };
    }

    /**
     * Get real-time metrics for dashboard
     */
    getRealtimeMetrics() {
        return {
            current_success_rate: this.calculateSuccessRate(),
            requests_per_minute: this.calculateRequestsPerMinute(),
            average_response_time: this.calculateAverageResponseTime(),
            active_errors: this.getActiveErrors(),
            memory_usage: this.getCurrentMemoryUsage(),
            quality_score: this.calculateQualityMetrics().averageScore,
            cache_hit_rate: this.metrics.flirtGeneration.cacheHitRate,
            timestamp: new Date().toISOString()
        };
    }

    // Helper Methods

    recordOverallRequest(success, duration) {
        this.metrics.totalRequests++;

        if (success) {
            this.metrics.successfulRequests++;
        } else {
            this.metrics.failedRequests++;
        }

        // Update average response time
        this.metrics.averageResponseTime =
            (this.metrics.averageResponseTime * (this.metrics.totalRequests - 1) + duration) / this.metrics.totalRequests;
    }

    updateAverageTime(feature, duration) {
        const featureMetrics = this.metrics[feature];
        const total = featureMetrics.successful;

        featureMetrics.averageTime =
            (featureMetrics.averageTime * (total - 1) + duration) / total;
    }

    updateCacheHitRate() {
        const total = this.metrics.flirtGeneration.total;
        this.metrics.flirtGeneration.cacheHitRate =
            (this.metrics.flirtGeneration.cacheHitRate * (total - 1) + 1) / total;
    }

    updateQualityMetrics(qualityScore) {
        const current = this.metrics.qualityAssurance.averageQualityScore;
        const count = this.metrics.flirtGeneration.qualityScores.length;

        this.metrics.qualityAssurance.averageQualityScore =
            (current * (count - 1) + qualityScore) / count;
    }

    calculateSuccessRate() {
        if (this.metrics.totalRequests === 0) return 100;
        return (this.metrics.successfulRequests / this.metrics.totalRequests) * 100;
    }

    calculateFeatureSuccessRate(feature) {
        const featureMetrics = this.metrics[feature];
        if (featureMetrics.total === 0) return 100;
        return (featureMetrics.successful / featureMetrics.total) * 100;
    }

    calculateAverageResponseTime() {
        return this.metrics.averageResponseTime;
    }

    calculateKeyboardPerformance() {
        const keyboardTimes = this.metrics.benchmarks.keyboardResponseTime;
        if (keyboardTimes.length === 0) {
            return { averageTime: 0, meetsTarget: true };
        }

        const averageTime = keyboardTimes.reduce((sum, time) => sum + time, 0) / keyboardTimes.length;
        return {
            averageTime,
            meetsTarget: averageTime <= this.performanceTargets.keyboardResponseTime
        };
    }

    calculateQualityMetrics() {
        const scores = this.metrics.flirtGeneration.qualityScores;
        if (scores.length === 0) {
            return { averageScore: 0, meetsTarget: false };
        }

        const averageScore = scores.reduce((sum, score) => sum + score, 0) / scores.length;
        return {
            averageScore,
            meetsTarget: averageScore >= this.performanceTargets.qualityThreshold,
            distribution: this.calculateQualityDistribution(scores)
        };
    }

    calculateQualityDistribution(scores) {
        const distribution = { high: 0, medium: 0, low: 0 };

        scores.forEach(score => {
            if (score >= 0.8) distribution.high++;
            else if (score >= 0.6) distribution.medium++;
            else distribution.low++;
        });

        return distribution;
    }

    calculateCompressionEfficiency() {
        const ratios = this.metrics.benchmarks.compressionRatio;
        if (ratios.length === 0) return 0;

        return ratios.reduce((sum, ratio) => sum + ratio, 0) / ratios.length;
    }

    calculateErrorRecoveryRate() {
        if (this.metrics.errorRecovery.totalErrors === 0) return 100;
        return (this.metrics.errorRecovery.recoveredErrors / this.metrics.errorRecovery.totalErrors) * 100;
    }

    calculateGeminiUsageRate() {
        if (this.metrics.screenshotAnalysis.total === 0) return 0;
        return (this.metrics.screenshotAnalysis.geminiAnalysisUsage / this.metrics.screenshotAnalysis.total) * 100;
    }

    calculateRequestsPerMinute() {
        // Calculate based on recent requests (last minute)
        const now = Date.now();
        const oneMinuteAgo = now - 60000;

        // This would need to track request timestamps
        // For now, return estimated rate
        return Math.round(this.metrics.totalRequests / 60);
    }

    getCurrentMemoryUsage() {
        const memoryUsages = this.metrics.benchmarks.memoryUsage;
        return memoryUsages.length > 0 ? memoryUsages[memoryUsages.length - 1] : 0;
    }

    getActiveErrors() {
        // Return current error rate
        return this.metrics.totalRequests > 0 ?
            (this.metrics.failedRequests / this.metrics.totalRequests) * 100 : 0;
    }

    calculatePerformanceTrends() {
        if (this.historicalData.length < 2) {
            return { trend: 'insufficient_data' };
        }

        const recent = this.historicalData.slice(-12); // Last hour
        const older = this.historicalData.slice(-24, -12); // Previous hour

        const recentAvgSuccess = recent.reduce((sum, snapshot) => sum + snapshot.successRate, 0) / recent.length;
        const olderAvgSuccess = older.length > 0 ? older.reduce((sum, snapshot) => sum + snapshot.successRate, 0) / older.length : recentAvgSuccess;

        const successTrend = recentAvgSuccess - olderAvgSuccess;

        return {
            success_rate_trend: successTrend > 1 ? 'improving' : successTrend < -1 ? 'declining' : 'stable',
            success_rate_change: successTrend,
            period: 'last_hour_vs_previous_hour'
        };
    }

    generatePerformanceRecommendations() {
        const recommendations = [];
        const successRate = this.calculateSuccessRate();
        const keyboardPerf = this.calculateKeyboardPerformance();
        const qualityMetrics = this.calculateQualityMetrics();
        const errorRecoveryRate = this.calculateErrorRecoveryRate();

        if (successRate < this.performanceTargets.successRate) {
            recommendations.push({
                type: 'critical',
                area: 'success_rate',
                message: `Success rate (${successRate.toFixed(1)}%) is below target (${this.performanceTargets.successRate}%)`,
                action: 'Investigate error patterns and improve error handling'
            });
        }

        if (!keyboardPerf.meetsTarget) {
            recommendations.push({
                type: 'warning',
                area: 'keyboard_performance',
                message: `Keyboard response time (${keyboardPerf.averageTime.toFixed(0)}ms) exceeds target (${this.performanceTargets.keyboardResponseTime}ms)`,
                action: 'Optimize keyboard extension compression and caching'
            });
        }

        if (!qualityMetrics.meetsTarget) {
            recommendations.push({
                type: 'improvement',
                area: 'quality',
                message: `Quality score (${qualityMetrics.averageScore.toFixed(2)}) is below target (${this.performanceTargets.qualityThreshold})`,
                action: 'Enhance quality assurance filters and improve AI training'
            });
        }

        if (errorRecoveryRate < 90) {
            recommendations.push({
                type: 'warning',
                area: 'error_recovery',
                message: `Error recovery rate (${errorRecoveryRate.toFixed(1)}%) could be improved`,
                action: 'Strengthen fallback mechanisms and circuit breaker logic'
            });
        }

        return recommendations;
    }

    async collectRealtimeMetrics() {
        try {
            const realtimeData = this.getRealtimeMetrics();
            this.realtimeMetrics.set('current', realtimeData);

            // Store in Redis for external access
            await redisService.set('metrics:realtime', realtimeData, 60); // 1 minute TTL

        } catch (error) {
            logger.error('Failed to collect realtime metrics', { error: error.message });
        }
    }

    async storeSnapshotInRedis(snapshot) {
        try {
            await redisService.set(`metrics:snapshot:${Date.now()}`, snapshot, 86400); // 24 hours TTL
            await redisService.set('metrics:latest_snapshot', snapshot, 86400);

        } catch (error) {
            logger.error('Failed to store performance snapshot', { error: error.message });
        }
    }

    checkPerformanceAlerts(feature, data, correlationId) {
        const { success, duration, keyboardExtension } = data;

        // Check response time alerts
        const timeLimit = keyboardExtension ?
            this.performanceTargets.keyboardResponseTime :
            this.performanceTargets.apiResponseTime;

        if (duration > timeLimit) {
            logger.warn('Performance alert: Slow response time', {
                feature,
                duration,
                limit: timeLimit,
                keyboardExtension,
                correlationId
            });
        }

        // Check error rate alerts
        const featureMetrics = this.metrics[feature];
        if (featureMetrics.total > 10) { // Only check after some volume
            const errorRate = ((featureMetrics.total - featureMetrics.successful) / featureMetrics.total) * 100;

            if (errorRate > this.alertThresholds.errorRate) {
                logger.warn('Performance alert: High error rate', {
                    feature,
                    errorRate: `${errorRate.toFixed(1)}%`,
                    threshold: `${this.alertThresholds.errorRate}%`,
                    correlationId
                });
            }
        }
    }

    /**
     * Reset all metrics (for testing)
     */
    resetMetrics() {
        this.metrics = {
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            averageResponseTime: 0,
            screenshotAnalysis: { total: 0, successful: 0, averageTime: 0, geminiAnalysisUsage: 0, fallbackUsage: 0, compressionStats: [] },
            flirtGeneration: { total: 0, successful: 0, averageTime: 0, uniqueGenerations: 0, keyboardExtensionUsage: 0, cacheHitRate: 0, qualityScores: [] },
            voiceSynthesis: { total: 0, successful: 0, averageTime: 0, audioGenerations: 0, compressionRate: 0 },
            errorRecovery: { totalErrors: 0, recoveredErrors: 0, fallbackUsage: 0, circuitBreakerTrips: 0 },
            qualityAssurance: { duplicatesDetected: 0, lowQualityRejected: 0, qualityUpgrades: 0, averageQualityScore: 0 },
            benchmarks: { keyboardResponseTime: [], apiResponseTime: [], compressionRatio: [], memoryUsage: [], successRates: [] }
        };

        this.historicalData = [];
        this.realtimeMetrics.clear();

        logger.info('Performance metrics reset');
    }
}

// Export singleton instance
module.exports = new PerformanceMetricsService();