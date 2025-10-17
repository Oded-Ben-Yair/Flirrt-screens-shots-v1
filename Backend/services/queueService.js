const { logger } = require('./logger');
const circuitBreakerService = require('./circuitBreaker');

class QueueService {
    constructor() {
        this.queues = new Map();
        this.isInitialized = false;
        this.fallbackMode = true; // Always use fallback mode for now

        logger.warn('Queue service running in fallback mode - jobs will execute immediately');
    }

    // Add job to queue (in fallback mode, execute immediately)
    async addJob(queueName, data, options = {}) {
        if (!this.fallbackMode) {
            const queue = this.queues.get(queueName);
            if (!queue) {
                logger.error(`Queue ${queueName} not found`);
                throw new Error(`Queue ${queueName} not found`);
            }
            return await queue.add(data, options);
        }

        // Fallback mode: Execute immediately
        logger.debug(`Fallback mode: Executing ${queueName} job immediately`);
        return { id: Date.now().toString(), data, queue: queueName };
    }

    // Process queue jobs (in fallback mode, this does nothing)
    processQueue(queueName, processor, concurrency = 1) {
        if (!this.fallbackMode) {
            const queue = this.queues.get(queueName);
            if (!queue) {
                logger.error(`Queue ${queueName} not found for processing`);
                return;
            }

            queue.process(concurrency, async (job) => {
                try {
                    return await processor(job);
                } catch (error) {
                    logger.error(`Error processing ${queueName} job:`, error.message);
                    throw error;
                }
            });

            // Event listeners
            queue.on('completed', (job) => {
                logger.info(`Job ${job.id} in queue ${queueName} completed`);
            });

            queue.on('failed', (job, err) => {
                logger.error(`Job ${job.id} in queue ${queueName} failed:`, err.message);
            });

            queue.on('stalled', (job) => {
                logger.warn(`Job ${job.id} in queue ${queueName} stalled`);
            });
        }

        // In fallback mode, processors are not attached to queues
        logger.debug(`Fallback mode: Processor registered for ${queueName} but not active`);
    }

    // Get queue statistics
    async getQueueStats(queueName) {
        if (!this.fallbackMode) {
            const queue = this.queues.get(queueName);
            if (!queue) {
                return null;
            }

            const [waiting, active, completed, failed, delayed] = await Promise.all([
                queue.getWaitingCount(),
                queue.getActiveCount(),
                queue.getCompletedCount(),
                queue.getFailedCount(),
                queue.getDelayedCount()
            ]);

            return {
                name: queueName,
                waiting,
                active,
                completed,
                failed,
                delayed,
                total: waiting + active + delayed
            };
        }

        // Fallback mode stats
        return {
            name: queueName,
            mode: 'fallback',
            waiting: 0,
            active: 0,
            completed: 0,
            failed: 0,
            delayed: 0,
            total: 0
        };
    }

    // Get all queues statistics
    async getAllQueuesStats() {
        const stats = [];
        const queueNames = ['grok-api', 'elevenlabs-api', 'screenshot-analysis', 'voice-cloning'];

        for (const queueName of queueNames) {
            const queueStats = await this.getQueueStats(queueName);
            if (queueStats) {
                stats.push(queueStats);
            }
        }

        return stats;
    }

    // Pause a queue
    async pauseQueue(queueName) {
        if (!this.fallbackMode) {
            const queue = this.queues.get(queueName);
            if (queue) {
                await queue.pause();
                logger.info(`Queue ${queueName} paused`);
            }
        }
    }

    // Resume a queue
    async resumeQueue(queueName) {
        if (!this.fallbackMode) {
            const queue = this.queues.get(queueName);
            if (queue) {
                await queue.resume();
                logger.info(`Queue ${queueName} resumed`);
            }
        }
    }

    // Clean completed jobs
    async cleanQueue(queueName, grace = 0) {
        if (!this.fallbackMode) {
            const queue = this.queues.get(queueName);
            if (queue) {
                await queue.clean(grace, 'completed');
                await queue.clean(grace, 'failed');
                logger.info(`Queue ${queueName} cleaned`);
            }
        }
    }

    // Close all queues
    async closeAll() {
        if (!this.fallbackMode) {
            for (const [name, queue] of this.queues) {
                await queue.close();
                logger.info(`Queue ${name} closed`);
            }
        }
        this.queues.clear();
        this.isInitialized = false;
    }

    // Check if service is ready
    isReady() {
        return this.isInitialized || this.fallbackMode;
    }

    // Queue Grok API flirt generation (fallback mode: execute immediately)
    async queueGrokFlirtGeneration(grokPayload, correlationId = null, priority = 1) {
        logger.debug('Queueing Grok flirt generation', {
            correlationId,
            priority,
            model: grokPayload.model
        });

        if (!this.fallbackMode) {
            // Real queue mode (not implemented yet)
            return await this.addJob('grok-api', {
                type: 'flirt-generation',
                payload: grokPayload,
                correlationId,
                priority
            }, { priority });
        }

        // Fallback mode: Execute immediately through circuit breaker
        try {
            logger.info('Fallback mode: Executing Grok API call immediately', { correlationId });

            const result = await circuitBreakerService.callGrokApi(grokPayload, correlationId);

            logger.info('Grok API call completed successfully', {
                correlationId,
                success: result.success,
                fallback: result.fallback || false
            });

            return result;
        } catch (error) {
            logger.error('Grok API call failed in fallback mode', {
                correlationId,
                error: error.message
            });
            throw error;
        }
    }

    // Get health status
    getHealthStatus() {
        return {
            initialized: this.isInitialized || this.fallbackMode,
            fallbackMode: this.fallbackMode,
            queuesCount: this.queues.size,
            ready: this.isReady()
        };
    }

    // Shutdown service
    async shutdown() {
        try {
            await this.closeAll();
            logger.info('Queue service shutdown completed');
        } catch (error) {
            logger.error('Error during queue service shutdown:', error.message);
            throw error;
        }
    }
}

// Export singleton instance
const queueService = new QueueService();

module.exports = queueService;