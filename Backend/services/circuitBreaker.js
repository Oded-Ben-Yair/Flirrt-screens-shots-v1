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
            timeout: 35000, // 35 second timeout
            errorThresholdPercentage: 50, // Open circuit if 50% of requests fail
            resetTimeout: 60000, // Try again after 60 seconds
            rollingCountTimeout: 60000, // Rolling window for error counting
            rollingCountBuckets: 10, // Number of buckets in rolling window
            volumeThreshold: 5, // Minimum number of requests before circuit can open
            enabled: true
        };

        // Create bound function for Grok API calls
        const boundGrokRequest = (requestData) => this.makeGrokRequest(requestData);
        this.breakers.set('grok', new CircuitBreaker(boundGrokRequest, grokOptions));

        // Grok-4 Fast Reasoning Model Circuit Breaker
        const grok4ReasoningOptions = {
            timeout: 8000, // 8 second timeout for reasoning model
            errorThresholdPercentage: 40, // More sensitive for fast model
            resetTimeout: 30000, // Try again after 30 seconds
            rollingCountTimeout: 60000,
            rollingCountBuckets: 10,
            volumeThreshold: 3,
            enabled: true
        };

        const boundGrok4ReasoningRequest = (requestData) => this.makeGrok4FastRequest(requestData);
        this.breakers.set('grok4-reasoning', new CircuitBreaker(boundGrok4ReasoningRequest, grok4ReasoningOptions));

        // Grok-4 Fast Non-Reasoning Model Circuit Breaker
        const grok4NonReasoningOptions = {
            timeout: 3000, // 3 second timeout for non-reasoning model
            errorThresholdPercentage: 30, // Very sensitive for ultra-fast model
            resetTimeout: 15000, // Try again after 15 seconds
            rollingCountTimeout: 30000,
            rollingCountBuckets: 10,
            volumeThreshold: 3,
            enabled: true
        };

        const boundGrok4NonReasoningRequest = (requestData) => this.makeGrok4FastRequest(requestData);
        this.breakers.set('grok4-non-reasoning', new CircuitBreaker(boundGrok4NonReasoningRequest, grok4NonReasoningOptions));

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

        // Create bound function for ElevenLabs API calls
        const boundElevenLabsRequest = (requestData) => this.makeElevenLabsRequest(requestData);
        this.breakers.set('elevenlabs', new CircuitBreaker(boundElevenLabsRequest, elevenLabsOptions));

        // Gemini API Circuit Breaker
        const geminiOptions = {
            timeout: 45000, // 45 second timeout for image analysis
            errorThresholdPercentage: 40, // More sensitive for vision analysis
            resetTimeout: 90000, // Try again after 90 seconds
            rollingCountTimeout: 90000,
            rollingCountBuckets: 10,
            volumeThreshold: 3,
            enabled: true
        };

        // Create bound function for Gemini API calls
        const boundGeminiRequest = (requestData) => this.makeGeminiRequest(requestData);
        this.breakers.set('gemini', new CircuitBreaker(boundGeminiRequest, geminiOptions));

        // Setup event listeners for all circuit breakers
        this.breakers.forEach((breaker, serviceName) => {
            this.setupBreakerEvents(breaker, serviceName);
        });

        logger.info('Circuit breakers initialized', {
            services: Array.from(this.breakers.keys()),
            grokTimeout: grokOptions.timeout,
            grok4ReasoningTimeout: grok4ReasoningOptions.timeout,
            grok4NonReasoningTimeout: grok4NonReasoningOptions.timeout,
            elevenLabsTimeout: elevenLabsOptions.timeout,
            geminiTimeout: geminiOptions.timeout
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

    // Retry wrapper with exponential backoff
    async retryWithBackoff(fn, maxRetries = 2, baseDelay = 1000) {
        let lastError;

        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                return await fn();
            } catch (error) {
                lastError = error;

                // Don't retry on authentication errors or client errors (4xx)
                if (error.response?.status >= 400 && error.response?.status < 500) {
                    throw error;
                }

                // If this was the last attempt, throw the error
                if (attempt === maxRetries) {
                    throw error;
                }

                // Calculate delay with exponential backoff and jitter
                const delay = baseDelay * Math.pow(2, attempt) + Math.random() * 1000;

                logger.warn('Request failed, retrying', {
                    attempt: attempt + 1,
                    maxRetries: maxRetries + 1,
                    delayMs: Math.round(delay),
                    error: error.message
                });

                // Wait before retrying
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }

        throw lastError;
    }

    // Grok-4 Fast API request function
    async makeGrok4FastRequest(requestData) {
        const axios = require('axios');
        const startTime = Date.now();

        try {
            const response = await this.retryWithBackoff(async () => {
                const config = {
                    headers: {
                        'Authorization': `Bearer ${process.env.GROK_API_KEY}`,
                        'Content-Type': 'application/json'
                    },
                    timeout: requestData.streaming ? 15000 : 8000 // Longer timeout for streaming
                };

                if (requestData.streaming) {
                    config.responseType = 'stream';
                }

                return await axios.post(
                    `${process.env.GROK_API_URL}/chat/completions`,
                    requestData.payload,
                    config
                );
            });

            const duration = Date.now() - startTime;

            logger.info('Grok-4 Fast API request successful', {
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                model: requestData.payload.model,
                streaming: requestData.streaming || false
            });

            return {
                success: true,
                data: response.data,
                duration,
                statusCode: response.status,
                streaming: requestData.streaming || false
            };

        } catch (error) {
            const duration = Date.now() - startTime;

            logger.error('Grok-4 Fast API request failed', {
                error: error.message,
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                statusCode: error.response?.status,
                model: requestData.payload?.model,
                responseData: error.response?.data
            });

            throw error;
        }
    }

    // Grok API request function
    async makeGrokRequest(requestData) {
        const axios = require('axios');
        const startTime = Date.now();

        try {
            const response = await this.retryWithBackoff(async () => {
                return await axios.post(
                    `${process.env.GROK_API_URL}/chat/completions`,
                    requestData.payload,
                    {
                        headers: {
                            'Authorization': `Bearer ${process.env.GROK_API_KEY}`,
                            'Content-Type': 'application/json'
                        },
                        timeout: 30000 // Slightly less than circuit breaker timeout
                    }
                );
            });

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
                // Voice synthesis with retry
                response = await this.retryWithBackoff(async () => {
                    return await axios.post(
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
                });
            } else if (requestData.operation === 'clone') {
                // Voice cloning with retry
                response = await this.retryWithBackoff(async () => {
                    const formData = new FormData();
                    formData.append('name', requestData.voiceName);
                    formData.append('description', requestData.description || '');

                    requestData.files.forEach((file, index) => {
                        formData.append('files', file.buffer, file.filename);
                    });

                    return await axios.post(
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
                });
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

    // Gemini API request function
    async makeGeminiRequest(requestData) {
        const { GoogleGenAI } = require('@google/genai');
        const OpenAI = require('openai');
        const startTime = Date.now();

        try {
            let response;

            if (requestData.operation === 'vision_analysis') {
                // Use Google GenAI for image analysis
                if (process.env.GEMINI_API_KEY) {
                    const googleAI = new GoogleGenAI(process.env.GEMINI_API_KEY);
                    const model = googleAI.getGenerativeModel({
                        model: "gemini-2.5-pro",
                        generationConfig: {
                            maxOutputTokens: 2048,
                            temperature: 0.4,
                        }
                    });

                    response = await this.retryWithBackoff(async () => {
                        return await model.generateContent(requestData.contents);
                    });
                } else {
                    throw new Error('GEMINI_API_KEY not configured');
                }
            } else if (requestData.operation === 'openai_compatible') {
                // Use OpenAI-compatible Gemini API
                const openai = new OpenAI({
                    apiKey: process.env.GEMINI_API_KEY,
                    baseURL: "https://generativelanguage.googleapis.com/v1beta/openai/"
                });

                response = await this.retryWithBackoff(async () => {
                    return await openai.chat.completions.create(requestData.payload);
                });
            } else {
                throw new Error(`Unknown Gemini operation: ${requestData.operation}`);
            }

            const duration = Date.now() - startTime;

            logger.info('Gemini API request successful', {
                operation: requestData.operation,
                duration: `${duration}ms`,
                correlationId: requestData.correlationId,
                model: 'gemini-2.5-pro'
            });

            return {
                success: true,
                data: response,
                duration,
                operation: requestData.operation
            };

        } catch (error) {
            const duration = Date.now() - startTime;

            logger.error('Gemini API request failed', {
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

    async callGeminiApi(operation, requestData, correlationId = null) {
        const breaker = this.breakers.get('gemini');

        if (!breaker) {
            throw new Error('Gemini circuit breaker not initialized');
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
                logger.warn('Gemini API circuit breaker is open', {
                    operation,
                    correlationId,
                    state: breaker.state
                });

                return {
                    success: false,
                    fallback: true,
                    error: 'Vision analysis service temporarily unavailable',
                    retryAfter: breaker.options.resetTimeout / 1000
                };
            }

            throw error;
        }
    }

    async callGrok4FastApi(modelType, payload, correlationId = null, streaming = false) {
        const breakerName = modelType === 'reasoning' ? 'grok4-reasoning' : 'grok4-non-reasoning';
        const breaker = this.breakers.get(breakerName);

        if (!breaker) {
            throw new Error(`Grok-4 Fast ${modelType} circuit breaker not initialized`);
        }

        try {
            const result = await breaker.fire({
                payload,
                correlationId,
                streaming
            });

            return result;
        } catch (error) {
            if (breaker.state === 'open') {
                logger.warn(`Grok-4 Fast ${modelType} circuit breaker is open`, {
                    correlationId,
                    state: breaker.state,
                    modelType
                });

                return {
                    success: false,
                    fallback: true,
                    error: `Grok-4 Fast ${modelType} service temporarily unavailable`,
                    retryAfter: breaker.options.resetTimeout / 1000,
                    modelType
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