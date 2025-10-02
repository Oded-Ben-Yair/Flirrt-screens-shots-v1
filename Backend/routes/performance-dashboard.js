/**
 * Performance Dashboard Routes - Real-time AI Pipeline Monitoring
 *
 * Comprehensive dashboard endpoints for monitoring:
 * - Real-time performance metrics
 * - Quality assurance insights
 * - Caching efficiency
 * - Streaming delivery metrics
 * - Optimization recommendations
 * - System health status
 */

const express = require('express');
const router = express.Router();
const { logger } = require('../services/logger');

// Import monitoring services
const performanceMonitoringService = require('../services/performanceMonitoringService');
const intelligentCacheService = require('../services/intelligentCacheService');
const advancedQualityAssurance = require('../services/advancedQualityAssurance');
const streamingDeliveryService = require('../services/streamingDeliveryService');
const enhancedAIOrchestrator = require('../services/enhancedAIOrchestrator');

/**
 * GET /api/performance/dashboard
 * Real-time performance dashboard overview
 */
router.get('/dashboard', async (req, res) => {
    try {
        logger.info('Performance dashboard requested', {
            userAgent: req.get('User-Agent'),
            timestamp: new Date().toISOString()
        });

        const dashboard = performanceMonitoringService.getPerformanceDashboard();

        res.json({
            success: true,
            dashboard,
            timestamp: new Date().toISOString(),
            version: 'v2.0-enhanced'
        });

    } catch (error) {
        logger.error('Error generating performance dashboard', {
            error: error.message,
            stack: error.stack
        });

        res.status(500).json({
            success: false,
            error: 'Failed to generate performance dashboard',
            message: error.message
        });
    }
});

/**
 * GET /api/performance/insights
 * Detailed performance insights and analytics
 */
router.get('/insights', async (req, res) => {
    try {
        const insights = await performanceMonitoringService.getPerformanceInsights();

        res.json({
            success: true,
            insights,
            generatedAt: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Error generating performance insights', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to generate performance insights'
        });
    }
});

/**
 * GET /api/performance/quality
 * Quality assurance metrics and trends
 */
router.get('/quality', async (req, res) => {
    try {
        const qualityInsights = advancedQualityAssurance.getCacheInsights();
        const healthStatus = advancedQualityAssurance.getHealthStatus();

        res.json({
            success: true,
            quality: {
                insights: qualityInsights,
                health: healthStatus,
                timestamp: new Date().toISOString()
            }
        });

    } catch (error) {
        logger.error('Error getting quality metrics', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to retrieve quality metrics'
        });
    }
});

/**
 * GET /api/performance/caching
 * Intelligent caching performance and insights
 */
router.get('/caching', async (req, res) => {
    try {
        const cacheInsights = intelligentCacheService.getCacheInsights();
        const healthStatus = intelligentCacheService.getHealthStatus();

        res.json({
            success: true,
            caching: {
                insights: cacheInsights,
                health: healthStatus,
                timestamp: new Date().toISOString()
            }
        });

    } catch (error) {
        logger.error('Error getting cache insights', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to retrieve cache insights'
        });
    }
});

/**
 * GET /api/performance/streaming
 * Streaming delivery metrics and status
 */
router.get('/streaming', async (req, res) => {
    try {
        const streamingInsights = streamingDeliveryService.getStreamingInsights();
        const healthStatus = streamingDeliveryService.getHealthStatus();

        res.json({
            success: true,
            streaming: {
                insights: streamingInsights,
                health: healthStatus,
                timestamp: new Date().toISOString()
            }
        });

    } catch (error) {
        logger.error('Error getting streaming metrics', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to retrieve streaming metrics'
        });
    }
});

/**
 * GET /api/performance/orchestrator
 * AI orchestrator performance and configuration
 */
router.get('/orchestrator', async (req, res) => {
    try {
        const healthStatus = enhancedAIOrchestrator.getHealthStatus();
        const performanceReport = enhancedAIOrchestrator.getPerformanceReport();

        res.json({
            success: true,
            orchestrator: {
                health: healthStatus,
                performance: performanceReport,
                timestamp: new Date().toISOString()
            }
        });

    } catch (error) {
        logger.error('Error getting orchestrator status', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to retrieve orchestrator status'
        });
    }
});

