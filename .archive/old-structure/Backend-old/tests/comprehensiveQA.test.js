/**
 * Comprehensive QA Testing Framework
 * Tests different photo types, scenarios, and quality assurance pipeline
 */

const request = require('supertest');
const path = require('path');
const fs = require('fs').promises;

// Import services for testing
const qualityAssurance = require('../services/qualityAssurance');
const errorRecovery = require('../services/errorRecovery');

// Disable console logging during tests
process.env.LOG_LEVEL = 'error';
process.env.NODE_ENV = 'test';

describe('Comprehensive QA Testing Framework', () => {
    let app;
    let server;

    beforeAll(async () => {
        // Import app after setting env vars
        app = require('../server');

        // Start server on a test port
        await new Promise((resolve) => {
            server = app.listen(3002, resolve);
        });
    });

    afterAll(async () => {
        // Close server
        await new Promise((resolve) => {
            server.close(resolve);
        });

        // Clean up
        if (global.redisCleanupInterval) {
            clearInterval(global.redisCleanupInterval);
        }
    });

    describe('Quality Assurance Pipeline', () => {
        describe('Response Validation', () => {
            test('should validate suggestion structure', async () => {
                const validSuggestions = [
                    {
                        text: "Hey! Your photo caught my attention - what's the story behind that adventure?",
                        confidence: 0.85,
                        reasoning: "Photo-specific opener"
                    },
                    {
                        text: "I love your energy in that picture! What got you into hiking?",
                        confidence: 0.82,
                        reasoning: "Interest-based follow-up"
                    }
                ];

                const context = {
                    suggestion_type: 'opener',
                    tone: 'playful'
                };

                const result = await qualityAssurance.validateResponse(validSuggestions, context, 'test-correlation-1');

                expect(result.qualityMetrics.validationPassed).toBe(true);
                expect(result.suggestions.length).toBeGreaterThan(0);
                expect(result.qualityMetrics.averageQualityScore).toBeGreaterThan(0.7);
            });

            test('should reject low-quality suggestions', async () => {
                const lowQualitySuggestions = [
                    {
                        text: "Hi",
                        confidence: 0.3,
                        reasoning: "Too short"
                    },
                    {
                        text: "Generic pickup line that everyone uses",
                        confidence: 0.4,
                        reasoning: "Generic content"
                    }
                ];

                const context = {
                    suggestion_type: 'opener',
                    tone: 'playful'
                };

                const result = await qualityAssurance.validateResponse(lowQualitySuggestions, context, 'test-correlation-2');

                // Should provide fallbacks for low quality
                expect(result.suggestions.length).toBeGreaterThanOrEqual(3);
                expect(result.qualityMetrics.finalCount).toBeGreaterThanOrEqual(3);
            });

            test('should detect and remove duplicates', async () => {
                const duplicateSuggestions = [
                    {
                        text: "Hey! Your photo caught my attention - what's the story behind that adventure?",
                        confidence: 0.85,
                        reasoning: "Photo-specific opener"
                    },
                    {
                        text: "Hey! Your photo caught my attention - what's the story behind that adventure?",
                        confidence: 0.83,
                        reasoning: "Duplicate"
                    },
                    {
                        text: "I love your energy in that picture! What got you into hiking?",
                        confidence: 0.82,
                        reasoning: "Unique suggestion"
                    }
                ];

                const context = {
                    suggestion_type: 'opener',
                    tone: 'playful'
                };

                const result = await qualityAssurance.validateResponse(duplicateSuggestions, context, 'test-correlation-3');

                expect(result.validationResults.duplicates.duplicatesFound).toBeGreaterThan(0);
                expect(result.suggestions.length).toBeLessThan(duplicateSuggestions.length);
            });
        });

        describe('Content Quality Scoring', () => {
            test('should score personalized content higher', async () => {
                const personalizedSuggestion = {
                    text: "I love your hiking photo! What trail is that? I'm always looking for new adventures.",
                    confidence: 0.8
                };

                const genericSuggestion = {
                    text: "Hi there, how are you doing today?",
                    confidence: 0.8
                };

                const personalizedScored = qualityAssurance.generateQualityScores([personalizedSuggestion], { tone: 'playful' });
                const genericScored = qualityAssurance.generateQualityScores([genericSuggestion], { tone: 'playful' });

                expect(personalizedScored[0].qualityScore).toBeGreaterThan(genericScored[0].qualityScore);
                expect(personalizedScored[0].componentScores.personalization).toBeGreaterThan(0.5);
            });

            test('should score engaging content higher', async () => {
                const engagingSuggestion = {
                    text: "What's been the most exciting part of your week? You seem like someone with great stories!",
                    confidence: 0.8
                };

                const flatSuggestion = {
                    text: "Hello, nice to meet you.",
                    confidence: 0.8
                };

                const engagingScored = qualityAssurance.generateQualityScores([engagingSuggestion], { tone: 'playful' });
                const flatScored = qualityAssurance.generateQualityScores([flatSuggestion], { tone: 'playful' });

                expect(engagingScored[0].qualityScore).toBeGreaterThan(flatScored[0].qualityScore);
                expect(engagingScored[0].componentScores.engagement).toBeGreaterThan(0.3);
            });
        });
    });

    describe('Error Recovery Testing', () => {
        test('should recover from API timeout errors', async () => {
            const timeoutError = new Error('Request timeout');
            timeoutError.code = 'ETIMEDOUT';

            const context = {
                suggestion_type: 'opener',
                tone: 'playful',
                payload: {
                    max_tokens: 1000,
                    temperature: 0.7
                }
            };

            const recovery = await errorRecovery.recoverFromError(timeoutError, context, 'test-recovery-1');

            expect(recovery.success).toBe(true);
            expect(recovery.action).toBeDefined();
        });

        test('should handle rate limit errors with backoff', async () => {
            const rateLimitError = new Error('Rate limit exceeded');
            rateLimitError.status = 429;
            rateLimitError.response = {
                headers: {
                    'retry-after': '5'
                }
            };

            const context = {
                suggestion_type: 'opener',
                tone: 'playful'
            };

            const recovery = await errorRecovery.recoverFromError(rateLimitError, context, 'test-recovery-2');

            expect(recovery.success).toBe(true);
            expect(['retry', 'fallback', 'emergency']).toContain(recovery.action);
        });

        test('should recover from JSON parse errors', async () => {
            const parseError = new Error('Unexpected token in JSON');
            parseError.rawResponse = '{"suggestions": [{"text": "Hello, broken json"';

            const context = {
                suggestion_type: 'opener',
                tone: 'playful'
            };

            const recovery = await errorRecovery.recoverFromError(parseError, context, 'test-recovery-3');

            expect(recovery.success).toBe(true);
        });
    });

    describe('Photo Type Testing', () => {
        describe('Outdoor Adventure Photos', () => {
            test('should generate adventure-focused suggestions', async () => {
                const response = await request(app)
                    .post('/api/v1/flirts/analyze_screenshot')
                    .send({
                        context_hint: 'hiking photo with mountains and backpack, outdoor adventure',
                        image_url: 'test://adventure-photo.jpg'
                    });

                expect(response.status).toBe(200);
                expect(response.body.success).toBe(true);
                expect(response.body.analysis.key_elements).toContain('hiking photo with mountains and backpack, outdoor adventure');

                // Now generate suggestions based on this analysis
                const suggestionsResponse = await request(app)
                    .post('/api/v1/flirts/generate_flirts')
                    .send({
                        screenshot_id: response.body.screenshot_id,
                        suggestion_type: 'opener',
                        tone: 'playful',
                        context: 'outdoor adventure hiking photo'
                    });

                expect(suggestionsResponse.status).toBe(200);
                expect(suggestionsResponse.body.success).toBe(true);
                expect(suggestionsResponse.body.data.suggestions.length).toBeGreaterThan(0);

                // Check if suggestions are adventure-related
                const suggestionTexts = suggestionsResponse.body.data.suggestions.map(s => s.text.toLowerCase());
                const hasAdventureContent = suggestionTexts.some(text =>
                    text.includes('adventure') ||
                    text.includes('hiking') ||
                    text.includes('trail') ||
                    text.includes('outdoors') ||
                    text.includes('mountain')
                );

                expect(hasAdventureContent).toBe(true);
            });
        });

        describe('Professional Headshots', () => {
            test('should generate professional-appropriate suggestions', async () => {
                const response = await request(app)
                    .post('/api/v1/flirts/analyze_screenshot')
                    .send({
                        context_hint: 'professional headshot, business attire, office background',
                        image_url: 'test://professional-photo.jpg'
                    });

                expect(response.status).toBe(200);
                expect(response.body.success).toBe(true);

                const suggestionsResponse = await request(app)
                    .post('/api/v1/flirts/generate_flirts')
                    .send({
                        screenshot_id: response.body.screenshot_id,
                        suggestion_type: 'opener',
                        tone: 'casual',
                        context: 'professional headshot business setting'
                    });

                expect(suggestionsResponse.status).toBe(200);
                expect(suggestionsResponse.body.success).toBe(true);

                // Suggestions should be professional and respectful
                const suggestionTexts = suggestionsResponse.body.data.suggestions.map(s => s.text.toLowerCase());
                const isAppropriate = suggestionTexts.every(text =>
                    !text.includes('hot') &&
                    !text.includes('sexy') &&
                    !text.includes('gorgeous')
                );

                expect(isAppropriate).toBe(true);
            });
        });

        describe('Casual Lifestyle Shots', () => {
            test('should generate lifestyle-focused suggestions', async () => {
                const response = await request(app)
                    .post('/api/v1/flirts/analyze_screenshot')
                    .send({
                        context_hint: 'casual photo at coffee shop, reading book, relaxed setting',
                        image_url: 'test://lifestyle-photo.jpg'
                    });

                expect(response.status).toBe(200);

                const suggestionsResponse = await request(app)
                    .post('/api/v1/flirts/generate_flirts')
                    .send({
                        screenshot_id: response.body.screenshot_id,
                        suggestion_type: 'opener',
                        tone: 'casual',
                        context: 'coffee shop reading lifestyle'
                    });

                expect(suggestionsResponse.status).toBe(200);

                const suggestionTexts = suggestionsResponse.body.data.suggestions.map(s => s.text.toLowerCase());
                const hasLifestyleContent = suggestionTexts.some(text =>
                    text.includes('coffee') ||
                    text.includes('book') ||
                    text.includes('reading') ||
                    text.includes('relax')
                );

                expect(hasLifestyleContent).toBe(true);
            });
        });

        describe('Group Photos', () => {
            test('should handle group photos appropriately', async () => {
                const response = await request(app)
                    .post('/api/v1/flirts/analyze_screenshot')
                    .send({
                        context_hint: 'group photo with friends at party, multiple people',
                        image_url: 'test://group-photo.jpg'
                    });

                expect(response.status).toBe(200);

                const suggestionsResponse = await request(app)
                    .post('/api/v1/flirts/generate_flirts')
                    .send({
                        screenshot_id: response.body.screenshot_id,
                        suggestion_type: 'opener',
                        tone: 'playful',
                        context: 'group photo with friends'
                    });

                expect(suggestionsResponse.status).toBe(200);

                // Should generate suggestions that acknowledge it's a group photo
                const suggestionTexts = suggestionsResponse.body.data.suggestions.map(s => s.text.toLowerCase());
                const acknowledgesGroup = suggestionTexts.some(text =>
                    text.includes('friend') ||
                    text.includes('group') ||
                    text.includes('which one') ||
                    text.includes('you and your')
                );

                // At least one suggestion should acknowledge the group context
                expect(acknowledgesGroup).toBe(true);
            });
        });

        describe('Low Quality/Blurry Images', () => {
            test('should handle low quality images gracefully', async () => {
                const response = await request(app)
                    .post('/api/v1/flirts/analyze_screenshot')
                    .send({
                        context_hint: 'blurry photo, low quality, hard to see details',
                        image_url: 'test://blurry-photo.jpg'
                    });

                expect(response.status).toBe(200);

                const suggestionsResponse = await request(app)
                    .post('/api/v1/flirts/generate_flirts')
                    .send({
                        screenshot_id: response.body.screenshot_id,
                        suggestion_type: 'opener',
                        tone: 'playful',
                        context: 'low quality blurry image'
                    });

                expect(suggestionsResponse.status).toBe(200);
                expect(suggestionsResponse.body.success).toBe(true);

                // Should still provide suggestions even with poor quality
                expect(suggestionsResponse.body.data.suggestions.length).toBeGreaterThanOrEqual(3);

                // Suggestions should be general rather than photo-specific
                const suggestionTexts = suggestionsResponse.body.data.suggestions.map(s => s.text);
                const isGeneralContent = suggestionTexts.some(text =>
                    !text.toLowerCase().includes('photo') ||
                    text.toLowerCase().includes('profile') ||
                    text.toLowerCase().includes('energy')
                );

                expect(isGeneralContent).toBe(true);
            });
        });
    });

    describe('Performance Benchmarking', () => {
        test('should generate suggestions within acceptable time limits', async () => {
            const startTime = Date.now();

            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .set('X-Keyboard-Extension', 'true')
                .send({
                    screenshot_id: 'test-screenshot-performance',
                    suggestion_type: 'opener',
                    tone: 'playful',
                    context: 'performance test'
                });

            const endTime = Date.now();
            const responseTime = endTime - startTime;

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);

            // Keyboard extension should respond quickly (under 10 seconds)
            expect(responseTime).toBeLessThan(10000);

            // Should have suggestions
            expect(response.body.data.suggestions.length).toBeGreaterThan(0);
        });

        test('should handle concurrent requests efficiently', async () => {
            const concurrentRequests = 5;
            const promises = [];

            for (let i = 0; i < concurrentRequests; i++) {
                const promise = request(app)
                    .post('/api/v1/flirts/generate_flirts')
                    .set('X-Keyboard-Extension', 'true')
                    .send({
                        screenshot_id: `test-concurrent-${i}`,
                        suggestion_type: 'opener',
                        tone: 'playful',
                        context: `concurrent test ${i}`
                    });

                promises.push(promise);
            }

            const startTime = Date.now();
            const responses = await Promise.all(promises);
            const endTime = Date.now();

            const totalTime = endTime - startTime;

            // All requests should succeed
            responses.forEach(response => {
                expect(response.status).toBe(200);
                expect(response.body.success).toBe(true);
            });

            // Concurrent requests shouldn't take much longer than single request
            expect(totalTime).toBeLessThan(15000);
        });
    });

    describe('Automated Success Rate Tracking', () => {
        test('should track and report success metrics', async () => {
            // Reset metrics before test
            qualityAssurance.resetMetrics();
            errorRecovery.resetMetrics();

            // Run several test requests
            const testRequests = 10;
            let successCount = 0;

            for (let i = 0; i < testRequests; i++) {
                try {
                    const response = await request(app)
                        .post('/api/v1/flirts/generate_flirts')
                        .set('X-Keyboard-Extension', 'true')
                        .send({
                            screenshot_id: `test-metrics-${i}`,
                            suggestion_type: 'opener',
                            tone: 'playful',
                            context: `metrics test ${i}`
                        });

                    if (response.status === 200 && response.body.success) {
                        successCount++;
                    }
                } catch (error) {
                    // Count as failure
                }
            }

            const successRate = (successCount / testRequests) * 100;
            expect(successRate).toBeGreaterThanOrEqual(80); // At least 80% success rate

            // Get QA metrics
            const qaMetrics = qualityAssurance.getMetrics();
            expect(qaMetrics.totalRequests).toBeGreaterThan(0);

            // Get recovery metrics
            const recoveryMetrics = errorRecovery.getRecoveryMetrics();
            expect(recoveryMetrics).toBeDefined();
        });
    });

    describe('Edge Cases and Stress Testing', () => {
        test('should handle empty screenshot ID gracefully', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    screenshot_id: '',
                    suggestion_type: 'opener',
                    tone: 'playful'
                });

            expect(response.status).toBe(400);
            expect(response.body.error).toContain('Screenshot ID is required');
        });

        test('should handle invalid suggestion types', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .set('X-Keyboard-Extension', 'true')
                .send({
                    screenshot_id: 'test-invalid-type',
                    suggestion_type: 'invalid_type',
                    tone: 'playful'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            // Should provide fallback suggestions even with invalid type
            expect(response.body.data.suggestions.length).toBeGreaterThan(0);
        });

        test('should handle extremely long context strings', async () => {
            const longContext = 'A'.repeat(5000); // 5000 character context

            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .set('X-Keyboard-Extension', 'true')
                .send({
                    screenshot_id: 'test-long-context',
                    suggestion_type: 'opener',
                    tone: 'playful',
                    context: longContext
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.suggestions.length).toBeGreaterThan(0);
        });
    });
});

