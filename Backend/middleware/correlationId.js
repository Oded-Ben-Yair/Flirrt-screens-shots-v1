const { v4: uuidv4 } = require('uuid');
const { logger } = require('../services/logger');

/**
 * Correlation ID Middleware
 * Adds unique correlation ID to each request for tracing
 */
const correlationIdMiddleware = (req, res, next) => {
    // Check if correlation ID is provided in headers, otherwise generate new one
    const correlationId = req.headers['x-correlation-id'] ||
                         req.headers['x-request-id'] ||
                         uuidv4();

    // Add to request object
    req.correlationId = correlationId;

    // Add to response headers
    res.setHeader('X-Correlation-ID', correlationId);

    // Add correlation ID to logger context for this request
    req.logger = {
        debug: (message, meta = {}) => logger.debug(message, meta, correlationId),
        info: (message, meta = {}) => logger.info(message, meta, correlationId),
        warn: (message, meta = {}) => logger.warn(message, meta, correlationId),
        error: (message, meta = {}) => logger.error(message, meta, correlationId),
        timer: (operation) => logger.timer(operation, correlationId)
    };

    // Log request start
    req.logger.info('Request started', {
        method: req.method,
        url: req.url,
        userAgent: req.headers['user-agent'],
        ip: req.ip || req.connection.remoteAddress,
        userId: req.user?.id || 'anonymous'
    });

    // Track request timing
    req.startTime = Date.now();

    // Override res.json to log response
    const originalJson = res.json;
    res.json = function(body) {
        const duration = Date.now() - req.startTime;

        req.logger.info('Request completed', {
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            userId: req.user?.id || 'anonymous',
            responseSize: JSON.stringify(body).length
        });

        return originalJson.call(this, body);
    };

    // Handle response end for non-JSON responses
    const originalEnd = res.end;
    res.end = function(chunk, encoding) {
        if (!res.headersSent) {
            const duration = Date.now() - req.startTime;

            req.logger.info('Request completed', {
                method: req.method,
                url: req.url,
                statusCode: res.statusCode,
                duration: `${duration}ms`,
                userId: req.user?.id || 'anonymous',
                responseType: res.getHeader('content-type') || 'unknown'
            });
        }

        return originalEnd.call(this, chunk, encoding);
    };

    next();
};

/**
 * Error Correlation Middleware
 * Ensures errors are logged with correlation IDs
 */
const errorCorrelationMiddleware = (error, req, res, next) => {
    const correlationId = req.correlationId || uuidv4();

    // Add correlation ID to response headers if not already present
    if (!res.getHeader('X-Correlation-ID')) {
        res.setHeader('X-Correlation-ID', correlationId);
    }

    // Log error with correlation ID
    const errorLogger = req.logger || {
        error: (message, meta = {}) => logger.error(message, meta, correlationId)
    };

    const duration = req.startTime ? Date.now() - req.startTime : null;

    errorLogger.error('Request failed', {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode || 500,
        error: error.message,
        stack: error.stack,
        userId: req.user?.id || 'anonymous',
        ...(duration && { duration: `${duration}ms` })
    });

    // Add correlation ID to error response
    if (error.correlationId === undefined) {
        error.correlationId = correlationId;
    }

    next(error);
};

/**
 * Request Logger Middleware
 * Enhanced request logging with correlation IDs
 */
const requestLoggerMiddleware = (req, res, next) => {
    // Skip health check endpoints from detailed logging
    if (req.path === '/health' || req.path.startsWith('/health/')) {
        return next();
    }

    const startTime = Date.now();

    // Log request details
    req.logger.info('Processing request', {
        method: req.method,
        url: req.url,
        query: Object.keys(req.query).length > 0 ? req.query : undefined,
        body: req.method !== 'GET' && req.body ? {
            // Sanitize sensitive fields
            ...req.body,
            password: req.body.password ? '[REDACTED]' : undefined,
            token: req.body.token ? '[REDACTED]' : undefined,
            api_key: req.body.api_key ? '[REDACTED]' : undefined
        } : undefined,
        contentType: req.headers['content-type'],
        contentLength: req.headers['content-length'],
        userId: req.user?.id || 'anonymous'
    });

    // Track response when finished
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const level = res.statusCode >= 400 ? 'warn' : 'info';

        req.logger[level]('Request finished', {
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            contentLength: res.getHeader('content-length'),
            userId: req.user?.id || 'anonymous'
        });
    });

    next();
};

/**
 * Database Correlation Middleware
 * Adds correlation ID context to database operations
 */
const addDbCorrelation = (req, res, next) => {
    // Add correlation helper for database operations
    req.dbQuery = async (pool, query, params = []) => {
        const timer = req.logger.timer('database-query');

        try {
            const result = await pool.query(query, params);

            timer.finish({
                query: query.substring(0, 100) + (query.length > 100 ? '...' : ''),
                rowCount: result.rowCount,
                success: true
            });

            req.logger.debug('Database query executed', {
                query: query.substring(0, 200) + (query.length > 200 ? '...' : ''),
                params: params.length,
                rowCount: result.rowCount,
                duration: timer.finish()
            });

            return result;
        } catch (error) {
            timer.error(error, {
                query: query.substring(0, 100) + (query.length > 100 ? '...' : ''),
                params: params.length
            });

            req.logger.error('Database query failed', {
                query: query.substring(0, 200) + (query.length > 200 ? '...' : ''),
                params: params.length,
                error: error.message
            });

            throw error;
        }
    };

    next();
};

/**
 * API Call Correlation Middleware
 * Adds correlation context to external API calls
 */
const addApiCorrelation = (req, res, next) => {
    // Add correlation helper for external API calls
    req.apiCall = async (serviceName, operation, apiFunction) => {
        const timer = req.logger.timer(`${serviceName}-api-call`);

        try {
            req.logger.info('External API call started', {
                service: serviceName,
                operation
            });

            const result = await apiFunction();

            req.logger.info('External API call completed', {
                service: serviceName,
                operation,
                duration: timer.finish(),
                success: true,
                statusCode: result.statusCode
            });

            return result;
        } catch (error) {
            timer.error(error, {
                service: serviceName,
                operation
            });

            req.logger.error('External API call failed', {
                service: serviceName,
                operation,
                error: error.message,
                statusCode: error.response?.status
            });

            throw error;
        }
    };

    next();
};

/**
 * User Action Logger Middleware
 * Logs significant user actions with correlation IDs
 */
const userActionLogger = (action) => {
    return (req, res, next) => {
        if (req.user) {
            req.logger.info('User action', {
                action,
                userId: req.user.id,
                userEmail: req.user.email,
                sessionId: req.user.sessionId,
                ip: req.ip || req.connection.remoteAddress,
                userAgent: req.headers['user-agent']
            });
        }
        next();
    };
};

/**
 * Rate Limit Logger Middleware
 * Logs rate limit events with correlation IDs
 */
const rateLimitLogger = (req, res, next) => {
    const originalStatus = res.status;

    res.status = function(code) {
        if (code === 429) {
            req.logger.warn('Rate limit exceeded', {
                userId: req.user?.id || 'anonymous',
                ip: req.ip || req.connection.remoteAddress,
                endpoint: req.url,
                method: req.method,
                userAgent: req.headers['user-agent']
            });
        }
        return originalStatus.call(this, code);
    };

    next();
};

module.exports = {
    correlationIdMiddleware,
    errorCorrelationMiddleware,
    requestLoggerMiddleware,
    addDbCorrelation,
    addApiCorrelation,
    userActionLogger,
    rateLimitLogger
};