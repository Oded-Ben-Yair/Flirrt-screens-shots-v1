const Queue = require('bull');
const Redis = require('ioredis');
const { logger } = require('./logger');
const circuitBreakerService = require('./circuitBreaker');

class QueueService {
    constructor() {
        this.queues = new Map();
        this.redis = null;
        this.isInitialized = false;

        this.initializeQueues();
    }

    initializeQueues() {
        try {
            // Redis connection for Bull queues
            const redisConfig = {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD,
                db: process.env.REDIS_QUEUE_DB || 1, // Use different DB for queues
                maxRetriesPerRequest: 3,
                retryDelayOnFailover: 100,
                enableOfflineQueue: false,
                lazyConnect: false
            };

            // Create Redis instance for queues
            this.redis = new Redis(redisConfig);

            this.redis.on('connect', () => {
                logger.info('Queue Redis connected');
                this.setupQueues();
            });

            this.redis.on('error', (error) => {
                logger.error('Queue Redis error:', error.message);
                // Continue without queues if Redis is not available
                this.setupFallbackMode();
            });

        } catch (error) {
            logger.error('Failed to initialize queue service:', error.message);
            this.setupFallbackMode();
        }
    }

    setupQueues() {
        try {
            // Grok API Queue - Rate limited
            this.queues.set('grok-api', new Queue('grok-api', {
                redis: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379,
                    password: process.env.REDIS_PASSWORD,
                    db: process.env.REDIS_QUEUE_DB || 1
                },
                defaultJobOptions: {
                    removeOnComplete: 10, // Keep last 10 completed jobs
                    removeOnFail: 20, // Keep last 20 failed jobs
                    attempts: 3, // Retry failed jobs 3 times
                    backoff: {
                        type: 'exponential',
                        delay: 2000 // Start with 2 second delay
                    },
                    delay: 1000 // Rate limit: 1 second between jobs
                }
            }));

            // ElevenLabs API Queue - More restrictive rate limiting
            this.queues.set('elevenlabs-api', new Queue('elevenlabs-api', {
                redis: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379,
                    password: process.env.REDIS_PASSWORD,
                    db: process.env.REDIS_QUEUE_DB || 1
                },
                defaultJobOptions: {
                    removeOnComplete: 5,
                    removeOnFail: 15,
                    attempts: 2, // Fewer retries for expensive operations
                    backoff: {
                        type: 'exponential',
                        delay: 5000 // Start with 5 second delay
                    },
                    delay: 3000 // Rate limit: 3 seconds between voice jobs
                }
            }));

