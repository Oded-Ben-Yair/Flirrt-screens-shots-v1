const { body, param, query, validationResult } = require('express-validator');

/**
 * Validation error handler middleware
 */
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            error: 'Validation failed',
            details: errors.array(),
            code: 'VALIDATION_ERROR'
        });
    }
    next();
};

/**
 * Sanitization middleware for text inputs
 */
const sanitizeInput = (field) => {
    return body(field)
        .trim()
        .escape()
        .blacklist(['<', '>', '"', "'", '&', '\0'])
        .isLength({ max: 2000 })
        .withMessage(`${field} must be less than 2000 characters`);
};

/**
 * Validation rules for screenshot analysis
 */
const validateScreenshotAnalysis = [
    body('context')
        .optional()
        .isLength({ max: 1000 })
        .withMessage('Context must be less than 1000 characters')
        .trim(),
    body('preferences')
        .optional()
        .isJSON()
        .withMessage('Preferences must be valid JSON'),
    handleValidationErrors
];

/**
 * Validation rules for flirt generation
 */
const validateFlirtGeneration = [
    body('screenshot_id')
        .notEmpty()
        .withMessage('Screenshot ID is required')
        .isLength({ max: 100 })
        .withMessage('Screenshot ID too long'),
    body('context')
        .optional()
        .isLength({ max: 1000 })
        .withMessage('Context must be less than 1000 characters')
        .trim(),
    body('suggestion_type')
        .optional()
        .isIn(['opener', 'response', 'continuation'])
        .withMessage('Invalid suggestion type'),
    body('tone')
        .optional()
        .isIn(['playful', 'witty', 'romantic', 'casual', 'bold'])
        .withMessage('Invalid tone'),
    body('user_preferences')
        .optional()
        .isObject()
        .withMessage('User preferences must be an object'),
    handleValidationErrors
];

/**
 * Validation rules for voice synthesis
 */
const validateVoiceSynthesis = [
    body('text')
        .notEmpty()
        .withMessage('Text is required')
        .isLength({ min: 1, max: 1000 })
        .withMessage('Text must be between 1 and 1000 characters')
        .trim(),
    body('flirt_suggestion_id')
        .optional()
        .isLength({ max: 100 })
        .withMessage('Flirt suggestion ID too long'),
    body('voice_model')
        .optional()
        .isIn(['eleven_monolingual_v1', 'eleven_multilingual_v2', 'eleven_turbo_v2'])
        .withMessage('Invalid voice model'),
    body('voice_id')
        .optional()
        .isLength({ max: 100 })
        .withMessage('Voice ID too long'),
    body('voice_settings')
        .optional()
        .isObject()
        .withMessage('Voice settings must be an object'),
    body('voice_settings.stability')
        .optional()
        .isFloat({ min: 0, max: 1 })
        .withMessage('Stability must be between 0 and 1'),
    body('voice_settings.similarity_boost')
        .optional()
        .isFloat({ min: 0, max: 1 })
        .withMessage('Similarity boost must be between 0 and 1'),
    body('voice_settings.style')
        .optional()
        .isFloat({ min: 0, max: 1 })
        .withMessage('Style must be between 0 and 1'),
    handleValidationErrors
];

/**
 * Validation rules for user registration
 */
const validateUserRegistration = [
    body('email')
        .isEmail()
        .withMessage('Valid email is required')
        .normalizeEmail()
        .isLength({ max: 255 })
        .withMessage('Email too long'),
    body('apple_id')
        .notEmpty()
        .withMessage('Apple ID is required')
        .isLength({ max: 255 })
        .withMessage('Apple ID too long'),
    body('age')
        .isInt({ min: 18, max: 120 })
        .withMessage('Age must be between 18 and 120'),
    body('name')
        .optional()
        .isLength({ max: 100 })
        .withMessage('Name too long')
        .trim(),
    handleValidationErrors
];

/**
 * Validation rules for pagination
 */
const validatePagination = [
    query('page')
        .optional()
        .isInt({ min: 1, max: 1000 })
        .withMessage('Page must be between 1 and 1000'),
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('Limit must be between 1 and 100'),
    handleValidationErrors
];

/**
 * Validation rules for user ID parameter
 */
const validateUserId = [
    param('id')
        .notEmpty()
        .withMessage('User ID is required')
        .isLength({ max: 100 })
        .withMessage('User ID too long'),
    handleValidationErrors
];

/**
 * Rate limiting validation
 */
const validateRating = [
    body('rating')
        .isInt({ min: 1, max: 5 })
        .withMessage('Rating must be between 1 and 5'),
    body('feedback')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Feedback must be less than 500 characters')
        .trim(),
    handleValidationErrors
];

/**
 * Security headers middleware
 */
const securityHeaders = (req, res, next) => {
    // Remove X-Powered-By header
    res.removeHeader('X-Powered-By');

    // Add security headers
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

    // Content Security Policy for API
    res.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none';");

    next();
};

/**
 * Request size limiter
 */
const requestSizeLimiter = (req, res, next) => {
    const contentLength = parseInt(req.get('Content-Length') || '0');
    const maxSize = 50 * 1024 * 1024; // 50MB

    if (contentLength > maxSize) {
        return res.status(413).json({
            success: false,
            error: 'Request entity too large',
            code: 'PAYLOAD_TOO_LARGE'
        });
    }

    next();
};

module.exports = {
    handleValidationErrors,
    sanitizeInput,
    validateScreenshotAnalysis,
    validateFlirtGeneration,
    validateVoiceSynthesis,
    validateUserRegistration,
    validatePagination,
    validateUserId,
    validateRating,
    securityHeaders,
    requestSizeLimiter
};