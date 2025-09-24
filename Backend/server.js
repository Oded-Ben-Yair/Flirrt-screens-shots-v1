require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const http = require('http');
const { Pool } = require('pg');

// Import new services
const { logger } = require('./services/logger');
const redisService = require('./services/redis');
const queueService = require('./services/queueService');
const webSocketService = require('./services/websocketService');
const circuitBreakerService = require('./services/circuitBreaker');
const healthCheckService = require('./services/healthCheck');

// Import enhanced middleware
const {
    correlationIdMiddleware,
    errorCorrelationMiddleware,
    requestLoggerMiddleware,
    addDbCorrelation,
    addApiCorrelation,
    rateLimitLogger
} = require('./middleware/correlationId');
const { uploadService } = require('./middleware/optimizedUpload');

// Import routes
const authRoutes = require('./routes/auth');
const analysisRoutes = require('./routes/analysis');
const flirtRoutes = require('./routes/flirts');
const voiceRoutes = require('./routes/voice');

// Import middleware
const { authenticateToken, createRateLimit } = require('./middleware/auth');
const { securityHeaders, requestSizeLimiter } = require('./middleware/validation');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

// Test database connection
pool.connect()
    .then(() => logger.info('Connected to PostgreSQL database'))
    .catch(err => logger.warn('Database connection failed (some features disabled)', { error: err.message }));

// Initialize services
logger.info('Initializing Flirrt.ai Backend Server', {
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    port: PORT
});

// Initialize WebSocket service
webSocketService.initialize(server);

// Initialize upload service (creates directories)
try {
    // Upload service initialization is handled internally
    logger.info('Upload service ready');
} catch (error) {
    logger.error('Upload service initialization failed', { error: error.message });
}

// Core middleware setup
app.use(correlationIdMiddleware); // Add correlation IDs first
app.use(addDbCorrelation); // Add database correlation helpers
app.use(addApiCorrelation); // Add API correlation helpers
app.use(rateLimitLogger); // Add rate limit logging

