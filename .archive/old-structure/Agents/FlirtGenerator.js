/**
 * FlirtGenerator.js - AI Sub-Agent for Contextual Flirt Suggestion Generation
 *
 * Generates personalized flirt suggestions with playful, humorous, and sincere tones
 * while maintaining 280 character limit and providing safety ratings.
 */

const axios = require('axios');

class FlirtGenerator {
    constructor() {
        this.grokApiKey = process.env.GROK_API_KEY || 'REMOVED_XAI_KEY';
        this.apiUrl = 'https://api.x.ai/v1/chat/completions';
        this.characterLimit = 280;

        // Tone templates for different flirt styles
        this.toneTemplates = {
            playful: {
                characteristics: 'lighthearted, teasing, fun, energetic',
                examples: ['Well, this is unexpected...', 'I see what you did there 😏', 'Plot twist!'],
                avoid: 'overly serious topics, negativity, heavy subjects'
            },
            humorous: {
                characteristics: 'witty, clever, amusing, light banter',
                examples: ['My therapist said I need to talk to more interesting people... so here I am', 'I was going to make a chemistry joke, but I know I wouldn\'t get a reaction'],
                avoid: 'mean-spirited jokes, controversial topics, sarcasm that could hurt'
            },
            sincere: {
                characteristics: 'genuine, thoughtful, authentic, warm',
                examples: ['I really appreciate how thoughtful your messages are', 'There\'s something really refreshing about talking with you'],
                avoid: 'overly intense declarations, fake compliments, generic statements'
            },
            intellectual: {
                characteristics: 'thoughtful, curious, engaging, sophisticated',
                examples: ['That\'s a fascinating perspective on...', 'I love how you think about...'],
                avoid: 'condescending tone, showing off, overly complex language'
            },
            adventurous: {
                characteristics: 'bold, exciting, spontaneous, confident',
                examples: ['Life\'s too short for boring conversations', 'Ready for an adventure?'],
                avoid: 'reckless suggestions, inappropriate boldness, pressuring'
            }
        };

        // Safety guidelines
        this.safetyGuidelines = {
            prohibited: [
                'sexual content', 'explicit language', 'harassment', 'discrimination',
                'personal information requests', 'meeting immediately', 'financial requests',
                'illegal activities', 'violent content', 'hate speech'
            ],
            cautionFlags: [
                'overly personal questions early on', 'appearance-focused comments',
                'assumptions about lifestyle', 'pushing for quick meetups',
                'generic pickup lines', 'overly forward suggestions'
            ],
            recommended: [
                'common interests', 'thoughtful questions', 'genuine compliments',
                'humor that\'s inclusive', 'conversation starters', 'mutual interests'
            ]
        };
    }

    /**
     * Generate contextual flirt suggestions
     * @param {Object} context - Conversation context and user preferences
     * @returns {Promise<Object>} Generated suggestions with metadata
     */
    async generateFlirts(context) {
        try {
            // Validate and normalize input
            const normalizedContext = this.normalizeContext(context);

            // Generate multiple suggestions with different tones
            const suggestions = await this.generateMultipleSuggestions(normalizedContext);

            // Apply safety filtering and rating
            const safeSuggestions = suggestions.map(suggestion =>
                this.applySafetyFilter(suggestion)
            ).filter(suggestion => suggestion.safetyRating >= 6); // Only include safe suggestions

            // Rank suggestions by relevance and personalization
            const rankedSuggestions = this.rankSuggestions(safeSuggestions, normalizedContext);

            return {
                success: true,
                suggestions: rankedSuggestions.slice(0, 6), // Return top 6 suggestions
                context: normalizedContext,
                metadata: {
                    totalGenerated: suggestions.length,
                    safetyFiltered: suggestions.length - safeSuggestions.length,
                    generatedAt: new Date().toISOString(),
                    modelUsed: 'grok-beta'
                }
            };

        } catch (error) {
            console.error('Flirt generation error:', error);
            return {
                success: false,
                error: error.message,
                fallbackSuggestions: this.getFallbackSuggestions(context)
            };
        }
    }

