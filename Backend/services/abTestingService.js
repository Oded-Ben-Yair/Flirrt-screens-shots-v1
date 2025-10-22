/**
 * A/B Testing Service for Flirrt.AI
 * 
 * Implements a lightweight, privacy-compliant A/B testing framework
 * Based on expert recommendations from Gemini 2.5 Pro and Perplexity Sonar Pro
 * 
 * Architecture:
 * - Server-driven: Client receives configuration, doesn't contain testing logic
 * - Event-based tracking: All user interactions logged to events table
 * - Graceful degradation: Works without database (in-memory fallback)
 * - Privacy-first: Uses anonymous UUIDs, no PII storage
 * 
 * Future Enhancement: Integrate with GrowthBook for advanced analytics
 */

const crypto = require('crypto');

class ABTestingService {
    constructor() {
        // Define active experiments
        this.experiments = {
            'gamification_prompts': {
                id: 'exp_gamification_prompts',
                name: 'Gamification Prompt Styles',
                variants: [
                    { name: 'control', weight: 0.25, config: { promptStyle: 'direct' } },
                    { name: 'playful', weight: 0.25, config: { promptStyle: 'playful' } },
                    { name: 'mysterious', weight: 0.25, config: { promptStyle: 'mysterious' } },
                    { name: 'confident', weight: 0.25, config: { promptStyle: 'confident' } }
                ],
                enabled: true
            },
            'ai_model_selection': {
                id: 'exp_ai_model_selection',
                name: 'AI Model Combinations',
                variants: [
                    { name: 'gpt4o_only', weight: 0.33, config: { primaryModel: 'gpt-4o', fallback: 'grok-4' } },
                    { name: 'grok4_only', weight: 0.33, config: { primaryModel: 'grok-4', fallback: 'gpt-4o' } },
                    { name: 'hybrid', weight: 0.34, config: { primaryModel: 'gpt-4o', secondaryModel: 'grok-4' } }
                ],
                enabled: true
            },
            'suggestion_format': {
                id: 'exp_suggestion_format',
                name: 'Suggestion Formatting',
                variants: [
                    { name: 'standard', weight: 0.5, config: { format: 'standard', maxSuggestions: 5 } },
                    { name: 'concise', weight: 0.5, config: { format: 'concise', maxSuggestions: 3 } }
                ],
                enabled: true
            }
        };

        // In-memory cache for user assignments (fallback when DB unavailable)
        this.userAssignments = new Map();
    }

    /**
     * Get configuration for a user (assigns to variants if needed)
     * @param {string} userId - Anonymous user identifier (UUID)
     * @param {object} db - Database connection (optional, graceful degradation)
     * @returns {object} Configuration object with feature flags and experiment assignments
     */
    async getUserConfiguration(userId, db = null) {
        try {
            const config = {
                features: {},
                experiments: []
            };

            // Get or create assignments for each active experiment
            for (const [experimentKey, experiment] of Object.entries(this.experiments)) {
                if (!experiment.enabled) continue;

                let assignment;

                // Try to get existing assignment from database
                if (db) {
                    try {
                        const result = await db.query(
                            `SELECT variant_name, variant_config 
                             FROM user_experiment_assignments 
                             WHERE user_id = $1 AND experiment_id = $2`,
                            [userId, experiment.id]
                        );

                        if (result.rows.length > 0) {
                            assignment = {
                                variantName: result.rows[0].variant_name,
                                config: result.rows[0].variant_config
                            };
                        }
                    } catch (dbError) {
                        console.warn(`Database query failed for user ${userId}, using in-memory fallback:`, dbError.message);
                    }
                }

                // If no database assignment, check in-memory cache
                if (!assignment) {
                    const cacheKey = `${userId}:${experiment.id}`;
                    assignment = this.userAssignments.get(cacheKey);
                }

                // If still no assignment, create new one
                if (!assignment) {
                    assignment = this._assignVariant(userId, experiment);

                    // Store in database if available
                    if (db) {
                        try {
                            await db.query(
                                `INSERT INTO user_experiment_assignments 
                                 (user_id, experiment_id, variant_name, variant_config, assigned_at)
                                 VALUES ($1, $2, $3, $4, NOW())
                                 ON CONFLICT (user_id, experiment_id) DO NOTHING`,
                                [userId, experiment.id, assignment.variantName, JSON.stringify(assignment.config)]
                            );
                        } catch (dbError) {
                            console.warn(`Failed to store assignment in database:`, dbError.message);
                        }
                    }

                    // Always store in memory as backup
                    const cacheKey = `${userId}:${experiment.id}`;
                    this.userAssignments.set(cacheKey, assignment);
                }

                // Merge variant config into features
                Object.assign(config.features, assignment.config);

                // Add to experiments list for event tracking
                config.experiments.push({
                    experimentId: experiment.id,
                    experimentName: experiment.name,
                    variantName: assignment.variantName
                });
            }

            return config;
        } catch (error) {
            console.error('Error getting user configuration:', error);
            // Return default configuration on error
            return this._getDefaultConfiguration();
        }
    }

