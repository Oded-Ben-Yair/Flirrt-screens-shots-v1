const { logger } = require('./logger');

class RedisService {
    constructor() {
        this.redis = null;
        this.isConnected = false;
        this.cache = new Map(); // In-memory fallback cache

        logger.warn('Redis service running in fallback mode - using in-memory cache');
    }

    // Cache operations with in-memory fallback
    async get(key, correlationId = null) {
        const value = this.cache.get(key);
        if (value && value.expiry > Date.now()) {
            logger.debug('In-memory cache hit', { key, correlationId });
            return value.data;
        }

        if (value) {
            this.cache.delete(key); // Remove expired entry
        }

        logger.debug('In-memory cache miss', { key, correlationId });
        return null;
    }

    async set(key, value, ttl = 3600, correlationId = null) {
        const expiry = ttl ? Date.now() + (ttl * 1000) : Date.now() + (3600 * 1000);
        this.cache.set(key, { data: value, expiry });

        logger.debug('In-memory cache set', { key, ttl, correlationId });
        return true;
    }

    async del(key, correlationId = null) {
        const deleted = this.cache.delete(key);
        logger.debug('In-memory cache delete', { key, deleted, correlationId });
        return deleted;
    }

    async exists(key, correlationId = null) {
        const value = this.cache.get(key);
        return value && value.expiry > Date.now();
    }

    async increment(key, amount = 1, correlationId = null) {
        const existing = await this.get(key);
        const newValue = (existing || 0) + amount;
        await this.set(key, newValue);
        logger.debug('In-memory cache increment', { key, amount, newValue, correlationId });
        return newValue;
    }

    async setWithExpiry(key, value, expirySeconds, correlationId = null) {
        return this.set(key, value, expirySeconds, correlationId);
    }

    // Health check
    async healthCheck() {
        return {
            status: 'fallback',
            connected: false,
            mode: 'in-memory',
            cacheSize: this.cache.size
        };
    }

    // Graceful shutdown
    async disconnect() {
        this.cache.clear();
        logger.info('In-memory cache cleared');
    }

    // Get connection status
    getStatus() {
        return {
            connected: false,
            mode: 'in-memory',
            cacheSize: this.cache.size
        };
    }

    // Periodic cleanup of expired entries
    cleanupExpired() {
        const now = Date.now();
        let removed = 0;

        for (const [key, value] of this.cache.entries()) {
            if (value.expiry <= now) {
                this.cache.delete(key);
                removed++;
            }
        }

        if (removed > 0) {
            logger.debug(`Cleaned up ${removed} expired cache entries`);
        }
    }
}

// Export singleton instance
const redisService = new RedisService();

// Run cleanup every minute
setInterval(() => {
    redisService.cleanupExpired();
}, 60000);

module.exports = redisService;