const CircuitBreaker = require('opossum');
const { logger } = require('./logger');

class CircuitBreakerService {
    constructor() {
        this.breakers = new Map();
        this.setupCircuitBreakers();
    }

    setupCircuitBreakers() {
        // Grok API Circuit Breaker
        const grokOptions = {
            timeout: 30000, // 30 second timeout
            errorThresholdPercentage: 50, // Open circuit if 50% of requests fail
            resetTimeout: 60000, // Try again after 60 seconds
            rollingCountTimeout: 60000, // Rolling window for error counting
            rollingCountBuckets: 10, // Number of buckets in rolling window
            volumeThreshold: 5, // Minimum number of requests before circuit can open
            enabled: true
        };

        this.breakers.set('grok', new CircuitBreaker(this.makeGrokRequest, grokOptions));

        // ElevenLabs API Circuit Breaker
        const elevenLabsOptions = {
            timeout: 60000, // 60 second timeout for voice synthesis
            errorThresholdPercentage: 60, // More lenient for voice synthesis
            resetTimeout: 120000, // Try again after 2 minutes
            rollingCountTimeout: 120000,
            rollingCountBuckets: 10,
            volumeThreshold: 3,
            enabled: true
        };

        this.breakers.set('elevenlabs', new CircuitBreaker(this.makeElevenLabsRequest, elevenLabsOptions));

        // Setup event listeners for all circuit breakers
        this.breakers.forEach((breaker, serviceName) => {
            this.setupBreakerEvents(breaker, serviceName);
        });

        logger.info('Circuit breakers initialized', {
            services: Array.from(this.breakers.keys()),
            grokTimeout: grokOptions.timeout,
            elevenLabsTimeout: elevenLabsOptions.timeout
        });
    }

    setupBreakerEvents(breaker, serviceName) {
        breaker.on('open', () => {
            logger.warn('Circuit breaker opened', {
                service: serviceName,
                stats: breaker.stats
            });
        });

        breaker.on('halfOpen', () => {
            logger.info('Circuit breaker half-open', {
                service: serviceName,
                stats: breaker.stats
            });
        });

        breaker.on('close', () => {
            logger.info('Circuit breaker closed', {
                service: serviceName,
                stats: breaker.stats
            });
        });

        breaker.on('reject', () => {
            logger.warn('Circuit breaker rejected request', {
                service: serviceName,
                state: breaker.state
            });
        });

        breaker.on('timeout', (error) => {
            logger.warn('Circuit breaker timeout', {
                service: serviceName,
                error: error.message,
                timeout: breaker.options.timeout
            });
        });

        breaker.on('success', (result) => {
            logger.debug('Circuit breaker success', {
                service: serviceName,
                responseTime: result.duration || 'unknown'
            });
        });

        breaker.on('failure', (error) => {
            logger.error('Circuit breaker failure', {
                service: serviceName,
                error: error.message,
                stats: breaker.stats
            });
        });
    }

    // Grok API request function
    async makeGrokRequest(requestData) {
        const axios = require('axios');
        const startTime = Date.now();

        try {
            const response = await axios.post(
                `${process.env.GROK_API_URL}/chat/completions`,
                requestData.payload,
                {
                    headers: {
                        'Authorization': `Bearer ${process.env.GROK_API_KEY}`,
                        'Content-Type': 'application/json'
                    },
                    timeout: 25000 // Slightly less than circuit breaker timeout
                }
            );

            const duration = Date.now() - startTime;

            logger.info('Grok API request successful', {
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                model: requestData.payload.model
            });

            return {
                success: true,
                data: response.data,
                duration,
                statusCode: response.status
            };

        } catch (error) {
            const duration = Date.now() - startTime;

            logger.error('Grok API request failed', {
                error: error.message,
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                statusCode: error.response?.status,
                responseData: error.response?.data
            });

            throw error;
        }
    }

