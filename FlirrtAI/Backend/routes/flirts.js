const express = require('express');
const { Pool } = require('pg');
const axios = require('axios');
const Redis = require('ioredis');
const { authenticateToken, rateLimit } = require('../middleware/auth');
const { httpStatus, errors, validation, cache } = require('../config/constants');
const timeouts = require('../config/timeouts');
const {
    logError,
    sendErrorResponse,
    handleError,
    errorCodes
} = require('../utils/errorHandler');
const {
    validateScreenshotId,
    validateSuggestionType,
    validateTone,
    sanitizeText
} = require('../utils/validation');
const { callGrokWithRetry } = require('../utils/apiRetry');

const router = express.Router();

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

// Redis connection for caching (optional)
let redis = null;
try {
    redis = new Redis({
        host: process.env.REDIS_HOST,
        port: process.env.REDIS_PORT,
        password: process.env.REDIS_PASSWORD,
        retryDelayOnFailover: timeouts.retry.redisRetryDelay,
        maxRetriesPerRequest: timeouts.retry.maxRetriesNetworkError,
        lazyConnect: true
    });

    redis.on('error', (err) => {
        console.warn('Redis connection error (caching disabled):', err.message);
        redis = null;
    });
} catch (error) {
    console.warn('Redis initialization failed (caching disabled):', error.message);
    redis = null;
}

/**
 * Generate Flirt Suggestions with Real Grok API
 * POST /api/v1/generate_flirts
 *
 * MVP: Authentication temporarily disabled for testing
 */
