/**
 * Centralized Error Handling Utilities
 * Provides consistent error handling patterns across the application
 */

// HTTP Status Codes
const httpStatus = {
    OK: 200,
    CREATED: 201,
    ACCEPTED: 202,
    NO_CONTENT: 204,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    METHOD_NOT_ALLOWED: 405,
    REQUEST_TIMEOUT: 408,
    CONFLICT: 409,
    PAYLOAD_TOO_LARGE: 413,
    UNSUPPORTED_MEDIA_TYPE: 415,
    TOO_MANY_REQUESTS: 429,
    INTERNAL_SERVER_ERROR: 500,
    BAD_GATEWAY: 502,
    SERVICE_UNAVAILABLE: 503,
    GATEWAY_TIMEOUT: 504
};

// Error Codes
const errorCodes = {
    // Validation Errors (400)
    VALIDATION_ERROR: 'VALIDATION_ERROR',
    MISSING_REQUIRED_FIELD: 'MISSING_REQUIRED_FIELD',
    INVALID_FORMAT: 'INVALID_FORMAT',
    INVALID_INPUT: 'INVALID_INPUT',

    // Authentication Errors (401)
    AUTHENTICATION_FAILED: 'AUTHENTICATION_FAILED',
    INVALID_TOKEN: 'INVALID_TOKEN',
    TOKEN_EXPIRED: 'TOKEN_EXPIRED',

    // Authorization Errors (403)
    ACCESS_DENIED: 'ACCESS_DENIED',
    INSUFFICIENT_PERMISSIONS: 'INSUFFICIENT_PERMISSIONS',

    // Not Found Errors (404)
    RESOURCE_NOT_FOUND: 'RESOURCE_NOT_FOUND',
    SCREENSHOT_NOT_FOUND: 'SCREENSHOT_NOT_FOUND',
    SUGGESTION_NOT_FOUND: 'SUGGESTION_NOT_FOUND',
    VOICE_MESSAGE_NOT_FOUND: 'VOICE_MESSAGE_NOT_FOUND',

    // Timeout Errors (408, 504)
    REQUEST_TIMEOUT: 'REQUEST_TIMEOUT',
    API_TIMEOUT: 'API_TIMEOUT',

    // Rate Limit Errors (429)
    RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
    QUOTA_EXCEEDED: 'QUOTA_EXCEEDED',

    // Server Errors (500)
    INTERNAL_SERVER_ERROR: 'INTERNAL_SERVER_ERROR',
    DATABASE_ERROR: 'DATABASE_ERROR',
    CACHE_ERROR: 'CACHE_ERROR',

    // External API Errors (502, 503)
    EXTERNAL_API_ERROR: 'EXTERNAL_API_ERROR',
    GROK_API_ERROR: 'GROK_API_ERROR',
    ELEVENLABS_API_ERROR: 'ELEVENLABS_API_ERROR',
    GEMINI_API_ERROR: 'GEMINI_API_ERROR',
    SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',

    // Processing Errors
    FLIRT_GENERATION_ERROR: 'FLIRT_GENERATION_ERROR',
    VOICE_SYNTHESIS_ERROR: 'VOICE_SYNTHESIS_ERROR',
    IMAGE_PROCESSING_ERROR: 'IMAGE_PROCESSING_ERROR',
    STREAM_ERROR: 'STREAM_ERROR'
};

