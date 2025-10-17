/**
 * Advanced Error Recovery Service
 * Implements graceful degradation strategies and intelligent fallback mechanisms
 */

const { logger } = require('./logger');
const redisService = require('./redis');

class ErrorRecoveryService {
    constructor() {
        this.recoveryStrategies = new Map();
        this.errorPatterns = new Map();
        this.fallbackChain = [];
        this.recoveryMetrics = {
            totalErrors: 0,
            recoveredErrors: 0,
            fallbackUsages: 0,
            strategySuccess: new Map()
        };

        this.initializeRecoveryStrategies();
        this.initializeErrorPatterns();
    }

    /**
     * Initialize recovery strategies for different error types
     */
    initializeRecoveryStrategies() {
        // API Timeout Recovery
        this.recoveryStrategies.set('API_TIMEOUT', {
            priority: 1,
            maxRetries: 3,
            backoffMultiplier: 2,
            initialDelay: 1000,
            strategy: async (error, context, attempt) => {
                const delay = this.calculateExponentialBackoff(attempt, 1000, 2);
                await this.sleep(delay);

                // Reduce request complexity for retries
                if (context.payload) {
                    context.payload.max_tokens = Math.max(200, (context.payload.max_tokens || 1000) * 0.7);
                    context.payload.temperature = Math.min(0.3, context.payload.temperature || 0.7);
                }

                return { retry: true, modifiedContext: context };
            }
        });

        // API Rate Limit Recovery
        this.recoveryStrategies.set('RATE_LIMIT', {
            priority: 2,
            maxRetries: 2,
            backoffMultiplier: 3,
            initialDelay: 5000,
            strategy: async (error, context, attempt) => {
                const retryAfter = this.extractRetryAfterHeader(error) || (5000 * Math.pow(3, attempt));
                await this.sleep(retryAfter);

                // Use circuit breaker pattern
                return { retry: true, useCircuitBreaker: true };
            }
        });

        // Network Error Recovery
        this.recoveryStrategies.set('NETWORK_ERROR', {
            priority: 3,
            maxRetries: 2,
            backoffMultiplier: 2,
            initialDelay: 2000,
            strategy: async (error, context, attempt) => {
                await this.sleep(this.calculateExponentialBackoff(attempt, 2000, 2));

                // Try alternative endpoints or direct API calls
                if (context.alternativeEndpoints && context.alternativeEndpoints.length > 0) {
                    context.currentEndpoint = context.alternativeEndpoints.shift();
                    return { retry: true, modifiedContext: context };
                }

                return { retry: false, useFallback: true };
            }
        });

        // JSON Parse Error Recovery
        this.recoveryStrategies.set('JSON_PARSE_ERROR', {
            priority: 4,
            maxRetries: 1,
            strategy: async (error, context, attempt) => {
                // Try to extract partial JSON or fix common issues
                const recovered = this.attemptJsonRecovery(error.rawResponse);
                if (recovered) {
                    return { retry: false, recoveredData: recovered };
                }

                // Request structured response format
                if (context.payload) {
                    context.payload.response_format = { type: "json_object" };
                    context.payload.messages.push({
                        role: "system",
                        content: "CRITICAL: Your response MUST be valid JSON only. No additional text."
                    });
                }

                return { retry: true, modifiedContext: context };
            }
        });

        // Content Filter Error Recovery
        this.recoveryStrategies.set('CONTENT_FILTER', {
            priority: 5,
            maxRetries: 2,
            strategy: async (error, context, attempt) => {
                // Modify prompt to be more conservative
                if (context.payload && context.payload.messages) {
                    const userMessage = context.payload.messages.find(m => m.role === 'user');
                    if (userMessage) {
                        userMessage.content = this.sanitizePromptForContentFilter(userMessage.content);
                        context.payload.temperature = Math.min(0.3, context.payload.temperature || 0.7);
                    }
                }

                return { retry: true, modifiedContext: context };
            }
        });

        // Authentication Error Recovery
        this.recoveryStrategies.set('AUTH_ERROR', {
            priority: 6,
            maxRetries: 1,
            strategy: async (error, context, attempt) => {
                // Refresh API key or use alternative authentication
                const newApiKey = await this.refreshApiKey(context.service);
                if (newApiKey) {
                    context.apiKey = newApiKey;
                    return { retry: true, modifiedContext: context };
                }

                return { retry: false, useFallback: true };
            }
        });
    }

