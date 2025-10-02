/**
 * AI Orchestrator Service - Dual-Model Pipeline Architecture
 *
 * Orchestrates the dual-model AI pipeline:
 * 1. Gemini API for comprehensive screenshot analysis
 * 2. Grok API for creative flirt generation
 *
 * Features:
 * - Model-specific prompt engineering
 * - Parallel processing where possible
 * - Intelligent fallback strategies
 * - Progressive timeout handling
 * - Cross-model context enrichment
 * - Response quality validation
 * - Performance monitoring
 */

const axios = require('axios');
const { logger } = require('./logger');
const circuitBreakerService = require('./circuitBreaker');
const redisService = require('./redis');
const performanceOptimizer = require('./performanceOptimizer');
const abTestingFramework = require('./abTestingFramework');

class AIOrchestrator {
    constructor() {
        this.geminiApiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;
        this.grokApiKey = process.env.GROK_API_KEY;

        // API endpoints
        this.geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta';
        this.grokApiUrl = process.env.GROK_API_URL || 'https://api.x.ai/v1';

        // Model configurations
        this.models = {
            gemini: {
                analysis: 'gemini-1.5-pro-latest',
                vision: 'gemini-1.5-pro-vision-latest',
                timeout: 15000,
                maxRetries: 2
            },
            grok: {
                generation: 'grok-beta',
                creative: 'grok-2-latest',
                timeout: 25000,
                maxRetries: 3
            }
        };

        // Performance tracking
        this.metrics = {
            geminiRequests: 0,
            grokRequests: 0,
            successfulPipelines: 0,
            failedPipelines: 0,
            averageLatency: 0,
            fallbackUsage: 0
        };

        // Initialize pipeline strategies
        this.initializePipelineStrategies();

        logger.info('AI Orchestrator initialized', {
            geminiEnabled: !!this.geminiApiKey,
            grokEnabled: !!this.grokApiKey,
            models: this.models
        });
    }

    /**
     * Initialize different pipeline strategies based on image characteristics
     */
    initializePipelineStrategies() {
        this.pipelineStrategies = {
            // Fast pipeline for simple screenshots
            fast: {
                geminiTimeout: 8000,
                grokTimeout: 15000,
                parallelProcessing: true,
                fallbackThreshold: 0.5
            },

            // Standard pipeline for most screenshots
            standard: {
                geminiTimeout: 15000,
                grokTimeout: 25000,
                parallelProcessing: true,
                fallbackThreshold: 0.7
            },

            // Comprehensive pipeline for complex screenshots
            comprehensive: {
                geminiTimeout: 25000,
                grokTimeout: 35000,
                parallelProcessing: false, // Sequential for better context
                fallbackThreshold: 0.8
            }
        };
    }

    /**
     * Main orchestration method - coordinates the dual-model pipeline
     * @param {Object} request - Request containing image and context
     * @returns {Promise<Object>} Orchestrated AI response
     */
    async orchestrateAIPipeline(request) {
        const startTime = Date.now();
        const correlationId = request.correlationId || this.generateCorrelationId();

        logger.info('Starting AI pipeline orchestration', {
            correlationId,
            hasImage: !!request.imageData,
            hasContext: !!request.context,
            strategy: request.strategy || 'auto'
        });

        try {
            // Record request start for performance tracking
            await performanceOptimizer.updateSystemLoad('start', { correlationId });

            // 1. Determine optimal strategy using performance optimizer
            const strategy = await performanceOptimizer.determineOptimalStrategy(request);
            const cacheConfig = performanceOptimizer.optimizeCacheStrategy(request, strategy);
            const parallelConfig = performanceOptimizer.optimizeParallelProcessing(request, strategy);

            logger.debug('Pipeline strategy determined', {
                correlationId,
                strategy: strategy.name,
                cacheFirst: cacheConfig.checkFirst,
                parallelEnabled: parallelConfig.enabled
            });

            // 2. Phase 1: Gemini Analysis (with optimized strategy)
            const analysisResult = await this.performGeminiAnalysis(request, strategy, correlationId);

            // 3. Context Enrichment - Combine analysis with request context
            const enrichedContext = this.enrichContext(analysisResult, request);

            // 4. Phase 2: Grok Generation (using enriched context)
            const generationResult = await this.performGrokGeneration(enrichedContext, strategy, correlationId);

            // 5. Response Quality Validation and Enhancement
            const validatedResponse = await this.validateAndEnhanceResponse(
                analysisResult,
                generationResult,
                request
            );

            // 6. Cache and metrics
            await this.cacheResults(request, validatedResponse, correlationId);
            this.updateMetrics(startTime, true);

            const totalLatency = Date.now() - startTime;

            // Record performance metrics
            await performanceOptimizer.recordPerformance({
                correlationId,
                strategy: strategy.name,
                latency: totalLatency,
                success: true,
                cacheHit: analysisResult.fromCache || generationResult.fromCache,
                geminiLatency: analysisResult.latency || 0,
                grokLatency: generationResult.latency || 0
            });

            // Update system load tracking
            await performanceOptimizer.updateSystemLoad('end', {
                correlationId,
                latency: totalLatency,
                success: true
            });

            logger.info('AI pipeline orchestration completed successfully', {
                correlationId,
                totalLatency: `${totalLatency}ms`,
                strategy: strategy.name,
                analysisConfidence: analysisResult.confidence,
                generationQuality: generationResult.qualityScore
            });

            return {
                success: true,
                data: validatedResponse,
                metadata: {
                    correlationId,
                    totalLatency,
                    strategy: strategy.name,
                    analysisModel: analysisResult.model,
                    generationModel: generationResult.model,
                    pipelineVersion: '2.0',
                    timestamp: new Date().toISOString()
                }
            };

        } catch (error) {
            const errorLatency = Date.now() - startTime;
            this.updateMetrics(startTime, false);

            // Record performance metrics for failed request
            await performanceOptimizer.recordPerformance({
                correlationId,
                strategy: 'error',
                latency: errorLatency,
                success: false,
                error: error.message
            });

            // Update system load tracking
            await performanceOptimizer.updateSystemLoad('end', {
                correlationId,
                latency: errorLatency,
                error: true
            });

            logger.error('AI pipeline orchestration failed', {
                correlationId,
                error: error.message,
                stack: error.stack,
                latency: `${errorLatency}ms`
            });

            // Attempt fallback pipeline
            return await this.executeFallbackPipeline(request, correlationId, error);
        }
    }

