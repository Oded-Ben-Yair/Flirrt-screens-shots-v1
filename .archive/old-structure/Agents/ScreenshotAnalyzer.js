/**
 * ScreenshotAnalyzer.js - AI Sub-Agent for Dating App Conversation Analysis
 *
 * Analyzes dating app conversations from screenshots using Grok Vision API
 * to determine conversation stage, interest level, and personality indicators.
 */

const axios = require('axios');
const FormData = require('form-data');

class ScreenshotAnalyzer {
    constructor() {
        this.grokApiKey = process.env.GROK_API_KEY || 'REMOVED_XAI_KEY';
        this.apiUrl = 'https://api.x.ai/v1/chat/completions';
    }

    /**
     * Analyze dating app conversation screenshot
     * @param {string} base64Image - Base64 encoded image data
     * @param {Object} userContext - User context and preferences
     * @returns {Promise<Object>} Analysis results
     */
    async analyzeConversation(base64Image, userContext = {}) {
        try {
            // Validate inputs
            if (!base64Image) {
                throw new Error('Base64 image data is required');
            }

            // Prepare the analysis prompt
            const analysisPrompt = this.buildAnalysisPrompt(userContext);

            // Make API call to Grok Vision
            const response = await axios.post(this.apiUrl, {
                model: 'grok-vision-beta',
                messages: [
                    {
                        role: 'user',
                        content: [
                            {
                                type: 'text',
                                text: analysisPrompt
                            },
                            {
                                type: 'image_url',
                                image_url: {
                                    url: `data:image/jpeg;base64,${base64Image}`
                                }
                            }
                        ]
                    }
                ],
                max_tokens: 1000,
                temperature: 0.3
            }, {
                headers: {
                    'Authorization': `Bearer ${this.grokApiKey}`,
                    'Content-Type': 'application/json'
                }
            });

            // Parse and structure the response
            const analysis = this.parseAnalysisResponse(response.data.choices[0].message.content);

            // Add metadata
            analysis.timestamp = new Date().toISOString();
            analysis.modelUsed = 'grok-vision-beta';
            analysis.confidence = this.calculateConfidence(analysis);

            return {
                success: true,
                data: analysis,
                metadata: {
                    processingTime: Date.now(),
                    tokensUsed: response.data.usage?.total_tokens || 0
                }
            };

        } catch (error) {
            console.error('Screenshot analysis error:', error);
            return {
                success: false,
                error: error.message,
                data: null
            };
        }
    }

    /**
     * Build comprehensive analysis prompt for dating conversations
     * @param {Object} userContext - User preferences and context
     * @returns {string} Formatted prompt
     */
    buildAnalysisPrompt(userContext) {
        const basePrompt = `
Analyze this dating app conversation screenshot and provide a structured JSON response with the following analysis:

**CONVERSATION STAGE ANALYSIS:**
- opening: Initial messages, introductions
- building_rapport: Getting to know each other, finding common ground
- flirting: Playful banter, romantic interest shown
- planning_meetup: Discussing dates or meeting plans
- established_connection: Ongoing conversation with clear mutual interest

**INTEREST LEVEL INDICATORS (0-10 scale):**
- Response time patterns
- Message length and effort
- Use of emojis and enthusiasm
- Question asking and engagement
- Flirtatious language usage

**PERSONALITY INDICATORS:**
- Communication style (formal, casual, playful, serious)
- Humor type (witty, sarcastic, silly, dry)
- Interests mentioned
- Conversation topics preferred
- Energy level (high, medium, low)

**CONTEXTUAL FACTORS:**
- Time of day messages were sent
- Platform being used (Tinder, Bumble, Hinge, etc.)
- Recent message momentum
- Any red flags or concerning patterns

**RESPONSE RECOMMENDATIONS:**
- Suggested conversation direction
- Tone to match
- Topics to explore
- Timing recommendations

Please respond in valid JSON format only:
{
    "conversationStage": "string",
    "interestLevel": {
        "overall": number,
        "responseTime": number,
        "messageQuality": number,
        "engagement": number
    },
    "personalityIndicators": {
        "communicationStyle": "string",
        "humorType": "string",
        "interests": ["array"],
        "energyLevel": "string",
        "preferredTopics": ["array"]
    },
    "contextualFactors": {
        "platform": "string",
        "timeOfDay": "string",
        "momentum": "string",
        "redFlags": ["array"]
    },
    "recommendations": {
        "conversationDirection": "string",
        "toneToMatch": "string",
        "topicsToExplore": ["array"],
        "timingAdvice": "string"
    },
    "summary": "string"
}`;

        // Add user context if provided
        if (userContext.userAge) {
            return basePrompt + `\n\nUser Context: Age ${userContext.userAge}, looking for ${userContext.relationship_goal || 'connection'}.`;
        }

        return basePrompt;
    }

