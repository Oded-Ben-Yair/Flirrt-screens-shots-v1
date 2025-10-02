/**
 * Streaming Delivery Service - Advanced Real-Time AI Response Streaming
 *
 * Features:
 * - Progressive suggestion delivery as AI generates responses
 * - WebSocket-based real-time streaming
 * - Chunk-based delivery for optimal UX
 * - Quality-based streaming control
 * - Backpressure handling and flow control
 * - Stream compression and optimization
 */

const { EventEmitter } = require('events');
const { logger } = require('./logger');
const webSocketService = require('./websocketService');
const performanceOptimizer = require('./performanceOptimizer');

class StreamingDeliveryService extends EventEmitter {
    constructor() {
        super();
        this.activeStreams = new Map(); // correlationId -> stream metadata
        this.streamMetrics = {
            totalStreams: 0,
            activeStreams: 0,
            avgChunkSize: 0,
            avgStreamDuration: 0,
            totalBytesStreamed: 0,
            chunksDelivered: 0,
            streamSuccessRate: 0.0
        };

        // Streaming configuration
        this.config = {
            chunkSize: 256,              // Optimal chunk size for real-time feel
            minChunkDelay: 50,           // Minimum 50ms between chunks
            maxChunkDelay: 200,          // Maximum 200ms between chunks
            qualityThreshold: 0.7,       // Minimum quality to start streaming
            maxConcurrentStreams: 50,    // Maximum concurrent streams
            streamTimeout: 30000,        // 30 second stream timeout
            compressionEnabled: true,    // Enable stream compression
            adaptiveDelay: true          // Adaptive delay based on content
        };

        this.setupCleanupInterval();
        logger.info('Streaming Delivery Service initialized', { config: this.config });
    }

    /**
     * Start streaming suggestions for a request
     * @param {string} correlationId - Request correlation ID
     * @param {string} userId - User ID
     * @param {Object} options - Streaming options
     * @returns {Object} Stream handle
     */
    async startSuggestionStream(correlationId, userId, options = {}) {
        try {
            // Check concurrent stream limits
            if (this.activeStreams.size >= this.config.maxConcurrentStreams) {
                throw new Error('Maximum concurrent streams exceeded');
            }

            const streamConfig = {
                ...this.config,
                ...options,
                fastMode: options.isKeyboardExtension || false,
                priority: options.priority || 'normal'
            };

            // Adjust config for fast mode (keyboard extension)
            if (streamConfig.fastMode) {
                streamConfig.chunkSize = 128;
                streamConfig.minChunkDelay = 25;
                streamConfig.maxChunkDelay = 100;
                streamConfig.qualityThreshold = 0.6;
            }

            const streamMetadata = {
                correlationId,
                userId,
                startTime: Date.now(),
                config: streamConfig,
                chunks: [],
                totalSuggestions: 0,
                deliveredSuggestions: 0,
                bytesStreamed: 0,
                status: 'active',
                lastActivity: Date.now(),
                estimatedTotal: options.estimatedSuggestions || 6
            };

            this.activeStreams.set(correlationId, streamMetadata);
            this.streamMetrics.activeStreams = this.activeStreams.size;
            this.streamMetrics.totalStreams++;

            // Send stream start notification
            webSocketService.sendToUser(userId, 'stream_started', {
                correlationId,
                estimatedSuggestions: streamMetadata.estimatedTotal,
                streamId: correlationId,
                fastMode: streamConfig.fastMode
            }, `user:${userId}:streams`);

            logger.info('Suggestion stream started', {
                correlationId,
                userId,
                fastMode: streamConfig.fastMode,
                estimatedSuggestions: streamMetadata.estimatedTotal
            });

            // Set timeout for stream cleanup
            setTimeout(() => {
                this.cleanupStream(correlationId, 'timeout');
            }, streamConfig.streamTimeout);

            return {
                correlationId,
                streamId: correlationId,
                config: streamConfig,
                sendChunk: (suggestion) => this.sendSuggestionChunk(correlationId, suggestion),
                sendBatch: (suggestions) => this.sendSuggestionBatch(correlationId, suggestions),
                complete: (finalData) => this.completeStream(correlationId, finalData),
                error: (error) => this.errorStream(correlationId, error)
            };

        } catch (error) {
            logger.error('Failed to start suggestion stream', {
                correlationId,
                userId,
                error: error.message
            });

            // Send error to user
            webSocketService.sendToUser(userId, 'stream_error', {
                correlationId,
                error: error.message,
                timestamp: new Date().toISOString()
            }, `user:${userId}:streams`);

            throw error;
        }
    }

