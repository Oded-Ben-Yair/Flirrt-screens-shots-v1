const winston = require('winston');
const path = require('path');
const fs = require('fs');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Custom format for correlation IDs and structured logging
const customFormat = winston.format.combine(
    winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss.SSS'
    }),
    winston.format.errors({ stack: true }),
    winston.format.json(),
    winston.format.printf((info) => {
        const { timestamp, level, message, correlationId, ...meta } = info;

        const logEntry = {
            timestamp,
            level: level.toUpperCase(),
            message,
            ...(correlationId && { correlationId }),
            ...(Object.keys(meta).length > 0 && { meta })
        };

        return JSON.stringify(logEntry);
    })
);

// Console format for development
const consoleFormat = winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp({
        format: 'HH:mm:ss'
    }),
    winston.format.printf((info) => {
        const { timestamp, level, message, correlationId, ...meta } = info;

        let logString = `${timestamp} [${level}]`;

        if (correlationId) {
            logString += ` [${correlationId}]`;
        }

        logString += `: ${message}`;

        if (Object.keys(meta).length > 0) {
            logString += ` ${JSON.stringify(meta)}`;
        }

        return logString;
    })
);

// Create the logger
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: customFormat,
    defaultMeta: {
        service: 'flirrt-backend',
        version: process.env.APP_VERSION || '1.0.0',
        environment: process.env.NODE_ENV || 'development'
    },
    transports: [
        // Error logs - separate file
        new winston.transports.File({
            filename: path.join(logsDir, 'error.log'),
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.errors({ stack: true }),
                winston.format.json()
            )
        }),

        // Combined logs
        new winston.transports.File({
            filename: path.join(logsDir, 'combined.log'),
            maxsize: 5242880, // 5MB
            maxFiles: 10
        }),

        // Debug logs (if enabled)
        ...(process.env.LOG_LEVEL === 'debug' ? [
            new winston.transports.File({
                filename: path.join(logsDir, 'debug.log'),
                level: 'debug',
                maxsize: 5242880,
                maxFiles: 3
            })
        ] : [])
    ],

    // Handle exceptions and rejections
    exceptionHandlers: [
        new winston.transports.File({
            filename: path.join(logsDir, 'exceptions.log'),
            maxsize: 5242880,
            maxFiles: 3
        })
    ],

    rejectionHandlers: [
        new winston.transports.File({
            filename: path.join(logsDir, 'rejections.log'),
            maxsize: 5242880,
            maxFiles: 3
        })
    ],

    exitOnError: false
});

// Add console transport in development
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: consoleFormat,
        level: process.env.LOG_LEVEL || 'debug'
    }));
}

// Performance timing helper
class PerformanceTimer {
    constructor(operation, correlationId = null) {
        this.operation = operation;
        this.correlationId = correlationId;
        this.startTime = process.hrtime.bigint();

        logger.debug('Operation started', {
            operation: this.operation,
            correlationId: this.correlationId
        });
    }

    finish(additionalData = {}) {
        const endTime = process.hrtime.bigint();
        const duration = Number(endTime - this.startTime) / 1000000; // Convert to milliseconds

        logger.info('Operation completed', {
            operation: this.operation,
            duration: `${duration.toFixed(2)}ms`,
            correlationId: this.correlationId,
            ...additionalData
        });

        return duration;
    }

    error(error, additionalData = {}) {
        const endTime = process.hrtime.bigint();
        const duration = Number(endTime - this.startTime) / 1000000;

        logger.error('Operation failed', {
            operation: this.operation,
            duration: `${duration.toFixed(2)}ms`,
            error: error.message,
            stack: error.stack,
            correlationId: this.correlationId,
            ...additionalData
        });

        return duration;
    }
}

// Enhanced logger with correlation ID support
class EnhancedLogger {
    constructor(baseLogger) {
        this.winston = baseLogger;
    }

    // Helper to add correlation ID to log entries
    _log(level, message, meta = {}, correlationId = null) {
        const logData = {
            ...meta,
            ...(correlationId && { correlationId })
        };

        this.winston[level](message, logData);
    }

    debug(message, meta = {}, correlationId = null) {
        this._log('debug', message, meta, correlationId);
    }

    info(message, meta = {}, correlationId = null) {
        this._log('info', message, meta, correlationId);
    }

    warn(message, meta = {}, correlationId = null) {
        this._log('warn', message, meta, correlationId);
    }

    error(message, meta = {}, correlationId = null) {
        this._log('error', message, meta, correlationId);
    }

    // Create performance timer
    timer(operation, correlationId = null) {
        return new PerformanceTimer(operation, correlationId);
    }

    // Log API request/response
    logApiCall(method, url, statusCode, duration, correlationId = null, additionalData = {}) {
        const level = statusCode >= 400 ? 'warn' : 'info';

        this._log(level, 'API call', {
            method,
            url,
            statusCode,
            duration: `${duration}ms`,
            ...additionalData
        }, correlationId);
    }

    // Log database operations
    logDbOperation(operation, duration, rowCount = null, correlationId = null) {
        this._log('debug', 'Database operation', {
            operation,
            duration: `${duration}ms`,
            ...(rowCount !== null && { rowCount })
        }, correlationId);
    }

    // Log cache operations
    logCacheOperation(operation, key, hit = null, correlationId = null) {
        this._log('debug', 'Cache operation', {
            operation,
            key,
            ...(hit !== null && { hit })
        }, correlationId);
    }

    // Log external API calls
    logExternalApi(service, operation, duration, success = true, correlationId = null, error = null) {
        const level = success ? 'info' : 'error';

        this._log(level, 'External API call', {
            service,
            operation,
            duration: `${duration}ms`,
            success,
            ...(error && { error: error.message })
        }, correlationId);
    }

    // Security logging
    logSecurityEvent(event, userId = null, ip = null, correlationId = null, additionalData = {}) {
        this._log('warn', 'Security event', {
            event,
            userId,
            ip,
            timestamp: new Date().toISOString(),
            ...additionalData
        }, correlationId);
    }

    // User action logging
    logUserAction(action, userId, correlationId = null, additionalData = {}) {
        this._log('info', 'User action', {
            action,
            userId,
            timestamp: new Date().toISOString(),
            ...additionalData
        }, correlationId);
    }

    // Business logic logging
    logBusinessEvent(event, data = {}, correlationId = null) {
        this._log('info', 'Business event', {
            event,
            timestamp: new Date().toISOString(),
            ...data
        }, correlationId);
    }
}

const enhancedLogger = new EnhancedLogger(logger);

// Health check for logging system
const getLoggerHealth = () => {
    try {
        const logFiles = [
            path.join(logsDir, 'combined.log'),
            path.join(logsDir, 'error.log')
        ];

        const health = {
            status: 'healthy',
            logLevel: logger.level,
            logDirectory: logsDir,
            files: {}
        };

        logFiles.forEach(file => {
            if (fs.existsSync(file)) {
                const stats = fs.statSync(file);
                health.files[path.basename(file)] = {
                    size: `${(stats.size / 1024 / 1024).toFixed(2)}MB`,
                    lastModified: stats.mtime.toISOString()
                };
            }
        });

        return health;
    } catch (error) {
        return {
            status: 'error',
            error: error.message
        };
    }
};

module.exports = {
    logger: enhancedLogger,
    rawLogger: logger,
    PerformanceTimer,
    getLoggerHealth
};