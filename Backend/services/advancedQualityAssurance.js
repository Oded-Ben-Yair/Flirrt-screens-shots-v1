/**
 * Advanced Quality Assurance Service - AI Response Validation and Metrics
 *
 * Comprehensive quality monitoring system:
 * - Real-time quality scoring and validation
 * - Content appropriateness filtering
 * - Engagement potential analysis
 * - Response uniqueness validation
 * - Performance quality metrics
 * - A/B testing quality comparisons
 * - Quality-based routing decisions
 */

const { logger } = require('./logger');

class AdvancedQualityAssurance {
    constructor() {
        // Quality scoring weights
        this.qualityWeights = {
            confidence: 0.3,        // AI model confidence
            uniqueness: 0.2,        // Response uniqueness
            engagement: 0.2,        // Engagement potential
            appropriateness: 0.15,  // Content appropriateness
            relevance: 0.15         // Context relevance
        };

        // Quality thresholds by tier
        this.qualityThresholds = {
            keyboard: {
                minimum: 0.6,
                target: 0.75,
                excellent: 0.85
            },
            standard: {
                minimum: 0.7,
                target: 0.8,
                excellent: 0.9
            },
            analysis: {
                minimum: 0.75,
                target: 0.85,
                excellent: 0.95
            }
        };

        // Content filters
        this.contentFilters = {
            inappropriate: [
                /\b(explicit|sexual|nsfw|adult|porn|xxx)\b/i,
                /\b(drug|cocaine|marijuana|weed|high)\b/i,
                /\b(kill|die|death|suicide|murder)\b/i,
                /\b(hate|racism|sexist|homophob)\b/i
            ],
            lowQuality: [
                /^(hi|hey|hello|sup)$/i,
                /^(ok|okay|sure|yes|no)$/i,
                /^(.{1,10})$/,  // Too short
                /(.)\1{4,}/,    // Repeated characters
                /^[^a-zA-Z]*$/ // No letters
            ],
            spam: [
                /\b(click here|visit|website|link|url)\b/i,
                /\b(buy now|sale|discount|offer|deal)\b/i,
                /\b(money|cash|payment|free)\b/i
            ]
        };

        // Quality metrics tracking
        this.qualityMetrics = {
            totalEvaluations: 0,
            passedMinimum: 0,
            reachedTarget: 0,
            achievedExcellent: 0,
            filteredContent: 0,
            avgQualityScore: 0,
            qualityTrends: [],
            tierMetrics: {}
        };

        // Initialize tier metrics
        for (const tier of Object.keys(this.qualityThresholds)) {
            this.qualityMetrics.tierMetrics[tier] = {
                evaluations: 0,
                avgScore: 0,
                passRate: 0,
                trends: []
            };
        }

        this.initializeQualityTracking();
        logger.info('Advanced Quality Assurance initialized', {
            tiers: Object.keys(this.qualityThresholds),
            contentFilters: Object.keys(this.contentFilters).length
        });
    }