    /**
     * Determine the best pipeline strategy based on image and context characteristics
     * @param {Object} request - The request object
     * @returns {Object} Selected pipeline strategy
     */
    async determinePipelineStrategy(request) {
        // Quick heuristics to determine complexity
        let complexityScore = 0;

        // Image complexity factors
        if (request.imageData) {
            const imageSize = Buffer.from(request.imageData.split(',')[1] || '', 'base64').length;
            if (imageSize > 500000) complexityScore += 0.3; // Large image
            if (imageSize > 1000000) complexityScore += 0.2; // Very large image
        }

        // Context complexity factors
        if (request.context) {
            if (request.context.length > 500) complexityScore += 0.2; // Long context
            if (/conversation|chat|messages/i.test(request.context)) complexityScore += 0.2; // Conversation
            if (/profile|bio|description/i.test(request.context)) complexityScore += 0.1; // Profile
        }

        // Special requirements
        if (request.requireHighAccuracy) complexityScore += 0.3;
        if (request.isKeyboardExtension) complexityScore -= 0.4; // Prefer fast for keyboard

        // Select strategy
        let selectedStrategy;
        if (complexityScore >= 0.8) {
            selectedStrategy = { name: 'comprehensive', ...this.pipelineStrategies.comprehensive };
        } else if (complexityScore >= 0.4) {
            selectedStrategy = { name: 'standard', ...this.pipelineStrategies.standard };
        } else {
            selectedStrategy = { name: 'fast', ...this.pipelineStrategies.fast };
        }

        logger.debug('Pipeline strategy determined', {
            complexityScore,
            strategy: selectedStrategy.name,
            isKeyboard: request.isKeyboardExtension
        });

        return selectedStrategy;
    }

    /**
     * Perform comprehensive screenshot analysis using Gemini
     * @param {Object} request - Request object
     * @param {Object} strategy - Pipeline strategy
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Analysis results
     */
    async performGeminiAnalysis(request, strategy, correlationId) {
        const startTime = Date.now();

        try {
            // Check cache first
            const cacheKey = `gemini_analysis:${this.hashRequest(request)}`;
            const cached = await redisService.get(cacheKey, correlationId);

            if (cached && !request.bypassCache) {
                logger.info('Using cached Gemini analysis', { correlationId });
                return { ...cached, fromCache: true };
            }

            // Use existing Gemini Vision Service
            const options = {
                analysisType: request.analysisType || 'comprehensive',
                correlationId,
                contextHint: request.context
            };

            // Make API call through existing service
            const response = await this.makeGeminiRequest(request.imageData, options, correlationId);

            // Transform the response to match our expected format
            const analysisData = this.transformGeminiResponse(response.data);

            // Add metadata
            const result = {
                ...analysisData,
                model: response.metadata?.model || 'gemini-vision',
                latency: Date.now() - startTime,
                confidence: this.calculateAnalysisConfidence(analysisData),
                timestamp: new Date().toISOString(),
                fromCache: false
            };

            // Cache the result
            await redisService.set(cacheKey, result, 3600, correlationId); // Cache for 1 hour

            this.metrics.geminiRequests++;

            logger.info('Gemini analysis completed', {
                correlationId,
                model: result.model,
                latency: `${result.latency}ms`,
                confidence: result.confidence
            });

            return result;

        } catch (error) {
            logger.error('Gemini analysis failed', {
                correlationId,
                error: error.message,
                latency: Date.now() - startTime
            });

            // Return fallback analysis
            return this.getFallbackAnalysis(request, correlationId);
        }
    }

    /**
     * Build Gemini-specific analysis prompt
     * @param {Object} request - Request object
     * @returns {string} Formatted prompt
     */
    buildGeminiAnalysisPrompt(request) {
        return `You are an expert dating conversation analyst. Analyze this screenshot and context to provide comprehensive insights for generating appropriate flirt suggestions.

ANALYSIS REQUIREMENTS:
1. **Image Analysis** (if image provided):
   - Identify the dating platform (Tinder, Bumble, Hinge, etc.)
   - Determine screen type (profile, conversation, match, etc.)
   - Extract visible conversation context
   - Identify user sentiment and engagement level
   - Note any profile information visible

2. **Conversation Stage Assessment**:
   - opening: First messages, introductions
   - building_rapport: Getting to know each other
   - flirting: Playful romantic interaction
   - planning_meetup: Discussing meeting plans
   - established: Ongoing connection

3. **Personality Insights**:
   - Communication style (formal, casual, playful, intellectual)
   - Humor preferences (witty, silly, sarcastic, dry)
   - Interest indicators from visible content
   - Energy level and enthusiasm

4. **Context Enrichment**:
   - Suggested response tone (playful, sincere, witty, romantic, casual)
   - Topics that would resonate
   - Conversation direction recommendations
   - Timing and pacing advice

CONTEXT PROVIDED:
${request.context || 'No additional context provided'}

CURRENT TIME: ${new Date().toISOString()}
ANALYSIS TYPE: ${request.analysisType || 'comprehensive'}

Respond with a comprehensive JSON object:
{
  "platformAnalysis": {
    "platform": "detected_platform",
    "screenType": "profile|conversation|match|other",
    "confidence": 0.95
  },
  "conversationAnalysis": {
    "stage": "opening|building_rapport|flirting|planning_meetup|established",
    "momentum": "high|medium|low",
    "userEngagement": 0.85,
    "lastMessageTone": "friendly|excited|casual|formal",
    "responseExpectation": "immediate|within_hours|casual"
  },
  "personalityInsights": {
    "communicationStyle": "style_description",
    "humorType": "witty|playful|dry|silly|intellectual",
    "interests": ["interest1", "interest2"],
    "energyLevel": "high|medium|low",
    "sophisticationLevel": 0.75
  },
  "contextFactors": {
    "timeOfDay": "morning|afternoon|evening|night",
    "conversationLength": "new|short|medium|long",
    "mutualInterest": 0.80,
    "redFlags": [],
    "positiveSignals": ["signal1", "signal2"]
  },
  "recommendations": {
    "suggestedTone": "playful|sincere|witty|romantic|casual|intellectual",
    "topicsToExplore": ["topic1", "topic2"],
    "conversationDirection": "direction_description",
    "timingAdvice": "timing_recommendation",
    "confidenceLevel": 0.90
  },
  "generationGuidance": {
    "primaryStyle": "style_for_grok",
    "avoidanceTopics": ["topic1", "topic2"],
    "keywordSuggestions": ["keyword1", "keyword2"],
    "lengthPreference": "short|medium|long",
    "creativityLevel": 0.75
  }
}`;
    }

