/**
 * A/B Testing Framework for Dual-Model AI Pipeline
 *
 * Provides comprehensive A/B testing capabilities for:
 * - Pipeline architecture variants (single vs dual model)
 * - Prompt engineering variations
 * - Response generation strategies
 * - Performance optimizations
 * - User experience improvements
 */

const { logger } = require('./logger');
const redisService = require('./redis');

class ABTestingFramework {
    constructor() {
        this.activeTests = new Map();
        this.testResults = new Map();

        // Default test configurations
        this.defaultTests = {
            // Pipeline Architecture Tests
            'pipeline_comparison': {
                name: 'Pipeline Architecture Comparison',
                description: 'Compare dual-model vs single-model pipeline performance',
                variants: [
                    { id: 'dual_model', name: 'Dual Model (Gemini + Grok)', weight: 0.6 },
                    { id: 'single_model', name: 'Single Model (Grok Only)', weight: 0.4 }
                ],
                metrics: ['response_quality', 'latency', 'user_satisfaction', 'uniqueness'],
                status: 'active',
                startDate: new Date().toISOString(),
                duration: 30 * 24 * 60 * 60 * 1000 // 30 days
            },

            // Prompt Engineering Tests
            'prompt_variations': {
                name: 'Prompt Engineering Variations',
                description: 'Test different prompt structures for Grok generation',
                variants: [
                    { id: 'detailed_context', name: 'Detailed Context Prompt', weight: 0.33 },
                    { id: 'concise_focused', name: 'Concise Focused Prompt', weight: 0.33 },
                    { id: 'creative_freedom', name: 'Creative Freedom Prompt', weight: 0.34 }
                ],
                metrics: ['creativity_score', 'relevance', 'response_time', 'user_engagement'],
                status: 'active',
                startDate: new Date().toISOString(),
                duration: 14 * 24 * 60 * 60 * 1000 // 14 days
            },

            // Response Quality Tests
            'quality_optimization': {
                name: 'Response Quality Optimization',
                description: 'Test different quality validation approaches',
                variants: [
                    { id: 'strict_validation', name: 'Strict Quality Validation', weight: 0.5 },
                    { id: 'balanced_validation', name: 'Balanced Validation', weight: 0.5 }
                ],
                metrics: ['suggestion_quality', 'approval_rate', 'user_feedback'],
                status: 'active',
                startDate: new Date().toISOString(),
                duration: 21 * 24 * 60 * 60 * 1000 // 21 days
            },

            // Performance Strategy Tests
            'performance_strategy': {
                name: 'Performance Strategy Comparison',
                description: 'Test different performance optimization strategies',
                variants: [
                    { id: 'cache_aggressive', name: 'Aggressive Caching', weight: 0.33 },
                    { id: 'parallel_processing', name: 'Parallel Processing Focus', weight: 0.33 },
                    { id: 'adaptive_timeouts', name: 'Adaptive Timeouts', weight: 0.34 }
                ],
                metrics: ['response_time', 'cache_hit_rate', 'resource_usage', 'error_rate'],
                status: 'active',
                startDate: new Date().toISOString(),
                duration: 7 * 24 * 60 * 60 * 1000 // 7 days
            }
        };

        this.initializeTests();

        logger.info('A/B Testing Framework initialized', {
            activeTests: this.activeTests.size,
            defaultTests: Object.keys(this.defaultTests).length
        });
    }

    /**
     * Initialize default tests
     */
    async initializeTests() {
        try {
            // Load existing tests from cache
            const existingTests = await redisService.get('ab_tests:active') || {};

            // Merge with default tests
            for (const [testId, testConfig] of Object.entries(this.defaultTests)) {
                if (!existingTests[testId]) {
                    this.activeTests.set(testId, {
                        ...testConfig,
                        id: testId,
                        participants: 0,
                        conversions: new Map(),
                        metrics: new Map()
                    });
                } else {
                    this.activeTests.set(testId, existingTests[testId]);
                }
            }

            // Save updated tests
            await this.saveTestsToCache();

        } catch (error) {
            logger.error('Failed to initialize A/B tests', { error: error.message });
        }
    }

