const { GoogleGenAI } = require('@google/genai');
const OpenAI = require('openai');
const { logger } = require('./logger');
const fs = require('fs').promises;
const path = require('path');

/**
 * Gemini 2.5 Pro Vision Service for Advanced Visual Analysis
 *
 * This service provides comprehensive image analysis for dating app screenshots
 * using Google's Gemini 2.5 Pro multimodal capabilities with 1M token context.
 *
 * Features:
 * - Visual feature extraction (clothing, setting, activities)
 * - Personality trait inference (adventurous, professional, casual)
 * - Scene context understanding (outdoor, indoor, group, solo)
 * - Emotional tone detection (confident, playful, serious)
 * - Structured output for seamless handoff to Grok
 */
class GeminiVisionService {
    constructor() {
        this.googleAI = null;
        this.openAI = null;
        this.initialized = false;
        this.confidenceThreshold = 0.7;
        this.maxRetries = 2;
        this.timeout = 45000; // 45 seconds for vision analysis

        this.initialize();
    }

    async initialize() {
        try {
            // Initialize Google GenAI client
            if (process.env.GEMINI_API_KEY) {
                this.googleAI = new GoogleGenAI({
                    apiKey: process.env.GEMINI_API_KEY
                });
                logger.info('Gemini API client initialized successfully');
            } else {
                logger.warn('GEMINI_API_KEY not found, Gemini vision will be unavailable');
            }

            // Initialize OpenAI client for fallback (supports Gemini API format)
            if (process.env.GEMINI_API_KEY) {
                this.openAI = new OpenAI({
                    apiKey: process.env.GEMINI_API_KEY,
                    baseURL: "https://generativelanguage.googleapis.com/v1beta/openai/"
                });
                logger.info('Gemini OpenAI-compatible client initialized successfully');
            }

            this.initialized = true;
            logger.info('GeminiVisionService initialized successfully', {
                hasGoogleAI: !!this.googleAI,
                hasOpenAI: !!this.openAI,
                timeout: this.timeout
            });

        } catch (error) {
            logger.error('Failed to initialize GeminiVisionService', {
                error: error.message,
                stack: error.stack
            });
            this.initialized = false;
        }
    }

    /**
     * Enhanced Image Analysis Prompts for Different Photo Types
     */
    getAnalysisPrompts() {
        return {
            // Comprehensive visual analysis prompt
            comprehensive: `You are an expert dating app visual analyst. Analyze this image comprehensively and provide detailed insights that will help generate personalized conversation starters.

ANALYSIS FRAMEWORK:

1. VISUAL FEATURES:
   - Clothing style (casual, formal, athletic, trendy, vintage, etc.)
   - Setting/Environment (outdoor, indoor, restaurant, beach, gym, travel, home, etc.)
   - Activities visible (sports, hobbies, travel, social events, etc.)
   - Props/Objects that indicate interests (books, instruments, sports equipment, etc.)
   - Lighting and photo quality (professional, candid, selfie, group photo, etc.)

2. PERSONALITY INFERENCE:
   - Energy level (high-energy, calm, adventurous, laid-back)
   - Social style (outgoing, intimate, group-oriented, independent)
   - Lifestyle indicators (active, professional, artistic, outdoorsy, homebody)
   - Confidence level (confident, approachable, shy, bold)

3. SCENE CONTEXT:
   - Photo type (selfie, group photo, action shot, portrait, candid)
   - Social context (alone, with friends, with family, professional setting)
   - Mood/Atmosphere (fun, serious, romantic, casual, celebratory)
   - Time context if visible (day/night, season, special occasion)

4. CONVERSATION STARTERS:
   - Specific elements that could spark conversation
   - Questions that could be asked about the scene
   - Compliments that would be genuine and specific
   - Common interests that might be inferred

5. EMOTIONAL TONE:
   - Overall vibe (playful, serious, confident, mysterious, approachable)
   - Facial expressions and body language
   - Energy the person is projecting

Return your analysis in this JSON structure:`,

            // Profile photo specific analysis
            profile: `Analyze this dating profile photo with focus on creating engaging conversation starters.

PROFILE PHOTO ANALYSIS:
- What makes this photo interesting or unique?
- What personality traits are visible?
- What activities or interests are suggested?
- What's the overall vibe/energy?
- What specific elements could be conversation topics?

Focus on elements that would help someone craft a personalized, engaging opening message.

Return analysis in JSON format:`,

            // Conversation screenshot analysis
            conversation: `Analyze this dating app conversation screenshot to understand context and suggest appropriate responses.

CONVERSATION ANALYSIS:
- What's the conversation tone and style?
- What topics are being discussed?
- What's the relationship stage (just matched, ongoing chat, etc.)?
- What personality traits are evident from both participants?
- What would be appropriate response styles?

Return analysis in JSON format:`,

            // Group photo analysis
            group: `Analyze this group photo to identify the target person and understand their social context.

GROUP PHOTO ANALYSIS:
- Identify likely target person (if determinable)
- Social dynamics visible
- Activity or event context
- Personality traits of target person
- Conversation opportunities based on group context

Return analysis in JSON format:`
        };
    }