    /**
     * Build parts array for Gemini request (text + image if provided)
     * @param {string} prompt - Text prompt
     * @param {string} imageData - Base64 image data
     * @returns {Array} Parts array for Gemini
     */
    buildGeminiParts(prompt, imageData) {
        const parts = [{ text: prompt }];

        if (imageData) {
            // Extract base64 data and format for Gemini
            const base64Data = imageData.replace(/^data:image\/[a-z]+;base64,/, '');
            parts.push({
                inline_data: {
                    mime_type: "image/jpeg",
                    data: base64Data
                }
            });
        }

        return parts;
    }

    /**
     * Make request to Gemini API through existing vision service
     * @param {string} imageData - Base64 image data
     * @param {Object} options - Analysis options
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} API response
     */
    async makeGeminiRequest(imageData, options, correlationId) {
        const geminiVisionService = require('./geminiVisionService');

        // Use existing Gemini Vision Service
        const result = await geminiVisionService.analyzeImage(imageData, {
            ...options,
            correlationId
        });

        if (result.success) {
            return {
                success: true,
                data: result.analysis,
                metadata: result.metadata
            };
        } else {
            throw new Error(result.error || 'Gemini analysis failed');
        }
    }

    /**
     * Transform Gemini Vision Service response to orchestrator format
     * @param {Object} geminiData - Response from Gemini Vision Service
     * @returns {Object} Transformed analysis data
     */
    transformGeminiResponse(geminiData) {
        try {
            // Transform the existing Gemini Vision Service format to our orchestrator format
            return {
                platformAnalysis: {
                    platform: 'dating_app', // Vision service doesn't detect platform yet
                    screenType: geminiData.scene_context?.photo_type || 'profile',
                    confidence: geminiData.analysis_metadata?.confidence_score || 0.8
                },
                conversationAnalysis: {
                    stage: this.mapPhotoTypeToStage(geminiData.scene_context?.photo_type),
                    momentum: geminiData.personality_traits?.energy_level || 'medium',
                    userEngagement: geminiData.analysis_metadata?.confidence_score || 0.8,
                    lastMessageTone: geminiData.emotional_tone?.overall_vibe || 'friendly'
                },
                personalityInsights: {
                    communicationStyle: geminiData.personality_traits?.social_style || 'casual',
                    humorType: this.inferHumorType(geminiData.emotional_tone),
                    interests: geminiData.conversation_starters?.shared_interests || [],
                    energyLevel: geminiData.personality_traits?.energy_level || 'medium',
                    sophisticationLevel: this.calculateSophistication(geminiData)
                },
                contextFactors: {
                    timeOfDay: geminiData.scene_context?.time_context || 'unknown',
                    conversationLength: 'new',
                    mutualInterest: 0.7,
                    redFlags: [],
                    positiveSignals: geminiData.conversation_starters?.specific_elements || []
                },
                recommendations: {
                    suggestedTone: geminiData.analysis_metadata?.recommended_tone || 'playful',
                    topicsToExplore: geminiData.conversation_starters?.shared_interests || [],
                    conversationDirection: this.buildConversationDirection(geminiData),
                    timingAdvice: 'Respond within reasonable time',
                    confidenceLevel: geminiData.analysis_metadata?.confidence_score || 0.8
                },
                generationGuidance: {
                    primaryStyle: geminiData.analysis_metadata?.recommended_tone || 'playful',
                    avoidanceTopics: [],
                    keywordSuggestions: geminiData.conversation_starters?.specific_elements || [],
                    lengthPreference: 'medium',
                    creativityLevel: this.calculateCreativityLevel(geminiData)
                },
                // Store original Gemini data for reference
                rawGeminiData: geminiData
            };

        } catch (error) {
            logger.error('Failed to transform Gemini response', { error: error.message });
            throw new Error('Invalid Gemini response transformation');
        }
    }

    /**
     * Map photo type to conversation stage
     * @param {string} photoType - Photo type from Gemini
     * @returns {string} Conversation stage
     */
    mapPhotoTypeToStage(photoType) {
        const mapping = {
            'selfie': 'opening',
            'group_photo': 'opening',
            'action_shot': 'building_rapport',
            'portrait': 'opening',
            'travel_photo': 'building_rapport',
            'professional_photo': 'opening'
        };
        return mapping[photoType] || 'opening';
    }

    /**
     * Infer humor type from emotional tone
     * @param {Object} emotionalTone - Emotional tone data
     * @returns {string} Humor type
     */
    inferHumorType(emotionalTone) {
        const vibe = emotionalTone?.overall_vibe || 'approachable';
        const mapping = {
            'playful': 'playful',
            'confident': 'witty',
            'mysterious': 'dry',
            'approachable': 'balanced',
            'fun': 'silly'
        };
        return mapping[vibe] || 'balanced';
    }

    /**
     * Calculate sophistication level from analysis
     * @param {Object} geminiData - Gemini analysis data
     * @returns {number} Sophistication level 0-1
     */
    calculateSophistication(geminiData) {
        let score = 0.5; // Base score

        // Photo quality indicators
        const photoQuality = geminiData.visual_features?.photo_quality;
        if (photoQuality === 'professional') score += 0.2;
        else if (photoQuality === 'high_quality_casual') score += 0.1;

        // Setting sophistication
        const setting = geminiData.visual_features?.setting_environment;
        if (setting?.includes('professional') || setting?.includes('formal')) score += 0.2;
        else if (setting?.includes('artistic') || setting?.includes('cultural')) score += 0.15;

        // Aesthetic style
        const aesthetic = geminiData.personality_traits?.aesthetic_style;
        if (aesthetic === 'minimalist' || aesthetic === 'classic') score += 0.1;
        else if (aesthetic === 'artistic') score += 0.15;

        return Math.min(1.0, score);
    }

    /**
     * Build conversation direction from analysis
     * @param {Object} geminiData - Gemini analysis data
     * @returns {string} Conversation direction
     */
    buildConversationDirection(geminiData) {
        const interests = geminiData.conversation_starters?.shared_interests || [];
        const activities = geminiData.visual_features?.activities_visible || [];
        const vibe = geminiData.emotional_tone?.overall_vibe;

        if (activities.length > 0) {
            return `Explore their interest in ${activities[0]} and related activities`;
        } else if (interests.length > 0) {
            return `Build connection through shared interest in ${interests[0]}`;
        } else if (vibe === 'adventurous') {
            return 'Focus on adventure and exciting experiences';
        } else {
            return 'Build connection through genuine interest and curiosity';
        }
    }

