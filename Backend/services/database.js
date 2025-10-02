const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const { logger } = require('./logger');

class DatabaseService {
    constructor() {
        this.db = null;
        this.isConnected = false;
        this.dbPath = path.join(__dirname, '..', 'data', 'flirrt.db');
        this.init();
    }

    init() {
        try {
            // Ensure data directory exists
            const dataDir = path.dirname(this.dbPath);
            if (!fs.existsSync(dataDir)) {
                fs.mkdirSync(dataDir, { recursive: true });
            }

            // Initialize database connection
            this.db = new Database(this.dbPath, {
                verbose: process.env.NODE_ENV === 'development' ? console.log : null,
                fileMustExist: false
            });

            // Enable WAL mode for better performance
            this.db.exec('PRAGMA journal_mode = WAL');
            this.db.exec('PRAGMA synchronous = NORMAL');
            this.db.exec('PRAGMA cache_size = 1000');
            this.db.exec('PRAGMA foreign_keys = ON');

            this.isConnected = true;
            logger.info('Database connection established', { dbPath: this.dbPath });

            // Initialize tables
            this.initializeTables();

        } catch (error) {
            logger.error('Failed to initialize database', { error: error.message });
            throw error;
        }
    }

    initializeTables() {
        try {
            // Users table
            this.db.exec(`
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT UNIQUE NOT NULL,
                    email TEXT,
                    name TEXT,
                    preferences TEXT,
                    voice_settings TEXT,
                    subscription_status TEXT DEFAULT 'free',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    last_login DATETIME
                )
            `);

            // Screenshots table
            this.db.exec(`
                CREATE TABLE IF NOT EXISTS screenshots (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    image_path TEXT NOT NULL,
                    image_data BLOB,
                    analysis_result TEXT,
                    context_info TEXT,
                    processing_status TEXT DEFAULT 'pending',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    processed_at DATETIME,
                    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
                )
            `);

            // Flirts table
            this.db.exec(`
                CREATE TABLE IF NOT EXISTS flirts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    screenshot_id INTEGER,
                    content TEXT NOT NULL,
                    style TEXT,
                    tone TEXT,
                    confidence_score REAL,
                    is_favorite BOOLEAN DEFAULT FALSE,
                    usage_count INTEGER DEFAULT 0,
                    feedback_rating INTEGER,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    used_at DATETIME,
                    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                    FOREIGN KEY (screenshot_id) REFERENCES screenshots(id) ON DELETE SET NULL
                )
            `);

            // Sessions table
            this.db.exec(`
                CREATE TABLE IF NOT EXISTS sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT UNIQUE NOT NULL,
                    user_id TEXT NOT NULL,
                    device_info TEXT,
                    start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
                    end_time DATETIME,
                    activity_data TEXT,
                    is_active BOOLEAN DEFAULT TRUE,
                    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
                )
            `);

            // Create indexes for better performance
            this.db.exec('CREATE INDEX IF NOT EXISTS idx_screenshots_user_id ON screenshots(user_id)');
            this.db.exec('CREATE INDEX IF NOT EXISTS idx_flirts_user_id ON flirts(user_id)');
            this.db.exec('CREATE INDEX IF NOT EXISTS idx_flirts_screenshot_id ON flirts(screenshot_id)');
            this.db.exec('CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id)');
            this.db.exec('CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active)');

            // Create triggers for updated_at timestamp
            this.db.exec(`
                CREATE TRIGGER IF NOT EXISTS update_users_timestamp
                AFTER UPDATE ON users
                BEGIN
                    UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
                END
            `);

            logger.info('Database tables initialized successfully');

        } catch (error) {
            logger.error('Failed to initialize database tables', { error: error.message });
            throw error;
        }
    }

    // User operations
    createUser(userData) {
        try {
            const stmt = this.db.prepare(`
                INSERT INTO users (user_id, email, name, preferences, voice_settings, subscription_status)
                VALUES (?, ?, ?, ?, ?, ?)
            `);

            return stmt.run(
                userData.user_id,
                userData.email || null,
                userData.name || null,
                userData.preferences ? JSON.stringify(userData.preferences) : null,
                userData.voice_settings ? JSON.stringify(userData.voice_settings) : null,
                userData.subscription_status || 'free'
            );
        } catch (error) {
            logger.error('Failed to create user', { error: error.message, userData });
            throw error;
        }
    }

