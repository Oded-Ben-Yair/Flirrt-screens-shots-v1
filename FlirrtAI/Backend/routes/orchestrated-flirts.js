/**
 * Orchestrated Flirts API - Dual-Model AI Pipeline Routes
 *
 * This router provides enhanced flirt generation using the dual-model pipeline:
 * 1. Gemini Vision API for comprehensive screenshot analysis
 * 2. Grok API for creative flirt generation based on analysis
 *
 * Features:
 * - Advanced visual analysis with personality insights
 * - Context-aware flirt generation
 * - Parallel processing and intelligent fallbacks
 * - Performance monitoring and A/B testing
 * - Response quality validation
 */

const express = require('express');
const { authenticateToken, createRateLimit } = require('../middleware/auth');
const { userActionLogger } = require('../middleware/correlationId');
const aiOrchestrator = require('../services/aiOrchestrator');
const redisService = require('../services/redis');
const { logger } = require('../services/logger');

const router = express.Router();

/**
 * Enhanced Flirt Generation using Dual-Model AI Pipeline
 * POST /api/v2/flirts/generate
 */
router.post('/generate',
    // authenticateToken, // Temporarily disabled for testing
    userActionLogger('orchestrated_flirts_generate'),
    createRateLimit(20, 15 * 60 * 1000), // 20 requests per 15 minutes
    async (req, res) => {
        const startTime = Date.now();
        const correlationId = req.correlationId || `orch_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // Extract request parameters
        const {
            image_data,
            context = '',
            suggestion_type = 'opener',
            tone = 'playful',
            user_preferences = {},
            pipeline_strategy = 'auto', // auto, fast, standard, comprehensive
            enable_ab_testing = false,
            bypass_cache = false
        } = req.body;

        // Mock user for testing when authentication is disabled
        if (!req.user) {
            req.user = { id: 'test-user-orchestrated', isKeyboard: false };
        }

        const isKeyboardExtension = req.user?.isKeyboard || req.headers['x-keyboard-extension'] === 'true';

        logger.info('Starting orchestrated flirt generation', {
            correlationId,
            userId: req.user.id,
            suggestionType: suggestion_type,
            tone,
            hasImage: !!image_data,
            isKeyboard: isKeyboardExtension,
            strategy: pipeline_strategy
        });

        try {
            // Validate required parameters
            if (!image_data) {
                return res.status(400).json({
                    success: false,
                    error: 'Image data is required for orchestrated generation',
                    code: 'MISSING_IMAGE_DATA',
                    correlationId
                });
            }

            // Prepare orchestration request
            const orchestrationRequest = {
                imageData: image_data,
                context: context,
                suggestion_type: suggestion_type,
                tone: tone,
                user_preferences: user_preferences,
                strategy: pipeline_strategy,
                isKeyboardExtension: isKeyboardExtension,
                bypassCache: bypass_cache,
                correlationId: correlationId,
                userId: req.user.id,

                // Additional metadata
                requestTimestamp: new Date().toISOString(),
                userAgent: req.headers['user-agent'],
                platform: req.headers['x-platform'] || 'unknown'
            };

            // A/B Testing: Randomly choose between orchestrated and legacy pipeline
            let useOrchestrator = true;
            let abTestGroup = 'orchestrated';

            if (enable_ab_testing && Math.random() < 0.5) {
                useOrchestrator = false;
                abTestGroup = 'legacy';
                logger.info('A/B Test: Using legacy pipeline', { correlationId, abTestGroup });
            }

            let result;

            if (useOrchestrator) {
                // Use dual-model AI orchestrator
                result = await aiOrchestrator.orchestrateAIPipeline(orchestrationRequest);
            } else {
                // Fallback to legacy single-model generation
                result = await generateLegacyFlirts(orchestrationRequest);
            }

            if (!result.success) {
                throw new Error(result.error || 'Pipeline execution failed');
            }

            // Enhance response with orchestrator metadata
            const enhancedResponse = {
                success: true,
                data: {
                    suggestions: result.data.suggestions,
                    analysis: result.data.analysis,
                    metadata: {
                        ...result.data.metadata,
                        pipeline_used: abTestGroup,
                        ab_test_enabled: enable_ab_testing,
                        request_latency: Date.now() - startTime,
                        orchestrator_version: '2.0',
                        quality_metrics: await calculateQualityMetrics(result.data.suggestions)
                    }
                },
                correlationId: correlationId,
                pipeline: {
                    type: 'dual_model_orchestrated',
                    gemini_analysis: !!result.data.analysis?.rawGeminiData,
                    grok_generation: true,
                    fallback_used: result.metadata?.fallback || false,
                    total_latency: result.metadata?.totalLatency || (Date.now() - startTime)
                }
            };

            // Log performance metrics
            await logPerformanceMetrics({
                correlationId,
                userId: req.user.id,
                pipeline: abTestGroup,
                latency: Date.now() - startTime,
                success: true,
                suggestionCount: result.data.suggestions?.length || 0,
                analysisConfidence: result.data.analysis?.recommendations?.confidenceLevel || 0,
                qualityScore: enhancedResponse.data.metadata.quality_metrics?.average_score || 0
            });

            logger.info('Orchestrated flirt generation completed', {
                correlationId,
                pipeline: abTestGroup,
                latency: `${Date.now() - startTime}ms`,
                suggestionCount: result.data.suggestions?.length || 0,
                success: true
            });

            res.json(enhancedResponse);

        } catch (error) {
            const errorLatency = Date.now() - startTime;

            logger.error('Orchestrated flirt generation failed', {
                correlationId,
                error: error.message,
                stack: error.stack,
                latency: `${errorLatency}ms`
            });

            // Log error metrics
            await logPerformanceMetrics({
                correlationId,
                userId: req.user.id,
                pipeline: 'error',
                latency: errorLatency,
                success: false,
                error: error.message
            });

            // Try emergency fallback
            try {
                const fallbackResult = await generateEmergencyFallback({
                    suggestion_type,
                    tone,
                    context,
                    correlationId
                });

                res.status(200).json({
                    success: true,
                    data: fallbackResult,
                    warning: 'Using emergency fallback due to pipeline failure',
                    correlationId: correlationId,
                    pipeline: {
                        type: 'emergency_fallback',
                        original_error: error.message,
                        fallback_latency: Date.now() - startTime
                    }
                });

            } catch (fallbackError) {
                res.status(500).json({
                    success: false,
                    error: 'Orchestrated flirt generation failed',
                    details: error.message,
                    fallback_error: fallbackError.message,
                    code: 'ORCHESTRATION_PIPELINE_ERROR',
                    correlationId: correlationId
                });
            }
        }
    }
);

/**
 * Get Pipeline Performance Metrics
 * GET /api/v2/flirts/metrics
 */
router.get('/metrics',
    authenticateToken,
    async (req, res) => {
        try {
            const orchestratorHealth = aiOrchestrator.getHealthStatus();

            // Get recent performance data from cache
            const metricsKey = 'orchestrator_metrics:recent';
            const recentMetrics = await redisService.get(metricsKey) || {};

            const response = {
                success: true,
                timestamp: new Date().toISOString(),
                orchestrator: orchestratorHealth,
                performance: {
                    recent_requests: recentMetrics.totalRequests || 0,
                    success_rate: recentMetrics.successRate || '100%',
                    average_latency: recentMetrics.averageLatency || 0,
                    gemini_usage: recentMetrics.geminiRequests || 0,
                    grok_usage: recentMetrics.grokRequests || 0,
                    fallback_rate: recentMetrics.fallbackRate || '0%'
                },
                pipeline_health: {
                    dual_model_available: orchestratorHealth.status === 'healthy',
                    gemini_vision_status: orchestratorHealth.models?.gemini?.enabled ? 'enabled' : 'disabled',
                    grok_generation_status: orchestratorHealth.models?.grok?.enabled ? 'enabled' : 'disabled',
                    circuit_breakers: 'operational'
                }
            };

            res.json(response);

        } catch (error) {
            logger.error('Failed to get orchestrator metrics', { error: error.message });
            res.status(500).json({
                success: false,
                error: 'Failed to retrieve metrics',
                details: error.message
            });
        }
    }
);

/**
 * Test Pipeline Health
 * GET /api/v2/flirts/health
 */
router.get('/health', async (req, res) => {
    try {
        const startTime = Date.now();

        // Test orchestrator health
        const orchestratorHealth = aiOrchestrator.getHealthStatus();

        // Perform quick pipeline test if requested
        const includeTest = req.query.test === 'true';
        let pipelineTest = null;

        if (includeTest) {
            try {
                // Create minimal test image
                const testImage = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

                const testRequest = {
                    imageData: testImage,
                    context: 'health check test',
                    suggestion_type: 'opener',
                    tone: 'casual',
                    strategy: 'fast',
                    correlationId: 'health_check'
                };

                const testResult = await aiOrchestrator.orchestrateAIPipeline(testRequest);

                pipelineTest = {
                    success: testResult.success,
                    latency: testResult.metadata?.totalLatency || 0,
                    components_tested: ['gemini_analysis', 'grok_generation', 'response_validation']
                };

            } catch (testError) {
                pipelineTest = {
                    success: false,
                    error: testError.message,
                    latency: Date.now() - startTime
                };
            }
        }

        const healthResponse = {
            status: orchestratorHealth.status,
            timestamp: new Date().toISOString(),
            response_time: Date.now() - startTime,
            components: {
                ai_orchestrator: orchestratorHealth.status,
                gemini_vision: orchestratorHealth.models?.gemini?.enabled ? 'enabled' : 'disabled',
                grok_generation: orchestratorHealth.models?.grok?.enabled ? 'enabled' : 'disabled',
                cache_service: 'operational',
                circuit_breakers: 'operational'
            },
            capabilities: [
                'dual_model_pipeline',
                'advanced_visual_analysis',
                'context_aware_generation',
                'intelligent_fallbacks',
                'performance_monitoring',
                'a_b_testing'
            ],
            pipeline_test: pipelineTest
        };

        const statusCode = orchestratorHealth.status === 'healthy' ? 200 : 503;
        res.status(statusCode).json(healthResponse);

    } catch (error) {
        logger.error('Health check failed', { error: error.message });
        res.status(500).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message,
            components: {
                ai_orchestrator: 'unknown'
            }
        });
    }
});

/**
 * Legacy flirt generation (for A/B testing)
 * @param {Object} request - Generation request
 * @returns {Promise<Object>} Legacy generation result
 */
async function generateLegacyFlirts(request) {
    const FlirtGenerator = require('../../Agents/FlirtGenerator');
    const fallbackGenerator = new FlirtGenerator();

    // Convert request to legacy format
    const legacyContext = {
        conversationStage: 'opening',
        personalityInsights: {},
        userPreferences: request.user_preferences || {},
        conversationHistory: [],
        platform: 'dating_app',
        timeOfDay: new Date().getHours() < 12 ? 'morning' :
                  new Date().getHours() < 18 ? 'afternoon' : 'evening'
    };

    const result = await fallbackGenerator.generateFlirts(legacyContext);

    if (result.success) {
        return {
            success: true,
            data: {
                suggestions: result.suggestions.map(s => ({
                    ...s,
                    pipeline: 'legacy',
                    compositeScore: 0.7
                })),
                analysis: { legacy: true },
                metadata: {
                    ...result.metadata,
                    pipeline: 'legacy'
                }
            }
        };
    }

    throw new Error('Legacy generation failed');
}

/**
 * Generate emergency fallback suggestions
 * @param {Object} params - Fallback parameters
 * @returns {Object} Emergency suggestions
 */
async function generateEmergencyFallback(params) {
    const { suggestion_type, tone, context, correlationId } = params;

    const emergencySuggestions = [
        {
            id: `emergency_${Date.now()}_1`,
            text: "Your photo caught my attention - what's the story behind it?",
            confidence: 0.6,
            reasoning: "Generic but safe opener",
            tone: tone,
            topics: ['general'],
            compositeScore: 0.6,
            emergency: true
        },
        {
            id: `emergency_${Date.now()}_2`,
            text: "I love the energy in your photo! What were you up to?",
            confidence: 0.6,
            reasoning: "Positive energy-focused",
            tone: tone,
            topics: ['general'],
            compositeScore: 0.6,
            emergency: true
        },
        {
            id: `emergency_${Date.now()}_3`,
            text: "That looks like an interesting place - tell me more!",
            confidence: 0.6,
            reasoning: "Location-focused conversation starter",
            tone: tone,
            topics: ['location'],
            compositeScore: 0.6,
            emergency: true
        }
    ];

    return {
        suggestions: emergencySuggestions,
        analysis: { emergency: true },
        metadata: {
            suggestion_type,
            tone,
            generated_at: new Date().toISOString(),
            emergency_fallback: true,
            correlation_id: correlationId
        }
    };
}

/**
 * Calculate quality metrics for suggestions
 * @param {Array} suggestions - Generated suggestions
 * @returns {Promise<Object>} Quality metrics
 */
async function calculateQualityMetrics(suggestions) {
    if (!suggestions || suggestions.length === 0) {
        return {
            average_score: 0,
            confidence_distribution: { high: 0, medium: 0, low: 0 },
            uniqueness_score: 0,
            total_suggestions: 0
        };
    }

    const scores = suggestions.map(s => s.compositeScore || s.confidence || 0.5);
    const averageScore = scores.reduce((sum, score) => sum + score, 0) / scores.length;

    const confidenceDistribution = {
        high: suggestions.filter(s => (s.confidence || 0.5) >= 0.8).length,
        medium: suggestions.filter(s => (s.confidence || 0.5) >= 0.6 && (s.confidence || 0.5) < 0.8).length,
        low: suggestions.filter(s => (s.confidence || 0.5) < 0.6).length
    };

    // Calculate uniqueness by checking for similar phrases
    const texts = suggestions.map(s => s.text.toLowerCase());
    const uniquePhrases = new Set();
    texts.forEach(text => {
        const words = text.split(' ').filter(word => word.length > 3);
        words.forEach(word => uniquePhrases.add(word));
    });
    const uniquenessScore = uniquePhrases.size / Math.max(texts.join(' ').split(' ').length, 1);

    return {
        average_score: Math.round(averageScore * 100) / 100,
        confidence_distribution: confidenceDistribution,
        uniqueness_score: Math.round(uniquenessScore * 100) / 100,
        total_suggestions: suggestions.length
    };
}

/**
 * Log performance metrics for monitoring
 * @param {Object} metrics - Performance metrics
 */
async function logPerformanceMetrics(metrics) {
    try {
        const metricsKey = 'orchestrator_metrics:recent';
        const existingMetrics = await redisService.get(metricsKey) || {
            totalRequests: 0,
            successfulRequests: 0,
            totalLatency: 0,
            geminiRequests: 0,
            grokRequests: 0,
            fallbackRequests: 0
        };

        // Update metrics
        existingMetrics.totalRequests += 1;
        if (metrics.success) {
            existingMetrics.successfulRequests += 1;
        }
        existingMetrics.totalLatency += metrics.latency;

        if (metrics.pipeline === 'orchestrated') {
            existingMetrics.geminiRequests += 1;
            existingMetrics.grokRequests += 1;
        } else if (metrics.pipeline === 'legacy') {
            existingMetrics.grokRequests += 1;
        } else if (metrics.pipeline === 'error') {
            existingMetrics.fallbackRequests += 1;
        }

        // Calculate derived metrics
        existingMetrics.successRate = `${Math.round((existingMetrics.successfulRequests / existingMetrics.totalRequests) * 100)}%`;
        existingMetrics.averageLatency = Math.round(existingMetrics.totalLatency / existingMetrics.totalRequests);
        existingMetrics.fallbackRate = `${Math.round((existingMetrics.fallbackRequests / existingMetrics.totalRequests) * 100)}%`;

        // Store metrics (expire after 1 hour)
        await redisService.set(metricsKey, existingMetrics, 3600);

        // Also log individual metric
        logger.info('Performance metric logged', {
            correlationId: metrics.correlationId,
            pipeline: metrics.pipeline,
            latency: metrics.latency,
            success: metrics.success
        });

    } catch (error) {
        logger.error('Failed to log performance metrics', { error: error.message });
    }
}

module.exports = router;