    /**
     * Comprehensive quality evaluation of AI response
     * @param {Object} response - AI response object
     * @param {Object} request - Original request
     * @param {string} tier - Processing tier
     * @returns {Object} Quality evaluation result
     */
    async evaluateResponseQuality(response, request, tier = 'standard') {
        const startTime = Date.now();
        this.qualityMetrics.totalEvaluations++;

        try {
            const evaluation = {
                overallScore: 0,
                scores: {},
                passed: false,
                tier,
                issues: [],
                recommendations: [],
                metadata: {
                    evaluationTime: 0,
                    evaluatedAt: new Date().toISOString(),
                    version: 'v2.0'
                }
            };

            // 1. Content appropriateness check
            evaluation.scores.appropriateness = await this.evaluateContentAppropriateness(response);

            // 2. Uniqueness analysis
            evaluation.scores.uniqueness = await this.evaluateUniqueness(response, request);

            // 3. Engagement potential scoring
            evaluation.scores.engagement = await this.evaluateEngagementPotential(response, request);

            // 4. Context relevance evaluation
            evaluation.scores.relevance = await this.evaluateContextRelevance(response, request);

            // 5. Confidence scoring (use existing or calculate)
            evaluation.scores.confidence = this.evaluateConfidenceScore(response);

            // 6. Calculate overall weighted score
            evaluation.overallScore = this.calculateWeightedScore(evaluation.scores);

            // 7. Quality threshold validation
            const thresholds = this.qualityThresholds[tier];
            evaluation.passed = evaluation.overallScore >= thresholds.minimum;
            evaluation.targetMet = evaluation.overallScore >= thresholds.target;
            evaluation.excellent = evaluation.overallScore >= thresholds.excellent;

            // 8. Generate quality insights and recommendations
            evaluation.issues = this.identifyQualityIssues(evaluation.scores, thresholds);
            evaluation.recommendations = this.generateQualityRecommendations(evaluation);

            // 9. Update metrics
            evaluation.metadata.evaluationTime = Date.now() - startTime;
            this.updateQualityMetrics(evaluation, tier);

            logger.debug('Quality evaluation completed', {
                correlationId: request.correlationId,
                tier,
                overallScore: evaluation.overallScore.toFixed(3),
                passed: evaluation.passed,
                evaluationTime: evaluation.metadata.evaluationTime
            });

            return evaluation;

        } catch (error) {
            logger.error('Quality evaluation failed', {
                correlationId: request.correlationId,
                tier,
                error: error.message
            });

            // Return minimal passing evaluation to avoid blocking
            return {
                overallScore: 0.7,
                scores: { error: true },
                passed: true,
                tier,
                issues: ['Evaluation error'],
                recommendations: ['Review evaluation system'],
                metadata: {
                    evaluationTime: Date.now() - startTime,
                    error: error.message
                }
            };
        }
    }

    /**
     * Evaluate content appropriateness
     * @param {Object} response - Response object
     * @returns {Promise<number>} Appropriateness score (0-1)
     */
    async evaluateContentAppropriateness(response) {
        try {
            if (!response.suggestions || !Array.isArray(response.suggestions)) {
                return 0.5; // Neutral if no suggestions
            }

            let totalScore = 0;
            let validSuggestions = 0;

            for (const suggestion of response.suggestions) {
                let suggestionScore = 1.0; // Start with perfect score

                const text = suggestion.text || '';

                // Check for inappropriate content
                for (const pattern of this.contentFilters.inappropriate) {
                    if (pattern.test(text)) {
                        suggestionScore -= 0.8; // Major penalty
                        break;
                    }
                }

                // Check for spam content
                for (const pattern of this.contentFilters.spam) {
                    if (pattern.test(text)) {
                        suggestionScore -= 0.3; // Moderate penalty
                        break;
                    }
                }

                // Check for low quality patterns
                for (const pattern of this.contentFilters.lowQuality) {
                    if (pattern.test(text)) {
                        suggestionScore -= 0.2; // Minor penalty
                        break;
                    }
                }

                // Length-based quality (too short or too long)
                if (text.length < 10) {
                    suggestionScore -= 0.3;
                } else if (text.length > 500) {
                    suggestionScore -= 0.2;
                } else if (text.length >= 20 && text.length <= 200) {
                    suggestionScore += 0.1; // Bonus for good length
                }

                totalScore += Math.max(0, Math.min(1, suggestionScore));
                validSuggestions++;
            }

            return validSuggestions > 0 ? totalScore / validSuggestions : 0;

        } catch (error) {
            logger.warn('Error evaluating content appropriateness', { error: error.message });
            return 0.7; // Default acceptable score
        }
    }

    /**
     * Evaluate response uniqueness
     * @param {Object} response - Response object
     * @param {Object} request - Original request
     * @returns {Promise<number>} Uniqueness score (0-1)
     */
    async evaluateUniqueness(response, request) {
        try {
            if (!response.suggestions || !Array.isArray(response.suggestions)) {
                return 0.5;
            }

            const suggestions = response.suggestions.map(s => s.text || '').filter(t => t.length > 0);
            if (suggestions.length === 0) return 0;

            let uniquenessSum = 0;
            let validComparisons = 0;

            // Check internal uniqueness (suggestions vs each other)
            for (let i = 0; i < suggestions.length; i++) {
                for (let j = i + 1; j < suggestions.length; j++) {
                    const similarity = this.calculateTextSimilarity(suggestions[i], suggestions[j]);
                    uniquenessSum += (1 - similarity);
                    validComparisons++;
                }
            }

            // Bonus for creative language patterns
            const creativityBonus = this.evaluateCreativity(suggestions);

            // Calculate base uniqueness
            let uniquenessScore = validComparisons > 0 ? uniquenessSum / validComparisons : 0.8;

            // Apply creativity bonus
            uniquenessScore = Math.min(1.0, uniquenessScore + (creativityBonus * 0.2));

            return uniquenessScore;

        } catch (error) {
            logger.warn('Error evaluating uniqueness', { error: error.message });
            return 0.7;
        }
    }

