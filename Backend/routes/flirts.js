const express = require('express');
const router = express.Router();
const aiOrchestrator = require('../services/aiOrchestrator');
const moderationService = require('../services/moderation');
const { logger } = require('../services/logger');

/**
 * POST /api/flirts
 * Generate flirt suggestions from screenshot(s)
 * 
 * Body:
 * - images: Array of base64 images (max 3)
 * - context: "profile" or "chat"
 * - previousSuggestions: Array of strings (for refresh)
 * - userPreferences: { tone, spiciness, style }
 */
router.post('/', async (req, res) => {
    try {
        const { images, context, previousSuggestions, userPreferences } = req.body;

        // Validation
        if (!images || !Array.isArray(images) || images.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'At least one image is required'
            });
        }

        if (images.length > 3) {
            return res.status(400).json({
                success: false,
                error: 'Maximum 3 images allowed'
            });
        }

        logger.info('Flirt generation request', {
            imageCount: images.length,
            context,
            hasPreferences: !!userPreferences,
            isRefresh: !!(previousSuggestions && previousSuggestions.length > 0)
        });

        // Generate flirts
        const result = await aiOrchestrator.generateFlirts({
            images,
            context,
            previousSuggestions,
            userPreferences
        });

        // Content moderation
        const moderationResults = await Promise.all(
            result.suggestions.map(s => moderationService.moderateText(s.message))
        );

        const flagged = moderationResults.some(r => r.flagged);

        if (flagged) {
            logger.warn('Content moderation flagged suggestions', {
                flaggedCount: moderationResults.filter(r => r.flagged).length
            });
        }

        res.json({
            success: true,
            suggestions: result.suggestions,
            reasoning: result.reasoning,
            metadata: result.metadata,
            moderation: {
                flagged,
                results: moderationResults
            }
        });

    } catch (error) {
        logger.error('Flirt generation failed', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to generate flirts',
            message: error.message
        });
    }
});

module.exports = router;
