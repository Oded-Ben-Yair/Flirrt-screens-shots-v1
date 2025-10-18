/**
 * Grok-4 Fast Service - High-Performance AI Model Integration
 *
 * Features Grok-4 Fast from xAI for sub-second response times:
 * - Streaming support for real-time responses
 * - Smart model selection (reasoning vs non-reasoning)
 * - Intelligent request routing based on complexity
 * - Response caching for frequent patterns
 * - Circuit breaker integration
 * - Performance monitoring and optimization
 */

const axios = require('axios');
const { logger } = require('./logger');
const circuitBreakerService = require('./circuitBreaker');
const redisService = require('./redis');

class Grok4FastService {
    constructor() {
        this.apiKey = process.env.GROK_API_KEY;
        this.baseURL = process.env.GROK_API_URL || 'https://api.x.ai/v1';

        // Grok-4 Fast Models Configuration
        this.models = {
            // Fast reasoning model for complex analysis
            reasoning: {
                name: 'grok-4-fast-reasoning',
                contextWindow: 2000000, // 2M tokens
                timeout: 8000, // Target <2 seconds for reasoning
                temperature: 0.7,
                features: ['reasoning', 'analysis', 'complex_logic']
            },
            // Fast non-reasoning model for simple tasks
            nonReasoning: {
                name: 'grok-4-fast-non-reasoning',
                contextWindow: 2000000, // 2M tokens
                timeout: 3000, // Target <1 second for simple tasks
                temperature: 0.8,
                features: ['generation', 'creative_writing', 'quick_responses']
            }
        };

        // Performance optimization settings
        this.optimization = {
            // Response time targets
            targets: {
                simple: 1000,    // <1 second for simple flirts
                complex: 3000,   // <3 seconds for complex analysis
                streaming: 200   // <200ms for streaming start
            },

            // Caching configuration
            cache: {
                simple: 3600,    // 1 hour for simple responses
                complex: 1800,   // 30 minutes for complex responses
                frequent: 7200   // 2 hours for frequent patterns
            },

            // Parallel processing limits
            concurrency: {
                max: 5,          // Maximum concurrent requests
                perModel: 3      // Maximum per model
            }
        };

        // Request classification patterns
        this.classificationRules = {
            simple: [
                /^(hi|hello|hey|what's up)/i,
                /opener|greeting|simple/i,
                /short|quick|brief/i
            ],
            complex: [
                /analyze|analysis|detailed/i,
                /personality|psychology|deep/i,
                /comprehensive|thorough/i,
                /conversation.*history/i
            ],
            creative: [
                /creative|original|unique/i,
                /witty|clever|funny/i,
                /romantic|passionate|intimate/i
            ]
        };

        // Performance metrics
        this.metrics = {
            requests: 0,
            streamingRequests: 0,
            cacheHits: 0,
            reasoningModelUsage: 0,
            nonReasoningModelUsage: 0,
            averageLatency: 0,
            streamingLatency: 0,
            errors: 0
        };

        // Active streams tracking
        this.activeStreams = new Map();

        logger.info('Grok-4 Fast Service initialized', {
            models: Object.keys(this.models),
            apiConfigured: !!this.apiKey,
            streamingEnabled: true,
            performanceTargets: this.optimization.targets
        });
    }

    /**
     * Generate flirt suggestions with intelligent model selection
     * @param {Object} request - Generation request
     * @param {Object} options - Generation options
     * @returns {Promise<Object>} Generation response
     */
    async generateFlirts(request, options = {}) {
        const startTime = Date.now();
        const correlationId = request.correlationId || this.generateCorrelationId();

        try {
            // 1. Classify request complexity and select optimal model
            const requestClassification = this.classifyRequest(request);
            const selectedModel = this.selectOptimalModel(requestClassification, options);

            // 2. Check cache for similar requests
            const cacheResult = await this.checkCache(request, requestClassification);
            if (cacheResult.hit && !options.bypassCache) {
                this.metrics.cacheHits++;
                return this.formatCacheResponse(cacheResult.data, correlationId);
            }

            // 3. Determine if streaming is beneficial
            const useStreaming = this.shouldUseStreaming(requestClassification, options);

            // 4. Generate response using selected strategy
            let result;
            if (useStreaming && options.streamCallback) {
                result = await this.generateWithStreaming(
                    request, selectedModel, requestClassification, options, correlationId
                );
            } else {
                result = await this.generateStandard(
                    request, selectedModel, requestClassification, options, correlationId
                );
            }

            // 5. Cache high-quality results
            await this.cacheResult(request, result, requestClassification);

            // 6. Update metrics
            this.updateMetrics(startTime, selectedModel.name, useStreaming, true);

            const totalLatency = Date.now() - startTime;

            logger.info('Grok-4 Fast generation completed', {
                correlationId,
                model: selectedModel.name,
                classification: requestClassification.type,
                streaming: useStreaming,
                totalLatency: `${totalLatency}ms`,
                cacheHit: false,
                qualityScore: result.qualityScore
            });

            return {
                success: true,
                data: result,
                metadata: {
                    correlationId,
                    model: selectedModel.name,
                    classification: requestClassification,
                    streaming: useStreaming,
                    totalLatency,
                    timestamp: new Date().toISOString(),
                    version: 'grok-4-fast'
                }
            };

        } catch (error) {
            this.metrics.errors++;
            this.updateMetrics(startTime, null, false, false);

            logger.error('Grok-4 Fast generation failed', {
                correlationId,
                error: error.message,
                latency: Date.now() - startTime
            });

            // Fallback to legacy Grok if available
            return await this.handleFailureWithFallback(request, options, correlationId, error);
        }
    }

    /**
     * Classify request complexity and characteristics
     * @param {Object} request - Generation request
     * @returns {Object} Request classification
     */
    classifyRequest(request) {
        const context = (request.context || '').toLowerCase();
        const suggestionType = (request.suggestion_type || '').toLowerCase();
        const tone = (request.tone || '').toLowerCase();

        let complexity = 0;
        let characteristics = [];

        // Check for simple patterns
        const isSimple = this.classificationRules.simple.some(pattern =>
            pattern.test(context) || pattern.test(suggestionType)
        );

        // Check for complex patterns
        const isComplex = this.classificationRules.complex.some(pattern =>
            pattern.test(context) || pattern.test(suggestionType)
        );

        // Check for creative patterns
        const isCreative = this.classificationRules.creative.some(pattern =>
            pattern.test(context) || pattern.test(tone)
        );

        // Calculate complexity score
        if (isComplex) complexity += 0.7;
        if (isCreative) complexity += 0.3;
        if (request.imageData) complexity += 0.4;
        if (context.length > 500) complexity += 0.2;
        if (request.user_preferences && Object.keys(request.user_preferences).length > 0) complexity += 0.2;

        // Determine primary type
        let type;
        if (complexity >= 0.6) {
            type = 'complex';
            characteristics.push('requires_reasoning');
        } else if (isSimple || complexity <= 0.3) {
            type = 'simple';
            characteristics.push('fast_response');
        } else {
            type = 'standard';
            characteristics.push('balanced');
        }

        if (isCreative) characteristics.push('creative');
        if (request.imageData) characteristics.push('visual_context');
        if (request.isKeyboardExtension) {
            characteristics.push('keyboard_context');
            type = 'simple'; // Prefer fast response for keyboard
        }

        return {
            type,
            complexity,
            characteristics,
            estimatedTokens: this.estimateTokenUsage(request),
            priorityLevel: this.calculatePriority(request, complexity)
        };
    }

    /**
     * Select optimal model based on request classification
     * @param {Object} classification - Request classification
     * @param {Object} options - Generation options
     * @returns {Object} Selected model configuration
     */
    selectOptimalModel(classification, options) {
        // Force model selection if specified
        if (options.forceModel) {
            return this.models[options.forceModel] || this.models.nonReasoning;
        }

        // Select based on classification
        switch (classification.type) {
            case 'complex':
                if (classification.characteristics.includes('requires_reasoning')) {
                    return this.models.reasoning;
                }
                return this.models.nonReasoning;

            case 'simple':
                return this.models.nonReasoning;

            case 'standard':
            default:
                // Choose based on complexity score
                return classification.complexity > 0.5 ?
                    this.models.reasoning : this.models.nonReasoning;
        }
    }

    /**
     * Determine if streaming should be used
     * @param {Object} classification - Request classification
     * @param {Object} options - Generation options
     * @returns {boolean} Whether to use streaming
     */
    shouldUseStreaming(classification, options) {
        // User explicitly requested streaming
        if (options.streaming === true) return true;
        if (options.streaming === false) return false;

        // Don't stream for simple requests (they're fast enough)
        if (classification.type === 'simple') return false;

        // Don't stream for keyboard extension (prefer complete response)
        if (classification.characteristics.includes('keyboard_context')) return false;

        // Stream for complex requests and creative generation
        return classification.type === 'complex' ||
               classification.characteristics.includes('creative');
    }

    /**
     * Generate response with streaming for real-time updates
     * @param {Object} request - Generation request
     * @param {Object} model - Selected model
     * @param {Object} classification - Request classification
     * @param {Object} options - Generation options
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Streaming generation result
     */
    async generateWithStreaming(request, model, classification, options, correlationId) {
        const startTime = Date.now();
        this.metrics.streamingRequests++;

        try {
            const prompt = this.buildOptimizedPrompt(request, classification, model);
            const streamId = this.generateStreamId(correlationId);

            // Prepare streaming request
            const payload = {
                model: model.name,
                messages: [
                    {
                        role: "system",
                        content: this.getSystemPrompt(classification, model)
                    },
                    {
                        role: "user",
                        content: prompt
                    }
                ],
                max_tokens: this.calculateMaxTokens(classification),
                temperature: this.adjustTemperature(model.temperature, classification),
                top_p: 0.9,
                stream: true,
                response_format: { type: "json_object" }
            };

            let streamingResult = {
                suggestions: [],
                metadata: {},
                streamingData: {
                    streamId,
                    chunks: [],
                    startTime,
                    firstChunkTime: null,
                    completed: false
                }
            };

            // Track active stream
            this.activeStreams.set(streamId, {
                correlationId,
                startTime,
                model: model.name,
                status: 'active'
            });

            // Make streaming request through circuit breaker
            const response = await this.makeStreamingRequest(payload, correlationId);

            let buffer = '';
            let firstChunk = true;

            // Process streaming chunks
            for await (const chunk of response) {
                if (firstChunk) {
                    streamingResult.streamingData.firstChunkTime = Date.now();
                    this.metrics.streamingLatency = streamingResult.streamingData.firstChunkTime - startTime;
                    firstChunk = false;
                }

                const content = this.parseStreamChunk(chunk);
                if (content) {
                    buffer += content;
                    streamingResult.streamingData.chunks.push({
                        content,
                        timestamp: Date.now(),
                        length: content.length
                    });

                    // Send partial update to callback if available
                    if (options.streamCallback) {
                        options.streamCallback({
                            type: 'chunk',
                            data: content,
                            streamId,
                            metadata: {
                                chunkCount: streamingResult.streamingData.chunks.length,
                                totalLength: buffer.length
                            }
                        });
                    }
                }
            }

            // Parse final result
            const finalResult = this.parseStreamingResponse(buffer);
            streamingResult = { ...streamingResult, ...finalResult };
            streamingResult.streamingData.completed = true;

            // Mark stream as completed
            this.activeStreams.set(streamId, {
                ...this.activeStreams.get(streamId),
                status: 'completed',
                endTime: Date.now()
            });

            // Quality validation
            streamingResult.qualityScore = this.calculateQualityScore(streamingResult, classification);

            // Send completion callback
            if (options.streamCallback) {
                options.streamCallback({
                    type: 'complete',
                    data: streamingResult,
                    streamId,
                    metadata: {
                        totalLatency: Date.now() - startTime,
                        firstChunkLatency: streamingResult.streamingData.firstChunkTime - startTime,
                        qualityScore: streamingResult.qualityScore
                    }
                });
            }

            return streamingResult;

        } catch (error) {
            // Clean up failed stream
            if (streamId && this.activeStreams.has(streamId)) {
                this.activeStreams.set(streamId, {
                    ...this.activeStreams.get(streamId),
                    status: 'failed',
                    error: error.message
                });
            }

            logger.error('Streaming generation failed', {
                correlationId,
                model: model.name,
                error: error.message
            });

            throw error;
        }
    }

    /**
     * Generate response using standard (non-streaming) approach
     * @param {Object} request - Generation request
     * @param {Object} model - Selected model
     * @param {Object} classification - Request classification
     * @param {Object} options - Generation options
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Standard generation result
     */
    async generateStandard(request, model, classification, options, correlationId) {
        try {
            const prompt = this.buildOptimizedPrompt(request, classification, model);

            const payload = {
                model: model.name,
                messages: [
                    {
                        role: "system",
                        content: this.getSystemPrompt(classification, model)
                    },
                    {
                        role: "user",
                        content: prompt
                    }
                ],
                max_tokens: this.calculateMaxTokens(classification),
                temperature: this.adjustTemperature(model.temperature, classification),
                top_p: 0.9,
                response_format: { type: "json_object" }
            };

            // Make request through circuit breaker with optimized timeout
            const response = await circuitBreakerService.callGrokApi(payload, correlationId);

            if (!response.success) {
                throw new Error(response.error || 'Grok-4 Fast API call failed');
            }

            // Parse and validate response
            const result = this.parseStandardResponse(response.data);
            result.qualityScore = this.calculateQualityScore(result, classification);

            return result;

        } catch (error) {
            logger.error('Standard generation failed', {
                correlationId,
                model: model.name,
                error: error.message
            });
            throw error;
        }
    }

    /**
     * Build optimized prompt for Grok-4 Fast
     * @param {Object} request - Generation request
     * @param {Object} classification - Request classification
     * @param {Object} model - Selected model
     * @returns {string} Optimized prompt
     */
    buildOptimizedPrompt(request, classification, model) {
        const isReasoning = model.name.includes('reasoning');
        const tone = request.tone || 'playful';
        const suggestionType = request.suggestion_type || 'opener';

        let prompt = '';

        if (isReasoning) {
            // More detailed prompt for reasoning model
            prompt = `Generate ${suggestionType} suggestions for dating conversation with comprehensive analysis.

CONTEXT ANALYSIS:
- Platform: ${request.platform || 'dating app'}
- Conversation Stage: ${this.inferConversationStage(request)}
- User Context: ${request.context || 'No specific context provided'}
- Requested Tone: ${tone}
- Classification: ${classification.type} (complexity: ${classification.complexity.toFixed(2)})

REASONING REQUIREMENTS:
1. Analyze the context and user characteristics
2. Consider the conversation stage and momentum
3. Evaluate tone appropriateness and personality fit
4. Generate contextually relevant suggestions
5. Ensure uniqueness and engagement potential

QUALITY TARGETS:
- Uniqueness: >0.85
- Context Relevance: >0.90
- Tone Consistency: >0.95
- Engagement Potential: >0.80`;

        } else {
            // Streamlined prompt for non-reasoning model
            prompt = `Generate ${suggestionType} suggestions for dating conversation.

CONTEXT: ${request.context || 'General dating conversation'}
TONE: ${tone}
TYPE: ${suggestionType}

REQUIREMENTS:
- Generate 6 unique suggestions
- Match ${tone} tone perfectly
- Keep under 280 characters each
- High engagement potential
- Contextually appropriate`;
        }

        prompt += `

USER PREFERENCES:
${request.user_preferences ? JSON.stringify(request.user_preferences, null, 2) : 'None specified'}

RESPONSE FORMAT:
{
  "suggestions": [
    {
      "text": "suggestion text here",
      "confidence": 0.90,
      "reasoning": "why this works",
      "tone": "${tone}",
      "topics": ["relevant", "topics"],
      "uniquenessScore": 0.85,
      "engagementPotential": 0.90,
      "characterCount": 45
    }
  ],
  "metadata": {
    "model": "${model.name}",
    "generationStrategy": "optimized",
    "contextUtilization": 0.95,
    "averageConfidence": 0.88,
    "responseTime": "fast"
  }
}`;

        return prompt;
    }

    /**
     * Get system prompt optimized for model type
     * @param {Object} classification - Request classification
     * @param {Object} model - Selected model
     * @returns {string} System prompt
     */
    getSystemPrompt(classification, model) {
        const isReasoning = model.name.includes('reasoning');

        if (isReasoning) {
            return `You are Vibe8.ai's advanced reasoning engine powered by Grok-4 Fast.

CAPABILITIES:
- Deep context analysis and pattern recognition
- Multi-step reasoning for optimal response generation
- Personality and conversation stage assessment
- Advanced tone matching and style adaptation

SPECIALIZATION:
- Dating conversation psychology
- Context-aware response optimization
- Engagement potential maximization
- Real-time conversation flow analysis

REASONING MODE: Use your advanced reasoning capabilities to analyze context deeply and generate highly targeted, personalized suggestions.

PERFORMANCE TARGET: Generate high-quality responses with reasoning transparency.`;

        } else {
            return `You are Vibe8.ai's high-speed generation engine powered by Grok-4 Fast.

MISSION: Generate engaging, contextually appropriate dating conversation suggestions with maximum speed and quality.

SPECIALIZATION:
- Rapid response generation
- Tone consistency and style matching
- Creative and unique suggestion creation
- Dating conversation optimization

SPEED MODE: Prioritize fast, high-quality generation while maintaining contextual relevance and engagement potential.

PERFORMANCE TARGET: Sub-second response times with consistent quality.`;
        }
    }

    /**
     * Make streaming request to Grok-4 Fast API
     * @param {Object} payload - Request payload
     * @param {string} correlationId - Correlation ID
     * @returns {AsyncIterable} Streaming response
     */
    async makeStreamingRequest(payload, correlationId) {
        const response = await axios.post(
            `${this.baseURL}/chat/completions`,
            payload,
            {
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json'
                },
                responseType: 'stream',
                timeout: this.optimization.targets.complex
            }
        );

        return this.parseServerSentEvents(response.data);
    }

