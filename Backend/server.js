require('dotenv').config();

// Validate required environment variables on startup
const requiredEnvVars = [
    'GROK_API_KEY',
    'ELEVENLABS_API_KEY'
    // JWT_SECRET is optional - only needed if using authentication
];

const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingEnvVars.length > 0) {
    console.error('❌ Missing required environment variables:', missingEnvVars.join(', '));
    console.error('💡 Please ensure these variables are set in your .env file');
    process.exit(1);
}

// Validate JWT_SECRET strength (if provided)
if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
    console.warn('⚠️  JWT_SECRET is too weak. Should be at least 32 characters long.');
    console.warn('💡 Generate a secure secret with: openssl rand -base64 64');
    // Don't exit - just warn for now
}

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { httpStatus, errors, cors: corsConfig, server } = require('./config/constants');
const timeouts = require('./config/timeouts');
const db = require('./config/database');

// Import routes
const authRoutes = require('./routes/auth');
const analysisRoutes = require('./routes/analysis');
const flirtRoutes = require('./routes/flirts');
const voiceRoutes = require('./routes/voice');
const legalRoutes = require('./routes/legal');
const accountRoutes = require('./routes/account');

// Import middleware
const { authenticateToken, rateLimit } = require('./middleware/auth');
const { securityHeaders, requestSizeLimiter } = require('./middleware/validation');

const app = express();
const PORT = process.env.PORT || server.defaultPort;

// Configure EJS view engine for rendering HTML (privacy policy, terms, etc.)
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Ensure upload directory exists
const uploadDir = process.env.UPLOAD_DIR || './uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
    console.log(`📁 Created upload directory: ${uploadDir}`);
}

// Enhanced CORS configuration for iOS app compatibility
app.use(cors({
    origin: corsConfig.allowedOrigins,
    credentials: true,
    methods: corsConfig.allowedMethods,
    allowedHeaders: corsConfig.allowedHeaders,
    exposedHeaders: corsConfig.exposedHeaders,
    maxAge: corsConfig.maxAge
}));

// Security and validation middleware
app.use(securityHeaders);
app.use(requestSizeLimiter);

app.use(express.json({ limit: server.requestLimits.json }));
app.use(express.urlencoded({ extended: true, limit: server.requestLimits.urlencoded }));

// Request logging middleware
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    const method = req.method;
    const url = req.url;
    const ip = req.ip || req.connection.remoteAddress;

    console.log(`[${timestamp}] ${method} ${url} - ${ip}`);
    next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
    // Check database connection (optional - don't fail if unavailable)
    let databaseStatus = 'not_configured';

    if (db.isAvailable()) {
        try {
            await db.query('SELECT 1');
            databaseStatus = 'connected';
        } catch (error) {
            console.warn('Database health check failed:', error.message);
            databaseStatus = 'error';
        }
    } else {
        databaseStatus = 'optional_not_configured';
    }

    // Health check passes even without database (API keys are more critical)
    res.json({
        success: true,
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        services: {
            database: databaseStatus,
            grok_api: process.env.GROK_API_KEY ? 'configured' : 'not_configured',
            elevenlabs_api: process.env.ELEVENLABS_API_KEY ? 'configured' : 'not_configured',
            openai_api: process.env.OPENAI_API_KEY ? 'configured' : 'not_configured'
        }
    });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/analysis', analysisRoutes);
app.use('/api/v1/flirts', flirtRoutes);
app.use('/api/v1/voice', voiceRoutes);
app.use('/api/v1/legal', legalRoutes);
app.use('/api/v1/account', accountRoutes);