// Enhanced CORS configuration for iOS app compatibility
app.use(cors({
    origin: [
        'http://localhost:3000',
        'http://localhost:3001',
        'http://localhost:8080',
        'http://localhost:8081',
        'https://flirrt.ai',
        'https://app.flirrt.ai',
        // iOS specific origins
        'capacitor://localhost',
        'ionic://localhost',
        'http://localhost',
        'https://localhost',
        // For iOS simulator and development
        /^http:\/\/192\.168\.\d+\.\d+/,
        /^http:\/\/10\.0\.\d+\.\d+/,
        /^http:\/\/172\.16\.\d+\.\d+/
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowedHeaders: [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin',
        'Access-Control-Request-Method',
        'Access-Control-Request-Headers'
    ],
    exposedHeaders: ['Content-Length', 'X-Foo', 'X-Bar'],
    maxAge: 86400 // 24 hours
}));

// Security and validation middleware
app.use(securityHeaders);
app.use(requestSizeLimiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Enhanced request logging
app.use(requestLoggerMiddleware);

// Global rate limiting
app.use('/api/', createRateLimit(1000, 15 * 60 * 1000)); // 1000 requests per 15 minutes for API routes

// Legacy request logging removed - handled by requestLoggerMiddleware

// Enhanced Health Check Endpoints
app.get('/health', async (req, res) => {
    try {
        const health = await healthCheckService.performHealthCheck(false, req.correlationId);
        const statusCode = health.status === 'healthy' ? 200 : health.status === 'degraded' ? 200 : 503;

        res.status(statusCode).json(health);
    } catch (error) {
        req.logger.error('Health check failed', { error: error.message });
        res.status(503).json({
            success: false,
            status: 'error',
            error: error.message,
            timestamp: new Date().toISOString(),
            correlationId: req.correlationId
        });
    }
});

// Detailed health check
app.get('/health/detailed', async (req, res) => {
    try {
        const health = await healthCheckService.performHealthCheck(true, req.correlationId);
        const statusCode = health.status === 'healthy' ? 200 : health.status === 'degraded' ? 200 : 503;

        res.status(statusCode).json(health);
    } catch (error) {
        req.logger.error('Detailed health check failed', { error: error.message });
        res.status(503).json({
            success: false,
            status: 'error',
            error: error.message,
            timestamp: new Date().toISOString(),
            correlationId: req.correlationId
        });
    }
});

// Quick health check for load balancers
app.get('/health/quick', async (req, res) => {
    const health = await healthCheckService.quickCheck();
    const statusCode = health.status === 'healthy' ? 200 : 503;
    res.status(statusCode).json(health);
});

// Kubernetes readiness probe
app.get('/health/ready', async (req, res) => {
    const health = await healthCheckService.readinessCheck();
    const statusCode = health.status === 'ready' ? 200 : 503;
    res.status(statusCode).json(health);
});

// Kubernetes liveness probe
app.get('/health/live', async (req, res) => {
    const health = await healthCheckService.livenessCheck();
    res.status(200).json(health);
});

// Health history endpoint
app.get('/health/history', authenticateToken, async (req, res) => {
    const limit = Math.min(parseInt(req.query.limit) || 10, 50);
    const history = healthCheckService.getHealthHistory(limit);
    const trends = healthCheckService.getHealthTrends();

    res.json({
        success: true,
        history,
        trends,
        correlationId: req.correlationId
    });
});

// System metrics endpoint
app.get('/metrics', authenticateToken, async (req, res) => {
    try {
        const [queueStats, uploadStats, wsHealth, cbHealth] = await Promise.all([
            queueService.getQueueStats(),
            uploadService.getUploadStats(),
            webSocketService.getHealthStatus(),
            circuitBreakerService.getHealthStatus()
        ]);

        res.json({
            success: true,
            timestamp: new Date().toISOString(),
            metrics: {
                queues: queueStats,
                uploads: uploadStats,
                websockets: wsHealth,
                circuitBreakers: cbHealth
            },
            correlationId: req.correlationId
        });
    } catch (error) {
        req.logger.error('Metrics collection failed', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to collect metrics',
            correlationId: req.correlationId
        });
    }
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/analysis', analysisRoutes);
app.use('/api/v1/flirts', flirtRoutes);
app.use('/api/v1/voice', voiceRoutes);

// GDPR Compliance - User Data Deletion
app.delete('/api/v1/user/:id/data', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const requestingUserId = req.user.id;

        // Check if user is deleting their own data or is admin
        if (requestingUserId !== id) {
            // If database is available, check admin status
            try {
                const adminQuery = `
                    SELECT role FROM user_profiles WHERE user_id = $1 AND role IN ('admin', 'super_admin')
                `;
                const adminResult = await pool.query(adminQuery, [requestingUserId]);

                if (adminResult.rows.length === 0) {
                    return res.status(403).json({
                        success: false,
                        error: 'Access denied. Can only delete your own data.',
                        code: 'ACCESS_DENIED'
                    });
                }
            } catch (dbError) {
                // If database is not available, only allow users to delete their own data
                console.warn('Database not available for admin check, restricting to self-deletion only');
                return res.status(403).json({
                    success: false,
                    error: 'Access denied. Can only delete your own data.',
                    code: 'ACCESS_DENIED'
                });
            }
        }

        // Log deletion request (if database is available)
        let filesToDelete = [];
        try {
            await pool.query(
                `INSERT INTO data_deletion_log (user_id, deletion_requested_at, deletion_status)
                 VALUES ($1, NOW(), 'requested')`,
                [id]
            );

            // Start transaction for complete data deletion
            const client = await pool.connect();

            try {
                await client.query('BEGIN');

                // Get all file paths that need to be deleted
                const filePathsQuery = `
                    SELECT voice_file_path FROM voice_messages WHERE user_id = $1
                    UNION
                    SELECT file_path FROM screenshots WHERE user_id = $1
                `;
                const filePathsResult = await client.query(filePathsQuery, [id]);
                filesToDelete = filePathsResult.rows;

                // Delete database records (foreign key constraints will handle cascade)
                await client.query('DELETE FROM user_sessions WHERE user_id = $1', [id]);
                await client.query('DELETE FROM analytics WHERE user_id = $1', [id]);
                await client.query('DELETE FROM voice_messages WHERE user_id = $1', [id]);
                await client.query('DELETE FROM flirt_suggestions WHERE user_id = $1', [id]);
                await client.query('DELETE FROM screenshots WHERE user_id = $1', [id]);
                await client.query('DELETE FROM users WHERE id = $1', [id]);

                // Update deletion log
                await client.query(
                    `UPDATE data_deletion_log
                     SET deletion_completed_at = NOW(), deletion_status = 'completed'
                     WHERE user_id = $1 AND deletion_status = 'requested'`,
                    [id]
                );

                await client.query('COMMIT');
                client.release();

            } catch (error) {
                await client.query('ROLLBACK');
                client.release();
                throw error;
            }
        } catch (dbError) {
            console.warn('Database not available for user data deletion, performing file cleanup only:', dbError.message);

            // If database is not available, try to clean up any files in upload directory for this user
            // This is a limited cleanup since we can't query the database
            const uploadDir = process.env.UPLOAD_DIR || './uploads';
            const fs = require('fs').promises;
            const path = require('path');

            try {
                const files = await fs.readdir(uploadDir);

                // Look for files that might belong to this user (basic pattern matching)
                const userFiles = files.filter(file =>
                    file.includes(id) ||
                    file.startsWith(`screenshot-${id}`) ||
                    file.startsWith(`voice-${id}`)
                );

                for (const file of userFiles) {
                    try {
                        await fs.unlink(path.join(uploadDir, file));
                    } catch (fileError) {
                        console.error('Failed to delete file:', file, fileError.message);
                    }
                }

                filesToDelete = userFiles.map(file => ({ file_path: path.join(uploadDir, file) }));
            } catch (dirError) {
                console.warn('Could not access upload directory for cleanup:', dirError.message);
                // Don't throw - just continue with empty files list
                filesToDelete = [];
            }
        }

        // Delete physical files
        for (const row of filesToDelete) {
            if (row.voice_file_path || row.file_path) {
                const filePath = row.voice_file_path || row.file_path;
                try {
                    await require('fs').promises.unlink(filePath);
                } catch (fileError) {
                    console.error('Failed to delete file:', filePath, fileError.message);
                }
            }
        }

        res.json({
            success: true,
            message: 'User data deletion completed successfully',
            deleted_at: new Date().toISOString(),
            gdpr_compliant: true,
            files_deleted: filesToDelete.length,
            database_available: filesToDelete.length > 0 ? true : false
        });

    } catch (error) {
        console.error('GDPR deletion error:', error);

        // Update deletion log with failure (if database is available)
        try {
            await pool.query(
                `UPDATE data_deletion_log
                 SET deletion_status = 'failed', admin_notes = $2
                 WHERE user_id = $1 AND deletion_status = 'requested'`,
                [req.params.id, error.message]
            );
        } catch (logError) {
            console.warn('Failed to update deletion log (database not available):', logError.message);
        }

        res.status(500).json({
            success: false,
            error: 'Failed to delete user data',
            details: error.message,
            code: 'DELETION_ERROR'
        });
    }
});

// Analytics endpoint
app.get('/api/v1/analytics/dashboard', authenticateToken, async (req, res) => {
    try {
        const { timeRange = '30d' } = req.query;

        let timeFilter = "created_at >= NOW() - INTERVAL '30 days'";
        if (timeRange === '7d') timeFilter = "created_at >= NOW() - INTERVAL '7 days'";
        if (timeRange === '1d') timeFilter = "created_at >= NOW() - INTERVAL '1 day'";

        const analyticsQuery = `
            SELECT
                COUNT(*) FILTER (WHERE event_type = 'screenshot_analyzed') as screenshots_analyzed,
                COUNT(*) FILTER (WHERE event_type = 'flirts_generated') as flirts_generated,
                COUNT(*) FILTER (WHERE event_type = 'voice_synthesized') as voices_created,
                COUNT(*) FILTER (WHERE event_type = 'suggestion_used') as suggestions_used,
                AVG(CAST(event_data->>'analysis_confidence' AS FLOAT)) FILTER (WHERE event_type = 'screenshot_analyzed') as avg_confidence
            FROM analytics
            WHERE user_id = $1 AND ${timeFilter}
        `;

        const result = await pool.query(analyticsQuery, [req.user.id]);
        const stats = result.rows[0];

        res.json({
            success: true,
            data: {
                time_range: timeRange,
                statistics: {
                    screenshots_analyzed: parseInt(stats.screenshots_analyzed) || 0,
                    flirts_generated: parseInt(stats.flirts_generated) || 0,
                    voices_created: parseInt(stats.voices_created) || 0,
                    suggestions_used: parseInt(stats.suggestions_used) || 0,
                    average_confidence: parseFloat(stats.avg_confidence) || 0
                }
            }
        });

    } catch (error) {
        console.error('Analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get analytics data',
            code: 'ANALYTICS_ERROR'
        });
    }
});

