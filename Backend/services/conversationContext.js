const { Pool } = require('pg');

/**
 * Conversation Context Service
 * Maintains multi-screenshot context for intelligent conversation flow
 *
 * Features:
 * - Track conversation sessions
 * - Store screenshot history per conversation
 * - Provide context history for AI suggestions
 * - Session timeout management
 */
class ConversationContextService {
  constructor() {
    // Only create pool if DB credentials exist (graceful degradation)
    if (process.env.DB_HOST && process.env.DB_NAME) {
      this.pool = new Pool({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
      });
      console.log('✅ Database pool initialized for conversation context');
    } else {
      this.pool = null;
      console.warn('⚠️  Database not configured - using mock sessions (conversation context disabled)');
    }

    // Session expires after 30 minutes of inactivity
    this.sessionTimeout = 30 * 60 * 1000;
  }

  /**
   * Create or get active conversation session
   * @param {string} userId - User ID
   * @param {string} conversationId - Optional conversation ID (dating app specific)
   * @returns {Promise<Object>} Session object
   */
  async getOrCreateSession(userId, conversationId = null) {
    // If no database, return mock session immediately
    if (!this.pool) {
      console.log('📦 Returning mock session (database not configured)');
      return {
        id: `session_${Date.now()}`,
        user_id: userId,
        conversation_id: conversationId,
        created_at: new Date(),
        updated_at: new Date(),
        screenshot_count: 0
      };
    }

    try {
      // Try to find active session (updated within last 30 minutes)
      const activeSessionQuery = `
        SELECT id, user_id, conversation_id, created_at, updated_at, screenshot_count
        FROM conversation_sessions
        WHERE user_id = $1
          AND ($2::text IS NULL OR conversation_id = $2)
          AND updated_at > NOW() - INTERVAL '30 minutes'
        ORDER BY updated_at DESC
        LIMIT 1
      `;

      const result = await this.pool.query(activeSessionQuery, [userId, conversationId]);

      if (result.rows.length > 0) {
        // Return existing active session
        console.log(`📝 Using active session: ${result.rows[0].id}`);
        return result.rows[0];
      }

      // Create new session
      const createSessionQuery = `
        INSERT INTO conversation_sessions (user_id, conversation_id)
        VALUES ($1, $2)
        RETURNING id, user_id, conversation_id, created_at, updated_at, screenshot_count
      `;

      const createResult = await this.pool.query(createSessionQuery, [userId, conversationId]);
      console.log(`✨ Created new conversation session: ${createResult.rows[0].id}`);

      return createResult.rows[0];

    } catch (error) {
      console.error('❌ Session creation/retrieval error:', error.message);
      // Return mock session for development
      return {
        id: `session_${Date.now()}`,
        user_id: userId,
        conversation_id: conversationId,
        created_at: new Date(),
        updated_at: new Date(),
        screenshot_count: 0
      };
    }
  }

  /**
   * Add screenshot to conversation session
   * @param {string} sessionId - Session ID
   * @param {string} screenshotId - Screenshot ID
   * @param {Object} analysis - Screenshot analysis result
   * @returns {Promise<void>}
   */
  async addScreenshotToSession(sessionId, screenshotId, analysis) {
    // If no database, skip gracefully
    if (!this.pool) {
      console.log('📦 Skipping screenshot session link (database not configured)');
      return;
    }

    try {
      // Link screenshot to session
      const linkQuery = `
        UPDATE screenshots
        SET session_id = $1, analysis_result = $2
        WHERE id = $3
      `;

      await this.pool.query(linkQuery, [sessionId, analysis, screenshotId]);

      // Update session timestamp and screenshot count
      const updateSessionQuery = `
        UPDATE conversation_sessions
        SET updated_at = NOW(),
            screenshot_count = screenshot_count + 1
        WHERE id = $1
      `;

      await this.pool.query(updateSessionQuery, [sessionId]);

      console.log(`📸 Added screenshot ${screenshotId} to session ${sessionId}`);

    } catch (error) {
      console.warn('Failed to link screenshot to session (database unavailable):', error.message);
    }
  }

