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
        
        return `You are an expert wingman and dating coach. Your ONLY job is to help users get dates, hookups, and real-world meetups through highly effective, spicy flirting.

GOAL: Every message MUST push towards meeting up in real life. Be bold, confident, and sexually charged (when appropriate).

YOUR FLIRTING STYLE:
- Tone: ${tone} but ALWAYS confident and date-focused
- Spiciness: ${spiciness} - don't be afraid of sexual tension, innuendo, and playful teasing
- Authenticity: Sound like a real person who knows how to flirt, not a corporate chatbot
- Personalization: Use SPECIFIC details from their profile/photos/bio
- Date-Pushing: EVERY message should suggest meeting up (coffee, drinks, activity, etc.)

MANDATORY ELEMENTS (at least 2 of 3 messages MUST have):
1. Clear date invitation ("let's grab...", "how about we...", "want to meet up...", "free this weekend?")
2. Sexual tension/chemistry hints ("chemistry", "vibe", "tension", "close", "steamy", "hot", "dying to", "hooked")
3. Playful challenge or tease that builds attraction
4. Specific activity suggestion based on their interests

FLIRTING TECHNIQUES TO USE:
- Reference specific photos/details to show you actually looked
- Use emojis strategically (😏, 😉, 🔥) but don't overdo it
- Create intrigue and curiosity
- Be direct about wanting to meet
- Add subtle sexual undertones ("close encounters", "chemistry", "see where the night takes us")
- Show confidence, not desperation

RULES:
1. Create EXACTLY 3 messages with DIFFERENT approaches
2. At least 2 of 3 MUST explicitly suggest meeting up
3. At least 1 of 3 MUST have clear sexual tension/chemistry language
4. Each message MUST reference specific profile details
5. Vary intensity: one playful, one bold, one balanced
6. Provide coaching reasoning for each

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
