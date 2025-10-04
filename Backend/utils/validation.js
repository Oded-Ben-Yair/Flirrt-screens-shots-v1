const validator = require('validator');
const xss = require('xss');

/**
 * Input Validation Utilities
 * Centralized validation functions for security
 */

// Valid suggestion types whitelist
const VALID_SUGGESTION_TYPES = ['opener', 'reply', 'question', 'compliment', 'icebreaker', 'response', 'continuation'];

// Valid tone types whitelist
const VALID_TONES = ['playful', 'direct', 'thoughtful', 'witty', 'romantic', 'casual', 'bold'];

/**
 * Validate screenshot ID
 * @param {string} screenshotId - Screenshot ID to validate
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateScreenshotId(screenshotId) {
    if (!screenshotId) {
        return { valid: false, error: 'Screenshot ID is required' };
    }

    if (typeof screenshotId !== 'string') {
        return { valid: false, error: 'Screenshot ID must be a string' };
    }

    // Allow alphanumeric with hyphens and underscores, max 100 chars
    if (!validator.isAlphanumeric(screenshotId.replace(/[-_]/g, '')) || screenshotId.length > 100) {
        return { valid: false, error: 'Invalid screenshot ID format' };
    }

    return { valid: true, error: null };
}

/**
 * Validate suggestion type
 * @param {string} suggestionType - Suggestion type to validate
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateSuggestionType(suggestionType) {
    if (!suggestionType) {
        return { valid: false, error: 'Suggestion type is required' };
    }

    if (!VALID_SUGGESTION_TYPES.includes(suggestionType)) {
        return {
            valid: false,
            error: `Invalid suggestion type. Must be one of: ${VALID_SUGGESTION_TYPES.join(', ')}`
        };
    }

    return { valid: true, error: null };
}

/**
 * Validate tone
 * @param {string} tone - Tone to validate
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateTone(tone) {
    if (!tone) {
        return { valid: false, error: 'Tone is required' };
    }

    if (!VALID_TONES.includes(tone)) {
        return {
            valid: false,
            error: `Invalid tone. Must be one of: ${VALID_TONES.join(', ')}`
        };
    }

    return { valid: true, error: null };
}

/**
 * Sanitize text input to prevent XSS
 * @param {string} text - Text to sanitize
 * @returns {string} Sanitized text
 */
function sanitizeText(text) {
    if (typeof text !== 'string') {
        return '';
    }

    return xss(text, {
        whiteList: {}, // No HTML tags allowed
        stripIgnoreTag: true,
        stripIgnoreTagBody: ['script', 'style']
    });
}

/**
 * Sanitize suggestion object for safe output
 * @param {Object} suggestion - Suggestion object to sanitize
 * @returns {Object} Sanitized suggestion
 */
function sanitizeSuggestion(suggestion) {
    if (!suggestion || typeof suggestion !== 'object') {
        return {};
    }

    return {
        ...suggestion,
        text: sanitizeText(suggestion.text || ''),
        reasoning: sanitizeText(suggestion.reasoning || ''),
        // Preserve other fields as-is (numbers, booleans, etc.)
        confidence: suggestion.confidence,
        created_at: suggestion.created_at,
        id: suggestion.id,
        tone: suggestion.tone,
        references: suggestion.references
    };
}

/**
 * Sanitize array of suggestions
 * @param {Array} suggestions - Array of suggestion objects
 * @returns {Array} Sanitized suggestions
 */
function sanitizeSuggestions(suggestions) {
    if (!Array.isArray(suggestions)) {
        return [];
    }

    return suggestions.map(sanitizeSuggestion);
}

/**
 * Validate text length
 * @param {string} text - Text to validate
 * @param {number} maxLength - Maximum allowed length
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateTextLength(text, maxLength = 1000) {
    if (!text) {
        return { valid: false, error: 'Text is required' };
    }

    if (typeof text !== 'string') {
        return { valid: false, error: 'Text must be a string' };
    }

    if (text.length > maxLength) {
        return {
            valid: false,
            error: `Text too long. Maximum ${maxLength} characters allowed`
        };
    }

    return { valid: true, error: null };
}

/**
 * Validate voice model
 * @param {string} voiceModel - Voice model to validate
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateVoiceModel(voiceModel) {
    const validModels = [
        'eleven_monolingual_v1',
        'eleven_multilingual_v1',
        'eleven_multilingual_v2'
    ];

    if (!voiceModel) {
        return { valid: true, error: null }; // Optional parameter
    }

    if (!validModels.includes(voiceModel)) {
        return {
            valid: false,
            error: `Invalid voice model. Must be one of: ${validModels.join(', ')}`
        };
    }

    return { valid: true, error: null };
}

/**
 * Validate voice ID (alphanumeric only)
 * @param {string} voiceId - Voice ID to validate
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateVoiceId(voiceId) {
    if (!voiceId) {
        return { valid: true, error: null }; // Optional parameter
    }

    if (typeof voiceId !== 'string' || !validator.isAlphanumeric(voiceId) || voiceId.length > 50) {
        return { valid: false, error: 'Invalid voice ID format' };
    }

    return { valid: true, error: null };
}

module.exports = {
    validateScreenshotId,
    validateSuggestionType,
    validateTone,
    validateTextLength,
    validateVoiceModel,
    validateVoiceId,
    sanitizeText,
    sanitizeSuggestion,
    sanitizeSuggestions,
    VALID_SUGGESTION_TYPES,
    VALID_TONES
};
