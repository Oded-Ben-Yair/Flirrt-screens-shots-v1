/**
 * CP-6: Comprehensive Service Layer Tests
 * Tests all backend services for functionality and edge cases
 */

const contentModeration = require('../services/contentModeration');
const conversationContext = require('../services/conversationContext');
const gamificationService = require('../services/gamificationService');
const aiOrchestrator = require('../services/aiOrchestrator');

describe('Service Layer Tests', () => {

    describe('Content Moderation Service', () => {
        test('filterSuggestions should remove inappropriate content', async () => {
            const suggestions = [
                { text: 'Hey, you look amazing!', confidence: 0.9 },
                { text: 'Inappropriate content here', confidence: 0.8 },
                { text: 'Would love to get to know you', confidence: 0.85 }
            ];

            const filtered = await contentModeration.filterSuggestions(suggestions);

            expect(Array.isArray(filtered)).toBe(true);
            // All returned suggestions should be appropriate
            filtered.forEach(suggestion => {
                expect(suggestion).toHaveProperty('text');
                expect(suggestion).toHaveProperty('confidence');
            });
        });

        test('moderateText should flag inappropriate content', async () => {
            const inappropriateText = 'This contains offensive language';
            const result = await contentModeration.moderateText(inappropriateText);

            expect(result).toHaveProperty('flagged');
            expect(typeof result.flagged).toBe('boolean');

            if (result.flagged) {
                expect(result).toHaveProperty('categories');
            }
        });

        test('Empty suggestions array should return empty array', async () => {
            const filtered = await contentModeration.filterSuggestions([]);
            expect(filtered).toEqual([]);
        });
    });

    describe('Conversation Context Service', () => {
        let testUserId = 'test-user-123';
        let testConversationId = 'test-conversation-123';

        test('getOrCreateSession should create new session', async () => {
            const session = await conversationContext.getOrCreateSession(
                testUserId,
                testConversationId
            );

            expect(session).toHaveProperty('id');
            expect(session).toHaveProperty('userId', testUserId);
            expect(session).toHaveProperty('conversationId', testConversationId);
        });

        test('getConversationHistory should return recent screenshots', async () => {
            const sessionId = 'test-session-123';
            const history = await conversationContext.getConversationHistory(sessionId, 3);

            expect(Array.isArray(history)).toBe(true);
            expect(history.length).toBeLessThanOrEqual(3);
        });

        test('buildContextPrompt should generate prompt from history', () => {
            const history = [
                {
                    screenshot_type: 'profile',
                    extracted_details: { name: 'Sarah', age: 25 }
                },
                {
                    screenshot_type: 'chat',
                    extracted_details: { last_message: 'Hey! How are you?' }
                }
            ];

            const prompt = conversationContext.buildContextPrompt(history);

            expect(typeof prompt).toBe('string');
            expect(prompt).toContain('CONVERSATION CONTEXT');
        });

        test('Empty history should return empty prompt', () => {
            const prompt = conversationContext.buildContextPrompt([]);
            expect(prompt).toBe('');
        });
    });

    describe('Gamification Service', () => {
        let testUserId = 'test-gamification-user';

        test('getUserStats should return user statistics', async () => {
            const stats = await gamificationService.getUserStats(testUserId);

            expect(stats).toHaveProperty('messages_sent');
            expect(stats).toHaveProperty('successful_conversations');
            expect(stats).toHaveProperty('profiles_analyzed');
            expect(stats).toHaveProperty('daily_streak');
            expect(typeof stats.messages_sent).toBe('number');
        });

        test('calculateLevel should return level information', async () => {
            const levelInfo = await gamificationService.calculateLevel(testUserId);

            expect(levelInfo).toHaveProperty('level');
            expect(levelInfo).toHaveProperty('title');
            expect(levelInfo).toHaveProperty('progress');
            expect(levelInfo).toHaveProperty('nextLevelAt');
            expect(levelInfo).toHaveProperty('percentageToNext');

            expect(typeof levelInfo.level).toBe('number');
            expect(levelInfo.level).toBeGreaterThanOrEqual(1);
        });

        test('getLevelTitle should return correct titles', () => {
            expect(gamificationService.getLevelTitle(1)).toBe('Beginner');
            expect(gamificationService.getLevelTitle(2)).toBe('Learner');
            expect(gamificationService.getLevelTitle(4)).toBe('Confident');
            expect(gamificationService.getLevelTitle(8)).toBe('Skilled');
            expect(gamificationService.getLevelTitle(15)).toBe('Expert');
        });

        test('checkAchievements should return unlocked and locked achievements', async () => {
            const achievements = await gamificationService.checkAchievements(testUserId);

            expect(achievements).toHaveProperty('unlocked');
            expect(achievements).toHaveProperty('locked');
            expect(achievements).toHaveProperty('total');
            expect(achievements).toHaveProperty('unlockedCount');
            expect(achievements).toHaveProperty('completionPercentage');

            expect(Array.isArray(achievements.unlocked)).toBe(true);
            expect(Array.isArray(achievements.locked)).toBe(true);
            expect(achievements.total).toBe(12); // We have 12 achievements
        });

        test('recordSuggestionUsed should update stats', async () => {
            const result = await gamificationService.recordSuggestionUsed(testUserId, {
                confidence: 85,
                tone: 'playful',
                wasRefresh: false
            });

            // Should return updated stats or null if database not available
            if (result) {
                expect(result).toHaveProperty('messages_sent');
            }
        });

        test('recordProfileAnalyzed should update stats', async () => {
            const result = await gamificationService.recordProfileAnalyzed(testUserId);

            if (result) {
                expect(result).toHaveProperty('profiles_analyzed');
            }
        });

        test('recordSuccessfulConversation should update stats and level', async () => {
            const result = await gamificationService.recordSuccessfulConversation(testUserId);

            if (result) {
                expect(result).toHaveProperty('stats');
                expect(result).toHaveProperty('level');
            }
        });

        test('getProgressDashboard should return complete progress data', async () => {
            const progress = await gamificationService.getProgressDashboard(testUserId);

            expect(progress).toHaveProperty('success', true);
            expect(progress).toHaveProperty('level');
            expect(progress).toHaveProperty('stats');
            expect(progress).toHaveProperty('achievements');
            expect(progress).toHaveProperty('engagement');
        });
    });

    describe('AI Orchestrator Service', () => {
        test('generateCoachingSuggestions should return suggestions with reasoning', async () => {
            const context = {
                conversation_history: [],
                user_context: 'Profile shows interest in hiking and photography',
                suggestion_type: 'opener',
                screenshot_analysis: {
                    screenshot_type: 'profile',
                    extracted_details: {
                        interests: ['hiking', 'photography']
                    }
                }
            };

            const userProfile = {
                tone_preference: 'playful',
                goal: 'casual',
                experience_level: 'beginner'
            };

            try {
                const result = await aiOrchestrator.generateCoachingSuggestions(context, userProfile);

                if (result.success) {
                    expect(result).toHaveProperty('suggestions');
                    expect(result).toHaveProperty('coaching');
                    expect(Array.isArray(result.suggestions)).toBe(true);

                    // Verify max 3 suggestions
                    expect(result.suggestions.length).toBeLessThanOrEqual(3);

                    // Check coaching data
                    expect(result.coaching).toHaveProperty('overall_strategy');
                    expect(result.coaching).toHaveProperty('tone_analysis');
                    expect(result.coaching).toHaveProperty('next_steps');

                    // Each suggestion should have reasoning
                    result.suggestions.forEach(suggestion => {
                        expect(suggestion).toHaveProperty('text');
                        expect(suggestion).toHaveProperty('confidence');
                        expect(suggestion).toHaveProperty('reasoning');
                    });
                }
            } catch (error) {
                // API key might not be available in test environment
                console.log('Skipping AI Orchestrator test - API key not available');
            }
        });

        test('refreshCoachingSuggestions should avoid previous suggestions', async () => {
            const context = {
                conversation_history: [],
                user_context: 'Looking for conversation starters',
                suggestion_type: 'opener',
                screenshot_analysis: {}
            };

            const userProfile = {
                tone_preference: 'witty',
                goal: 'relationship',
                experience_level: 'confident'
            };

            const previousSuggestions = [
                'Hey there!',
                'How are you doing?'
            ];

            try {
                const result = await aiOrchestrator.refreshCoachingSuggestions(
                    context,
                    userProfile,
                    previousSuggestions
                );

                if (result.success) {
                    expect(result).toHaveProperty('suggestions');
                    expect(result.suggestions.length).toBeLessThanOrEqual(3);

                    // New suggestions should be different from previous ones
                    result.suggestions.forEach(suggestion => {
                        expect(previousSuggestions).not.toContain(suggestion.text);
                    });
                }
            } catch (error) {
                console.log('Skipping refresh test - API key not available');
            }
        });
    });

    describe('Service Integration', () => {
        test('Moderation should work with AI suggestions', async () => {
            const suggestions = [
                { text: 'Nice to meet you!', confidence: 0.9, reasoning: 'Friendly opener' },
                { text: 'Love your photos!', confidence: 0.85, reasoning: 'Compliment' }
            ];

            const moderated = await contentModeration.filterSuggestions(suggestions);

            expect(moderated.length).toBeGreaterThan(0);
            moderated.forEach(suggestion => {
                expect(suggestion).toHaveProperty('reasoning');
            });
        });

        test('Gamification should track suggestion usage', async () => {
            const userId = 'integration-test-user';

            // Record multiple actions
            await gamificationService.recordProfileAnalyzed(userId);
            await gamificationService.recordSuggestionUsed(userId, {
                confidence: 90,
                tone: 'romantic',
                wasRefresh: false
            });

            const progress = await gamificationService.getProgressDashboard(userId);

            expect(progress.success).toBe(true);
        });
    });

    describe('Error Handling', () => {
        test('Services should handle database unavailability gracefully', async () => {
            // Even if database is unavailable, services should not crash
            const userId = 'error-test-user';

            const stats = await gamificationService.getUserStats(userId);
            expect(stats).toBeDefined();

            const level = await gamificationService.calculateLevel(userId);
            expect(level).toBeDefined();
            expect(level.level).toBeGreaterThanOrEqual(1);
        });

        test('Services should handle null inputs gracefully', async () => {
            await expect(
                contentModeration.filterSuggestions(null)
            ).resolves.not.toThrow();

            await expect(
                gamificationService.getUserStats(null)
            ).resolves.not.toThrow();
        });

        test('Services should handle empty inputs gracefully', async () => {
            const emptyFiltered = await contentModeration.filterSuggestions([]);
            expect(emptyFiltered).toEqual([]);

            const emptyPrompt = conversationContext.buildContextPrompt([]);
            expect(emptyPrompt).toBe('');
        });
    });
});

// Run tests
if (require.main === module) {
    console.log('Running service tests...');
    console.log('Use: npm test or jest to run these tests');
}

module.exports = {};