// Error Messages
const errorMessages = {
    [errorCodes.VALIDATION_ERROR]: 'Validation failed',
    [errorCodes.MISSING_REQUIRED_FIELD]: 'Required field is missing',
    [errorCodes.INVALID_FORMAT]: 'Invalid format',
    [errorCodes.INVALID_INPUT]: 'Invalid input provided',
    [errorCodes.AUTHENTICATION_FAILED]: 'Authentication failed',
    [errorCodes.INVALID_TOKEN]: 'Invalid authentication token',
    [errorCodes.TOKEN_EXPIRED]: 'Authentication token has expired',
    [errorCodes.ACCESS_DENIED]: 'Access denied',
    [errorCodes.INSUFFICIENT_PERMISSIONS]: 'Insufficient permissions',
    [errorCodes.RESOURCE_NOT_FOUND]: 'Resource not found',
    [errorCodes.REQUEST_TIMEOUT]: 'Request timeout',
    [errorCodes.API_TIMEOUT]: 'API request timeout',
    [errorCodes.RATE_LIMIT_EXCEEDED]: 'Rate limit exceeded',
    [errorCodes.QUOTA_EXCEEDED]: 'API quota exceeded',
    [errorCodes.INTERNAL_SERVER_ERROR]: 'Internal server error',
    [errorCodes.DATABASE_ERROR]: 'Database operation failed',
    [errorCodes.EXTERNAL_API_ERROR]: 'External API error',
    [errorCodes.SERVICE_UNAVAILABLE]: 'Service temporarily unavailable'
};

/**
 * Structured error logging with context
 * @param {string} context - Error context (e.g., 'generate_flirts', 'voice_synthesis')
 * @param {Error} error - Error object
 * @param {Object} metadata - Additional metadata for debugging
 */
function logError(context, error, metadata = {}) {
    const errorLog = {
        timestamp: new Date().toISOString(),
        context,
        error: {
            message: error.message,
            stack: error.stack,
            code: error.code,
            name: error.name
        },
        metadata
    };

    console.error(JSON.stringify(errorLog, null, 2));
}

/**
 * Create standardized error response
 * @param {Object} res - Express response object
 * @param {number} statusCode - HTTP status code
 * @param {string} code - Error code
 * @param {string} message - Error message
 * @param {Object} details - Additional error details
 * @param {string} requestId - Request ID for tracking
 */
function sendErrorResponse(res, statusCode, code, message, details = null, requestId = null) {
    const errorResponse = {
        success: false,
        error: {
            code,
            message,
            ...(details && { details })
        },
        ...(requestId && { request_id: requestId })
    };

    res.status(statusCode).json(errorResponse);
}

/**
 * Create standardized success response
 * @param {Object} res - Express response object
 * @param {Object} data - Response data
 * @param {string} message - Success message
 * @param {string} requestId - Request ID for tracking
 */
function sendSuccessResponse(res, data, message = null, requestId = null) {
    const successResponse = {
        success: true,
        data,
        ...(message && { message }),
        ...(requestId && { request_id: requestId })
    };

    res.status(httpStatus.OK).json(successResponse);
}

/**
 * Handle specific error types and return appropriate response
 * @param {Error} error - Error object
 * @param {Object} res - Express response object
 * @param {string} context - Error context
 * @param {string} requestId - Request ID for tracking
 */
