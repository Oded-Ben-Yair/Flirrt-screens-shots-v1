/**
 * Gamification Service for Flirrt.AI
 *
 * Provides progress tracking, achievements, and level system
 * to create an engaging dating coach experience.
 *
 * Level System:
 * - Beginner (Level 1): 0-4 successful conversations
 * - Learner (Level 2-3): 5-14 successful conversations
 * - Confident (Level 4-5): 15-24 successful conversations
 * - Skilled (Level 6-10): 25-49 successful conversations
 * - Expert (Level 11+): 50+ successful conversations
 */

const db = require('../config/database');

class GamificationService {

    constructor() {
        this.achievements = this.initializeAchievements();
    }

    /**
     * Initialize achievement definitions
     */
    initializeAchievements() {
        return [
            {
                id: 'first_message',
                title: 'Ice Breaker',
                description: 'Send your first flirt suggestion',
                icon: '❄️',
                requirement: { type: 'messages_sent', count: 1 }
            },
            {
                id: 'ten_messages',
                title: 'Conversation Starter',
                description: 'Send 10 flirt suggestions',
                icon: '💬',
                requirement: { type: 'messages_sent', count: 10 }
            },
            {
                id: 'first_success',
                title: 'First Connection',
                description: 'Have your first successful conversation',
                icon: '✨',
                requirement: { type: 'successful_conversations', count: 1 }
            },
            {
                id: 'five_successes',
                title: 'Confident Communicator',
                description: 'Achieve 5 successful conversations',
                icon: '🎯',
                requirement: { type: 'successful_conversations', count: 5 }
            },
            {
                id: 'ten_successes',
                title: 'Dating Pro',
                description: 'Achieve 10 successful conversations',
                icon: '🏆',
                requirement: { type: 'successful_conversations', count: 10 }
            },
            {
                id: 'profile_analyzer',
                title: 'Profile Expert',
                description: 'Analyze 20 dating profiles',
                icon: '🔍',
                requirement: { type: 'profiles_analyzed', count: 20 }
            },
            {
                id: 'conversation_master',
                title: 'Conversation Master',
                description: 'Get 50 conversation suggestions',
                icon: '💡',
                requirement: { type: 'suggestions_generated', count: 50 }
            },
            {
                id: 'refresh_enthusiast',
                title: 'Perfectionist',
                description: 'Use the refresh button 10 times',
                icon: '🔄',
                requirement: { type: 'refreshes_used', count: 10 }
            },
            {
                id: 'high_confidence',
                title: 'High Roller',
                description: 'Use a suggestion with 90+ confidence',
                icon: '⭐',
                requirement: { type: 'high_confidence_used', count: 1 }
            },
            {
                id: 'diverse_tones',
                title: 'Tone Master',
                description: 'Try all 4 tone preferences',
                icon: '🎭',
                requirement: { type: 'unique_tones_used', count: 4 }
            },
            {
                id: 'week_streak',
                title: 'Committed',
                description: 'Use Flirrt for 7 days in a row',
                icon: '🔥',
                requirement: { type: 'daily_streak', count: 7 }
            },
            {
                id: 'expert_level',
                title: 'Dating Expert',
                description: 'Reach Expert level (Level 11+)',
                icon: '👑',
                requirement: { type: 'level', count: 11 }
            }
        ];
    }