    getUserById(userId) {
        try {
            const stmt = this.db.prepare('SELECT * FROM users WHERE user_id = ?');
            const user = stmt.get(userId);

            if (user) {
                user.preferences = user.preferences ? JSON.parse(user.preferences) : null;
                user.voice_settings = user.voice_settings ? JSON.parse(user.voice_settings) : null;
            }

            return user;
        } catch (error) {
            logger.error('Failed to get user', { error: error.message, userId });
            throw error;
        }
    }

    updateUser(userId, updateData) {
        try {
            const fields = [];
            const values = [];

            Object.keys(updateData).forEach(key => {
                if (key === 'preferences' || key === 'voice_settings') {
                    fields.push(`${key} = ?`);
                    values.push(JSON.stringify(updateData[key]));
                } else {
                    fields.push(`${key} = ?`);
                    values.push(updateData[key]);
                }
            });

            values.push(userId);

            const stmt = this.db.prepare(`
                UPDATE users SET ${fields.join(', ')} WHERE user_id = ?
            `);

            return stmt.run(...values);
        } catch (error) {
            logger.error('Failed to update user', { error: error.message, userId, updateData });
            throw error;
        }
    }

    // Screenshot operations
    createScreenshot(screenshotData) {
        try {
            const stmt = this.db.prepare(`
                INSERT INTO screenshots (user_id, image_path, image_data, analysis_result, context_info, processing_status)
                VALUES (?, ?, ?, ?, ?, ?)
            `);

            return stmt.run(
                screenshotData.user_id,
                screenshotData.image_path || null,
                screenshotData.image_data || null,
                screenshotData.analysis_result ? JSON.stringify(screenshotData.analysis_result) : null,
                screenshotData.context_info ? JSON.stringify(screenshotData.context_info) : null,
                screenshotData.processing_status || 'pending'
            );
        } catch (error) {
            logger.error('Failed to create screenshot', { error: error.message, screenshotData });
            throw error;
        }
    }

    getScreenshotById(screenshotId) {
        try {
            const stmt = this.db.prepare('SELECT * FROM screenshots WHERE id = ?');
            const screenshot = stmt.get(screenshotId);

            if (screenshot) {
                screenshot.analysis_result = screenshot.analysis_result ? JSON.parse(screenshot.analysis_result) : null;
                screenshot.context_info = screenshot.context_info ? JSON.parse(screenshot.context_info) : null;
            }

            return screenshot;
        } catch (error) {
            logger.error('Failed to get screenshot', { error: error.message, screenshotId });
            throw error;
        }
    }

    getUserScreenshots(userId, limit = 20, offset = 0) {
        try {
            const stmt = this.db.prepare(`
                SELECT * FROM screenshots
                WHERE user_id = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            `);

            const screenshots = stmt.all(userId, limit, offset);

            return screenshots.map(screenshot => ({
                ...screenshot,
                analysis_result: screenshot.analysis_result ? JSON.parse(screenshot.analysis_result) : null,
                context_info: screenshot.context_info ? JSON.parse(screenshot.context_info) : null
            }));
        } catch (error) {
            logger.error('Failed to get user screenshots', { error: error.message, userId });
            throw error;
        }
    }

    updateScreenshot(screenshotId, updateData) {
        try {
            const fields = [];
            const values = [];

            Object.keys(updateData).forEach(key => {
                if (key === 'analysis_result' || key === 'context_info') {
                    fields.push(`${key} = ?`);
                    values.push(JSON.stringify(updateData[key]));
                } else {
                    fields.push(`${key} = ?`);
                    values.push(updateData[key]);
                }
            });

            if (updateData.processing_status === 'completed') {
                fields.push('processed_at = CURRENT_TIMESTAMP');
            }

            values.push(screenshotId);

            const stmt = this.db.prepare(`
                UPDATE screenshots SET ${fields.join(', ')} WHERE id = ?
            `);

            return stmt.run(...values);
        } catch (error) {
            logger.error('Failed to update screenshot', { error: error.message, screenshotId, updateData });
            throw error;
        }
    }

    // Flirt operations
    createFlirt(flirtData) {
        try {
            const stmt = this.db.prepare(`
                INSERT INTO flirts (user_id, screenshot_id, content, style, tone, confidence_score)
                VALUES (?, ?, ?, ?, ?, ?)
            `);

            return stmt.run(
                flirtData.user_id,
                flirtData.screenshot_id || null,
                flirtData.content,
                flirtData.style || null,
                flirtData.tone || null,
                flirtData.confidence_score || null
            );
        } catch (error) {
            logger.error('Failed to create flirt', { error: error.message, flirtData });
            throw error;
        }
    }

