/**
 * Upload Queue Service - Priority-based Image Processing Pipeline
 *
 * This service provides high-performance upload queue management with
 * priority-based processing, intelligent compression, and real-time
 * progress tracking for streaming analysis pipeline.
 *
 * Features:
 * - Priority-based queue processing
 * - Intelligent image compression
 * - Memory-optimized handling
 * - Real-time progress updates
 * - Concurrent processing with limits
 * - Performance monitoring
 */

const EventEmitter = require('events');
const { v4: uuidv4 } = require('uuid');
const sharp = require('sharp');
const { logger } = require('./logger');

// Lazy-load streamingService to avoid circular dependency
let _streamingService = null;
const getStreamingService = () => {
    if (!_streamingService) {
        _streamingService = require('./streamingService');
    }
    return _streamingService;
};

const webSocketService = require('./websocketService');

class UploadQueueService extends EventEmitter {
    constructor() {
        super();

        // Queue storage
        this.queues = {
            urgent: [],     // Priority 0: <2s processing
            high: [],       // Priority 1: <5s processing
            normal: [],     // Priority 2: <10s processing
            low: []         // Priority 3: background processing
        };

        // Processing configuration
        this.config = {
            maxConcurrent: 5,           // Max concurrent uploads
            maxQueueSize: 100,          // Max items per priority queue
            compressionQuality: 80,     // JPEG quality
            maxImageSize: 1920,         // Max width/height in pixels
            maxFileSize: 5 * 1024 * 1024, // 5MB max file size
            timeouts: {
                urgent: 2000,           // 2 seconds
                high: 5000,             // 5 seconds
                normal: 10000,          // 10 seconds
                low: 30000              // 30 seconds
            }
        };

        // Processing state
        this.processing = new Map(); // uploadId -> ProcessingContext
        this.activeWorkers = 0;
        this.metrics = {
            totalUploads: 0,
            processedUploads: 0,
            failedUploads: 0,
            totalProcessingTime: 0,
            averageProcessingTime: 0,
            compressionSavings: 0,
            queueSizes: {
                urgent: 0,
                high: 0,
                normal: 0,
                low: 0
            }
        };

        this.startProcessingLoop();
        this.startMetricsReporting();

        logger.info('Upload Queue Service initialized', {
            maxConcurrent: this.config.maxConcurrent,
            compressionQuality: this.config.compressionQuality,
            maxImageSize: this.config.maxImageSize
        });
    }

    /**
     * Add upload to priority queue
     * @param {Object} uploadRequest - Upload request
     * @returns {Promise<string>} Upload ID
     */
    async addUpload(uploadRequest) {
        const uploadId = uuidv4();
        const priority = this.determinePriority(uploadRequest);
        const queueName = this.getQueueName(priority);

        // Validate request
        const validation = await this.validateUpload(uploadRequest);
        if (!validation.valid) {
            throw new Error(`Upload validation failed: ${validation.error}`);
        }

        // Check queue capacity
        if (this.queues[queueName].length >= this.config.maxQueueSize) {
            throw new Error(`Queue ${queueName} is full`);
        }

        // Create upload context
        const uploadContext = {
            uploadId,
            userId: uploadRequest.userId,
            correlationId: uploadRequest.correlationId,
            priority,
            queueName,
            imageData: uploadRequest.imageData,
            originalSize: this.calculateImageSize(uploadRequest.imageData),
            uploadParams: {
                suggestionType: uploadRequest.suggestionType,
                tone: uploadRequest.tone,
                context: uploadRequest.context,
                userPreferences: uploadRequest.userPreferences
            },
            metadata: {
                isKeyboard: uploadRequest.isKeyboardExtension || false,
                platform: uploadRequest.platform || 'unknown',
                userAgent: uploadRequest.userAgent,
                timestamp: new Date().toISOString()
            },
            status: 'queued',
            queuedAt: Date.now(),
            timeout: this.config.timeouts[queueName]
        };

        // Add to appropriate queue
        this.queues[queueName].push(uploadContext);
        this.metrics.totalUploads++;
        this.updateQueueMetrics();

        logger.info('Upload added to queue', {
            uploadId,
            userId: uploadRequest.userId,
            correlationId: uploadRequest.correlationId,
            priority,
            queueName,
            originalSize: uploadContext.originalSize,
            queuePosition: this.queues[queueName].length
        });

        // Send queue status update
        this.sendQueueUpdate(uploadContext, 'upload_queued', {
            uploadId,
            priority,
            queuePosition: this.queues[queueName].length,
            estimatedWaitTime: this.estimateWaitTime(queueName)
        });

        // Emit event for external listeners
        this.emit('upload_queued', uploadContext);

        return uploadId;
    }

