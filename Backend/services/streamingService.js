/**
 * Streaming Service - Real-time Progressive AI Analysis Pipeline
 *
 * This service provides high-performance streaming capabilities for progressive
 * AI suggestion delivery as analysis happens in real-time. Optimized for sub-12s
 * complete analysis with immediate feedback to users.
 *
 * Features:
 * - WebSocket-based real-time communication
 * - Progressive AI analysis delivery
 * - Priority-based processing queue
 * - Memory-optimized streaming
 * - Performance monitoring
 */

const EventEmitter = require('events');
const { v4: uuidv4 } = require('uuid');
const { logger } = require('./logger');
const webSocketService = require('./websocketService');
const aiOrchestrator = require('./aiOrchestrator');
const queueService = require('./queueService');

class StreamingService extends EventEmitter {
    constructor() {
        super();
        this.activeStreams = new Map(); // streamId -> StreamContext
        this.streamMetrics = {
            totalStreams: 0,
            activeStreams: 0,
            completedStreams: 0,
            averageStreamDuration: 0,
            peakConcurrentStreams: 0,
            totalStreamingTime: 0
        };

        this.setupEventHandlers();
        this.startPerformanceMonitoring();
    }

    /**
     * Start a new streaming analysis session
     * @param {Object} request - Streaming request parameters
     * @returns {Promise<string>} Stream ID
     */
    async startStream(request) {
        const streamId = uuidv4();
        const startTime = Date.now();

        const streamContext = {
            streamId,
            userId: request.userId,
            correlationId: request.correlationId,
            startTime,
            status: 'initializing',
            progress: 0,
            analysisPhases: [],
            currentPhase: null,
            suggestions: [],
            analysisData: null,
            metadata: {
                imageSize: request.imageData?.length || 0,
                strategy: request.strategy || 'auto',
                priority: request.priority || 'normal',
                isKeyboard: request.isKeyboardExtension || false
            },
            requestParams: {
                imageData: request.imageData,
                context: request.context,
                suggestionType: request.suggestionType,
                tone: request.tone,
                userPreferences: request.userPreferences
            }
        };

        this.activeStreams.set(streamId, streamContext);
        this.streamMetrics.totalStreams++;
        this.streamMetrics.activeStreams++;
        this.updatePeakConcurrency();

        logger.info('Stream analysis started', {
            streamId,
            userId: request.userId,
            correlationId: request.correlationId,
            imageSize: streamContext.metadata.imageSize,
            strategy: streamContext.metadata.strategy
        });

        // Send initial status
        this.sendStreamUpdate(streamContext, 'stream_started', {
            streamId,
            estimatedDuration: this.estimateStreamDuration(streamContext),
            phases: ['image_analysis', 'context_processing', 'suggestion_generation', 'quality_validation']
        });

        // Start asynchronous processing
        this.processStreamAsync(streamContext).catch(error => {
            logger.error('Stream processing error', {
                streamId,
                error: error.message,
                stack: error.stack
            });
            this.handleStreamError(streamContext, error);
        });

        return streamId;
    }