/**
 * GET /api/performance/health
 * Overall system health check
 */
router.get('/health', async (req, res) => {
    try {
        const healthChecks = {
            performanceMonitoring: performanceMonitoringService.getHealthStatus(),
            qualityAssurance: advancedQualityAssurance.getHealthStatus(),
            intelligentCaching: intelligentCacheService.getHealthStatus(),
            streamingDelivery: streamingDeliveryService.getHealthStatus(),
            aiOrchestrator: enhancedAIOrchestrator.getHealthStatus()
        };

        // Determine overall health status
        const healthStatuses = Object.values(healthChecks).map(h => h.status);
        const overallHealth = healthStatuses.every(status =>
            status === 'healthy' || status === 'operational' || status === 'optimal'
        ) ? 'healthy' : healthStatuses.some(status =>
            status === 'degraded' || status === 'warning'
        ) ? 'degraded' : 'unhealthy';

        res.json({
            success: true,
            health: {
                overall: overallHealth,
                services: healthChecks,
                timestamp: new Date().toISOString(),
                version: 'enhanced-v2.0'
            }
        });

    } catch (error) {
        logger.error('Error performing health check', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            health: {
                overall: 'error',
                error: error.message
            }
        });
    }
});

/**
 * GET /api/performance/targets
 * Performance targets and achievement status
 */
router.get('/targets', async (req, res) => {
    try {
        const dashboard = performanceMonitoringService.getPerformanceDashboard();

        // Calculate target achievements
        const targets = {
            responseTime: {
                target: '< 15 seconds',
                current: `${dashboard.latency.average}ms`,
                achieved: dashboard.latency.average < 15000,
                p95: `${dashboard.latency.percentiles.p95}ms`,
                p99: `${dashboard.latency.percentiles.p99}ms`
            },
            compression: {
                target: '> 70% reduction',
                description: 'Advanced image compression with WebP/HEIC support',
                features: ['Binary search optimization', 'Ultra compression mode', 'AI-optimized dimensions']
            },
            caching: {
                target: '> 50% hit rate',
                current: intelligentCacheService.getHealthStatus().hitRate,
                achieved: intelligentCacheService.getHealthStatus().hitRate > 50,
                features: ['Semantic similarity', 'Context awareness', 'Pattern-based caching']
            },
            quality: {
                target: '> 80% pass rate',
                current: advancedQualityAssurance.getHealthStatus().passRate,
                achieved: advancedQualityAssurance.getHealthStatus().passRate > 80,
                features: ['Multi-dimensional scoring', 'Content filtering', 'Trend analysis']
            },
            streaming: {
                target: 'Real-time delivery',
                current: `${streamingDeliveryService.getHealthStatus().activeStreams} active streams`,
                features: ['Progressive delivery', 'Quality-based streaming', 'Adaptive delays']
            }
        };

        const achievementRate = Object.values(targets)
            .filter(t => t.achieved !== undefined)
            .reduce((sum, t) => sum + (t.achieved ? 1 : 0), 0) /
            Object.values(targets).filter(t => t.achieved !== undefined).length * 100;

        res.json({
            success: true,
            targets: {
                overview: {
                    achievementRate: Math.round(achievementRate),
                    allTargetsAchieved: achievementRate === 100
                },
                details: targets,
                optimizations: {
                    imageCompression: 'Advanced HEIC/WebP with 70%+ reduction',
                    streamingDelivery: 'Real-time progressive suggestion delivery',
                    intelligentCaching: 'Context-aware semantic caching',
                    qualityAssurance: 'Multi-dimensional quality scoring',
                    performanceMonitoring: 'Real-time alerting with auto-optimization'
                }
            },
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Error getting performance targets', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to retrieve performance targets'
        });
    }
});

/**
 * GET /api/performance/recommendations
 * System optimization recommendations
 */
