/**
 * A/B Testing API Routes
 * 
 * Endpoints for client configuration and event tracking
 */

const express = require('express');
const router = express.Router();
const abTestingService = require('../services/abTestingService');
const db = require('../config/database');

/**
 * GET /api/abtesting/config
 * 
 * Get user configuration including experiment assignments
 * Client should call this on app launch and cache the result
 * 
 * Query params:
 * - userId: Anonymous user identifier (UUID)
 */
router.get('/config', async (req, res) => {
    try {
        const { userId } = req.query;

        if (!userId) {
            return res.status(400).json({
                success: false,
                error: 'userId is required'
            });
        }

        // Validate UUID format
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(userId)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid userId format (must be UUID)'
            });
        }

        // Get configuration (with graceful degradation if DB unavailable)
        const config = await abTestingService.getUserConfiguration(userId, db);

        res.json({
            success: true,
            userId,
            config,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error in /config endpoint:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get configuration',
            message: error.message
        });
    }
});

/**
 * POST /api/abtesting/event
 * 
 * Track a user event for analytics
 * 
 * Body:
 * - userId: User identifier
 * - eventName: Name of the event (e.g., 'suggestion_accepted')
 * - activeExperiments: Array of experiments user was exposed to
 * - metadata: Additional event data (optional)
 * - value: Numeric value (optional, e.g., latency in ms)
 */
router.post('/event', async (req, res) => {
    try {
        const { userId, eventName, activeExperiments = [], metadata = {}, value = null } = req.body;

        if (!userId || !eventName) {
            return res.status(400).json({
                success: false,
                error: 'userId and eventName are required'
            });
        }

        // Track the event
        const tracked = await abTestingService.trackEvent(
            userId,
            eventName,
            activeExperiments,
            metadata,
            value,
            db
        );

        res.json({
            success: tracked,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error in /event endpoint:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to track event',
            message: error.message
        });
    }
});

/**
 * GET /api/abtesting/stats/:experimentId
 * 
 * Get statistics for an experiment (admin only)
 * 
 * Params:
 * - experimentId: ID of the experiment
 */
router.get('/stats/:experimentId', async (req, res) => {
    try {
        const { experimentId } = req.params;

        if (!experimentId) {
            return res.status(400).json({
                success: false,
                error: 'experimentId is required'
            });
        }

        // Get experiment statistics
        const stats = await abTestingService.getExperimentStats(experimentId, db);

        if (stats.error) {
            return res.status(500).json({
                success: false,
                error: stats.error
            });
        }

        res.json({
            success: true,
            stats
        });
    } catch (error) {
        console.error('Error in /stats endpoint:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get statistics',
            message: error.message
        });
    }
});

module.exports = router;