// Static file serving for uploads (with authentication)
app.get('/uploads/:filename', authenticateToken, async (req, res) => {
    try {
        const { filename } = req.params;
        const filePath = path.join(uploadDir, filename);

        // Verify file belongs to user
        const fileQuery = `
            SELECT user_id FROM screenshots WHERE filename = $1
            UNION
            SELECT user_id FROM voice_messages WHERE voice_file_path LIKE $2
        `;

        const fileResult = await pool.query(fileQuery, [filename, `%${filename}`]);

        if (fileResult.rows.length === 0 || fileResult.rows[0].user_id !== req.user.id) {
            return res.status(404).json({
                success: false,
                error: 'File not found',
                code: 'FILE_NOT_FOUND'
            });
        }

        res.sendFile(path.resolve(filePath));

    } catch (error) {
        console.error('File serving error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to serve file',
            code: 'FILE_SERVE_ERROR'
        });
    }
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        code: 'NOT_FOUND',
        available_endpoints: [
            'POST /api/v1/auth/register',
            'POST /api/v1/auth/login',
            'POST /api/v1/auth/logout',
            'GET /api/v1/auth/me',
            'POST /api/v1/analysis/analyze_screenshot',
            'GET /api/v1/analysis/history',
            'POST /api/v1/flirts/generate_flirts',
            'GET /api/v1/flirts/history',
            'POST /api/v1/voice/synthesize_voice',
            'GET /api/v1/voice/history',
            'DELETE /api/v1/user/:id/data',
            'GET /health'
        ]
    });
});