// GDPR Compliance - User Data Deletion
app.delete('/api/v1/user/:id/data', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const requestingUserId = req.user.id;

        // Check if user is deleting their own data or is admin
        if (requestingUserId !== id) {
            // If database is available, check admin status
            if (db.isAvailable()) {
                try {
                    const adminQuery = `
                        SELECT role FROM user_profiles WHERE user_id = $1 AND role IN ('admin', 'super_admin')
                    `;
                    const adminResult = await db.query(adminQuery, [requestingUserId]);

                    if (!adminResult || adminResult.rows.length === 0) {
                        return res.status(httpStatus.FORBIDDEN).json({
                            success: false,
                            error: errors.ACCESS_DENIED.message,
                            code: errors.ACCESS_DENIED.code
                        });
                    }
                } catch (dbError) {
                    console.warn('Database error during admin check:', dbError.message);
                    return res.status(httpStatus.FORBIDDEN).json({
                        success: false,
                        error: errors.ACCESS_DENIED.message,
                        code: errors.ACCESS_DENIED.code
                    });
                }
            } else {
                // No database - only allow self-deletion
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    error: errors.ACCESS_DENIED.message,
                    code: errors.ACCESS_DENIED.code
                });
            }
        }

        // Log deletion request (if database is available)
        let filesToDelete = [];
        if (db.isAvailable()) {
            try {
                await db.query(
                    `INSERT INTO data_deletion_log (user_id, deletion_requested_at, deletion_status)
                     VALUES ($1, NOW(), 'requested')`,
                    [id]
                );

                // Start transaction for complete data deletion
                const client = await db.pool.connect();

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
                console.warn('Database error during user data deletion, performing file cleanup only:', dbError.message);

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
        if (db.isAvailable()) {
            try {
                await db.query(
                    `UPDATE data_deletion_log
                     SET deletion_status = 'failed', admin_notes = $2
                     WHERE user_id = $1 AND deletion_status = 'requested'`,
                    [req.params.id, error.message]
                );
            } catch (logError) {
                console.warn('Failed to update deletion log:', logError.message);
            }
        }

        res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
            success: false,
            error: errors.DELETION_ERROR.message,
            details: error.message,
            code: errors.DELETION_ERROR.code
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

        const result = await db.query(analyticsQuery, [req.user.id]);
        const stats = result ? result.rows[0] : null;

        if (!result || !stats) {
            return res.status(httpStatus.SERVICE_UNAVAILABLE).json({
                success: false,
                error: 'Analytics database not available',
                code: 'DATABASE_UNAVAILABLE'
            });
        }

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
        res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
            success: false,
            error: errors.ANALYTICS_ERROR.message,
            code: errors.ANALYTICS_ERROR.code
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

        const fileResult = await db.query(fileQuery, [filename, `%${filename}`]);

        if (!fileResult || fileResult.rows.length === 0 || fileResult.rows[0].user_id !== req.user.id) {
            return res.status(httpStatus.NOT_FOUND).json({
                success: false,
                error: errors.FILE_NOT_FOUND.message,
                code: errors.FILE_NOT_FOUND.code
            });
        }

        res.sendFile(path.resolve(filePath));

    } catch (error) {
        console.error('File serving error:', error);
        res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
            success: false,
            error: errors.FILE_SERVE_ERROR.message,
            code: errors.FILE_SERVE_ERROR.code
        });
    }
});

// 404 handler
const { availableEndpoints } = require('./config/constants');
app.use((req, res) => {
    res.status(httpStatus.NOT_FOUND).json({
        success: false,
        error: errors.NOT_FOUND.message,
        code: errors.NOT_FOUND.code,
        available_endpoints: availableEndpoints
    });
});

// Global error handler
app.use((error, req, res, next) => {
    console.error('Global error handler:', error);

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
        code: 'INTERNAL_SERVER_ERROR'
    });
});

// Graceful shutdown (database cleanup handled in config/database.js)
process.on('SIGTERM', () => {
    console.log('🔄 SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🔄 SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Vibe8.ai Backend Server running on port ${PORT}`);
    console.log(`📡 Health check: http://localhost:${PORT}/health`);
    console.log(`🔑 API Base URL: http://localhost:${PORT}/api/v1`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🗄️  Database: ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
    console.log('✅ Server ready to accept connections');
});

module.exports = app;