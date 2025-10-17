/**
 * Intelligent Cache Service - Context-Aware AI Response Caching
 *
 * Advanced caching system that understands content context and user patterns:
 * - Semantic similarity caching for related requests
 * - User behavior pattern recognition
 * - Quality-based cache priority and TTL
 * - Intelligent preemptive caching
 * - Multi-tier cache hierarchy
 * - Real-time cache optimization
 */

const crypto = require('crypto');
const { logger } = require('./logger');
const redisService = require('./redis');

class IntelligentCacheService {
    constructor() {
        this.cacheHierarchy = {
            // Ultra-fast cache for keyboard extensions
            keyboard: {
                ttl: 14400,        // 4 hours
                maxSize: 1000,     // Max entries
                qualityThreshold: 0.6,
                priority: 'high'
            },

            // Standard request cache
            standard: {
                ttl: 7200,         // 2 hours
                maxSize: 5000,     // Max entries
                qualityThreshold: 0.75,
                priority: 'medium'
            },

            // Complex analysis cache
            analysis: {
                ttl: 3600,         // 1 hour
                maxSize: 2000,     // Max entries
                qualityThreshold: 0.85,
                priority: 'high'
            },

            // Semantic similarity cache
            semantic: {
                ttl: 10800,        // 3 hours
                maxSize: 3000,     // Max entries
                qualityThreshold: 0.8,
                priority: 'medium',
                similarityThreshold: 0.8
            }
        };

        this.cacheMetrics = {
            totalRequests: 0,
            cacheHits: 0,
            cacheMisses: 0,
            semanticHits: 0,
            preemptiveHits: 0,
            qualityFiltered: 0,
            evictions: 0,
            avgResponseSize: 0,
            hitRateByTier: {}
        };

        // User behavior patterns
        this.userPatterns = new Map(); // userId -> pattern data

        // Semantic similarity configuration
        this.semanticConfig = {
            enabled: true,
            minSimilarity: 0.75,
            maxCandidates: 10,
            vectorDimensions: 128
        };

        this.initializeCache();
        this.setupMaintenanceTasks();

        logger.info('Intelligent Cache Service initialized', {
            tiers: Object.keys(this.cacheHierarchy),
            semanticEnabled: this.semanticConfig.enabled
        });
    }

    /**
     * Initialize cache structures
     */
    async initializeCache() {
        try {
            // Initialize cache tier metrics
            for (const tier of Object.keys(this.cacheHierarchy)) {
                this.cacheMetrics.hitRateByTier[tier] = {
                    requests: 0,
                    hits: 0,
                    hitRate: 0
                };

                // Ensure Redis keys exist
                await redisService.setnx(`cache:${tier}:size`, 0);
            }

            logger.debug('Cache structures initialized');
        } catch (error) {
            logger.error('Failed to initialize cache', { error: error.message });
        }
    }

    /**
     * Get cached response with intelligent matching
     * @param {string} cacheKey - Base cache key
     * @param {Object} request - Original request
     * @param {string} tier - Cache tier
     * @returns {Promise<Object|null>} Cached response or null
     */
    async getIntelligentCache(cacheKey, request, tier = 'standard') {
        this.cacheMetrics.totalRequests++;
        const tierConfig = this.cacheHierarchy[tier];

        try {
            // 1. Direct cache hit
            const directHit = await this.getDirectCache(cacheKey, tier);
            if (directHit) {
                this.recordCacheHit(tier, 'direct');
                logger.debug('Direct cache hit', { cacheKey, tier });
                return directHit;
            }

            // 2. Semantic similarity search (if enabled)
            if (this.semanticConfig.enabled && request.context) {
                const semanticHit = await this.getSemanticCache(request, tier);
                if (semanticHit) {
                    this.recordCacheHit(tier, 'semantic');
                    logger.debug('Semantic cache hit', {
                        cacheKey,
                        tier,
                        similarity: semanticHit.similarity
                    });
                    return semanticHit.data;
                }
            }

            // 3. Pattern-based preemptive cache
            if (request.userId) {
                const preemptiveHit = await this.getPreemptiveCache(request, tier);
                if (preemptiveHit) {
                    this.recordCacheHit(tier, 'preemptive');
                    logger.debug('Preemptive cache hit', { cacheKey, tier });
                    return preemptiveHit;
                }
            }

            // Cache miss
            this.cacheMetrics.cacheMisses++;
            this.cacheMetrics.hitRateByTier[tier].requests++;

            return null;

        } catch (error) {
            logger.error('Error during intelligent cache lookup', {
                cacheKey,
                tier,
                error: error.message
            });
            return null;
        }
    }