    /**
     * Determine upload priority based on request characteristics
     * @param {Object} uploadRequest - Upload request
     * @returns {number} Priority level (0-3)
     */
    determinePriority(uploadRequest) {
        let priority = 2; // Default: normal

        // Keyboard extension gets higher priority
        if (uploadRequest.isKeyboardExtension) {
            priority = Math.min(priority, 1); // High priority
        }

        // Small images get higher priority
        const imageSize = this.calculateImageSize(uploadRequest.imageData);
        if (imageSize < 500000) { // < 500KB
            priority = Math.min(priority, 1); // High priority
        } else if (imageSize > 2000000) { // > 2MB
            priority = Math.max(priority, 3); // Low priority
        }

        // User preferences for speed
        if (uploadRequest.priorityHint === 'urgent') {
            priority = 0; // Urgent
        } else if (uploadRequest.priorityHint === 'background') {
            priority = 3; // Low
        }

        // System load consideration
        const totalQueueSize = this.getTotalQueueSize();
        if (totalQueueSize > 50) {
            priority = Math.min(priority + 1, 3); // Demote priority under load
        }

        return priority;
    }

    /**
     * Get queue name from priority
     * @param {number} priority - Priority level
     * @returns {string} Queue name
     */
    getQueueName(priority) {
        const mapping = {
            0: 'urgent',
            1: 'high',
            2: 'normal',
            3: 'low'
        };
        return mapping[priority] || 'normal';
    }

    /**
     * Validate upload request
     * @param {Object} uploadRequest - Upload request
     * @returns {Promise<Object>} Validation result
     */
    async validateUpload(uploadRequest) {
        try {
            // Check required fields
            if (!uploadRequest.imageData) {
                return { valid: false, error: 'Image data is required' };
            }

            if (!uploadRequest.userId) {
                return { valid: false, error: 'User ID is required' };
            }

            // Validate image data format
            if (!uploadRequest.imageData.startsWith('data:image/')) {
                return { valid: false, error: 'Invalid image data format' };
            }

            // Check file size
            const imageSize = this.calculateImageSize(uploadRequest.imageData);
            if (imageSize > this.config.maxFileSize) {
                return {
                    valid: false,
                    error: `Image too large: ${imageSize} bytes (max: ${this.config.maxFileSize})`
                };
            }

            // Validate image format (basic check)
            const base64Data = uploadRequest.imageData.split(',')[1];
            if (!base64Data || base64Data.length < 100) {
                return { valid: false, error: 'Invalid or empty image data' };
            }

            return { valid: true };

        } catch (error) {
            return { valid: false, error: `Validation error: ${error.message}` };
        }
    }

    /**
     * Calculate image size from base64 data
     * @param {string} imageData - Base64 image data
     * @returns {number} Size in bytes
     */
    calculateImageSize(imageData) {
        try {
            const base64Data = imageData.split(',')[1] || imageData;
            return Math.floor(base64Data.length * 0.75); // Approximate size
        } catch (error) {
            return 0;
        }
    }

    /**
     * Get total queue size across all priorities
     * @returns {number} Total queue size
     */
    getTotalQueueSize() {
        return Object.values(this.queues).reduce((total, queue) => total + queue.length, 0);
    }