    /**
     * Parse the AI response into structured data
     * @param {string} responseText - Raw response from Grok
     * @returns {Object} Parsed analysis data
     */
    parseAnalysisResponse(responseText) {
        try {
            // Extract JSON from response (in case there's additional text)
            const jsonMatch = responseText.match(/\{[\s\S]*\}/);
            if (!jsonMatch) {
                throw new Error('No valid JSON found in response');
            }

            const parsed = JSON.parse(jsonMatch[0]);

            // Validate required fields and add defaults
            return {
                conversationStage: parsed.conversationStage || 'unknown',
                interestLevel: {
                    overall: this.clampValue(parsed.interestLevel?.overall || 5, 0, 10),
                    responseTime: this.clampValue(parsed.interestLevel?.responseTime || 5, 0, 10),
                    messageQuality: this.clampValue(parsed.interestLevel?.messageQuality || 5, 0, 10),
                    engagement: this.clampValue(parsed.interestLevel?.engagement || 5, 0, 10)
                },
                personalityIndicators: {
                    communicationStyle: parsed.personalityIndicators?.communicationStyle || 'neutral',
                    humorType: parsed.personalityIndicators?.humorType || 'unknown',
                    interests: parsed.personalityIndicators?.interests || [],
                    energyLevel: parsed.personalityIndicators?.energyLevel || 'medium',
                    preferredTopics: parsed.personalityIndicators?.preferredTopics || []
                },
                contextualFactors: {
                    platform: parsed.contextualFactors?.platform || 'unknown',
                    timeOfDay: parsed.contextualFactors?.timeOfDay || 'unknown',
                    momentum: parsed.contextualFactors?.momentum || 'neutral',
                    redFlags: parsed.contextualFactors?.redFlags || []
                },
                recommendations: {
                    conversationDirection: parsed.recommendations?.conversationDirection || 'Continue natural flow',
                    toneToMatch: parsed.recommendations?.toneToMatch || 'friendly',
                    topicsToExplore: parsed.recommendations?.topicsToExplore || [],
                    timingAdvice: parsed.recommendations?.timingAdvice || 'Respond naturally'
                },
                summary: parsed.summary || 'Analysis completed successfully'
            };

        } catch (error) {
            console.error('Error parsing analysis response:', error);
            // Return fallback analysis
            return this.getFallbackAnalysis();
        }
    }

    /**
     * Calculate confidence score for the analysis
     * @param {Object} analysis - Parsed analysis data
     * @returns {number} Confidence score 0-1
     */
    calculateConfidence(analysis) {
        let confidence = 0.7; // Base confidence

        // Increase confidence if we have specific insights
        if (analysis.personalityIndicators.interests.length > 0) confidence += 0.1;
        if (analysis.contextualFactors.platform !== 'unknown') confidence += 0.1;
        if (analysis.recommendations.topicsToExplore.length > 0) confidence += 0.1;

        return Math.min(confidence, 1.0);
    }

    /**
     * Clamp a numeric value between min and max
     * @param {number} value - Value to clamp
     * @param {number} min - Minimum value
     * @param {number} max - Maximum value
     * @returns {number} Clamped value
     */
    clampValue(value, min, max) {
        return Math.max(min, Math.min(max, value));
    }

    /**
     * Provide fallback analysis when parsing fails
     * @returns {Object} Default analysis structure
     */
    getFallbackAnalysis() {
        return {
            conversationStage: 'unknown',
            interestLevel: {
                overall: 5,
                responseTime: 5,
                messageQuality: 5,
                engagement: 5
            },
            personalityIndicators: {
                communicationStyle: 'neutral',
                humorType: 'unknown',
                interests: [],
                energyLevel: 'medium',
                preferredTopics: []
            },
            contextualFactors: {
                platform: 'unknown',
                timeOfDay: 'unknown',
                momentum: 'neutral',
                redFlags: []
            },
            recommendations: {
                conversationDirection: 'Continue natural conversation',
                toneToMatch: 'friendly',
                topicsToExplore: ['common interests', 'light humor'],
                timingAdvice: 'Respond within reasonable time'
            },
            summary: 'Analysis completed with fallback data due to parsing error'
        };
    }

    /**
     * Validate screenshot for analysis
     * @param {string} base64Image - Base64 image data
     * @returns {Object} Validation result
     */
    validateScreenshot(base64Image) {
        if (!base64Image) {
            return { valid: false, error: 'No image data provided' };
        }

        // Check if it's valid base64
        try {
            const base64Data = base64Image.replace(/^data:image\/[a-z]+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');

            if (buffer.length === 0) {
                return { valid: false, error: 'Invalid base64 image data' };
            }

            // Check file size (max 10MB)
            if (buffer.length > 10 * 1024 * 1024) {
                return { valid: false, error: 'Image too large (max 10MB)' };
            }

            return { valid: true };

        } catch (error) {
            return { valid: false, error: 'Invalid base64 format' };
        }
    }

    /**
     * Get analysis health status
     * @returns {Object} Health status
     */
    async getHealthStatus() {
        try {
            // Test API connectivity with a minimal request
            const response = await axios.post(this.apiUrl, {
                model: 'grok-beta',
                messages: [{ role: 'user', content: 'Test connection' }],
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
}

module.exports = ScreenshotAnalyzer;