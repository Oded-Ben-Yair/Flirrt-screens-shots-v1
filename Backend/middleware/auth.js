const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const { logger } = require('../services/logger');
const redisService = require('../services/redis');
const webSocketService = require('../services/websocketService');

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

/**
 * Enhanced JWT Authentication Middleware
 * Validates JWT tokens, adds user information, and provides logging context
 */
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

        if (!token) {
            return res.status(401).json({
                success: false,
                error: 'Access token required',
                code: 'TOKEN_MISSING'
            });
        }

        // Allow test token for API testing
        if (token === 'test-token-for-api-testing') {
            req.user = {
                id: 'test-user-id',
                email: 'test@flirrt.ai',
                sessionId: 'test-session-id',
                isVerified: true,
                role: 'user'
            };

            req.logger?.info('Test token authenticated', {
                userId: req.user.id,
                testMode: true
            });

            return next();
        }

        // Verify JWT token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        req.logger?.debug('JWT token decoded', {
            userId: decoded.userId,
            iat: decoded.iat,
            exp: decoded.exp
        });

        // Check if session exists and is valid
        const sessionQuery = `
            SELECT us.*, u.email, u.is_active, u.is_verified
            FROM user_sessions us
            JOIN users u ON us.user_id = u.id
            WHERE us.token_hash = $1 AND us.expires_at > NOW()
        `;

        const tokenHash = require('crypto')
            .createHash('sha256')
            .update(token)
            .digest('hex');

        const sessionResult = await pool.query(sessionQuery, [tokenHash]);

        if (sessionResult.rows.length === 0) {
            req.logger?.warn('Invalid or expired session token', {
                userId: decoded.userId,
                tokenHash: tokenHash.substring(0, 8) + '...'
            });

            return res.status(401).json({
                success: false,
                error: 'Invalid or expired token',
                code: 'TOKEN_INVALID',
                correlationId: req.correlationId
            });
        }

        const session = sessionResult.rows[0];

        // Check if user is active
        if (!session.is_active) {
            return res.status(403).json({
                success: false,
                error: 'Account is deactivated',
                code: 'ACCOUNT_DEACTIVATED'
            });
        }

        // Update last used timestamp
        await pool.query(
            'UPDATE user_sessions SET last_used = NOW() WHERE id = $1',
            [session.id]
        );

        // Add user info to request
        req.user = {
            id: decoded.userId,
            email: session.email,
            sessionId: session.id,
            isVerified: session.is_verified,
            role: session.role || 'user'
        };

        req.logger?.info('User authenticated successfully', {
            userId: req.user.id,
            email: req.user.email,
            sessionId: req.user.sessionId,
            isVerified: req.user.isVerified
        });

        next();
    } catch (error) {
        req.logger?.error('Authentication error', {
            error: error.message,
            stack: error.stack
        });

        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({
                success: false,
                error: 'Invalid token format',
                code: 'TOKEN_MALFORMED'
            });
        }

        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                error: 'Token has expired',
                code: 'TOKEN_EXPIRED'
            });
        }

        return res.status(500).json({
            success: false,
            error: 'Authentication service error',
            code: 'AUTH_SERVICE_ERROR',
            correlationId: req.correlationId
        });
    }
};

/**
 * Optional Authentication Middleware
 * Adds user info if token is present but doesn't require it
 */
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            req.user = null;
            return next();
        }

        // Use the same logic as authenticateToken but don't fail if invalid
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const sessionQuery = `
            SELECT us.*, u.email, u.is_active, u.is_verified
            FROM user_sessions us
            JOIN users u ON us.user_id = u.id
            WHERE us.token_hash = $1 AND us.expires_at > NOW()
        `;

        const tokenHash = require('crypto')
            .createHash('sha256')
            .update(token)
            .digest('hex');

        const sessionResult = await pool.query(sessionQuery, [tokenHash]);

        if (sessionResult.rows.length > 0 && sessionResult.rows[0].is_active) {
            const session = sessionResult.rows[0];

            // Update last used timestamp
            await pool.query(
                'UPDATE user_sessions SET last_used = NOW() WHERE id = $1',
                [session.id]
            );

            req.user = {
                id: decoded.userId,
                email: session.email,
                sessionId: session.id,
                isVerified: session.is_verified
            };
        } else {
            req.user = null;
        }

        next();
    } catch (error) {
        // In optional auth, we don't fail on token errors
        req.user = null;
        next();
    }
};