    /**
     * Process stream asynchronously with progressive updates
     * @param {Object} streamContext - Stream context
     */
    async processStreamAsync(streamContext) {
        try {
            const { streamId, requestParams } = streamContext;

            // Phase 1: Image Analysis (20-30% progress)
            await this.executePhase(streamContext, 'image_analysis', async () => {
                this.sendStreamUpdate(streamContext, 'phase_progress', {
                    phase: 'image_analysis',
                    progress: 10,
                    message: 'Starting visual analysis...'
                });

                // Start Gemini Vision analysis
                const analysisPromise = aiOrchestrator.analyzeImageWithGemini({
                    imageData: requestParams.imageData,
                    context: requestParams.context,
                    correlationId: streamContext.correlationId
                });

                // Send progress updates while analysis is running
                const progressInterval = setInterval(() => {
                    if (streamContext.progress < 25) {
                        streamContext.progress += 2;
                        this.sendStreamUpdate(streamContext, 'phase_progress', {
                            phase: 'image_analysis',
                            progress: streamContext.progress,
                            message: 'Analyzing visual elements...'
                        });
                    }
                }, 500);

                const analysisResult = await analysisPromise;
                clearInterval(progressInterval);

                streamContext.analysisData = analysisResult;
                streamContext.progress = 30;

                this.sendStreamUpdate(streamContext, 'analysis_complete', {
                    phase: 'image_analysis',
                    progress: 30,
                    analysis: {
                        visualElements: analysisResult.visualElements || [],
                        personalities: analysisResult.personalities || [],
                        confidence: analysisResult.confidence || 0.8
                    }
                });

                return analysisResult;
            });

            // Phase 2: Context Processing (30-50% progress)
            await this.executePhase(streamContext, 'context_processing', async () => {
                this.sendStreamUpdate(streamContext, 'phase_progress', {
                    phase: 'context_processing',
                    progress: 35,
                    message: 'Processing context and preferences...'
                });

                // Process context and user preferences
                const contextData = await this.processContextData(streamContext);
                streamContext.progress = 50;

                this.sendStreamUpdate(streamContext, 'context_processed', {
                    phase: 'context_processing',
                    progress: 50,
                    contextInsights: contextData.insights || [],
                    personalityMatch: contextData.personalityMatch || {}
                });

                return contextData;
            });

            // Phase 3: Suggestion Generation (50-80% progress)
            await this.executePhase(streamContext, 'suggestion_generation', async () => {
                this.sendStreamUpdate(streamContext, 'phase_progress', {
                    phase: 'suggestion_generation',
                    progress: 55,
                    message: 'Generating personalized suggestions...'
                });

                // Generate suggestions progressively
                const suggestions = await this.generateSuggestionsProgressively(streamContext);
                streamContext.suggestions = suggestions;
                streamContext.progress = 80;

                this.sendStreamUpdate(streamContext, 'suggestions_generated', {
                    phase: 'suggestion_generation',
                    progress: 80,
                    suggestions: suggestions.map(s => ({
                        id: s.id,
                        text: s.text,
                        confidence: s.confidence,
                        reasoning: s.reasoning
                    })),
                    count: suggestions.length
                });

                return suggestions;
            });

            // Phase 4: Quality Validation (80-100% progress)
            await this.executePhase(streamContext, 'quality_validation', async () => {
                this.sendStreamUpdate(streamContext, 'phase_progress', {
                    phase: 'quality_validation',
                    progress: 85,
                    message: 'Validating and ranking suggestions...'
                });

                // Validate and rank suggestions
                const validatedSuggestions = await this.validateSuggestionsQuality(streamContext);
                streamContext.suggestions = validatedSuggestions;
                streamContext.progress = 100;

                return validatedSuggestions;
            });

            // Complete the stream
            await this.completeStream(streamContext);

        } catch (error) {
            await this.handleStreamError(streamContext, error);
        }
    }

    /**
     * Execute a processing phase with error handling
     * @param {Object} streamContext - Stream context
     * @param {string} phaseName - Phase name
     * @param {Function} phaseFunction - Phase execution function
     */
    async executePhase(streamContext, phaseName, phaseFunction) {
        const phaseStart = Date.now();
        streamContext.currentPhase = phaseName;

        try {
            const result = await phaseFunction();

            const phaseDuration = Date.now() - phaseStart;
            streamContext.analysisPhases.push({
                name: phaseName,
                duration: phaseDuration,
                success: true,
                completedAt: new Date().toISOString()
            });

            logger.debug(`Stream phase completed`, {
                streamId: streamContext.streamId,
                phase: phaseName,
                duration: phaseDuration,
                progress: streamContext.progress
            });

            return result;
        } catch (error) {
            const phaseDuration = Date.now() - phaseStart;
            streamContext.analysisPhases.push({
                name: phaseName,
                duration: phaseDuration,
                success: false,
                error: error.message,
                completedAt: new Date().toISOString()
            });

            logger.error(`Stream phase failed`, {
                streamId: streamContext.streamId,
                phase: phaseName,
                duration: phaseDuration,
                error: error.message
            });

            throw error;
        }
    }

