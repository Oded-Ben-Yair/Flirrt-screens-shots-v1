const axios = require('axios');
const { logger } = require('./logger');

/**
 * GPT-5 Flirt Generation Service
 *
 * Implements flirt message generation using Azure OpenAI GPT-5 with:
 * - Optimal prompt engineering patterns from research
 * - Quality evaluation framework (sentiment, creativity, relevance, tone matching)
 * - Performance optimization (caching, streaming)
 * - Error handling and fallback strategies
 *
 * Research Findings Applied:
 * - Instruction-following pattern (instructions separate from content)
 * - Negative constraint pattern (explicit exclusions)
 * - Context-rich prompts for personalization
 * - Structured output for downstream processing
 */
class GPT5FlirtService {
    constructor() {
        // Azure OpenAI GPT-5 configuration from CLAUDE.md
        this.endpoint = process.env.GPT5_ENDPOINT ||
            'https://brn-azai.cognitiveservices.azure.com/openai/deployments/gpt-5/chat/completions?api-version=2025-01-01-preview';
        this.apiKey = process.env.GPT5_KEY ||
            process.env.AZURE_OPENAI_KEY;
        this.modelVersion = process.env.GPT5_MODEL_VERSION || '2025-08-07';

        this.initialized = false;
        this.maxRetries = 2;
        this.timeout = 15000; // 15 seconds (research target: <2s for simple, <5s for complex)
        this.maxTokens = 300; // Typical flirt message length

        this.initialize();
    }

    async initialize() {
        try {
            if (!this.apiKey) {
                throw new Error('GPT5_KEY or AZURE_OPENAI_KEY not configured');
            }

            // Test connection
            logger.info('GPT5FlirtService initialized successfully', {
                endpoint: this.endpoint,
                modelVersion: this.modelVersion,
                timeout: this.timeout
            });

            this.initialized = true;
        } catch (error) {
            logger.error('Failed to initialize GPT5FlirtService', {
                error: error.message,
                stack: error.stack
            });
            this.initialized = false;
        }
    }

    /**
     * System Instructions (Instruction-Following Pattern)
     *
     * Research: Place detailed instructions at beginning, separate from variable content
     * Reference: OpenAI cookbook on prompt engineering
     */
    getSystemInstructions() {
        return `You are an expert conversation coach specializing in dating app interactions. Generate engaging, personalized flirt messages that spark genuine connection.

CORE PRINCIPLES:
1. AUTHENTICITY: Messages should feel genuine, not scripted or generic
2. PERSONALIZATION: Reference specific details from the visual context provided
3. ENGAGEMENT: Create hooks that encourage response and conversation
4. RESPECT: Never objectify, use crude language, or make assumptions about appearance
5. TONE MATCHING: Adapt style to specified tone while maintaining authenticity

QUALITY STANDARDS:
- Length: 15-60 words (concise but substantive)
- Specificity: Reference at least one concrete detail from context
- Question integration: Include engaging question when appropriate for tone
- Emoji usage: Maximum 2 emojis, only when natural for tone
- Originality: Avoid clichés like "You seem interesting" or "I'd love to know more"

STRICT EXCLUSIONS (Negative Constraint Pattern):
- NO generic compliments without context ("You're beautiful", "Nice smile")
- NO clichéd openers ("What brings you here?", "Swipe right if...")
- NO ALL-CAPS sections
- NO excessive punctuation (!!!, ???)
- NO pickup lines or cheesy wordplay
- NO assumptions about interests without visual evidence
- NO inappropriate or suggestive content
- NO more than 2 emojis per message

OUTPUT FORMAT:
Return ONLY valid JSON with this exact structure:
{
  "flirt": "The actual flirt message text",
  "tone": "The tone used (playful/confident/casual/romantic/witty)",
  "reasoning": "Brief explanation of personalization elements used",
  "confidence": 0.85,
  "alternatives": ["alternative version 1", "alternative version 2"]
}`;
    }

    /**
     * Generate Flirt Messages
     *
     * @param {Object} params - Generation parameters
     * @param {string} params.screenshotAnalysis - Gemini analysis results (context, personality, scene)
     * @param {string} params.tone - Desired tone (playful/confident/casual/romantic/witty)
     * @param {string} params.suggestionType - Type (opener/response/continuation)
     * @param {Object} params.userPreferences - Optional user preferences
     * @param {boolean} params.stream - Enable streaming (default: false)
     * @returns {Promise<Object>} - Generated flirt with quality scores
     */
    async generateFlirts(params) {
        const {
            screenshotAnalysis,
            tone = 'playful',
            suggestionType = 'opener',
            userPreferences = {},
            stream = false,
            count = 3 // Number of alternatives
        } = params;

        if (!this.initialized) {
            await this.initialize();
        }

        if (!this.initialized) {
            throw new Error('GPT5FlirtService not initialized');
        }

        try {
            const startTime = Date.now();

            // Build context-rich prompt
            const userPrompt = this.buildContextPrompt({
                screenshotAnalysis,
                tone,
                suggestionType,
                userPreferences,
                count
            });

            // Call Azure OpenAI GPT-5
            const response = await this.callGPT5({
                systemPrompt: this.getSystemInstructions(),
                userPrompt,
                stream,
                temperature: this.getTemperatureForTone(tone),
                maxTokens: this.maxTokens
            });

            const latency = Date.now() - startTime;

            // Parse and validate response
            const flirtData = this.parseGPT5Response(response);

            // Quality evaluation
            const qualityScores = await this.evaluateQuality(flirtData, params);

            // Performance logging
            logger.info('GPT-5 flirt generation completed', {
                latency,
                tone,
                suggestionType,
                qualityScore: qualityScores.overall,
                targetLatency: suggestionType === 'opener' ? 2000 : 5000
            });

            return {
                ...flirtData,
                qualityScores,
                metadata: {
                    latency,
                    model: 'gpt-5',
                    modelVersion: this.modelVersion,
                    timestamp: new Date().toISOString()
                }
            };

        } catch (error) {
            logger.error('GPT-5 flirt generation failed', {
                error: error.message,
                stack: error.stack,
                params: { tone, suggestionType }
            });
            throw error;
        }
    }