    /**
     * Get direct cache hit
     * @param {string} cacheKey - Cache key
     * @param {string} tier - Cache tier
     * @returns {Promise<Object|null>} Cached data
     */
    async getDirectCache(cacheKey, tier) {
        try {
            const fullKey = `cache:${tier}:${cacheKey}`;
            const cached = await redisService.get(fullKey);

            if (cached && this.validateCacheQuality(cached, tier)) {
                // Update access time for LRU
                await redisService.set(`${fullKey}:accessed`, Date.now(), 300);
                return cached;
            }

            return null;
        } catch (error) {
            logger.warn('Error getting direct cache', { error: error.message });
            return null;
        }
    }

    /**
     * Get semantically similar cached response
     * @param {Object} request - Request object
     * @param {string} tier - Cache tier
     * @returns {Promise<Object|null>} Similar cached response
     */
    async getSemanticCache(request, tier) {
        try {
            const requestVector = await this.generateSemanticVector(request);
            const candidates = await this.findSemanticCandidates(tier, this.semanticConfig.maxCandidates);

            let bestMatch = null;
            let bestSimilarity = 0;

            for (const candidate of candidates) {
                const similarity = this.calculateCosineSimilarity(requestVector, candidate.vector);

                if (similarity > bestSimilarity &&
                    similarity >= this.semanticConfig.minSimilarity) {
                    bestMatch = candidate;
                    bestSimilarity = similarity;
                }
            }

            if (bestMatch) {
                return {
                    data: bestMatch.data,
                    similarity: bestSimilarity,
                    originalKey: bestMatch.key
                };
            }

            return null;

        } catch (error) {
            logger.warn('Error in semantic cache lookup', { error: error.message });
            return null;
        }
    }

    /**
     * Get preemptive cache based on user patterns
     * @param {Object} request - Request object
     * @param {string} tier - Cache tier
     * @returns {Promise<Object|null>} Preemptive cached response
     */
    async getPreemptiveCache(request, tier) {
        try {
            const userPattern = this.userPatterns.get(request.userId);
            if (!userPattern || userPattern.requests < 5) {
                return null; // Need more data for patterns
            }

            // Look for similar patterns in user's history
            const patternKey = this.generatePatternKey(request, userPattern);
            const preemptiveKey = `cache:preemptive:${tier}:${patternKey}`;

            const cached = await redisService.get(preemptiveKey);
            if (cached && this.validateCacheQuality(cached, tier)) {
                return cached;
            }

            return null;

        } catch (error) {
            logger.warn('Error in preemptive cache lookup', { error: error.message });
            return null;
        }
    }

    /**
     * Store response in intelligent cache with multiple indexing
     * @param {string} cacheKey - Base cache key
     * @param {Object} request - Original request
     * @param {Object} response - Response to cache
     * @param {string} tier - Cache tier
     * @param {Object} options - Caching options
     * @returns {Promise<boolean>} Success status
     */
    async setIntelligentCache(cacheKey, request, response, tier = 'standard', options = {}) {
        const tierConfig = this.cacheHierarchy[tier];

        try {
            // Quality check
            if (!this.validateResponseQuality(response, tierConfig.qualityThreshold)) {
                this.cacheMetrics.qualityFiltered++;
                logger.debug('Response filtered by quality threshold', {
                    cacheKey,
                    tier,
                    quality: response.qualityScore || 0,
                    threshold: tierConfig.qualityThreshold
                });
                return false;
            }

            // Check cache size limits
            const currentSize = await redisService.get(`cache:${tier}:size`) || 0;
            if (currentSize >= tierConfig.maxSize) {
                await this.evictLeastUsed(tier, Math.floor(tierConfig.maxSize * 0.1)); // Evict 10%
            }

            const cacheData = {
                ...response,
                cached: true,
                cachedAt: new Date().toISOString(),
                tier,
                cacheKey,
                accessCount: 0,
                lastAccessed: new Date().toISOString(),
                requestHash: this.hashRequest(request)
            };

            const ttl = this.calculateDynamicTTL(response, tierConfig, options);
            const fullKey = `cache:${tier}:${cacheKey}`;

            // 1. Store primary cache entry
            await redisService.set(fullKey, cacheData, ttl);

            // 2. Store semantic index (if enabled)
            if (this.semanticConfig.enabled && request.context) {
                await this.indexSemanticCache(cacheKey, request, cacheData, tier);
            }

            // 3. Store pattern-based index
            if (request.userId) {
                await this.indexPatternCache(cacheKey, request, cacheData, tier);
                this.updateUserPattern(request.userId, request);
            }

            // 4. Update cache size
            await redisService.incr(`cache:${tier}:size`);

            // 5. Update metrics
            this.cacheMetrics.avgResponseSize =
                (this.cacheMetrics.avgResponseSize * 0.9) +
                (JSON.stringify(response).length * 0.1);

            logger.info('Response cached with intelligent indexing', {
                cacheKey,
                tier,
                quality: response.qualityScore || 0,
                ttl,
                size: JSON.stringify(cacheData).length
            });

            return true;

        } catch (error) {
            logger.error('Failed to set intelligent cache', {
                cacheKey,
                tier,
                error: error.message
            });
            return false;
        }
    }