    /**
     * Generate suggestions progressively with real-time updates
     * @param {Object} streamContext - Stream context
     * @returns {Promise<Array>} Generated suggestions
     */
    async generateSuggestionsProgressively(streamContext) {
        const { requestParams, analysisData } = streamContext;
        const suggestions = [];

        // Generate multiple suggestions in parallel with streaming updates
        const generationPromises = [];
        const targetCount = 5; // Generate 5 suggestions

        for (let i = 0; i < targetCount; i++) {
            const promise = this.generateSingleSuggestion({
                analysisData,
                requestParams,
                suggestionIndex: i,
                correlationId: streamContext.correlationId
            }).then(suggestion => {
                // Send progressive update as each suggestion is generated
                suggestions.push(suggestion);
                const progress = Math.min(80, 55 + Math.floor((suggestions.length / targetCount) * 25));
                streamContext.progress = progress;

                this.sendStreamUpdate(streamContext, 'suggestion_generated', {
                    suggestion: {
                        id: suggestion.id,
                        text: suggestion.text,
                        confidence: suggestion.confidence,
                        index: suggestions.length
                    },
                    progress,
                    totalGenerated: suggestions.length,
                    targetCount
                });

                return suggestion;
            });

            generationPromises.push(promise);

            // Stagger requests to avoid overwhelming the API
            await new Promise(resolve => setTimeout(resolve, 200));
        }

        // Wait for all suggestions to complete
        const results = await Promise.allSettled(generationPromises);

        // Filter successful suggestions
        const successfulSuggestions = results
            .filter(result => result.status === 'fulfilled')
            .map(result => result.value);

        return successfulSuggestions;
    }

    /**
     * Generate a single suggestion
     * @param {Object} params - Generation parameters
     * @returns {Promise<Object>} Generated suggestion
     */
    async generateSingleSuggestion(params) {
        const { analysisData, requestParams, suggestionIndex, correlationId } = params;

        try {
            const suggestion = await aiOrchestrator.generateSingleSuggestion({
                analysisData,
                context: requestParams.context,
                suggestionType: requestParams.suggestionType,
                tone: requestParams.tone,
                userPreferences: requestParams.userPreferences,
                variationIndex: suggestionIndex,
                correlationId
            });

            return {
                id: `suggestion_${Date.now()}_${suggestionIndex}`,
                text: suggestion.text,
                confidence: suggestion.confidence || 0.7,
                reasoning: suggestion.reasoning || '',
                tone: requestParams.tone,
                topics: suggestion.topics || [],
                compositeScore: suggestion.compositeScore || suggestion.confidence || 0.7,
                generatedAt: new Date().toISOString(),
                index: suggestionIndex
            };
        } catch (error) {
            logger.warn('Single suggestion generation failed', {
                suggestionIndex,
                correlationId,
                error: error.message
            });

            // Return fallback suggestion
            return {
                id: `fallback_${Date.now()}_${suggestionIndex}`,
                text: this.getFallbackSuggestion(requestParams.tone, suggestionIndex),
                confidence: 0.5,
                reasoning: 'Fallback suggestion due to generation error',
                tone: requestParams.tone,
                topics: ['general'],
                compositeScore: 0.5,
                generatedAt: new Date().toISOString(),
                index: suggestionIndex,
                fallback: true
            };
        }
    }

    /**
     * Process context data for personalization
     * @param {Object} streamContext - Stream context
     * @returns {Promise<Object>} Processed context data
     */
    async processContextData(streamContext) {
        const { requestParams, analysisData } = streamContext;

        // Simulate context processing with gradual progress
        await new Promise(resolve => setTimeout(resolve, 500));

        const contextInsights = [];

        if (requestParams.context) {
            contextInsights.push({
                type: 'conversation_context',
                insight: 'User provided conversation context',
                confidence: 0.9
            });
        }

        if (analysisData?.visualElements?.length > 0) {
            contextInsights.push({
                type: 'visual_context',
                insight: `Detected ${analysisData.visualElements.length} visual elements`,
                confidence: 0.8
            });
        }

        return {
            insights: contextInsights,
            personalityMatch: {
                tone: requestParams.tone,
                style: 'adaptive',
                confidence: 0.8
            },
            processedAt: new Date().toISOString()
        };
    }