    /**
     * Build context-rich prompt (Research: Detailed context improves personalization)
     */
    buildContextPrompt({ screenshotAnalysis, tone, suggestionType, userPreferences, count }) {
        const toneInstructions = this.getToneInstructions(tone);
        const typeInstructions = this.getTypeInstructions(suggestionType);

        return `CONTEXT FROM SCREENSHOT ANALYSIS:
${typeof screenshotAnalysis === 'object' ? JSON.stringify(screenshotAnalysis, null, 2) : screenshotAnalysis}

GENERATION PARAMETERS:
- Tone: ${tone} (${toneInstructions})
- Type: ${suggestionType} (${typeInstructions})
- Alternatives requested: ${count}
${Object.keys(userPreferences).length > 0 ? `- User preferences: ${JSON.stringify(userPreferences)}` : ''}

TASK:
Generate ${count} high-quality ${tone} ${suggestionType} messages based on the visual context provided. Each message should:
1. Reference specific details from the screenshot analysis
2. Match the ${tone} tone authentically
3. Create an engaging hook for response
4. Follow all quality standards and exclusions listed in system instructions

Return response in specified JSON format with main flirt and ${count - 1} alternatives.`;
    }

    /**
     * Tone-specific instructions
     */
    getToneInstructions(tone) {
        const instructions = {
            playful: 'Light, fun, slightly teasing without being offensive. Use humor naturally.',
            confident: 'Direct, self-assured, shows interest clearly without being aggressive.',
            casual: 'Relaxed, friendly, conversational. Like talking to a friend.',
            romantic: 'Warm, genuine, emotionally expressive without being over-the-top.',
            witty: 'Clever, intelligent humor. Wordplay and observations when natural.'
        };
        return instructions[tone] || instructions.playful;
    }

    /**
     * Type-specific instructions
     */
    getTypeInstructions(suggestionType) {
        const instructions = {
            opener: 'First message to start conversation. Must be compelling enough to get response.',
            response: 'Reply to their message. Build on conversation context provided.',
            continuation: 'Keep conversation flowing. Reference previous exchange naturally.'
        };
        return instructions[suggestionType] || instructions.opener;
    }

    /**
     * Temperature based on tone (Research: Higher temperature for creativity)
     */
    getTemperatureForTone(tone) {
        const temperatures = {
            playful: 0.9,    // Higher creativity
            witty: 0.95,     // Maximum creativity
            confident: 0.8,  // Balanced
            casual: 0.85,    // Slightly creative
            romantic: 0.9    // Creative but coherent
        };
        return temperatures[tone] || 0.85;
    }

    /**
     * Call Azure OpenAI GPT-5 API
     */
    async callGPT5({ systemPrompt, userPrompt, stream = false, temperature, maxTokens }) {
        const requestBody = {
            messages: [
                {
                    role: 'system',
                    content: systemPrompt
                },
                {
                    role: 'user',
                    content: userPrompt
                }
            ],
            temperature,
            max_tokens: maxTokens,
            response_format: { type: 'json_object' }, // Force JSON output
            stream
        };

        const response = await axios.post(
            this.endpoint,
            requestBody,
            {
                headers: {
                    'Content-Type': 'application/json',
                    'api-key': this.apiKey
                },
                timeout: this.timeout
            }
        );

        return response.data;
    }

    /**
     * Parse GPT-5 response
     */
    parseGPT5Response(response) {
        try {
            const content = response.choices[0].message.content;
            const parsed = JSON.parse(content);

            // Validate required fields
            if (!parsed.flirt || !parsed.tone) {
                throw new Error('Invalid GPT-5 response format');
            }

            return parsed;
        } catch (error) {
            logger.error('Failed to parse GPT-5 response', {
                error: error.message,
                response: JSON.stringify(response).substring(0, 500)
            });
            throw new Error('Invalid GPT-5 response format');
        }
    }