    /**
     * Generate multiple suggestions using Grok API
     * @param {Object} context - Normalized context
     * @returns {Promise<Array>} Generated suggestions
     */
    async generateMultipleSuggestions(context) {
        const prompt = this.buildGenerationPrompt(context);

        const response = await axios.post(this.apiUrl, {
            model: 'grok-beta',
            messages: [
                {
                    role: 'system',
                    content: this.getSystemPrompt()
                },
                {
                    role: 'user',
                    content: prompt
                }
            ],
            max_tokens: 1500,
            temperature: 0.8,
            top_p: 0.9
        }, {
            headers: {
                'Authorization': `Bearer ${this.grokApiKey}`,
                'Content-Type': 'application/json'
            }
        });

        const responseText = response.data.choices[0].message.content;
        return this.parseGeneratedSuggestions(responseText, context);
    }

    /**
     * Build generation prompt for Grok API
     * @param {Object} context - Conversation context
     * @returns {string} Formatted prompt
     */
    buildGenerationPrompt(context) {
        const {
            conversationStage,
            personalityInsights,
            userPreferences,
            conversationHistory,
            platform,
            timeOfDay
        } = context;

        return `
Generate 8 flirt suggestions for this dating conversation context:

**CONVERSATION CONTEXT:**
- Stage: ${conversationStage}
- Platform: ${platform}
- Time: ${timeOfDay}
- User's personality: ${personalityInsights?.communicationStyle || 'friendly'}
- Humor preference: ${personalityInsights?.humorType || 'balanced'}

**USER PREFERENCES:**
- Preferred styles: ${userPreferences?.styles?.map(s => s.style).join(', ') || 'playful, sincere, humorous'}
- Preferred topics: ${userPreferences?.topics?.map(t => t.topic).join(', ') || 'common interests, travel, humor'}
- Risk tolerance: ${userPreferences?.riskTolerance || 0.5}/1.0
- Creativity level: ${userPreferences?.creativityLevel || 0.6}/1.0

**CONVERSATION CONTEXT:**
${conversationHistory ? `Recent messages: ${conversationHistory.slice(-3).join(' | ')}` : 'Starting new conversation'}

**REQUIREMENTS:**
1. Generate exactly 8 suggestions in different tones: playful, humorous, sincere, intellectual, adventurous, casual, witty, warm
2. Each suggestion must be under 280 characters
3. Match the conversation stage appropriately
4. Consider user's personality and preferences
5. Be respectful, inclusive, and appropriate
6. No generic pickup lines - make them contextual and unique

**OUTPUT FORMAT:**
Return as JSON array with this structure:
[
  {
    "text": "suggestion text here",
    "tone": "playful",
    "topics": ["humor", "travel"],
    "characterCount": 45,
    "contextualRelevance": 0.9,
    "creativity": 0.7,
    "appropriateness": 0.95
  }
]

Generate suggestions now:`;
    }

    /**
     * Get system prompt for Grok API
     * @returns {string} System prompt
     */
    getSystemPrompt() {
        return `You are an expert at generating contextual, respectful, and engaging flirt suggestions for dating conversations. Your suggestions should be:

1. RESPECTFUL: Never objectifying, always considerate
2. CONTEXTUAL: Based on the specific conversation and person
3. CREATIVE: Unique and personalized, not generic
4. APPROPRIATE: Safe for all audiences, no explicit content
5. ENGAGING: Designed to continue meaningful conversation
6. DIVERSE: Different tones and approaches
7. BRIEF: Under 280 characters each

Focus on building genuine connections through wit, warmth, shared interests, and thoughtful conversation starters.`;
    }

    /**
     * Parse generated suggestions from API response
     * @param {string} responseText - Raw API response
     * @param {Object} context - Generation context
     * @returns {Array} Parsed suggestions
     */
    parseGeneratedSuggestions(responseText, context) {
        try {
            // Extract JSON from response
            const jsonMatch = responseText.match(/\[[\s\S]*\]/);
            if (!jsonMatch) {
                throw new Error('No valid JSON array found in response');
            }

            const suggestions = JSON.parse(jsonMatch[0]);

            return suggestions.map((suggestion, index) => ({
                id: `flirt_${Date.now()}_${index}`,
                text: suggestion.text || '',
                tone: suggestion.tone || 'friendly',
                topics: suggestion.topics || [],
                characterCount: suggestion.text?.length || 0,
                contextualRelevance: this.clampValue(suggestion.contextualRelevance || 0.7, 0, 1),
                creativity: this.clampValue(suggestion.creativity || 0.6, 0, 1),
                appropriateness: this.clampValue(suggestion.appropriateness || 0.8, 0, 1),
                generatedAt: new Date().toISOString(),

                // Additional metadata
                conversationStage: context.conversationStage,
                platform: context.platform,
                userPreferences: context.userPreferences
            }));

        } catch (error) {
            console.error('Error parsing suggestions:', error);
            return this.generateFallbackSuggestions(context);
        }
    }