    // ElevenLabs API request function
    async makeElevenLabsRequest(requestData) {
        const axios = require('axios');
        const FormData = require('form-data');
        const startTime = Date.now();

        try {
            let response;

            if (requestData.operation === 'synthesize') {
                // Voice synthesis
                response = await axios.post(
                    `https://api.elevenlabs.io/v1/text-to-speech/${requestData.voiceId}`,
                    requestData.payload,
                    {
                        headers: {
                            'xi-api-key': process.env.ELEVENLABS_API_KEY,
                            'Content-Type': 'application/json'
                        },
                        responseType: 'arraybuffer',
                        timeout: 55000 // Slightly less than circuit breaker timeout
                    }
                );
            } else if (requestData.operation === 'clone') {
                // Voice cloning
                const formData = new FormData();
                formData.append('name', requestData.voiceName);
                formData.append('description', requestData.description || '');

                requestData.files.forEach((file, index) => {
                    formData.append('files', file.buffer, file.filename);
                });

                response = await axios.post(
                    'https://api.elevenlabs.io/v1/voices/add',
                    formData,
                    {
                        headers: {
                            'xi-api-key': process.env.ELEVENLABS_API_KEY,
                            ...formData.getHeaders()
                        },
                        timeout: 55000
                    }
                );
            }

            const duration = Date.now() - startTime;

            logger.info('ElevenLabs API request successful', {
                operation: requestData.operation,
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                voiceId: requestData.voiceId || 'new_voice'
            });

            return {
                success: true,
                data: response.data,
                duration,
                statusCode: response.status
            };

        } catch (error) {
            const duration = Date.now() - startTime;

            logger.error('ElevenLabs API request failed', {
                operation: requestData.operation,
                error: error.message,
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                statusCode: error.response?.status
            });

            throw error;
        }
    }

    // Public methods to make requests through circuit breakers
    async callGrokApi(payload, correlationId = null) {
        const breaker = this.breakers.get('grok');

        if (!breaker) {
            throw new Error('Grok circuit breaker not initialized');
        }

        try {
            const result = await breaker.fire({
                payload,
                correlationId
            });

            return result;
        } catch (error) {
            if (breaker.state === 'open') {
                logger.warn('Grok API circuit breaker is open, providing fallback', {
                    correlationId,
                    state: breaker.state
                });

                // Return fallback response
                return {
                    success: false,
                    fallback: true,
                    error: 'Service temporarily unavailable',
                    retryAfter: breaker.options.resetTimeout / 1000
                };
            }

            throw error;
        }
    }

    async callElevenLabsApi(operation, requestData, correlationId = null) {
        const breaker = this.breakers.get('elevenlabs');

        if (!breaker) {
            throw new Error('ElevenLabs circuit breaker not initialized');
        }

        try {
            const result = await breaker.fire({
                operation,
                correlationId,
                ...requestData
            });

            return result;
        } catch (error) {
            if (breaker.state === 'open') {
                logger.warn('ElevenLabs API circuit breaker is open', {
                    operation,
                    correlationId,
                    state: breaker.state
                });

                return {
                    success: false,
                    fallback: true,
                    error: 'Voice service temporarily unavailable',
                    retryAfter: breaker.options.resetTimeout / 1000
                };
            }

            throw error;
        }
    }

    // Health check for circuit breakers
    getHealthStatus() {
        const health = {
            status: 'healthy',
            breakers: {}
        };

        this.breakers.forEach((breaker, serviceName) => {
            const stats = breaker.stats;

            health.breakers[serviceName] = {
                state: breaker.state,
                stats: {
                    requests: stats.requests,
                    successes: stats.successes,
                    failures: stats.failures,
                    rejects: stats.rejects,
                    timeouts: stats.timeouts,
                    successRate: stats.requests > 0 ? (stats.successes / stats.requests * 100).toFixed(2) + '%' : '0%',
                    errorRate: stats.requests > 0 ? (stats.failures / stats.requests * 100).toFixed(2) + '%' : '0%'
                },
                config: {
                    timeout: breaker.options.timeout,
                    errorThreshold: breaker.options.errorThresholdPercentage + '%',
                    resetTimeout: breaker.options.resetTimeout / 1000 + 's'
                }
            };

            // If any breaker is open or has high error rate, mark as degraded
            if (breaker.state === 'open' || (stats.failures / Math.max(stats.requests, 1)) > 0.5) {
                health.status = 'degraded';
            }
        });

        return health;
    }

    // Reset circuit breaker stats (for testing/admin purposes)
    resetBreaker(serviceName) {
        const breaker = this.breakers.get(serviceName);
        if (breaker) {
            breaker.stats.reset();
            logger.info('Circuit breaker stats reset', { service: serviceName });
            return true;
        }
        return false;
    }

    // Force close circuit breaker (for testing/admin purposes)
    forceCloseBreaker(serviceName) {
        const breaker = this.breakers.get(serviceName);
        if (breaker) {
            breaker.close();
            logger.info('Circuit breaker forced closed', { service: serviceName });
            return true;
        }
        return false;
    }

    // Get all breaker states
    getAllStates() {
        const states = {};
        this.breakers.forEach((breaker, serviceName) => {
            states[serviceName] = {
                state: breaker.state,
                enabled: breaker.enabled
            };
        });
        return states;
    }
}

// Export singleton instance
const circuitBreakerService = new CircuitBreakerService();

module.exports = circuitBreakerService;