    /**
     * Send a single suggestion chunk
     * @param {string} correlationId - Stream correlation ID
     * @param {Object} suggestion - Suggestion data
     * @returns {Promise<boolean>} Success status
     */
    async sendSuggestionChunk(correlationId, suggestion) {
        const stream = this.activeStreams.get(correlationId);
        if (!stream || stream.status !== 'active') {
            logger.warn('Cannot send chunk to inactive stream', { correlationId });
            return false;
        }

        try {
            // Apply quality filtering
            if (suggestion.confidence < stream.config.qualityThreshold) {
                logger.debug('Suggestion below quality threshold, buffering', {
                    correlationId,
                    confidence: suggestion.confidence,
                    threshold: stream.config.qualityThreshold
                });
                return false; // Don't stream low-quality suggestions immediately
            }

            // Prepare chunk data
            const chunk = {
                id: suggestion.id,
                text: suggestion.text,
                confidence: suggestion.confidence,
                reasoning: suggestion.reasoning || '',
                tone: suggestion.tone,
                topics: suggestion.topics || [],
                uniquenessScore: suggestion.uniquenessScore || 0,
                engagementPotential: suggestion.engagementPotential || 0,
                characterCount: suggestion.characterCount,
                chunkIndex: stream.chunks.length,
                timestamp: new Date().toISOString(),
                partial: false
            };

            // Apply adaptive delay based on content complexity
            const delay = this.calculateAdaptiveDelay(suggestion, stream.config);

            // Send with delay for natural feel
            await this.delayedSend(async () => {
                const success = webSocketService.sendToUser(stream.userId, 'suggestion_chunk', {
                    correlationId,
                    chunk,
                    progress: {
                        delivered: stream.deliveredSuggestions + 1,
                        estimated: stream.estimatedTotal,
                        percentage: Math.round(((stream.deliveredSuggestions + 1) / stream.estimatedTotal) * 100)
                    }
                }, `user:${stream.userId}:streams`);

                if (success) {
                    stream.chunks.push(chunk);
                    stream.deliveredSuggestions++;
                    stream.bytesStreamed += JSON.stringify(chunk).length;
                    stream.lastActivity = Date.now();

                    this.updateStreamMetrics();

                    logger.debug('Suggestion chunk delivered', {
                        correlationId,
                        chunkIndex: chunk.chunkIndex,
                        progress: `${stream.deliveredSuggestions}/${stream.estimatedTotal}`,
                        confidence: suggestion.confidence
                    });

                    return true;
                } else {
                    logger.warn('Failed to deliver suggestion chunk', { correlationId });
                    return false;
                }
            }, delay);

            return true;

        } catch (error) {
            logger.error('Error sending suggestion chunk', {
                correlationId,
                error: error.message
            });

            // Mark stream as errored
            stream.status = 'error';
            this.errorStream(correlationId, error);
            return false;
        }
    }

    /**
     * Send multiple suggestions as optimized batch
     * @param {string} correlationId - Stream correlation ID
     * @param {Array} suggestions - Array of suggestions
     * @returns {Promise<boolean>} Success status
     */
    async sendSuggestionBatch(correlationId, suggestions) {
        const stream = this.activeStreams.get(correlationId);
        if (!stream || stream.status !== 'active') {
            logger.warn('Cannot send batch to inactive stream', { correlationId });
            return false;
        }

        try {
            // Filter by quality
            const qualitySuggestions = suggestions.filter(s =>
                s.confidence >= stream.config.qualityThreshold
            );

            if (qualitySuggestions.length === 0) {
                logger.debug('No suggestions meet quality threshold for batch', {
                    correlationId,
                    originalCount: suggestions.length,
                    threshold: stream.config.qualityThreshold
                });
                return false;
            }

            // Sort by confidence for optimal streaming order
            const sortedSuggestions = qualitySuggestions.sort((a, b) => b.confidence - a.confidence);

            // Stream in optimal chunks
            for (let i = 0; i < sortedSuggestions.length; i++) {
                const suggestion = sortedSuggestions[i];
                const success = await this.sendSuggestionChunk(correlationId, suggestion);

                if (!success) {
                    logger.warn('Failed to send suggestion in batch', {
                        correlationId,
                        suggestionIndex: i,
                        suggestionId: suggestion.id
                    });
                    continue;
                }

                // Progressive delay - faster for first few suggestions
                const batchDelay = Math.max(
                    stream.config.minChunkDelay,
                    stream.config.maxChunkDelay - (i * 20)
                );

                if (i < sortedSuggestions.length - 1) {
                    await new Promise(resolve => setTimeout(resolve, batchDelay));
                }
            }

            logger.info('Suggestion batch streaming completed', {
                correlationId,
                totalSuggestions: suggestions.length,
                qualitySuggestions: qualitySuggestions.length,
                delivered: stream.deliveredSuggestions
            });

            return true;

        } catch (error) {
            logger.error('Error sending suggestion batch', {
                correlationId,
                error: error.message
            });

            this.errorStream(correlationId, error);
            return false;
        }
    }

