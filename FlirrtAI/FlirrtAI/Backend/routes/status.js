/**
 * Real-time Status API Routes - Live Progress Updates
 *
 * This router provides real-time status endpoints for monitoring
 * upload queues, streaming analysis, and system performance with
 * WebSocket integration for live updates.
 *
 * Features:
 * - Real-time upload queue status
 * - Streaming analysis progress
 * - System performance metrics
 * - WebSocket status updates
 * - Health monitoring
 */

const express = require('express');
const { authenticateToken, createRateLimit } = require('../middleware/auth');
const { userActionLogger } = require('../middleware/correlationId');
const streamingService = require('../services/streamingService');
const uploadQueueService = require('../services/uploadQueueService');
const webSocketService = require('../services/websocketService');
const queueService = require('../services/queueService');
const { logger } = require('../services/logger');

const router = express.Router();

/**
 * Get Real-time System Status
 * GET /api/v1/status/system
 */
router.get('/system',
    // authenticateToken, // Temporarily disabled for testing
    createRateLimit(60, 5 * 60 * 1000), // 60 requests per 5 minutes
    async (req, res) => {
        const startTime = Date.now();
        const correlationId = req.query.correlationId || `status_${Date.now()}`;

        try {
            // Gather status from all services
            const [
                streamingHealth,
                uploadQueueHealth,
                webSocketHealth,
                queueHealth
            ] = await Promise.all([
                streamingService.getHealthStatus(),
                uploadQueueService.getHealthStatus(),
                webSocketService.getHealthStatus(),
                queueService.getHealthStatus()
            ]);

            // Determine overall system status
            const componentStatuses = [
                streamingHealth.status,
                uploadQueueHealth.status,
                webSocketHealth.status,
                queueHealth.initialized ? 'healthy' : 'unhealthy'
            ];

            const overallStatus = componentStatuses.every(status => status === 'healthy') ? 'healthy' :
                                 componentStatuses.some(status => status === 'healthy') ? 'degraded' : 'unhealthy';

            const systemStatus = {
                status: overallStatus,
                timestamp: new Date().toISOString(),
                response_time: Date.now() - startTime,
                correlationId,

                // Component status
                components: {
                    streaming_service: {
                        status: streamingHealth.status,
                        active_streams: streamingHealth.activeStreams,
                        peak_concurrency: streamingHealth.peakConcurrency,
                        average_duration: streamingHealth.averageDuration
                    },
                    upload_queue: {
                        status: uploadQueueHealth.status,
                        active_workers: uploadQueueHealth.activeWorkers,
                        total_queued: uploadQueueHealth.totalQueued,
                        utilization: uploadQueueHealth.utilizationPercent
                    },
                    websocket_service: {
                        status: webSocketHealth.status,
                        active_connections: webSocketHealth.connections?.active || 0,
                        authenticated_users: webSocketHealth.users?.connected || 0
                    },
                    queue_service: {
                        status: queueHealth.initialized ? 'healthy' : 'unhealthy',
                        size: queueHealth.size || 0
                    }
                },

                // Performance metrics
                performance: {
                    streaming: {
                        total_streams: streamingHealth.metrics?.totalStreams || 0,
                        completed_streams: streamingHealth.metrics?.completedStreams || 0,
                        average_duration: streamingHealth.averageDuration || 0
                    },
                    uploads: {
                        total_uploads: uploadQueueHealth.metrics?.totalUploads || 0,
                        processed_uploads: uploadQueueHealth.metrics?.processedUploads || 0,
                        failed_uploads: uploadQueueHealth.metrics?.failedUploads || 0,
                        average_processing_time: uploadQueueHealth.metrics?.averageProcessingTime || 0,
                        compression_savings: uploadQueueHealth.metrics?.compressionSavings || 0
                    },
                    websockets: {
                        total_connections: webSocketHealth.metrics?.total || 0,
                        messages_per_minute: webSocketHealth.metrics?.messagesPerMinute || 0
                    }
                },

                // Resource usage
                resources: {
                    memory: process.memoryUsage(),
                    uptime: process.uptime(),
                    cpu_usage: process.cpuUsage()
                },

                // Capabilities
                capabilities: [
                    'real_time_streaming',
                    'priority_based_uploads',
                    'websocket_communication',
                    'progressive_analysis',
                    'image_compression',
                    'performance_monitoring'
                ]
            };

            const statusCode = overallStatus === 'healthy' ? 200 :
                              overallStatus === 'degraded' ? 200 : 503;

            res.status(statusCode).json(systemStatus);

        } catch (error) {
            logger.error('System status check failed', {
                correlationId,
                error: error.message,
                responseTime: Date.now() - startTime
            });

            res.status(500).json({
                status: 'error',
                timestamp: new Date().toISOString(),
                error: error.message,
                correlationId,
                response_time: Date.now() - startTime
            });
        }
    }
);