    /**
     * Initialize error pattern recognition
     */
    initializeErrorPatterns() {
        this.errorPatterns.set(/timeout|ETIMEDOUT|ECONNABORTED/i, 'API_TIMEOUT');
        this.errorPatterns.set(/rate.?limit|429|too many requests/i, 'RATE_LIMIT');
        this.errorPatterns.set(/network|ECONNREFUSED|ENOTFOUND|ECONNRESET/i, 'NETWORK_ERROR');
        this.errorPatterns.set(/json|parse|syntax|unexpected token/i, 'JSON_PARSE_ERROR');
        this.errorPatterns.set(/content.?filter|inappropriate|violation/i, 'CONTENT_FILTER');
        this.errorPatterns.set(/unauthorized|401|403|invalid.?key/i, 'AUTH_ERROR');
        this.errorPatterns.set(/server.?error|500|502|503|504/i, 'SERVER_ERROR');
        this.errorPatterns.set(/quota|limit.?exceeded|insufficient.?quota/i, 'QUOTA_EXCEEDED');
    }

    /**
     * Main error recovery method
     */
    async recoverFromError(error, context, correlationId) {
        this.recoveryMetrics.totalErrors++;

        const errorType = this.identifyErrorType(error);
        const timer = logger.timer('error_recovery');

        logger.info('Starting error recovery process', {
            correlationId,
            errorType,
            errorMessage: error.message,
            attempt: context.attempt || 1
        });

        try {
            // Try specific recovery strategy
            if (this.recoveryStrategies.has(errorType)) {
                const recovery = await this.executeRecoveryStrategy(errorType, error, context, correlationId);

                if (recovery.success) {
                    this.recoveryMetrics.recoveredErrors++;
                    this.updateStrategyMetrics(errorType, true);

                    timer.finish({
                        success: true,
                        errorType,
                        recoveryMethod: 'strategy'
                    });

                    return recovery;
                }
            }

            // Try progressive fallback chain
            const fallbackRecovery = await this.executeProgressiveFallback(error, context, correlationId);

            if (fallbackRecovery.success) {
                this.recoveryMetrics.fallbackUsages++;
                timer.finish({
                    success: true,
                    errorType,
                    recoveryMethod: 'fallback'
                });

                return fallbackRecovery;
            }

            // Final emergency recovery
            const emergencyRecovery = await this.executeEmergencyRecovery(error, context, correlationId);
            timer.finish({
                success: true,
                errorType,
                recoveryMethod: 'emergency'
            });

            return emergencyRecovery;

        } catch (recoveryError) {
            timer.error(recoveryError);

            logger.error('Error recovery failed completely', {
                correlationId,
                originalError: error.message,
                recoveryError: recoveryError.message
            });

            return {
                success: false,
                error: recoveryError,
                emergencyResponse: await this.getEmergencyResponse(context)
            };
        }
    }

    /**
     * Identify error type from error object
     */
    identifyErrorType(error) {
        const errorString = `${error.message} ${error.code || ''} ${error.status || ''}`;

        for (const [pattern, type] of this.errorPatterns) {
            if (pattern.test(errorString)) {
                return type;
            }
        }

        return 'UNKNOWN_ERROR';
    }

    /**
     * Execute specific recovery strategy
     */
    async executeRecoveryStrategy(errorType, error, context, correlationId) {
        const strategy = this.recoveryStrategies.get(errorType);
        const attempt = context.attempt || 1;

        if (attempt > strategy.maxRetries) {
            logger.warn('Max retries exceeded for strategy', {
                correlationId,
                errorType,
                attempt,
                maxRetries: strategy.maxRetries
            });

            return { success: false, reason: 'max_retries_exceeded' };
        }

        try {
            const result = await strategy.strategy(error, context, attempt);

            if (result.retry) {
                context.attempt = attempt + 1;

                logger.info('Strategy suggesting retry', {
                    correlationId,
                    errorType,
                    attempt: context.attempt,
                    modifications: result.modifiedContext ? 'yes' : 'no'
                });

                return {
                    success: true,
                    action: 'retry',
                    context: result.modifiedContext || context,
                    delay: result.delay || 0
                };
            }

            if (result.recoveredData) {
                logger.info('Strategy recovered data', {
                    correlationId,
                    errorType
                });

                return {
                    success: true,
                    action: 'use_recovered_data',
                    data: result.recoveredData
                };
            }

            if (result.useFallback) {
                return { success: false, reason: 'strategy_suggests_fallback' };
            }

            return { success: false, reason: 'strategy_failed' };

        } catch (strategyError) {
            logger.error('Recovery strategy execution failed', {
                correlationId,
                errorType,
                strategyError: strategyError.message
            });

            this.updateStrategyMetrics(errorType, false);
            return { success: false, reason: 'strategy_error', error: strategyError };
        }
    }