    /**
     * Estimate wait time for queue
     * @param {string} queueName - Queue name
     * @returns {number} Estimated wait time in milliseconds
     */
    estimateWaitTime(queueName) {
        const position = this.queues[queueName].length;
        const avgProcessingTime = this.metrics.averageProcessingTime || 5000;
        const concurrencyFactor = Math.max(1, this.config.maxConcurrent - this.activeWorkers);

        return Math.floor((position * avgProcessingTime) / concurrencyFactor);
    }

    /**
     * Start the main processing loop
     */
    startProcessingLoop() {
        setInterval(async () => {
            await this.processQueue();
        }, 100); // Check every 100ms

        logger.info('Upload queue processing loop started');
    }

    /**
     * Process queued uploads by priority
     */
    async processQueue() {
        // Don't exceed concurrent processing limit
        if (this.activeWorkers >= this.config.maxConcurrent) {
            return;
        }

        // Process by priority: urgent -> high -> normal -> low
        const priorityOrder = ['urgent', 'high', 'normal', 'low'];

        for (const queueName of priorityOrder) {
            const queue = this.queues[queueName];

            if (queue.length > 0 && this.activeWorkers < this.config.maxConcurrent) {
                const uploadContext = queue.shift();
                this.processUpload(uploadContext);
                this.updateQueueMetrics();
            }
        }
    }

    /**
     * Process individual upload
     * @param {Object} uploadContext - Upload context
     */
    async processUpload(uploadContext) {
        const { uploadId, userId, correlationId } = uploadContext;
        const startTime = Date.now();

        this.activeWorkers++;
        this.processing.set(uploadId, uploadContext);
        uploadContext.status = 'processing';
        uploadContext.processingStartedAt = startTime;

        logger.info('Starting upload processing', {
            uploadId,
            userId,
            correlationId,
            priority: uploadContext.priority,
            queueName: uploadContext.queueName,
            activeWorkers: this.activeWorkers
        });

        // Send processing started update
        this.sendQueueUpdate(uploadContext, 'upload_processing_started', {
            uploadId,
            estimatedDuration: this.config.timeouts[uploadContext.queueName]
        });

        try {
            // Phase 1: Image compression and optimization
            const compressionResult = await this.compressImage(uploadContext);

            // Send compression progress
            this.sendQueueUpdate(uploadContext, 'upload_progress', {
                uploadId,
                phase: 'compression',
                progress: 30,
                compressionSavings: compressionResult.compressionRatio
            });

            // Phase 2: Start streaming analysis
            const streamingRequest = {
                userId: uploadContext.userId,
                correlationId: uploadContext.correlationId,
                imageData: compressionResult.compressedImageData,
                context: uploadContext.uploadParams.context,
                suggestionType: uploadContext.uploadParams.suggestionType,
                tone: uploadContext.uploadParams.tone,
                userPreferences: uploadContext.uploadParams.userPreferences,
                priority: uploadContext.queueName,
                strategy: this.determineAnalysisStrategy(uploadContext),
                isKeyboardExtension: uploadContext.metadata.isKeyboard,
                enableWebSocket: true,
                timeout: uploadContext.timeout
            };

            const streamId = await getStreamingService().startStream(streamingRequest);

            // Send streaming started update
            this.sendQueueUpdate(uploadContext, 'upload_progress', {
                uploadId,
                phase: 'analysis',
                progress: 50,
                streamId
            });

            // Upload processing complete (streaming continues independently)
            const processingTime = Date.now() - startTime;
            uploadContext.status = 'completed';
            uploadContext.processingCompletedAt = Date.now();
            uploadContext.streamId = streamId;

            // Update metrics
            this.metrics.processedUploads++;
            this.metrics.totalProcessingTime += processingTime;
            this.metrics.averageProcessingTime = Math.round(
                this.metrics.totalProcessingTime / this.metrics.processedUploads
            );
            this.metrics.compressionSavings += compressionResult.spaceSaved;

            // Send completion update
            this.sendQueueUpdate(uploadContext, 'upload_completed', {
                uploadId,
                streamId,
                processingTime,
                compressionSavings: compressionResult.compressionRatio,
                originalSize: uploadContext.originalSize,
                compressedSize: compressionResult.compressedSize
            });

            logger.info('Upload processing completed', {
                uploadId,
                userId,
                correlationId,
                processingTime: `${processingTime}ms`,
                streamId,
                compressionRatio: compressionResult.compressionRatio
            });

            // Emit completion event
            this.emit('upload_completed', uploadContext, compressionResult);

        } catch (error) {
            const errorTime = Date.now() - startTime;
            uploadContext.status = 'failed';
            uploadContext.error = error.message;

            this.metrics.failedUploads++;

            logger.error('Upload processing failed', {
                uploadId,
                userId,
                correlationId,
                error: error.message,
                processingTime: `${errorTime}ms`
            });

            // Send error update
            this.sendQueueUpdate(uploadContext, 'upload_failed', {
                uploadId,
                error: error.message,
                processingTime: errorTime
            });

            // Emit error event
            this.emit('upload_failed', uploadContext, error);

        } finally {
            // Clean up
            this.activeWorkers--;

            // Keep processing context for a short time for status queries
            setTimeout(() => {
                this.processing.delete(uploadId);
            }, 30000); // 30 seconds
        }
    }