/**
 * Get Upload Queue Status
 * GET /api/v1/status/upload-queue
 */
router.get('/upload-queue',
    // authenticateToken, // Temporarily disabled for testing
    createRateLimit(100, 5 * 60 * 1000), // 100 requests per 5 minutes
    async (req, res) => {
        const correlationId = req.query.correlationId || `queue_status_${Date.now()}`;

        try {
            const queueStats = uploadQueueService.getQueueStats();

            const response = {
                success: true,
                timestamp: new Date().toISOString(),
                correlationId,

                // Queue status
                queue_status: {
                    active_workers: queueStats.activeWorkers,
                    max_concurrent: queueStats.maxConcurrent,
                    utilization: `${Math.round((queueStats.activeWorkers / queueStats.maxConcurrent) * 100)}%`,
                    total_queued: queueStats.totalQueued,
                    currently_processing: queueStats.processing
                },

                // Priority queue breakdown
                priority_queues: {
                    urgent: {
                        size: queueStats.queueSizes.urgent,
                        estimated_wait: queueStats.queueSizes.urgent * 2000 // 2s per urgent upload
                    },
                    high: {
                        size: queueStats.queueSizes.high,
                        estimated_wait: queueStats.queueSizes.high * 5000 // 5s per high upload
                    },
                    normal: {
                        size: queueStats.queueSizes.normal,
                        estimated_wait: queueStats.queueSizes.normal * 10000 // 10s per normal upload
                    },
                    low: {
                        size: queueStats.queueSizes.low,
                        estimated_wait: queueStats.queueSizes.low * 30000 // 30s per low upload
                    }
                },

                // Performance metrics
                metrics: {
                    total_uploads: queueStats.metrics.totalUploads,
                    processed_uploads: queueStats.metrics.processedUploads,
                    failed_uploads: queueStats.metrics.failedUploads,
                    success_rate: queueStats.metrics.totalUploads > 0 ?
                        `${Math.round((queueStats.metrics.processedUploads / queueStats.metrics.totalUploads) * 100)}%` : '0%',
                    average_processing_time: queueStats.metrics.averageProcessingTime,
                    total_compression_savings: queueStats.metrics.compressionSavings
                },

                // Configuration
                config: queueStats.config
            };

            res.json(response);

        } catch (error) {
            logger.error('Upload queue status check failed', {
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to get upload queue status',
                details: error.message,
                correlationId
            });
        }
    }
);

/**
 * Get Upload Status by ID
 * GET /api/v1/status/upload/:uploadId
 */
router.get('/upload/:uploadId',
    // authenticateToken, // Temporarily disabled for testing
    createRateLimit(200, 5 * 60 * 1000), // 200 requests per 5 minutes
    async (req, res) => {
        const { uploadId } = req.params;
        const correlationId = req.query.correlationId || `upload_status_${Date.now()}`;

        try {
            const uploadStatus = uploadQueueService.getUploadStatus(uploadId);

            if (!uploadStatus) {
                return res.status(404).json({
                    success: false,
                    error: 'Upload not found or expired',
                    uploadId,
                    correlationId
                });
            }

            // TODO: Verify user owns this upload (when auth is enabled)

            const response = {
                success: true,
                uploadId,
                correlationId,
                timestamp: new Date().toISOString(),
                upload_status: uploadStatus
            };

            // If upload is completed and has a stream, include stream status
            if (uploadStatus.streamId) {
                const streamStatus = streamingService.getStreamStatus(uploadStatus.streamId);
                if (streamStatus) {
                    response.stream_status = streamStatus;
                }
            }

            res.json(response);

        } catch (error) {
            logger.error('Upload status check failed', {
                uploadId,
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to get upload status',
                details: error.message,
                uploadId,
                correlationId
            });
        }
    }
);

/**
 * Get Streaming Service Status
 * GET /api/v1/status/streaming
 */