    /**
     * Get or create user stats
     * @param {string} userId - User UUID
     * @returns {Promise<Object>} User statistics
     */
    async getUserStats(userId) {
        if (!db.isAvailable()) {
            // Return default stats if database is not available
            return {
                messages_sent: 0,
                successful_conversations: 0,
                profiles_analyzed: 0,
                suggestions_generated: 0,
                refreshes_used: 0,
                high_confidence_used: 0,
                unique_tones_used: 0,
                daily_streak: 0,
                last_activity_date: new Date().toISOString(),
                total_confidence_sum: 0,
                total_confidence_count: 0
            };
        }

        try {
            const query = `
                SELECT
                    messages_sent,
                    successful_conversations,
                    profiles_analyzed,
                    suggestions_generated,
                    refreshes_used,
                    high_confidence_used,
                    unique_tones_used,
                    daily_streak,
                    last_activity_date,
                    total_confidence_sum,
                    total_confidence_count,
                    created_at,
                    updated_at
                FROM user_stats
                WHERE user_id = $1
            `;

            const result = await db.query(query, [userId]);

            if (!result || result.rows.length === 0) {
                // Create new stats record
                const insertQuery = `
                    INSERT INTO user_stats (
                        user_id,
                        messages_sent,
                        successful_conversations,
                        profiles_analyzed,
                        suggestions_generated,
                        refreshes_used,
                        high_confidence_used,
                        unique_tones_used,
                        daily_streak,
                        last_activity_date
                    ) VALUES ($1, 0, 0, 0, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP)
                    RETURNING *
                `;

                const insertResult = await db.query(insertQuery, [userId]);
                return insertResult.rows[0];
            }

            return result.rows[0];

        } catch (error) {
            console.error('Error fetching user stats:', error);
            throw error;
        }
    }