  /**
   * Get conversation history for context
   * @param {string} sessionId - Session ID
   * @param {number} limit - Max number of previous screenshots to retrieve
   * @returns {Promise<Array>} Array of previous screenshots with suggestions
   */
  async getConversationHistory(sessionId, limit = 3) {
    // If no database, return empty history
    if (!this.pool) {
      console.log('📦 Returning empty history (database not configured)');
      return [];
    }

    try {
      const historyQuery = `
        SELECT
          s.id as screenshot_id,
          s.analysis_result,
          s.created_at as screenshot_time,
          COALESCE(
            json_agg(
              json_build_object(
                'text', fs.suggestion_text,
                'confidence', fs.confidence_score,
                'used', fs.used_at IS NOT NULL
              ) ORDER BY fs.created_at
            ) FILTER (WHERE fs.id IS NOT NULL),
            '[]'
          ) as suggestions
        FROM screenshots s
        LEFT JOIN flirt_suggestions fs ON fs.screenshot_id = s.id
        WHERE s.session_id = $1
        GROUP BY s.id, s.analysis_result, s.created_at
        ORDER BY s.created_at DESC
        LIMIT $2
      `;

      const result = await this.pool.query(historyQuery, [sessionId, limit]);

      console.log(`📚 Retrieved ${result.rows.length} previous screenshots for context`);

      return result.rows;

    } catch (error) {
      console.warn('Failed to retrieve conversation history (database unavailable):', error.message);
      return [];
    }
  }

  /**
   * Build context prompt from conversation history
   * @param {Array} history - Array of previous screenshots
   * @returns {string} Formatted context string
   */
  buildContextPrompt(history) {
    if (!history || history.length === 0) {
      return 'No previous conversation history.';
    }

    let contextPrompt = `CONVERSATION HISTORY (${history.length} previous screenshots):\n\n`;

    history.reverse().forEach((item, index) => {
      contextPrompt += `Screenshot ${index + 1} (${item.screenshot_time}):\n`;
      contextPrompt += `Analysis: ${JSON.stringify(item.analysis_result)}\n`;

      if (item.suggestions && item.suggestions.length > 0) {
        const usedSuggestions = item.suggestions.filter(s => s.used);
        if (usedSuggestions.length > 0) {
          contextPrompt += `Used suggestions:\n`;
          usedSuggestions.forEach(s => {
            contextPrompt += `  - "${s.text}"\n`;
          });
        }
      }

      contextPrompt += '\n';
    });

    contextPrompt += 'Based on this conversation history, generate suggestions that:\n';
    contextPrompt += '1. Continue the natural flow of the conversation\n';
    contextPrompt += '2. Reference previous topics if relevant\n';
    contextPrompt += '3. Avoid repeating similar suggestions\n';
    contextPrompt += '4. Progress the conversation forward\n\n';

    return contextPrompt;
  }

  /**
   * Close inactive sessions (cleanup job)
   * @returns {Promise<number>} Number of sessions closed
   */
  async closeInactiveSessions() {
    // If no database, skip gracefully
    if (!this.pool) {
      return 0;
    }

    try {
      const closeQuery = `
        UPDATE conversation_sessions
        SET status = 'closed', closed_at = NOW()
        WHERE status = 'active'
          AND updated_at < NOW() - INTERVAL '30 minutes'
      `;

      const result = await this.pool.query(closeQuery);

      if (result.rowCount > 0) {
        console.log(`🧹 Closed ${result.rowCount} inactive sessions`);
      }

      return result.rowCount;

    } catch (error) {
      console.warn('Failed to close inactive sessions:', error.message);
      return 0;
    }
  }

  /**
   * Get session statistics
   * @param {string} sessionId - Session ID
   * @returns {Promise<Object>} Session stats
   */
  async getSessionStats(sessionId) {
    // If no database, return null
    if (!this.pool) {
      return null;
    }

    try {
      const statsQuery = `
        SELECT
          cs.id,
          cs.screenshot_count,
          cs.created_at,
          cs.updated_at,
          COUNT(DISTINCT s.id) as total_screenshots,
          COUNT(DISTINCT fs.id) as total_suggestions,
          COUNT(DISTINCT fs.id) FILTER (WHERE fs.used_at IS NOT NULL) as used_suggestions
        FROM conversation_sessions cs
        LEFT JOIN screenshots s ON s.session_id = cs.id
        LEFT JOIN flirt_suggestions fs ON fs.screenshot_id = s.id
        WHERE cs.id = $1
        GROUP BY cs.id, cs.screenshot_count, cs.created_at, cs.updated_at
      `;

      const result = await this.pool.query(statsQuery, [sessionId]);

      if (result.rows.length > 0) {
        return result.rows[0];
      }

      return null;

    } catch (error) {
      console.warn('Failed to retrieve session stats:', error.message);
      return null;
    }
  }
}

module.exports = new ConversationContextService();
