/**
 * Grok-4 Fast API Routes - High-Performance AI Integration
 *
 * Optimized routes for Grok-4 Fast with:
 * - Sub-second response targets for simple requests
 * - Intelligent model selection and load balancing
 * - Real-time streaming support
 * - Advanced caching and performance monitoring
 * - Smart fallback strategies
 */

const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');

const { logger } = require('../services/logger');
const grok4FastService = require('../services/grok4FastService');
const enhancedAIOrchestrator = require('../services/enhancedAIOrchestrator');
// const performanceMetrics = require('../services/performanceMetrics'); // Not available yet

// Rate limiting for Grok-4 Fast endpoints
const grok4FastLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 100, // More generous limit for fast model
    message: 'Too many Grok-4 Fast requests, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn('Grok-4 Fast rate limit exceeded', {
            ip: req.ip,
            userAgent: req.get('User-Agent'),
            endpoint: req.path
        });
        res.status(429).json({
            success: false,
            error: 'Rate limit exceeded',
            retryAfter: 60
        });
    }
});

// Apply rate limiting to all routes
router.use(grok4FastLimiter);

/**
 * POST /generate-fast-flirts
 * Ultra-fast flirt generation using Grok-4 Fast with intelligent model selection
 */
router.post('/generate-fast-flirts', async (req, res) => {
    const startTime = Date.now();
    const correlationId = req.headers['x-correlation-id'] ||
                         `grok4_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    try {
        // Request validation
        const { error: validationError } = validateFlirtRequest(req.body);
        if (validationError) {
            return res.status(400).json({
                success: false,
                error: 'Invalid request',
                details: validationError.details[0].message,
                correlationId
            });
        }

        // Prepare request with optimization hints
        const optimizedRequest = {
            ...req.body,
            correlationId,
            isKeyboardExtension: req.headers['x-keyboard-extension'] === 'true',
            fastMode: req.query.fast === 'true'
        };

        // Set streaming callback for real-time updates
        let streamingData = null;
        const streamCallback = req.query.stream === 'true' ? (chunk) => {
            if (!streamingData) streamingData = [];
            streamingData.push(chunk);

            // Send Server-Sent Events if supported
            if (req.headers.accept?.includes('text/event-stream')) {
                res.write(`data: ${JSON.stringify(chunk)}\n\n`);
            }
        } : null;

        // Use enhanced orchestrator for intelligent model selection
        const result = await enhancedAIOrchestrator.orchestrateOptimizedPipeline(
            optimizedRequest,
            {
                streamCallback,
                bypassCache: req.query.bypass_cache === 'true',
                fastMode: optimizedRequest.fastMode
            }
        );

        const totalLatency = Date.now() - startTime;

        // Record performance metrics (when available)
        try {
            if (typeof performanceMetrics !== 'undefined') {
                await performanceMetrics.recordMetric({
                    endpoint: '/grok4-fast/generate-fast-flirts',
                    correlationId,
                    latency: totalLatency,
                    success: result.success,
                    tier: result.metadata?.tier,
                    model: result.metadata?.model,
                    cacheHit: result.metadata?.cached || false,
                    targetMet: result.metadata?.targetMet || false
                });
            }
        } catch (metricsError) {
            // Silently ignore metrics errors for now
        }

        // Response with performance metadata
        const response = {
            success: true,
            data: result.data,
            performance: {
                totalLatency: `${totalLatency}ms`,
                tier: result.metadata?.tier,
                model: result.metadata?.model,
                targetMet: result.metadata?.targetMet,
                cacheHit: result.metadata?.cached || false,
                streamingUsed: !!streamCallback
            },
            metadata: {
                correlationId,
                timestamp: new Date().toISOString(),
                version: 'grok-4-fast-v1'
            }
        };

        // Log successful request
        logger.info('Grok-4 Fast generation completed', {
            correlationId,
            endpoint: '/generate-fast-flirts',
            totalLatency: `${totalLatency}ms`,
            tier: result.metadata?.tier,
            targetMet: result.metadata?.targetMet,
            suggestions: result.data?.suggestions?.length || 0
        });

        res.json(response);

    } catch (error) {
        const errorLatency = Date.now() - startTime;

        // Record error metrics (when available)
        try {
            if (typeof performanceMetrics !== 'undefined') {
                await performanceMetrics.recordMetric({
                    endpoint: '/grok4-fast/generate-fast-flirts',
                    correlationId,
                    latency: errorLatency,
                    success: false,
                    error: error.message
                });
            }
        } catch (metricsError) {
            // Silently ignore metrics errors for now
        }

        logger.error('Grok-4 Fast generation failed', {
            correlationId,
            error: error.message,
            stack: error.stack,
            latency: `${errorLatency}ms`
        });

        res.status(500).json({
            success: false,
            error: 'Generation failed',
            message: error.message,
            correlationId,
            latency: `${errorLatency}ms`
        });
    }
});

/**
 * POST /generate-streaming-flirts
 * Real-time streaming flirt generation with Server-Sent Events
 */
router.post('/generate-streaming-flirts', async (req, res) => {
    const correlationId = req.headers['x-correlation-id'] ||
                         `stream_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Set up Server-Sent Events
    res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control'
    });

    // Send initial connection event
    res.write(`data: ${JSON.stringify({
        type: 'connection',
        correlationId,
        timestamp: new Date().toISOString()
    })}\n\n`);

    try {
        const startTime = Date.now();

        // Validate request
        const { error: validationError } = validateFlirtRequest(req.body);
        if (validationError) {
            res.write(`data: ${JSON.stringify({
                type: 'error',
                error: 'Invalid request',
                details: validationError.details[0].message
            })}\n\n`);
            res.end();
            return;
        }

        // Prepare streaming request
        const streamingRequest = {
            ...req.body,
            correlationId,
            isKeyboardExtension: req.headers['x-keyboard-extension'] === 'true'
        };

        // Stream callback for real-time updates
        const streamCallback = (chunk) => {
            res.write(`data: ${JSON.stringify(chunk)}\n\n`);
        };

        // Use Grok-4 Fast with streaming
        const result = await grok4FastService.generateFlirts(streamingRequest, {
            streaming: true,
            streamCallback,
            correlationId
        });

        // Send final result
        res.write(`data: ${JSON.stringify({
            type: 'complete',
            data: result.data,
            metadata: {
                correlationId,
                totalLatency: Date.now() - startTime,
                model: result.metadata?.model
            }
        })}\n\n`);

        res.end();

        logger.info('Streaming generation completed', {
            correlationId,
            totalLatency: `${Date.now() - startTime}ms`,
            model: result.metadata?.model
        });

    } catch (error) {
        res.write(`data: ${JSON.stringify({
            type: 'error',
            error: error.message,
            correlationId
        })}\n\n`);

        res.end();

        logger.error('Streaming generation failed', {
            correlationId,
            error: error.message
        });
    }
});

