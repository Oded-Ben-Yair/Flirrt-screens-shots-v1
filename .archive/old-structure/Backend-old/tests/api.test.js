const request = require('supertest');
const path = require('path');

// Disable console logging during tests
process.env.LOG_LEVEL = 'error';
process.env.NODE_ENV = 'test';

describe('Vibe8 API Endpoints', () => {
    let app;
    let server;

    beforeAll(async () => {
        // Import app after setting env vars
        app = require('../server');

        // Start server on a test port
        await new Promise((resolve) => {
            server = app.listen(3001, resolve);
        });
    });

    afterAll(async () => {
        // Close server
        await new Promise((resolve) => {
            server.close(resolve);
        });

        // Clean up any intervals or connections
        if (global.redisCleanupInterval) {
            clearInterval(global.redisCleanupInterval);
        }
    });

    describe('GET /health', () => {
        test('should return health status', async () => {
            const response = await request(app).get('/health');

            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('status', 'healthy');
            expect(response.body).toHaveProperty('uptime');
            expect(response.body).toHaveProperty('services');
        });
    });

    describe('POST /api/v1/generate_flirts', () => {
        test('should return fallback suggestions when keyboard extension header is present', async () => {
            const response = await request(app)
                .post('/api/v1/generate_flirts')
                .set('X-Keyboard-Extension', 'true')
                .send({
                    suggestion_type: 'opener'
                });

            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('success', true);
            expect(response.body).toHaveProperty('suggestions');
            expect(Array.isArray(response.body.suggestions)).toBe(true);
            expect(response.body.suggestions.length).toBeGreaterThan(0);
        });

        test('should require authentication without keyboard extension header', async () => {
            const response = await request(app)
                .post('/api/v1/generate_flirts')
                .send({
                    suggestion_type: 'opener'
                });

            // Should return 401 or similar auth error
            expect(response.status).toBeGreaterThanOrEqual(400);
        });
    });

    describe('GET /api/v1/suggestions/cached', () => {
        test('should return cached suggestions', async () => {
            const response = await request(app)
                .get('/api/v1/suggestions/cached')
                .set('X-Keyboard-Extension', 'true');

            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('suggestions');
            expect(Array.isArray(response.body.suggestions)).toBe(true);
        });
    });

    describe('POST /api/v1/voice/clone', () => {
        test('should reject voice cloning without auth', async () => {
            const response = await request(app)
                .post('/api/v1/voice/clone')
                .send({
                    text: 'Test voice clone'
                });

            expect(response.status).toBeGreaterThanOrEqual(400);
        });
    });

    describe('POST /api/v1/screenshot/analyze', () => {
        test('should reject screenshot analysis without auth', async () => {
            const response = await request(app)
                .post('/api/v1/screenshot/analyze')
                .send({});

            expect(response.status).toBeGreaterThanOrEqual(400);
        });
    });
});

// Simple test runner if running directly
if (require.main === module) {
    console.log('Running Vibe8 API tests...\n');

    const jest = require('jest');
    jest.run(['--testPathPattern=api.test.js', '--verbose'])
        .then(() => {
            console.log('\n✅ All tests completed');
            process.exit(0);
        })
        .catch((error) => {
            console.error('\n❌ Tests failed:', error);
            process.exit(1);
        });
}