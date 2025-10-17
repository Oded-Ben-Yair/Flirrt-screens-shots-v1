/**
 * Streaming API Routes - Real-time Progressive AI Analysis
 *
 * This router provides streaming endpoints for real-time AI analysis with
 * progressive delivery of suggestions as they are generated. Optimized for
 * sub-12s complete analysis with immediate user feedback.
 *
 * Features:
 * - WebSocket-based streaming analysis
 * - Progressive suggestion delivery
 * - Real-time status updates
 * - Priority-based processing
 * - Performance monitoring
 */

const express = require('express');
const { authenticateToken, createRateLimit } = require('../middleware/auth');
const { userActionLogger } = require('../middleware/correlationId');
const streamingService = require('../services/streamingService');
const webSocketService = require('../services/websocketService');
const queueService = require('../services/queueService');
const { logger } = require('../services/logger');

const router = express.Router();

/**
 * Start Streaming Analysis
 * POST /api/v1/stream/analyze
 */
router.post('/analyze',
    // authenticateToken, // Temporarily disabled for testing
    userActionLogger('streaming_analyze'),
    createRateLimit(30, 15 * 60 * 1000), // 30 requests per 15 minutes for streaming
    async (req, res) => {
        const startTime = Date.now();
        const correlationId = req.correlationId || `stream_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // Extract request parameters
        const {
            image_data,
            context = '',
            suggestion_type = 'opener',
            tone = 'playful',
            user_preferences = {},
            priority = 'normal', // normal, high, urgent
            strategy = 'auto', // auto, fast, standard, comprehensive
            enable_websocket = true,
            timeout = 15000 // Maximum 15 seconds
        } = req.body;

        // Mock user for testing when authentication is disabled
        if (!req.user) {
            req.user = { id: 'test-user-streaming', isKeyboard: false };
        }

        const isKeyboardExtension = req.user?.isKeyboard || req.headers['x-keyboard-extension'] === 'true';

        logger.info('Starting streaming analysis', {
            correlationId,
            userId: req.user.id,
            suggestionType: suggestion_type,
            tone,
            hasImage: !!image_data,
            isKeyboard: isKeyboardExtension,
            strategy,
            priority,
            enableWebSocket: enable_websocket
        });

        try {
            // Validate required parameters
            if (!image_data) {
                return res.status(400).json({
                    success: false,
                    error: 'Image data is required for streaming analysis',
                    code: 'MISSING_IMAGE_DATA',
                    correlationId
                });
            }

            // Validate image data format
            if (!image_data.startsWith('data:image/')) {
                return res.status(400).json({
                    success: false,
                    error: 'Invalid image data format. Must be base64 data URL',
                    code: 'INVALID_IMAGE_FORMAT',
                    correlationId
                });
            }

            // Check WebSocket connection if streaming is enabled
            if (enable_websocket) {
                const wsHealth = webSocketService.getHealthStatus();
                if (wsHealth.status !== 'online') {
                    logger.warn('WebSocket service unavailable, falling back to polling mode', {
                        correlationId,
                        wsStatus: wsHealth.status
                    });
                }
            }

            // Prepare streaming request
            const streamingRequest = {
                userId: req.user.id,
                correlationId,
                imageData: image_data,
                context,
                suggestionType: suggestion_type,
                tone,
                userPreferences: user_preferences,
                priority,
                strategy,
                isKeyboardExtension,
                enableWebSocket: enable_websocket,
                timeout,

                // Additional metadata for optimization
                requestTimestamp: new Date().toISOString(),
                userAgent: req.headers['user-agent'],
                platform: req.headers['x-platform'] || 'unknown',
                clientIP: req.ip,
                imageSize: image_data.length
            };

            // Start the streaming analysis
            const streamId = await streamingService.startStream(streamingRequest);

            // Return immediate response with stream information
            const response = {
                success: true,
                streamId,
                correlationId,
                message: 'Streaming analysis started',
                websocket: {
                    enabled: enable_websocket,
                    endpoint: enable_websocket ? `/ws?token=${req.headers.authorization?.split(' ')[1] || 'test-token'}` : null,
                    subscription_channel: `user:${req.user.id}:streams`
                },
                polling: {
                    status_endpoint: `/api/v1/stream/status/${streamId}`,
                    recommended_interval: 1000 // 1 second
                },
                estimated_duration: streamingService.estimateStreamDuration({
                    metadata: {
                        imageSize: image_data.length,
                        strategy,
                        isKeyboard: isKeyboardExtension
                    }
                }),
                timeout_at: new Date(Date.now() + timeout).toISOString(),
                phases: [
                    { name: 'image_analysis', progress_range: [0, 30] },
                    { name: 'context_processing', progress_range: [30, 50] },
                    { name: 'suggestion_generation', progress_range: [50, 80] },
                    { name: 'quality_validation', progress_range: [80, 100] }
                ]
            };

            logger.info('Streaming analysis initiated', {
                correlationId,
                streamId,
                estimatedDuration: response.estimated_duration,
                latency: `${Date.now() - startTime}ms`
            });

            res.json(response);

        } catch (error) {
            const errorLatency = Date.now() - startTime;

            logger.error('Failed to start streaming analysis', {
                correlationId,
                error: error.message,
                stack: error.stack,
                latency: `${errorLatency}ms`
            });

            res.status(500).json({
                success: false,
                error: 'Failed to start streaming analysis',
                details: error.message,
                code: 'STREAMING_START_ERROR',
                correlationId
            });
        }
    }
);

/**
 * Get Stream Status
 * GET /api/v1/stream/status/:streamId
 */
router.get('/status/:streamId',
    // authenticateToken, // Temporarily disabled for testing
    createRateLimit(100, 5 * 60 * 1000), // 100 requests per 5 minutes for status checks
    async (req, res) => {
        const { streamId } = req.params;
        const correlationId = req.query.correlationId || `status_${Date.now()}`;

        try {
            const streamStatus = streamingService.getStreamStatus(streamId);

            if (!streamStatus) {
                return res.status(404).json({
                    success: false,
                    error: 'Stream not found or expired',
                    code: 'STREAM_NOT_FOUND',
                    streamId,
                    correlationId
                });
            }

            // TODO: Verify user owns this stream (when auth is enabled)
            // if (req.user && streamStatus.userId !== req.user.id) {
            //     return res.status(403).json({
            //         success: false,
            //         error: 'Access denied',
            //         code: 'STREAM_ACCESS_DENIED'
            //     });
            // }

            const response = {
                success: true,
                streamId,
                status: streamStatus.status,
                progress: streamStatus.progress,
                currentPhase: streamStatus.currentPhase,
                duration: streamStatus.duration,
                estimatedTimeRemaining: streamStatus.estimatedTimeRemaining,
                suggestionsGenerated: streamStatus.suggestionsGenerated,
                analysisPhases: streamStatus.analysisPhases,
                timestamp: new Date().toISOString(),
                correlationId
            };

            // Include suggestions if stream is completed
            if (streamStatus.status === 'completed' && streamStatus.suggestions) {
                response.suggestions = streamStatus.suggestions;
                response.finalAnalysis = streamStatus.analysisData;
            }

            res.json(response);

        } catch (error) {
            logger.error('Failed to get stream status', {
                streamId,
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to get stream status',
                details: error.message,
                code: 'STREAM_STATUS_ERROR',
                streamId,
                correlationId
            });
        }
    }
);

/**
 * Cancel Stream
 * DELETE /api/v1/stream/:streamId
 */
router.delete('/:streamId',
    // authenticateToken, // Temporarily disabled for testing
    async (req, res) => {
        const { streamId } = req.params;
        const correlationId = req.query.correlationId || `cancel_${Date.now()}`;

        try {
            const streamStatus = streamingService.getStreamStatus(streamId);

            if (!streamStatus) {
                return res.status(404).json({
                    success: false,
                    error: 'Stream not found or already completed',
                    code: 'STREAM_NOT_FOUND',
                    streamId,
                    correlationId
                });
            }

            // TODO: Verify user owns this stream (when auth is enabled)

            // Cancel the stream
            const cancelled = await streamingService.cancelStream(streamId);

            if (cancelled) {
                logger.info('Stream cancelled by user', {
                    streamId,
                    correlationId,
                    userId: req.user?.id || 'test-user'
                });

                res.json({
                    success: true,
                    message: 'Stream cancelled successfully',
                    streamId,
                    correlationId
                });
            } else {
                res.status(400).json({
                    success: false,
                    error: 'Stream could not be cancelled',
                    code: 'STREAM_CANCEL_FAILED',
                    streamId,
                    correlationId
                });
            }

        } catch (error) {
            logger.error('Failed to cancel stream', {
                streamId,
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to cancel stream',
                details: error.message,
                code: 'STREAM_CANCEL_ERROR',
                streamId,
                correlationId
            });
        }
    }
);

/**
 * Get Streaming Service Health
 * GET /api/v1/stream/health
 */
router.get('/health', async (req, res) => {
    try {
        const streamingHealth = streamingService.getHealthStatus();
        const wsHealth = webSocketService.getHealthStatus();
        const queueHealth = queueService.getHealthStatus();

        const overallStatus =
            streamingHealth.status === 'healthy' &&
            wsHealth.status === 'online' &&
            queueHealth.initialized ? 'healthy' : 'degraded';

        const response = {
            status: overallStatus,
            timestamp: new Date().toISOString(),
            components: {
                streaming_service: streamingHealth.status,
                websocket_service: wsHealth.status,
                queue_service: queueHealth.initialized ? 'healthy' : 'unhealthy'
            },
            metrics: {
                active_streams: streamingHealth.activeStreams,
                peak_concurrency: streamingHealth.peakConcurrency,
                average_duration: streamingHealth.averageDuration,
                websocket_connections: wsHealth.connections?.active || 0,
                queue_size: queueHealth.size || 0
            },
            capabilities: [
                'real_time_streaming',
                'progressive_delivery',
                'websocket_communication',
                'priority_processing',
                'performance_monitoring'
            ]
        };

        const statusCode = overallStatus === 'healthy' ? 200 : 503;
        res.status(statusCode).json(response);

    } catch (error) {
        logger.error('Streaming health check failed', { error: error.message });
        res.status(500).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message,
            components: {
                streaming_service: 'unknown',
                websocket_service: 'unknown',
                queue_service: 'unknown'
            }
        });
    }
});

/**
 * Get Streaming Metrics (for monitoring)
 * GET /api/v1/stream/metrics
 */
router.get('/metrics',
    authenticateToken,
    async (req, res) => {
        try {
            const streamingHealth = streamingService.getHealthStatus();
            const wsHealth = webSocketService.getHealthStatus();

            const response = {
                success: true,
                timestamp: new Date().toISOString(),
                streaming: {
                    metrics: streamingHealth.metrics,
                    active_streams: streamingHealth.activeStreams,
                    memory_usage: streamingHealth.memoryUsage
                },
                websockets: {
                    connections: wsHealth.connections,
                    users: wsHealth.users,
                    metrics: wsHealth.metrics
                },
                performance: {
                    average_stream_duration: streamingHealth.averageDuration,
                    peak_concurrent_streams: streamingHealth.peakConcurrency,
                    uptime: streamingHealth.uptime
                }
            };

            res.json(response);

        } catch (error) {
            logger.error('Failed to get streaming metrics', { error: error.message });
            res.status(500).json({
                success: false,
                error: 'Failed to retrieve streaming metrics',
                details: error.message
            });
        }
    }
);

/**
 * Test Streaming Performance
 * POST /api/v1/stream/test
 */
router.post('/test',
    // authenticateToken, // Disabled for testing
    createRateLimit(10, 10 * 60 * 1000), // 10 requests per 10 minutes
    async (req, res) => {
        const startTime = Date.now();
        const correlationId = `stream_test_${Date.now()}`;

        try {
            // Create minimal test image
            const testImage = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

            const testRequest = {
                userId: req.user?.id || 'test-user-performance',
                correlationId,
                imageData: testImage,
                context: 'Performance test',
                suggestionType: 'opener',
                tone: 'casual',
                strategy: 'fast',
                priority: 'normal',
                isKeyboardExtension: false,
                enableWebSocket: true,
                timeout: 10000
            };

            // Start test stream
            const streamId = await streamingService.startStream(testRequest);

            // Wait for completion or timeout
            const maxWait = 10000; // 10 seconds
            const pollInterval = 500; // 500ms
            let elapsed = 0;
            let finalStatus = null;

            while (elapsed < maxWait) {
                await new Promise(resolve => setTimeout(resolve, pollInterval));
                elapsed += pollInterval;

                const status = streamingService.getStreamStatus(streamId);
                if (!status || status.status === 'completed' || status.status === 'error') {
                    finalStatus = status;
                    break;
                }
            }

            const totalDuration = Date.now() - startTime;

            const testResult = {
                success: !!finalStatus && finalStatus.status === 'completed',
                streamId,
                duration: totalDuration,
                status: finalStatus?.status || 'timeout',
                progress: finalStatus?.progress || 0,
                suggestionsGenerated: finalStatus?.suggestionsGenerated || 0,
                phases: finalStatus?.analysisPhases || [],
                performance: {
                    total_duration: totalDuration,
                    target_duration: 8000, // 8 second target
                    met_target: totalDuration <= 8000,
                    efficiency: finalStatus ? Math.round((finalStatus.progress / 100) * 100) : 0
                },
                correlationId
            };

            logger.info('Streaming performance test completed', {
                correlationId,
                duration: totalDuration,
                success: testResult.success,
                metTarget: testResult.performance.met_target
            });

            res.json(testResult);

        } catch (error) {
            const errorDuration = Date.now() - startTime;

            logger.error('Streaming performance test failed', {
                correlationId,
                duration: errorDuration,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Performance test failed',
                details: error.message,
                duration: errorDuration,
                correlationId
            });
        }
    }
);

module.exports = router;