            // Screenshot Analysis Queue - Medium priority
            this.queues.set('screenshot-analysis', new Queue('screenshot-analysis', {
                redis: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379,
                    password: process.env.REDIS_PASSWORD,
                    db: process.env.REDIS_QUEUE_DB || 1
                },
                defaultJobOptions: {
                    removeOnComplete: 15,
                    removeOnFail: 25,
                    attempts: 2,
                    backoff: {
                        type: 'fixed',
                        delay: 3000
                    },
                    delay: 500 // Faster processing for analysis
                }
            }));

            // Setup queue processors
            this.setupQueueProcessors();
            this.setupQueueEvents();

            this.isInitialized = true;
            logger.info('Queue service initialized successfully', {
                queues: Array.from(this.queues.keys()),
                redis: {
                    host: process.env.REDIS_HOST || 'localhost',
                    db: process.env.REDIS_QUEUE_DB || 1
                }
            });

        } catch (error) {
            logger.error('Failed to setup queues:', error.message);
            this.setupFallbackMode();
        }
    }

    setupQueueProcessors() {
        // Grok API processor
        const grokQueue = this.queues.get('grok-api');
        if (grokQueue) {
            grokQueue.process('generate-flirts', 1, this.processGrokFlirtGeneration.bind(this));
            grokQueue.process('analyze-screenshot', 1, this.processGrokAnalysis.bind(this));
        }

        // ElevenLabs API processor
        const elevenLabsQueue = this.queues.get('elevenlabs-api');
        if (elevenLabsQueue) {
            elevenLabsQueue.process('synthesize-voice', 1, this.processVoiceSynthesis.bind(this));
            elevenLabsQueue.process('clone-voice', 1, this.processVoiceCloning.bind(this));
        }

        // Screenshot analysis processor
        const analysisQueue = this.queues.get('screenshot-analysis');
        if (analysisQueue) {
            analysisQueue.process('analyze-screenshot', 2, this.processScreenshotAnalysis.bind(this)); // Allow 2 concurrent
        }
    }

    setupQueueEvents() {
        this.queues.forEach((queue, queueName) => {
            queue.on('completed', (job, result) => {
                logger.info('Queue job completed', {
                    queue: queueName,
                    jobId: job.id,
                    jobType: job.name,
                    duration: Date.now() - job.processedOn,
                    correlationId: job.data.correlationId
                });
            });

            queue.on('failed', (job, err) => {
                logger.error('Queue job failed', {
                    queue: queueName,
                    jobId: job.id,
                    jobType: job.name,
                    error: err.message,
                    attempts: job.attemptsMade,
                    correlationId: job.data.correlationId
                });
            });

            queue.on('stalled', (job) => {
                logger.warn('Queue job stalled', {
                    queue: queueName,
                    jobId: job.id,
                    jobType: job.name,
                    correlationId: job.data.correlationId
                });
            });

            queue.on('active', (job) => {
                logger.debug('Queue job active', {
                    queue: queueName,
                    jobId: job.id,
                    jobType: job.name,
                    correlationId: job.data.correlationId
                });
            });
        });
    }

    setupFallbackMode() {
        this.isInitialized = false;
        logger.warn('Queue service running in fallback mode - jobs will execute immediately');
    }

    // Queue job processors
    async processGrokFlirtGeneration(job) {
        const { payload, correlationId } = job.data;
        const timer = logger.timer('grok-flirt-generation', correlationId);

        try {
            const result = await circuitBreakerService.callGrokApi(payload, correlationId);
            timer.finish({ success: result.success });
            return result;
        } catch (error) {
            timer.error(error);
            throw error;
        }
    }

    async processGrokAnalysis(job) {
        const { payload, correlationId } = job.data;
        const timer = logger.timer('grok-analysis', correlationId);

        try {
            const result = await circuitBreakerService.callGrokApi(payload, correlationId);
            timer.finish({ success: result.success });
            return result;
        } catch (error) {
            timer.error(error);
            throw error;
        }
    }

    async processVoiceSynthesis(job) {
        const { voiceId, payload, correlationId } = job.data;
        const timer = logger.timer('voice-synthesis', correlationId);

        try {
            const result = await circuitBreakerService.callElevenLabsApi('synthesize', {
                voiceId,
                payload
            }, correlationId);
            timer.finish({ success: result.success });
            return result;
        } catch (error) {
            timer.error(error);
            throw error;
        }
    }

    async processVoiceCloning(job) {
        const { voiceName, description, files, correlationId } = job.data;
        const timer = logger.timer('voice-cloning', correlationId);

        try {
            const result = await circuitBreakerService.callElevenLabsApi('clone', {
                voiceName,
                description,
                files
            }, correlationId);
            timer.finish({ success: result.success });
            return result;
        } catch (error) {
            timer.error(error);
            throw error;
        }
    }

    async processScreenshotAnalysis(job) {
        const { screenshotPath, analysisType, correlationId } = job.data;
        const timer = logger.timer('screenshot-analysis', correlationId);

        try {
            // This would integrate with your screenshot analyzer
            // For now, return a mock result
            const result = {
                success: true,
                analysisResult: {
                    confidence: 0.85,
                    elements: ['profile_photo', 'bio_text'],
                    suggestions: 3
                },
                processingTime: timer.finish({ success: true })
            };

            return result;
        } catch (error) {
            timer.error(error);
            throw error;
        }
    }

    // Public methods to add jobs to queues
    async queueGrokFlirtGeneration(payload, correlationId = null, priority = 0) {
        if (!this.isInitialized) {
            // Fallback: execute immediately
            logger.debug('Queue not available, executing Grok request immediately');
            return await circuitBreakerService.callGrokApi(payload, correlationId);
        }

        const queue = this.queues.get('grok-api');
        const job = await queue.add('generate-flirts', {
            payload,
            correlationId
        }, {
            priority,
            removeOnComplete: 10,
            removeOnFail: 20
        });

        logger.debug('Grok flirt generation queued', {
            jobId: job.id,
            correlationId,
            priority,
            queueSize: await queue.count()
        });

        return job;
    }

    async queueVoiceSynthesis(voiceId, payload, correlationId = null, priority = 0) {
        if (!this.isInitialized) {
            logger.debug('Queue not available, executing ElevenLabs request immediately');
            return await circuitBreakerService.callElevenLabsApi('synthesize', {
                voiceId,
                payload
            }, correlationId);
        }

        const queue = this.queues.get('elevenlabs-api');
        const job = await queue.add('synthesize-voice', {
            voiceId,
            payload,
            correlationId
        }, {
            priority,
            removeOnComplete: 5,
            removeOnFail: 15
        });

        logger.debug('Voice synthesis queued', {
            jobId: job.id,
            voiceId,
            correlationId,
            priority,
            queueSize: await queue.count()
        });

        return job;
    }

    async queueVoiceCloning(voiceName, description, files, correlationId = null) {
        if (!this.isInitialized) {
            logger.debug('Queue not available, executing voice cloning immediately');
            return await circuitBreakerService.callElevenLabsApi('clone', {
                voiceName,
                description,
                files
            }, correlationId);
        }

        const queue = this.queues.get('elevenlabs-api');
        const job = await queue.add('clone-voice', {
            voiceName,
            description,
            files,
            correlationId
        }, {
            priority: 10, // Higher priority for cloning
            removeOnComplete: 5,
            removeOnFail: 10
        });

        logger.info('Voice cloning queued', {
            jobId: job.id,
            voiceName,
            correlationId,
            filesCount: files.length,
            queueSize: await queue.count()
        });

        return job;
    }

    async queueScreenshotAnalysis(screenshotPath, analysisType = 'full', correlationId = null) {
        if (!this.isInitialized) {
            logger.debug('Queue not available, skipping screenshot analysis queue');
            return null;
        }

        const queue = this.queues.get('screenshot-analysis');
        const job = await queue.add('analyze-screenshot', {
            screenshotPath,
            analysisType,
            correlationId
        });

        logger.debug('Screenshot analysis queued', {
            jobId: job.id,
            analysisType,
            correlationId,
            queueSize: await queue.count()
        });

        return job;
    }

    // Queue management methods
    async getQueueStats() {
        const stats = {};

        for (const [queueName, queue] of this.queues) {
            try {
                const [waiting, active, completed, failed, delayed] = await Promise.all([
                    queue.getWaiting(),
                    queue.getActive(),
                    queue.getCompleted(),
                    queue.getFailed(),
                    queue.getDelayed()
                ]);

                stats[queueName] = {
                    waiting: waiting.length,
                    active: active.length,
                    completed: completed.length,
                    failed: failed.length,
                    delayed: delayed.length,
                    total: waiting.length + active.length + completed.length + failed.length + delayed.length
                };
            } catch (error) {
                stats[queueName] = {
                    error: error.message
                };
            }
        }

        return stats;
    }

    async getJobStatus(queueName, jobId) {
        const queue = this.queues.get(queueName);
        if (!queue) {
            return null;
        }

        try {
            const job = await queue.getJob(jobId);
            if (!job) {
                return null;
            }

            return {
                id: job.id,
                name: job.name,
                data: job.data,
                progress: job.progress(),
                state: await job.getState(),
                createdAt: new Date(job.timestamp),
                processedAt: job.processedOn ? new Date(job.processedOn) : null,
                finishedAt: job.finishedOn ? new Date(job.finishedOn) : null,
                attemptsMade: job.attemptsMade,
                failedReason: job.failedReason
            };
        } catch (error) {
            logger.error('Error getting job status:', error.message);
            return null;
        }
    }

    // Health check
    async getHealthStatus() {
        if (!this.isInitialized) {
            return {
                status: 'degraded',
                mode: 'fallback',
                message: 'Queue service running without Redis'
            };
        }

        try {
            const stats = await this.getQueueStats();
            const totalJobs = Object.values(stats).reduce((sum, stat) => {
                return sum + (stat.total || 0);
            }, 0);

            const failedJobs = Object.values(stats).reduce((sum, stat) => {
                return sum + (stat.failed || 0);
            }, 0);

            const healthStatus = {
                status: 'healthy',
                mode: 'queue',
                initialized: this.isInitialized,
                queues: Object.keys(stats).length,
                totalJobs,
                failedJobs,
                stats
            };

            // Mark as degraded if too many failed jobs
            if (totalJobs > 0 && (failedJobs / totalJobs) > 0.1) {
                healthStatus.status = 'degraded';
                healthStatus.message = 'High failure rate detected';
            }

            return healthStatus;
        } catch (error) {
            return {
                status: 'error',
                error: error.message
            };
        }
    }

    // Graceful shutdown
    async shutdown() {
        logger.info('Shutting down queue service...');

        const shutdownPromises = [];

        for (const [queueName, queue] of this.queues) {
            logger.info(`Closing queue: ${queueName}`);
            shutdownPromises.push(
                queue.close().catch(error => {
                    logger.error(`Error closing queue ${queueName}:`, error.message);
                })
            );
        }

        await Promise.all(shutdownPromises);

        if (this.redis) {
            try {
                await this.redis.quit();
                logger.info('Queue Redis connection closed');
            } catch (error) {
                logger.error('Error closing queue Redis connection:', error.message);
            }
        }

        logger.info('Queue service shutdown complete');
    }
}

// Export singleton instance
const queueService = new QueueService();

module.exports = queueService;