// Global error handler with correlation support
app.use(errorCorrelationMiddleware);
app.use((error, req, res, next) => {
    // Error already logged by errorCorrelationMiddleware

    // Handle multer errors
    if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({
            success: false,
            error: 'File too large',
            details: `Maximum file size is ${process.env.MAX_FILE_SIZE || '10MB'}`,
            code: 'FILE_TOO_LARGE'
        });
    }

    if (error.code === 'LIMIT_UNEXPECTED_FILE') {
        return res.status(400).json({
            success: false,
            error: 'Unexpected file field',
            code: 'UNEXPECTED_FILE'
        });
    }

    // Handle JSON parsing errors
    if (error.type === 'entity.parse.failed') {
        return res.status(400).json({
            success: false,
            error: 'Invalid JSON format',
            code: 'INVALID_JSON'
        });
    }

    // Default error response
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        code: 'INTERNAL_SERVER_ERROR',
        correlationId: req.correlationId
    });
});

// Enhanced graceful shutdown
const gracefulShutdown = async (signal) => {
    logger.info(`${signal} received, shutting down gracefully`);

    try {
        // Stop accepting new connections
        server.close(() => {
            logger.info('HTTP server closed');
        });

        // Shutdown services in order
        logger.info('Shutting down services...');

        await webSocketService.shutdown();
        await queueService.shutdown();
        await redisService.disconnect();
        await pool.end();

        logger.info('Graceful shutdown completed');
        process.exit(0);

    } catch (error) {
        logger.error('Error during graceful shutdown', { error: error.message });
        process.exit(1);
    }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', {
        error: error.message,
        stack: error.stack
    });
    gracefulShutdown('UNCAUGHT_EXCEPTION');
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection', {
        reason: reason instanceof Error ? reason.message : reason,
        stack: reason instanceof Error ? reason.stack : undefined,
        promise: promise.toString()
    });
    gracefulShutdown('UNHANDLED_REJECTION');
});

// Start server
server.listen(PORT, () => {
    logger.info('Flirrt.ai Backend Server started successfully', {
        port: PORT,
        environment: process.env.NODE_ENV || 'development',
        version: process.env.APP_VERSION || '1.0.0',
        database: `${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`,
        endpoints: {
            health: `http://localhost:${PORT}/health`,
            api: `http://localhost:${PORT}/api/v1`,
            websocket: `ws://localhost:${PORT}/ws`,
            metrics: `http://localhost:${PORT}/metrics`
        },
        features: {
            redis: redisService.getStatus().connected,
            queues: queueService.getHealthStatus().initialized || false,
            websocket: true,
            circuitBreaker: true,
            enhancedLogging: true,
            correlationIds: true
        }
    });

    // Cleanup old temp files on startup
    uploadService.cleanupTempFiles().catch(error => {
        logger.warn('Initial temp file cleanup failed', { error: error.message });
    });

    // Schedule regular temp file cleanup (every hour)
    setInterval(() => {
        uploadService.cleanupTempFiles().catch(error => {
            logger.warn('Scheduled temp file cleanup failed', { error: error.message });
        });
    }, 60 * 60 * 1000);

    logger.info('Server ready to accept connections');
});

// Handle server startup errors
server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
        logger.error('Port already in use', { port: PORT });
    } else {
        logger.error('Server startup error', { error: error.message });
    }
    process.exit(1);
});

module.exports = app;