    /**
     * Parse Server-Sent Events from streaming response
     * @param {Stream} stream - Response stream
     * @returns {AsyncIterable} Parsed events
     */
    async* parseServerSentEvents(stream) {
        let buffer = '';

        for await (const chunk of stream) {
            buffer += chunk.toString();
            const lines = buffer.split('\n');
            buffer = lines.pop() || ''; // Keep the last incomplete line

            for (const line of lines) {
                if (line.startsWith('data: ')) {
                    const data = line.slice(6);
                    if (data === '[DONE]') {
                        return;
                    }
                    try {
                        yield JSON.parse(data);
                    } catch (error) {
                        logger.warn('Failed to parse streaming chunk', {
                            data,
                            error: error.message
                        });
                    }
                }
            }
        }
    }

    /**
     * Parse content from streaming chunk
     * @param {Object} chunk - Streaming chunk
     * @returns {string|null} Extracted content
     */
    parseStreamChunk(chunk) {
        try {
            if (chunk.choices && chunk.choices[0] && chunk.choices[0].delta) {
                return chunk.choices[0].delta.content || null;
            }
            return null;
        } catch (error) {
            logger.warn('Failed to parse stream chunk content', { error: error.message });
            return null;
        }
    }

    /**
     * Parse final streaming response
     * @param {string} buffer - Accumulated response buffer
     * @returns {Object} Parsed response
     */
    parseStreamingResponse(buffer) {
        try {
            // Try to extract JSON from the buffer
            const jsonMatch = buffer.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                const parsed = JSON.parse(jsonMatch[0]);
                return this.validateAndEnhanceResponse(parsed);
            } else {
                throw new Error('No valid JSON found in streaming response');
            }
        } catch (error) {
            logger.error('Failed to parse streaming response', {
                error: error.message,
                bufferLength: buffer.length
            });

            // Return fallback response
            return this.generateFallbackResponse('streaming_parse_error');
        }
    }

    /**
     * Parse standard (non-streaming) response
     * @param {Object} response - API response
     * @returns {Object} Parsed response
     */
    parseStandardResponse(response) {
        try {
            const content = response.choices[0].message.content;
            const parsed = JSON.parse(content);
            return this.validateAndEnhanceResponse(parsed);
        } catch (error) {
            logger.error('Failed to parse standard response', { error: error.message });
            return this.generateFallbackResponse('standard_parse_error');
        }
    }

    /**
     * Validate and enhance parsed response
     * @param {Object} parsed - Parsed response
     * @returns {Object} Enhanced response
     */
    validateAndEnhanceResponse(parsed) {
        // Ensure suggestions array exists and is valid
        if (!parsed.suggestions || !Array.isArray(parsed.suggestions)) {
            parsed.suggestions = [];
        }

        // Validate and enhance each suggestion
        parsed.suggestions = parsed.suggestions
            .filter(s => s && s.text && s.text.trim().length > 0)
            .map((suggestion, index) => ({
                id: `grok4_${Date.now()}_${index}`,
                text: suggestion.text.trim(),
                confidence: Math.max(0, Math.min(1, suggestion.confidence || 0.8)),
                reasoning: suggestion.reasoning || 'Generated by Grok-4 Fast',
                tone: suggestion.tone || 'friendly',
                topics: Array.isArray(suggestion.topics) ? suggestion.topics : ['general'],
                uniquenessScore: Math.max(0, Math.min(1, suggestion.uniquenessScore || 0.7)),
                engagementPotential: Math.max(0, Math.min(1, suggestion.engagementPotential || 0.75)),
                characterCount: suggestion.text.trim().length,
                model: 'grok-4-fast',
                timestamp: new Date().toISOString()
            }))
            .slice(0, 6); // Limit to 6 suggestions

        // Ensure metadata exists
        parsed.metadata = parsed.metadata || {};
        parsed.metadata.totalSuggestions = parsed.suggestions.length;
        parsed.metadata.averageConfidence = parsed.suggestions.length > 0 ?
            parsed.suggestions.reduce((sum, s) => sum + s.confidence, 0) / parsed.suggestions.length : 0;

        return parsed;
    }

    /**
     * Generate fallback response for errors
     * @param {string} errorType - Type of error
     * @returns {Object} Fallback response
     */
    generateFallbackResponse(errorType) {
        const fallbackSuggestions = [
            "I love your energy - tell me more about what makes you excited!",
            "Your profile caught my attention - what's the story behind that smile?",
            "I have to ask... what's been the highlight of your week so far?",
            "Something tells me you have some interesting stories to share",
            "Your vibe seems really genuine - that's refreshing to see"
        ];

        return {
            suggestions: fallbackSuggestions.slice(0, 3).map((text, index) => ({
                id: `fallback_${Date.now()}_${index}`,
                text,
                confidence: 0.6,
                reasoning: `Fallback suggestion due to ${errorType}`,
                tone: 'friendly',
                topics: ['general'],
                uniquenessScore: 0.5,
                engagementPotential: 0.7,
                characterCount: text.length,
                model: 'grok-4-fast-fallback',
                fallback: true
            })),
            metadata: {
                fallback: true,
                errorType,
                totalSuggestions: 3,
                averageConfidence: 0.6
            }
        };
    }

    /**
     * Calculate quality score for generated response
     * @param {Object} result - Generated result
     * @param {Object} classification - Request classification
     * @returns {number} Quality score 0-1
     */
    calculateQualityScore(result, classification) {
        if (!result.suggestions || result.suggestions.length === 0) return 0;

        let totalScore = 0;
        const suggestions = result.suggestions;

        suggestions.forEach(suggestion => {
            let score = 0;

            // Confidence score (30%)
            score += (suggestion.confidence || 0) * 0.3;

            // Uniqueness score (25%)
            score += (suggestion.uniquenessScore || 0) * 0.25;

            // Engagement potential (25%)
            score += (suggestion.engagementPotential || 0) * 0.25;

            // Length appropriateness (10%)
            const length = suggestion.characterCount || 0;
            if (length >= 20 && length <= 280) {
                score += 0.1;
            } else if (length > 280) {
                score += 0.05; // Penalty for too long
            }

            // Context relevance (10%)
            if (suggestion.topics && suggestion.topics.length > 0) {
                score += 0.05;
            }
            if (classification.characteristics.includes('creative') &&
                suggestion.uniquenessScore > 0.8) {
                score += 0.05;
            }

            totalScore += score;
        });

        return Math.max(0, Math.min(1, totalScore / suggestions.length));
    }

    /**
     * Check cache for existing responses
     * @param {Object} request - Generation request
     * @param {Object} classification - Request classification
     * @returns {Promise<Object>} Cache check result
     */
    async checkCache(request, classification) {
        try {
            const cacheKey = this.generateCacheKey(request, classification);
            const cached = await redisService.get(cacheKey);

            if (cached) {
                // Check if cache is still valid based on classification
                const cacheAge = Date.now() - new Date(cached.timestamp).getTime();
                const maxAge = this.optimization.cache[classification.type] * 1000;

                if (cacheAge < maxAge) {
                    return { hit: true, data: cached };
                }
            }

            return { hit: false, data: null };

        } catch (error) {
            logger.warn('Cache check failed', { error: error.message });
            return { hit: false, data: null };
        }
    }

    /**
     * Cache generation result
     * @param {Object} request - Original request
     * @param {Object} result - Generation result
     * @param {Object} classification - Request classification
     */
    async cacheResult(request, result, classification) {
        try {
            // Only cache high-quality results
            if (result.qualityScore >= 0.7) {
                const cacheKey = this.generateCacheKey(request, classification);
                const cacheData = {
                    ...result,
                    timestamp: new Date().toISOString(),
                    cacheType: classification.type
                };

                const ttl = this.optimization.cache[classification.type];
                await redisService.set(cacheKey, cacheData, ttl);

                logger.debug('Result cached', {
                    cacheKey: cacheKey.substring(0, 20) + '...',
                    qualityScore: result.qualityScore,
                    ttl
                });
            }
        } catch (error) {
            logger.warn('Failed to cache result', { error: error.message });
        }
    }

    /**
     * Generate cache key for request
     * @param {Object} request - Generation request
     * @param {Object} classification - Request classification
     * @returns {string} Cache key
     */
    generateCacheKey(request, classification) {
        const crypto = require('crypto');
        const keyData = {
            context: request.context,
            suggestion_type: request.suggestion_type,
            tone: request.tone,
            classification: classification.type,
            hasImage: !!request.imageData,
            preferences: request.user_preferences
        };

        const hash = crypto.createHash('md5')
            .update(JSON.stringify(keyData))
            .digest('hex');

        return `grok4_cache:${hash}`;
    }

    /**
     * Handle failure with fallback to legacy Grok
     * @param {Object} request - Original request
     * @param {Object} options - Generation options
     * @param {string} correlationId - Correlation ID
     * @param {Error} originalError - Original error
     * @returns {Promise<Object>} Fallback response
     */
    async handleFailureWithFallback(request, options, correlationId, originalError) {
        try {
            logger.info('Attempting fallback to legacy Grok', { correlationId });

            // Try legacy circuit breaker approach
            const legacyPayload = {
                model: 'grok-4-fast',
                messages: [
                    {
                        role: "user",
                        content: `Generate dating conversation suggestions for: ${request.context || 'general conversation'}`
                    }
                ],
                max_tokens: 1000,
                temperature: 0.8
            };

            const fallbackResponse = await circuitBreakerService.callGrokApi(legacyPayload, correlationId);

            if (fallbackResponse.success) {
                return {
                    success: true,
                    data: this.parseLegacyResponse(fallbackResponse.data),
                    metadata: {
                        correlationId,
                        fallback: true,
                        originalError: originalError.message,
                        fallbackModel: 'grok-4-fast'
                    }
                };
            }

            throw new Error('Legacy fallback also failed');

        } catch (fallbackError) {
            logger.error('All fallback attempts failed', {
                correlationId,
                originalError: originalError.message,
                fallbackError: fallbackError.message
            });

            // Return emergency fallback
            return {
                success: true,
                data: this.generateFallbackResponse('all_fallbacks_failed'),
                metadata: {
                    correlationId,
                    emergency: true,
                    originalError: originalError.message
                }
            };
        }
    }

    /**
     * Parse legacy Grok response
     * @param {Object} response - Legacy response
     * @returns {Object} Parsed response
     */
    parseLegacyResponse(response) {
        try {
            const content = response.choices[0].message.content;

            // Simple parsing for legacy response
            const suggestions = content.split('\n')
                .filter(line => line.trim().length > 0)
                .slice(0, 6)
                .map((text, index) => ({
                    id: `legacy_${Date.now()}_${index}`,
                    text: text.replace(/^\d+\.\s*/, '').trim(),
                    confidence: 0.7,
                    reasoning: 'Generated by legacy Grok',
                    tone: 'friendly',
                    topics: ['general'],
                    uniquenessScore: 0.6,
                    engagementPotential: 0.7,
                    characterCount: text.length,
                    model: 'grok-4-fast-fallback'
                }));

            return {
                suggestions,
                metadata: {
                    legacy: true,
                    totalSuggestions: suggestions.length,
                    averageConfidence: 0.7
                },
                qualityScore: 0.65
            };

        } catch (error) {
            logger.error('Failed to parse legacy response', { error: error.message });
            return this.generateFallbackResponse('legacy_parse_error');
        }
    }

    /**
     * Helper Methods
     */

    inferConversationStage(request) {
        const context = (request.context || '').toLowerCase();

        if (context.includes('first') || context.includes('opener')) return 'opening';
        if (context.includes('getting to know') || context.includes('rapport')) return 'building_rapport';
        if (context.includes('flirt') || context.includes('playful')) return 'flirting';
        if (context.includes('meet') || context.includes('date')) return 'planning_meetup';

        return 'building_rapport';
    }

    estimateTokenUsage(request) {
        let tokens = 0;

        if (request.context) tokens += Math.ceil(request.context.length / 4);
        if (request.user_preferences) tokens += Math.ceil(JSON.stringify(request.user_preferences).length / 4);
        if (request.imageData) tokens += 1000; // Approximate for image

        return tokens + 500; // Base prompt tokens
    }

    calculatePriority(request, complexity) {
        let priority = 0.5; // Base priority

        if (request.isKeyboardExtension) priority += 0.3; // Higher priority for keyboard
        if (complexity > 0.7) priority += 0.2; // Higher priority for complex requests
        if (request.urgent) priority += 0.3;

        return Math.min(1.0, priority);
    }

    calculateMaxTokens(classification) {
        switch (classification.type) {
            case 'simple': return 800;
            case 'complex': return 1500;
            default: return 1200;
        }
    }

    adjustTemperature(baseTemperature, classification) {
        if (classification.characteristics.includes('creative')) {
            return Math.min(1.0, baseTemperature + 0.1);
        }
        if (classification.type === 'simple') {
            return Math.max(0.3, baseTemperature - 0.1);
        }
        return baseTemperature;
    }

    formatCacheResponse(cachedData, correlationId) {
        return {
            success: true,
            data: {
                ...cachedData,
                fromCache: true,
                cacheRetrievedAt: new Date().toISOString()
            },
            metadata: {
                correlationId,
                cached: true,
                cacheAge: Date.now() - new Date(cachedData.timestamp).getTime(),
                version: 'grok-4-fast'
            }
        };
    }

    updateMetrics(startTime, modelName, streaming, success) {
        const latency = Date.now() - startTime;

        this.metrics.requests++;

        if (success) {
            // Update average latency with exponential moving average
            this.metrics.averageLatency = this.metrics.averageLatency === 0 ?
                latency : (this.metrics.averageLatency * 0.9 + latency * 0.1);

            if (streaming) {
                this.metrics.streamingLatency = this.metrics.streamingLatency === 0 ?
                    latency : (this.metrics.streamingLatency * 0.9 + latency * 0.1);
            }
        } else {
            this.metrics.errors++;
        }

        if (modelName) {
            if (modelName.includes('reasoning')) {
                this.metrics.reasoningModelUsage++;
            } else {
                this.metrics.nonReasoningModelUsage++;
            }
        }
    }

    generateCorrelationId() {
        return `grok4_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    generateStreamId(correlationId) {
        return `stream_${correlationId}_${Date.now()}`;
    }

    /**
     * Public API Methods
     */

    /**
     * Get service health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        const totalRequests = this.metrics.requests;
        const successRate = totalRequests > 0 ?
            ((totalRequests - this.metrics.errors) / totalRequests * 100).toFixed(2) + '%' : '100%';

        return {
            status: this.metrics.errors / Math.max(totalRequests, 1) < 0.1 ? 'healthy' : 'degraded',
            version: 'grok-4-fast',
            models: this.models,
            metrics: {
                ...this.metrics,
                successRate,
                cacheHitRate: totalRequests > 0 ?
                    (this.metrics.cacheHits / totalRequests * 100).toFixed(2) + '%' : '0%'
            },
            activeStreams: this.activeStreams.size,
            performanceTargets: this.optimization.targets,
            apiConfigured: !!this.apiKey,
            lastChecked: new Date().toISOString()
        };
    }

    /**
     * Get performance metrics
     * @returns {Object} Performance metrics
     */
    getPerformanceMetrics() {
        return {
            ...this.metrics,
            modelDistribution: {
                reasoning: this.metrics.reasoningModelUsage,
                nonReasoning: this.metrics.nonReasoningModelUsage,
                total: this.metrics.requests
            },
            averageLatencies: {
                overall: Math.round(this.metrics.averageLatency),
                streaming: Math.round(this.metrics.streamingLatency),
                target: this.optimization.targets
            },
            cachePerformance: {
                hits: this.metrics.cacheHits,
                requests: this.metrics.requests,
                hitRate: this.metrics.requests > 0 ?
                    (this.metrics.cacheHits / this.metrics.requests * 100).toFixed(2) + '%' : '0%'
            }
        };
    }

    /**
     * Reset metrics (for testing)
     */
    resetMetrics() {
        this.metrics = {
            requests: 0,
            streamingRequests: 0,
            cacheHits: 0,
            reasoningModelUsage: 0,
            nonReasoningModelUsage: 0,
            averageLatency: 0,
            streamingLatency: 0,
            errors: 0
        };

        this.activeStreams.clear();

        logger.info('Grok-4 Fast metrics reset');
    }
}

// Export singleton instance
const grok4FastService = new Grok4FastService();
module.exports = grok4FastService;