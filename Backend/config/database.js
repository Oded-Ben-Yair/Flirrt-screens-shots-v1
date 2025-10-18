/**
 * Database Configuration for Vibe8.ai Backend
 * Supports both local development (optional DB) and production (PostgreSQL on Render)
 */

const { Pool } = require('pg');

// Parse DATABASE_URL if provided (Render auto-provides this)
function parseDatabaseUrl(url) {
    if (!url) return null;

    try {
        const dbUrl = new URL(url);
        return {
            host: dbUrl.hostname,
            port: parseInt(dbUrl.port) || 5432,
            database: dbUrl.pathname.slice(1),
            user: dbUrl.username,
            password: dbUrl.password,
            ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
        };
    } catch (error) {
        console.error('Failed to parse DATABASE_URL:', error.message);
        return null;
    }
}

// Database configuration
const dbConfig = process.env.DATABASE_URL
    ? parseDatabaseUrl(process.env.DATABASE_URL)
    : {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT || 5432,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        ssl: false
    };

// Create connection pool (only if credentials exist)
let pool = null;
let isDatabaseEnabled = false;

if (dbConfig && dbConfig.host && dbConfig.database) {
    try {
        pool = new Pool({
            ...dbConfig,
            max: 20,
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 10000,
        });

        // Test connection
        pool.connect()
            .then(() => {
                isDatabaseEnabled = true;
                console.log('✅ PostgreSQL database connected successfully');
                console.log(`📊 Database: ${dbConfig.database} at ${dbConfig.host}:${dbConfig.port}`);
            })
            .catch(err => {
                console.warn('⚠️  Database connection failed - running without persistence:', err.message);
                console.warn('💡 API will work but user data won\'t be stored');
                pool = null;
                isDatabaseEnabled = false;
            });

    } catch (error) {
        console.warn('⚠️  Failed to create database pool:', error.message);
        console.warn('💡 Running in API-only mode (no data persistence)');
        pool = null;
        isDatabaseEnabled = false;
    }
} else {
    console.log('ℹ️  No database credentials found - running in API-only mode');
    console.log('💡 This is normal for MVP. Add DATABASE_URL to enable persistence.');
}

// Graceful shutdown
process.on('SIGTERM', async () => {
    if (pool) {
        await pool.end();
        console.log('Database pool closed');
    }
});

process.on('SIGINT', async () => {
    if (pool) {
        await pool.end();
        console.log('Database pool closed');
    }
});

module.exports = {
    pool,
    isDatabaseEnabled,

    // Helper to check if database is available
    isAvailable() {
        return isDatabaseEnabled && pool !== null;
    },

    // Safe query wrapper - returns null if database unavailable
    async query(...args) {
        if (!this.isAvailable()) {
            console.warn('Database query attempted but database is not available');
            return null;
        }

        try {
            return await pool.query(...args);
        } catch (error) {
            console.error('Database query error:', error.message);
            throw error;
        }
    }
};