    /**
     * Generate semantic vector for content
     * @param {Object} request - Request object
     * @returns {Promise<Array>} Semantic vector
     */
    async generateSemanticVector(request) {
        try {
            // Simple semantic vector generation using text analysis
            // In production, you might use a proper embedding service
            const text = (request.context || '') + ' ' + (request.suggestion_type || '') + ' ' + (request.tone || '');
            const words = text.toLowerCase().split(/\s+/).filter(w => w.length > 2);

            // Create a simple bag-of-words vector with position weighting
            const vector = new Array(this.semanticConfig.vectorDimensions).fill(0);

            words.forEach((word, index) => {
                const hash = this.simpleHash(word);
                const position = hash % this.semanticConfig.vectorDimensions;
                const weight = Math.max(0.1, 1.0 - (index * 0.01)); // Decay weight by position
                vector[position] += weight;
            });

            // Normalize vector
            const magnitude = Math.sqrt(vector.reduce((sum, val) => sum + val * val, 0));
            return magnitude > 0 ? vector.map(val => val / magnitude) : vector;

        } catch (error) {
            logger.warn('Error generating semantic vector', { error: error.message });
            return new Array(this.semanticConfig.vectorDimensions).fill(0);
        }
    }

    /**
     * Simple hash function for words
     * @param {string} str - String to hash
     * @returns {number} Hash value
     */
    simpleHash(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return Math.abs(hash);
    }

    /**
     * Calculate cosine similarity between vectors
     * @param {Array} vectorA - First vector
     * @param {Array} vectorB - Second vector
     * @returns {number} Similarity score (0-1)
     */
    calculateCosineSimilarity(vectorA, vectorB) {
        try {
            if (vectorA.length !== vectorB.length) return 0;

            let dotProduct = 0;
            let magnitudeA = 0;
            let magnitudeB = 0;

            for (let i = 0; i < vectorA.length; i++) {
                dotProduct += vectorA[i] * vectorB[i];
                magnitudeA += vectorA[i] * vectorA[i];
                magnitudeB += vectorB[i] * vectorB[i];
            }

            magnitudeA = Math.sqrt(magnitudeA);
            magnitudeB = Math.sqrt(magnitudeB);

            if (magnitudeA === 0 || magnitudeB === 0) return 0;

            return dotProduct / (magnitudeA * magnitudeB);

        } catch (error) {
            logger.warn('Error calculating cosine similarity', { error: error.message });
            return 0;
        }
    }

    /**
     * Find semantic cache candidates
     * @param {string} tier - Cache tier
     * @param {number} maxCandidates - Maximum candidates to return
     * @returns {Promise<Array>} Array of candidates with vectors
     */
    async findSemanticCandidates(tier, maxCandidates) {
        try {
            const semanticKeys = await redisService.keys(`semantic:${tier}:*`);
            const candidates = [];

            for (const key of semanticKeys.slice(0, maxCandidates * 2)) {
                const semanticData = await redisService.get(key);
                if (semanticData && semanticData.vector && semanticData.data) {
                    candidates.push(semanticData);
                }
            }

            return candidates.slice(0, maxCandidates);

        } catch (error) {
            logger.warn('Error finding semantic candidates', { error: error.message });
            return [];
        }
    }