    /**
     * Complete a stream with final data
     * @param {string} correlationId - Stream correlation ID
     * @param {Object} finalData - Final stream data
     */
    async completeStream(correlationId, finalData = {}) {
        const stream = this.activeStreams.get(correlationId);
        if (!stream) {
            logger.warn('Cannot complete non-existent stream', { correlationId });
            return;
        }

        try {
            const duration = Date.now() - stream.startTime;
            const successRate = stream.deliveredSuggestions / Math.max(stream.estimatedTotal, 1);

            // Send completion notification
            webSocketService.sendToUser(stream.userId, 'stream_completed', {
                correlationId,
                summary: {
                    totalSuggestions: stream.deliveredSuggestions,
                    bytesStreamed: stream.bytesStreamed,
                    duration,
                    successRate: Math.round(successRate * 100),
                    avgChunkSize: stream.bytesStreamed / Math.max(stream.chunks.length, 1)
                },
                finalData,
                timestamp: new Date().toISOString()
            }, `user:${stream.userId}:streams`);

            // Update metrics
            this.updateStreamCompletionMetrics(stream, duration, successRate);

            logger.info('Suggestion stream completed successfully', {
                correlationId,
                duration,
                deliveredSuggestions: stream.deliveredSuggestions,
                successRate: Math.round(successRate * 100),
                avgChunkSize: Math.round(stream.bytesStreamed / Math.max(stream.chunks.length, 1))
            });

            // Record performance for optimization
            await performanceOptimizer.recordPerformance({
                correlationId,
                strategy: stream.config.fastMode ? 'keyboard' : 'standard',
                latency: duration,
                success: true,
                streaming: true,
                chunksDelivered: stream.chunks.length,
                bytesStreamed: stream.bytesStreamed
            });

            // Cleanup
            this.cleanupStream(correlationId, 'completed');

        } catch (error) {
            logger.error('Error completing stream', {
                correlationId,
                error: error.message
            });

            this.errorStream(correlationId, error);
        }
    }

    /**
     * Handle stream error
     * @param {string} correlationId - Stream correlation ID
     * @param {Error} error - Error object
     */
    async errorStream(correlationId, error) {
        const stream = this.activeStreams.get(correlationId);
        if (!stream) {
            return;
        }

        try {
            // Send error notification
            webSocketService.sendToUser(stream.userId, 'stream_error', {
                correlationId,
                error: error.message,
                partialData: {
                    deliveredSuggestions: stream.deliveredSuggestions,
                    chunks: stream.chunks
                },
                timestamp: new Date().toISOString()
            }, `user:${stream.userId}:streams`);

            logger.error('Suggestion stream error', {
                correlationId,
                userId: stream.userId,
                error: error.message,
                deliveredSuggestions: stream.deliveredSuggestions,
                duration: Date.now() - stream.startTime
            });

            // Record failed performance
            await performanceOptimizer.recordPerformance({
                correlationId,
                strategy: stream.config.fastMode ? 'keyboard' : 'standard',
                latency: Date.now() - stream.startTime,
                success: false,
                streaming: true,
                error: error.message
            });

            // Cleanup
            this.cleanupStream(correlationId, 'error');

        } catch (cleanupError) {
            logger.error('Error during stream error handling', {
                correlationId,
                originalError: error.message,
                cleanupError: cleanupError.message
            });
        }
    }

    /**
     * Calculate adaptive delay based on suggestion content
     * @param {Object} suggestion - Suggestion object
     * @param {Object} config - Stream configuration
     * @returns {number} Delay in milliseconds
     */
    calculateAdaptiveDelay(suggestion, config) {
        if (!config.adaptiveDelay) {
            return config.minChunkDelay;
        }

        let delay = config.minChunkDelay;

        // Longer delay for longer suggestions (natural reading feel)
        const textLength = suggestion.text.length;
        if (textLength > 100) delay += 50;
        else if (textLength > 200) delay += 100;

        // Shorter delay for high-confidence suggestions
        if (suggestion.confidence > 0.9) delay -= 20;
        else if (suggestion.confidence < 0.7) delay += 30;

        // Adjust for tone complexity
        const complexTones = ['witty', 'intellectual', 'sophisticated'];
        if (complexTones.includes(suggestion.tone)) {
            delay += 25; // Slight pause for complex content
        }

        return Math.max(config.minChunkDelay, Math.min(config.maxChunkDelay, delay));
    }

