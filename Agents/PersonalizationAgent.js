/**
 * PersonalizationAgent.js - AI Sub-Agent for User Personality Profiling
 *
 * Builds and maintains user personality profiles by tracking selections,
 * outcomes, and interaction patterns to improve flirt suggestion accuracy.
 */

class PersonalizationAgent {
    constructor() {
        this.userProfiles = new Map(); // In-memory storage for demo
        this.interactionHistory = new Map();
        this.preferenceWeights = {
            humor_style: 0.3,
            communication_tone: 0.25,
            conversation_topics: 0.2,
            flirt_success_rate: 0.15,
            timing_patterns: 0.1
        };
    }

    /**
     * Initialize or update user personality profile
     * @param {string} userId - User identifier
     * @param {Object} initialData - Initial user data
     * @returns {Object} Created/updated profile
     */
    initializeProfile(userId, initialData = {}) {
        const profile = {
            userId,
            createdAt: new Date().toISOString(),
            lastUpdated: new Date().toISOString(),

            // Core personality metrics
            personalityTraits: {
                humor_style: initialData.humor_style || 'balanced', // witty, playful, sarcastic, silly, dry
                communication_tone: initialData.communication_tone || 'friendly', // casual, formal, flirty, direct
                risk_tolerance: initialData.risk_tolerance || 0.5, // 0-1 scale for bold vs safe suggestions
                creativity_preference: initialData.creativity_preference || 0.6, // 0-1 scale for unique vs conventional
                emotional_intelligence: initialData.emotional_intelligence || 0.7 // 0-1 scale
            },

            // Preference scores (0-1 scale)
            preferences: {
                topics: {
                    travel: 0.5,
                    food: 0.5,
                    movies: 0.5,
                    music: 0.5,
                    sports: 0.5,
                    books: 0.5,
                    career: 0.5,
                    hobbies: 0.5,
                    humor: 0.5,
                    deep_conversation: 0.5
                },
                flirt_styles: {
                    playful: 0.5,
                    sincere: 0.5,
                    humorous: 0.5,
                    intellectual: 0.5,
                    adventurous: 0.5
                },
                conversation_starters: {
                    questions: 0.5,
                    observations: 0.5,
                    compliments: 0.5,
                    humor: 0.5,
                    shared_interests: 0.5
                }
            },

            // Learning metrics
            learning_data: {
                total_suggestions_generated: 0,
                suggestions_used: 0,
                positive_outcomes: 0,
                negative_outcomes: 0,
                user_ratings: [],
                success_patterns: {},
                failure_patterns: {}
            },

            // Behavioral patterns
            usage_patterns: {
                most_active_times: [],
                average_session_length: 0,
                preferred_platforms: {},
                response_time_preference: 'immediate' // immediate, delayed, strategic
            },

            // Confidence metrics
            confidence_scores: {
                profile_accuracy: 0.3, // Starts low, improves with data
                suggestion_relevance: 0.5,
                style_match: 0.4
            }
        };

        this.userProfiles.set(userId, profile);
        return profile;
    }