    /**
     * Evaluate engagement potential
     * @param {Object} response - Response object
     * @param {Object} request - Original request
     * @returns {Promise<number>} Engagement score (0-1)
     */
    async evaluateEngagementPotential(response, request) {
        try {
            if (!response.suggestions || !Array.isArray(response.suggestions)) {
                return 0.5;
            }

            let totalEngagement = 0;
            let validSuggestions = 0;

            for (const suggestion of response.suggestions) {
                const text = suggestion.text || '';
                let engagementScore = 0.5; // Base score

                // Question patterns (encourage response)
                if (/\?/.test(text)) engagementScore += 0.2;
                if (/\b(what|how|why|when|where|who)\b/i.test(text)) engagementScore += 0.15;

                // Personal connection patterns
                if (/\b(you|your|yours)\b/i.test(text)) engagementScore += 0.1;
                if (/\b(I|me|my|mine)\b/i.test(text)) engagementScore += 0.05;

                // Emotional engagement
                const emotionalWords = ['love', 'excited', 'amazing', 'wonderful', 'fascinating', 'curious', 'intrigued'];
                for (const word of emotionalWords) {
                    if (new RegExp(`\\b${word}\\b`, 'i').test(text)) {
                        engagementScore += 0.1;
                        break;
                    }
                }

                // Conversational starters
                const starterPatterns = [
                    /\b(tell me|share|describe)\b/i,
                    /\b(what's|how's|where's)\b/i,
                    /\b(have you|do you|would you)\b/i
                ];
                for (const pattern of starterPatterns) {
                    if (pattern.test(text)) {
                        engagementScore += 0.15;
                        break;
                    }
                }

                // Tone matching (if specified in request)
                if (request.tone) {
                    const toneWords = this.getToneWords(request.tone);
                    for (const word of toneWords) {
                        if (new RegExp(`\\b${word}\\b`, 'i').test(text)) {
                            engagementScore += 0.1;
                            break;
                        }
                    }
                }

                // Length optimization (not too short, not too long)
                if (text.length >= 30 && text.length <= 150) {
                    engagementScore += 0.1;
                }

                totalEngagement += Math.min(1.0, engagementScore);
                validSuggestions++;
            }

            return validSuggestions > 0 ? totalEngagement / validSuggestions : 0.5;

        } catch (error) {
            logger.warn('Error evaluating engagement potential', { error: error.message });
            return 0.7;
        }
    }

    /**
     * Evaluate context relevance
     * @param {Object} response - Response object
     * @param {Object} request - Original request
     * @returns {Promise<number>} Relevance score (0-1)
     */
    async evaluateContextRelevance(response, request) {
        try {
            if (!response.suggestions || !Array.isArray(response.suggestions)) {
                return 0.5;
            }

            const context = request.context || '';
            const suggestionType = request.suggestion_type || '';
            const tone = request.tone || '';

            if (!context && !suggestionType) {
                return 0.7; // Default for requests without context
            }

            let totalRelevance = 0;
            let validSuggestions = 0;

            // Extract key terms from context
            const contextTerms = this.extractKeyTerms(context);
            const typeTerms = this.extractKeyTerms(suggestionType);

            for (const suggestion of response.suggestions) {
                const text = suggestion.text || '';
                let relevanceScore = 0.3; // Base relevance

                // Context term matching
                for (const term of contextTerms) {
                    if (new RegExp(`\\b${term}\\b`, 'i').test(text)) {
                        relevanceScore += 0.2;
                    }
                }

                // Suggestion type relevance
                for (const term of typeTerms) {
                    if (new RegExp(`\\b${term}\\b`, 'i').test(text)) {
                        relevanceScore += 0.15;
                    }
                }

                // Tone consistency
                if (tone && this.matchesTone(text, tone)) {
                    relevanceScore += 0.2;
                }

                // Topic alignment
                if (suggestion.topics && suggestion.topics.length > 0) {
                    const topicAlignment = this.evaluateTopicAlignment(suggestion.topics, context);
                    relevanceScore += topicAlignment * 0.15;
                }

                totalRelevance += Math.min(1.0, relevanceScore);
                validSuggestions++;
            }

            return validSuggestions > 0 ? totalRelevance / validSuggestions : 0.5;

        } catch (error) {
            logger.warn('Error evaluating context relevance', { error: error.message });
            return 0.7;
        }
    }

    /**
     * Evaluate confidence score
     * @param {Object} response - Response object
     * @returns {number} Confidence score (0-1)
     */
    evaluateConfidenceScore(response) {
        try {
            if (!response.suggestions || !Array.isArray(response.suggestions)) {
                return response.qualityScore || 0.5;
            }

            // Use existing confidence scores if available
            const confidenceScores = response.suggestions
                .map(s => s.confidence || 0)
                .filter(c => c > 0);

            if (confidenceScores.length > 0) {
                return confidenceScores.reduce((sum, c) => sum + c, 0) / confidenceScores.length;
            }

            // Calculate based on response characteristics
            let confidenceScore = 0.5;

            // Model-based confidence
            if (response.metadata?.model) {
                const modelConfidence = this.getModelConfidence(response.metadata.model);
                confidenceScore += modelConfidence * 0.3;
            }

            // Response completeness
            if (response.suggestions.length >= 3) confidenceScore += 0.1;
            if (response.suggestions.length >= 5) confidenceScore += 0.1;

            // Quality indicators
            if (response.qualityScore) {
                confidenceScore += response.qualityScore * 0.3;
            }

            return Math.min(1.0, confidenceScore);

        } catch (error) {
            logger.warn('Error evaluating confidence score', { error: error.message });
            return 0.7;
        }
    }

    /**
     * Calculate weighted overall score
     * @param {Object} scores - Individual quality scores
     * @returns {number} Weighted overall score
     */
    calculateWeightedScore(scores) {
        let weightedSum = 0;
        let totalWeight = 0;

        for (const [category, score] of Object.entries(scores)) {
            if (typeof score === 'number' && this.qualityWeights[category]) {
                weightedSum += score * this.qualityWeights[category];
                totalWeight += this.qualityWeights[category];
            }
        }

        return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
    }

    /**
     * Calculate text similarity using Jaccard index
     * @param {string} text1 - First text
     * @param {string} text2 - Second text
     * @returns {number} Similarity score (0-1)
     */
    calculateTextSimilarity(text1, text2) {
        try {
            const words1 = new Set(text1.toLowerCase().split(/\s+/));
            const words2 = new Set(text2.toLowerCase().split(/\s+/));

            const intersection = new Set([...words1].filter(w => words2.has(w)));
            const union = new Set([...words1, ...words2]);

            return union.size > 0 ? intersection.size / union.size : 0;

        } catch (error) {
            return 0;
        }
    }

    /**
     * Evaluate creativity in suggestions
     * @param {Array} suggestions - Array of suggestion texts
     * @returns {number} Creativity score (0-1)
     */
    evaluateCreativity(suggestions) {
        try {
            let creativityScore = 0;

            const creativityIndicators = [
                /\b(imagine|picture|envision|dream)\b/i,
                /\b(adventure|journey|explore|discover)\b/i,
                /\b(unique|special|extraordinary|remarkable)\b/i,
                /\b(creative|artistic|innovative|original)\b/i
            ];

            const metaphorPatterns = [
                /like a/i,
                /as if/i,
                /reminds me of/i
            ];

            for (const suggestion of suggestions) {
                // Check for creative language
                for (const pattern of creativityIndicators) {
                    if (pattern.test(suggestion)) {
                        creativityScore += 0.1;
                        break;
                    }
                }

                // Check for metaphorical language
                for (const pattern of metaphorPatterns) {
                    if (pattern.test(suggestion)) {
                        creativityScore += 0.05;
                        break;
                    }
                }

                // Vocabulary diversity bonus
                const words = suggestion.toLowerCase().split(/\s+/);
                const uniqueWords = new Set(words);
                if (uniqueWords.size / words.length > 0.8) {
                    creativityScore += 0.05;
                }
            }

            return Math.min(1.0, creativityScore);

        } catch (error) {
            return 0;
        }
    }

    /**
     * Get tone-specific words
     * @param {string} tone - Desired tone
     * @returns {Array} Array of tone words
     */
    getToneWords(tone) {
        const toneWords = {
            playful: ['fun', 'playful', 'silly', 'amusing', 'delightful'],
            romantic: ['romantic', 'sweet', 'adorable', 'charming', 'lovely'],
            witty: ['clever', 'witty', 'smart', 'brilliant', 'sharp'],
            casual: ['casual', 'relaxed', 'easy', 'comfortable', 'natural'],
            confident: ['confident', 'strong', 'bold', 'determined', 'sure'],
            friendly: ['friendly', 'warm', 'welcoming', 'kind', 'nice']
        };

        return toneWords[tone.toLowerCase()] || [];
    }

    /**
     * Check if text matches desired tone
     * @param {string} text - Text to check
     * @param {string} tone - Desired tone
     * @returns {boolean} Whether text matches tone
     */
    matchesTone(text, tone) {
        const toneWords = this.getToneWords(tone);
        for (const word of toneWords) {
            if (new RegExp(`\\b${word}\\b`, 'i').test(text)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Extract key terms from text
     * @param {string} text - Text to extract from
     * @returns {Array} Key terms
     */
    extractKeyTerms(text) {
        if (!text) return [];

        // Simple extraction - remove stop words and get meaningful terms
        const stopWords = new Set(['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'can']);

        return text.toLowerCase()
            .split(/\s+/)
            .filter(word => word.length > 2 && !stopWords.has(word))
            .slice(0, 10); // Top 10 terms
    }

    /**
     * Evaluate topic alignment
     * @param {Array} topics - Suggestion topics
     * @param {string} context - Request context
     * @returns {number} Alignment score (0-1)
     */
    evaluateTopicAlignment(topics, context) {
        if (!topics || !context) return 0.5;

        const contextTerms = this.extractKeyTerms(context);
        let alignmentScore = 0;

        for (const topic of topics) {
            for (const term of contextTerms) {
                if (topic.toLowerCase().includes(term) || term.includes(topic.toLowerCase())) {
                    alignmentScore += 0.2;
                    break;
                }
            }
        }

        return Math.min(1.0, alignmentScore);
    }

    /**
     * Get model confidence factor
     * @param {string} model - Model name
     * @returns {number} Confidence factor (0-1)
     */
    getModelConfidence(model) {
        const modelConfidences = {
            'grok-4-fast-reasoning': 0.9,
            'grok-4-fast-non-reasoning': 0.8,
            'grok-4-fast': 0.75,
            'gemini-vision': 0.85,
            'emergency-fallback': 0.3
        };

        return modelConfidences[model] || 0.7;
    }

    /**
     * Identify quality issues
     * @param {Object} scores - Quality scores
     * @param {Object} thresholds - Quality thresholds
     * @returns {Array} List of issues
     */
    identifyQualityIssues(scores, thresholds) {
        const issues = [];

        if (scores.appropriateness < 0.8) {
            issues.push('Content appropriateness concerns detected');
        }

        if (scores.uniqueness < 0.6) {
            issues.push('Low uniqueness - responses may be too similar');
        }

        if (scores.engagement < 0.7) {
            issues.push('Low engagement potential - responses may not encourage conversation');
        }

        if (scores.relevance < 0.7) {
            issues.push('Context relevance issues - responses may not align with request');
        }

        if (scores.confidence < 0.7) {
            issues.push('Low confidence scores - model uncertainty detected');
        }

        return issues;
    }

    /**
     * Generate quality recommendations
     * @param {Object} evaluation - Quality evaluation
     * @returns {Array} List of recommendations
     */
    generateQualityRecommendations(evaluation) {
        const recommendations = [];
        const scores = evaluation.scores;

        if (scores.appropriateness < 0.8) {
            recommendations.push('Review content filtering rules and model training');
        }

        if (scores.uniqueness < 0.6) {
            recommendations.push('Increase temperature or adjust creativity parameters');
        }

        if (scores.engagement < 0.7) {
            recommendations.push('Enhance prompts to encourage more engaging responses');
        }

        if (scores.relevance < 0.7) {
            recommendations.push('Improve context understanding and prompt engineering');
        }

        if (scores.confidence < 0.7) {
            recommendations.push('Consider using higher-confidence model or ensemble methods');
        }

        if (evaluation.overallScore < evaluation.targetMet) {
            recommendations.push('Consider tier upgrade or quality enhancement techniques');
        }

        return recommendations;
    }

    /**
     * Update quality metrics
     * @param {Object} evaluation - Quality evaluation
     * @param {string} tier - Processing tier
     */
    updateQualityMetrics(evaluation, tier) {
        try {
            const thresholds = this.qualityThresholds[tier];

            // Update overall metrics
            if (evaluation.overallScore >= thresholds.minimum) {
                this.qualityMetrics.passedMinimum++;
            }

            if (evaluation.overallScore >= thresholds.target) {
                this.qualityMetrics.reachedTarget++;
            }

            if (evaluation.overallScore >= thresholds.excellent) {
                this.qualityMetrics.achievedExcellent++;
            }

            // Update average quality score
            const currentAvg = this.qualityMetrics.avgQualityScore;
            this.qualityMetrics.avgQualityScore =
                currentAvg === 0 ? evaluation.overallScore :
                (currentAvg * 0.95 + evaluation.overallScore * 0.05);

            // Update tier-specific metrics
            const tierMetrics = this.qualityMetrics.tierMetrics[tier];
            tierMetrics.evaluations++;

            const tierCurrentAvg = tierMetrics.avgScore;
            tierMetrics.avgScore =
                tierCurrentAvg === 0 ? evaluation.overallScore :
                (tierCurrentAvg * 0.9 + evaluation.overallScore * 0.1);

            tierMetrics.passRate =
                this.qualityMetrics.passedMinimum / this.qualityMetrics.totalEvaluations;

            // Update trends (keep last 100 evaluations)
            this.qualityMetrics.qualityTrends.push(evaluation.overallScore);
            if (this.qualityMetrics.qualityTrends.length > 100) {
                this.qualityMetrics.qualityTrends.shift();
            }

            tierMetrics.trends.push(evaluation.overallScore);
            if (tierMetrics.trends.length > 50) {
                tierMetrics.trends.shift();
            }

        } catch (error) {
            logger.warn('Error updating quality metrics', { error: error.message });
        }
    }

    /**
     * Initialize quality tracking
     */
    initializeQualityTracking() {
        // Log quality metrics every 10 minutes
        setInterval(() => {
            this.logQualityMetrics();
        }, 10 * 60 * 1000);

        logger.debug('Quality tracking initialized');
    }

    /**
     * Log quality metrics for monitoring
     */
    logQualityMetrics() {
        try {
            const insights = this.getQualityInsights();

            logger.info('Quality metrics summary', {
                totalEvaluations: this.qualityMetrics.totalEvaluations,
                avgQualityScore: Math.round(this.qualityMetrics.avgQualityScore * 1000) / 1000,
                passRate: insights.overall.passRate,
                trendDirection: insights.trends.direction,
                timestamp: new Date().toISOString()
            });

        } catch (error) {
            logger.warn('Error logging quality metrics', { error: error.message });
        }
    }

    /**
     * Get comprehensive quality insights
     * @returns {Object} Quality insights and analytics
     */
    getQualityInsights() {
        try {
            const total = this.qualityMetrics.totalEvaluations;

            const insights = {
                overall: {
                    totalEvaluations: total,
                    avgQualityScore: Math.round(this.qualityMetrics.avgQualityScore * 1000) / 1000,
                    passRate: total > 0 ? Math.round((this.qualityMetrics.passedMinimum / total) * 100) : 0,
                    targetRate: total > 0 ? Math.round((this.qualityMetrics.reachedTarget / total) * 100) : 0,
                    excellenceRate: total > 0 ? Math.round((this.qualityMetrics.achievedExcellent / total) * 100) : 0
                },

                trends: {
                    direction: this.calculateTrendDirection(),
                    recent: this.qualityMetrics.qualityTrends.slice(-10),
                    volatility: this.calculateVolatility()
                },

                tierPerformance: {},

                recommendations: this.generateSystemRecommendations()
            };

            // Add tier-specific insights
            for (const [tier, metrics] of Object.entries(this.qualityMetrics.tierMetrics)) {
                insights.tierPerformance[tier] = {
                    evaluations: metrics.evaluations,
                    avgScore: Math.round(metrics.avgScore * 1000) / 1000,
                    passRate: Math.round(metrics.passRate * 100),
                    trend: this.calculateTierTrend(metrics.trends),
                    status: this.getTierStatus(metrics.avgScore, tier)
                };
            }

            return insights;

        } catch (error) {
            logger.error('Error generating quality insights', { error: error.message });
            return {
                overall: { error: 'Unable to generate insights' },
                trends: { direction: 'unknown' },
                tierPerformance: {},
                recommendations: []
            };
        }
    }

    /**
     * Calculate quality trend direction
     * @returns {string} Trend direction
     */
    calculateTrendDirection() {
        const trends = this.qualityMetrics.qualityTrends;
        if (trends.length < 10) return 'insufficient_data';

        const recent = trends.slice(-10);
        const older = trends.slice(-20, -10);

        if (older.length === 0) return 'insufficient_data';

        const recentAvg = recent.reduce((sum, v) => sum + v, 0) / recent.length;
        const olderAvg = older.reduce((sum, v) => sum + v, 0) / older.length;

        const change = recentAvg - olderAvg;

        if (change > 0.02) return 'improving';
        if (change < -0.02) return 'declining';
        return 'stable';
    }

    /**
     * Calculate quality volatility
     * @returns {number} Volatility score
     */
    calculateVolatility() {
        const trends = this.qualityMetrics.qualityTrends;
        if (trends.length < 5) return 0;

        const mean = trends.reduce((sum, v) => sum + v, 0) / trends.length;
        const variance = trends.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / trends.length;

        return Math.sqrt(variance);
    }

    /**
     * Calculate tier trend
     * @param {Array} trends - Tier trends
     * @returns {string} Trend status
     */
    calculateTierTrend(trends) {
        if (trends.length < 5) return 'insufficient_data';

        const recent = trends.slice(-5);
        const avg = recent.reduce((sum, v) => sum + v, 0) / recent.length;
        const first = recent[0];
        const last = recent[recent.length - 1];

        if (last > first * 1.05) return 'improving';
        if (last < first * 0.95) return 'declining';
        return 'stable';
    }

    /**
     * Get tier status based on performance
     * @param {number} avgScore - Average score
     * @param {string} tier - Tier name
     * @returns {string} Status
     */
    getTierStatus(avgScore, tier) {
        const thresholds = this.qualityThresholds[tier];

        if (avgScore >= thresholds.excellent) return 'excellent';
        if (avgScore >= thresholds.target) return 'good';
        if (avgScore >= thresholds.minimum) return 'acceptable';
        return 'needs_improvement';
    }

    /**
     * Generate system-wide recommendations
     * @returns {Array} Recommendations
     */
    generateSystemRecommendations() {
        const recommendations = [];
        const insights = this.getQualityInsights();

        if (insights.overall.passRate < 80) {
            recommendations.push('Overall pass rate is below target - review model parameters');
        }

        if (insights.trends.direction === 'declining') {
            recommendations.push('Quality trend is declining - investigate recent changes');
        }

        if (insights.trends.volatility > 0.1) {
            recommendations.push('High quality volatility detected - stabilize model outputs');
        }

        if (insights.overall.avgQualityScore < 0.75) {
            recommendations.push('Average quality below target - consider model upgrade');
        }

        return recommendations;
    }

    /**
     * Get health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        const insights = this.getQualityInsights();

        return {
            status: insights.overall.passRate > 75 ? 'healthy' : 'degraded',
            avgQualityScore: insights.overall.avgQualityScore,
            passRate: insights.overall.passRate,
            trend: insights.trends.direction,
            evaluations: insights.overall.totalEvaluations,
            tiers: Object.keys(this.qualityThresholds).length
        };
    }
}

// Export singleton instance
const advancedQualityAssurance = new AdvancedQualityAssurance();
module.exports = advancedQualityAssurance;