router.get('/recommendations', async (req, res) => {
    try {
        const insights = await performanceMonitoringService.getPerformanceInsights();
        const recommendations = insights.recommendations || [];

        // Add service-specific recommendations
        const qualityHealth = advancedQualityAssurance.getHealthStatus();
        const cacheHealth = intelligentCacheService.getHealthStatus();

        if (qualityHealth.passRate < 85) {
            recommendations.push({
                type: 'quality',
                priority: 'medium',
                title: 'Improve Quality Pass Rate',
                description: `Current pass rate: ${qualityHealth.passRate}%`,
                actions: [
                    'Review quality thresholds',
                    'Enhance content filtering rules',
                    'Consider model parameter tuning'
                ]
            });
        }

        if (cacheHealth.hitRate < 60) {
            recommendations.push({
                type: 'caching',
                priority: 'medium',
                title: 'Optimize Cache Performance',
                description: `Current hit rate: ${cacheHealth.hitRate}%`,
                actions: [
                    'Increase cache TTL for high-quality responses',
                    'Enable preemptive caching for common patterns',
                    'Review semantic similarity thresholds'
                ]
            });
        }

        res.json({
            success: true,
            recommendations: {
                total: recommendations.length,
                highPriority: recommendations.filter(r => r.priority === 'high').length,
                mediumPriority: recommendations.filter(r => r.priority === 'medium').length,
                lowPriority: recommendations.filter(r => r.priority === 'low').length,
                items: recommendations
            },
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Error generating recommendations', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to generate recommendations'
        });
    }
});

/**
 * GET /api/performance/summary
 * Executive summary of system performance
 */
router.get('/summary', async (req, res) => {
    try {
        const dashboard = performanceMonitoringService.getPerformanceDashboard();
        const qualityHealth = advancedQualityAssurance.getHealthStatus();
        const cacheHealth = intelligentCacheService.getHealthStatus();
        const streamingHealth = streamingDeliveryService.getHealthStatus();

        const summary = {
            status: dashboard.overview.status,
            performance: {
                averageLatency: `${dashboard.latency.average}ms`,
                successRate: `${dashboard.overview.successRate}%`,
                targetAchievement: `${dashboard.targets.targetMet}%`,
                throughput: `${dashboard.throughput.requestsPerSecond} RPS`
            },
            optimization: {
                qualityScore: qualityHealth.avgQualityScore,
                cacheHitRate: `${cacheHealth.hitRate}%`,
                activeStreams: streamingHealth.activeStreams,
                compressionEnabled: true
            },
            alerts: {
                active: dashboard.alerts.active.length,
                recent: dashboard.alerts.recent.length
            },
            uptime: dashboard.overview.totalRequests > 0 ? 'Active' : 'Initializing',
            optimizations: [
                '✅ Advanced Image Compression (70%+ reduction)',
                '✅ Real-time Streaming Delivery',
                '✅ Intelligent Context-aware Caching',
                '✅ Multi-dimensional Quality Assurance',
                '✅ Real-time Performance Monitoring'
            ]
        };

        res.json({
            success: true,
            summary,
            timestamp: new Date().toISOString(),
            version: 'enhanced-ai-pipeline-v2.0'
        });

    } catch (error) {
        logger.error('Error generating performance summary', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to generate performance summary'
        });
    }
});

/**
 * POST /api/performance/test
 * Run performance optimization test suite
 */
router.post('/test', async (req, res) => {
    try {
        logger.info('Performance optimization test requested');

        // This would trigger the test suite
        // For now, return test configuration
        res.json({
            success: true,
            message: 'Performance test suite configured',
            testSuite: {
                available: true,
                location: './test-ai-pipeline-optimizations.js',
                categories: [
                    'Image Compression (70%+ target)',
                    'Streaming Delivery System',
                    'Intelligent Caching Layer',
                    'Quality Assurance Metrics',
                    'Performance Monitoring',
                    'End-to-End Integration'
                ]
            },
            runCommand: 'node test-ai-pipeline-optimizations.js',
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Error configuring performance test', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to configure performance test'
        });
    }
});

module.exports = router;