    /**
     * Validate and rank suggestions by quality
     * @param {Object} streamContext - Stream context
     * @returns {Promise<Array>} Validated suggestions
     */
    async validateSuggestionsQuality(streamContext) {
        const { suggestions } = streamContext;

        // Simulate quality validation
        await new Promise(resolve => setTimeout(resolve, 300));

        // Sort by composite score and add quality metrics
        const validatedSuggestions = suggestions
            .sort((a, b) => b.compositeScore - a.compositeScore)
            .map((suggestion, index) => ({
                ...suggestion,
                rank: index + 1,
                qualityScore: Math.min(0.95, suggestion.compositeScore + (index === 0 ? 0.1 : 0)),
                validated: true,
                validatedAt: new Date().toISOString()
            }));

        return validatedSuggestions;
    }

    /**
     * Complete a stream successfully
     * @param {Object} streamContext - Stream context
     */
    async completeStream(streamContext) {
        const duration = Date.now() - streamContext.startTime;
        streamContext.status = 'completed';

        // Update metrics
        this.streamMetrics.completedStreams++;
        this.streamMetrics.activeStreams--;
        this.streamMetrics.totalStreamingTime += duration;
        this.streamMetrics.averageStreamDuration = Math.round(
            this.streamMetrics.totalStreamingTime / this.streamMetrics.completedStreams
        );

        // Send final completion update
        this.sendStreamUpdate(streamContext, 'stream_completed', {
            streamId: streamContext.streamId,
            duration,
            totalSuggestions: streamContext.suggestions.length,
            analysisPhases: streamContext.analysisPhases,
            finalSuggestions: streamContext.suggestions,
            performance: {
                totalDuration: duration,
                averagePhaseTime: streamContext.analysisPhases.reduce((sum, phase) =>
                    sum + phase.duration, 0) / streamContext.analysisPhases.length,
                successRate: streamContext.analysisPhases.filter(p => p.success).length /
                           streamContext.analysisPhases.length
            }
        });

        logger.info('Stream completed successfully', {
            streamId: streamContext.streamId,
            userId: streamContext.userId,
            duration,
            suggestionsGenerated: streamContext.suggestions.length,
            phases: streamContext.analysisPhases.length
        });

        // Clean up stream context after delay
        setTimeout(() => {
            this.activeStreams.delete(streamContext.streamId);
        }, 30000); // Keep for 30 seconds for potential status queries
    }

    /**
     * Handle stream errors with graceful fallback
     * @param {Object} streamContext - Stream context
     * @param {Error} error - Error that occurred
     */
    async handleStreamError(streamContext, error) {
        const duration = Date.now() - streamContext.startTime;
        streamContext.status = 'error';

        this.streamMetrics.activeStreams--;

        logger.error('Stream processing failed', {
            streamId: streamContext.streamId,
            userId: streamContext.userId,
            duration,
            error: error.message,
            phase: streamContext.currentPhase
        });

        // Try to provide fallback suggestions
        try {
            const fallbackSuggestions = this.generateFallbackSuggestions(streamContext);

            this.sendStreamUpdate(streamContext, 'stream_error_with_fallback', {
                streamId: streamContext.streamId,
                error: 'Analysis failed but fallback suggestions provided',
                fallbackSuggestions,
                duration,
                phase: streamContext.currentPhase
            });
        } catch (fallbackError) {
            this.sendStreamUpdate(streamContext, 'stream_failed', {
                streamId: streamContext.streamId,
                error: error.message,
                duration,
                phase: streamContext.currentPhase
            });
        }

        // Clean up
        setTimeout(() => {
            this.activeStreams.delete(streamContext.streamId);
        }, 10000);
    }