    /**
     * Calculate creativity level for generation
     * @param {Object} geminiData - Gemini analysis data
     * @returns {number} Creativity level 0-1
     */
    calculateCreativityLevel(geminiData) {
        let level = 0.7; // Base creativity

        // Unique elements suggest higher creativity can work
        const uniqueElements = geminiData.analysis_metadata?.unique_elements_count || 0;
        if (uniqueElements > 3) level += 0.1;

        // Playful vibe suggests higher creativity
        const vibe = geminiData.emotional_tone?.overall_vibe;
        if (vibe === 'playful' || vibe === 'fun') level += 0.1;
        else if (vibe === 'serious' || vibe === 'professional') level -= 0.1;

        // High energy suggests higher creativity
        const energy = geminiData.personality_traits?.energy_level;
        if (energy === 'high_energy') level += 0.1;
        else if (energy === 'calm_relaxed') level -= 0.05;

        return Math.max(0.5, Math.min(1.0, level));
    }

    /**
     * Calculate confidence score for analysis results
     * @param {Object} analysisData - Analysis data
     * @returns {number} Confidence score 0-1
     */
    calculateAnalysisConfidence(analysisData) {
        let confidence = 0.5; // Base confidence

        // Platform analysis confidence
        if (analysisData.platformAnalysis?.confidence) {
            confidence += analysisData.platformAnalysis.confidence * 0.15;
        }

        // Conversation insights
        if (analysisData.conversationAnalysis?.stage && analysisData.conversationAnalysis.stage !== 'unknown') {
            confidence += 0.15;
        }

        // Personality insights
        if (analysisData.personalityInsights?.interests?.length > 0) {
            confidence += 0.1;
        }

        // Recommendations quality
        if (analysisData.recommendations?.confidenceLevel) {
            confidence += analysisData.recommendations.confidenceLevel * 0.1;
        }

        // Generation guidance completeness
        if (analysisData.generationGuidance?.primaryStyle) {
            confidence += 0.1;
        }

        return Math.min(confidence, 1.0);
    }

    /**
     * Enrich context by combining Gemini analysis with original request
     * @param {Object} analysisResult - Gemini analysis results
     * @param {Object} originalRequest - Original request
     * @returns {Object} Enriched context for Grok generation
     */
    enrichContext(analysisResult, originalRequest) {
        return {
            // Original request data
            originalContext: originalRequest.context,
            suggestionType: originalRequest.suggestion_type || 'opener',
            requestedTone: originalRequest.tone || 'playful',
            userPreferences: originalRequest.user_preferences || {},

            // Gemini analysis insights
            platformContext: analysisResult.platformAnalysis,
            conversationStage: analysisResult.conversationAnalysis?.stage || 'opening',
            personalityProfile: analysisResult.personalityInsights,
            contextualFactors: analysisResult.contextFactors,

            // Generation guidance from Gemini
            recommendedTone: analysisResult.recommendations?.suggestedTone || originalRequest.tone,
            topicsToExplore: analysisResult.recommendations?.topicsToExplore || [],
            conversationDirection: analysisResult.recommendations?.conversationDirection,

            // Grok-specific instructions
            generationGuidance: analysisResult.generationGuidance,
            creativityLevel: analysisResult.generationGuidance?.creativityLevel || 0.7,

            // Quality targets
            qualityTargets: {
                uniqueness: 0.85,
                contextRelevance: 0.90,
                toneConsistency: 0.95,
                engagementPotential: 0.80
            },

            // Metadata
            analysisConfidence: analysisResult.confidence,
            enrichmentTimestamp: new Date().toISOString()
        };
    }

    /**
     * Perform creative flirt generation using Grok with enriched context
     * @param {Object} enrichedContext - Context enriched with Gemini analysis
     * @param {Object} strategy - Pipeline strategy
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Generation results
     */
    async performGrokGeneration(enrichedContext, strategy, correlationId) {
        const startTime = Date.now();

        try {
            // Check cache for generation results
            const cacheKey = `grok_generation:${this.hashContext(enrichedContext)}`;
            const cached = await redisService.get(cacheKey, correlationId);

            if (cached && !enrichedContext.bypassCache) {
                logger.info('Using cached Grok generation', { correlationId });
                return { ...cached, fromCache: true };
            }

            // Build Grok-specific prompt
            const grokPrompt = this.buildGrokGenerationPrompt(enrichedContext);

            // Choose model based on creativity requirements
            const model = enrichedContext.creativityLevel > 0.8 ?
                this.models.grok.creative : this.models.grok.generation;

            // Prepare request payload
            const payload = {
                model: model,
                messages: [
                    {
                        role: "system",
                        content: this.getGrokSystemPrompt(enrichedContext)
                    },
                    {
                        role: "user",
                        content: grokPrompt
                    }
                ],
                max_tokens: 1500,
                temperature: enrichedContext.creativityLevel || 0.8,
                top_p: 0.9,
                response_format: { type: "json_object" }
            };

            // Make API call through circuit breaker
            const response = await circuitBreakerService.callGrokApi(payload, correlationId);

            if (!response.success) {
                throw new Error(response.error || 'Grok API call failed');
            }

            // Parse and validate response
            const generationData = this.parseGrokResponse(response.data);

            // Quality scoring and validation
            const qualityScore = this.calculateGenerationQuality(generationData, enrichedContext);

            // Add metadata
            const result = {
                ...generationData,
                model: model,
                latency: Date.now() - startTime,
                qualityScore: qualityScore,
                timestamp: new Date().toISOString(),
                fromCache: false
            };

            // Cache high-quality results
            if (qualityScore >= 0.7) {
                await redisService.set(cacheKey, result, 1800, correlationId); // Cache for 30 minutes
            }

            this.metrics.grokRequests++;

            logger.info('Grok generation completed', {
                correlationId,
                model,
                latency: `${result.latency}ms`,
                qualityScore: qualityScore
            });

            return result;

        } catch (error) {
            logger.error('Grok generation failed', {
                correlationId,
                error: error.message,
                latency: Date.now() - startTime
            });

            // Return fallback generation
            return this.getFallbackGeneration(enrichedContext, correlationId);
        }
    }

