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
    // Check for null/undefined/empty
    if (screenshotId === null || screenshotId === undefined || screenshotId === '') {
        return { valid: false, error: 'Screenshot ID is required and cannot be empty' };
    }

    if (typeof screenshotId !== 'string') {
        return { valid: false, error: 'Screenshot ID must be a string' };
    }

    // Trim and check for whitespace-only strings
    const trimmed = screenshotId.trim();
    if (trimmed === '') {
        return { valid: false, error: 'Screenshot ID cannot be empty or whitespace' };
    }

    // Allow alphanumeric with hyphens and underscores, max 100 chars
    if (!validator.isAlphanumeric(trimmed.replace(/[-_]/g, '')) || trimmed.length > 100) {
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
    // Check for null/undefined/empty
    if (suggestionType === null || suggestionType === undefined || suggestionType === '') {
        return { valid: false, error: 'Suggestion type is required and cannot be empty' };
    }

    if (typeof suggestionType !== 'string') {
        return { valid: false, error: 'Suggestion type must be a string' };
    }

    const trimmed = suggestionType.trim();
    if (trimmed === '') {
        return { valid: false, error: 'Suggestion type cannot be empty or whitespace' };
    }

    if (!VALID_SUGGESTION_TYPES.includes(trimmed)) {
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
    // Check for null/undefined/empty
    if (tone === null || tone === undefined || tone === '') {
        return { valid: false, error: 'Tone is required and cannot be empty' };
    }

    if (typeof tone !== 'string') {
        return { valid: false, error: 'Tone must be a string' };
    }

    const trimmed = tone.trim();
    if (trimmed === '') {
        return { valid: false, error: 'Tone cannot be empty or whitespace' };
    }

    if (!VALID_TONES.includes(trimmed)) {
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
    // Check for null/undefined/empty
    if (text === null || text === undefined || text === '') {
        return { valid: false, error: 'Text is required and cannot be empty' };
    }

    if (typeof text !== 'string') {
        return { valid: false, error: 'Text must be a string' };
    }

    const trimmed = text.trim();
    if (trimmed === '') {
        return { valid: false, error: 'Text cannot be empty or whitespace' };
    }

    if (trimmed.length > maxLength) {
        return {
            valid: false,
            error: `Text too long. Maximum ${maxLength} characters allowed`
        };
    }

    return { valid: true, error: null };
}

/**
 * Validate required string field with max length
 * @param {*} value - Value to validate
 * @param {string} fieldName - Field name for error messages
 * @param {number} maxLength - Maximum allowed length (default 1000)
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateRequiredString(value, fieldName, maxLength = 1000) {
    // Check for null/undefined
    if (value === null || value === undefined) {
        return { valid: false, error: `${fieldName} is required` };
    }

    if (typeof value !== 'string') {
        return { valid: false, error: `${fieldName} must be a string` };
    }

    const trimmed = value.trim();
    if (trimmed === '') {
        return { valid: false, error: `${fieldName} cannot be empty` };
    }

    if (trimmed.length > maxLength) {
        return {
            valid: false,
            error: `${fieldName} exceeds maximum length of ${maxLength} characters`
        };
    }

    return { valid: true, error: null };
}

/**
 * Validate optional string field with max length
 * @param {*} value - Value to validate
 * @param {string} fieldName - Field name for error messages
 * @param {number} maxLength - Maximum allowed length (default 1000)
 * @returns {Object} { valid: boolean, error: string|null }
 */
function validateOptionalString(value, fieldName, maxLength = 1000) {
    // Optional field - null/undefined is okay
    if (value === null || value === undefined) {
        return { valid: true, error: null };
    }

    if (typeof value !== 'string') {
        return { valid: false, error: `${fieldName} must be a string` };
    }

    // Empty string is okay for optional fields
    if (value.trim().length > maxLength) {
        return {
            valid: false,
            error: `${fieldName} exceeds maximum length of ${maxLength} characters`
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
    validateRequiredString,
    validateOptionalString,
    validateVoiceModel,
    validateVoiceId,
    sanitizeText,
    sanitizeSuggestion,
    sanitizeSuggestions,
    VALID_SUGGESTION_TYPES,
    VALID_TONES
};