    /**
     * Compress and optimize image
     * @param {Object} uploadContext - Upload context
     * @returns {Promise<Object>} Compression result
     */
    async compressImage(uploadContext) {
        const { imageData, originalSize } = uploadContext;

        try {
            // Extract base64 data
            const base64Data = imageData.split(',')[1];
            const imageBuffer = Buffer.from(base64Data, 'base64');

            // Get image metadata
            const metadata = await sharp(imageBuffer).metadata();

            logger.debug('Image compression started', {
                uploadId: uploadContext.uploadId,
                originalSize,
                format: metadata.format,
                width: metadata.width,
                height: metadata.height
            });

            // Determine optimal compression strategy
            const compressionStrategy = this.determineCompressionStrategy(uploadContext, metadata);

            // Apply compression
            let sharpInstance = sharp(imageBuffer);

            // Resize if needed
            if (metadata.width > this.config.maxImageSize || metadata.height > this.config.maxImageSize) {
                sharpInstance = sharpInstance.resize(
                    this.config.maxImageSize,
                    this.config.maxImageSize,
                    { fit: 'inside', withoutEnlargement: true }
                );
            }

            // Apply compression based on strategy
            let compressedBuffer;
            switch (compressionStrategy.format) {
                case 'webp':
                    compressedBuffer = await sharpInstance
                        .webp({ quality: compressionStrategy.quality })
                        .toBuffer();
                    break;
                case 'jpeg':
                    compressedBuffer = await sharpInstance
                        .jpeg({ quality: compressionStrategy.quality, progressive: true })
                        .toBuffer();
                    break;
                case 'png':
                    compressedBuffer = await sharpInstance
                        .png({ compressionLevel: 9, adaptiveFiltering: true })
                        .toBuffer();
                    break;
                default:
                    // Keep original format but optimize
                    compressedBuffer = await sharpInstance
                        .jpeg({ quality: this.config.compressionQuality })
                        .toBuffer();
            }

            // Convert back to base64
            const compressedBase64 = compressedBuffer.toString('base64');
            const compressedImageData = `data:image/${compressionStrategy.format};base64,${compressedBase64}`;
            const compressedSize = compressedBuffer.length;

            // Calculate compression metrics
            const compressionRatio = Math.round((1 - compressedSize / originalSize) * 100);
            const spaceSaved = originalSize - compressedSize;

            logger.info('Image compression completed', {
                uploadId: uploadContext.uploadId,
                originalSize,
                compressedSize,
                compressionRatio: `${compressionRatio}%`,
                spaceSaved,
                strategy: compressionStrategy
            });

            return {
                compressedImageData,
                compressedSize,
                originalSize,
                compressionRatio,
                spaceSaved,
                strategy: compressionStrategy,
                metadata: {
                    originalFormat: metadata.format,
                    originalDimensions: { width: metadata.width, height: metadata.height },
                    compressedFormat: compressionStrategy.format
                }
            };

        } catch (error) {
            logger.error('Image compression failed', {
                uploadId: uploadContext.uploadId,
                error: error.message
            });

            // Return original data if compression fails
            return {
                compressedImageData: imageData,
                compressedSize: originalSize,
                originalSize,
                compressionRatio: 0,
                spaceSaved: 0,
                strategy: { format: 'original', quality: 100 },
                error: error.message
            };
        }
    }