    getUserFlirts(userId, limit = 50, offset = 0) {
        try {
            const stmt = this.db.prepare(`
                SELECT f.*, s.image_path, s.context_info
                FROM flirts f
                LEFT JOIN screenshots s ON f.screenshot_id = s.id
                WHERE f.user_id = ?
                ORDER BY f.created_at DESC
                LIMIT ? OFFSET ?
            `);

            return stmt.all(userId, limit, offset);
        } catch (error) {
            logger.error('Failed to get user flirts', { error: error.message, userId });
            throw error;
        }
    }

    updateFlirtUsage(flirtId) {
        try {
            const stmt = this.db.prepare(`
                UPDATE flirts
                SET usage_count = usage_count + 1, used_at = CURRENT_TIMESTAMP
                WHERE id = ?
            `);

            return stmt.run(flirtId);
        } catch (error) {
            logger.error('Failed to update flirt usage', { error: error.message, flirtId });
            throw error;
        }
    }

    // Session operations
    createSession(sessionData) {
        try {
            const stmt = this.db.prepare(`
                INSERT INTO sessions (session_id, user_id, device_info, activity_data)
                VALUES (?, ?, ?, ?)
            `);

            return stmt.run(
                sessionData.session_id,
                sessionData.user_id,
                sessionData.device_info ? JSON.stringify(sessionData.device_info) : null,
                sessionData.activity_data ? JSON.stringify(sessionData.activity_data) : null
            );
        } catch (error) {
            logger.error('Failed to create session', { error: error.message, sessionData });
            throw error;
        }
    }

    endSession(sessionId) {
        try {
            const stmt = this.db.prepare(`
                UPDATE sessions
                SET end_time = CURRENT_TIMESTAMP, is_active = FALSE
                WHERE session_id = ?
            `);

            return stmt.run(sessionId);
        } catch (error) {
            logger.error('Failed to end session', { error: error.message, sessionId });
            throw error;
        }
    }

    getActiveSession(userId) {
        try {
            const stmt = this.db.prepare(`
                SELECT * FROM sessions
                WHERE user_id = ? AND is_active = TRUE
                ORDER BY start_time DESC
                LIMIT 1
            `);

            return stmt.get(userId);
        } catch (error) {
            logger.error('Failed to get active session', { error: error.message, userId });
            throw error;
        }
    }

    // Utility methods
    getStats() {
        try {
            const stats = {
                totalUsers: this.db.prepare('SELECT COUNT(*) as count FROM users').get().count,
                totalScreenshots: this.db.prepare('SELECT COUNT(*) as count FROM screenshots').get().count,
                totalFlirts: this.db.prepare('SELECT COUNT(*) as count FROM flirts').get().count,
                activeSessions: this.db.prepare('SELECT COUNT(*) as count FROM sessions WHERE is_active = TRUE').get().count
            };

            return stats;
        } catch (error) {
            logger.error('Failed to get database stats', { error: error.message });
            throw error;
        }
    }

    // Transaction wrapper
    transaction(fn) {
        try {
            return this.db.transaction(fn)();
        } catch (error) {
            logger.error('Transaction failed', { error: error.message });
            throw error;
        }
    }

    // Health check
    healthCheck() {
        try {
            this.db.prepare('SELECT 1').get();
            return { status: 'healthy', connected: this.isConnected };
        } catch (error) {
            logger.error('Database health check failed', { error: error.message });
            return { status: 'unhealthy', connected: false, error: error.message };
        }
    }

    // Cleanup and close
    close() {
        try {
            if (this.db) {
                this.db.close();
                this.isConnected = false;
                logger.info('Database connection closed');
            }
        } catch (error) {
            logger.error('Failed to close database', { error: error.message });
        }
    }

    // Backup database
    backup(backupPath) {
        try {
            const backupDb = new Database(backupPath);
            this.db.backup(backupDb);
            backupDb.close();
            logger.info('Database backup created', { backupPath });
            return true;
        } catch (error) {
            logger.error('Failed to create database backup', { error: error.message, backupPath });
            throw error;
        }
    }
}

// Create singleton instance
const databaseService = new DatabaseService();

// Graceful shutdown
process.on('SIGINT', () => {
    databaseService.close();
    process.exit(0);
});

process.on('SIGTERM', () => {
    databaseService.close();
    process.exit(0);
});

module.exports = databaseService;