    /**
     * Track user selection and outcome
     * @param {string} userId - User identifier
     * @param {Object} interaction - Interaction data
     * @returns {Object} Updated profile
     */
    trackInteraction(userId, interaction) {
        try {
            let profile = this.userProfiles.get(userId);
            if (!profile) {
                profile = this.initializeProfile(userId);
            }

            // Store interaction in history
            const interactionId = `${userId}_${Date.now()}`;
            const interactionData = {
                id: interactionId,
                timestamp: new Date().toISOString(),
                type: interaction.type, // 'suggestion_selected', 'suggestion_rated', 'outcome_reported'
                data: interaction.data,
                userId
            };

            // Add to history
            if (!this.interactionHistory.has(userId)) {
                this.interactionHistory.set(userId, []);
            }
            this.interactionHistory.get(userId).push(interactionData);

            // Update profile based on interaction type
            this.updateProfileFromInteraction(profile, interactionData);

            // Update timestamps
            profile.lastUpdated = new Date().toISOString();
            this.userProfiles.set(userId, profile);

            return {
                success: true,
                profile: this.getProfileSummary(profile),
                confidenceImprovement: this.calculateConfidenceImprovement(profile)
            };

        } catch (error) {
            console.error('Error tracking interaction:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Update profile based on specific interaction
     * @param {Object} profile - User profile
     * @param {Object} interaction - Interaction data
     */
    updateProfileFromInteraction(profile, interaction) {
        const { type, data } = interaction;

        switch (type) {
            case 'suggestion_selected':
                this.updateFromSuggestionSelection(profile, data);
                break;
            case 'suggestion_rated':
                this.updateFromRating(profile, data);
                break;
            case 'outcome_reported':
                this.updateFromOutcome(profile, data);
                break;
            case 'conversation_analysis':
                this.updateFromConversationAnalysis(profile, data);
                break;
        }

        // Update confidence scores
        this.updateConfidenceScores(profile);
    }

    /**
     * Update profile when user selects a suggestion
     * @param {Object} profile - User profile
     * @param {Object} data - Selection data
     */
    updateFromSuggestionSelection(profile, data) {
        profile.learning_data.total_suggestions_generated++;
        profile.learning_data.suggestions_used++;

        // Update style preferences based on selection
        if (data.style) {
            const currentScore = profile.preferences.flirt_styles[data.style] || 0.5;
            profile.preferences.flirt_styles[data.style] = Math.min(1.0, currentScore + 0.1);
        }

        // Update topic preferences
        if (data.topics && Array.isArray(data.topics)) {
            data.topics.forEach(topic => {
                if (profile.preferences.topics[topic] !== undefined) {
                    const currentScore = profile.preferences.topics[topic];
                    profile.preferences.topics[topic] = Math.min(1.0, currentScore + 0.05);
                }
            });
        }
    }

    /**
     * Update profile from user rating
     * @param {Object} profile - User profile
     * @param {Object} data - Rating data
     */
    updateFromRating(profile, data) {
        const { rating, suggestion_id, suggestion_style, suggestion_topics } = data;

        // Store rating
        profile.learning_data.user_ratings.push({
            rating,
            timestamp: new Date().toISOString(),
            suggestion_id,
            style: suggestion_style,
            topics: suggestion_topics
        });

        // Adjust preferences based on rating
        if (rating >= 4) { // Positive rating (4-5 stars)
            if (suggestion_style) {
                const currentScore = profile.preferences.flirt_styles[suggestion_style] || 0.5;
                profile.preferences.flirt_styles[suggestion_style] = Math.min(1.0, currentScore + 0.15);
            }

            if (suggestion_topics) {
                suggestion_topics.forEach(topic => {
                    if (profile.preferences.topics[topic] !== undefined) {
                        const currentScore = profile.preferences.topics[topic];
                        profile.preferences.topics[topic] = Math.min(1.0, currentScore + 0.1);
                    }
                });
            }
        } else if (rating <= 2) { // Negative rating (1-2 stars)
            if (suggestion_style) {
                const currentScore = profile.preferences.flirt_styles[suggestion_style] || 0.5;
                profile.preferences.flirt_styles[suggestion_style] = Math.max(0.0, currentScore - 0.1);
            }

            if (suggestion_topics) {
                suggestion_topics.forEach(topic => {
                    if (profile.preferences.topics[topic] !== undefined) {
                        const currentScore = profile.preferences.topics[topic];
                        profile.preferences.topics[topic] = Math.max(0.0, currentScore - 0.05);
                    }
                });
            }
        }
    }

    /**
     * Update profile from conversation outcome
     * @param {Object} profile - User profile
     * @param {Object} data - Outcome data
     */
    updateFromOutcome(profile, data) {
        const { outcome, suggestion_used, conversation_context } = data;

        if (outcome === 'positive') {
            profile.learning_data.positive_outcomes++;

            // Store success pattern
            const pattern = this.extractPattern(suggestion_used, conversation_context);
            const patternKey = this.generatePatternKey(pattern);
            profile.learning_data.success_patterns[patternKey] =
                (profile.learning_data.success_patterns[patternKey] || 0) + 1;

        } else if (outcome === 'negative') {
            profile.learning_data.negative_outcomes++;

            // Store failure pattern
            const pattern = this.extractPattern(suggestion_used, conversation_context);
            const patternKey = this.generatePatternKey(pattern);
            profile.learning_data.failure_patterns[patternKey] =
                (profile.learning_data.failure_patterns[patternKey] || 0) + 1;
        }
    }

    /**
     * Update profile from conversation analysis
     * @param {Object} profile - User profile
     * @param {Object} data - Analysis data
     */
    updateFromConversationAnalysis(profile, data) {
        const { analysis } = data;

        // Update personality traits based on analysis
        if (analysis.personalityIndicators) {
            const indicators = analysis.personalityIndicators;

            if (indicators.communicationStyle) {
                profile.personalityTraits.communication_tone = indicators.communicationStyle;
            }

            if (indicators.humorType) {
                profile.personalityTraits.humor_style = indicators.humorType;
            }
        }

        // Update topic preferences based on interests found
        if (analysis.personalityIndicators?.interests) {
            analysis.personalityIndicators.interests.forEach(interest => {
                const normalizedInterest = this.normalizeTopicName(interest);
                if (profile.preferences.topics[normalizedInterest] !== undefined) {
                    profile.preferences.topics[normalizedInterest] = Math.min(1.0,
                        profile.preferences.topics[normalizedInterest] + 0.2);
                }
            });
        }
    }

    /**
     * Calculate preference scores for new suggestions
     * @param {string} userId - User identifier
     * @param {Object} context - Current conversation context
     * @returns {Object} Personalized preferences
     */
    getPersonalizedPreferences(userId, context = {}) {
        const profile = this.userProfiles.get(userId);
        if (!profile) {
            return this.getDefaultPreferences();
        }

        // Calculate weighted preferences based on learning data
        const preferences = {
            preferred_styles: this.calculateStylePreferences(profile),
            preferred_topics: this.calculateTopicPreferences(profile),
            risk_tolerance: profile.personalityTraits.risk_tolerance,
            creativity_level: profile.personalityTraits.creativity_preference,
            timing_preference: profile.usage_patterns.response_time_preference,
            confidence_level: profile.confidence_scores.profile_accuracy
        };

        // Adjust based on current context
        if (context.conversation_stage) {
            preferences.style_weights = this.adjustStylesForStage(
                preferences.preferred_styles,
                context.conversation_stage
            );
        }

        return preferences;
    }

    /**
     * Calculate style preferences with confidence scores
     * @param {Object} profile - User profile
     * @returns {Object} Style preferences
     */
    calculateStylePreferences(profile) {
        const styles = profile.preferences.flirt_styles;
        const total = Object.values(styles).reduce((sum, score) => sum + score, 0);

        return Object.entries(styles).map(([style, score]) => ({
            style,
            preference_score: score,
            normalized_score: total > 0 ? score / total : 0.2,
            confidence: this.calculateStyleConfidence(profile, style)
        })).sort((a, b) => b.preference_score - a.preference_score);
    }

    /**
     * Calculate topic preferences with confidence scores
     * @param {Object} profile - User profile
     * @returns {Object} Topic preferences
     */
    calculateTopicPreferences(profile) {
        const topics = profile.preferences.topics;
        const total = Object.values(topics).reduce((sum, score) => sum + score, 0);

        return Object.entries(topics).map(([topic, score]) => ({
            topic,
            preference_score: score,
            normalized_score: total > 0 ? score / total : 0.1,
            confidence: this.calculateTopicConfidence(profile, topic)
        })).sort((a, b) => b.preference_score - a.preference_score);
    }

    /**
     * Update confidence scores based on interaction history
     * @param {Object} profile - User profile
     */
    updateConfidenceScores(profile) {
        const totalInteractions = profile.learning_data.total_suggestions_generated;
        const positiveOutcomes = profile.learning_data.positive_outcomes;
        const totalRatings = profile.learning_data.user_ratings.length;

        // Profile accuracy improves with successful interactions
        if (totalInteractions > 0) {
            const successRate = positiveOutcomes / Math.max(1, profile.learning_data.suggestions_used);
            profile.confidence_scores.profile_accuracy = Math.min(0.95,
                0.3 + (successRate * 0.6) + (Math.min(totalInteractions, 50) / 50 * 0.1)
            );
        }

        // Suggestion relevance based on ratings
        if (totalRatings > 0) {
            const avgRating = profile.learning_data.user_ratings.reduce((sum, r) => sum + r.rating, 0) / totalRatings;
            profile.confidence_scores.suggestion_relevance = Math.min(0.95, avgRating / 5);
        }

        // Style match based on consistent high ratings for preferred styles
        profile.confidence_scores.style_match = this.calculateStyleMatchConfidence(profile);
    }

    /**
     * Extract pattern from suggestion and context
     * @param {Object} suggestion - Used suggestion
     * @param {Object} context - Conversation context
     * @returns {Object} Pattern data
     */
    extractPattern(suggestion, context) {
        return {
            style: suggestion?.style,
            topics: suggestion?.topics || [],
            conversation_stage: context?.conversation_stage,
            time_of_day: context?.time_of_day,
            platform: context?.platform
        };
    }

    /**
     * Generate unique key for pattern storage
     * @param {Object} pattern - Pattern data
     * @returns {string} Pattern key
     */
    generatePatternKey(pattern) {
        return `${pattern.style || 'unknown'}_${pattern.conversation_stage || 'unknown'}_${pattern.platform || 'unknown'}`;
    }

    /**
     * Normalize topic names for consistency
     * @param {string} topic - Raw topic name
     * @returns {string} Normalized topic
     */
    normalizeTopicName(topic) {
        const topicMap = {
            'traveling': 'travel',
            'cuisine': 'food',
            'films': 'movies',
            'cinema': 'movies',
            'athletics': 'sports',
            'literature': 'books',
            'reading': 'books',
            'work': 'career',
            'job': 'career'
        };

        return topicMap[topic.toLowerCase()] || topic.toLowerCase();
    }

    /**
     * Get default preferences for new users
     * @returns {Object} Default preferences
     */
    getDefaultPreferences() {
        return {
            preferred_styles: [
                { style: 'friendly', preference_score: 0.7, confidence: 0.3 },
                { style: 'humorous', preference_score: 0.6, confidence: 0.3 },
                { style: 'playful', preference_score: 0.5, confidence: 0.3 }
            ],
            preferred_topics: [
                { topic: 'common_interests', preference_score: 0.7, confidence: 0.3 },
                { topic: 'humor', preference_score: 0.6, confidence: 0.3 },
                { topic: 'travel', preference_score: 0.5, confidence: 0.3 }
            ],
            risk_tolerance: 0.5,
            creativity_level: 0.6,
            timing_preference: 'immediate',
            confidence_level: 0.3
        };
    }

    /**
     * Calculate confidence for specific style
     * @param {Object} profile - User profile
     * @param {string} style - Style to calculate confidence for
     * @returns {number} Confidence score
     */
    calculateStyleConfidence(profile, style) {
        const styleRatings = profile.learning_data.user_ratings.filter(r => r.style === style);
        if (styleRatings.length === 0) return 0.3;

        const avgRating = styleRatings.reduce((sum, r) => sum + r.rating, 0) / styleRatings.length;
        return Math.min(0.95, (avgRating / 5) * (Math.min(styleRatings.length, 10) / 10));
    }

    /**
     * Calculate confidence for specific topic
     * @param {Object} profile - User profile
     * @param {string} topic - Topic to calculate confidence for
     * @returns {number} Confidence score
     */
    calculateTopicConfidence(profile, topic) {
        const interactions = this.interactionHistory.get(profile.userId) || [];
        const topicInteractions = interactions.filter(i =>
            i.data.topics && i.data.topics.includes(topic)
        );

        if (topicInteractions.length === 0) return 0.3;
        return Math.min(0.9, 0.3 + (topicInteractions.length / 20));
    }

    /**
     * Calculate style match confidence
     * @param {Object} profile - User profile
     * @returns {number} Style match confidence
     */
    calculateStyleMatchConfidence(profile) {
        const ratings = profile.learning_data.user_ratings;
        if (ratings.length < 5) return 0.4;

        // Calculate consistency of high ratings for preferred styles
        const topStyles = this.calculateStylePreferences(profile).slice(0, 3);
        const consistentHighRatings = ratings.filter(r =>
            r.rating >= 4 && topStyles.some(s => s.style === r.style)
        );

        return Math.min(0.9, 0.4 + (consistentHighRatings.length / ratings.length) * 0.5);
    }

    /**
     * Get profile summary for external use
     * @param {Object} profile - Full profile
     * @returns {Object} Summary data
     */
    getProfileSummary(profile) {
        return {
            userId: profile.userId,
            personalityTraits: profile.personalityTraits,
            topPreferences: {
                styles: this.calculateStylePreferences(profile).slice(0, 3),
                topics: this.calculateTopicPreferences(profile).slice(0, 5)
            },
            confidence: profile.confidence_scores,
            interactionCount: profile.learning_data.total_suggestions_generated,
            successRate: profile.learning_data.suggestions_used > 0 ?
                profile.learning_data.positive_outcomes / profile.learning_data.suggestions_used : 0
        };
    }

    /**
     * Calculate confidence improvement from interaction
     * @param {Object} profile - User profile
     * @returns {Object} Confidence changes
     */
    calculateConfidenceImprovement(profile) {
        // Simple improvement calculation - could be more sophisticated
        const interactions = profile.learning_data.total_suggestions_generated;
        const baseImprovement = Math.min(0.02, 0.1 / Math.max(1, interactions));

        return {
            profile_accuracy: baseImprovement,
            suggestion_relevance: baseImprovement * 0.8,
            style_match: baseImprovement * 0.6
        };
    }

    /**
     * Adjust style weights based on conversation stage
     * @param {Array} styles - Style preferences
     * @param {string} stage - Conversation stage
     * @returns {Array} Adjusted style weights
     */
    adjustStylesForStage(styles, stage) {
        const stageAdjustments = {
            'opening': { playful: 1.2, friendly: 1.3, sincere: 0.8 },
            'building_rapport': { intellectual: 1.2, sincere: 1.2, humorous: 1.1 },
            'flirting': { playful: 1.4, humorous: 1.3, adventurous: 1.2 },
            'planning_meetup': { sincere: 1.3, adventurous: 1.2, intellectual: 1.1 }
        };

        const adjustments = stageAdjustments[stage] || {};

        return styles.map(style => ({
            ...style,
            adjusted_score: style.preference_score * (adjustments[style.style] || 1.0)
        }));
    }

    /**
     * Get user interaction history
     * @param {string} userId - User identifier
     * @param {number} limit - Maximum number of interactions to return
     * @returns {Array} Recent interactions
     */
    getInteractionHistory(userId, limit = 50) {
        const history = this.interactionHistory.get(userId) || [];
        return history.slice(-limit).reverse(); // Most recent first
    }

    /**
     * Delete user profile and data (GDPR compliance)
     * @param {string} userId - User identifier
     * @returns {Object} Deletion result
     */
    deleteUserData(userId) {
        try {
            const profileDeleted = this.userProfiles.delete(userId);
            const historyDeleted = this.interactionHistory.delete(userId);

            return {
                success: true,
                profileDeleted,
                historyDeleted,
                deletedAt: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Get personalization agent health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: 'healthy',
            profilesStored: this.userProfiles.size,
            interactionHistoriesStored: this.interactionHistory.size,
            memoryUsage: process.memoryUsage(),
            lastChecked: new Date().toISOString()
        };
    }
}

module.exports = PersonalizationAgent;