    /**
     * Apply safety filtering and rating to suggestions
     * @param {Object} suggestion - Individual suggestion
     * @returns {Object} Suggestion with safety rating
     */
    applySafetyFilter(suggestion) {
        let safetyRating = 10; // Start with perfect score
        const text = suggestion.text.toLowerCase();
        const concerns = [];

        // Check for prohibited content
        this.safetyGuidelines.prohibited.forEach(prohibited => {
            if (text.includes(prohibited.toLowerCase())) {
                safetyRating -= 4;
                concerns.push(`Contains prohibited content: ${prohibited}`);
            }
        });

        // Check for caution flags
        this.safetyGuidelines.cautionFlags.forEach(flag => {
            if (this.checkCautionFlag(text, flag)) {
                safetyRating -= 1;
                concerns.push(`Caution flag: ${flag}`);
            }
        });

        // Check character limit
        if (suggestion.characterCount > this.characterLimit) {
            safetyRating -= 2;
            concerns.push('Exceeds character limit');
        }

        // Check appropriateness score
        if (suggestion.appropriateness < 0.7) {
            safetyRating -= 2;
            concerns.push('Low appropriateness score');
        }

        // Ensure minimum rating
        safetyRating = Math.max(0, safetyRating);

        return {
            ...suggestion,
            safetyRating: safetyRating,
            safetyConcerns: concerns,
            isApproved: safetyRating >= 6
        };
    }

    /**
     * Check for specific caution flags in text
     * @param {string} text - Text to check
     * @param {string} flag - Caution flag to check for
     * @returns {boolean} Whether flag is present
     */
    checkCautionFlag(text, flag) {
        const flagChecks = {
            'overly personal questions early on': (text) =>
                text.includes('where do you live') || text.includes('what\'s your address') || text.includes('send me a photo'),
            'appearance-focused comments': (text) =>
                text.includes('sexy') || text.includes('hot') || text.includes('beautiful body'),
            'assumptions about lifestyle': (text) =>
                text.includes('you must be') || text.includes('girls like you') || text.includes('guys like you'),
            'pushing for quick meetups': (text) =>
                text.includes('meet tonight') || text.includes('come over') || text.includes('my place'),
            'generic pickup lines': (text) =>
                text.includes('did it hurt when you fell') || text.includes('are you a magician'),
            'overly forward suggestions': (text) =>
                text.includes('let\'s get physical') || text.includes('bedroom') || text.includes('hookup')
        };

        const checkFunction = flagChecks[flag];
        return checkFunction ? checkFunction(text) : false;
    }

    /**
     * Rank suggestions by relevance and personalization
     * @param {Array} suggestions - Filtered suggestions
     * @param {Object} context - Generation context
     * @returns {Array} Ranked suggestions
     */
    rankSuggestions(suggestions, context) {
        return suggestions.map(suggestion => {
            let score = 0;

            // Base scores
            score += suggestion.contextualRelevance * 0.3;
            score += suggestion.creativity * 0.2;
            score += suggestion.appropriateness * 0.2;
            score += (suggestion.safetyRating / 10) * 0.2;

            // Preference matching
            if (context.userPreferences?.styles) {
                const styleMatch = context.userPreferences.styles.find(s => s.style === suggestion.tone);
                if (styleMatch) {
                    score += styleMatch.preference_score * 0.1;
                }
            }

            // Topic matching
            if (context.userPreferences?.topics && suggestion.topics) {
                const topicMatches = suggestion.topics.filter(topic =>
                    context.userPreferences.topics.some(t => t.topic === topic)
                );
                score += (topicMatches.length / suggestion.topics.length) * 0.1;
            }

            // Stage appropriateness
            score += this.calculateStageAppropriatenesss(suggestion.tone, context.conversationStage) * 0.1;

            return {
                ...suggestion,
                relevanceScore: this.clampValue(score, 0, 1),
                ranking: 0 // Will be set after sorting
            };
        }).sort((a, b) => b.relevanceScore - a.relevanceScore)
          .map((suggestion, index) => ({
              ...suggestion,
              ranking: index + 1
          }));
    }

