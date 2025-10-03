const express = require('express');
const { Pool } = require('pg');
const axios = require('axios');
const Redis = require('ioredis');
const { authenticateToken, rateLimit } = require('../middleware/auth');

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
        retryDelayOnFailover: 100,
        maxRetriesPerRequest: 3,
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
 */
router.post('/generate_flirts',
    authenticateToken,
    rateLimit(30, 15 * 60 * 1000), // 30 requests per 15 minutes
    async (req, res) => {
        try {
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
                return res.status(400).json({
                    success: false,
                    error: 'Either screenshot_id or image_data is required',
                    code: 'MISSING_REQUIRED_FIELD'
                });
            }

            // Get screenshot analysis (if database is available)
            let screenshot = { analysis_result: { test: 'mock_analysis_for_testing' } };
            try {
                const screenshotQuery = `
                    SELECT s.*, u.id as owner_id
                    FROM screenshots s
                    JOIN users u ON s.user_id = u.id
                    WHERE s.id = $1 AND s.analysis_status = 'completed'
                `;

                const screenshotResult = await pool.query(screenshotQuery, [screenshot_id]);

                if (screenshotResult.rows.length === 0) {
                    console.warn('Screenshot not found in database, using mock data for testing');
                } else {
                    screenshot = screenshotResult.rows[0];

                    // Check if user owns this screenshot
                    if (screenshot.owner_id !== req.user.id) {
                        return res.status(403).json({
                            success: false,
                            error: 'Access denied',
                            code: 'ACCESS_DENIED'
                        });
                    }
                }
            } catch (dbError) {
                console.warn('Database query failed, using mock data for testing:', dbError.message);
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
                context,
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
- Additional Context: ${context}
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

            // NEW: Grok-4-latest Vision Mode (analyze image + generate flirts in one call)
            let grokRequestBody;
            if (image_data) {
                console.log('Using Grok-4-latest VISION mode (image analysis + flirt generation)');
                grokRequestBody = {
                    model: "grok-4-latest",
                    messages: [
                        {
                            role: "system",
                            content: "You are Flirrt.ai, a witty dating coach who analyzes dating app profiles and creates personalized conversation starters. Your flirts are clever, respectful, and reference specific details from the profile. Always respond with valid JSON only."
                        },
                        {
                            role: "user",
                            content: [
                                {
                                    type: "text",
                                    text: `Analyze this dating app screenshot and generate 5 creative ${suggestion_type} suggestions with ${tone} tone. Each should reference something specific you see in the image.

Return ONLY a JSON object with this structure:
{
    "suggestions": [
        {
            "text": "the flirt text",
            "confidence": 0.85,
            "reasoning": "why this works"
        }
    ],
    "metadata": {
        "suggestion_type": "${suggestion_type}",
        "tone": "${tone}",
        "generated_at": "ISO_timestamp"
    }
}`
                                },
                                {
                                    type: "image_url",
                                    image_url: {
                                        url: `data:image/jpeg;base64,${image_data}`
                                    }
                                }
                            ]
                        }
                    ],
                    max_tokens: 2000,
                    temperature: 0.9,
                    response_format: { type: "json_object" }
                };
            } else {
                // LEGACY: Text-only mode (existing logic)
                console.log('Using Grok-4-latest TEXT mode (pre-analyzed screenshot)');
                grokRequestBody = {
                    model: "grok-4-latest",
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

            const grokResponse = await axios.post(grokApiUrl, grokRequestBody, {
                headers: {
                    'Authorization': `Bearer ${process.env.GROK_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                timeout: 45000 // 45 second timeout for vision processing
            });

            if (!grokResponse.data || !grokResponse.data.choices || !grokResponse.data.choices[0]) {
                throw new Error('Invalid response from Grok API');
            }

            const responseText = grokResponse.data.choices[0].message.content;

            // Parse JSON response
            let suggestions;
            try {
                suggestions = JSON.parse(responseText);
            } catch (parseError) {
                console.error('Failed to parse Grok response as JSON:', parseError);
                throw new Error('Invalid JSON response from Grok API');
            }

            // Validate response structure
            if (!suggestions.suggestions || !Array.isArray(suggestions.suggestions)) {
                throw new Error('Invalid suggestions format from Grok API');
            }

            // Save suggestions to database (if database is available)
            const savedSuggestions = [];
            for (const suggestion of suggestions.suggestions) {
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

            // Prepare response data
            const responseData = {
                suggestions: savedSuggestions,
                metadata: {
                    suggestion_type,
                    tone,
                    screenshot_id,
                    total_suggestions: savedSuggestions.length,
                    generated_at: new Date().toISOString()
                }
            };

            // Cache results for 1 hour (if Redis is available)
            if (redis) {
                try {
                    const cacheKey = `flirts:${screenshot_id}:${suggestion_type}:${tone}:${JSON.stringify(user_preferences)}`;
                    await redis.setex(cacheKey, 3600, JSON.stringify(responseData));
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
            console.error('Flirt generation error:', error);
            console.warn('⚠️  Grok API failed - Using mock suggestions for testing');

            // FALLBACK: Return mock suggestions when Grok API fails
            // This allows testing keyboard UI without working API
            const requestBody = req.body || {};
            const fallbackTone = requestBody.tone || 'playful';
            const fallbackScreenshotId = requestBody.screenshot_id || 'mock-screenshot';
            const fallbackSuggestionType = requestBody.suggestion_type || 'opener';

            const mockSuggestions = [
                {
                    id: 'mock-1-' + Date.now(),
                    text: "So what's your story? Besides being absolutely captivating, I mean 😏",
                    confidence: 0.85,
                    tone: fallbackTone
                },
                {
                    id: 'mock-2-' + Date.now(),
                    text: "I have a feeling you're the type who makes bad decisions look incredibly appealing",
                    confidence: 0.78,
                    tone: fallbackTone
                },
                {
                    id: 'mock-3-' + Date.now(),
                    text: "Quick question: on a scale of 1-10, how good are you at ignoring red flags? Asking for a friend 😅",
                    confidence: 0.72,
                    tone: fallbackTone
                }
            ];

            return res.json({
                success: true,
                suggestions: mockSuggestions,
                metadata: {
                    suggestion_type: fallbackSuggestionType,
                    tone: fallbackTone,
                    screenshot_id: fallbackScreenshotId,
                    total_suggestions: mockSuggestions.length,
                    generated_at: new Date().toISOString(),
                    mock: true,
                    mock_reason: 'Grok API unavailable'
                },
                cached: false,
                message: 'Mock flirt suggestions (API unavailable)'
            });
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
        console.error('Get flirt history error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get flirt history',
            code: 'GET_HISTORY_ERROR'
        });
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

        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({
                success: false,
                error: 'Rating must be between 1 and 5',
                code: 'INVALID_RATING'
            });
        }

        // Check if suggestion belongs to user
        const suggestionQuery = `
            SELECT user_id FROM flirt_suggestions WHERE id = $1
        `;

        const suggestionResult = await pool.query(suggestionQuery, [suggestionId]);

        if (suggestionResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Suggestion not found',
                code: 'SUGGESTION_NOT_FOUND'
            });
        }

        if (suggestionResult.rows[0].user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Access denied',
                code: 'ACCESS_DENIED'
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
                feedback: feedback || null
            }]
        );

        res.json({
            success: true,
            message: 'Rating saved successfully'
        });

    } catch (error) {
        console.error('Rate suggestion error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to save rating',
            code: 'RATING_ERROR'
        });
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
            return res.status(404).json({
                success: false,
                error: 'Suggestion not found',
                code: 'SUGGESTION_NOT_FOUND'
            });
        }

        if (suggestionResult.rows[0].user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Access denied',
                code: 'ACCESS_DENIED'
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
        console.error('Mark used error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to mark suggestion as used',
            code: 'MARK_USED_ERROR'
        });
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
            return res.status(404).json({
                success: false,
                error: 'Suggestion not found',
                code: 'SUGGESTION_NOT_FOUND'
            });
        }

        res.json({
            success: true,
            message: 'Suggestion deleted successfully'
        });

    } catch (error) {
        console.error('Delete suggestion error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete suggestion',
            code: 'DELETE_ERROR'
        });
    }
});

module.exports = router;