    /**
     * Get structured output format for different analysis types
     */
    getOutputFormat(analysisType = 'comprehensive') {
        const baseFormat = {
            // Visual Elements
            visual_features: {
                clothing_style: "string // e.g., 'casual_trendy', 'formal_professional', 'athletic_sporty'",
                setting_environment: "string // e.g., 'outdoor_nature', 'urban_cityscape', 'indoor_cozy'",
                activities_visible: "array // e.g., ['hiking', 'dining', 'photography']",
                props_objects: "array // e.g., ['guitar', 'book', 'surfboard']",
                photo_quality: "string // e.g., 'professional', 'candid', 'selfie'"
            },

            // Personality Inference
            personality_traits: {
                energy_level: "string // 'high_energy', 'moderate', 'calm_relaxed'",
                social_style: "string // 'outgoing', 'intimate', 'independent'",
                lifestyle_indicators: "array // e.g., ['active', 'professional', 'creative']",
                confidence_level: "string // 'confident', 'approachable', 'reserved'"
            },

            // Scene Context
            scene_context: {
                photo_type: "string // 'selfie', 'group_photo', 'action_shot', 'portrait'",
                social_context: "string // 'solo', 'with_friends', 'family', 'professional'",
                mood_atmosphere: "string // 'fun', 'romantic', 'adventurous', 'casual'",
                time_context: "string // 'daytime', 'evening', 'vacation', 'special_event'"
            },

            // Conversation Opportunities
            conversation_starters: {
                specific_elements: "array // Unique elements that could spark conversation",
                potential_questions: "array // Questions that could be asked about the scene",
                genuine_compliments: "array // Specific, non-generic compliments",
                shared_interests: "array // Interests that might be inferred"
            },

            // Emotional Analysis
            emotional_tone: {
                overall_vibe: "string // 'playful', 'confident', 'mysterious', 'approachable'",
                facial_expression: "string // 'smiling', 'serious', 'contemplative'",
                body_language: "string // 'relaxed', 'energetic', 'posed'",
                projected_energy: "string // Energy the person is projecting"
            },

            // Analysis Metadata
            analysis_metadata: {
                confidence_score: "number // 0.0 to 1.0",
                analysis_type: `"${analysisType}"`,
                recommended_tone: "string // 'playful', 'witty', 'romantic', 'casual', 'bold'",
                conversation_difficulty: "string // 'easy', 'moderate', 'challenging'",
                unique_elements_count: "number // Count of unique/interesting elements found"
            }
        };

        // Customize format based on analysis type
        if (analysisType === 'conversation') {
            baseFormat.conversation_context = {
                conversation_stage: "string // 'initial_match', 'ongoing_chat', 'deep_conversation'",
                topics_discussed: "array // Current conversation topics",
                response_style_needed: "string // Appropriate response style",
                relationship_temperature: "string // 'warming_up', 'engaged', 'cooling_down'"
            };
        }

        return baseFormat;
    }