// Test helper functions
const TestHelpers = {
    /**
     * Create test photo analysis data
     */
    createTestPhotoAnalysis(type) {
        const analyses = {
            outdoor: {
                conversation_type: "profile",
                profile_detected: true,
                conversation_context: "profile_view",
                user_sentiment: "excited",
                suggested_response_tone: "playful",
                key_elements: ["outdoor", "adventure", "hiking", "nature"],
                confidence: 0.85,
                analysis_notes: "Outdoor adventure photo detected"
            },
            professional: {
                conversation_type: "profile",
                profile_detected: true,
                conversation_context: "profile_view",
                user_sentiment: "neutral",
                suggested_response_tone: "casual",
                key_elements: ["professional", "business", "headshot"],
                confidence: 0.80,
                analysis_notes: "Professional headshot detected"
            },
            lifestyle: {
                conversation_type: "profile",
                profile_detected: true,
                conversation_context: "profile_view",
                user_sentiment: "interested",
                suggested_response_tone: "casual",
                key_elements: ["coffee", "lifestyle", "casual", "relaxed"],
                confidence: 0.82,
                analysis_notes: "Casual lifestyle photo detected"
            },
            group: {
                conversation_type: "profile",
                profile_detected: true,
                conversation_context: "profile_view",
                user_sentiment: "interested",
                suggested_response_tone: "playful",
                key_elements: ["group", "friends", "social", "party"],
                confidence: 0.75,
                analysis_notes: "Group photo with multiple people detected"
            },
            lowquality: {
                conversation_type: "profile",
                profile_detected: false,
                conversation_context: "profile_view",
                user_sentiment: "unknown",
                suggested_response_tone: "playful",
                key_elements: ["blurry", "low_quality"],
                confidence: 0.60,
                analysis_notes: "Low quality image, limited details available"
            }
        };

        return analyses[type] || analyses.lifestyle;
    },

    /**
     * Validate suggestion quality
     */
    validateSuggestionQuality(suggestion) {
        return {
            hasText: !!suggestion.text,
            adequateLength: suggestion.text && suggestion.text.length >= 10,
            hasConfidence: typeof suggestion.confidence === 'number',
            validConfidence: suggestion.confidence >= 0 && suggestion.confidence <= 1,
            hasReasoning: !!suggestion.reasoning
        };
    },

    /**
     * Calculate response time
     */
    async timeRequest(requestPromise) {
        const startTime = Date.now();
        const response = await requestPromise;
        const endTime = Date.now();
        return {
            response,
            responseTime: endTime - startTime
        };
    }
};

module.exports = TestHelpers;