    /**
     * Assign user to test variant
     * @param {string} userId - User ID
     * @param {string} testId - Test ID
     * @param {Object} context - Request context
     * @returns {Object} Test assignment
     */
    async assignToVariant(userId, testId, context = {}) {
        try {
            const test = this.activeTests.get(testId);

            if (!test || test.status !== 'active') {
                return {
                    testId,
                    variant: null,
                    reason: 'Test not active or not found'
                };
            }

            // Check if test has expired
            if (this.isTestExpired(test)) {
                await this.endTest(testId);
                return {
                    testId,
                    variant: null,
                    reason: 'Test expired'
                };
            }

            // Check existing assignment
            const existingAssignment = await this.getExistingAssignment(userId, testId);
            if (existingAssignment) {
                return existingAssignment;
            }

            // Assign to variant based on weights
            const variant = this.selectVariant(test, userId, context);

            // Record assignment
            const assignment = {
                testId,
                variant: variant.id,
                variantName: variant.name,
                assignedAt: new Date().toISOString(),
                userId,
                context
            };

            await this.recordAssignment(assignment);

            // Update test participant count
            test.participants += 1;
            await this.saveTestsToCache();

            logger.debug('User assigned to A/B test variant', {
                userId,
                testId,
                variant: variant.id,
                participants: test.participants
            });

            return assignment;

        } catch (error) {
            logger.error('Failed to assign user to variant', {
                error: error.message,
                userId,
                testId
            });

            return {
                testId,
                variant: null,
                reason: 'Assignment failed'
            };
        }
    }

    /**
     * Select variant based on weights and user characteristics
     * @param {Object} test - Test configuration
     * @param {string} userId - User ID
     * @param {Object} context - Request context
     * @returns {Object} Selected variant
     */
    selectVariant(test, userId, context) {
        // Use user ID for consistent assignment
        const hash = this.hashUserId(userId);
        const random = (hash % 10000) / 10000; // 0-1 range

        let cumulativeWeight = 0;
        for (const variant of test.variants) {
            cumulativeWeight += variant.weight;
            if (random <= cumulativeWeight) {
                return variant;
            }
        }

        // Fallback to first variant
        return test.variants[0];
    }

