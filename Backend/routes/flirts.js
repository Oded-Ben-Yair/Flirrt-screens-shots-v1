const express = require('express');
const router = express.Router();
const aiOrchestrator = require('../services/aiOrchestrator');
const moderationService = require('../services/moderation');
const conversationContext = require('../services/conversationContext');
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
 * - userId: User ID (optional, for session tracking)
 * - conversationId: Conversation ID (optional, for multi-screenshot context)
 * - screenshotId: Screenshot ID (optional, for linking to session)
 */
router.post('/', async (req, res) => {
    try {
        const { images, context, previousSuggestions, userPreferences, userId, conversationId, screenshotId } = req.body;

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

        // Session management - Get or create conversation session
        let session = null;
        let needsMoreContext = false;

        if (userId && conversationId) {
            session = await conversationContext.getOrCreateSession(userId, conversationId);

            // Check if we need more screenshots for context
            needsMoreContext = checkIfNeedsMoreScreenshots(session);

            logger.info('Flirt generation request with session tracking', {
                imageCount: images.length,
                context,
                hasPreferences: !!userPreferences,
                isRefresh: !!(previousSuggestions && previousSuggestions.length > 0),
                sessionId: session.id,
                screenshotCount: session.screenshot_count,
                needsMoreContext
            });
        } else {
            logger.info('Flirt generation request (no session tracking)', {
                imageCount: images.length,
                context,
                hasPreferences: !!userPreferences,
                isRefresh: !!(previousSuggestions && previousSuggestions.length > 0)
            });
        }

        // Generate flirts with session context
        const result = await aiOrchestrator.generateFlirts({
            images,
            context,
            previousSuggestions,
            userPreferences,
            userId,
            conversationId,
            sessionId: session ? session.id : null,
            screenshotId
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

        // Build response with session metadata
        const response = {
            success: true,
            suggestions: result.suggestions,
            reasoning: result.reasoning,
            metadata: result.metadata,
            moderation: {
                flagged,
                results: moderationResults
            }
        };

        // Add session metadata if available
        if (session) {
            response.session = {
                sessionId: session.id,
                screenshotCount: session.screenshot_count + 1, // +1 for current screenshot
                needsMoreContext,
                contextMessage: needsMoreContext
                    ? generateContextRequestMessage(session.screenshot_count)
                    : null
            };
        }

        res.json(response);

    } catch (error) {
        logger.error('Flirt generation failed', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to generate flirts',
            message: error.message
        });
    }
});

/**
 * Helper: Check if we need more screenshots for context
 * @param {Object} session - Session object
 * @returns {boolean}
 */
function checkIfNeedsMoreScreenshots(session) {
    const screenshotCount = session.screenshot_count || 0;

    // Always request more for first screenshot
    if (screenshotCount === 0) {
        return true;
    }

    // Stop at 3+ screenshots (we have enough context)
    if (screenshotCount >= 2) {
        return false;
    }

    // For 1-2 screenshots, we might want more context
    return true;
}

/**
 * Helper: Generate context request message
 * @param {number} screenshotCount - Current screenshot count
 * @returns {string}
 */
function generateContextRequestMessage(screenshotCount) {
    if (screenshotCount === 0) {
        return "First screenshot received! For better suggestions, you can share 1-2 more screenshots by scrolling up in the conversation.";
    } else if (screenshotCount === 1) {
        return "Good! You can share one more screenshot for even better context-aware suggestions.";
    }
    return null;
}

module.exports = router;