router.get('/streaming',
    // authenticateToken, // Temporarily disabled for testing
    createRateLimit(100, 5 * 60 * 1000), // 100 requests per 5 minutes
    async (req, res) => {
        const correlationId = req.query.correlationId || `streaming_status_${Date.now()}`;

        try {
            const streamingHealth = streamingService.getHealthStatus();

            const response = {
                success: true,
                timestamp: new Date().toISOString(),
                correlationId,

                // Service status
                service_status: {
                    status: streamingHealth.status,
                    active_streams: streamingHealth.activeStreams,
                    peak_concurrency: streamingHealth.peakConcurrency,
                    average_duration: streamingHealth.averageDuration
                },

                // Metrics
                metrics: streamingHealth.metrics,

                // Performance
                performance: {
                    memory_usage: streamingHealth.memoryUsage,
                    uptime: streamingHealth.uptime
                },

                // Real-time capabilities
                capabilities: {
                    websocket_streaming: true,
                    progressive_analysis: true,
                    priority_processing: true,
                    real_time_updates: true
                }
            };

            res.json(response);

        } catch (error) {
            logger.error('Streaming status check failed', {
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to get streaming service status',
                details: error.message,
                correlationId
            });
        }
    }
);

/**
 * Get WebSocket Service Status
 * GET /api/v1/status/websocket
 */
router.get('/websocket',
    // authenticateToken, // Temporarily disabled for testing
    createRateLimit(100, 5 * 60 * 1000), // 100 requests per 5 minutes
    async (req, res) => {
        const correlationId = req.query.correlationId || `ws_status_${Date.now()}`;

        try {
            const wsHealth = webSocketService.getHealthStatus();

            const response = {
                success: true,
                timestamp: new Date().toISOString(),
                correlationId,

                // WebSocket service status
                service_status: {
                    status: wsHealth.status,
                    endpoint: '/ws',
                    authentication_required: true
                },

                // Connection metrics
                connections: wsHealth.connections,

                // User metrics
                users: wsHealth.users,

                // Performance metrics
                metrics: wsHealth.metrics,

                // Available channels
                available_channels: [
                    'user:{userId}:streams',
                    'user:{userId}:uploads',
                    'user:{userId}:flirts',
                    'user:{userId}:voice',
                    'user:{userId}:analysis',
                    'user:{userId}:limits',
                    'system:status',
                    'system:announcements'
                ]
            };

            res.json(response);

        } catch (error) {
            logger.error('WebSocket status check failed', {
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to get WebSocket service status',
                details: error.message,
                correlationId
            });
        }
    }
);

/**
 * Get User-specific Status
 * GET /api/v1/status/user
 */
router.get('/user',
    authenticateToken,
    createRateLimit(50, 5 * 60 * 1000), // 50 requests per 5 minutes
    async (req, res) => {
        const userId = req.user.id;
        const correlationId = req.query.correlationId || `user_status_${Date.now()}`;

        try {
            // Get user's WebSocket connections
            const wsHealth = webSocketService.getHealthStatus();
            const userConnections = wsHealth.users?.totalConnections || 0;

            // Check for active streams/uploads for this user
            // (This would require extending services to track by user)

            const response = {
                success: true,
                userId,
                timestamp: new Date().toISOString(),
                correlationId,

                // User connection status
                connection_status: {
                    websocket_connected: userConnections > 0,
                    total_connections: userConnections,
                    last_activity: new Date().toISOString() // This would be tracked per user
                },

                // User activity status
                activity_status: {
                    active_streams: 0, // Would be populated from streaming service
                    queued_uploads: 0, // Would be populated from upload queue
                    processing_uploads: 0 // Would be populated from upload queue
                },

                // User preferences
                preferences: {
                    realtime_updates_enabled: true,
                    websocket_preferred: true,
                    notification_channels: ['streams', 'uploads', 'flirts']
                },

                // Available actions
                available_actions: [
                    'start_stream_analysis',
                    'upload_image',
                    'subscribe_to_updates',
                    'check_status'
                ]
            };

            res.json(response);

        } catch (error) {
            logger.error('User status check failed', {
                userId,
                correlationId,
                error: error.message
            });

            res.status(500).json({
                success: false,
                error: 'Failed to get user status',
                details: error.message,
                userId,
                correlationId
            });
        }
    }
);

/**
 * Get Comprehensive Status Dashboard
 * GET /api/v1/status/dashboard
 */