    /**
     * Build Grok-specific generation prompt with enriched context
     * @param {Object} enrichedContext - Enriched context from analysis
     * @returns {string} Formatted prompt for Grok
     */
    buildGrokGenerationPrompt(enrichedContext) {
        const {
            suggestionType,
            requestedTone,
            recommendedTone,
            conversationStage,
            personalityProfile,
            topicsToExplore,
            generationGuidance,
            qualityTargets
        } = enrichedContext;

        return `Generate ${suggestionType} suggestions for a dating conversation using the comprehensive context analysis provided.

CONTEXT ANALYSIS:
**Conversation Stage**: ${conversationStage}
**Platform**: ${enrichedContext.platformContext?.platform || 'dating app'}
**User Personality**: ${JSON.stringify(personalityProfile, null, 2)}
**Recommended Tone**: ${recommendedTone} (originally requested: ${requestedTone})
**Topics to Explore**: ${topicsToExplore.join(', ')}

GENERATION GUIDANCE:
**Primary Style**: ${generationGuidance?.primaryStyle || recommendedTone}
**Creativity Level**: ${enrichedContext.creativityLevel}/1.0
**Length Preference**: ${generationGuidance?.lengthPreference || 'medium'}
**Avoid Topics**: ${generationGuidance?.avoidanceTopics?.join(', ') || 'none specified'}
**Keyword Suggestions**: ${generationGuidance?.keywordSuggestions?.join(', ') || 'context-appropriate'}

QUALITY TARGETS:
- Uniqueness: ${qualityTargets.uniqueness}/1.0
- Context Relevance: ${qualityTargets.contextRelevance}/1.0
- Tone Consistency: ${qualityTargets.toneConsistency}/1.0
- Engagement Potential: ${qualityTargets.engagementPotential}/1.0

REQUIREMENTS:
1. Generate exactly 6 suggestions in JSON format
2. Each suggestion must be unique and contextually relevant
3. Maintain ${recommendedTone} tone throughout
4. Consider the personality insights and conversation stage
5. Incorporate relevant topics naturally
6. Aim for high engagement potential
7. Keep suggestions under 280 characters each
8. Include confidence scores and reasoning for each

RESPONSE FORMAT:
{
  "suggestions": [
    {
      "text": "suggestion text here",
      "confidence": 0.90,
      "reasoning": "why this works in this context",
      "tone": "${recommendedTone}",
      "topics": ["relevant", "topics"],
      "uniquenessScore": 0.85,
      "engagementPotential": 0.90
    }
  ],
  "metadata": {
    "generationStrategy": "strategy_used",
    "contextUtilization": 0.95,
    "averageConfidence": 0.88,
    "toneConsistency": 0.92
  }
}

Generate engaging, contextually perfect suggestions now:`;
    }

    /**
     * Get Grok system prompt based on enriched context
     * @param {Object} enrichedContext - Enriched context
     * @returns {string} System prompt
     */
    getGrokSystemPrompt(enrichedContext) {
        const stage = enrichedContext.conversationStage;
        const personality = enrichedContext.personalityProfile;

        return `You are Flirrt.ai, an expert dating conversation assistant with deep contextual understanding.

EXPERTISE AREAS:
- Dating psychology and conversation dynamics
- Tone matching and personality adaptation
- Context-aware response generation
- Engagement optimization

CURRENT CONTEXT:
- Conversation Stage: ${stage}
- User Communication Style: ${personality?.communicationStyle || 'adaptive'}
- Humor Preference: ${personality?.humorType || 'balanced'}
- Analysis Confidence: ${enrichedContext.analysisConfidence || 'high'}

RESPONSE PRINCIPLES:
1. **Context First**: Every suggestion must reflect the specific conversation context
2. **Personality Match**: Adapt to the detected communication style and preferences
3. **Stage Appropriate**: Suggestions must fit the current conversation stage
4. **Engagement Focused**: Prioritize responses that encourage continued conversation
5. **Authenticity**: Avoid generic or template-like responses
6. **Quality Over Quantity**: Each suggestion should be carefully crafted

You have access to comprehensive conversation analysis. Use this intelligence to create perfectly tailored suggestions that feel natural and engaging in the specific context provided.`;
    }

    /**
     * Parse Grok response and extract generation data
     * @param {Object} response - Raw Grok response
     * @returns {Object} Parsed generation data
     */
    parseGrokResponse(response) {
        try {
            const content = response.choices[0].message.content;
            const parsed = JSON.parse(content);

            // Validate response structure
            if (!parsed.suggestions || !Array.isArray(parsed.suggestions)) {
                throw new Error('Invalid suggestions format');
            }

            // Ensure all suggestions have required fields
            const validatedSuggestions = parsed.suggestions.map((suggestion, index) => ({
                id: `grok_${Date.now()}_${index}`,
                text: suggestion.text || '',
                confidence: Math.max(0, Math.min(1, suggestion.confidence || 0.7)),
                reasoning: suggestion.reasoning || 'Generated by Grok AI',
                tone: suggestion.tone || 'friendly',
                topics: suggestion.topics || [],
                uniquenessScore: suggestion.uniquenessScore || 0.7,
                engagementPotential: suggestion.engagementPotential || 0.7,
                characterCount: (suggestion.text || '').length
            }));

            return {
                suggestions: validatedSuggestions,
                metadata: parsed.metadata || {},
                rawContent: content
            };

        } catch (error) {
            logger.error('Failed to parse Grok response', { error: error.message });
            throw new Error('Invalid JSON response from Grok');
        }
    }

    /**
     * Calculate quality score for generated suggestions
     * @param {Object} generationData - Generation data
     * @param {Object} enrichedContext - Context used for generation
     * @returns {number} Quality score 0-1
     */
    calculateGenerationQuality(generationData, enrichedContext) {
        const suggestions = generationData.suggestions;
        if (!suggestions || suggestions.length === 0) return 0;

        let totalScore = 0;
        let validSuggestions = 0;

        suggestions.forEach(suggestion => {
            let score = 0;

            // Confidence score (30%)
            score += (suggestion.confidence || 0) * 0.3;

            // Uniqueness score (25%)
            score += (suggestion.uniquenessScore || 0) * 0.25;

            // Engagement potential (25%)
            score += (suggestion.engagementPotential || 0) * 0.25;

            // Character length appropriateness (10%)
            const charCount = suggestion.characterCount || 0;
            if (charCount > 20 && charCount <= 280) {
                score += 0.1;
            } else if (charCount > 280) {
                score += 0.05; // Penalty for too long
            }

            // Context relevance (10%)
            if (suggestion.tone === enrichedContext.recommendedTone) {
                score += 0.05;
            }
            if (suggestion.topics && suggestion.topics.length > 0) {
                score += 0.05;
            }

            totalScore += score;
            validSuggestions++;
        });

        const averageScore = validSuggestions > 0 ? totalScore / validSuggestions : 0;

        // Metadata bonus
        if (generationData.metadata?.contextUtilization >= 0.8) {
            return Math.min(1.0, averageScore + 0.05);
        }

        return Math.max(0, Math.min(1.0, averageScore));
    }