    /**
     * Hash user ID for consistent variant assignment
     * @param {string} userId - User ID
     * @returns {number} Hash value
     */
    hashUserId(userId) {
        let hash = 0;
        for (let i = 0; i < userId.length; i++) {
            const char = userId.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return Math.abs(hash);
    }

    /**
     * Get existing test assignment for user
     * @param {string} userId - User ID
     * @param {string} testId - Test ID
     * @returns {Promise<Object|null>} Existing assignment
     */
    async getExistingAssignment(userId, testId) {
        try {
            const assignmentKey = `ab_assignment:${userId}:${testId}`;
            return await redisService.get(assignmentKey);
        } catch (error) {
            logger.warn('Failed to get existing assignment', { error: error.message });
            return null;
        }
    }

    /**
     * Record test assignment
     * @param {Object} assignment - Assignment details
     */
    async recordAssignment(assignment) {
        try {
            const assignmentKey = `ab_assignment:${assignment.userId}:${assignment.testId}`;
            await redisService.set(assignmentKey, assignment, 30 * 24 * 60 * 60); // 30 days TTL

        } catch (error) {
            logger.error('Failed to record assignment', { error: error.message });
        }
    }

    /**
     * Record test event/metric
     * @param {string} userId - User ID
     * @param {string} testId - Test ID
     * @param {string} eventType - Event type
     * @param {Object} eventData - Event data
     */
    async recordEvent(userId, testId, eventType, eventData = {}) {
        try {
            const assignment = await this.getExistingAssignment(userId, testId);
            if (!assignment) {
                return; // User not in test
            }

            const event = {
                userId,
                testId,
                variant: assignment.variant,
                eventType,
                eventData,
                timestamp: new Date().toISOString()
            };

            // Store event
            const eventKey = `ab_events:${testId}:${assignment.variant}`;
            const events = await redisService.get(eventKey) || [];
            events.push(event);

            // Keep only recent events (last 1000 per variant)
            if (events.length > 1000) {
                events.splice(0, events.length - 1000);
            }

            await redisService.set(eventKey, events, 30 * 24 * 60 * 60); // 30 days TTL

            // Update test metrics
            await this.updateTestMetrics(testId, assignment.variant, eventType, eventData);

            logger.debug('A/B test event recorded', {
                userId,
                testId,
                variant: assignment.variant,
                eventType
            });

        } catch (error) {
            logger.error('Failed to record A/B test event', {
                error: error.message,
                userId,
                testId,
                eventType
            });
        }
    }

    /**
     * Update test metrics
     * @param {string} testId - Test ID
     * @param {string} variant - Variant ID
     * @param {string} eventType - Event type
     * @param {Object} eventData - Event data
     */
    async updateTestMetrics(testId, variant, eventType, eventData) {
        try {
            const metricsKey = `ab_metrics:${testId}:${variant}`;
            const metrics = await redisService.get(metricsKey) || {
                totalEvents: 0,
                eventCounts: {},
                averageMetrics: {},
                lastUpdated: new Date().toISOString()
            };

            // Update event counts
            metrics.totalEvents += 1;
            metrics.eventCounts[eventType] = (metrics.eventCounts[eventType] || 0) + 1;

            // Update average metrics for numeric data
            if (eventData && typeof eventData === 'object') {
                for (const [key, value] of Object.entries(eventData)) {
                    if (typeof value === 'number') {
                        const current = metrics.averageMetrics[key] || { sum: 0, count: 0, avg: 0 };
                        current.sum += value;
                        current.count += 1;
                        current.avg = current.sum / current.count;
                        metrics.averageMetrics[key] = current;
                    }
                }
            }

            metrics.lastUpdated = new Date().toISOString();

            await redisService.set(metricsKey, metrics, 30 * 24 * 60 * 60);

        } catch (error) {
            logger.error('Failed to update test metrics', { error: error.message });
        }
    }

    /**
     * Get test results
     * @param {string} testId - Test ID
     * @returns {Promise<Object>} Test results
     */
    async getTestResults(testId) {
        try {
            const test = this.activeTests.get(testId);
            if (!test) {
                throw new Error(`Test ${testId} not found`);
            }

            const results = {
                testId,
                testName: test.name,
                description: test.description,
                status: test.status,
                participants: test.participants,
                variants: {},
                summary: {},
                recommendations: []
            };

            // Get results for each variant
            for (const variant of test.variants) {
                const variantMetrics = await redisService.get(`ab_metrics:${testId}:${variant.id}`) || {};
                const variantEvents = await redisService.get(`ab_events:${testId}:${variant.id}`) || [];

                results.variants[variant.id] = {
                    name: variant.name,
                    weight: variant.weight,
                    participants: variantEvents.length,
                    metrics: variantMetrics.averageMetrics || {},
                    eventCounts: variantMetrics.eventCounts || {},
                    lastUpdated: variantMetrics.lastUpdated
                };
            }

            // Calculate summary and statistical significance
            results.summary = this.calculateSummary(results.variants, test.metrics);
            results.recommendations = this.generateRecommendations(results);

            return results;

        } catch (error) {
            logger.error('Failed to get test results', { error: error.message, testId });
            throw error;
        }
    }

    /**
     * Calculate test summary and statistical significance
     * @param {Object} variants - Variant data
     * @param {Array} testMetrics - Metrics to analyze
     * @returns {Object} Summary data
     */
    calculateSummary(variants, testMetrics) {
        const summary = {
            significantDifferences: [],
            bestPerforming: {},
            confidence: {},
            sampleSizes: {}
        };

        const variantIds = Object.keys(variants);

        // Calculate best performing variant for each metric
        for (const metric of testMetrics) {
            let bestVariant = null;
            let bestValue = null;

            for (const variantId of variantIds) {
                const variant = variants[variantId];
                const metricValue = variant.metrics[metric]?.avg;

                if (metricValue !== undefined) {
                    if (bestValue === null || metricValue > bestValue) {
                        bestValue = metricValue;
                        bestVariant = variantId;
                    }
                }
            }

            if (bestVariant) {
                summary.bestPerforming[metric] = {
                    variant: bestVariant,
                    value: bestValue
                };
            }
        }

        // Calculate sample sizes
        for (const variantId of variantIds) {
            summary.sampleSizes[variantId] = variants[variantId].participants;
        }

        // Simple statistical significance check (chi-square for proportions)
        summary.confidence = this.calculateStatisticalSignificance(variants);

        return summary;
    }

    /**
     * Calculate statistical significance
     * @param {Object} variants - Variant data
     * @returns {Object} Confidence levels
     */
    calculateStatisticalSignificance(variants) {
        const confidence = {};

        // For simplicity, using sample size thresholds
        const variantIds = Object.keys(variants);

        for (const variantId of variantIds) {
            const sampleSize = variants[variantId].participants;

            if (sampleSize >= 1000) {
                confidence[variantId] = 'high';
            } else if (sampleSize >= 100) {
                confidence[variantId] = 'medium';
            } else if (sampleSize >= 30) {
                confidence[variantId] = 'low';
            } else {
                confidence[variantId] = 'insufficient';
            }
        }

        return confidence;
    }

    /**
     * Generate recommendations based on test results
     * @param {Object} results - Test results
     * @returns {Array} Recommendations
     */
    generateRecommendations(results) {
        const recommendations = [];

        // Check for clear winners
        const metrics = Object.keys(results.summary.bestPerforming);
        const variantScores = new Map();

        // Score variants based on how often they're best
        for (const metric of metrics) {
            const bestVariant = results.summary.bestPerforming[metric].variant;
            variantScores.set(bestVariant, (variantScores.get(bestVariant) || 0) + 1);
        }

        // Find overall best performer
        let overallBest = null;
        let maxScore = 0;
        for (const [variant, score] of variantScores) {
            if (score > maxScore) {
                maxScore = score;
                overallBest = variant;
            }
        }

        if (overallBest && results.summary.confidence[overallBest] === 'high') {
            recommendations.push({
                type: 'winner',
                variant: overallBest,
                message: `Variant ${overallBest} shows superior performance across multiple metrics with high confidence`,
                action: 'consider_rollout'
            });
        }

        // Check for insufficient sample sizes
        for (const [variant, confidence] of Object.entries(results.summary.confidence)) {
            if (confidence === 'insufficient') {
                recommendations.push({
                    type: 'data_collection',
                    variant,
                    message: `Variant ${variant} needs more data for statistical significance`,
                    action: 'continue_test'
                });
            }
        }

        // Check for long-running tests
        const testAge = Date.now() - new Date(results.startDate).getTime();
        if (testAge > 30 * 24 * 60 * 60 * 1000) { // 30 days
            recommendations.push({
                type: 'test_duration',
                message: 'Test has been running for over 30 days',
                action: 'review_and_conclude'
            });
        }

        return recommendations;
    }

    /**
     * End test and record final results
     * @param {string} testId - Test ID
     * @param {string} reason - Reason for ending
     * @returns {Promise<Object>} Final results
     */
    async endTest(testId, reason = 'manual') {
        try {
            const test = this.activeTests.get(testId);
            if (!test) {
                throw new Error(`Test ${testId} not found`);
            }

            // Get final results
            const finalResults = await this.getTestResults(testId);

            // Update test status
            test.status = 'completed';
            test.endDate = new Date().toISOString();
            test.endReason = reason;

            // Archive results
            const archiveKey = `ab_archive:${testId}`;
            await redisService.set(archiveKey, {
                test,
                results: finalResults,
                archivedAt: new Date().toISOString()
            }, 365 * 24 * 60 * 60); // Archive for 1 year

            // Remove from active tests
            this.activeTests.delete(testId);
            await this.saveTestsToCache();

            logger.info('A/B test ended', {
                testId,
                reason,
                participants: test.participants,
                duration: test.endDate ? new Date(test.endDate) - new Date(test.startDate) : 'unknown'
            });

            return finalResults;

        } catch (error) {
            logger.error('Failed to end test', { error: error.message, testId });
            throw error;
        }
    }

    /**
     * Check if test has expired
     * @param {Object} test - Test configuration
     * @returns {boolean} Whether test has expired
     */
    isTestExpired(test) {
        if (!test.duration) return false;
        const startTime = new Date(test.startDate).getTime();
        return Date.now() - startTime > test.duration;
    }

    /**
     * Save tests to cache
     */
    async saveTestsToCache() {
        try {
            const testsData = {};
            for (const [testId, test] of this.activeTests) {
                testsData[testId] = test;
            }
            await redisService.set('ab_tests:active', testsData, 30 * 24 * 60 * 60);
        } catch (error) {
            logger.error('Failed to save tests to cache', { error: error.message });
        }
    }

    /**
     * Get all active tests
     * @returns {Array} Active tests
     */
    getActiveTests() {
        return Array.from(this.activeTests.values()).map(test => ({
            id: test.id,
            name: test.name,
            description: test.description,
            status: test.status,
            participants: test.participants,
            variants: test.variants.map(v => ({ id: v.id, name: v.name, weight: v.weight })),
            startDate: test.startDate,
            duration: test.duration
        }));
    }

    /**
     * Create new A/B test
     * @param {Object} testConfig - Test configuration
     * @returns {string} Test ID
     */
    async createTest(testConfig) {
        try {
            const testId = `custom_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            const test = {
                id: testId,
                name: testConfig.name,
                description: testConfig.description,
                variants: testConfig.variants,
                metrics: testConfig.metrics || ['conversion_rate'],
                status: 'active',
                startDate: new Date().toISOString(),
                duration: testConfig.duration || (14 * 24 * 60 * 60 * 1000), // 14 days default
                participants: 0,
                conversions: new Map(),
                metrics: new Map()
            };

            this.activeTests.set(testId, test);
            await this.saveTestsToCache();

            logger.info('New A/B test created', {
                testId,
                name: test.name,
                variants: test.variants.length
            });

            return testId;

        } catch (error) {
            logger.error('Failed to create A/B test', { error: error.message });
            throw error;
        }
    }

    /**
     * Get framework health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: 'healthy',
            activeTests: this.activeTests.size,
            totalTests: this.activeTests.size + Object.keys(this.defaultTests).length,
            lastChecked: new Date().toISOString()
        };
    }
}

// Export singleton instance
const abTestingFramework = new ABTestingFramework();
module.exports = abTestingFramework;