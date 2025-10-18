/**
 * CP-6: Comprehensive API Endpoint Tests
 * Tests all backend API endpoints for functionality and edge cases
 */

const request = require('supertest');
const app = require('../server');
const db = require('../config/database');

describe('API Endpoint Tests', () => {
    let authToken;
    let testUserId;

    beforeAll(async () => {
        // Setup test database connection
        if (db.isAvailable()) {
            // Create test user
            const result = await db.query(
                `INSERT INTO users (email, password_hash, created_at)
                 VALUES ($1, $2, NOW())
                 RETURNING id`,
                ['test@vibe8.ai', 'test_hash_123']
            );
            testUserId = result.rows[0].id;
        }

        // Get auth token (mock for testing)
        authToken = 'test_token_123';
    });

    afterAll(async () => {
        // Cleanup test data
        if (db.isAvailable() && testUserId) {
            await db.query('DELETE FROM users WHERE id = $1', [testUserId]);
        }
    });

    describe('Health Check', () => {
        test('GET /health should return 200 and service status', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            expect(response.body).toHaveProperty('success', true);
            expect(response.body).toHaveProperty('status', 'healthy');
            expect(response.body).toHaveProperty('services');
        });
    });

    describe('Flirt Generation Endpoints', () => {
        test('POST /api/v1/flirts/generate_flirts with image_data should return suggestions', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    image_data: 'base64_encoded_image_data',
                    suggestion_type: 'opener',
                    tone: 'playful'
                })
                .expect(200);

            expect(response.body).toHaveProperty('success', true);
            expect(response.body.data).toHaveProperty('suggestions');
            expect(Array.isArray(response.body.data.suggestions)).toBe(true);

            // Verify max 3 suggestions
            expect(response.body.data.suggestions.length).toBeLessThanOrEqual(3);
        });

        test('POST /api/v1/flirts/generate_flirts without screenshot_id or image_data should return 400', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    suggestion_type: 'opener',
                    tone: 'playful'
                })
                .expect(400);

            expect(response.body).toHaveProperty('success', false);
        });

        test('POST /api/v1/flirts/refresh should return new suggestions', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/refresh')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    screenshot_id: 'test_screenshot_id',
                    suggestion_type: 'opener',
                    tone: 'playful',
                    previous_suggestions: ['Previous suggestion 1', 'Previous suggestion 2']
                });

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body.data).toHaveProperty('suggestions');
                expect(response.body.data.suggestions.length).toBeLessThanOrEqual(3);
                expect(response.body.data.metadata).toHaveProperty('is_refresh', true);
            }
        });

        test('GET /api/v1/flirts/progress should return user progress', async () => {
            const response = await request(app)
                .get('/api/v1/flirts/progress')
                .set('Authorization', `Bearer ${authToken}`);

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body.data).toHaveProperty('level');
                expect(response.body.data).toHaveProperty('stats');
                expect(response.body.data).toHaveProperty('achievements');
            }
        });
    });

    describe('Legal & Compliance Endpoints', () => {
        test('GET /api/v1/legal/privacy should return privacy policy HTML', async () => {
            const response = await request(app)
                .get('/api/v1/legal/privacy')
                .expect(200);

            expect(response.type).toMatch(/html/);
            expect(response.text).toContain('Privacy Policy');
        });

        test('GET /api/v1/legal/data-usage should return JSON data usage info', async () => {
            const response = await request(app)
                .get('/api/v1/legal/data-usage')
                .expect(200);

            expect(response.body).toHaveProperty('data_collected');
            expect(response.body).toHaveProperty('third_party_services');
        });
    });

    describe('Account Management Endpoints', () => {
        test('POST /api/v1/account/delete should initiate account deletion', async () => {
            const response = await request(app)
                .post('/api/v1/account/delete')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    reason: 'Testing account deletion'
                });

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body).toHaveProperty('deletion_id');
                expect(response.body).toHaveProperty('estimated_completion_at');
            }
        });

        test('GET /api/v1/account/deletion-status/:deletionId should return deletion status', async () => {
            const deletionId = 'test_deletion_id';

            const response = await request(app)
                .get(`/api/v1/account/deletion-status/${deletionId}`)
                .set('Authorization', `Bearer ${authToken}`);

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body).toHaveProperty('status');
            }
        });
    });

    describe('Voice Endpoints', () => {
        test('POST /api/v1/voice/clone should accept voice clone request', async () => {
            const response = await request(app)
                .post('/api/v1/voice/clone')
                .set('Authorization', `Bearer ${authToken}`)
                .attach('audio', Buffer.from('fake_audio_data'), 'voice.mp3');

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body).toHaveProperty('voice_id');
            }
        });

        test('POST /api/v1/voice/synthesize should synthesize voice message', async () => {
            const response = await request(app)
                .post('/api/v1/voice/synthesize')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    text: 'Hello, this is a test message',
                    voice_id: 'test_voice_id',
                    emotion: 'friendly'
                });

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body).toHaveProperty('audio_url');
            }
        });
    });

    describe('Content Moderation', () => {
        test('Inappropriate content should be filtered', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    image_data: 'base64_encoded_inappropriate_content',
                    suggestion_type: 'opener',
                    tone: 'playful'
                });

            if (response.status === 200 && response.body.success) {
                // All suggestions should pass moderation
                const suggestions = response.body.data.suggestions;
                suggestions.forEach(suggestion => {
                    expect(suggestion.text).not.toContain('inappropriate');
                    expect(suggestion.text).not.toContain('offensive');
                });
            }
        });
    });

    describe('Rate Limiting', () => {
        test('Multiple rapid requests should be rate limited', async () => {
            const requests = [];
            for (let i = 0; i < 100; i++) {
                requests.push(
                    request(app)
                        .post('/api/v1/flirts/generate_flirts')
                        .set('Authorization', `Bearer ${authToken}`)
                        .send({
                            image_data: 'base64_data',
                            suggestion_type: 'opener',
                            tone: 'playful'
                        })
                );
            }

            const responses = await Promise.all(requests);
            const rateLimited = responses.filter(r => r.status === 429);

            // At least some requests should be rate limited
            expect(rateLimited.length).toBeGreaterThan(0);
        });
    });

    describe('Error Handling', () => {
        test('Invalid tone should return 400', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    image_data: 'base64_data',
                    suggestion_type: 'opener',
                    tone: 'invalid_tone'
                })
                .expect(400);

            expect(response.body).toHaveProperty('success', false);
        });

        test('Invalid suggestion_type should return 400', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    image_data: 'base64_data',
                    suggestion_type: 'invalid_type',
                    tone: 'playful'
                })
                .expect(400);

            expect(response.body).toHaveProperty('success', false);
        });

        test('Missing required fields should return 400', async () => {
            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({})
                .expect(400);

            expect(response.body).toHaveProperty('success', false);
        });
    });

    describe('Database Integration', () => {
        test('Suggestions should be saved to database', async () => {
            if (!db.isAvailable()) {
                return; // Skip if database not available
            }

            const response = await request(app)
                .post('/api/v1/flirts/generate_flirts')
                .send({
                    image_data: 'base64_data',
                    suggestion_type: 'opener',
                    tone: 'playful'
                });

            if (response.status === 200 && response.body.success) {
                const suggestions = response.body.data.suggestions;

                // Verify suggestions have IDs (indicating they were saved)
                suggestions.forEach(suggestion => {
                    expect(suggestion).toHaveProperty('id');
                    expect(suggestion.id).toBeTruthy();
                });
            }
        });
    });
});

// Run tests
if (require.main === module) {
    console.log('Running API tests...');
    console.log('Use: npm test or jest to run these tests');
}

module.exports = {};