    /**
     * Analyze image using Gemini 2.5 Pro with comprehensive visual analysis
     */
    async analyzeImage(imageData, options = {}) {
        const startTime = Date.now();
        const correlationId = options.correlationId || `gemini-${Date.now()}`;

        logger.info('Starting Gemini image analysis', {
            correlationId,
            analysisType: options.analysisType || 'comprehensive',
            hasImageData: !!imageData,
            imageSize: imageData?.length || 'unknown'
        });

        if (!this.initialized) {
            throw new Error('GeminiVisionService not initialized');
        }

        try {
            // Determine analysis type and get appropriate prompt
            const analysisType = options.analysisType || 'comprehensive';
            const prompts = this.getAnalysisPrompts();
            const basePrompt = prompts[analysisType] || prompts.comprehensive;
            const outputFormat = this.getOutputFormat(analysisType);

            // Create comprehensive analysis prompt
            const fullPrompt = `${basePrompt}

OUTPUT FORMAT (return ONLY this JSON structure):
${JSON.stringify(outputFormat, null, 2)}

IMPORTANT GUIDELINES:
1. Be specific and detailed in your analysis
2. Focus on elements that would help create personalized conversation starters
3. Avoid generic observations - find unique, specific details
4. Consider cultural and social contexts
5. Provide actionable insights for conversation generation
6. Assign confidence scores based on visual clarity and certainty
7. Recommend appropriate conversation tones based on the analysis

Analyze the provided image and return the analysis in the exact JSON format specified above.`;

            let result;

            // Try Google GenAI API first (preferred method)
            if (this.googleAI) {
                try {
                    result = await this.analyzeWithGoogleGenAI(imageData, fullPrompt, correlationId);
                } catch (googleError) {
                    logger.warn('Google GenAI analysis failed, trying OpenAI-compatible API', {
                        correlationId,
                        error: googleError.message
                    });

                    // Fallback to OpenAI-compatible API
                    if (this.openAI) {
                        result = await this.analyzeWithOpenAI(imageData, fullPrompt, correlationId);
                    } else {
                        throw googleError;
                    }
                }
            } else if (this.openAI) {
                result = await this.analyzeWithOpenAI(imageData, fullPrompt, correlationId);
            } else {
                throw new Error('No Gemini API clients available');
            }

            // Validate and enhance result
            const validatedResult = this.validateAnalysisResult(result, analysisType);

            const duration = Date.now() - startTime;
            logger.info('Gemini image analysis completed successfully', {
                correlationId,
                duration: `${duration}ms`,
                analysisType,
                confidenceScore: validatedResult.analysis_metadata?.confidence_score,
                uniqueElements: validatedResult.analysis_metadata?.unique_elements_count
            });

            return {
                success: true,
                analysis: validatedResult,
                metadata: {
                    correlationId,
                    duration,
                    analysisType,
                    model: result.model || 'gemini-2.5-pro',
                    confidence: validatedResult.analysis_metadata?.confidence_score || 0.8
                }
            };

        } catch (error) {
            const duration = Date.now() - startTime;

            logger.error('Gemini image analysis failed', {
                correlationId,
                duration: `${duration}ms`,
                error: error.message,
                stack: error.stack
            });

            // Return structured error with fallback analysis
            return {
                success: false,
                error: error.message,
                fallbackAnalysis: this.generateFallbackAnalysis(options.contextHint),
                metadata: {
                    correlationId,
                    duration,
                    analysisType: options.analysisType || 'comprehensive',
                    fallback: true
                }
            };
        }
    }