    /**
     * Validate and enhance the final response
     * @param {Object} analysisResult - Gemini analysis results
     * @param {Object} generationResult - Grok generation results
     * @param {Object} originalRequest - Original request
     * @returns {Object} Validated and enhanced response
     */
    async validateAndEnhanceResponse(analysisResult, generationResult, originalRequest) {
        const suggestions = generationResult.suggestions || [];

        // Filter out suggestions that don't meet quality thresholds
        const qualityFiltered = suggestions.filter(suggestion => {
            return (
                suggestion.confidence >= 0.6 &&
                suggestion.text.length >= 10 &&
                suggestion.text.length <= 280 &&
                suggestion.text.trim() !== ''
            );
        });

        // Ensure we have enough suggestions
        if (qualityFiltered.length < 3) {
            logger.warn('Insufficient quality suggestions, adding fallbacks');
            const fallbackSuggestions = this.generateFallbackSuggestions(
                originalRequest,
                analysisResult,
                3 - qualityFiltered.length
            );
            qualityFiltered.push(...fallbackSuggestions);
        }

        // Rank suggestions by composite score
        const rankedSuggestions = qualityFiltered
            .map(suggestion => ({
                ...suggestion,
                compositeScore: this.calculateCompositeScore(suggestion, analysisResult),
                validatedAt: new Date().toISOString()
            }))
            .sort((a, b) => b.compositeScore - a.compositeScore)
            .slice(0, 6); // Return top 6

        // Add response metadata
        const responseMetadata = {
            analysisQuality: analysisResult.confidence,
            generationQuality: generationResult.qualityScore,
            totalSuggestions: rankedSuggestions.length,
            averageConfidence: rankedSuggestions.reduce((sum, s) => sum + s.confidence, 0) / rankedSuggestions.length,
            contextUtilization: generationResult.metadata?.contextUtilization || 0.8,
            pipelineSuccess: true,
            enhancedAt: new Date().toISOString()
        };

        return {
            suggestions: rankedSuggestions,
            analysis: {
                platform: analysisResult.platformAnalysis,
                conversation: analysisResult.conversationAnalysis,
                personality: analysisResult.personalityInsights,
                recommendations: analysisResult.recommendations
            },
            metadata: responseMetadata
        };
    }

    /**
     * Calculate composite score for suggestion ranking
     * @param {Object} suggestion - Individual suggestion
     * @param {Object} analysisResult - Analysis results
     * @returns {number} Composite score
     */
    calculateCompositeScore(suggestion, analysisResult) {
        let score = 0;

        // Base confidence (40%)
        score += suggestion.confidence * 0.4;

        // Engagement potential (30%)
        score += (suggestion.engagementPotential || 0.7) * 0.3;

        // Uniqueness (20%)
        score += (suggestion.uniquenessScore || 0.7) * 0.2;

        // Context alignment bonus (10%)
        const recommendedTone = analysisResult.recommendations?.suggestedTone;
        if (suggestion.tone === recommendedTone) {
            score += 0.1;
        }

        return Math.min(1.0, score);
    }

    /**
     * Execute fallback pipeline when main pipeline fails
     * @param {Object} request - Original request
     * @param {string} correlationId - Correlation ID
     * @param {Error} originalError - Original error
     * @returns {Promise<Object>} Fallback response
     */
    async executeFallbackPipeline(request, correlationId, originalError) {
        this.metrics.fallbackUsage++;

        logger.warn('Executing fallback pipeline', {
            correlationId,
            originalError: originalError.message
        });

        try {
            // Use existing FlirtGenerator as fallback
            const FlirtGenerator = require('../../Agents/FlirtGenerator');
            const fallbackGenerator = new FlirtGenerator();

            // Convert request to FlirtGenerator format
            const fallbackContext = {
                conversationStage: 'opening',
                personalityInsights: {},
                userPreferences: request.user_preferences || {},
                conversationHistory: [],
                platform: 'dating_app',
                timeOfDay: new Date().getHours() < 12 ? 'morning' :
                          new Date().getHours() < 18 ? 'afternoon' : 'evening'
            };

            const fallbackResult = await fallbackGenerator.generateFlirts(fallbackContext);

            if (fallbackResult.success) {
                return {
                    success: true,
                    data: {
                        suggestions: fallbackResult.suggestions.map(s => ({
                            ...s,
                            fallback: true,
                            compositeScore: 0.6
                        })),
                        analysis: { fallback: true },
                        metadata: {
                            ...fallbackResult.metadata,
                            fallbackReason: originalError.message,
                            pipelineSuccess: false
                        }
                    },
                    metadata: {
                        correlationId,
                        fallback: true,
                        originalError: originalError.message
                    }
                };
            }

            throw new Error('Fallback generator also failed');

        } catch (fallbackError) {
            logger.error('Fallback pipeline failed', {
                correlationId,
                fallbackError: fallbackError.message
            });

            // Final emergency fallback
            return this.getEmergencyFallback(request, correlationId);
        }
    }

    /**
     * Get emergency fallback response
     * @param {Object} request - Original request
     * @param {string} correlationId - Correlation ID
     * @returns {Object} Emergency fallback response
     */
    getEmergencyFallback(request, correlationId) {
        const emergencySuggestions = [
            "Your message made me smile - tell me more about that!",
            "I love how thoughtful your messages are",
            "This conversation is turning out to be the highlight of my day",
            "You seem like someone with great stories to tell",
            "I'm curious to know more about your perspective on this"
        ];

        const suggestions = emergencySuggestions.slice(0, 3).map((text, index) => ({
            id: `emergency_${Date.now()}_${index}`,
            text: text,
            confidence: 0.5,
            reasoning: "Emergency fallback suggestion",
            tone: request.tone || 'friendly',
            topics: ['general'],
            uniquenessScore: 0.4,
            engagementPotential: 0.6,
            characterCount: text.length,
            fallback: true,
            emergency: true,
            compositeScore: 0.5
        }));

        return {
            success: true,
            data: {
                suggestions: suggestions,
                analysis: { emergency: true },
                metadata: {
                    emergency: true,
                    totalSuggestions: suggestions.length,
                    pipelineSuccess: false
                }
            },
            metadata: {
                correlationId,
                emergency: true
            }
        };
    }