router.post('/generate_flirts',
    // authenticateToken,  // DISABLED FOR MVP TESTING
    // rateLimit(30, 15 * 60 * 1000), // DISABLED FOR MVP TESTING
    async (req, res) => {
        console.log('🔍 [DEBUG] generate_flirts endpoint hit - code version a2ddf7e');
        try {
            // MVP: Use test user when auth is disabled
            if (!req.user) {
                req.user = { id: 'test-user-mvp-' + Date.now() };
            }

            const {
                screenshot_id,
                image_data,  // NEW: Base64 encoded image for direct Grok vision analysis
                context = '',
                suggestion_type = 'opener', // 'opener', 'response', 'continuation'
                tone = 'playful', // 'playful', 'witty', 'romantic', 'casual', 'bold'
                user_preferences = {}
            } = req.body;

            // Support both modes: new (image_data) and legacy (screenshot_id)
            if (!screenshot_id && !image_data) {
                return sendErrorResponse(
                    res,
                    400,
                    errorCodes.VALIDATION_ERROR,
                    'Either screenshot_id or image_data is required'
                );
            }

            // Validate screenshot_id if provided
            if (screenshot_id) {
                const screenshotIdValidation = validateScreenshotId(screenshot_id);
                if (!screenshotIdValidation.valid) {
                    return sendErrorResponse(
                        res,
                        400,
                        errorCodes.VALIDATION_ERROR,
                        screenshotIdValidation.error
                    );
                }
            }

            // Validate suggestion_type
            const suggestionTypeValidation = validateSuggestionType(suggestion_type);
            if (!suggestionTypeValidation.valid) {
                return sendErrorResponse(
                    res,
                    400,
                    errorCodes.VALIDATION_ERROR,
                    suggestionTypeValidation.error
                );
            }

            // Validate tone
            const toneValidation = validateTone(tone);
            if (!toneValidation.valid) {
                return sendErrorResponse(
                    res,
                    400,
                    errorCodes.VALIDATION_ERROR,
                    toneValidation.error
                );
            }

            // Sanitize context text input
            const sanitizedContext = sanitizeText(context);

            // Get screenshot analysis (if database is available)
            let screenshot = { analysis_result: { test: 'mock_analysis_for_testing' } };

            // MVP: Skip database ownership check entirely when screenshot_id is provided
            if (screenshot_id) {
                console.log('[MVP] Skipping database ownership check for screenshot_id:', screenshot_id);
                // Use mock data for MVP testing
            }

            // Check cache first (if Redis is available)
            let cachedSuggestions = null;
            if (redis) {
                try {
                    const cacheKey = `flirts:${screenshot_id}:${suggestion_type}:${tone}:${JSON.stringify(user_preferences)}`;
                    cachedSuggestions = await redis.get(cacheKey);

                    if (cachedSuggestions) {
                        console.log('Returning cached flirt suggestions');
                        return res.json({
                            success: true,
                            data: JSON.parse(cachedSuggestions),
                            cached: true,
                            message: 'Flirt suggestions generated successfully (cached)'
                        });
                    }
                } catch (cacheError) {
                    console.warn('Cache retrieval failed:', cacheError.message);
                }
            }

            // Prepare context for Grok API
            const analysisData = screenshot.analysis_result || {};
            const userContext = {
                suggestion_type,
                tone,
                context: sanitizedContext,
                user_preferences,
                analysis: analysisData
            };

            // Create personalized prompt based on analysis and preferences
            const prompt = `You are Flirrt.ai, an expert dating conversation assistant. Based on the following analysis and context, generate 5 highly personalized and engaging flirt suggestions.

SCREENSHOT ANALYSIS:
${JSON.stringify(analysisData, null, 2)}

REQUEST DETAILS:
- Type: ${suggestion_type}
- Tone: ${tone}
- Additional Context: ${sanitizedContext}
- User Preferences: ${JSON.stringify(user_preferences, null, 2)}

INSTRUCTIONS:
1. Generate exactly 5 ${suggestion_type} suggestions
2. Use ${tone} tone throughout
3. Make suggestions highly specific to the analyzed profile/conversation
4. Each suggestion should be 1-3 sentences maximum
5. Avoid generic pickup lines - be creative and personalized
6. Consider the user's preferences and the analyzed context
7. Make suggestions that are likely to get a positive response

Return ONLY a JSON object with this exact structure:
{
    "suggestions": [
        {
            "text": "suggestion text here",
            "confidence": 0.85,
            "reasoning": "why this suggestion works"
        }
    ],
    "metadata": {
        "suggestion_type": "${suggestion_type}",
        "tone": "${tone}",
        "generated_at": "ISO_timestamp"
    }
}`;

            // Make REAL API call to Grok
            const grokApiUrl = `${process.env.GROK_API_URL}/chat/completions`;

            console.log('Making request to Grok API for flirt generation...');

            // NEW: Grok Vision Mode (analyze image + generate flirts in one call)
            let grokRequestBody;
            if (image_data) {
                console.log('Using grok-2-vision-1212 VISION mode (image analysis + flirt generation)');
                grokRequestBody = {
                    model: "grok-2-vision-1212",
                    messages: [
                        {
                            role: "system",
                            content: "You are Flirrt.ai, an expert dating profile analyst and conversation coach. You intelligently analyze dating app screenshots, extract visual and text details, assess profile quality, and generate personalized conversation starters. You handle multiple languages (English, Hebrew, etc.). You MUST respond with valid JSON only."
                        },
                        {
                            role: "user",
                            content: [
                                {
                                    type: "text",
                                    text: `CRITICAL: You MUST respond with a JSON object containing ALL required fields. DO NOT omit any fields.

ANALYZE THIS DATING APP SCREENSHOT WITH INTELLIGENCE:

STEP 1 - Screenshot Type Detection (REQUIRED):
You MUST set "screenshot_type" to one of:
- "profile": Dating app profile with photos, bio, interests, age, name
- "chat": Message conversation between users

STEP 2 - Content Extraction (Extract ALL visible text in ANY language):
For PROFILES, extract:
- Bio text (Hebrew, English, or any language)
- Name, age, location if visible
- Interests/hobbies (from tags or UI elements)
- Visual elements: photos show (activities, pets, tattoos, style, locations)
- UI elements: interest buttons, hobby icons, prompts

For CHAT, extract:
- Conversation context and tone
- Last message content
- Username/contact name

STEP 3 - Profile Quality Scoring (REQUIRED - You MUST set "profile_score"):
Calculate a score from 1-10:
1-3: Minimal (only 1 photo, no bio text)
4-6: Basic (has photos but limited bio or interests)
7-10: Rich (multiple photos + detailed bio + interests/hobbies visible)

IMPORTANT: Every profile MUST have a profile_score. Even if it's a chat, set profile_score to 0.

STEP 4 - Decision Logic (REQUIRED - You MUST set "needs_more_scrolling"):
IF profile_score < 6:
  → Set needs_more_scrolling: true
  → Explain what's missing (bio, interests, more photos)
  → Return empty suggestions array

IF profile_score >= 6:
  → Set needs_more_scrolling: false
  → Generate 5 personalized ${suggestion_type} with ${tone} tone
  → Each MUST reference specific extracted details

IF screenshot_type is CHAT:
  IF extracted_details contains chat messages (chat_context with actual messages):
    → Set needs_more_scrolling: false
    → Set has_conversation: true
    → Generate 5 conversation continuation responses based on last message
    → Reference conversation context and tone
  ELSE (empty chat or no messages visible):
    → Set needs_more_scrolling: true
    → Set has_conversation: false
    → Message: "This is a chat conversation. Please screenshot the person's profile instead for better openers."

STEP 5 - Response Format with FEW-SHOT EXAMPLES:

EXAMPLE 1 (Complete Profile - Clarinha):
{
  "screenshot_type": "profile",
  "needs_more_scrolling": false,
  "profile_score": 8,
  "message_to_user": "✅ Great profile! Found plenty of details.",
  "extracted_details": {
    "bio_text": "I'm looking for friends because im moving. I love cats and gym!",
    "name": "Clarinha",
    "age": "24",
    "interests": ["cats", "gym", "making friends", "relocating"],
    "visual_elements": ["black dress", "mirror selfie", "home setting", "elegant style"],
    "key_hooks": ["cat lover", "fitness enthusiast", "new to area", "social"]
  },
  "suggestions": [
    {
      "text": "New in town and already hitting the gym? I need that kind of motivation! Does your cat have a workout routine too? 🐱💪",
      "confidence": 0.93,
      "reasoning": "Playfully combines moving + gym + cats in one opener, shows attention to profile",
      "references": ["moving", "gym", "cats"]
    },
    {
      "text": "Looking for friends AND a gym buddy? I volunteer as tribute! Though I should warn you, I might spend more time playing with your cat than actually working out 😅",
      "confidence": 0.88,
      "reasoning": "References both interests, adds humor, creates conversation opportunity",
      "references": ["friends", "gym", "cats"]
    },
    {
      "text": "So when you said you love cats and gym, do you bring your cat to the gym or does the cat critique your form from home? 🏋️",
      "confidence": 0.85,
      "reasoning": "Humorous question based on both interests, easy to respond to",
      "references": ["cats", "gym"]
    },
    {
      "text": "Moving to a new place is the perfect excuse to explore! Any chance your cat is also your gym spotter? That would be impressive 🐈",
      "confidence": 0.82,
      "reasoning": "Ties together relocation and both hobbies in playful way",
      "references": ["moving", "cats", "gym"]
    },
    {
      "text": "I'm convinced cat people who love the gym have it all figured out - balance of cuddles and gains! What's your cat's name?",
      "confidence": 0.87,
      "reasoning": "Validates her interests, opens conversation with specific question",
      "references": ["cats", "gym"]
    }
  ]
}

EXAMPLE 2 (Incomplete Profile):
{
  "screenshot_type": "profile",
  "needs_more_scrolling": true,
  "profile_score": 4,
  "message_to_user": "📸 I can see photos but no bio text or interests. Please scroll down to show more of the profile (bio, interests, hobbies) and take another screenshot for personalized suggestions.",
  "extracted_details": {
    "bio_text": "",
    "interests": [],
    "visual_elements": ["outdoor photo", "casual style"],
    "key_hooks": []
  },
  "suggestions": []
}

EXAMPLE 3 (Empty Chat - No Conversation):
{
  "screenshot_type": "chat",
  "needs_more_scrolling": true,
  "has_conversation": false,
  "profile_score": 0,
  "message_to_user": "📱 This is a chat conversation, not a profile. Please screenshot the person's dating profile instead for better openers.",
  "extracted_details": {
    "chat_context": "Empty Instagram direct message conversation",
    "usernames": ["alegra", "alegrazuili"]
  },
  "suggestions": []
}

EXAMPLE 4 (Active Chat - Conversation Continuation):
{
  "screenshot_type": "chat",
  "needs_more_scrolling": false,
  "has_conversation": true,
  "profile_score": 0,
  "message_to_user": "💬 Great! I can see the conversation. Here are some ways to continue:",
  "extracted_details": {
    "chat_context": "Active Instagram conversation about weekend plans",
    "last_message_from_them": "I'm thinking about trying that new sushi place this weekend",
    "conversation_tone": "casual and friendly",
    "usernames": ["sarah_92", "you"]
  },
  "suggestions": [
    {
      "text": "Ooh I've been wanting to try that place too! Are you going Saturday or Sunday?",
      "confidence": 0.92,
      "reasoning": "Shows shared interest, asks specific question to continue conversation naturally",
      "references": ["sushi place", "weekend"]
    },
    {
      "text": "I heard their spicy tuna rolls are amazing! Do you usually go for the adventurous rolls or stick with classics?",
      "confidence": 0.89,
      "reasoning": "Demonstrates knowledge, creates opportunity to learn their preferences",
      "references": ["sushi place"]
    },
    {
      "text": "That sounds perfect! I know a great spot nearby for dessert after if you're interested 😊",
      "confidence": 0.87,
      "reasoning": "Builds on their plan, subtly suggests extending the time together",
      "references": ["weekend plans"]
    },
    {
      "text": "Nice choice! Are you a sake person or do you prefer to stick with the rolls and sashimi?",
      "confidence": 0.85,
      "reasoning": "Keeps focus on their interest, opens discussion about preferences",
      "references": ["sushi"]
    },
    {
      "text": "Love that idea! Let me know if you want company - I make an excellent sushi companion 🍣",
      "confidence": 0.90,
      "reasoning": "Playful, shows interest in joining, uses emoji to match casual tone",
      "references": ["sushi place", "weekend"]
    }
  ]
}

Now analyze the provided screenshot and return JSON in this EXACT format with proper intelligence.`
                                },
                                {
                                    type: "image_url",
                                    image_url: {
                                        url: `data:image/jpeg;base64,${image_data}`,
                                        detail: "high"
                                    }
                                }
                            ]
                        }
                    ],
                    max_tokens: 3000,
                    temperature: 0.9,
                    response_format: { type: "json_object" }
                };
            } else {
                // LEGACY: Text-only mode (existing logic)
                console.log('Using grok-2-vision-1212 TEXT mode (pre-analyzed screenshot)');
                grokRequestBody = {
                    model: "grok-2-vision-1212",
                    messages: [
                        {
                            role: "system",
                            content: "You are Flirrt.ai, an expert dating conversation assistant. You create personalized, engaging, and contextually appropriate flirt suggestions. Always respond with valid JSON only."
                        },
                        {
                            role: "user",
                            content: prompt
                        }
                    ],
                    max_tokens: 1500,
                    temperature: 0.8,
                    response_format: { type: "json_object" }
                };
            }

            // Call Grok API with retry logic (3 attempts with exponential backoff)
            const grokData = await callGrokWithRetry(
                axios,
                grokApiUrl,
                grokRequestBody,
                {
                    'Authorization': `Bearer ${process.env.GROK_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                timeouts.api.geminiVisionFlirts,
                3 // max retries
            );

            if (!grokData || !grokData.choices || !grokData.choices[0]) {
                throw new Error('Invalid response from Grok API');
            }

            const responseText = grokData.choices[0].message.content;

            // Optional debug logging (enable with DEBUG_GROK_RESPONSES=true)
            if (process.env.DEBUG_GROK_RESPONSES === 'true') {
                console.log('\n' + '='.repeat(80));
                console.log('📊 GROK API RESPONSE ANALYSIS');
                console.log('='.repeat(80));
                console.log('Response length:', responseText.length, 'chars');
                console.log('Model:', grokData.model);
                console.log('Tokens used:', JSON.stringify(grokData.usage || 'N/A'));
                console.log('Finish reason:', grokData.choices[0].finish_reason);
                console.log('\n📝 RAW RESPONSE CONTENT:');
                console.log(responseText.substring(0, 500) + (responseText.length > 500 ? '...' : ''));
                console.log('='.repeat(80) + '\n');
            }

            // Parse JSON response
            let suggestions;
            try {
                suggestions = JSON.parse(responseText);
            } catch (parseError) {
                console.error('❌ Failed to parse Grok response as JSON:', parseError);
                if (process.env.DEBUG_GROK_RESPONSES === 'true') {
                    console.error('Raw response:', responseText);
                }
                throw new Error('Invalid JSON response from Grok API');
            }

            // Validate response structure (handle both old and new formats)
            const parsedData = suggestions;

            // Optional field validation logging
            if (process.env.DEBUG_GROK_RESPONSES === 'true') {
                console.log('🔍 FIELD VALIDATION:');
                const requiredFields = ['screenshot_type', 'needs_more_scrolling', 'profile_score', 'extracted_details', 'suggestions'];
                const missingFields = requiredFields.filter(field => parsedData[field] === undefined);
                const presentFields = requiredFields.filter(field => parsedData[field] !== undefined);

                console.log('✅ Present fields:', presentFields.join(', '));
                if (missingFields.length > 0) {
                    console.log('❌ Missing fields:', missingFields.join(', '));
                }

                // Validate suggestion structure
                if (parsedData.suggestions && Array.isArray(parsedData.suggestions)) {
                    console.log(`📋 Suggestions count: ${parsedData.suggestions.length}`);
                    parsedData.suggestions.forEach((s, i) => {
                        const hasReasoning = s.reasoning !== undefined;
                        const hasReferences = s.references !== undefined;
                        const hasConfidence = s.confidence !== undefined;
                        console.log(`  Suggestion ${i+1}: confidence=${hasConfidence ? '✓' : '✗'} reasoning=${hasReasoning ? '✓' : '✗'} references=${hasReferences ? '✓' : '✗'}`);
                    });
                }
                console.log('='.repeat(80) + '\n');
            }

            // NEW: Handle intelligent response format with needs_more_scrolling
            if (parsedData.needs_more_scrolling !== undefined) {
                // New intelligent format
                console.log(`Intelligent analysis: screenshot_type=${parsedData.screenshot_type}, score=${parsedData.profile_score}, needs_more=${parsedData.needs_more_scrolling}, has_conversation=${parsedData.has_conversation || false}`);

                // If needs more scrolling, return early with message
                if (parsedData.needs_more_scrolling) {
                    return res.status(httpStatus.OK).json({
                        success: true,
                        screenshot_type: parsedData.screenshot_type,
                        needs_more_scrolling: true,
                        has_conversation: parsedData.has_conversation || false,
                        profile_score: parsedData.profile_score,
                        message_to_user: parsedData.message_to_user || 'Please provide more profile information',
                        extracted_details: parsedData.extracted_details || {},
                        suggestions: []
                    });
                }
            }

            // Validate suggestions array exists
            if (!parsedData.suggestions || !Array.isArray(parsedData.suggestions)) {
                throw new Error('Invalid suggestions format from Grok API');
            }

            // Save suggestions to database (if database is available)
            const savedSuggestions = [];
            for (const suggestion of parsedData.suggestions) {
                let suggestionId = 'test-suggestion-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
                let createdAt = new Date().toISOString();

                try {
                    const insertQuery = `
                        INSERT INTO flirt_suggestions (screenshot_id, user_id, suggestion_text, confidence_score, suggestion_type, context)
                        VALUES ($1, $2, $3, $4, $5, $6)
                        RETURNING id, created_at
                    `;

                    const suggestionResult = await pool.query(insertQuery, [
                        screenshot_id,
                        req.user.id,
                        suggestion.text,
                        suggestion.confidence || 0.7,
                        suggestion_type,
                        JSON.stringify({
                            tone,
                            reasoning: suggestion.reasoning,
                            user_preferences,
                            original_context: context
                        })
                    ]);

                    suggestionId = suggestionResult.rows[0].id;
                    createdAt = suggestionResult.rows[0].created_at;
                } catch (dbError) {
                    console.warn('Database insert failed, using mock ID:', dbError.message);
                }

                savedSuggestions.push({
                    id: suggestionId,
                    text: suggestion.text,
                    tone: tone,  // Add tone field for iOS keyboard compatibility
                    confidence: suggestion.confidence || 0.7,
                    reasoning: suggestion.reasoning,
                    created_at: createdAt
                });
            }

            // Prepare response data (include new intelligent fields)
            const responseData = {
                success: true,
                screenshot_type: parsedData.screenshot_type || 'profile',
                needs_more_scrolling: parsedData.needs_more_scrolling || false,
                has_conversation: parsedData.has_conversation || false,
                profile_score: parsedData.profile_score,
                message_to_user: parsedData.message_to_user,
                extracted_details: parsedData.extracted_details || {},
                suggestions: savedSuggestions,
                metadata: {
                    suggestion_type,
                    tone,
                    screenshot_id,
                    total_suggestions: savedSuggestions.length,
                    generated_at: new Date().toISOString()
                }
            };

            // Cache results (if Redis is available)
            if (redis) {
                try {
                    const cacheKey = `flirts:${screenshot_id}:${suggestion_type}:${tone}:${JSON.stringify(user_preferences)}`;
                    await redis.setex(cacheKey, cache.tiers.warm.ttl / 1000, JSON.stringify(responseData));
                } catch (cacheError) {
                    console.warn('Cache storage failed:', cacheError.message);
                }
            }

            // Log analytics event (if database is available)
            try {
                await pool.query(
                    `INSERT INTO analytics (user_id, event_type, event_data)
                     VALUES ($1, $2, $3)`,
                    [req.user.id, 'flirts_generated', {
                        screenshot_id,
                        suggestion_type,
                        tone,
                        suggestions_count: savedSuggestions.length,
                        avg_confidence: savedSuggestions.reduce((acc, s) => acc + s.confidence, 0) / savedSuggestions.length
                    }]
                );
            } catch (dbError) {
                console.warn('Analytics logging failed:', dbError.message);
            }

            res.json({
                success: true,
                data: responseData,
                cached: false,
                message: 'Flirt suggestions generated successfully'
            });

        } catch (error) {
            // Log error with full context
            logError('generate_flirts', error, {
                screenshot_id: req.body.screenshot_id || null,
                suggestion_type: req.body.suggestion_type || null,
                tone: req.body.tone || null,
                user_id: req.user?.id,
                has_image_data: !!req.body.image_data
            });

            // Use centralized error handler for consistent responses
            return handleError(error, res, 'generate_flirts', req.id);
        }
    }
);

/**
 * Get User's Flirt History
 * GET /api/v1/flirts/history
 */
router.get('/history', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 20, suggestion_type, screenshot_id } = req.query;
        const offset = (page - 1) * limit;

        // Validate suggestion_type if provided
        if (suggestion_type) {
            const suggestionTypeValidation = validateSuggestionType(suggestion_type);
            if (!suggestionTypeValidation.valid) {
                return sendErrorResponse(
                    res,
                    400,
                    errorCodes.VALIDATION_ERROR,
                    suggestionTypeValidation.error
                );
            }
        }

        // Validate screenshot_id if provided
        if (screenshot_id) {
            const screenshotIdValidation = validateScreenshotId(screenshot_id);
            if (!screenshotIdValidation.valid) {
                return sendErrorResponse(
                    res,
                    400,
                    errorCodes.VALIDATION_ERROR,
                    screenshotIdValidation.error
                );
            }
        }

        let whereClause = 'WHERE fs.user_id = $1';
        let queryParams = [req.user.id];

        if (suggestion_type) {
            whereClause += ' AND fs.suggestion_type = $' + (queryParams.length + 1);
            queryParams.push(suggestion_type);
        }

        if (screenshot_id) {
            whereClause += ' AND fs.screenshot_id = $' + (queryParams.length + 1);
            queryParams.push(screenshot_id);
        }

        const historyQuery = `
            SELECT fs.*, s.filename as screenshot_filename
            FROM flirt_suggestions fs
            LEFT JOIN screenshots s ON fs.screenshot_id = s.id
            ${whereClause}
            ORDER BY fs.created_at DESC
            LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
        `;

        const countQuery = `
            SELECT COUNT(*) as total
            FROM flirt_suggestions fs
            ${whereClause}
        `;

        queryParams.push(limit, offset);

        const [historyResult, countResult] = await Promise.all([
            pool.query(historyQuery, queryParams),
            pool.query(countQuery, queryParams.slice(0, -2)) // Remove limit and offset for count
        ]);

        const suggestions = historyResult.rows;
        const total = parseInt(countResult.rows[0].total);

        res.json({
            success: true,
            data: {
                suggestions,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        logError('get_flirt_history', error, {
            user_id: req.user?.id,
            page: req.query.page,
            limit: req.query.limit
        });
        return handleError(error, res, 'get_flirt_history', req.id);
    }
});

/**
 * Rate a Flirt Suggestion
 * POST /api/v1/flirts/:suggestionId/rate
 */
router.post('/:suggestionId/rate', authenticateToken, async (req, res) => {
    try {
        const { suggestionId } = req.params;
        const { rating, feedback } = req.body;

        // Sanitize feedback text input if provided
        const sanitizedFeedback = feedback ? sanitizeText(feedback) : null;

        if (!rating || rating < validation.range.rating.min || rating > validation.range.rating.max) {
            return res.status(httpStatus.BAD_REQUEST).json({
                success: false,
                error: `Rating must be between ${validation.range.rating.min} and ${validation.range.rating.max}`,
                code: errors.VALIDATION_ERROR.code
            });
        }

        // Check if suggestion belongs to user
        const suggestionQuery = `
            SELECT user_id FROM flirt_suggestions WHERE id = $1
        `;

        const suggestionResult = await pool.query(suggestionQuery, [suggestionId]);

        if (suggestionResult.rows.length === 0) {
            return res.status(httpStatus.NOT_FOUND).json({
                success: false,
                error: errors.FLIRT_NOT_FOUND.message,
                code: errors.FLIRT_NOT_FOUND.code
            });
        }

        if (suggestionResult.rows[0].user_id !== req.user.id) {
            return res.status(httpStatus.FORBIDDEN).json({
                success: false,
                error: errors.ACCESS_DENIED.message,
                code: errors.ACCESS_DENIED.code
            });
        }

        // Update rating
        await pool.query(
            `UPDATE flirt_suggestions
             SET rating = $1, used_at = CASE WHEN used_at IS NULL THEN NOW() ELSE used_at END
             WHERE id = $2`,
            [rating, suggestionId]
        );

        // Log analytics event
        await pool.query(
            `INSERT INTO analytics (user_id, event_type, event_data)
             VALUES ($1, $2, $3)`,
            [req.user.id, 'suggestion_rated', {
                suggestion_id: suggestionId,
                rating,
                feedback: sanitizedFeedback
            }]
        );

        res.json({
            success: true,
            message: 'Rating saved successfully'
        });

    } catch (error) {
        logError('rate_suggestion', error, {
            user_id: req.user?.id,
            suggestion_id: req.params.suggestionId,
            rating: req.body.rating
        });
        return handleError(error, res, 'rate_suggestion', req.id);
    }
});

/**
 * Mark Suggestion as Used
 * POST /api/v1/flirts/:suggestionId/used
 */
router.post('/:suggestionId/used', authenticateToken, async (req, res) => {
    try {
        const { suggestionId } = req.params;

        // Check if suggestion belongs to user
        const suggestionQuery = `
            SELECT user_id FROM flirt_suggestions WHERE id = $1
        `;

        const suggestionResult = await pool.query(suggestionQuery, [suggestionId]);

        if (suggestionResult.rows.length === 0) {
            return res.status(httpStatus.NOT_FOUND).json({
                success: false,
                error: errors.FLIRT_NOT_FOUND.message,
                code: errors.FLIRT_NOT_FOUND.code
            });
        }

        if (suggestionResult.rows[0].user_id !== req.user.id) {
            return res.status(httpStatus.FORBIDDEN).json({
                success: false,
                error: errors.ACCESS_DENIED.message,
                code: errors.ACCESS_DENIED.code
            });
        }

        // Mark as used
        await pool.query(
            'UPDATE flirt_suggestions SET used_at = NOW() WHERE id = $1',
            [suggestionId]
        );

        // Log analytics event
        await pool.query(
            `INSERT INTO analytics (user_id, event_type, event_data)
             VALUES ($1, $2, $3)`,
            [req.user.id, 'suggestion_used', { suggestion_id: suggestionId }]
        );

        res.json({
            success: true,
            message: 'Suggestion marked as used'
        });

    } catch (error) {
        logError('mark_suggestion_used', error, {
            user_id: req.user?.id,
            suggestion_id: req.params.suggestionId
        });
        return handleError(error, res, 'mark_suggestion_used', req.id);
    }
});

/**
 * Delete Suggestion
 * DELETE /api/v1/flirts/:suggestionId
 */
router.delete('/:suggestionId', authenticateToken, async (req, res) => {
    try {
        const { suggestionId } = req.params;

        // Check if suggestion belongs to user and delete
        const deleteResult = await pool.query(
            'DELETE FROM flirt_suggestions WHERE id = $1 AND user_id = $2',
            [suggestionId, req.user.id]
        );

        if (deleteResult.rowCount === 0) {
            return res.status(httpStatus.NOT_FOUND).json({
                success: false,
                error: errors.FLIRT_NOT_FOUND.message,
                code: errors.FLIRT_NOT_FOUND.code
            });
        }

        res.json({
            success: true,
            message: 'Suggestion deleted successfully'
        });

    } catch (error) {
        logError('delete_suggestion', error, {
            user_id: req.user?.id,
            suggestion_id: req.params.suggestionId
        });
        return handleError(error, res, 'delete_suggestion', req.id);
    }
});

module.exports = router;