    /**
     * Analyze using Google GenAI (native Gemini API)
     */
    async analyzeWithGoogleGenAI(imageData, prompt, correlationId) {
        const model = this.googleAI.getGenerativeModel({
            model: "gemini-2.5-pro",
            generationConfig: {
                maxOutputTokens: 2048,
                temperature: 0.4, // Lower temperature for more consistent analysis
            }
        });

        // Convert base64 image data to the format expected by Gemini
        const imagePart = {
            inlineData: {
                data: imageData.replace(/^data:image\/[a-z]+;base64,/, ''),
                mimeType: this.detectMimeType(imageData)
            }
        };

        const contents = [
            {
                role: "user",
                parts: [
                    { text: prompt },
                    imagePart
                ]
            }
        ];

        logger.debug('Calling Google GenAI for image analysis', {
            correlationId,
            model: "gemini-2.5-pro",
            hasImage: true
        });

        const response = await model.generateContent(contents);
        const responseText = response.response.text();

        // Parse JSON response
        try {
            const analysis = JSON.parse(responseText);
            return {
                ...analysis,
                model: "gemini-2.5-pro",
                apiType: "google-genai"
            };
        } catch (parseError) {
            logger.error('Failed to parse Gemini response as JSON', {
                correlationId,
                responseText: responseText.substring(0, 500),
                parseError: parseError.message
            });
            throw new Error('Invalid JSON response from Gemini API');
        }
    }

    /**
     * Analyze using OpenAI-compatible Gemini API
     */
    async analyzeWithOpenAI(imageData, prompt, correlationId) {
        logger.debug('Calling OpenAI-compatible Gemini API for image analysis', {
            correlationId,
            model: "gemini-2.5-pro"
        });

        const response = await this.openAI.chat.completions.create({
            model: "gemini-2.5-pro",
            messages: [
                {
                    role: "user",
                    content: [
                        {
                            type: "text",
                            text: prompt
                        },
                        {
                            type: "image_url",
                            image_url: {
                                url: imageData
                            }
                        }
                    ]
                }
            ],
            max_tokens: 2048,
            temperature: 0.4,
            response_format: { type: "json_object" }
        });

        const responseText = response.choices[0].message.content;

        // Parse JSON response
        try {
            const analysis = JSON.parse(responseText);
            return {
                ...analysis,
                model: "gemini-2.5-pro",
                apiType: "openai-compatible"
            };
        } catch (parseError) {
            logger.error('Failed to parse OpenAI-compatible Gemini response as JSON', {
                correlationId,
                responseText: responseText.substring(0, 500),
                parseError: parseError.message
            });
            throw new Error('Invalid JSON response from Gemini API');
        }
    }

    /**
     * Validate and enhance analysis result
     */
    validateAnalysisResult(result, analysisType) {
        // Ensure all required fields are present
        const validated = {
            visual_features: result.visual_features || {
                clothing_style: "casual",
                setting_environment: "unknown",
                activities_visible: [],
                props_objects: [],
                photo_quality: "standard"
            },
            personality_traits: result.personality_traits || {
                energy_level: "moderate",
                social_style: "approachable",
                lifestyle_indicators: ["social"],
                confidence_level: "approachable"
            },
            scene_context: result.scene_context || {
                photo_type: "portrait",
                social_context: "solo",
                mood_atmosphere: "casual",
                time_context: "daytime"
            },
            conversation_starters: result.conversation_starters || {
                specific_elements: ["general photo elements"],
                potential_questions: ["What's your story?"],
                genuine_compliments: ["Great photo!"],
                shared_interests: ["photography"]
            },
            emotional_tone: result.emotional_tone || {
                overall_vibe: "approachable",
                facial_expression: "friendly",
                body_language: "relaxed",
                projected_energy: "positive"
            },
            analysis_metadata: {
                confidence_score: result.analysis_metadata?.confidence_score || 0.8,
                analysis_type: analysisType,
                recommended_tone: result.analysis_metadata?.recommended_tone || "playful",
                conversation_difficulty: result.analysis_metadata?.conversation_difficulty || "moderate",
                unique_elements_count: result.analysis_metadata?.unique_elements_count ||
                    (result.conversation_starters?.specific_elements?.length || 1),
                timestamp: new Date().toISOString()
            }
        };

        // Add conversation context if analyzing conversation
        if (analysisType === 'conversation' && result.conversation_context) {
            validated.conversation_context = result.conversation_context;
        }

        return validated;
    }