    /**
     * Generate fallback analysis when Gemini fails
     * @param {Object} request - Original request
     * @param {string} correlationId - Correlation ID
     * @returns {Object} Fallback analysis
     */
    getFallbackAnalysis(request, correlationId) {
        logger.info('Using fallback analysis', { correlationId });

        // Simple heuristic-based analysis
        const context = request.context || '';
        const hasConversation = /conversation|chat|message/i.test(context);
        const hasProfile = /profile|bio|about/i.test(context);

        return {
            platformAnalysis: {
                platform: 'dating_app',
                screenType: hasProfile ? 'profile' : hasConversation ? 'conversation' : 'unknown',
                confidence: 0.6
            },
            conversationAnalysis: {
                stage: hasConversation ? 'building_rapport' : 'opening',
                momentum: 'medium',
                userEngagement: 0.7,
                lastMessageTone: 'friendly'
            },
            personalityInsights: {
                communicationStyle: 'casual',
                humorType: 'balanced',
                interests: [],
                energyLevel: 'medium'
            },
            contextFactors: {
                timeOfDay: new Date().getHours() < 12 ? 'morning' :
                          new Date().getHours() < 18 ? 'afternoon' : 'evening',
                conversationLength: 'unknown',
                mutualInterest: 0.7
            },
            recommendations: {
                suggestedTone: request.tone || 'playful',
                topicsToExplore: ['common interests', 'light humor'],
                conversationDirection: 'Continue building connection',
                confidenceLevel: 0.6
            },
            generationGuidance: {
                primaryStyle: request.tone || 'playful',
                creativityLevel: 0.7,
                lengthPreference: 'medium'
            },
            confidence: 0.6,
            fallback: true,
            model: 'heuristic_analysis'
        };
    }

    /**
     * Generate fallback suggestions
     * @param {Object} request - Original request
     * @param {Object} analysisResult - Analysis results
     * @param {number} count - Number of fallbacks needed
     * @returns {Array} Fallback suggestions
     */
    generateFallbackSuggestions(request, analysisResult, count) {
        const tone = request.tone || analysisResult.recommendations?.suggestedTone || 'playful';
        const stage = analysisResult.conversationAnalysis?.stage || 'opening';

        const fallbackTemplates = {
            opening: {
                playful: [
                    "Well, this is refreshing - someone who actually looks interesting!",
                    "I have to ask... what's the story behind that smile?",
                    "Your profile stopped me mid-scroll. What's your secret?"
                ],
                sincere: [
                    "Something about your energy really caught my attention",
                    "You seem like someone with fascinating stories to tell",
                    "I'd love to know what makes you laugh"
                ],
                witty: [
                    "I was going to use a pickup line, but you look too smart for that",
                    "Your profile suggests excellent taste. Can you confirm?",
                    "Scale of 1-10, how tired are you of hearing 'hey'?"
                ]
            }
        };

        const templates = fallbackTemplates[stage]?.[tone] || fallbackTemplates.opening.playful;
        const selectedTemplates = templates.slice(0, count);

        return selectedTemplates.map((text, index) => ({
            id: `fallback_${Date.now()}_${index}`,
            text: text,
            confidence: 0.65,
            reasoning: "Fallback suggestion based on tone and stage",
            tone: tone,
            topics: ['general'],
            uniquenessScore: 0.6,
            engagementPotential: 0.7,
            characterCount: text.length,
            fallback: true
        }));
    }

    /**
     * Generate fallback generation when Grok fails
     * @param {Object} enrichedContext - Enriched context
     * @param {string} correlationId - Correlation ID
     * @returns {Object} Fallback generation
     */
    getFallbackGeneration(enrichedContext, correlationId) {
        logger.info('Using fallback generation', { correlationId });

        const fallbackSuggestions = this.generateFallbackSuggestions(
            { tone: enrichedContext.recommendedTone },
            {
                conversationAnalysis: { stage: enrichedContext.conversationStage },
                recommendations: { suggestedTone: enrichedContext.recommendedTone }
            },
            5
        );

        return {
            suggestions: fallbackSuggestions,
            metadata: {
                fallback: true,
                contextUtilization: 0.5
            },
            qualityScore: 0.6,
            model: 'fallback_generator',
            fromCache: false
        };
    }

    /**
     * Cache pipeline results
     * @param {Object} request - Original request
     * @param {Object} response - Pipeline response
     * @param {string} correlationId - Correlation ID
     */
    async cacheResults(request, response, correlationId) {
        try {
            const cacheKey = `pipeline_result:${this.hashRequest(request)}`;
            await redisService.set(cacheKey, {
                response: response,
                timestamp: new Date().toISOString()
            }, 1800, correlationId); // Cache for 30 minutes

        } catch (error) {
            logger.warn('Failed to cache pipeline results', {
                correlationId,
                error: error.message
            });
        }
    }

    /**
     * Update performance metrics
     * @param {number} startTime - Pipeline start time
     * @param {boolean} success - Whether pipeline succeeded
     */
    updateMetrics(startTime, success) {
        const latency = Date.now() - startTime;

        if (success) {
            this.metrics.successfulPipelines++;
        } else {
            this.metrics.failedPipelines++;
        }

        // Update average latency with exponential moving average
        this.metrics.averageLatency = this.metrics.averageLatency === 0 ?
            latency : (this.metrics.averageLatency * 0.9 + latency * 0.1);
    }