    /**
     * Calculate how appropriate a tone is for a conversation stage
     * @param {string} tone - Suggestion tone
     * @param {string} stage - Conversation stage
     * @returns {number} Appropriateness score 0-1
     */
    calculateStageAppropriatenesss(tone, stage) {
        const stageAppropriatenessMap = {
            'opening': {
                'playful': 0.9,
                'humorous': 0.8,
                'sincere': 0.7,
                'casual': 0.9,
                'witty': 0.8,
                'warm': 0.6,
                'intellectual': 0.5,
                'adventurous': 0.4
            },
            'building_rapport': {
                'sincere': 0.9,
                'intellectual': 0.8,
                'humorous': 0.8,
                'warm': 0.9,
                'playful': 0.7,
                'casual': 0.8,
                'witty': 0.7,
                'adventurous': 0.5
            },
            'flirting': {
                'playful': 0.9,
                'humorous': 0.8,
                'adventurous': 0.9,
                'witty': 0.8,
                'warm': 0.7,
                'sincere': 0.6,
                'casual': 0.7,
                'intellectual': 0.5
            },
            'planning_meetup': {
                'sincere': 0.9,
                'adventurous': 0.8,
                'warm': 0.8,
                'casual': 0.9,
                'playful': 0.6,
                'humorous': 0.6,
                'witty': 0.5,
                'intellectual': 0.7
            }
        };

        return stageAppropriatenessMap[stage]?.[tone] || 0.5;
    }

    /**
     * Normalize and validate context data
     * @param {Object} context - Raw context
     * @returns {Object} Normalized context
     */
    normalizeContext(context) {
        return {
            conversationStage: context.conversationStage || 'opening',
            personalityInsights: context.personalityInsights || {},
            userPreferences: context.userPreferences || {},
            conversationHistory: Array.isArray(context.conversationHistory) ?
                context.conversationHistory : [],
            platform: context.platform || 'dating_app',
            timeOfDay: context.timeOfDay || 'afternoon',
            userId: context.userId,
            targetAge: context.targetAge,
            userAge: context.userAge
        };
    }

    /**
     * Generate fallback suggestions when API fails
     * @param {Object} context - Generation context
     * @returns {Array} Fallback suggestions
     */
    generateFallbackSuggestions(context) {
        const stage = context.conversationStage || 'opening';
        const fallbacks = this.getFallbacksByStage(stage);

        return fallbacks.map((suggestion, index) => ({
            id: `fallback_${Date.now()}_${index}`,
            text: suggestion.text,
            tone: suggestion.tone,
            topics: suggestion.topics,
            characterCount: suggestion.text.length,
            contextualRelevance: 0.6,
            creativity: 0.5,
            appropriateness: 0.9,
            safetyRating: 9,
            safetyConcerns: [],
            isApproved: true,
            isFallback: true,
            relevanceScore: 0.6,
            ranking: index + 1,
            generatedAt: new Date().toISOString()
        }));
    }

    /**
     * Get fallback suggestions by conversation stage
     * @param {string} stage - Conversation stage
     * @returns {Array} Stage-appropriate fallbacks
     */
    getFallbacksByStage(stage) {
        const fallbacks = {
            'opening': [
                { text: "I have to ask... what's the story behind that photo of yours?", tone: 'playful', topics: ['curiosity'] },
                { text: "Your profile made me smile - especially the part about...", tone: 'sincere', topics: ['profile'] },
                { text: "Well, this is refreshing - someone who actually reads profiles!", tone: 'humorous', topics: ['humor'] },
                { text: "I couldn't help but notice we both love... coincidence or good taste?", tone: 'witty', topics: ['common_interests'] }
            ],
            'building_rapport': [
                { text: "I love how you think about things differently", tone: 'sincere', topics: ['personality'] },
                { text: "This conversation is exactly what I needed today", tone: 'warm', topics: ['connection'] },
                { text: "You know what's interesting about what you just said?", tone: 'intellectual', topics: ['curiosity'] },
                { text: "I'm starting to think we might be trouble together 😏", tone: 'playful', topics: ['chemistry'] }
            ],
            'flirting': [
                { text: "You're dangerously good at making me smile", tone: 'playful', topics: ['chemistry'] },
                { text: "I should probably warn you... I'm getting a little addicted to our conversations", tone: 'adventurous', topics: ['connection'] },
                { text: "Is it just me, or is there some serious chemistry happening here?", tone: 'witty', topics: ['chemistry'] },
                { text: "You know what would be perfect right about now? Coffee and continuing this in person", tone: 'sincere', topics: ['meetup'] }
            ],
            'planning_meetup': [
                { text: "I vote we continue this conversation over coffee... when are you free?", tone: 'casual', topics: ['meetup'] },
                { text: "I know this great little place that would be perfect for us to meet", tone: 'adventurous', topics: ['meetup'] },
                { text: "How about we take this offline and grab a drink?", tone: 'sincere', topics: ['meetup'] },
                { text: "I'm thinking we should meet before I get even more charmed by your messages", tone: 'warm', topics: ['meetup'] }
            ]
        };

        return fallbacks[stage] || fallbacks['opening'];
    }

