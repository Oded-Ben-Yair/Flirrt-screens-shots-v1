const Redis = require('ioredis');
const { logger } = require('./logger');

class RedisService {
    constructor() {
        this.redis = null;
        this.isConnected = false;
        this.connectionAttempts = 0;
        this.maxConnectionAttempts = 5;
        this.reconnectTimer = null;

        this.initializeConnection();
    }

    initializeConnection() {
        try {
            const redisConfig = {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD,
                db: process.env.REDIS_DB || 0,

                // Connection pool settings
                maxRetriesPerRequest: 3,
                retryDelayOnFailover: 100,
                enableOfflineQueue: false,
                lazyConnect: true,

                // Connection timeout
                connectTimeout: 10000,
                commandTimeout: 5000,

                // Reconnection settings
                maxRetriesPerRequest: 3,
                retryStrategy: (times) => {
                    if (times > this.maxConnectionAttempts) {
                        logger.error('Redis max connection attempts reached, giving up');
                        return null;
                    }

                    const delay = Math.min(times * 50, 2000);
                    logger.warn(`Redis reconnection attempt ${times} in ${delay}ms`);
                    return delay;
                }
            };

            this.redis = new Redis(redisConfig);

            // Event handlers
            this.redis.on('connect', () => {
                this.isConnected = true;
                this.connectionAttempts = 0;
                logger.info('Redis connected successfully');

                if (this.reconnectTimer) {
                    clearTimeout(this.reconnectTimer);
                    this.reconnectTimer = null;
                }
            });

            this.redis.on('ready', () => {
                logger.info('Redis ready to accept commands');
            });

            this.redis.on('error', (err) => {
                this.isConnected = false;
                logger.error('Redis connection error:', err.message);

                // Attempt to reconnect after a delay
                this.scheduleReconnect();
            });

            this.redis.on('close', () => {
                this.isConnected = false;
                logger.warn('Redis connection closed');

                this.scheduleReconnect();
            });

            this.redis.on('reconnecting', () => {
                logger.info('Redis reconnecting...');
            });

            // Test connection
            this.connect();

        } catch (error) {
            logger.error('Failed to initialize Redis connection:', error.message);
            this.scheduleReconnect();
        }
    }

    async connect() {
        try {
            await this.redis.connect();
            logger.info('Redis connection established');
        } catch (error) {
            logger.error('Failed to connect to Redis:', error.message);
            this.scheduleReconnect();
        }
    }

    scheduleReconnect() {
        if (this.reconnectTimer) return;

        this.connectionAttempts++;

        if (this.connectionAttempts > this.maxConnectionAttempts) {
            logger.error('Max Redis reconnection attempts exceeded, Redis disabled');
            return;
        }

        const delay = Math.min(this.connectionAttempts * 1000, 10000);

        this.reconnectTimer = setTimeout(() => {
            this.reconnectTimer = null;
            logger.info('Attempting Redis reconnection...');
            this.initializeConnection();
        }, delay);
    }

    // Cache operations with error handling
    async get(key, correlationId = null) {
        if (!this.isConnected || !this.redis) {
            logger.warn('Redis not available for GET operation', { key, correlationId });
            return null;
        }

        try {
            const value = await this.redis.get(key);

            if (value) {
                logger.debug('Cache hit', { key, correlationId });
                return JSON.parse(value);
            }

            logger.debug('Cache miss', { key, correlationId });
            return null;
        } catch (error) {
            logger.error('Redis GET error:', error.message, { key, correlationId });
            return null;
        }
    }

    async set(key, value, ttl = 3600, correlationId = null) {
        if (!this.isConnected || !this.redis) {
            logger.warn('Redis not available for SET operation', { key, ttl, correlationId });
            return false;
        }

        try {
            const serializedValue = JSON.stringify(value);

            if (ttl) {
                await this.redis.setex(key, ttl, serializedValue);
            } else {
                await this.redis.set(key, serializedValue);
            }

            logger.debug('Cache set', { key, ttl, correlationId });
            return true;
        } catch (error) {
            logger.error('Redis SET error:', error.message, { key, ttl, correlationId });
            return false;
        }
    }

    async del(key, correlationId = null) {
        if (!this.isConnected || !this.redis) {
            logger.warn('Redis not available for DEL operation', { key, correlationId });
            return false;
        }

        try {
            const result = await this.redis.del(key);
            logger.debug('Cache delete', { key, deleted: result > 0, correlationId });
            return result > 0;
        } catch (error) {
            logger.error('Redis DEL error:', error.message, { key, correlationId });
            return false;
        }
    }

    async exists(key, correlationId = null) {
        if (!this.isConnected || !this.redis) {
            return false;
        }

        try {
            const result = await this.redis.exists(key);
            return result === 1;
        } catch (error) {
            logger.error('Redis EXISTS error:', error.message, { key, correlationId });
            return false;
        }
    }

    async increment(key, amount = 1, correlationId = null) {
        if (!this.isConnected || !this.redis) {
            logger.warn('Redis not available for INCR operation', { key, amount, correlationId });
            return 0;
        }

        try {
            const result = await this.redis.incrby(key, amount);
            logger.debug('Cache increment', { key, amount, newValue: result, correlationId });
            return result;
        } catch (error) {
            logger.error('Redis INCR error:', error.message, { key, amount, correlationId });
            return 0;
        }
    }

    async setWithExpiry(key, value, expirySeconds, correlationId = null) {
        return this.set(key, value, expirySeconds, correlationId);
    }

    // Health check
    async healthCheck() {
        if (!this.isConnected || !this.redis) {
            return {
                status: 'disconnected',
                connected: false,
                error: 'Redis not connected'
            };
        }

        try {
            const start = Date.now();
            await this.redis.ping();
            const responseTime = Date.now() - start;

            return {
                status: 'connected',
                connected: true,
                responseTime: `${responseTime}ms`,
                connectionAttempts: this.connectionAttempts
            };
        } catch (error) {
            return {
                status: 'error',
                connected: false,
                error: error.message
            };
        }
    }

    // Graceful shutdown
    async disconnect() {
        if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
        }

        if (this.redis) {
            try {
                await this.redis.quit();
                logger.info('Redis disconnected gracefully');
            } catch (error) {
                logger.error('Error during Redis disconnect:', error.message);
                this.redis.disconnect();
            }
        }

        this.isConnected = false;
        this.redis = null;
    }

    // Get connection status
    getStatus() {
        return {
            connected: this.isConnected,
            connectionAttempts: this.connectionAttempts,
            maxConnectionAttempts: this.maxConnectionAttempts
        };
    }
}

// Export singleton instance
const redisService = new RedisService();

module.exports = redisService;