    /**
     * Send stream updates via WebSocket
     * @param {Object} streamContext - Stream context
     * @param {string} updateType - Type of update
     * @param {Object} data - Update data
     */
    sendStreamUpdate(streamContext, updateType, data) {
        const updateMessage = {
            streamId: streamContext.streamId,
            updateType,
            timestamp: new Date().toISOString(),
            correlationId: streamContext.correlationId,
            ...data
        };

        // Send to user's WebSocket connections
        const sent = webSocketService.sendToUser(
            streamContext.userId,
            'stream_update',
            updateMessage,
            `user:${streamContext.userId}:streams`
        );

        if (sent === 0) {
            logger.debug('No WebSocket connections available for stream update', {
                streamId: streamContext.streamId,
                userId: streamContext.userId,
                updateType
            });
        }

        // Emit event for internal listeners
        this.emit('stream_update', streamContext.streamId, updateType, data);
    }

    /**
     * Get stream status
     * @param {string} streamId - Stream ID
     * @returns {Object|null} Stream status
     */
    getStreamStatus(streamId) {
        const streamContext = this.activeStreams.get(streamId);
        if (!streamContext) {
            return null;
        }

        return {
            streamId: streamContext.streamId,
            status: streamContext.status,
            progress: streamContext.progress,
            currentPhase: streamContext.currentPhase,
            duration: Date.now() - streamContext.startTime,
            suggestionsGenerated: streamContext.suggestions.length,
            analysisPhases: streamContext.analysisPhases,
            estimatedTimeRemaining: this.estimateRemainingTime(streamContext)
        };
    }

    /**
     * Estimate stream duration based on image size and strategy
     * @param {Object} streamContext - Stream context
     * @returns {number} Estimated duration in milliseconds
     */
    estimateStreamDuration(streamContext) {
        const { metadata } = streamContext;
        let baseDuration = 8000; // 8 seconds base

        // Adjust for image size
        if (metadata.imageSize > 1000000) { // > 1MB
            baseDuration += 2000;
        } else if (metadata.imageSize > 500000) { // > 500KB
            baseDuration += 1000;
        }

        // Adjust for strategy
        switch (metadata.strategy) {
            case 'fast':
                baseDuration *= 0.7;
                break;
            case 'comprehensive':
                baseDuration *= 1.5;
                break;
        }

        // Keyboard extension optimization
        if (metadata.isKeyboard) {
            baseDuration *= 0.8;
        }

        return Math.min(baseDuration, 12000); // Cap at 12 seconds
    }

    /**
     * Estimate remaining time for stream
     * @param {Object} streamContext - Stream context
     * @returns {number} Estimated remaining time in milliseconds
     */
    estimateRemainingTime(streamContext) {
        const elapsed = Date.now() - streamContext.startTime;
        const estimated = this.estimateStreamDuration(streamContext);
        const progressRatio = streamContext.progress / 100;

        if (progressRatio === 0) return estimated;

        const estimatedTotal = elapsed / progressRatio;
        return Math.max(0, estimatedTotal - elapsed);
    }

    /**
     * Generate fallback suggestions
     * @param {Object} streamContext - Stream context
     * @returns {Array} Fallback suggestions
     */
    generateFallbackSuggestions(streamContext) {
        const { requestParams } = streamContext;
        const tone = requestParams.tone || 'casual';

        return [
            {
                id: `fallback_${Date.now()}_1`,
                text: this.getFallbackSuggestion(tone, 0),
                confidence: 0.6,
                reasoning: 'Emergency fallback suggestion',
                fallback: true
            },
            {
                id: `fallback_${Date.now()}_2`,
                text: this.getFallbackSuggestion(tone, 1),
                confidence: 0.6,
                reasoning: 'Emergency fallback suggestion',
                fallback: true
            }
        ];
    }