    /**
     * Index cache entry for semantic search
     * @param {string} cacheKey - Cache key
     * @param {Object} request - Original request
     * @param {Object} cacheData - Cache data
     * @param {string} tier - Cache tier
     */
    async indexSemanticCache(cacheKey, request, cacheData, tier) {
        try {
            const vector = await this.generateSemanticVector(request);
            const semanticKey = `semantic:${tier}:${cacheKey}`;

            const semanticIndex = {
                key: cacheKey,
                vector,
                data: cacheData,
                requestHash: this.hashRequest(request),
                createdAt: new Date().toISOString()
            };

            const ttl = this.cacheHierarchy[tier].ttl;
            await redisService.set(semanticKey, semanticIndex, ttl);

            logger.debug('Semantic index created', { cacheKey, tier });

        } catch (error) {
            logger.warn('Error indexing semantic cache', { error: error.message });
        }
    }

    /**
     * Index cache entry for pattern matching
     * @param {string} cacheKey - Cache key
     * @param {Object} request - Original request
     * @param {Object} cacheData - Cache data
     * @param {string} tier - Cache tier
     */
    async indexPatternCache(cacheKey, request, cacheData, tier) {
        try {
            const userPattern = this.userPatterns.get(request.userId);
            if (!userPattern) return;

            const patternKey = this.generatePatternKey(request, userPattern);
            const preemptiveKey = `cache:preemptive:${tier}:${patternKey}`;

            const ttl = this.cacheHierarchy[tier].ttl * 1.5; // Longer TTL for preemptive cache
            await redisService.set(preemptiveKey, cacheData, ttl);

            logger.debug('Pattern index created', { cacheKey, tier, patternKey });

        } catch (error) {
            logger.warn('Error indexing pattern cache', { error: error.message });
        }
    }

    /**
     * Update user behavior pattern
     * @param {string} userId - User ID
     * @param {Object} request - Request object
     */
    updateUserPattern(userId, request) {
        try {
            let pattern = this.userPatterns.get(userId) || {
                requests: 0,
                tones: {},
                topics: {},
                times: [],
                contexts: [],
                lastUpdated: Date.now()
            };

            pattern.requests++;

            // Track tone preferences
            if (request.tone) {
                pattern.tones[request.tone] = (pattern.tones[request.tone] || 0) + 1;
            }

            // Track topic preferences
            if (request.suggestion_type) {
                pattern.topics[request.suggestion_type] = (pattern.topics[request.suggestion_type] || 0) + 1;
            }

            // Track timing patterns
            pattern.times.push(new Date().getHours());
            if (pattern.times.length > 100) {
                pattern.times.shift(); // Keep last 100 requests
            }

            // Track context patterns (simplified)
            if (request.context) {
                const contextHash = this.simpleHash(request.context.substring(0, 100));
                pattern.contexts.push(contextHash);
                if (pattern.contexts.length > 50) {
                    pattern.contexts.shift();
                }
            }

            pattern.lastUpdated = Date.now();
            this.userPatterns.set(userId, pattern);

            logger.debug('User pattern updated', {
                userId,
                totalRequests: pattern.requests
            });

        } catch (error) {
            logger.warn('Error updating user pattern', { error: error.message });
        }
    }

    /**
     * Generate pattern key based on user behavior
     * @param {Object} request - Request object
     * @param {Object} userPattern - User pattern data
     * @returns {string} Pattern key
     */
    generatePatternKey(request, userPattern) {
        try {
            // Find most frequent tone and topic
            const topTone = Object.entries(userPattern.tones)
                .sort(([,a], [,b]) => b - a)[0]?.[0] || 'default';

            const topTopic = Object.entries(userPattern.topics)
                .sort(([,a], [,b]) => b - a)[0]?.[0] || 'default';

            // Current hour for time-based patterns
            const currentHour = new Date().getHours();
            const hourBucket = Math.floor(currentHour / 4) * 4; // 4-hour buckets

            return crypto.createHash('md5')
                .update(`${request.userId}:${topTone}:${topTopic}:${hourBucket}`)
                .digest('hex');

        } catch (error) {
            logger.warn('Error generating pattern key', { error: error.message });
            return crypto.createHash('md5')
                .update(`${request.userId}:default`)
                .digest('hex');
        }
    }

