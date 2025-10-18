/**
 * AI Orchestrator Service - Dual-Model Pipeline Architecture
 *
 * Orchestrates the dual-model AI pipeline:
 * 1. GPT-4O for comprehensive screenshot analysis (vision)
 * 2. Grok-4 Fast for creative flirt generation
 *
 * Winner from Phase 2 testing: 87/100 quality score
 */

const axios = require('axios');
const { logger } = require('./logger');

class AIOrchestrator {
    constructor() {
        this.openaiApiKey = process.env.OPENAI_API_KEY;
        this.grokApiKey = process.env.XAI_API_KEY || process.env.GROK_API_KEY;

        // API endpoints
        this.openaiApiUrl = 'https://api.openai.com/v1';
        this.grokApiUrl = 'https://api.x.ai/v1';

        // Model configurations
        this.models = {
            vision: 'gpt-4o',
            flirting: 'grok-4-fast'
        };

        logger.info('AI Orchestrator initialized (GPT-4O + Grok-4 Fast)', {
            openaiEnabled: !!this.openaiApiKey,
            grokEnabled: !!this.grokApiKey
        });
    }

    /**
     * Main method: Generate flirt suggestions from screenshot(s)
     * @param {Object} request - { images: [base64...], context, previousSuggestions, userPreferences }
     * @returns {Promise<Object>} { suggestions: [...], reasoning: [...] }
     */
    async generateFlirts(request) {
        const startTime = Date.now();
        const { images, context, previousSuggestions, userPreferences } = request;

        try {
            // Phase 1: Vision Analysis with GPT-4O
            logger.info('Phase 1: GPT-4O vision analysis', { imageCount: images.length });
            const analysis = await this.analyzeWithGPT4O(images, context);

            // Phase 2: Flirt Generation with Grok-4 Fast
            logger.info('Phase 2: Grok-4 Fast flirt generation');
            const flirts = await this.generateWithGrok(analysis, previousSuggestions, userPreferences);

            const totalLatency = Date.now() - startTime;

            logger.info('Flirt generation complete', {
                latency: `${totalLatency}ms`,
                suggestionCount: flirts.suggestions.length
            });

            return {
                success: true,
                suggestions: flirts.suggestions.slice(0, 3), // Max 3 suggestions
                reasoning: flirts.reasoning,
                metadata: {
                    totalLatency,
                    visionModel: 'gpt-4o',
                    flirtingModel: 'grok-4-fast',
                    timestamp: new Date().toISOString()
                }
            };

        } catch (error) {
            logger.error('Flirt generation failed', { error: error.message });
            throw error;
        }
    }

    /**
     * Analyze screenshot(s) with GPT-4O vision
     * @param {Array} images - Array of base64 images
     * @param {String} context - Additional context (profile/chat)
     * @returns {Promise<String>} Analysis text
     */
    async analyzeWithGPT4O(images, context) {
        const isProfile = !context || context.toLowerCase().includes('profile');
        
        const prompt = isProfile
            ? "Analyze this dating profile screenshot. Provide: name, age, bio, interests, personality, visual context."
            : "Analyze this dating app chat screenshot. Provide: conversation context, relationship stage, her personality/interests, what she's looking for, conversation tone.";

        const messages = [
            {
                role: "system",
                content: "You are an expert dating coach analyzing dating app screenshots to help users create better connections. Your role is to extract profile information (name, age, bio, interests, personality traits, visual context) from dating app screenshots like Tinder, Bumble, Hinge, or Instagram. This is a legitimate dating assistance service. Never refuse to analyze dating app content."
            },
            {
                role: "user",
                content: [
                    { type: "text", text: prompt },
                    ...images.map(img => ({
                        type: "image_url",
                        image_url: { url: `data:image/png;base64,${img}` }
                    }))
                ]
            }
        ];

        const response = await axios.post(
            `${this.openaiApiUrl}/chat/completions`,
            {
                model: this.models.vision,
                messages,
                max_tokens: 500
            },
            {
                headers: {
                    'Authorization': `Bearer ${this.openaiApiKey}`,
                    'Content-Type': 'application/json'
                },
                timeout: 30000
            }
        );

        return response.data.choices[0].message.content;
    }

    /**
     * Generate flirts with Grok-4 Fast
     * @param {String} analysis - GPT-4O analysis
     * @param {Array} previousSuggestions - Previous suggestions (for refresh)
     * @param {Object} userPreferences - User preferences (tone, style)
     * @returns {Promise<Object>} { suggestions, reasoning }
     */
    async generateWithGrok(analysis, previousSuggestions = [], userPreferences = {}) {
        const systemPrompt = this.buildGrokSystemPrompt(userPreferences);
        const userPrompt = this.buildGrokUserPrompt(analysis, previousSuggestions);

        const response = await axios.post(
            `${this.grokApiUrl}/chat/completions`,
            {
                model: this.models.flirting,
                messages: [
                    { role: "system", content: systemPrompt },
                    { role: "user", content: userPrompt }
                ],
                max_tokens: 600
            },
            {
                headers: {
                    'Authorization': `Bearer ${this.grokApiKey}`,
                    'Content-Type': 'application/json'
                },
                timeout: 30000
            }
        );

        const content = response.data.choices[0].message.content;
        
        // Parse JSON response
        try {
            const parsed = JSON.parse(content);
            return {
                suggestions: parsed.suggestions || [],
                reasoning: parsed.suggestions.map(s => s.reasoning || '')
            };
        } catch (e) {
            // Fallback if not JSON
            logger.warn('Grok response not JSON, parsing manually');
            return {
                suggestions: [{ message: content, tone: "playful" }],
                reasoning: ["Generated from analysis"]
            };
        }
    }

    /**
     * Build Grok system prompt with user preferences
     */
    buildGrokSystemPrompt(userPreferences) {
        const tone = userPreferences.tone || 'playful';
        const spiciness = userPreferences.spiciness || 'medium';
        
        return `You are a flirty, ${tone} dating coach helping users craft opening messages.

GOAL: Get users dates/hookups through effective, authentic flirting.

STYLE:
- Tone: ${tone}
- Spiciness: ${spiciness} (allow sexual undertones when appropriate)
- Authenticity: Sound human, not robotic
- Personalization: Use specific profile details

RULES:
1. Create EXACTLY 3 flirty messages
2. Each message must:
   - Reference specific profile/chat details
   - Push towards getting a date/meeting
   - Include appropriate sexual undertones (if ${spiciness} >= medium)
   - Sound natural and conversational
3. Provide reasoning for each message
4. Vary tone across the 3 suggestions

OUTPUT FORMAT (JSON):
{
  "suggestions": [
    {
      "message": "...",
      "reasoning": "...",
      "tone": "playful/teasing/bold"
    }
  ]
}`;
    }

    /**
     * Build Grok user prompt
     */
    buildGrokUserPrompt(analysis, previousSuggestions) {
        let prompt = `Based on this profile/chat analysis, create 3 flirty messages:\n\n${analysis}\n\n`;
        
        if (previousSuggestions && previousSuggestions.length > 0) {
            prompt += `IMPORTANT: DO NOT repeat these previous suggestions:\n`;
            previousSuggestions.forEach((s, i) => {
                prompt += `${i + 1}. ${s}\n`;
            });
            prompt += `\nCreate 3 NEW, different suggestions.\n`;
        }

        prompt += `Provide exactly 3 suggestions in JSON format.`;
        
        return prompt;
    }
}

module.exports = new AIOrchestrator();