    /**
     * Determine optimal compression strategy
     * @param {Object} uploadContext - Upload context
     * @param {Object} metadata - Image metadata
     * @returns {Object} Compression strategy
     */
    determineCompressionStrategy(uploadContext, metadata) {
        const { priority, metadata: contextMeta } = uploadContext;
        const { format, width, height } = metadata;

        // Base strategy
        let strategy = {
            format: 'jpeg',
            quality: this.config.compressionQuality
        };

        // High priority uploads get lighter compression for speed
        if (priority <= 1) {
            strategy.quality = Math.min(90, strategy.quality + 10);
        }

        // Large images get more aggressive compression
        const pixelCount = width * height;
        if (pixelCount > 2000000) { // > 2MP
            strategy.quality = Math.max(60, strategy.quality - 15);
        }

        // Choose optimal format based on content
        if (format === 'png' && contextMeta.isKeyboard) {
            // Keep PNG for screenshots with text
            strategy.format = 'png';
            delete strategy.quality;
        } else if (format === 'webp') {
            // Keep WebP if already in WebP
            strategy.format = 'webp';
        }

        // Keyboard extension optimization
        if (contextMeta.isKeyboard) {
            strategy.quality = Math.max(70, strategy.quality); // Maintain quality for readability
        }

        return strategy;
    }

    /**
     * Determine analysis strategy based on upload context
     * @param {Object} uploadContext - Upload context
     * @returns {string} Analysis strategy
     */
    determineAnalysisStrategy(uploadContext) {
        const { priority, metadata } = uploadContext;

        if (priority === 0) return 'fast';      // Urgent
        if (priority === 1) return 'standard';  // High
        if (priority === 3) return 'comprehensive'; // Low

        // Normal priority - decide based on context
        if (metadata.isKeyboard) return 'fast';
        return 'standard';
    }

    /**
     * Send queue update via WebSocket
     * @param {Object} uploadContext - Upload context
     * @param {string} updateType - Update type
     * @param {Object} data - Update data
     */
    sendQueueUpdate(uploadContext, updateType, data) {
        const updateMessage = {
            uploadId: uploadContext.uploadId,
            updateType,
            timestamp: new Date().toISOString(),
            correlationId: uploadContext.correlationId,
            ...data
        };

        // Send to user's WebSocket connections
        const sent = webSocketService.sendToUser(
            uploadContext.userId,
            'upload_update',
            updateMessage,
            `user:${uploadContext.userId}:uploads`
        );

        if (sent === 0) {
            logger.debug('No WebSocket connections available for upload update', {
                uploadId: uploadContext.uploadId,
                userId: uploadContext.userId,
                updateType
            });
        }

        // Emit event for internal listeners
        this.emit('upload_update', uploadContext.uploadId, updateType, data);
    }