    /**
     * Clamp numeric value between min and max
     * @param {number} value - Value to clamp
     * @param {number} min - Minimum value
     * @param {number} max - Maximum value
     * @returns {number} Clamped value
     */
    clampValue(value, min, max) {
        return Math.max(min, Math.min(max, value));
    }

    /**
     * Get fallback suggestions for error cases
     * @param {Object} context - Original context
     * @returns {Array} Safe fallback suggestions
     */
    getFallbackSuggestions(context) {
        return [
            {
                id: 'fallback_1',
                text: "Your message made me smile - tell me more about that!",
                tone: 'warm',
                topics: ['encouragement'],
                characterCount: 55,
                safetyRating: 10,
                isApproved: true,
                isFallback: true
            },
            {
                id: 'fallback_2',
                text: "I love how thoughtful your messages are",
                tone: 'sincere',
                topics: ['appreciation'],
                characterCount: 40,
                safetyRating: 10,
                isApproved: true,
                isFallback: true
            },
            {
                id: 'fallback_3',
                text: "This conversation is turning out to be the highlight of my day",
                tone: 'warm',
                topics: ['positivity'],
                characterCount: 67,
                safetyRating: 10,
                isApproved: true,
                isFallback: true
            }
        ];
    }

    /**
     * Validate suggestion meets all requirements
     * @param {Object} suggestion - Suggestion to validate
     * @returns {Object} Validation result
     */
    validateSuggestion(suggestion) {
        const issues = [];

        if (!suggestion.text || suggestion.text.trim().length === 0) {
            issues.push('Text is required');
        }

        if (suggestion.text && suggestion.text.length > this.characterLimit) {
            issues.push(`Exceeds character limit (${suggestion.text.length}/${this.characterLimit})`);
        }

        if (!suggestion.tone || !this.toneTemplates[suggestion.tone]) {
            issues.push('Invalid or missing tone');
        }

        if (suggestion.safetyRating < 6) {
            issues.push('Safety rating too low');
        }

        return {
            valid: issues.length === 0,
            issues: issues
        };
    }

    /**
     * Get generator health status
     * @returns {Promise<Object>} Health status
     */
    async getHealthStatus() {
        try {
            // Test API connectivity
            const response = await axios.post(this.apiUrl, {
                model: 'grok-beta',
                messages: [{ role: 'user', content: 'Test' }],
                max_tokens: 1
            }, {
                headers: {
                    'Authorization': `Bearer ${this.grokApiKey}`,
                    'Content-Type': 'application/json'
                },
                timeout: 5000
            });

            return {
                status: 'healthy',
                apiConnected: true,
                tonesAvailable: Object.keys(this.toneTemplates).length,
                characterLimit: this.characterLimit,
                lastChecked: new Date().toISOString()
            };

        } catch (error) {
            return {
                status: 'unhealthy',
                apiConnected: false,
                error: error.message,
                lastChecked: new Date().toISOString()
            };
        }
    }

    /**
     * Get available tones and their characteristics
     * @returns {Object} Tone information
     */
    getAvailableTones() {
        return Object.entries(this.toneTemplates).map(([tone, template]) => ({
            tone,
            characteristics: template.characteristics,
            examples: template.examples.slice(0, 2), // Limit examples
            appropriateFor: this.getToneAppropriateStages(tone)
        }));
    }

    /**
     * Get stages where a tone is most appropriate
     * @param {string} tone - Tone to check
     * @returns {Array} Appropriate stages
     */
    getToneAppropriateStages(tone) {
        const stages = ['opening', 'building_rapport', 'flirting', 'planning_meetup'];
        return stages.filter(stage =>
            this.calculateStageAppropriatenesss(tone, stage) >= 0.7
        );
    }
}

module.exports = FlirtGenerator;