    /**
     * Generate correlation ID for tracking
     * @returns {string} Correlation ID
     */
    generateCorrelationId() {
        return `orch_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * Hash request for caching
     * @param {Object} request - Request object
     * @returns {string} Hash
     */
    hashRequest(request) {
        const crypto = require('crypto');
        const hashData = {
            context: request.context,
            suggestion_type: request.suggestion_type,
            tone: request.tone,
            hasImage: !!request.imageData
        };
        return crypto.createHash('md5').update(JSON.stringify(hashData)).digest('hex');
    }

    /**
     * Hash enriched context for caching
     * @param {Object} context - Enriched context
     * @returns {string} Hash
     */
    hashContext(context) {
        const crypto = require('crypto');
        const hashData = {
            suggestionType: context.suggestionType,
            recommendedTone: context.recommendedTone,
            conversationStage: context.conversationStage,
            personalityProfile: context.personalityProfile
        };
        return crypto.createHash('md5').update(JSON.stringify(hashData)).digest('hex');
    }

    /**
     * Get health status of the orchestrator
     * @returns {Object} Health status
     */
    getHealthStatus() {
        const totalRequests = this.metrics.successfulPipelines + this.metrics.failedPipelines;
        const successRate = totalRequests > 0 ?
            (this.metrics.successfulPipelines / totalRequests * 100).toFixed(2) + '%' : '0%';

        return {
            status: this.metrics.failedPipelines / Math.max(totalRequests, 1) < 0.1 ? 'healthy' : 'degraded',
            metrics: {
                ...this.metrics,
                successRate,
                totalRequests
            },
            models: {
                gemini: {
                    enabled: !!this.geminiApiKey,
                    model: this.models.gemini.analysis
                },
                grok: {
                    enabled: !!this.grokApiKey,
                    model: this.models.grok.generation
                }
            },
            lastChecked: new Date().toISOString()
        };
    }

    /**
     * Analyze image with Gemini (for streaming service)
     * @param {Object} params - Analysis parameters
     * @returns {Promise<Object>} Analysis result
     */
    async analyzeImageWithGemini(params) {
        const { imageData, context, correlationId } = params;

        const request = {
            imageData,
            context,
            correlationId,
            analysisType: 'comprehensive'
        };

        const strategy = await this.determinePipelineStrategy(request);
        return await this.performGeminiAnalysis(request, strategy, correlationId);
    }

    /**
     * Generate single suggestion (for streaming service)
     * @param {Object} params - Generation parameters
     * @returns {Promise<Object>} Single suggestion
     */
    async generateSingleSuggestion(params) {
        const {
            analysisData,
            context,
            suggestionType,
            tone,
            userPreferences,
            variationIndex,
            correlationId
        } = params;

        // Create enriched context for single suggestion
        const enrichedContext = {
            originalContext: context,
            suggestionType: suggestionType || 'opener',
            requestedTone: tone || 'playful',
            recommendedTone: analysisData.recommendations?.suggestedTone || tone || 'playful',
            conversationStage: analysisData.conversationAnalysis?.stage || 'opening',
            personalityProfile: analysisData.personalityInsights || {},
            topicsToExplore: analysisData.recommendations?.topicsToExplore || [],
            generationGuidance: analysisData.generationGuidance || {
                primaryStyle: tone || 'playful',
                creativityLevel: 0.7,
                lengthPreference: 'medium'
            },
            qualityTargets: {
                uniqueness: 0.85,
                contextRelevance: 0.90,
                toneConsistency: 0.95,
                engagementPotential: 0.80
            },
            variationIndex,
            singleSuggestion: true
        };

        try {
            // Generate single suggestion using modified Grok prompt
            const grokPrompt = this.buildSingleSuggestionPrompt(enrichedContext);

            const payload = {
                model: this.models.grok.generation,
                messages: [
                    {
                        role: "system",
                        content: this.getSingleSuggestionSystemPrompt(enrichedContext)
                    },
                    {
                        role: "user",
                        content: grokPrompt
                    }
                ],
                max_tokens: 300,
                temperature: enrichedContext.generationGuidance.creativityLevel || 0.8,
                top_p: 0.9,
                response_format: { type: "json_object" }
            };

            const response = await circuitBreakerService.callGrokApi(payload, correlationId);

            if (!response.success) {
                throw new Error(response.error || 'Grok API call failed');
            }

            // Parse single suggestion response
            const content = response.data.choices[0].message.content;
            const parsed = JSON.parse(content);

            return {
                text: parsed.text || parsed.suggestion || 'Great conversation starter!',
                confidence: Math.max(0, Math.min(1, parsed.confidence || 0.7)),
                reasoning: parsed.reasoning || 'Generated contextually',
                topics: parsed.topics || [],
                compositeScore: parsed.confidence || 0.7
            };

        } catch (error) {
            logger.warn('Single suggestion generation failed, using fallback', {
                correlationId,
                variationIndex,
                error: error.message
            });

            // Return fallback suggestion
            return this.getFallbackSingleSuggestion(enrichedContext, variationIndex);
        }
    }

    /**
     * Build prompt for single suggestion generation
     * @param {Object} enrichedContext - Enriched context
     * @returns {string} Single suggestion prompt
     */
    buildSingleSuggestionPrompt(enrichedContext) {
        const { suggestionType, recommendedTone, conversationStage, personalityProfile, variationIndex } = enrichedContext;

        return `Generate exactly ONE ${suggestionType} suggestion for a dating conversation.

CONTEXT:
- Stage: ${conversationStage}
- Tone: ${recommendedTone}
- Personality: ${personalityProfile.communicationStyle || 'adaptive'}
- Variation: #${variationIndex + 1}

REQUIREMENTS:
- Single suggestion only
- Under 280 characters
- ${recommendedTone} tone
- Contextually relevant
- High engagement potential

RESPONSE FORMAT:
{
  "text": "your suggestion here",
  "confidence": 0.85,
  "reasoning": "why this works",
  "topics": ["relevant", "topics"]
}

Generate the suggestion now:`;
    }

    /**
     * Get system prompt for single suggestion
     * @param {Object} enrichedContext - Enriched context
     * @returns {string} System prompt
     */
    getSingleSuggestionSystemPrompt(enrichedContext) {
        return `You are Flirrt.ai generating a single, high-quality dating conversation suggestion.

FOCUS:
- Quality over quantity (one perfect suggestion)
- Contextual relevance
- ${enrichedContext.recommendedTone} tone
- High engagement potential

Respond with JSON containing one suggestion.`;
    }

    /**
     * Get fallback single suggestion
     * @param {Object} enrichedContext - Enriched context
     * @param {number} variationIndex - Variation index
     * @returns {Object} Fallback suggestion
     */
    getFallbackSingleSuggestion(enrichedContext, variationIndex) {
        const tone = enrichedContext.recommendedTone || 'playful';

        const fallbacks = {
            playful: [
                "Your photos tell quite a story - what's the best chapter?",
                "I have to ask... what's behind that smile?",
                "Your profile stopped me mid-scroll. Mission accomplished!",
                "Something tells me you have great stories to share",
                "Well, this is refreshing - someone who looks genuinely interesting!"
            ],
            casual: [
                "Hey! What's going on in this photo?",
                "Nice pictures! Where was this taken?",
                "You seem like someone fun to talk to",
                "What's your story?",
                "How's your day going?"
            ],
            confident: [
                "I'm intrigued by your profile - care to elaborate?",
                "You clearly have excellent taste. Can you confirm?",
                "I was going to use a line, but you look too smart for that",
                "Your profile suggests we'd have great conversations",
                "I'd love to hear your perspective on life"
            ]
        };

        const options = fallbacks[tone] || fallbacks.playful;
        const text = options[variationIndex % options.length];

        return {
            text,
            confidence: 0.6,
            reasoning: 'Fallback suggestion based on tone preference',
            topics: ['general'],
            compositeScore: 0.6
        };
    }

    /**
     * Reset metrics (for testing)
     */
    resetMetrics() {
        this.metrics = {
            geminiRequests: 0,
            grokRequests: 0,
            successfulPipelines: 0,
            failedPipelines: 0,
            averageLatency: 0,
            fallbackUsage: 0
        };
    }
}

// Export singleton instance
const aiOrchestrator = new AIOrchestrator();
module.exports = aiOrchestrator;