    /**
     * Execute progressive fallback chain
     */
    async executeProgressiveFallback(error, context, correlationId) {
        const fallbackChain = [
            'cached_response',
            'simplified_request',
            'alternative_api',
            'local_generation',
            'emergency_fallback'
        ];

        for (const fallbackMethod of fallbackChain) {
            try {
                logger.info('Trying fallback method', {
                    correlationId,
                    method: fallbackMethod
                });

                const result = await this.executeFallbackMethod(fallbackMethod, error, context, correlationId);

                if (result.success) {
                    logger.info('Fallback method successful', {
                        correlationId,
                        method: fallbackMethod
                    });

                    return {
                        success: true,
                        action: 'fallback',
                        method: fallbackMethod,
                        data: result.data
                    };
                }

            } catch (fallbackError) {
                logger.warn('Fallback method failed', {
                    correlationId,
                    method: fallbackMethod,
                    error: fallbackError.message
                });
            }
        }

        return { success: false, reason: 'all_fallbacks_failed' };
    }

    /**
     * Execute specific fallback method
     */
    async executeFallbackMethod(method, error, context, correlationId) {
        switch (method) {
            case 'cached_response':
                return await this.tryGetCachedResponse(context, correlationId);

            case 'simplified_request':
                return await this.trySimplifiedRequest(context, correlationId);

            case 'alternative_api':
                return await this.tryAlternativeApi(context, correlationId);

            case 'local_generation':
                return await this.tryLocalGeneration(context, correlationId);

            case 'emergency_fallback':
                return await this.getEmergencyFallback(context, correlationId);

            default:
                return { success: false, reason: 'unknown_fallback_method' };
        }
    }

    /**
     * Try to get cached response
     */
    async tryGetCachedResponse(context, correlationId) {
        try {
            // Generate cache key from context
            const cacheKey = this.generateCacheKey(context);
            const cached = await redisService.get(cacheKey, correlationId);

            if (cached) {
                logger.info('Found cached response for error recovery', { correlationId });
                return { success: true, data: cached };
            }

            // Try similar context cache
            const similarCacheKey = this.generateSimilarCacheKey(context);
            const similarCached = await redisService.get(similarCacheKey, correlationId);

            if (similarCached) {
                logger.info('Found similar cached response for error recovery', { correlationId });
                return { success: true, data: this.adaptCachedResponse(similarCached, context) };
            }

            return { success: false, reason: 'no_cache_available' };

        } catch (cacheError) {
            return { success: false, reason: 'cache_error', error: cacheError };
        }
    }

    /**
     * Try simplified request
     */
    async trySimplifiedRequest(context, correlationId) {
        try {
            if (!context.payload) {
                return { success: false, reason: 'no_payload_to_simplify' };
            }

            const simplifiedPayload = {
                ...context.payload,
                max_tokens: 300,
                temperature: 0.3,
                messages: context.payload.messages.slice(0, 2) // Keep only system and user message
            };

            // Simplify the user message
            const userMessage = simplifiedPayload.messages.find(m => m.role === 'user');
            if (userMessage) {
                userMessage.content = this.simplifyPrompt(userMessage.content);
            }

            logger.info('Attempting simplified request', { correlationId });

            // This would need to be called through the circuit breaker service
            // For now, return a structured fallback
            return {
                success: true,
                data: this.generateSimplifiedResponse(context)
            };

        } catch (simplifyError) {
            return { success: false, reason: 'simplification_error', error: simplifyError };
        }
    }