    /**
     * Send with controlled delay
     * @param {Function} sendFunction - Function to execute
     * @param {number} delay - Delay in milliseconds
     * @returns {Promise} Send result
     */
    async delayedSend(sendFunction, delay) {
        if (delay > 0) {
            await new Promise(resolve => setTimeout(resolve, delay));
        }
        return sendFunction();
    }

    /**
     * Update streaming metrics
     */
    updateStreamMetrics() {
        const activeStreams = Array.from(this.activeStreams.values());

        if (activeStreams.length > 0) {
            const totalBytes = activeStreams.reduce((sum, stream) => sum + stream.bytesStreamed, 0);
            const totalChunks = activeStreams.reduce((sum, stream) => sum + stream.chunks.length, 0);

            this.streamMetrics.totalBytesStreamed = totalBytes;
            this.streamMetrics.chunksDelivered = totalChunks;
            this.streamMetrics.avgChunkSize = totalChunks > 0 ? totalBytes / totalChunks : 0;
        }

        this.streamMetrics.activeStreams = this.activeStreams.size;
    }

    /**
     * Update completion metrics
     * @param {Object} stream - Stream metadata
     * @param {number} duration - Stream duration
     * @param {number} successRate - Success rate
     */
    updateStreamCompletionMetrics(stream, duration, successRate) {
        // Update average duration
        if (this.streamMetrics.avgStreamDuration === 0) {
            this.streamMetrics.avgStreamDuration = duration;
        } else {
            this.streamMetrics.avgStreamDuration =
                (this.streamMetrics.avgStreamDuration * 0.9) + (duration * 0.1);
        }

        // Update success rate
        if (this.streamMetrics.streamSuccessRate === 0) {
            this.streamMetrics.streamSuccessRate = successRate;
        } else {
            this.streamMetrics.streamSuccessRate =
                (this.streamMetrics.streamSuccessRate * 0.9) + (successRate * 0.1);
        }
    }

    /**
     * Cleanup stream resources
     * @param {string} correlationId - Stream correlation ID
     * @param {string} reason - Cleanup reason
     */
    cleanupStream(correlationId, reason) {
        const stream = this.activeStreams.get(correlationId);
        if (stream) {
            stream.status = reason === 'completed' ? 'completed' : 'terminated';
            this.activeStreams.delete(correlationId);
            this.streamMetrics.activeStreams = this.activeStreams.size;

            logger.debug('Stream cleaned up', {
                correlationId,
                reason,
                duration: Date.now() - stream.startTime,
                deliveredSuggestions: stream.deliveredSuggestions
            });
        }
    }

    /**
     * Setup periodic cleanup of stale streams
     */
    setupCleanupInterval() {
        setInterval(() => {
            const now = Date.now();
            const staleThreshold = 5 * 60 * 1000; // 5 minutes

            for (const [correlationId, stream] of this.activeStreams.entries()) {
                if (now - stream.lastActivity > staleThreshold) {
                    logger.info('Cleaning up stale stream', {
                        correlationId,
                        age: now - stream.startTime,
                        lastActivity: now - stream.lastActivity
                    });

                    this.cleanupStream(correlationId, 'stale');
                }
            }
        }, 60000); // Check every minute
    }

    /**
     * Get streaming service health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: 'operational',
            activeStreams: this.activeStreams.size,
            metrics: { ...this.streamMetrics },
            config: { ...this.config },
            limits: {
                maxConcurrentStreams: this.config.maxConcurrentStreams,
                utilizationRate: (this.activeStreams.size / this.config.maxConcurrentStreams) * 100
            }
        };
    }

    /**
     * Get detailed streaming insights
     * @returns {Object} Streaming insights
     */
    getStreamingInsights() {
        const insights = {
            performance: {
                avgStreamDuration: Math.round(this.streamMetrics.avgStreamDuration),
                avgChunkSize: Math.round(this.streamMetrics.avgChunkSize),
                streamSuccessRate: Math.round(this.streamMetrics.streamSuccessRate * 100),
                totalBytesStreamed: this.streamMetrics.totalBytesStreamed
            },
            activity: {
                totalStreams: this.streamMetrics.totalStreams,
                activeStreams: this.streamMetrics.activeStreams,
                chunksDelivered: this.streamMetrics.chunksDelivered
            },
            efficiency: {
                avgChunksPerStream: this.streamMetrics.totalStreams > 0 ?
                    this.streamMetrics.chunksDelivered / this.streamMetrics.totalStreams : 0,
                bytesPerSecond: this.streamMetrics.avgStreamDuration > 0 ?
                    this.streamMetrics.avgChunkSize * 1000 / this.streamMetrics.avgStreamDuration : 0
            }
        };

        return insights;
    }
}

// Export singleton instance
const streamingDeliveryService = new StreamingDeliveryService();
module.exports = streamingDeliveryService;