    /**
     * Calculate dynamic TTL based on response quality and usage
     * @param {Object} response - Response object
     * @param {Object} tierConfig - Tier configuration
     * @param {Object} options - Caching options
     * @returns {number} TTL in seconds
     */
    calculateDynamicTTL(response, tierConfig, options) {
        let baseTTL = tierConfig.ttl;

        // Higher quality responses get longer TTL
        if (response.qualityScore) {
            const qualityMultiplier = Math.min(2.0, response.qualityScore / 0.5);
            baseTTL = Math.round(baseTTL * qualityMultiplier);
        }

        // Adjust based on response confidence
        const avgConfidence = response.suggestions?.reduce((sum, s) =>
            sum + (s.confidence || 0), 0) / (response.suggestions?.length || 1);

        if (avgConfidence > 0.9) {
            baseTTL = Math.round(baseTTL * 1.3);
        } else if (avgConfidence < 0.7) {
            baseTTL = Math.round(baseTTL * 0.8);
        }

        // Apply options
        if (options.extendedTTL) {
            baseTTL = Math.round(baseTTL * 1.5);
        }

        return Math.max(300, Math.min(baseTTL, 86400)); // 5 minutes to 24 hours
    }

    /**
     * Validate cache quality
     * @param {Object} cached - Cached data
     * @param {string} tier - Cache tier
     * @returns {boolean} Is valid
     */
    validateCacheQuality(cached, tier) {
        const tierConfig = this.cacheHierarchy[tier];

        // Check quality score
        if (cached.qualityScore && cached.qualityScore < tierConfig.qualityThreshold) {
            return false;
        }

        // Check age
        if (cached.cachedAt) {
            const age = Date.now() - new Date(cached.cachedAt).getTime();
            if (age > tierConfig.ttl * 1000) {
                return false;
            }
        }

        return true;
    }

    /**
     * Validate response quality for caching
     * @param {Object} response - Response object
     * @param {number} threshold - Quality threshold
     * @returns {boolean} Meets quality threshold
     */
    validateResponseQuality(response, threshold) {
        if (!response.qualityScore) {
            return response.suggestions && response.suggestions.length > 0;
        }
        return response.qualityScore >= threshold;
    }

    /**
     * Hash request for deduplication
     * @param {Object} request - Request object
     * @returns {string} Request hash
     */
    hashRequest(request) {
        const hashData = {
            context: request.context || '',
            tone: request.tone || '',
            suggestion_type: request.suggestion_type || '',
            userId: request.userId || '',
            imageHash: request.imageHash || ''
        };

        return crypto.createHash('md5')
            .update(JSON.stringify(hashData))
            .digest('hex');
    }

    /**
     * Evict least recently used cache entries
     * @param {string} tier - Cache tier
     * @param {number} count - Number of entries to evict
     */
    async evictLeastUsed(tier, count) {
        try {
            // Get all cache keys for tier
            const pattern = `cache:${tier}:*`;
            const keys = await redisService.keys(pattern);

            const accessData = [];

            // Get access times
            for (const key of keys) {
                if (key.includes(':accessed')) continue;

                const accessKey = `${key}:accessed`;
                const accessTime = await redisService.get(accessKey) || 0;
                accessData.push({ key, accessTime });
            }

            // Sort by access time (oldest first)
            accessData.sort((a, b) => a.accessTime - b.accessTime);

            // Evict oldest entries
            for (let i = 0; i < Math.min(count, accessData.length); i++) {
                await redisService.del(accessData[i].key);
                await redisService.del(`${accessData[i].key}:accessed`);
                await redisService.decr(`cache:${tier}:size`);
                this.cacheMetrics.evictions++;
            }

            logger.info('Cache eviction completed', {
                tier,
                evicted: Math.min(count, accessData.length)
            });

        } catch (error) {
            logger.error('Error during cache eviction', {
                tier,
                error: error.message
            });
        }
    }

    /**
     * Record cache hit metrics
     * @param {string} tier - Cache tier
     * @param {string} type - Hit type (direct, semantic, preemptive)
     */
    recordCacheHit(tier, type) {
        this.cacheMetrics.cacheHits++;
        this.cacheMetrics.hitRateByTier[tier].requests++;
        this.cacheMetrics.hitRateByTier[tier].hits++;
        this.cacheMetrics.hitRateByTier[tier].hitRate =
            this.cacheMetrics.hitRateByTier[tier].hits /
            this.cacheMetrics.hitRateByTier[tier].requests;

        if (type === 'semantic') {
            this.cacheMetrics.semanticHits++;
        } else if (type === 'preemptive') {
            this.cacheMetrics.preemptiveHits++;
        }
    }