    /**
     * Update user stats
     * @param {string} userId - User UUID
     * @param {Object} updates - Stats to update
     * @returns {Promise<Object>} Updated stats
     */
    async updateUserStats(userId, updates) {
        if (!db.isAvailable()) {
            console.warn('Database not available, skipping stats update');
            return null;
        }

        try {
            // Get current stats to calculate daily streak
            const currentStats = await this.getUserStats(userId);
            const lastActivity = new Date(currentStats.last_activity_date);
            const today = new Date();
            const daysSinceLastActivity = Math.floor((today - lastActivity) / (1000 * 60 * 60 * 24));

            // Update daily streak
            let newStreak = currentStats.daily_streak;
            if (daysSinceLastActivity === 1) {
                // Consecutive day
                newStreak += 1;
            } else if (daysSinceLastActivity > 1) {
                // Streak broken
                newStreak = 1;
            }
            // If daysSinceLastActivity === 0, same day, keep current streak

            const setClauses = [];
            const values = [];
            let paramIndex = 1;

            // Build dynamic SET clause
            for (const [key, value] of Object.entries(updates)) {
                if (key === 'increment') {
                    // Handle increment operations
                    for (const [field, amount] of Object.entries(value)) {
                        setClauses.push(`${field} = ${field} + $${paramIndex}`);
                        values.push(amount);
                        paramIndex++;
                    }
                } else {
                    setClauses.push(`${key} = $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
            }

            // Update daily streak and last activity
            setClauses.push(`daily_streak = $${paramIndex}`);
            values.push(newStreak);
            paramIndex++;

            setClauses.push(`last_activity_date = CURRENT_TIMESTAMP`);
            setClauses.push(`updated_at = CURRENT_TIMESTAMP`);

            values.push(userId);

            const query = `
                UPDATE user_stats
                SET ${setClauses.join(', ')}
                WHERE user_id = $${paramIndex}
                RETURNING *
            `;

            const result = await db.query(query, values);
            return result.rows[0];

        } catch (error) {
            console.error('Error updating user stats:', error);
            throw error;
        }
    }

    /**
     * Calculate user level based on successful conversations
     * @param {string} userId - User UUID
     * @returns {Promise<Object>} Level information
     */
    async calculateLevel(userId) {
        try {
            const stats = await this.getUserStats(userId);

            // Level based on successful conversations (every 5 conversations = 1 level)
            const level = Math.floor(stats.successful_conversations / 5) + 1;
            const nextLevelAt = level * 5;
            const progressToNextLevel = stats.successful_conversations % 5;

            return {
                level,
                title: this.getLevelTitle(level),
                progress: progressToNextLevel,
                nextLevelAt,
                totalSuccesses: stats.successful_conversations,
                percentageToNext: Math.round((progressToNextLevel / 5) * 100)
            };

        } catch (error) {
            console.error('Error calculating level:', error);
            // Return default level on error
            return {
                level: 1,
                title: 'Beginner',
                progress: 0,
                nextLevelAt: 5,
                totalSuccesses: 0,
                percentageToNext: 0
            };
        }
    }

    /**
     * Get level title based on level number
     * @param {number} level - Level number
     * @returns {string} Level title
     */
    getLevelTitle(level) {
        if (level === 1) return 'Beginner';
        if (level <= 3) return 'Learner';
        if (level <= 5) return 'Confident';
        if (level <= 10) return 'Skilled';
        return 'Expert';
    }

    /**
     * Check and unlock achievements for user
     * @param {string} userId - User UUID
     * @returns {Promise<Object>} Achievement status
     */
    async checkAchievements(userId) {
        try {
            const stats = await this.getUserStats(userId);
            const level = await this.calculateLevel(userId);

            const unlockedAchievements = [];
            const lockedAchievements = [];

            for (const achievement of this.achievements) {
                const { requirement } = achievement;
                let isUnlocked = false;

                // Check requirement
                switch (requirement.type) {
                    case 'messages_sent':
                        isUnlocked = stats.messages_sent >= requirement.count;
                        break;
                    case 'successful_conversations':
                        isUnlocked = stats.successful_conversations >= requirement.count;
                        break;
                    case 'profiles_analyzed':
                        isUnlocked = stats.profiles_analyzed >= requirement.count;
                        break;
                    case 'suggestions_generated':
                        isUnlocked = stats.suggestions_generated >= requirement.count;
                        break;
                    case 'refreshes_used':
                        isUnlocked = stats.refreshes_used >= requirement.count;
                        break;
                    case 'high_confidence_used':
                        isUnlocked = stats.high_confidence_used >= requirement.count;
                        break;
                    case 'unique_tones_used':
                        isUnlocked = stats.unique_tones_used >= requirement.count;
                        break;
                    case 'daily_streak':
                        isUnlocked = stats.daily_streak >= requirement.count;
                        break;
                    case 'level':
                        isUnlocked = level.level >= requirement.count;
                        break;
                    default:
                        isUnlocked = false;
                }

                const achievementData = {
                    ...achievement,
                    unlocked: isUnlocked,
                    progress: this.getAchievementProgress(requirement.type, stats, level),
                    target: requirement.count
                };

                if (isUnlocked) {
                    unlockedAchievements.push(achievementData);
                } else {
                    lockedAchievements.push(achievementData);
                }
            }

            return {
                unlocked: unlockedAchievements,
                locked: lockedAchievements,
                total: this.achievements.length,
                unlockedCount: unlockedAchievements.length,
                completionPercentage: Math.round((unlockedAchievements.length / this.achievements.length) * 100)
            };

        } catch (error) {
            console.error('Error checking achievements:', error);
            return {
                unlocked: [],
                locked: this.achievements.map(a => ({ ...a, unlocked: false, progress: 0, target: a.requirement.count })),
                total: this.achievements.length,
                unlockedCount: 0,
                completionPercentage: 0
            };
        }
    }

    /**
     * Get progress for a specific achievement requirement
     * @param {string} type - Requirement type
     * @param {Object} stats - User stats
     * @param {Object} level - User level info
     * @returns {number} Current progress
     */
    getAchievementProgress(type, stats, level) {
        switch (type) {
            case 'messages_sent':
                return stats.messages_sent;
            case 'successful_conversations':
                return stats.successful_conversations;
            case 'profiles_analyzed':
                return stats.profiles_analyzed;
            case 'suggestions_generated':
                return stats.suggestions_generated;
            case 'refreshes_used':
                return stats.refreshes_used;
            case 'high_confidence_used':
                return stats.high_confidence_used;
            case 'unique_tones_used':
                return stats.unique_tones_used;
            case 'daily_streak':
                return stats.daily_streak;
            case 'level':
                return level.level;
            default:
                return 0;
        }
    }

    /**
     * Record a suggestion usage event
     * @param {string} userId - User UUID
     * @param {Object} suggestionData - Suggestion details
     * @returns {Promise<Object>} Updated stats
     */
    async recordSuggestionUsed(userId, suggestionData) {
        const { confidence, tone, wasRefresh = false } = suggestionData;

        const updates = {
            increment: {
                messages_sent: 1,
                suggestions_generated: 1
            }
        };

        // Track high confidence usage
        if (confidence >= 90) {
            updates.increment.high_confidence_used = 1;
        }

        // Track refresh usage
        if (wasRefresh) {
            updates.increment.refreshes_used = 1;
        }

        // Track confidence for averaging
        if (confidence) {
            updates.increment.total_confidence_sum = confidence;
            updates.increment.total_confidence_count = 1;
        }

        return await this.updateUserStats(userId, updates);
    }

    /**
     * Record a profile analysis event
     * @param {string} userId - User UUID
     * @returns {Promise<Object>} Updated stats
     */
    async recordProfileAnalyzed(userId) {
        return await this.updateUserStats(userId, {
            increment: {
                profiles_analyzed: 1
            }
        });
    }

    /**
     * Record a successful conversation
     * @param {string} userId - User UUID
     * @returns {Promise<Object>} Updated stats and level info
     */
    async recordSuccessfulConversation(userId) {
        const updatedStats = await this.updateUserStats(userId, {
            increment: {
                successful_conversations: 1
            }
        });

        const levelInfo = await this.calculateLevel(userId);

        return {
            stats: updatedStats,
            level: levelInfo
        };
    }

    /**
     * Record tone preference usage
     * @param {string} userId - User UUID
     * @param {string} tone - Tone used (playful, serious, witty, romantic)
     * @returns {Promise<Object>} Updated stats
     */
    async recordToneUsed(userId, tone) {
        if (!db.isAvailable()) {
            return null;
        }

        try {
            // Get unique tones used by checking analytics
            const query = `
                SELECT DISTINCT event_data->>'tone' as tone
                FROM analytics
                WHERE user_id = $1 AND event_type = 'suggestion_used'
            `;

            const result = await db.query(query, [userId]);
            const uniqueTones = result ? result.rows.length : 0;

            return await this.updateUserStats(userId, {
                unique_tones_used: uniqueTones
            });

        } catch (error) {
            console.error('Error recording tone usage:', error);
            return null;
        }
    }

    /**
     * Get complete progress dashboard
     * @param {string} userId - User UUID
     * @returns {Promise<Object>} Complete progress data
     */
    async getProgressDashboard(userId) {
        try {
            const stats = await this.getUserStats(userId);
            const level = await this.calculateLevel(userId);
            const achievements = await this.checkAchievements(userId);

            // Calculate average confidence
            const avgConfidence = stats.total_confidence_count > 0
                ? Math.round(stats.total_confidence_sum / stats.total_confidence_count)
                : 0;

            return {
                success: true,
                user_id: userId,
                level,
                stats: {
                    messages_sent: stats.messages_sent,
                    successful_conversations: stats.successful_conversations,
                    profiles_analyzed: stats.profiles_analyzed,
                    suggestions_generated: stats.suggestions_generated,
                    refreshes_used: stats.refreshes_used,
                    daily_streak: stats.daily_streak,
                    average_confidence: avgConfidence
                },
                achievements,
                engagement: {
                    last_activity: stats.last_activity_date,
                    is_active_today: this.isActiveToday(stats.last_activity_date),
                    streak_status: this.getStreakStatus(stats.daily_streak)
                }
            };

        } catch (error) {
            console.error('Error getting progress dashboard:', error);
            throw error;
        }
    }

    /**
     * Check if user was active today
     * @param {string} lastActivityDate - Last activity date
     * @returns {boolean} True if active today
     */
    isActiveToday(lastActivityDate) {
        const lastActivity = new Date(lastActivityDate);
        const today = new Date();
        return lastActivity.toDateString() === today.toDateString();
    }

    /**
     * Get streak status message
     * @param {number} streak - Current streak count
     * @returns {string} Status message
     */
    getStreakStatus(streak) {
        if (streak === 0) return 'Start your streak today!';
        if (streak === 1) return 'Great start! Keep it going!';
        if (streak < 7) return `${streak} days strong! Keep going!`;
        if (streak < 30) return `Amazing ${streak} day streak!`;
        return `Incredible ${streak} day streak! You're a legend!`;
    }
}

module.exports = new GamificationService();