    /**
     * Generate fallback analysis when Gemini is unavailable
     */
    generateFallbackAnalysis(contextHint = '') {
        const fallbackAnalysis = {
            visual_features: {
                clothing_style: "casual",
                setting_environment: contextHint.includes('outdoor') ? 'outdoor_general' : 'indoor_general',
                activities_visible: contextHint.includes('activity') ? ['social_activity'] : [],
                props_objects: [],
                photo_quality: "standard"
            },
            personality_traits: {
                energy_level: "moderate",
                social_style: "approachable",
                lifestyle_indicators: ["social", "friendly"],
                confidence_level: "approachable"
            },
            scene_context: {
                photo_type: "portrait",
                social_context: "solo",
                mood_atmosphere: "casual",
                time_context: "daytime"
            },
            conversation_starters: {
                specific_elements: ["photo composition", "general appearance"],
                potential_questions: [
                    "What's the story behind this photo?",
                    "That looks like an interesting place, where was it taken?"
                ],
                genuine_compliments: [
                    "Great photo!",
                    "You have a really warm smile"
                ],
                shared_interests: ["photography", "conversation"]
            },
            emotional_tone: {
                overall_vibe: "approachable",
                facial_expression: "friendly",
                body_language: "relaxed",
                projected_energy: "positive"
            },
            analysis_metadata: {
                confidence_score: 0.5,
                analysis_type: "fallback",
                recommended_tone: "playful",
                conversation_difficulty: "easy",
                unique_elements_count: 2,
                timestamp: new Date().toISOString(),
                fallback_reason: "Gemini API unavailable"
            }
        };

        // Enhance based on context hint
        if (contextHint) {
            if (contextHint.includes('outdoor') || contextHint.includes('nature')) {
                fallbackAnalysis.visual_features.setting_environment = 'outdoor_nature';
                fallbackAnalysis.personality_traits.lifestyle_indicators.push('outdoorsy');
                fallbackAnalysis.conversation_starters.potential_questions.push(
                    "Do you enjoy spending time outdoors?"
                );
            }

            if (contextHint.includes('sport') || contextHint.includes('active')) {
                fallbackAnalysis.personality_traits.lifestyle_indicators.push('active');
                fallbackAnalysis.conversation_starters.shared_interests.push('fitness');
            }
        }

        return fallbackAnalysis;
    }

    /**
     * Detect MIME type from base64 data URL
     */
    detectMimeType(base64Data) {
        if (base64Data.startsWith('data:image/jpeg') || base64Data.startsWith('data:image/jpg')) {
            return 'image/jpeg';
        } else if (base64Data.startsWith('data:image/png')) {
            return 'image/png';
        } else if (base64Data.startsWith('data:image/webp')) {
            return 'image/webp';
        } else if (base64Data.startsWith('data:image/gif')) {
            return 'image/gif';
        }
        return 'image/jpeg'; // Default fallback
    }

    /**
     * Get service health status
     */
    getHealthStatus() {
        return {
            initialized: this.initialized,
            hasGoogleAI: !!this.googleAI,
            hasOpenAI: !!this.openAI,
            timeout: this.timeout,
            confidenceThreshold: this.confidenceThreshold,
            status: this.initialized ? 'healthy' : 'unavailable'
        };
    }

    /**
     * Test the service with a sample image
     */
    async testService() {
        try {
            // Create a simple test image (1x1 pixel base64 PNG)
            const testImage = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';

            const result = await this.analyzeImage(testImage, {
                analysisType: 'comprehensive',
                correlationId: 'health-check'
            });

            return {
                success: result.success,
                duration: result.metadata?.duration,
                model: result.metadata?.model,
                status: 'operational'
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                status: 'failed'
            };
        }
    }
}

// Export singleton instance
const geminiVisionService = new GeminiVisionService();

module.exports = geminiVisionService;