/**
 * GET /performance-metrics
 * Get detailed performance metrics for Grok-4 Fast services
 */
router.get('/performance-metrics', async (req, res) => {
    try {
        const grok4Metrics = grok4FastService.getPerformanceMetrics();
        const orchestratorMetrics = enhancedAIOrchestrator.getPerformanceReport();
        const systemMetrics = typeof performanceMetrics !== 'undefined' ?
            await performanceMetrics.getSystemMetrics() : { status: 'not available' };

        res.json({
            success: true,
            metrics: {
                grok4Fast: grok4Metrics,
                orchestrator: orchestratorMetrics,
                system: systemMetrics
            },
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Failed to retrieve performance metrics', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to retrieve metrics',
            message: error.message
        });
    }
});

/**
 * GET /health
 * Comprehensive health check for Grok-4 Fast services
 */
router.get('/health', async (req, res) => {
    try {
        const grok4Health = grok4FastService.getHealthStatus();
        const orchestratorHealth = enhancedAIOrchestrator.getHealthStatus();

        // Aggregate health status
        const overallStatus = (grok4Health.status === 'healthy' &&
                              orchestratorHealth.status === 'healthy') ? 'healthy' : 'degraded';

        res.json({
            success: true,
            status: overallStatus,
            services: {
                grok4Fast: grok4Health,
                orchestrator: orchestratorHealth
            },
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Health check failed', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            status: 'unhealthy',
            error: error.message
        });
    }
});

/**
 * POST /benchmark
 * Performance benchmark testing for different model configurations
 */