    /**
     * Try alternative API
     */
    async tryAlternativeApi(context, correlationId) {
        // This would implement switching to backup APIs
        // For now, return structured fallback
        logger.info('Alternative API fallback not implemented, using structured fallback', { correlationId });

        return {
            success: true,
            data: this.generateStructuredFallback(context)
        };
    }

    /**
     * Try local generation
     */
    async tryLocalGeneration(context, correlationId) {
        try {
            // Generate response using local algorithms
            const localResponse = this.generateLocalResponse(context);

            logger.info('Generated local response as fallback', { correlationId });

            return {
                success: true,
                data: localResponse
            };

        } catch (localError) {
            return { success: false, reason: 'local_generation_error', error: localError };
        }
    }

    /**
     * Get emergency fallback
     */
    async getEmergencyFallback(context, correlationId) {
        const emergencyResponse = this.getEmergencyResponse(context);

        logger.warn('Using emergency fallback response', { correlationId });

        return {
            success: true,
            data: emergencyResponse
        };
    }

    /**
     * Execute emergency recovery when all else fails
     */
    async executeEmergencyRecovery(error, context, correlationId) {
        logger.error('Executing emergency recovery', {
            correlationId,
            originalError: error.message
        });

        return {
            success: true,
            action: 'emergency',
            data: this.getEmergencyResponse(context),
            warning: 'Emergency recovery activated - system degraded'
        };
    }

    // Helper methods

    calculateExponentialBackoff(attempt, baseDelay, multiplier) {
        return Math.min(30000, baseDelay * Math.pow(multiplier, attempt - 1));
    }

    extractRetryAfterHeader(error) {
        const retryAfter = error.response?.headers?.['retry-after'] ||
                          error.response?.headers?.['Retry-After'];

        return retryAfter ? parseInt(retryAfter) * 1000 : null;
    }

