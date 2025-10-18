const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

/**
 * JWT Authentication Middleware
 * Validates JWT tokens and adds user information to request
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

        // Validate token format (must be a string)
        if (typeof token !== 'string' || token.trim() === '') {
            return res.status(401).json({
                success: false,
                error: 'Invalid token format',
                code: 'TOKEN_MALFORMED'
            });
        }

        // Allow test token ONLY in test environment
        if (process.env.NODE_ENV === 'test' && token === 'test-token-for-api-testing') {
            req.user = {
                id: 'test-user-id',
                email: 'test@vibe8.ai',
                sessionId: 'test-session-id',
                isVerified: true
            };
            return next();
        }

        // Verify JWT token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Additional expiration check (belt and suspenders approach)
        if (decoded.exp && Date.now() >= decoded.exp * 1000) {
            return res.status(401).json({
                success: false,
                error: 'Token has expired',
                code: 'TOKEN_EXPIRED'
            });
        }

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
            return res.status(401).json({
                success: false,
                error: 'Invalid or expired token',
                code: 'TOKEN_INVALID'
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
            isVerified: session.is_verified
        };

        next();
    } catch (error) {
        console.error('Authentication error:', error);

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
            code: 'AUTH_SERVICE_ERROR'
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
 * Rate Limiting Middleware
 * Prevents abuse by limiting requests per user
 */
const rateLimit = (maxRequests = 100, windowMs = 15 * 60 * 1000) => {
    const requests = new Map();

    return (req, res, next) => {
        const identifier = req.user ? req.user.id : req.ip;
        const now = Date.now();
        const windowStart = now - windowMs;

        if (!requests.has(identifier)) {
            requests.set(identifier, []);
        }

        const userRequests = requests.get(identifier);

        // Remove old requests outside the window
        const validRequests = userRequests.filter(time => time > windowStart);

        if (validRequests.length >= maxRequests) {
            return res.status(429).json({
                success: false,
                error: 'Too many requests',
                code: 'RATE_LIMIT_EXCEEDED',
                retryAfter: Math.ceil(windowMs / 1000)
            });
        }

        validRequests.push(now);
        requests.set(identifier, validRequests);

        next();
    };
};

module.exports = {
    authenticateToken,
    optionalAuth,
    requireAdmin,
    rateLimit
};