router.post('/benchmark', async (req, res) => {
    const correlationId = `benchmark_${Date.now()}`;

    try {
        const benchmarkRequest = {
            context: "Profile photo of someone hiking with beautiful mountain scenery",
            suggestion_type: "opener",
            tone: "playful",
            correlationId
        };

        const benchmarkResults = {};

        // Test Tier 1 (Non-reasoning)
        logger.info('Running Tier 1 benchmark', { correlationId });
        const tier1Start = Date.now();
        const tier1Result = await grok4FastService.generateFlirts(benchmarkRequest, {
            forceModel: 'nonReasoning'
        });
        benchmarkResults.tier1 = {
            latency: Date.now() - tier1Start,
            model: 'grok-4-fast-non-reasoning',
            success: tier1Result.success,
            qualityScore: tier1Result.data?.qualityScore
        };

        // Test Tier 2 (Reasoning)
        logger.info('Running Tier 2 benchmark', { correlationId });
        const tier2Start = Date.now();
        const tier2Result = await grok4FastService.generateFlirts(benchmarkRequest, {
            forceModel: 'reasoning'
        });
        benchmarkResults.tier2 = {
            latency: Date.now() - tier2Start,
            model: 'grok-4-fast-reasoning',
            success: tier2Result.success,
            qualityScore: tier2Result.data?.qualityScore
        };

        // Test Enhanced Orchestrator
        logger.info('Running orchestrator benchmark', { correlationId });
        const orchestratorStart = Date.now();
        const orchestratorResult = await enhancedAIOrchestrator.orchestrateOptimizedPipeline(
            benchmarkRequest
        );
        benchmarkResults.orchestrator = {
            latency: Date.now() - orchestratorStart,
            tier: orchestratorResult.metadata?.tier,
            model: orchestratorResult.metadata?.model,
            success: orchestratorResult.success,
            qualityScore: orchestratorResult.data?.qualityScore
        };

        res.json({
            success: true,
            benchmark: benchmarkResults,
            analysis: {
                fastestResponse: Object.entries(benchmarkResults)
                    .sort(([,a], [,b]) => a.latency - b.latency)[0],
                targets: {
                    tier1: '< 1000ms',
                    tier2: '< 3000ms',
                    tier3: '< 5000ms'
                }
            },
            correlationId,
            timestamp: new Date().toISOString()
        });

        logger.info('Benchmark completed', {
            correlationId,
            results: benchmarkResults
        });

    } catch (error) {
        logger.error('Benchmark failed', {
            correlationId,
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Benchmark failed',
            message: error.message,
            correlationId
        });
    }
});

/**
 * POST /reset-metrics
 * Reset performance metrics (admin endpoint)
 */
router.post('/reset-metrics', async (req, res) => {
    try {
        grok4FastService.resetMetrics();
        enhancedAIOrchestrator.resetMetrics();

        logger.info('Grok-4 Fast metrics reset');

        res.json({
            success: true,
            message: 'Metrics reset successfully',
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        logger.error('Failed to reset metrics', {
            error: error.message
        });

        res.status(500).json({
            success: false,
            error: 'Failed to reset metrics',
            message: error.message
        });
    }
});

/**
 * Request validation using Joi
 */
function validateFlirtRequest(body) {
    const Joi = require('joi');

    const schema = Joi.object({
        context: Joi.string().max(5000).optional(),
        suggestion_type: Joi.string().valid(
            'opener', 'response', 'question', 'compliment', 'playful', 'witty'
        ).default('opener'),
        tone: Joi.string().valid(
            'playful', 'witty', 'romantic', 'casual', 'confident', 'sweet', 'intellectual'
        ).default('playful'),
        user_preferences: Joi.object().optional(),
        imageData: Joi.string().optional(),
        platform: Joi.string().optional()
    });

    return schema.validate(body);
}

/**
 * Middleware for request logging with performance tracking
 */
router.use((req, res, next) => {
    const startTime = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - startTime;

        logger.info('Grok-4 Fast API request completed', {
            method: req.method,
            path: req.path,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            correlationId: req.headers['x-correlation-id'],
            userAgent: req.get('User-Agent'),
            ip: req.ip
        });
    });

    next();
});

module.exports = router;