function handleError(error, res, context, requestId = null) {
    // Log the error with context
    logError(context, error, { requestId });

    // Handle specific error types

    // Connection/Network Errors
    if (error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT') {
        return sendErrorResponse(
            res,
            httpStatus.GATEWAY_TIMEOUT,
            errorCodes.REQUEST_TIMEOUT,
            'Request timeout',
            { timeout: error.timeout || 'unknown' },
            requestId
        );
    }

    if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
        return sendErrorResponse(
            res,
            httpStatus.BAD_GATEWAY,
            errorCodes.EXTERNAL_API_ERROR,
            'Unable to connect to external service',
            { service: error.hostname || 'unknown' },
            requestId
        );
    }

    // Rate Limiting
    if (error.response?.status === 429 || error.code === 'RATE_LIMIT_EXCEEDED') {
        const retryAfter = error.response?.headers?.['retry-after'] || null;
        return sendErrorResponse(
            res,
            httpStatus.TOO_MANY_REQUESTS,
            errorCodes.RATE_LIMIT_EXCEEDED,
            'Rate limit exceeded',
            { retry_after: retryAfter },
            requestId
        );
    }

    // API Quota Exceeded
    if (error.response?.status === 402 || error.message?.toLowerCase().includes('quota')) {
        return sendErrorResponse(
            res,
            httpStatus.PAYMENT_REQUIRED,
            errorCodes.QUOTA_EXCEEDED,
            'API quota exceeded',
            { service: error.service || 'unknown' },
            requestId
        );
    }

    // Authentication Errors
    if (error.response?.status === 401 || error.code === 'INVALID_TOKEN') {
        return sendErrorResponse(
            res,
            httpStatus.UNAUTHORIZED,
            errorCodes.AUTHENTICATION_FAILED,
            'Authentication failed',
            null,
            requestId
        );
    }

    // Authorization Errors
    if (error.response?.status === 403) {
        return sendErrorResponse(
            res,
            httpStatus.FORBIDDEN,
            errorCodes.ACCESS_DENIED,
            'Access denied',
            null,
            requestId
        );
    }

    // Not Found Errors
    if (error.response?.status === 404) {
        return sendErrorResponse(
            res,
            httpStatus.NOT_FOUND,
            errorCodes.RESOURCE_NOT_FOUND,
            'Resource not found',
            null,
            requestId
        );
    }

    // Bad Gateway Errors
    if (error.response?.status === 502) {
        return sendErrorResponse(
            res,
            httpStatus.BAD_GATEWAY,
            errorCodes.EXTERNAL_API_ERROR,
            'External API error',
            { details: error.response?.data },
            requestId
        );
    }

    // Service Unavailable Errors
    if (error.response?.status === 503) {
        return sendErrorResponse(
            res,
            httpStatus.SERVICE_UNAVAILABLE,
            errorCodes.SERVICE_UNAVAILABLE,
            'Service temporarily unavailable',
            null,
            requestId
        );
    }

    // Validation Errors
    if (error.name === 'ValidationError' || error.code === 'VALIDATION_ERROR') {
        return sendErrorResponse(
            res,
            httpStatus.BAD_REQUEST,
            errorCodes.VALIDATION_ERROR,
            error.message || 'Validation failed',
            error.details || null,
            requestId
        );
    }

    // Default Internal Server Error
    return sendErrorResponse(
        res,
        httpStatus.INTERNAL_SERVER_ERROR,
        errorCodes.INTERNAL_SERVER_ERROR,
        'Internal server error',
        process.env.NODE_ENV === 'development' ? { message: error.message } : null,
        requestId
    );
}

/**
 * Async handler wrapper to catch errors in async route handlers
 * @param {Function} fn - Async function to wrap
 * @returns {Function} Wrapped function with error handling
 */
function asyncHandler(fn) {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
}

/**
 * Handle unhandled promise rejections in service functions
 * @param {Promise} promise - Promise to handle
 * @param {string} context - Context for error logging
 * @returns {Promise} Promise with error handling
 */
async function handlePromise(promise, context) {
    try {
        return await promise;
    } catch (error) {
        logError(context, error);
        throw error;
    }
}

/**
 * Validate required fields in request
 * @param {Object} data - Data to validate
 * @param {Array} requiredFields - Array of required field names
 * @throws {Error} Validation error if fields are missing
 */
function validateRequiredFields(data, requiredFields) {
    const missingFields = [];

    for (const field of requiredFields) {
        if (data[field] === undefined || data[field] === null || data[field] === '') {
            missingFields.push(field);
        }
    }

    if (missingFields.length > 0) {
        const error = new Error(`Missing required fields: ${missingFields.join(', ')}`);
        error.code = errorCodes.MISSING_REQUIRED_FIELD;
        error.details = { missingFields };
        throw error;
    }
}

module.exports = {
    httpStatus,
    errorCodes,
    errorMessages,
    logError,
    sendErrorResponse,
    sendSuccessResponse,
    handleError,
    asyncHandler,
    handlePromise,
    validateRequiredFields
};