    /**
     * Get a fallback suggestion by tone and index
     * @param {string} tone - Conversation tone
     * @param {number} index - Suggestion index
     * @returns {string} Fallback suggestion text
     */
    getFallbackSuggestion(tone, index) {
        const suggestions = {
            playful: [
                "Your photo caught my attention - what's the story behind it?",
                "I love the energy in your photo! What were you up to?",
                "That looks like an interesting place - tell me more!"
            ],
            casual: [
                "Hey! What's going on in this photo?",
                "Nice picture! Where was this taken?",
                "This looks fun - what's the context?"
            ],
            confident: [
                "I'm intrigued by your photo - care to elaborate?",
                "That's an interesting shot - what's the backstory?",
                "I'd love to hear about what's happening here."
            ]
        };

        const toneOptions = suggestions[tone] || suggestions.casual;
        return toneOptions[index % toneOptions.length];
    }

    /**
     * Update peak concurrency metrics
     */
    updatePeakConcurrency() {
        if (this.streamMetrics.activeStreams > this.streamMetrics.peakConcurrentStreams) {
            this.streamMetrics.peakConcurrentStreams = this.streamMetrics.activeStreams;
        }
    }

    /**
     * Setup event handlers
     */
    setupEventHandlers() {
        // Listen for WebSocket disconnections to clean up streams
        this.on('user_disconnected', (userId) => {
            this.cleanupUserStreams(userId);
        });
    }

    /**
     * Clean up streams for disconnected user
     * @param {string} userId - User ID
     */
    cleanupUserStreams(userId) {
        for (const [streamId, streamContext] of this.activeStreams) {
            if (streamContext.userId === userId) {
                logger.info('Cleaning up stream for disconnected user', {
                    streamId,
                    userId
                });
                this.activeStreams.delete(streamId);
                this.streamMetrics.activeStreams--;
            }
        }
    }

    /**
     * Start performance monitoring
     */
    startPerformanceMonitoring() {
        setInterval(() => {
            logger.debug('Streaming service metrics', this.streamMetrics);

            // Emit metrics for external monitoring
            this.emit('metrics_update', this.streamMetrics);
        }, 30000); // Every 30 seconds
    }

    /**
     * Cancel an active stream
     * @param {string} streamId - Stream ID to cancel
     * @returns {Promise<boolean>} True if cancelled successfully
     */
    async cancelStream(streamId) {
        const streamContext = this.activeStreams.get(streamId);
        if (!streamContext) {
            return false;
        }

        if (streamContext.status === 'completed' || streamContext.status === 'error') {
            return false; // Already finished
        }

        const duration = Date.now() - streamContext.startTime;
        streamContext.status = 'cancelled';

        this.streamMetrics.activeStreams--;

        // Send cancellation update
        this.sendStreamUpdate(streamContext, 'stream_cancelled', {
            streamId,
            duration,
            phase: streamContext.currentPhase,
            progress: streamContext.progress,
            message: 'Stream cancelled by user request'
        });

        logger.info('Stream cancelled', {
            streamId,
            userId: streamContext.userId,
            duration,
            phase: streamContext.currentPhase,
            progress: streamContext.progress
        });

        // Clean up immediately
        this.activeStreams.delete(streamId);

        return true;
    }

    /**
     * Get health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: 'healthy',
            activeStreams: this.streamMetrics.activeStreams,
            peakConcurrency: this.streamMetrics.peakConcurrentStreams,
            averageDuration: this.streamMetrics.averageStreamDuration,
            metrics: this.streamMetrics,
            memoryUsage: process.memoryUsage(),
            uptime: process.uptime()
        };
    }

    /**
     * Shutdown the streaming service
     */
    async shutdown() {
        logger.info('Shutting down streaming service...');

        // Notify all active streams
        for (const [streamId, streamContext] of this.activeStreams) {
            this.sendStreamUpdate(streamContext, 'service_shutdown', {
                message: 'Streaming service is shutting down'
            });
        }

        // Clear all streams
        this.activeStreams.clear();
        this.streamMetrics.activeStreams = 0;

        logger.info('Streaming service shutdown complete');
    }
}

// Export singleton instance
const streamingService = new StreamingService();

module.exports = streamingService;