router.get('/dashboard',
    authenticateToken,
    async (req, res) => {
        const correlationId = req.query.correlationId || `dashboard_${Date.now()}`;
        const startTime = Date.now();

        try {
            // Gather comprehensive status data
            const [
                systemStatus,
                streamingHealth,
                uploadQueueStats,
                wsHealth
            ] = await Promise.all([
                // We'll reuse the system status logic
                this.getSystemStatusData(),
                streamingService.getHealthStatus(),
                uploadQueueService.getQueueStats(),
                webSocketService.getHealthStatus()
            ]);

            const dashboard = {
                success: true,
                timestamp: new Date().toISOString(),
                correlationId,
                response_time: Date.now() - startTime,

                // Overall health indicators
                health_indicators: {
                    overall_status: systemStatus?.status || 'unknown',
                    streaming_healthy: streamingHealth.status === 'healthy',
                    uploads_healthy: uploadQueueStats.activeWorkers <= uploadQueueStats.maxConcurrent,
                    websockets_healthy: wsHealth.status === 'online',
                    api_responsive: true
                },

                // Real-time metrics
                realtime_metrics: {
                    active_streams: streamingHealth.activeStreams,
                    active_uploads: uploadQueueStats.activeWorkers,
                    websocket_connections: wsHealth.connections?.active || 0,
                    queue_utilization: Math.round((uploadQueueStats.totalQueued / (uploadQueueStats.maxConcurrent * 10)) * 100)
                },

                // Performance summaries
                performance_summary: {
                    average_stream_duration: streamingHealth.averageDuration,
                    average_upload_time: uploadQueueStats.metrics?.averageProcessingTime || 0,
                    success_rates: {
                        streaming: streamingHealth.metrics?.completedStreams > 0 ?
                            Math.round((streamingHealth.metrics.completedStreams / streamingHealth.metrics.totalStreams) * 100) : 100,
                        uploads: uploadQueueStats.metrics?.totalUploads > 0 ?
                            Math.round((uploadQueueStats.metrics.processedUploads / uploadQueueStats.metrics.totalUploads) * 100) : 100
                    }
                },

                // System resources
                system_resources: {
                    memory_usage: process.memoryUsage(),
                    uptime: process.uptime(),
                    load_average: process.loadavg ? process.loadavg() : null
                },

                // Alerts and warnings
                alerts: this.generateSystemAlerts(streamingHealth, uploadQueueStats, wsHealth),

                // Quick actions
                quick_actions: [
                    { action: 'view_active_streams', endpoint: '/api/v1/status/streaming' },
                    { action: 'check_upload_queue', endpoint: '/api/v1/status/upload-queue' },
                    { action: 'test_websocket', endpoint: '/ws' },
                    { action: 'system_health', endpoint: '/api/v1/status/system' }
                ]
            };

            res.json(dashboard);

        } catch (error) {
            logger.error('Status dashboard failed', {
                correlationId,
                error: error.message,
                responseTime: Date.now() - startTime
            });

            res.status(500).json({
                success: false,
                error: 'Failed to generate status dashboard',
                details: error.message,
                correlationId,
                response_time: Date.now() - startTime
            });
        }
    }
);

/**
 * Generate system alerts based on current status
 * @param {Object} streamingHealth - Streaming service health
 * @param {Object} uploadQueueStats - Upload queue statistics
 * @param {Object} wsHealth - WebSocket service health
 * @returns {Array} Alert list
 */
function generateSystemAlerts(streamingHealth, uploadQueueStats, wsHealth) {
    const alerts = [];

    // High queue utilization
    if (uploadQueueStats.totalQueued > uploadQueueStats.maxConcurrent * 5) {
        alerts.push({
            level: 'warning',
            message: 'Upload queue utilization is high',
            metric: 'queue_size',
            value: uploadQueueStats.totalQueued,
            threshold: uploadQueueStats.maxConcurrent * 5
        });
    }

    // High active streams
    if (streamingHealth.activeStreams > 20) {
        alerts.push({
            level: 'info',
            message: 'High concurrent streaming activity',
            metric: 'active_streams',
            value: streamingHealth.activeStreams,
            threshold: 20
        });
    }

    // WebSocket connection issues
    if (wsHealth.status !== 'online') {
        alerts.push({
            level: 'error',
            message: 'WebSocket service is not operational',
            metric: 'websocket_status',
            value: wsHealth.status,
            threshold: 'online'
        });
    }

    // Memory usage warning
    const memoryUsage = process.memoryUsage();
    const memoryUsagePercent = (memoryUsage.heapUsed / memoryUsage.heapTotal) * 100;
    if (memoryUsagePercent > 85) {
        alerts.push({
            level: 'warning',
            message: 'High memory usage detected',
            metric: 'memory_usage',
            value: `${memoryUsagePercent.toFixed(1)}%`,
            threshold: '85%'
        });
    }

    return alerts;
}

/**
 * Get system status data (helper function)
 * @returns {Promise<Object>} System status data
 */
async function getSystemStatusData() {
    try {
        // This would contain the same logic as the /system endpoint
        // Simplified for now
        return { status: 'healthy' };
    } catch (error) {
        return { status: 'error', error: error.message };
    }
}

module.exports = router;