    /**
     * Assign a user to a variant using consistent hashing
     * @param {string} userId - User identifier
     * @param {object} experiment - Experiment configuration
     * @returns {object} Assignment with variantName and config
     */
    _assignVariant(userId, experiment) {
        // Use consistent hashing to ensure same user always gets same variant
        const hash = crypto
            .createHash('sha256')
            .update(`${userId}:${experiment.id}`)
            .digest('hex');

        // Convert first 8 chars of hash to number between 0 and 1
        const hashValue = parseInt(hash.substring(0, 8), 16) / 0xffffffff;

        // Select variant based on cumulative weights
        let cumulativeWeight = 0;
        for (const variant of experiment.variants) {
            cumulativeWeight += variant.weight;
            if (hashValue <= cumulativeWeight) {
                return {
                    variantName: variant.name,
                    config: variant.config
                };
            }
        }

        // Fallback to first variant (should never happen with proper weights)
        return {
            variantName: experiment.variants[0].name,
            config: experiment.variants[0].config
        };
    }

    /**
     * Track an event for analytics
     * @param {string} userId - User identifier
     * @param {string} eventName - Name of the event
     * @param {array} activeExperiments - Experiments user was exposed to
     * @param {object} metadata - Additional event metadata
     * @param {number} value - Optional numeric value
     * @param {object} db - Database connection (optional)
     */
    async trackEvent(userId, eventName, activeExperiments = [], metadata = {}, value = null, db = null) {
        try {
            const eventData = {
                user_id: userId,
                event_name: eventName,
                timestamp: new Date(),
                metadata: {
                    ...metadata,
                    experiments: activeExperiments
                },
                value: value
            };

            // Store in database if available
            if (db) {
                try {
                    await db.query(
                        `INSERT INTO events (user_id, event_name, timestamp, metadata, value)
                         VALUES ($1, $2, $3, $4, $5)`,
                        [
                            eventData.user_id,
                            eventData.event_name,
                            eventData.timestamp,
                            JSON.stringify(eventData.metadata),
                            eventData.value
                        ]
                    );
                } catch (dbError) {
                    console.warn(`Failed to store event in database:`, dbError.message);
                }
            }

            // Log for monitoring (can be ingested by analytics tools)
            console.log('Event tracked:', JSON.stringify(eventData));

            return true;
        } catch (error) {
            console.error('Error tracking event:', error);
            return false;
        }
    }

    /**
     * Get default configuration (fallback when all systems fail)
     * @returns {object} Default configuration
     */
    _getDefaultConfiguration() {
        return {
            features: {
                promptStyle: 'direct',
                primaryModel: 'gpt-4o',
                fallback: 'grok-4',
                format: 'standard',
                maxSuggestions: 5
            },
            experiments: []
        };
    }

    /**
     * Get experiment statistics (for admin dashboard)
     * @param {string} experimentId - Experiment identifier
     * @param {object} db - Database connection
     * @returns {object} Statistics including variant distribution and key metrics
     */
    async getExperimentStats(experimentId, db) {
        if (!db) {
            return { error: 'Database connection required for statistics' };
        }

        try {
            // Get variant distribution
            const distributionResult = await db.query(
                `SELECT variant_name, COUNT(*) as user_count
                 FROM user_experiment_assignments
                 WHERE experiment_id = $1
                 GROUP BY variant_name
                 ORDER BY variant_name`,
                [experimentId]
            );

            // Get key metrics by variant
            const metricsResult = await db.query(
                `SELECT 
                    metadata->>'experiments'->0->>'variantName' as variant_name,
                    COUNT(*) FILTER (WHERE event_name = 'suggestion_shown') as suggestions_shown,
                    COUNT(*) FILTER (WHERE event_name = 'suggestion_accepted') as suggestions_accepted,
                    AVG(value) FILTER (WHERE event_name = 'ai_generation_latency') as avg_latency_ms
                 FROM events
                 WHERE metadata->>'experiments'->0->>'experimentId' = $1
                 GROUP BY variant_name`,
                [experimentId]
            );

            return {
                experimentId,
                distribution: distributionResult.rows,
                metrics: metricsResult.rows.map(row => ({
                    variantName: row.variant_name,
                    suggestionsShown: parseInt(row.suggestions_shown),
                    suggestionsAccepted: parseInt(row.suggestions_accepted),
                    acceptanceRate: row.suggestions_shown > 0 
                        ? (row.suggestions_accepted / row.suggestions_shown * 100).toFixed(2) + '%'
                        : 'N/A',
                    avgLatencyMs: row.avg_latency_ms ? parseFloat(row.avg_latency_ms).toFixed(2) : 'N/A'
                }))
            };
        } catch (error) {
            console.error('Error getting experiment stats:', error);
            return { error: error.message };
        }
    }
}

module.exports = new ABTestingService();

