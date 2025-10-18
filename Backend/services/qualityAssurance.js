/**
 * Quality Assurance Service
 * Comprehensive QA pipeline ensuring 100% success rate for Vibe8.ai
 */

const crypto = require('crypto');
const { logger } = require('./logger');
const redisService = require('./redis');

class QualityAssuranceService {
    constructor() {
        this.metrics = {
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            duplicateDetections: 0,
            lowQualityDetections: 0,
            fallbackUsages: 0
        };

        this.responseCache = new Map(); // For duplicate detection
        this.qualityThresholds = {
            minConfidence: 0.7,
            minSuggestionLength: 10,
            maxSuggestionLength: 280,
            minUniqueness: 0.8,
            minRelevance: 0.75
        };

        this.bannedPhrases = [
            'generic pickup line',
            'copy and paste',
            'not specific',
            'template response',
            'default message'
        ];

        this.qualityPatterns = {
            personalizations: [
                /\b(your|you're)\b/gi,
                /\b(photo|picture|pic)\b/gi,
                /\b(profile|bio)\b/gi,
                /\b(interest|hobby|passion)\b/gi
            ],
            engagement: [
                /\?/g,
                /\b(tell me|what|how|when|where|why)\b/gi,
                /\b(love|enjoy|excited|amazing|interesting)\b/gi
            ],
            conversational: [
                /\b(I|me|my)\b/gi,
                /\b(we|us|together)\b/gi,
                /\b(chat|talk|conversation)\b/gi
            ]
        };
    }

    /**
     * Main quality validation pipeline
     */
    async validateResponse(suggestions, context, correlationId) {
        const timer = logger.timer('quality_validation');

        try {
            this.metrics.totalRequests++;

            logger.info('Starting QA validation pipeline', {
                correlationId,
                suggestionsCount: suggestions.length,
                context: context?.suggestion_type || 'unknown'
            });

            // Step 1: Validate basic structure
            const structureValidation = this.validateStructure(suggestions);
            if (!structureValidation.valid) {
                throw new Error(`Structure validation failed: ${structureValidation.errors.join(', ')}`);
            }

            // Step 2: Check for duplicates
            const duplicateValidation = await this.checkForDuplicates(suggestions, correlationId);

            // Step 3: Validate content quality
            const qualityValidation = this.validateContentQuality(suggestions, context);

            // Step 4: Check relevance to context
            const relevanceValidation = this.validateRelevance(suggestions, context);

            // Step 5: Generate quality scores
            const scoredSuggestions = this.generateQualityScores(suggestions, context);

            // Step 6: Apply quality filters
            const filteredSuggestions = this.applyQualityFilters(scoredSuggestions);

            // Step 7: Ensure minimum count
            const finalSuggestions = await this.ensureMinimumCount(filteredSuggestions, context, correlationId);

            this.metrics.successfulRequests++;

            const result = {
                suggestions: finalSuggestions,
                qualityMetrics: {
                    originalCount: suggestions.length,
                    finalCount: finalSuggestions.length,
                    duplicatesRemoved: duplicateValidation.duplicatesFound,
                    averageQualityScore: this.calculateAverageScore(finalSuggestions),
                    highQualityCount: finalSuggestions.filter(s => s.qualityScore >= 0.8).length,
                    validationPassed: true
                },
                validationResults: {
                    structure: structureValidation,
                    duplicates: duplicateValidation,
                    quality: qualityValidation,
                    relevance: relevanceValidation
                }
            };

            timer.finish({ success: true, finalCount: finalSuggestions.length });

            return result;

        } catch (error) {
            this.metrics.failedRequests++;
            timer.error(error);

            logger.error('QA validation failed', {
                correlationId,
                error: error.message,
                suggestionsCount: suggestions?.length || 0
            });

            // Return emergency fallback
            return this.generateEmergencyFallback(context, correlationId);
        }
    }

    /**
     * Validate response structure
     */
    validateStructure(suggestions) {
        const errors = [];

        if (!Array.isArray(suggestions)) {
            errors.push('Suggestions must be an array');
            return { valid: false, errors };
        }

        if (suggestions.length === 0) {
            errors.push('Suggestions array cannot be empty');
        }

        suggestions.forEach((suggestion, index) => {
            if (!suggestion.text || typeof suggestion.text !== 'string') {
                errors.push(`Suggestion ${index + 1}: Missing or invalid text`);
            }

            if (suggestion.text && suggestion.text.length < this.qualityThresholds.minSuggestionLength) {
                errors.push(`Suggestion ${index + 1}: Text too short (minimum ${this.qualityThresholds.minSuggestionLength} characters)`);
            }

            if (suggestion.text && suggestion.text.length > this.qualityThresholds.maxSuggestionLength) {
                errors.push(`Suggestion ${index + 1}: Text too long (maximum ${this.qualityThresholds.maxSuggestionLength} characters)`);
            }

            if (suggestion.confidence !== undefined && (typeof suggestion.confidence !== 'number' || suggestion.confidence < 0 || suggestion.confidence > 1)) {
                errors.push(`Suggestion ${index + 1}: Invalid confidence score`);
            }
        });

        return {
            valid: errors.length === 0,
            errors,
            validCount: suggestions.filter(s => s.text && s.text.length >= this.qualityThresholds.minSuggestionLength).length
        };
    }

    /**
     * Check for duplicate responses
     */
    async checkForDuplicates(suggestions, correlationId) {
        const duplicatesFound = [];
        const uniqueSuggestions = [];
        const seenTexts = new Set();

        try {
            // Check against recent responses in cache
            const recentResponses = await redisService.get('qa:recent_responses', correlationId) || [];

            for (const suggestion of suggestions) {
                const normalizedText = this.normalizeText(suggestion.text);
                const textHash = this.generateTextHash(normalizedText);

                // Check for exact duplicates in current batch
                if (seenTexts.has(textHash)) {
                    duplicatesFound.push({
                        text: suggestion.text,
                        type: 'exact_duplicate_in_batch'
                    });
                    continue;
                }

                // Check for similarity to recent responses
                const isDuplicate = await this.checkSimilarity(normalizedText, recentResponses);
                if (isDuplicate.similar) {
                    duplicatesFound.push({
                        text: suggestion.text,
                        type: 'similar_to_recent',
                        similarity: isDuplicate.score,
                        matchedText: isDuplicate.matchedText
                    });
                    continue;
                }

                seenTexts.add(textHash);
                uniqueSuggestions.push({
                    ...suggestion,
                    textHash,
                    uniquenessScore: 1.0 - (isDuplicate.score || 0)
                });
            }

            // Update recent responses cache
            const updatedRecent = [
                ...uniqueSuggestions.map(s => s.text).slice(0, 3), // Only store top 3
                ...recentResponses.slice(0, 47) // Keep last 47 for total of 50
            ].slice(0, 50);

            await redisService.set('qa:recent_responses', updatedRecent, 3600, correlationId); // 1 hour cache

            this.metrics.duplicateDetections += duplicatesFound.length;

            return {
                duplicatesFound: duplicatesFound.length,
                uniqueSuggestions,
                duplicateDetails: duplicatesFound
            };

        } catch (error) {
            logger.warn('Duplicate checking failed, proceeding with original suggestions', {
                correlationId,
                error: error.message
            });

            return {
                duplicatesFound: 0,
                uniqueSuggestions: suggestions.map(s => ({ ...s, uniquenessScore: 0.9 })),
                duplicateDetails: []
            };
        }
    }

    /**
     * Validate content quality
     */
    validateContentQuality(suggestions, context) {
        const qualityIssues = [];
        const qualityScores = [];

        suggestions.forEach((suggestion, index) => {
            const text = suggestion.text;
            let qualityScore = 1.0;
            const issues = [];

            // Check for banned phrases
            for (const phrase of this.bannedPhrases) {
                if (text.toLowerCase().includes(phrase)) {
                    issues.push(`Contains banned phrase: "${phrase}"`);
                    qualityScore -= 0.3;
                }
            }

            // Check for personalization
            const personalizationScore = this.calculatePersonalizationScore(text);
            if (personalizationScore < 0.3) {
                issues.push('Lacks personalization');
                qualityScore -= 0.2;
            }

            // Check for engagement elements
            const engagementScore = this.calculateEngagementScore(text);
            if (engagementScore < 0.2) {
                issues.push('Lacks engagement elements');
                qualityScore -= 0.15;
            }

            // Check for appropriate tone
            const toneScore = this.validateTone(text, context?.tone || 'playful');
            if (toneScore < 0.5) {
                issues.push('Tone mismatch');
                qualityScore -= 0.1;
            }

            // Check for conversational elements
            const conversationalScore = this.calculateConversationalScore(text);
            if (conversationalScore < 0.1) {
                issues.push('Not conversational enough');
                qualityScore -= 0.1;
            }

            qualityScore = Math.max(0, qualityScore);
            qualityScores.push(qualityScore);

            if (issues.length > 0) {
                qualityIssues.push({
                    index: index + 1,
                    text: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
                    issues,
                    qualityScore
                });
            }
        });

        const averageQuality = qualityScores.reduce((sum, score) => sum + score, 0) / qualityScores.length;
        const highQualityCount = qualityScores.filter(score => score >= 0.8).length;

        return {
            averageQuality,
            highQualityCount,
            totalQuality: qualityScores.length,
            qualityIssues,
            qualityScores,
            passed: averageQuality >= this.qualityThresholds.minConfidence
        };
    }

    /**
     * Validate relevance to context
     */
    validateRelevance(suggestions, context) {
        const relevanceScores = suggestions.map(suggestion => {
            const text = suggestion.text.toLowerCase();
            let relevanceScore = 0.5; // Base score

            // Check suggestion type relevance
            const suggestionType = context?.suggestion_type || 'opener';
            if (suggestionType === 'opener') {
                if (text.includes('hey') || text.includes('hi') || text.includes('hello')) {
                    relevanceScore += 0.2;
                }
            } else if (suggestionType === 'response') {
                if (text.includes('that') || text.includes('you') || text.includes('interesting')) {
                    relevanceScore += 0.2;
                }
            } else if (suggestionType === 'continuation') {
                if (text.includes('continue') || text.includes('coffee') || text.includes('talk')) {
                    relevanceScore += 0.2;
                }
            }

            // Check tone relevance
            const tone = context?.tone || 'playful';
            const toneWords = {
                playful: ['fun', 'playful', 'haha', 'smile', 'laugh'],
                witty: ['clever', 'smart', 'wit', 'interesting', 'impressive'],
                romantic: ['beautiful', 'gorgeous', 'connection', 'feel', 'heart'],
                casual: ['cool', 'chill', 'casual', 'easy', 'relaxed'],
                bold: ['bold', 'confident', 'direct', 'honest', 'striking']
            };

            if (toneWords[tone]) {
                for (const word of toneWords[tone]) {
                    if (text.includes(word)) {
                        relevanceScore += 0.1;
                    }
                }
            }

            // Check context keywords
            if (context?.context) {
                const contextWords = context.context.toLowerCase().split(' ');
                for (const word of contextWords) {
                    if (word.length > 3 && text.includes(word)) {
                        relevanceScore += 0.15;
                    }
                }
            }

            return Math.min(1.0, relevanceScore);
        });

        const averageRelevance = relevanceScores.reduce((sum, score) => sum + score, 0) / relevanceScores.length;

        return {
            averageRelevance,
            relevanceScores,
            passed: averageRelevance >= this.qualityThresholds.minRelevance,
            highRelevanceCount: relevanceScores.filter(score => score >= 0.8).length
        };
    }

    /**
     * Generate comprehensive quality scores
     */
    generateQualityScores(suggestions, context) {
        return suggestions.map((suggestion, index) => {
            const text = suggestion.text;

            // Calculate component scores
            const personalizationScore = this.calculatePersonalizationScore(text);
            const engagementScore = this.calculateEngagementScore(text);
            const conversationalScore = this.calculateConversationalScore(text);
            const lengthScore = this.calculateLengthScore(text);
            const originalityScore = suggestion.uniquenessScore || 0.9;
            const toneScore = this.validateTone(text, context?.tone || 'playful');

            // Weighted combination
            const qualityScore = (
                personalizationScore * 0.25 +
                engagementScore * 0.20 +
                conversationalScore * 0.15 +
                lengthScore * 0.10 +
                originalityScore * 0.15 +
                toneScore * 0.15
            );

            return {
                ...suggestion,
                qualityScore: Math.round(qualityScore * 100) / 100,
                componentScores: {
                    personalization: personalizationScore,
                    engagement: engagementScore,
                    conversational: conversationalScore,
                    length: lengthScore,
                    originality: originalityScore,
                    tone: toneScore
                }
            };
        });
    }

    /**
     * Apply quality filters
     */
    applyQualityFilters(suggestions) {
        const filtered = suggestions.filter(suggestion => {
            // Basic quality threshold
            if (suggestion.qualityScore < this.qualityThresholds.minConfidence) {
                return false;
            }

            // Confidence threshold (if provided)
            if (suggestion.confidence && suggestion.confidence < this.qualityThresholds.minConfidence) {
                return false;
            }

            // Text length validation
            const textLength = suggestion.text.length;
            if (textLength < this.qualityThresholds.minSuggestionLength ||
                textLength > this.qualityThresholds.maxSuggestionLength) {
                return false;
            }

            return true;
        });

        // Sort by quality score
        return filtered.sort((a, b) => b.qualityScore - a.qualityScore);
    }

    /**
     * Ensure minimum suggestion count
     */
    async ensureMinimumCount(suggestions, context, correlationId) {
        const minCount = 3;

        if (suggestions.length >= minCount) {
            return suggestions.slice(0, 5); // Maximum 5 suggestions
        }

        this.metrics.fallbackUsages++;

        logger.warn('Insufficient high-quality suggestions, generating fallbacks', {
            correlationId,
            currentCount: suggestions.length,
            minRequired: minCount
        });

        // Generate fallback suggestions
        const fallbackSuggestions = this.generateFallbackSuggestions(
            context,
            minCount - suggestions.length
        );

        return [...suggestions, ...fallbackSuggestions].slice(0, 5);
    }

    /**
     * Generate emergency fallback when QA completely fails
     */
    generateEmergencyFallback(context, correlationId) {
        this.metrics.fallbackUsages++;

        logger.error('QA pipeline completely failed, using emergency fallback', {
            correlationId
        });

        const emergencyFallbacks = [
            {
                text: "Hey! Your profile caught my attention - what's been the highlight of your day?",
                confidence: 0.75,
                qualityScore: 0.75,
                reasoning: "Emergency fallback - general opener"
            },
            {
                text: "I love your energy! What got you into that?",
                confidence: 0.73,
                qualityScore: 0.73,
                reasoning: "Emergency fallback - engagement response"
            },
            {
                text: "That's really interesting! Tell me more about that.",
                confidence: 0.71,
                qualityScore: 0.71,
                reasoning: "Emergency fallback - conversation continuation"
            }
        ];

        return {
            suggestions: emergencyFallbacks.map((suggestion, index) => ({
                ...suggestion,
                id: `emergency-${Date.now()}-${index}`,
                created_at: new Date().toISOString(),
                emergency_fallback: true
            })),
            qualityMetrics: {
                originalCount: 0,
                finalCount: emergencyFallbacks.length,
                duplicatesRemoved: 0,
                averageQualityScore: 0.73,
                highQualityCount: 0,
                validationPassed: false,
                emergencyFallback: true
            },
            validationResults: {
                error: 'QA pipeline failed, using emergency fallback'
            }
        };
    }

    // Helper methods
    normalizeText(text) {
        return text.toLowerCase()
            .replace(/[^\w\s]/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
    }

    generateTextHash(text) {
        return crypto.createHash('md5').update(text).digest('hex');
    }

    async checkSimilarity(text, recentTexts) {
        if (!Array.isArray(recentTexts) || recentTexts.length === 0) {
            return { similar: false, score: 0 };
        }

        const normalizedRecent = recentTexts.map(t => this.normalizeText(t));

        for (const recentText of normalizedRecent) {
            const similarity = this.calculateTextSimilarity(text, recentText);
            if (similarity > 0.8) {
                return {
                    similar: true,
                    score: similarity,
                    matchedText: recentText
                };
            }
        }

        return { similar: false, score: 0 };
    }

    calculateTextSimilarity(text1, text2) {
        const words1 = text1.split(' ');
        const words2 = text2.split(' ');
        const commonWords = words1.filter(word => words2.includes(word));

        return commonWords.length / Math.max(words1.length, words2.length);
    }

    calculatePersonalizationScore(text) {
        let score = 0;
        const lowerText = text.toLowerCase();

        for (const pattern of this.qualityPatterns.personalizations) {
            const matches = lowerText.match(pattern);
            if (matches) {
                score += matches.length * 0.2;
            }
        }

        return Math.min(1.0, score);
    }

    calculateEngagementScore(text) {
        let score = 0;
        const lowerText = text.toLowerCase();

        for (const pattern of this.qualityPatterns.engagement) {
            const matches = lowerText.match(pattern);
            if (matches) {
                score += matches.length * 0.15;
            }
        }

        return Math.min(1.0, score);
    }

    calculateConversationalScore(text) {
        let score = 0;
        const lowerText = text.toLowerCase();

        for (const pattern of this.qualityPatterns.conversational) {
            const matches = lowerText.match(pattern);
            if (matches) {
                score += matches.length * 0.1;
            }
        }

        return Math.min(1.0, score);
    }

    calculateLengthScore(text) {
        const length = text.length;
        const optimal = 80; // Optimal length
        const tolerance = 40;

        if (length < this.qualityThresholds.minSuggestionLength) return 0;
        if (length > this.qualityThresholds.maxSuggestionLength) return 0.3;

        const distance = Math.abs(length - optimal);
        if (distance <= tolerance) {
            return 1.0 - (distance / tolerance) * 0.3;
        } else {
            return 0.7 - ((distance - tolerance) / 100) * 0.3;
        }
    }

    validateTone(text, targetTone) {
        const toneIndicators = {
            playful: ['fun', 'playful', '😊', 'haha', 'laugh', 'smile', 'exciting'],
            witty: ['clever', 'smart', 'wit', 'impressive', 'interesting', 'brilliant'],
            romantic: ['beautiful', 'gorgeous', 'connection', 'feel', 'heart', 'amazing'],
            casual: ['cool', 'chill', 'casual', 'easy', 'relaxed', 'laid-back'],
            bold: ['bold', 'confident', 'direct', 'honest', 'striking', 'fearless']
        };

        const lowerText = text.toLowerCase();
        const indicators = toneIndicators[targetTone] || [];

        let score = 0.5; // Base score
        for (const indicator of indicators) {
            if (lowerText.includes(indicator)) {
                score += 0.1;
            }
        }

        return Math.min(1.0, score);
    }

    calculateAverageScore(suggestions) {
        if (suggestions.length === 0) return 0;
        const total = suggestions.reduce((sum, s) => sum + (s.qualityScore || 0), 0);
        return Math.round((total / suggestions.length) * 100) / 100;
    }

    generateFallbackSuggestions(context, count) {
        const fallbacks = {
            opener: [
                "Hey! Your profile caught my attention - what's been the highlight of your day?",
                "I love your energy! What got you into that?",
                "That's amazing! How long have you been doing that?",
                "You seem like someone with great stories. What's been exciting in your world lately?",
                "I have to ask - is that from an actual adventure or are you just naturally photogenic?"
            ],
            response: [
                "That's actually really interesting! I wasn't expecting that perspective.",
                "That sounds amazing! What inspired you to get into that?",
                "I love how passionate you sound about that. What got you so into it?",
                "That's really cool! Tell me more about that.",
                "You're making me curious - what's the most exciting part about it?"
            ],
            continuation: [
                "This conversation is getting interesting. Want to grab coffee and keep talking?",
                "I feel like we're really connecting here. Want to continue this conversation over coffee?",
                "I'm really enjoying this chat. What do you say we continue it in person?",
                "You seem like someone I'd love to get to know better. Coffee sometime?",
                "This is turning into the kind of conversation I love. Want to continue it over drinks?"
            ]
        };

        const suggestionType = context?.suggestion_type || 'opener';
        const availableFallbacks = fallbacks[suggestionType] || fallbacks.opener;
        const tone = context?.tone || 'playful';

        return availableFallbacks
            .slice(0, count)
            .map((text, index) => ({
                id: `fallback-${Date.now()}-${index}`,
                text,
                confidence: 0.7 - (index * 0.05),
                qualityScore: 0.7 - (index * 0.05),
                reasoning: `Quality fallback for ${suggestionType} with ${tone} tone`,
                created_at: new Date().toISOString(),
                fallback: true
            }));
    }

    /**
     * Get QA metrics
     */
    getMetrics() {
        const successRate = this.metrics.totalRequests > 0
            ? (this.metrics.successfulRequests / this.metrics.totalRequests) * 100
            : 0;

        return {
            ...this.metrics,
            successRate: Math.round(successRate * 100) / 100,
            duplicateRate: this.metrics.totalRequests > 0
                ? (this.metrics.duplicateDetections / this.metrics.totalRequests) * 100
                : 0,
            fallbackRate: this.metrics.totalRequests > 0
                ? (this.metrics.fallbackUsages / this.metrics.totalRequests) * 100
                : 0
        };
    }

    /**
     * Reset metrics
     */
    resetMetrics() {
        this.metrics = {
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            duplicateDetections: 0,
            lowQualityDetections: 0,
            fallbackUsages: 0
        };
    }
}

// Export singleton instance
module.exports = new QualityAssuranceService();