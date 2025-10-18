/**
 * Backend Configuration Constants
 *
 * Centralized configuration for the Vibe8.ai backend server.
 * All magic strings, hardcoded values, and configuration constants are defined here.
 *
 * @module config/constants
 */

module.exports = {
    // ============================================================================
    // API CONFIGURATION
    // ============================================================================
    api: {
        version: 'v1',
        basePath: '/api/v1',

        endpoints: {
            // Authentication
            auth: {
                base: '/auth',
                register: '/auth/register',
                login: '/auth/login',
                logout: '/auth/logout',
                me: '/auth/me'
            },

            // Analysis
            analysis: {
                base: '/analysis',
                analyze: '/analysis/analyze_screenshot',
                history: '/analysis/history'
            },

            // Flirts
            flirts: {
                base: '/flirts',
                generate: '/flirts/generate_flirts',
                history: '/flirts/history',
                rate: '/flirts/:suggestionId/rate',
                used: '/flirts/:suggestionId/used',
                delete: '/flirts/:suggestionId'
            },

            // Voice
            voice: {
                base: '/voice',
                synthesize: '/voice/synthesize_voice',
                history: '/voice/history',
                download: '/voice/:voiceMessageId/download',
                delete: '/voice/:voiceMessageId',
                voices: '/voice/voices'
            },

            // Streaming
            streaming: {
                base: '/stream',
                analyze: '/stream/analyze',
                status: '/stream/status/:streamId',
                cancel: '/stream/:streamId',
                health: '/stream/health',
                test: '/stream/test'
            },

            // Orchestrated
            orchestrated: {
                base: '/orchestrated',
                generate: '/orchestrated/generate'
            },

            // Grok4Fast
            grok4Fast: {
                base: '/grok4fast',
                analyze: '/grok4fast/analyze',
                stream: '/grok4fast/stream',
                health: '/grok4fast/health'
            },

            // Status & Health
            status: {
                base: '/status',
                system: '/status/system',
                uploadQueue: '/status/upload-queue',
                websocket: '/status/websocket',
                metrics: '/status/metrics/:feature',
                cache: '/status/cache',
                orchestrator: '/status/orchestrator'
            },

            // Performance Dashboard
            performance: {
                base: '/performance',
                realtime: '/performance/realtime',
                historical: '/performance/historical',
                comparison: '/performance/comparison',
                recommendations: '/performance/recommendations',
                alerts: '/performance/alerts',
                export: '/performance/export'
            },

            // User Management
            user: {
                deleteData: '/user/:id/data'
            },

            // Analytics
            analytics: {
                dashboard: '/analytics/dashboard'
            },

            // Uploads
            uploads: '/uploads/:filename',

            // Health Check
            health: '/health'
        }
    },

    // ============================================================================
    // FILE UPLOAD CONFIGURATION
    // ============================================================================
    upload: {
        // File Size Limits
        maxFileSize: {
            default: 50 * 1024 * 1024,      // 50MB - default
            screenshot: 10 * 1024 * 1024,    // 10MB - screenshots
            voice: 50 * 1024 * 1024,         // 50MB - voice files
            document: 20 * 1024 * 1024       // 20MB - documents
        },

        // File Count Limits
        maxFiles: {
            screenshot: 1,                   // One screenshot at a time
            voice: 5,                        // Multiple voice files for cloning
            document: 3,                     // Multiple documents
            default: 1                       // Default single file
        },

        // MIME Types
        mimeTypes: {
            images: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'],
            audio: ['audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/m4a', 'audio/ogg'],
            documents: ['application/pdf', 'text/plain'],
            json: 'application/json'
        },

        // Upload Directories
        directories: {
            base: './uploads',
            temp: './uploads/temp',
            images: './uploads/images',
            audio: './uploads/audio',
            documents: './uploads/documents'
        },

        // Cleanup Configuration
        cleanup: {
            tempFileMaxAge: 24 * 60 * 60 * 1000  // 24 hours
        }
    },

    // ============================================================================
    // RATE LIMITING CONFIGURATION
    // ============================================================================
    rateLimit: {
        // Time Windows
        windows: {
            oneMinute: 1 * 60 * 1000,           // 1 minute
            fiveMinutes: 5 * 60 * 1000,         // 5 minutes
            fifteenMinutes: 15 * 60 * 1000,     // 15 minutes
            oneHour: 60 * 60 * 1000             // 1 hour
        },

        // Request Limits per Endpoint
        limits: {
            // Authentication
            register: { maxRequests: 5, windowMs: 15 * 60 * 1000 },       // 5 per 15 min
            login: { maxRequests: 10, windowMs: 15 * 60 * 1000 },         // 10 per 15 min

            // API Endpoints
            analysis: { maxRequests: 20, windowMs: 15 * 60 * 1000 },      // 20 per 15 min
            flirts: { maxRequests: 30, windowMs: 15 * 60 * 1000 },        // 30 per 15 min (disabled in MVP)
            voice: { maxRequests: 50, windowMs: 15 * 60 * 1000 },         // 50 per 15 min
            voices: { maxRequests: 10, windowMs: 1 * 60 * 1000 },         // 10 per 1 min
            streaming: { maxRequests: 30, windowMs: 15 * 60 * 1000 },     // 30 per 15 min
            orchestrated: { maxRequests: 20, windowMs: 15 * 60 * 1000 },  // 20 per 15 min

            // Status & Monitoring
            status: { maxRequests: 200, windowMs: 5 * 60 * 1000 },        // 200 per 5 min

            // Grok4Fast
            grok4Fast: { maxRequests: 100, windowMs: 1 * 60 * 1000 },     // 100 per 1 min

            // Default
            default: { maxRequests: 100, windowMs: 15 * 60 * 1000 }       // 100 per 15 min
        }
    },

    // ============================================================================
    // HTTP STATUS CODES
    // ============================================================================
    httpStatus: {
        // Success
        OK: 200,
        CREATED: 201,
        ACCEPTED: 202,
        NO_CONTENT: 204,

        // Client Errors
        BAD_REQUEST: 400,
        UNAUTHORIZED: 401,
        FORBIDDEN: 403,
        NOT_FOUND: 404,
        METHOD_NOT_ALLOWED: 405,
        CONFLICT: 409,
        PAYLOAD_TOO_LARGE: 413,

        // Server Errors
        INTERNAL_SERVER_ERROR: 500,
        NOT_IMPLEMENTED: 501,
        BAD_GATEWAY: 502,
        SERVICE_UNAVAILABLE: 503,
        GATEWAY_TIMEOUT: 504
    },

    // ============================================================================
    // ERROR CODES & MESSAGES
    // ============================================================================
    errors: {
        // Authentication Errors
        TOKEN_MISSING: { code: 'TOKEN_MISSING', message: 'Access token required' },
        TOKEN_INVALID: { code: 'TOKEN_INVALID', message: 'Invalid or expired token' },
        TOKEN_MALFORMED: { code: 'TOKEN_MALFORMED', message: 'Invalid token format' },
        TOKEN_EXPIRED: { code: 'TOKEN_EXPIRED', message: 'Token has expired' },
        ACCOUNT_DEACTIVATED: { code: 'ACCOUNT_DEACTIVATED', message: 'Account is deactivated' },

        // Validation Errors
        VALIDATION_ERROR: { code: 'VALIDATION_ERROR', message: 'Validation failed' },
        MISSING_IMAGE: { code: 'MISSING_IMAGE', message: 'Image data is required' },
        INVALID_FORMAT: { code: 'INVALID_FORMAT', message: 'Invalid image format' },
        INVALID_JSON: { code: 'INVALID_JSON', message: 'Invalid JSON format' },

        // File Upload Errors
        FILE_TOO_LARGE: { code: 'FILE_TOO_LARGE', message: 'File size exceeds limit' },
        PAYLOAD_TOO_LARGE: { code: 'PAYLOAD_TOO_LARGE', message: 'Request entity too large' },
        INVALID_FILE_TYPE: { code: 'INVALID_FILE_TYPE', message: 'File type not allowed' },
        UNSUPPORTED_FILE_TYPE: { code: 'UNSUPPORTED_FILE_TYPE', message: 'File type not supported' },
        DANGEROUS_FILE_EXTENSION: { code: 'DANGEROUS_FILE_EXTENSION', message: 'Dangerous file extension' },
        SECURITY_VIOLATION: { code: 'SECURITY_VIOLATION', message: 'File type not allowed for security reasons' },
        UNEXPECTED_FILE: { code: 'UNEXPECTED_FILE', message: 'Unexpected file field' },
        UNEXPECTED_FILE_FIELD: { code: 'UNEXPECTED_FILE_FIELD', message: 'Unexpected file field' },
        TOO_MANY_FILES: { code: 'TOO_MANY_FILES', message: 'Too many files' },
        FILE_VALIDATION_ERROR: { code: 'FILE_VALIDATION_ERROR', message: 'File validation failed' },
        UPLOAD_VALIDATION_ERROR: { code: 'UPLOAD_VALIDATION_ERROR', message: 'Upload validation failed' },
        UPLOAD_ERROR: { code: 'UPLOAD_ERROR', message: 'Upload failed' },

        // Resource Errors
        NOT_FOUND: { code: 'NOT_FOUND', message: 'Endpoint not found' },
        FILE_NOT_FOUND: { code: 'FILE_NOT_FOUND', message: 'File not found' },
        SCREENSHOT_NOT_FOUND: { code: 'SCREENSHOT_NOT_FOUND', message: 'Screenshot not found' },
        FLIRT_NOT_FOUND: { code: 'FLIRT_NOT_FOUND', message: 'Flirt suggestion not found' },
        VOICE_MESSAGE_NOT_FOUND: { code: 'VOICE_MESSAGE_NOT_FOUND', message: 'Voice message not found' },
        STREAM_NOT_FOUND: { code: 'STREAM_NOT_FOUND', message: 'Stream not found' },

        // Permission Errors
        ACCESS_DENIED: { code: 'ACCESS_DENIED', message: 'Access denied. Can only delete your own data.' },
        RATE_LIMIT_EXCEEDED: { code: 'RATE_LIMIT_EXCEEDED', message: 'Rate limit exceeded' },

        // Server Errors
        INTERNAL_SERVER_ERROR: { code: 'INTERNAL_SERVER_ERROR', message: 'Internal server error' },
        DATABASE_ERROR: { code: 'DATABASE_ERROR', message: 'Database operation failed' },
        API_ERROR: { code: 'API_ERROR', message: 'External API error' },
        ANALYSIS_ERROR: { code: 'ANALYSIS_ERROR', message: 'Screenshot analysis failed' },
        FLIRT_GENERATION_ERROR: { code: 'FLIRT_GENERATION_ERROR', message: 'Flirt generation failed' },
        VOICE_SYNTHESIS_ERROR: { code: 'VOICE_SYNTHESIS_ERROR', message: 'Voice synthesis failed' },
        ANALYTICS_ERROR: { code: 'ANALYTICS_ERROR', message: 'Failed to get analytics data' },
        DELETION_ERROR: { code: 'DELETION_ERROR', message: 'Failed to delete user data' },
        FILE_SERVE_ERROR: { code: 'FILE_SERVE_ERROR', message: 'Failed to serve file' }
    },

    // ============================================================================
    // VALIDATION CONSTRAINTS
    // ============================================================================
    validation: {
        // Length Constraints
        maxLength: {
            text: 2000,                      // General text input
            context: 1000,                   // Context field
            voiceText: 1000,                 // Voice synthesis text
            feedback: 500,                   // User feedback
            email: 255,                      // Email address
            appleId: 255,                    // Apple ID
            name: 100,                       // User name
            screenshotId: 100,               // Screenshot ID
            flirtId: 100,                    // Flirt suggestion ID
            voiceId: 100                     // Voice ID
        },

        // Range Constraints
        range: {
            age: { min: 18, max: 120 },                    // Age range
            rating: { min: 1, max: 5 },                    // Rating range
            page: { min: 1, max: 1000 },                   // Pagination page
            limit: { min: 1, max: 100 },                   // Pagination limit
            voiceStability: { min: 0, max: 1 },            // Voice stability
            voiceSimilarity: { min: 0, max: 1 },           // Voice similarity boost
            voiceStyle: { min: 0, max: 1 }                 // Voice style
        },

        // Allowed Values
        allowedValues: {
            suggestionType: ['opener', 'response', 'continuation'],
            tone: ['playful', 'witty', 'romantic', 'casual', 'bold'],
            voiceModel: ['eleven_monolingual_v1', 'eleven_multilingual_v2', 'eleven_turbo_v2'],
            timeRange: ['1d', '7d', '30d']
        }
    },

    // ============================================================================
    // CORS CONFIGURATION
    // ============================================================================
    cors: {
        allowedOrigins: [
            'http://localhost:3000',
            'http://localhost:3001',
            'http://localhost:8080',
            'http://localhost:8081',
            'https://vibe8.ai',
            'https://app.vibe8.ai',
            'capacitor://localhost',
            'ionic://localhost',
            'http://localhost',
            'https://localhost'
        ],

        allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],

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

        maxAge: 86400  // 24 hours
    },

    // ============================================================================
    // SECURITY CONFIGURATION
    // ============================================================================
    security: {
        // Security Headers
        headers: {
            xContentTypeOptions: 'nosniff',
            xFrameOptions: 'DENY',
            xXssProtection: '1; mode=block',
            referrerPolicy: 'strict-origin-when-cross-origin',
            contentSecurityPolicy: "default-src 'none'; frame-ancestors 'none';"
        },

        // Dangerous File Extensions
        dangerousExtensions: ['.exe', '.bat', '.cmd', '.scr', '.pif', '.vbs', '.js'],

        // JWT Configuration
        jwt: {
            testToken: 'test-token-for-api-testing',
            testUserId: 'test-user-id',
            testEmail: 'test@vibe8.ai',
            testSessionId: 'test-session-id'
        }
    },

    // ============================================================================
    // CACHE CONFIGURATION
    // ============================================================================
    cache: {
        tiers: {
            hot: {
                name: 'hot',
                maxSize: 1000,                       // Max entries
                ttl: 5 * 60 * 1000                   // 5 minutes
            },
            warm: {
                name: 'warm',
                maxSize: 5000,                       // Max entries
                ttl: 30 * 60 * 1000                  // 30 minutes
            },
            cold: {
                name: 'cold',
                maxSize: 2000,                       // Max entries
                ttl: 60 * 60 * 1000                  // 1 hour
            },
            semantic: {
                name: 'semantic',
                maxSize: 3000,                       // Max entries
                ttl: 120 * 60 * 1000                 // 2 hours
            }
        },

        evictionPercentage: 0.1  // Evict 10% when tier is full
    },

    // ============================================================================
    // PERFORMANCE THRESHOLDS
    // ============================================================================
    performance: {
        // Response Time Targets (milliseconds)
        responseTime: {
            streaming: 200,                          // <200ms for streaming start
            firstChunk: 200,                         // First chunk target
            standard: 500,                           // Standard response
            complex: 2000                            // Complex operations
        },

        // Complexity Scoring
        complexity: {
            imageSizeThresholds: {
                large: 500,                          // KB
                medium: 200                          // KB
            },
            contextLengthThresholds: {
                long: 500,                           // characters
                medium: 200                          // characters
            },
            complexityBoost: {
                largeImage: 0.2,
                mediumImage: 0.1,
                longContext: 0.15,
                mediumContext: 0.1
            }
        },

        // Alert Thresholds
        alerts: {
            responseTime: 2000,                      // Alert if > 2s
            errorRate: 10.0,                         // Alert if > 10%
            minRecoveryRate: 90                      // Alert if < 90%
        },

        // Polling Configuration
        polling: {
            interval: 500,                           // 500ms poll interval
            maxAttempts: 20                          // Max polling attempts
        }
    },

    // ============================================================================
    // AI SERVICE CONFIGURATION
    // ============================================================================
    ai: {
        // Model Names
        models: {
            grok: 'grok-4-fast',
            gemini: 'gemini-1.5-flash',
            grok4fast: 'grok-4-fast'
        },

        // API URLs
        apiUrls: {
            grok: 'https://api.x.ai/v1',
            elevenlabs: 'https://api.elevenlabs.io/v1'
        },

        // Token Estimation
        tokens: {
            basePromptTokens: 500                    // Base prompt overhead
        }
    },

    // ============================================================================
    // DATABASE CONFIGURATION
    // ============================================================================
    database: {
        type: 'sqlite',                              // Currently using SQLite
        path: './data/vibe8.db',

        // Time Filter Intervals
        timeFilters: {
            '1d': "created_at >= NOW() - INTERVAL '1 day'",
            '7d': "created_at >= NOW() - INTERVAL '7 days'",
            '30d': "created_at >= NOW() - INTERVAL '30 days'"
        }
    },

    // ============================================================================
    // SERVER CONFIGURATION
    // ============================================================================
    server: {
        defaultPort: 3000,
        appVersion: '1.0.0',

        // Request Limits
        requestLimits: {
            json: '10mb',
            urlencoded: '10mb'
        },

        // Signals
        shutdownSignals: ['SIGTERM', 'SIGINT']
    },

    // ============================================================================
    // LOGGING CONFIGURATION
    // ============================================================================
    logging: {
        levels: {
            error: 'error',
            warn: 'warn',
            info: 'info',
            debug: 'debug'
        },

        defaultLevel: 'info'
    },

    // ============================================================================
    // FEATURE FLAGS
    // ============================================================================
    features: {
        rateLimitingEnabled: {
            flirts: false,                           // Disabled for MVP testing
            default: true
        },

        testMode: {
            allowTestToken: true
        }
    },

    // ============================================================================
    // AVAILABLE ENDPOINTS LIST (for 404 responses)
    // ============================================================================
    availableEndpoints: [
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
};
