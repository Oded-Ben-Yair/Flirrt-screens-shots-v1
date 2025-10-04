/**
 * Centralized Timeout Configuration
 *
 * All timeout values, TTLs, delays, and intervals used across the Backend.
 * Values are in milliseconds unless otherwise noted.
 *
 * Last Updated: 2025-10-04
 * Issue: #8 - Consolidate scattered timeout values
 */

module.exports = {
    // ============================================================
    // API REQUEST TIMEOUTS (milliseconds)
    // ============================================================
    api: {
        // Grok API
        grokStandard: 35000,              // 35s - Standard Grok API requests
        grokAxios: 30000,                 // 30s - Axios timeout (slightly less than circuit breaker)

        // Grok-4 Fast Models
        grok4Reasoning: 8000,             // 8s - Reasoning model (target <2s)
        grok4ReasoningStreaming: 15000,   // 15s - Reasoning with streaming
        grok4NonReasoning: 3000,          // 3s - Non-reasoning model (target <1s)
        grok4Complex: 8000,               // 8s - Complex tasks
        grok4Simple: 3000,                // 3s - Simple tasks

        // ElevenLabs Voice API
        elevenlabsSynthesize: 60000,      // 60s - Voice synthesis
        elevenlabsAxios: 55000,           // 55s - Axios timeout (slightly less than circuit breaker)
        elevenlabsClone: 55000,           // 55s - Voice cloning

        // Gemini Vision API
        geminiVision: 45000,              // 45s - Image analysis
        geminiVisionFlirts: 45000,        // 45s - Vision processing in flirts route
        geminiAxios: 45000,               // 45s - Axios timeout

        // Generic/Default
        defaultRequest: 15000,            // 15s - Default API request timeout
        analysisRequest: 30000,           // 30s - Analysis endpoint
        voiceRequest: 30000,              // 30s - Voice endpoint
        streamingRequest: 15000,          // 15s - Streaming analysis default
    },

    // ============================================================
    // CIRCUIT BREAKER TIMEOUTS (milliseconds)
    // ============================================================
    circuitBreaker: {
        // Request timeouts
        grokTimeout: 35000,               // 35s - Grok circuit breaker
        grok4ReasoningTimeout: 8000,      // 8s - Grok-4 reasoning
        grok4NonReasoningTimeout: 3000,   // 3s - Grok-4 non-reasoning
        elevenlabsTimeout: 60000,         // 60s - ElevenLabs
        geminiTimeout: 45000,             // 45s - Gemini vision

        // Reset timeouts (time before retry after circuit opens)
        grokResetTimeout: 60000,          // 60s - Try again after 60 seconds
        grok4ReasoningResetTimeout: 30000,    // 30s - Try again after 30 seconds
        grok4NonReasoningResetTimeout: 15000, // 15s - Try again after 15 seconds
        elevenlabsResetTimeout: 120000,   // 120s - Try again after 2 minutes
        geminiResetTimeout: 90000,        // 90s - Try again after 90 seconds

        // Rolling window timeouts
        rollingCountTimeout: 60000,       // 60s - Standard rolling window
        rollingCountTimeoutShort: 30000,  // 30s - Short rolling window
        rollingCountTimeoutLong: 90000,   // 90s - Long rolling window (Gemini)
        rollingCountTimeoutVoice: 120000, // 120s - Voice synthesis rolling window
    },

    // ============================================================
    // RETRY & BACKOFF DELAYS (milliseconds)
    // ============================================================
    retry: {
        // Base delays for exponential backoff
        apiTimeoutInitial: 1000,          // 1s - Initial delay for API timeout recovery
        apiTimeoutBackoffMultiplier: 2,   // 2x - Exponential multiplier

        rateLimitInitial: 5000,           // 5s - Initial delay for rate limit
        rateLimitBackoffMultiplier: 3,    // 3x - Exponential multiplier

        networkErrorInitial: 2000,        // 2s - Initial delay for network errors
        networkErrorBackoffMultiplier: 2, // 2x - Exponential multiplier

        // Redis failover
        redisRetryDelay: 100,             // 100ms - Redis retry delay on failover

        // Maximum retry attempts (from errorRecovery.js)
        maxRetriesApiTimeout: 3,
        maxRetriesRateLimit: 2,
        maxRetriesNetworkError: 2,
        maxRetriesJsonParse: 1,
    },

    // ============================================================
    // CACHE TTLs (seconds)
    // ============================================================
    cache: {
        // Intelligent Cache Service tiers
        keyboard: 14400,                  // 4 hours - Ultra-fast keyboard extension cache
        standard: 7200,                   // 2 hours - Standard request cache
        flirtSuggestions: 300,            // 5 minutes - Flirt suggestions cache
        analysis: 3600,                   // 1 hour - Complex analysis cache
        semantic: 10800,                  // 3 hours - Semantic similarity cache

        // Performance optimizer cache
        performanceOptimizer: 3600,       // 1 hour - Base TTL for performance cache

        // A/B testing assignments
        abTestAssignment: 2592000,        // 30 days - User variant assignments
        abTestEvents: 2592000,            // 30 days - Test event tracking

        // Performance metrics
        realtimeMetrics: 60,              // 1 minute - Real-time metrics
        metricsSnapshot: 86400,           // 24 hours - Metrics snapshots
        performanceMonitoring: 86400,     // 24 hours - Performance monitoring data

        // Session/temporary caches
        cacheAccess: 300,                 // 5 minutes - Cache access tracking

        // TTL bounds
        minTTL: 300,                      // 5 minutes - Minimum TTL
        maxTTL: 86400,                    // 24 hours - Maximum TTL

        // Preemptive cache (extended TTL)
        preemptiveMultiplier: 1.5,        // 1.5x - Multiplier for preemptive cache

        // Quality-based TTL adjustments
        highQualityMultiplier: 1.3,       // 1.3x - Longer TTL for high quality
        lowQualityMultiplier: 0.8,        // 0.8x - Shorter TTL for low quality
    },

    // ============================================================
    // UPLOAD & PROCESSING TIMEOUTS (milliseconds)
    // ============================================================
    upload: {
        // Upload queue timeouts by priority
        urgent: 2000,                     // 2s - Urgent priority uploads
        high: 5000,                       // 5s - High priority uploads
        normal: 10000,                    // 10s - Normal priority uploads
        low: 30000,                       // 30s - Low priority uploads/background

        // Screenshot upload
        screenshotUpload: 60000,          // 60s - Screenshot upload timeout
    },

    // ============================================================
    // STREAMING & DELIVERY DELAYS (milliseconds)
    // ============================================================
    streaming: {
        // Chunk delivery delays
        minChunkDelay: 50,                // 50ms - Minimum delay between chunks
        maxChunkDelay: 200,               // 200ms - Maximum delay between chunks

        // Batch delays
        batchDelayMin: 50,                // 50ms - Minimum batch delay
        batchDelayMax: 200,               // 200ms - Maximum batch delay

        // Service delays
        streamingServiceDelay200: 200,    // 200ms - Various streaming service delays
        streamingServiceDelay300: 300,    // 300ms
        streamingServiceDelay500: 500,    // 500ms

        // Polling intervals
        pollInterval: 500,                // 500ms - Status polling interval
        pollIntervalTest: 1000,           // 1s - Test polling interval

        // Stream timeout
        streamTimeout: 30000,             // 30s - Stream timeout

        // Cleanup intervals
        cleanupInterval: 60000,           // 60s - Stream cleanup interval (assumed)
    },

    // ============================================================
    // DATABASE TIMEOUTS (milliseconds)
    // ============================================================
    database: {
        queryTimeout: 5000,               // 5s - Database query timeout
        connectionTimeout: 10000,         // 10s - Database connection timeout
    },

    // ============================================================
    // TEST TIMEOUTS (milliseconds)
    // ============================================================
    test: {
        jestGlobal: 30000,                // 30s - Jest global timeout
        endpointTest: 45000,              // 45s - Endpoint test timeout
        performanceTest: 30000,           // 30s - Performance test timeout
        visionApiTest: 60000,             // 60s - Vision API test timeout
        streamingTest: 15000,             // 15s - Streaming test timeout
        dualModelTest: 30000,             // 30s - Dual model test timeout
        voiceIntegrationTest: 30000,      // 30s - Voice integration test timeout

        // Test wait times
        testWait100: 100,                 // 100ms - Short test wait
        testWait200: 200,                 // 200ms - Medium test wait
        testWait1000: 1000,               // 1s - Standard test wait
        testWait5000: 5000,               // 5s - Long test wait
        testWait10000: 10000,             // 10s - Extra long test wait
    },

    // ============================================================
    // HEALTH CHECK & MONITORING INTERVALS (milliseconds)
    // ============================================================
    monitoring: {
        healthCheckInterval: 30000,       // 30s - Health check interval
        metricsReportInterval: 60000,     // 60s - Metrics reporting interval
        heartbeatInterval: 30000,         // 30s - WebSocket heartbeat
        connectionTimeout: 120000,        // 120s - Connection idle timeout
    },

    // ============================================================
    // SESSION & AUTHENTICATION (milliseconds)
    // ============================================================
    session: {
        maxAge: 86400000,                 // 24 hours - Session max age (in ms, not seconds)
        cookieMaxAge: 86400,              // 24 hours - Cookie max age (in seconds)
    },

    // ============================================================
    // WEBSOCKET TIMEOUTS (milliseconds)
    // ============================================================
    websocket: {
        heartbeatInterval: 30000,         // 30s - Heartbeat ping interval
        connectionIdleTimeout: 120000,    // 120s - Idle connection timeout
        messageTimeout: 10000,            // 10s - Message delivery timeout
    },

    // ============================================================
    // AI ORCHESTRATOR TIMEOUTS (milliseconds)
    // ============================================================
    orchestrator: {
        fastStrategy: 15000,              // 15s - Fast strategy timeout
        standardStrategy: 25000,          // 25s - Standard strategy timeout
    },

    // ============================================================
    // PERFORMANCE TARGETS (milliseconds)
    // ============================================================
    targets: {
        // Grok-4 Fast performance tiers
        tier1: 1000,                      // <1s - Ultra-fast responses
        tier2: 3000,                      // <3s - Fast responses
        tier3: 5000,                      // <5s - Standard responses

        // Overall targets
        keyboardExtension: 2000,          // <2s - Keyboard extension target
        streamingAnalysis: 12000,         // <12s - Complete streaming analysis
    },

    // ============================================================
    // QUEUE & WORKER LIMITS
    // ============================================================
    queue: {
        maxConcurrentWorkers: 5,          // Max concurrent upload workers
        maxQueueSize: 100,                // Max items per priority queue
    },

    // ============================================================
    // FILE & UPLOAD LIMITS
    // ============================================================
    limits: {
        maxFileSize: 5242880,             // 5MB - Maximum file size (5 * 1024 * 1024)
        maxImageSize: 1920,               // 1920px - Max image width/height
        compressionQuality: 80,           // 80% - JPEG compression quality
    },

    // ============================================================
    // HELPER FUNCTIONS
    // ============================================================

    /**
     * Get timeout for a specific API service
     * @param {string} service - Service name (grok, elevenlabs, gemini, etc.)
     * @returns {number} Timeout in milliseconds
     */
    getApiTimeout(service) {
        const timeouts = {
            'grok': this.api.grokStandard,
            'grok4-reasoning': this.api.grok4Reasoning,
            'grok4-non-reasoning': this.api.grok4NonReasoning,
            'elevenlabs': this.api.elevenlabsSynthesize,
            'gemini': this.api.geminiVision,
            'default': this.api.defaultRequest
        };
        return timeouts[service] || timeouts.default;
    },

    /**
     * Get circuit breaker timeout for a service
     * @param {string} service - Service name
     * @returns {number} Timeout in milliseconds
     */
    getCircuitBreakerTimeout(service) {
        const timeouts = {
            'grok': this.circuitBreaker.grokTimeout,
            'grok4-reasoning': this.circuitBreaker.grok4ReasoningTimeout,
            'grok4-non-reasoning': this.circuitBreaker.grok4NonReasoningTimeout,
            'elevenlabs': this.circuitBreaker.elevenlabsTimeout,
            'gemini': this.circuitBreaker.geminiTimeout
        };
        return timeouts[service];
    },

    /**
     * Get cache TTL for a tier
     * @param {string} tier - Cache tier (keyboard, standard, analysis, semantic)
     * @returns {number} TTL in seconds
     */
    getCacheTTL(tier) {
        return this.cache[tier] || this.cache.standard;
    },

    /**
     * Get upload timeout by priority
     * @param {string} priority - Priority level (urgent, high, normal, low)
     * @returns {number} Timeout in milliseconds
     */
    getUploadTimeout(priority) {
        return this.upload[priority] || this.upload.normal;
    },

    /**
     * Calculate exponential backoff delay
     * @param {number} attempt - Retry attempt number (0-based)
     * @param {number} baseDelay - Base delay in milliseconds
     * @param {number} multiplier - Backoff multiplier
     * @param {number} maxDelay - Maximum delay (optional)
     * @returns {number} Delay in milliseconds
     */
    calculateBackoff(attempt, baseDelay, multiplier, maxDelay = 30000) {
        const delay = baseDelay * Math.pow(multiplier, attempt);
        return Math.min(delay, maxDelay);
    },

    /**
     * Add jitter to a delay value
     * @param {number} delay - Base delay in milliseconds
     * @param {number} jitterPercent - Jitter percentage (0-1)
     * @returns {number} Delay with jitter
     */
    addJitter(delay, jitterPercent = 0.2) {
        const jitter = delay * jitterPercent * Math.random();
        return Math.round(delay + jitter);
    }
};