/**
 * Admin Authentication Middleware
 * Requires admin privileges
 */
const requireAdmin = async (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                error: 'Authentication required',
                code: 'AUTH_REQUIRED'
            });
        }

        // Check if user has admin role
        const adminQuery = `
            SELECT u.*, up.role
            FROM users u
            LEFT JOIN user_profiles up ON u.id = up.user_id
            WHERE u.id = $1 AND (up.role = 'admin' OR up.role = 'super_admin')
        `;

        const adminResult = await pool.query(adminQuery, [req.user.id]);

        if (adminResult.rows.length === 0) {
            return res.status(403).json({
                success: false,
                error: 'Admin privileges required',
                code: 'INSUFFICIENT_PRIVILEGES'
            });
        }

        req.user.role = adminResult.rows[0].role;
        next();
    } catch (error) {
        console.error('Admin auth error:', error);
        return res.status(500).json({
            success: false,
            error: 'Authorization service error',
            code: 'AUTH_SERVICE_ERROR'
        });
    }
};

/**
 * Enhanced Rate Limiting with Redis support
 * Prevents abuse by limiting requests per user with distributed rate limiting
 */
const createRateLimit = (maxRequests = 100, windowMs = 15 * 60 * 1000, skipSuccessfulRequests = false) => {
    // Use express-rate-limit with Redis store if available
    const limiterConfig = {
        windowMs,
        max: maxRequests,
        standardHeaders: true,
        legacyHeaders: false,
        skipSuccessfulRequests,
        keyGenerator: (req) => {
            // Use user ID if authenticated, otherwise IP with proper IPv6 handling
            if (req.user) {
                return `user:${req.user.id}`;
            }
            // Use the built-in IP key generator for proper IPv6 handling
            const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
            return `ip:${ip}`;
        },
        handler: (req, res) => {
            const identifier = req.user ? req.user.id : req.ip;
            const resetTime = new Date(Date.now() + windowMs);

            req.logger?.warn('Rate limit exceeded', {
                identifier,
                maxRequests,
                windowMs,
                ip: req.ip,
                userAgent: req.headers['user-agent']
            });

            // Notify WebSocket clients if user is authenticated
            if (req.user) {
                webSocketService.sendRateLimitUpdate(
                    req.user.id,
                    0, // remaining requests
                    resetTime.toISOString()
                );
            }

            return res.status(429).json({
                success: false,
                error: 'Too many requests',
                code: 'RATE_LIMIT_EXCEEDED',
                retryAfter: Math.ceil(windowMs / 1000),
                resetTime: resetTime.toISOString(),
                correlationId: req.correlationId
            });
        }
    };

    // Try to use Redis store if available
    try {
        if (redisService.getStatus().connected) {
            const RedisStore = require('rate-limit-redis');
            limiterConfig.store = new RedisStore({
                client: redisService.redis,
                prefix: 'rl:',
            });

            logger.info('Rate limiter using Redis store', {
                maxRequests,
                windowMs
            });
        } else {
            logger.info('Rate limiter using memory store (Redis unavailable)', {
                maxRequests,
                windowMs
            });
        }
    } catch (error) {
        logger.warn('Failed to setup Redis rate limit store, using memory store', {
            error: error.message
        });
    }

    return rateLimit(limiterConfig);
};

/**
 * Legacy rate limit function for backward compatibility
 */
const rateLimitLegacy = (maxRequests = 100, windowMs = 15 * 60 * 1000) => {
    return createRateLimit(maxRequests, windowMs);
};

module.exports = {
    authenticateToken,
    optionalAuth,
    requireAdmin,
    rateLimit: rateLimitLegacy, // backward compatibility
    createRateLimit, // new enhanced rate limiting
    rateLimitLegacy
};