    /**
     * Get upload status
     * @param {string} uploadId - Upload ID
     * @returns {Object|null} Upload status
     */
    getUploadStatus(uploadId) {
        // Check if currently processing
        const processingContext = this.processing.get(uploadId);
        if (processingContext) {
            return {
                uploadId: processingContext.uploadId,
                status: processingContext.status,
                queueName: processingContext.queueName,
                priority: processingContext.priority,
                queuedAt: processingContext.queuedAt,
                processingStartedAt: processingContext.processingStartedAt,
                streamId: processingContext.streamId,
                elapsed: Date.now() - (processingContext.processingStartedAt || processingContext.queuedAt)
            };
        }

        // Check if in queue
        for (const [queueName, queue] of Object.entries(this.queues)) {
            const position = queue.findIndex(item => item.uploadId === uploadId);
            if (position !== -1) {
                const uploadContext = queue[position];
                return {
                    uploadId: uploadContext.uploadId,
                    status: 'queued',
                    queueName,
                    priority: uploadContext.priority,
                    queuePosition: position + 1,
                    queuedAt: uploadContext.queuedAt,
                    estimatedWaitTime: this.estimateWaitTime(queueName)
                };
            }
        }

        return null; // Upload not found
    }

    /**
     * Update queue size metrics
     */
    updateQueueMetrics() {
        this.metrics.queueSizes = {
            urgent: this.queues.urgent.length,
            high: this.queues.high.length,
            normal: this.queues.normal.length,
            low: this.queues.low.length
        };
    }

    /**
     * Start metrics reporting
     */
    startMetricsReporting() {
        setInterval(() => {
            this.updateQueueMetrics();

            logger.debug('Upload queue metrics', {
                activeWorkers: this.activeWorkers,
                queueSizes: this.metrics.queueSizes,
                totalQueued: this.getTotalQueueSize(),
                metrics: this.metrics
            });

            // Emit metrics for external monitoring
            this.emit('metrics_update', this.metrics);
        }, 30000); // Every 30 seconds
    }

    /**
     * Get comprehensive queue statistics
     * @returns {Object} Queue statistics
     */
    getQueueStats() {
        return {
            activeWorkers: this.activeWorkers,
            maxConcurrent: this.config.maxConcurrent,
            queueSizes: this.metrics.queueSizes,
            totalQueued: this.getTotalQueueSize(),
            processing: this.processing.size,
            metrics: this.metrics,
            config: {
                maxImageSize: this.config.maxImageSize,
                compressionQuality: this.config.compressionQuality,
                maxFileSize: this.config.maxFileSize
            }
        };
    }

    /**
     * Get health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        const totalQueued = this.getTotalQueueSize();
        const isHealthy = totalQueued < 80 && this.activeWorkers <= this.config.maxConcurrent;

        return {
            status: isHealthy ? 'healthy' : 'overloaded',
            activeWorkers: this.activeWorkers,
            totalQueued,
            maxCapacity: this.config.maxQueueSize * 4, // 4 priority queues
            utilizationPercent: Math.round((totalQueued / (this.config.maxQueueSize * 4)) * 100),
            metrics: this.metrics,
            uptime: process.uptime()
        };
    }

    /**
     * Clear queues (for maintenance)
     * @param {string} queueName - Specific queue to clear, or 'all'
     */
    clearQueue(queueName = 'all') {
        if (queueName === 'all') {
            Object.keys(this.queues).forEach(name => {
                this.queues[name] = [];
            });
            logger.warn('All upload queues cleared');
        } else if (this.queues[queueName]) {
            this.queues[queueName] = [];
            logger.warn(`Upload queue '${queueName}' cleared`);
        }

        this.updateQueueMetrics();
    }

    /**
     * Shutdown the upload queue service
     */
    async shutdown() {
        logger.info('Shutting down upload queue service...');

        // Wait for active uploads to complete (with timeout)
        const shutdownTimeout = 30000; // 30 seconds
        const startTime = Date.now();

        while (this.activeWorkers > 0 && (Date.now() - startTime) < shutdownTimeout) {
            logger.info(`Waiting for ${this.activeWorkers} active uploads to complete...`);
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        // Clear all queues
        this.clearQueue('all');

        // Clear processing map
        this.processing.clear();

        logger.info('Upload queue service shutdown complete');
    }
}

// Export singleton instance
const uploadQueueService = new UploadQueueService();

module.exports = uploadQueueService;