    /**
     * Setup maintenance tasks
     */
    setupMaintenanceTasks() {
        // Cache cleanup every 30 minutes
        setInterval(async () => {
            await this.performCacheMaintenance();
        }, 30 * 60 * 1000);

        // User pattern cleanup every 6 hours
        setInterval(() => {
            this.cleanupUserPatterns();
        }, 6 * 60 * 60 * 1000);

        logger.debug('Cache maintenance tasks scheduled');
    }

    /**
     * Perform cache maintenance
     */
    async performCacheMaintenance() {
        try {
            logger.info('Starting cache maintenance');

            for (const tier of Object.keys(this.cacheHierarchy)) {
                // Clean expired semantic indices
                const semanticKeys = await redisService.keys(`semantic:${tier}:*`);
                let cleanedSemantic = 0;

                for (const key of semanticKeys) {
                    const data = await redisService.get(key);
                    if (!data || !data.createdAt) {
                        await redisService.del(key);
                        cleanedSemantic++;
                        continue;
                    }

                    const age = Date.now() - new Date(data.createdAt).getTime();
                    if (age > this.cacheHierarchy[tier].ttl * 1000) {
                        await redisService.del(key);
                        cleanedSemantic++;
                    }
                }

                logger.debug('Cache maintenance completed for tier', {
                    tier,
                    cleanedSemantic
                });
            }

            logger.info('Cache maintenance completed');

        } catch (error) {
            logger.error('Error during cache maintenance', { error: error.message });
        }
    }

    /**
     * Cleanup old user patterns
     */
    cleanupUserPatterns() {
        try {
            const cutoffTime = Date.now() - (24 * 60 * 60 * 1000); // 24 hours
            let cleanedCount = 0;

            for (const [userId, pattern] of this.userPatterns.entries()) {
                if (pattern.lastUpdated < cutoffTime && pattern.requests < 5) {
                    this.userPatterns.delete(userId);
                    cleanedCount++;
                }
            }

            logger.debug('User pattern cleanup completed', {
                cleaned: cleanedCount,
                remaining: this.userPatterns.size
            });

        } catch (error) {
            logger.warn('Error during user pattern cleanup', { error: error.message });
        }
    }

    /**
     * Get cache statistics and insights
     * @returns {Object} Cache insights
     */
    getCacheInsights() {
        const totalRequests = this.cacheMetrics.totalRequests;
        const overallHitRate = totalRequests > 0 ?
            (this.cacheMetrics.cacheHits / totalRequests) * 100 : 0;

        return {
            performance: {
                overallHitRate: Math.round(overallHitRate * 100) / 100,
                semanticHitRate: totalRequests > 0 ?
                    (this.cacheMetrics.semanticHits / totalRequests) * 100 : 0,
                preemptiveHitRate: totalRequests > 0 ?
                    (this.cacheMetrics.preemptiveHits / totalRequests) * 100 : 0
            },
            activity: {
                totalRequests: this.cacheMetrics.totalRequests,
                cacheHits: this.cacheMetrics.cacheHits,
                cacheMisses: this.cacheMetrics.cacheMisses,
                qualityFiltered: this.cacheMetrics.qualityFiltered,
                evictions: this.cacheMetrics.evictions
            },
            efficiency: {
                avgResponseSize: Math.round(this.cacheMetrics.avgResponseSize),
                userPatterns: this.userPatterns.size,
                tierHitRates: { ...this.cacheMetrics.hitRateByTier }
            },
            configuration: {
                tiers: Object.keys(this.cacheHierarchy).length,
                semanticEnabled: this.semanticConfig.enabled,
                maxSizeByTier: Object.fromEntries(
                    Object.entries(this.cacheHierarchy).map(([tier, config]) =>
                        [tier, config.maxSize]
                    )
                )
            }
        };
    }

    /**
     * Get health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        const insights = this.getCacheInsights();

        return {
            status: 'operational',
            hitRate: insights.performance.overallHitRate,
            activePatterns: this.userPatterns.size,
            tiers: Object.keys(this.cacheHierarchy),
            health: insights.performance.overallHitRate > 30 ? 'good' :
                    insights.performance.overallHitRate > 15 ? 'fair' : 'poor'
        };
    }
}

// Export singleton instance
const intelligentCacheService = new IntelligentCacheService();
module.exports = intelligentCacheService;