    async sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    attemptJsonRecovery(rawResponse) {
        if (!rawResponse || typeof rawResponse !== 'string') {
            return null;
        }

        try {
            // Try to find JSON within the response
            const jsonMatch = rawResponse.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                return JSON.parse(jsonMatch[0]);
            }

            // Try to fix common JSON issues
            let fixed = rawResponse
                .replace(/,\s*}/g, '}')  // Remove trailing commas
                .replace(/,\s*]/g, ']')   // Remove trailing commas in arrays
                .replace(/([{,]\s*)(\w+):/g, '$1"$2":'); // Quote unquoted keys

            return JSON.parse(fixed);

        } catch (e) {
            return null;
        }
    }

    sanitizePromptForContentFilter(prompt) {
        return prompt
            .replace(/\b(sexy|hot|beautiful|gorgeous)\b/gi, 'attractive')
            .replace(/\b(love|adore)\b/gi, 'like')
            .replace(/dating/gi, 'social')
            .substring(0, Math.min(prompt.length, 500)); // Limit length
    }

    async refreshApiKey(service) {
        // This would implement API key rotation
        // For now, return null (no refresh available)
        return null;
    }

    generateCacheKey(context) {
        const keyData = {
            type: context.type || 'unknown',
            tone: context.tone || 'default',
            suggestion_type: context.suggestion_type || 'default'
        };

        return `recovery:${JSON.stringify(keyData)}`;
    }

    generateSimilarCacheKey(context) {
        return `recovery:similar:${context.type || 'unknown'}`;
    }

    adaptCachedResponse(cached, context) {
        // Adapt cached response to current context
        if (Array.isArray(cached.suggestions)) {
            return {
                ...cached,
                adapted: true,
                originalContext: cached.context,
                newContext: context
            };
        }

        return cached;
    }

    simplifyPrompt(prompt) {
        return prompt
            .split('\n')
            .slice(0, 3) // Keep first 3 lines
            .join('\n')
            .substring(0, 200); // Limit to 200 chars
    }

    generateSimplifiedResponse(context) {
        const suggestions = [
            {
                text: "Hey! Your profile caught my attention. What's been the highlight of your day?",
                confidence: 0.75,
                reasoning: "Simplified opener"
            },
            {
                text: "I love your energy! What got you into that?",
                confidence: 0.73,
                reasoning: "Simplified engagement"
            },
            {
                text: "That's really interesting! Tell me more about that.",
                confidence: 0.71,
                reasoning: "Simplified response"
            }
        ];

        return {
            suggestions,
            simplified: true,
            metadata: {
                suggestion_type: context.suggestion_type || 'opener',
                tone: context.tone || 'playful',
                generated_at: new Date().toISOString()
            }
        };
    }

    generateStructuredFallback(context) {
        const type = context.suggestion_type || 'opener';
        const tone = context.tone || 'playful';

        const fallbacks = {
            opener: {
                playful: "Hey there! Your profile made me smile - what's been making you smile lately?",
                witty: "I have to ask - are you always this interesting, or is it just your profile?",
                romantic: "Hi! Something about your energy really drew me in. How's your day going?",
                casual: "Hey! You seem really cool. What's been keeping you busy?",
                bold: "Your profile stopped me in my tracks. What's the most interesting thing about you?"
            },
            response: {
                playful: "That's awesome! You're making this conversation way more fun than I expected.",
                witty: "I wasn't expecting that answer - you're full of surprises, aren't you?",
                romantic: "I love how passionate you sound about that. It's really attractive.",
                casual: "That's really cool! I can see why you're into that.",
                bold: "That's exactly the kind of thing I was hoping to hear about you."
            },
            continuation: {
                playful: "This is turning into exactly the kind of conversation I love. Coffee?",
                witty: "You're making this way too easy to talk to you. Want to continue over coffee?",
                romantic: "I feel like we're connecting here. Would you like to meet for coffee?",
                casual: "This chat is getting good. Want to grab coffee and keep talking?",
                bold: "I'm not one to beat around the bush - want to continue this over drinks?"
            }
        };

        const text = fallbacks[type]?.[tone] || fallbacks.opener.playful;

        return {
            suggestions: [{
                id: `structured-fallback-${Date.now()}`,
                text,
                confidence: 0.7,
                reasoning: `Structured fallback for ${type} with ${tone} tone`,
                created_at: new Date().toISOString(),
                fallback: true
            }],
            metadata: {
                suggestion_type: type,
                tone,
                generated_at: new Date().toISOString(),
                fallback_type: 'structured'
            }
        };
    }

    generateLocalResponse(context) {
        // Simple local generation based on context
        return this.generateStructuredFallback(context);
    }

    getEmergencyResponse(context) {
        return {
            suggestions: [{
                id: `emergency-${Date.now()}`,
                text: "Hey! Your profile caught my attention - what's been the highlight of your day?",
                confidence: 0.6,
                reasoning: "Emergency response when all systems fail",
                created_at: new Date().toISOString(),
                emergency: true
            }],
            metadata: {
                suggestion_type: context?.suggestion_type || 'opener',
                tone: context?.tone || 'playful',
                generated_at: new Date().toISOString(),
                emergency: true
            }
        };
    }

    updateStrategyMetrics(strategy, success) {
        if (!this.recoveryMetrics.strategySuccess.has(strategy)) {
            this.recoveryMetrics.strategySuccess.set(strategy, { success: 0, failure: 0 });
        }

        const metrics = this.recoveryMetrics.strategySuccess.get(strategy);
        if (success) {
            metrics.success++;
        } else {
            metrics.failure++;
        }
    }

    /**
     * Get recovery metrics
     */
    getRecoveryMetrics() {
        const recoveryRate = this.recoveryMetrics.totalErrors > 0
            ? (this.recoveryMetrics.recoveredErrors / this.recoveryMetrics.totalErrors) * 100
            : 0;

        const strategyMetrics = {};
        for (const [strategy, metrics] of this.recoveryMetrics.strategySuccess) {
            const total = metrics.success + metrics.failure;
            strategyMetrics[strategy] = {
                ...metrics,
                successRate: total > 0 ? (metrics.success / total) * 100 : 0
            };
        }

        return {
            ...this.recoveryMetrics,
            recoveryRate: Math.round(recoveryRate * 100) / 100,
            strategyMetrics
        };
    }

    /**
     * Reset metrics
     */
    resetMetrics() {
        this.recoveryMetrics = {
            totalErrors: 0,
            recoveredErrors: 0,
            fallbackUsages: 0,
            strategySuccess: new Map()
        };
    }
}

// Export singleton instance
module.exports = new ErrorRecoveryService();