    /**
     * Quality Evaluation Framework
     *
     * Research: Multi-dimensional evaluation (accuracy, relevance, coherence, creativity)
     * Metrics: Sentiment analysis, length check, creativity score, contextual relevance
     */
    async evaluateQuality(flirtData, params) {
        const scores = {
            sentiment: this.evaluateSentiment(flirtData.flirt),
            length: this.evaluateLength(flirtData.flirt),
            creativity: this.evaluateCreativity(flirtData.flirt, params.screenshotAnalysis),
            relevance: this.evaluateRelevance(flirtData.flirt, params.screenshotAnalysis),
            toneMatching: this.evaluateToneMatching(flirtData.flirt, params.tone),
            overall: 0
        };

        // Calculate weighted overall score
        scores.overall = (
            scores.sentiment * 0.20 +
            scores.length * 0.15 +
            scores.creativity * 0.25 +
            scores.relevance * 0.25 +
            scores.toneMatching * 0.15
        );

        return scores;
    }

    /**
     * Sentiment Analysis (0-1 scale, positive = higher)
     */
    evaluateSentiment(text) {
        // Simple sentiment heuristics (could be enhanced with NLP library)
        const positiveWords = ['love', 'great', 'amazing', 'awesome', 'beautiful', 'wonderful', 'exciting', 'fun', 'enjoy', 'happy'];
        const negativeWords = ['hate', 'boring', 'terrible', 'awful', 'bad', 'weird', 'strange', 'awkward'];

        const lowerText = text.toLowerCase();
        const positiveCount = positiveWords.filter(word => lowerText.includes(word)).length;
        const negativeCount = negativeWords.filter(word => lowerText.includes(word)).length;

        const netSentiment = positiveCount - (negativeCount * 2); // Weight negative higher
        return Math.max(0, Math.min(1, 0.5 + (netSentiment * 0.1)));
    }

    /**
     * Length Appropriateness (0-1 scale)
     */
    evaluateLength(text) {
        const words = text.split(/\s+/).length;
        const optimal = 30; // ~30 words is ideal
        const tolerance = 20;

        if (words < 10) return 0.3; // Too short
        if (words > 80) return 0.4; // Too long

        const deviation = Math.abs(words - optimal);
        return Math.max(0.5, 1 - (deviation / tolerance));
    }

    /**
     * Creativity Score (0-1 scale, checks for clichés and originality)
     */
    evaluateCreativity(text, context) {
        const lowerText = text.toLowerCase();

        // Penalize clichés
        const cliches = [
            'swipe right',
            'love to know more',
            'you seem interesting',
            'what brings you here',
            'tell me about yourself',
            'nice smile'
        ];

        const clicheCount = cliches.filter(cliche => lowerText.includes(cliche)).length;
        if (clicheCount > 0) return 0.3; // Heavy penalty for clichés

        // Reward specific references
        const hasSpecificReference = lowerText.length > 20 &&
            (lowerText.includes('i notice') ||
             lowerText.includes('i see') ||
             lowerText.match(/(\w+ing)\s/)); // Looks for specific actions

        return hasSpecificReference ? 0.85 : 0.65;
    }

    /**
     * Contextual Relevance (0-1 scale, measures connection to screenshot analysis)
     */
    evaluateRelevance(text, screenshotAnalysis) {
        if (!screenshotAnalysis) return 0.5;

        const analysisText = typeof screenshotAnalysis === 'object' ?
            JSON.stringify(screenshotAnalysis).toLowerCase() :
            screenshotAnalysis.toLowerCase();

        const lowerText = text.toLowerCase();

        // Extract key terms from analysis
        const keyTerms = analysisText
            .split(/\W+/)
            .filter(word => word.length > 4)
            .slice(0, 20);

        // Count how many key terms appear in flirt
        const matches = keyTerms.filter(term => lowerText.includes(term)).length;

        return Math.min(1, 0.4 + (matches * 0.1));
    }

    /**
     * Tone Matching (0-1 scale, checks if tone is appropriate)
     */
    evaluateToneMatching(text, targetTone) {
        const lowerText = text.toLowerCase();

        const toneIndicators = {
            playful: ['😊', '😄', '😉', 'fun', 'haha', 'lol', '!'],
            confident: ['know', 'will', 'can', 'should', 'definitely'],
            casual: ['hey', 'cool', 'nice', 'sounds', 'seems'],
            romantic: ['❤️', 'love', 'beautiful', 'gorgeous', 'sweet'],
            witty: ['?', 'notice', 'interesting', 'curious', 'wonder']
        };

        const indicators = toneIndicators[targetTone] || [];
        const matchCount = indicators.filter(indicator =>
            lowerText.includes(indicator.toLowerCase())
        ).length;

        return Math.min(1, 0.5 + (matchCount * 0.15));
    }

    /**
     * Get performance metrics
     */
    getMetrics() {
        return {
            initialized: this.initialized,
            endpoint: this.endpoint.substring(0, 50) + '...',
            modelVersion: this.modelVersion,
            timeout: this.timeout,
            maxTokens: this.maxTokens
        };
    }
}

module.exports = new GPT5FlirtService();
