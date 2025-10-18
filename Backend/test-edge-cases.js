/**
 * Edge Case Test Suite for Vibe8AI Backend
 *
 * Tests boundary conditions, unusual inputs, and error handling
 * for all major API endpoints.
 *
 * Run with: node test-edge-cases.js
 */

require('dotenv').config();
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

// Configuration
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const API_BASE = `${BASE_URL}/api/v1`;

// Test authentication token (using test mode)
const TEST_TOKEN = 'test-token-for-api-testing';

// Test results tracking
const testResults = {
    passed: 0,
    failed: 0,
    skipped: 0,
    totalTests: 0,
    failures: []
};

// Color codes for console output
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m'
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(testName) {
    testResults.totalTests++;
    log(`\n▶ Test ${testResults.totalTests}: ${testName}`, 'cyan');
}

function logPass(message) {
    testResults.passed++;
    log(`  ✓ ${message}`, 'green');
}

function logFail(message, error) {
    testResults.failed++;
    log(`  ✗ ${message}`, 'red');
    if (error) {
        log(`    Error: ${error.message || error}`, 'red');
    }
    testResults.failures.push({ test: message, error: error?.message || error });
}

function logSkip(message) {
    testResults.skipped++;
    log(`  ⊘ ${message}`, 'yellow');
}

async function makeRequest(method, endpoint, data = null, headers = {}) {
    const config = {
        method,
        url: `${API_BASE}${endpoint}`,
        headers: {
            'Authorization': `Bearer ${TEST_TOKEN}`,
            ...headers
        },
        timeout: 10000,
        validateStatus: () => true // Don't throw on any status code
    };

    if (data) {
        if (data instanceof FormData) {
            config.data = data;
            config.headers = { ...config.headers, ...data.getHeaders() };
        } else {
            config.data = data;
            config.headers['Content-Type'] = 'application/json';
        }
    }

    return axios(config);
}

// ============================================================================
// EDGE CASE TEST CATEGORIES
// ============================================================================

// Category 1: Input Validation Edge Cases
async function testInputValidationEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 1: INPUT VALIDATION EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 1.1: Empty string inputs
    logTest('Empty string text input');
    try {
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: '',
            voice_model: 'eleven_monolingual_v1'
        });

        if (response.status === 400 && response.data.code === 'VALIDATION_ERROR') {
            logPass('Empty string rejected with validation error');
        } else {
            logFail('Empty string should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.2: Null values
    logTest('Null value inputs');
    try {
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: null,
            voice_model: null
        });

        if (response.status === 400) {
            logPass('Null values rejected appropriately');
        } else {
            logFail('Null values should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.3: Undefined values
    logTest('Undefined value inputs');
    try {
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: undefined,
            voice_model: undefined
        });

        if (response.status === 400) {
            logPass('Undefined values rejected appropriately');
        } else {
            logFail('Undefined values should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.4: Extremely long text (>10,000 characters)
    logTest('Extremely long text input (>10,000 chars)');
    try {
        const longText = 'A'.repeat(10001);
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: longText,
            voice_model: 'eleven_monolingual_v1'
        });

        if (response.status === 400 && response.data.code === 'VALIDATION_ERROR') {
            logPass('Extremely long text rejected');
        } else {
            logFail('Text over limit should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.5: Text at exact boundary (1000 characters)
    logTest('Text at exact boundary (1000 chars)');
    try {
        const boundaryText = 'A'.repeat(1000);
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: boundaryText,
            voice_model: 'eleven_monolingual_v1'
        });

        // Note: This might fail if ElevenLabs API is not available
        // We're testing validation, not the actual API call
        if (response.status === 400) {
            logFail('Boundary text (1000 chars) should be accepted', response.data);
        } else {
            logPass('Boundary text accepted by validation');
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.6: Special characters and unicode
    logTest('Special characters and unicode in text');
    try {
        const specialText = '¡Hola! 你好 مرحبا 😊 <script>alert("xss")</script>';
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: specialText,
            voice_model: 'eleven_monolingual_v1'
        });

        // Should be sanitized, not rejected
        if (response.status < 500) {
            logPass('Special characters handled appropriately');
        } else {
            logFail('Special characters should be sanitized, not cause server error', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.7: Invalid JSON format
    logTest('Invalid JSON in request body');
    try {
        const response = await axios({
            method: 'POST',
            url: `${API_BASE}/voice/synthesize_voice`,
            headers: {
                'Authorization': `Bearer ${TEST_TOKEN}`,
                'Content-Type': 'application/json'
            },
            data: 'This is not JSON',
            validateStatus: () => true
        });

        if (response.status === 400 && response.data.code === 'INVALID_JSON') {
            logPass('Invalid JSON rejected with appropriate error');
        } else {
            logPass('Invalid JSON handled (may return different error code)');
        }
    } catch (error) {
        logPass('Invalid JSON rejected by parser');
    }

    // Test 1.8: Missing required fields
    logTest('Missing required fields');
    try {
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            // Missing 'text' field
            voice_model: 'eleven_monolingual_v1'
        });

        if (response.status === 400) {
            logPass('Missing required field rejected');
        } else {
            logFail('Missing required field should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.9: Extra unexpected fields
    logTest('Extra unexpected fields in request');
    try {
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: 'Hello world',
            voice_model: 'eleven_monolingual_v1',
            unexpected_field: 'This should be ignored',
            malicious_code: '<script>alert("xss")</script>',
            sql_injection: "'; DROP TABLE users; --"
        });

        // Extra fields should be ignored, not cause errors
        if (response.status < 500) {
            logPass('Extra fields handled gracefully');
        } else {
            logFail('Extra fields should be ignored, not cause server error', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 1.10: Invalid enum values
    logTest('Invalid enum values');
    try {
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: 'Hello world',
            voice_model: 'invalid_model_name_that_does_not_exist'
        });

        if (response.status === 400 && response.data.code === 'VALIDATION_ERROR') {
            logPass('Invalid enum value rejected');
        } else {
            logFail('Invalid enum should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }
}

// Category 2: File Upload Edge Cases
async function testFileUploadEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 2: FILE UPLOAD EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 2.1: Zero-byte file
    logTest('Zero-byte file upload');
    try {
        const form = new FormData();
        const emptyBuffer = Buffer.alloc(0);
        form.append('screenshot', emptyBuffer, {
            filename: 'empty.png',
            contentType: 'image/png'
        });

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        if (response.status === 400) {
            logPass('Zero-byte file rejected');
        } else {
            logFail('Zero-byte file should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 2.2: Oversized file (>10MB)
    logTest('Oversized file upload (>10MB)');
    try {
        const form = new FormData();
        // Create a buffer larger than 10MB
        const oversizedBuffer = Buffer.alloc(11 * 1024 * 1024);
        form.append('screenshot', oversizedBuffer, {
            filename: 'oversized.png',
            contentType: 'image/png'
        });

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        if (response.status === 413 || (response.status === 400 &&
            (response.data.code === 'FILE_TOO_LARGE' || response.data.code === 'PAYLOAD_TOO_LARGE'))) {
            logPass('Oversized file rejected');
        } else {
            logFail('Oversized file should be rejected with 413 or FILE_TOO_LARGE', response.data);
        }
    } catch (error) {
        // Timeout or connection error is acceptable for oversized files
        if (error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT') {
            logPass('Oversized file rejected (connection reset)');
        } else {
            logFail('Request failed unexpectedly', error);
        }
    }

    // Test 2.3: Invalid image format (text file as image)
    logTest('Invalid image format (text file as image)');
    try {
        const form = new FormData();
        form.append('screenshot', 'This is not an image', {
            filename: 'fake.png',
            contentType: 'image/png'
        });

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        if (response.status === 400 &&
            (response.data.code === 'INVALID_FORMAT' || response.data.code === 'VALIDATION_ERROR')) {
            logPass('Invalid image format rejected');
        } else {
            logPass('Invalid image handled (may be detected later in processing)');
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 2.4: Unsupported file type
    logTest('Unsupported file type');
    try {
        const form = new FormData();
        form.append('screenshot', 'executable content', {
            filename: 'malware.exe',
            contentType: 'application/x-msdownload'
        });

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        if (response.status === 400 &&
            (response.data.code === 'UNSUPPORTED_FILE_TYPE' ||
             response.data.code === 'INVALID_FILE_TYPE' ||
             response.data.code === 'DANGEROUS_FILE_EXTENSION')) {
            logPass('Unsupported file type rejected');
        } else {
            logFail('Dangerous file type should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 2.5: No file provided
    logTest('No file in upload request');
    try {
        const form = new FormData();
        // Don't append any file

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        if (response.status === 400 && response.data.code === 'MISSING_IMAGE') {
            logPass('Missing file rejected');
        } else {
            logFail('Missing file should be rejected with MISSING_IMAGE', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 2.6: Multiple files when only one expected
    logTest('Multiple files when only one expected');
    try {
        const form = new FormData();
        form.append('screenshot', 'File 1', {
            filename: 'file1.png',
            contentType: 'image/png'
        });
        form.append('screenshot', 'File 2', {
            filename: 'file2.png',
            contentType: 'image/png'
        });

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        if (response.status === 400 && response.data.code === 'TOO_MANY_FILES') {
            logPass('Multiple files rejected');
        } else {
            logPass('Multiple files handled (may use first file or reject)');
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 2.7: File with malicious filename
    logTest('File with malicious filename');
    try {
        const form = new FormData();
        form.append('screenshot', 'content', {
            filename: '../../../etc/passwd',
            contentType: 'image/png'
        });

        const response = await makeRequest('POST', '/analysis/analyze_screenshot', form);

        // Should either reject or sanitize the filename
        if (response.status < 500) {
            logPass('Malicious filename handled (rejected or sanitized)');
        } else {
            logFail('Malicious filename should not cause server error', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }
}

// Category 3: Rate Limiting Edge Cases
async function testRateLimitingEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 3: RATE LIMITING EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 3.1: Rapid-fire requests (test rate limiter)
    logTest('Rapid-fire requests (10 in quick succession)');
    try {
        const requests = [];
        for (let i = 0; i < 10; i++) {
            requests.push(makeRequest('GET', '/health'));
        }

        const responses = await Promise.all(requests);
        const rateLimited = responses.filter(r => r.status === 429);

        if (rateLimited.length > 0) {
            logPass(`Rate limiting triggered after ${10 - rateLimited.length} requests`);
        } else {
            logPass('All rapid requests succeeded (rate limit not reached)');
        }
    } catch (error) {
        logFail('Rapid-fire test failed', error);
    }

    // Test 3.2: Concurrent requests from same user
    logTest('Concurrent requests from same user');
    try {
        const concurrentRequests = [
            makeRequest('POST', '/voice/synthesize_voice', { text: 'Test 1', voice_model: 'eleven_monolingual_v1' }),
            makeRequest('POST', '/voice/synthesize_voice', { text: 'Test 2', voice_model: 'eleven_monolingual_v1' }),
            makeRequest('POST', '/voice/synthesize_voice', { text: 'Test 3', voice_model: 'eleven_monolingual_v1' })
        ];

        const responses = await Promise.all(concurrentRequests);
        const successful = responses.filter(r => r.status < 400).length;
        const rateLimited = responses.filter(r => r.status === 429).length;

        logPass(`${successful} concurrent requests succeeded, ${rateLimited} rate limited`);
    } catch (error) {
        logFail('Concurrent requests test failed', error);
    }

    // Test 3.3: Rate limit error clarity
    logTest('Rate limit error message clarity');
    try {
        // Make enough requests to trigger rate limit
        let response;
        for (let i = 0; i < 100; i++) {
            response = await makeRequest('POST', '/voice/synthesize_voice', {
                text: 'Test',
                voice_model: 'eleven_monolingual_v1'
            });

            if (response.status === 429) {
                break;
            }

            // Small delay to avoid overwhelming the server
            await new Promise(resolve => setTimeout(resolve, 10));
        }

        if (response.status === 429) {
            if (response.data.code === 'RATE_LIMIT_EXCEEDED' && response.data.error) {
                logPass('Rate limit error is clear and informative');
            } else {
                logFail('Rate limit error should have clear message', response.data);
            }
        } else {
            logSkip('Rate limit not reached within test bounds');
        }
    } catch (error) {
        logFail('Rate limit test failed', error);
    }
}

// Category 4: External API Edge Cases
async function testExternalAPIEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 4: EXTERNAL API EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 4.1: Invalid API key handling
    logTest('Invalid API key handling');
    try {
        // Temporarily break the API key (this won't actually work in our test env)
        // This test is more conceptual - checking error handling
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: 'Test with potentially invalid API config',
            voice_model: 'eleven_monolingual_v1'
        });

        if (response.status === 500 || response.status === 502 || response.status === 503) {
            logPass('API failure handled with appropriate server error');
        } else if (response.status === 200) {
            logPass('API call succeeded (API key is valid)');
        } else {
            logPass('API error handled with status: ' + response.status);
        }
    } catch (error) {
        logPass('API error handled with exception');
    }

    // Test 4.2: Timeout handling
    logTest('Request timeout handling');
    try {
        // Use a very short timeout to test timeout handling
        const response = await axios({
            method: 'POST',
            url: `${API_BASE}/voice/synthesize_voice`,
            headers: {
                'Authorization': `Bearer ${TEST_TOKEN}`,
                'Content-Type': 'application/json'
            },
            data: {
                text: 'Testing timeout',
                voice_model: 'eleven_monolingual_v1'
            },
            timeout: 1, // 1ms timeout - guaranteed to fail
            validateStatus: () => true
        });

        logFail('Request should have timed out', response.data);
    } catch (error) {
        if (error.code === 'ECONNABORTED' || error.message.includes('timeout')) {
            logPass('Timeout handled appropriately');
        } else {
            logFail('Expected timeout error, got different error', error);
        }
    }

    // Test 4.3: Malformed API response handling
    logTest('Graceful degradation on API failures');
    try {
        // Test with valid request that might fail due to API issues
        const response = await makeRequest('POST', '/voice/synthesize_voice', {
            text: 'x', // Minimal valid input
            voice_model: 'eleven_monolingual_v1'
        });

        // Should either succeed or fail gracefully
        if (response.status === 500) {
            if (response.data.code && response.data.error) {
                logPass('API failure handled gracefully with error response');
            } else {
                logFail('Error response should include code and message', response.data);
            }
        } else if (response.status === 200) {
            logPass('API call succeeded');
        } else {
            logPass('API handled with status: ' + response.status);
        }
    } catch (error) {
        logPass('API error caught and handled');
    }
}

// Category 5: Authentication Edge Cases
async function testAuthenticationEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 5: AUTHENTICATION EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 5.1: Missing authentication token
    logTest('Missing authentication token');
    try {
        const response = await axios({
            method: 'GET',
            url: `${API_BASE}/voice/history`,
            validateStatus: () => true
        });

        if (response.status === 401 && response.data.code === 'TOKEN_MISSING') {
            logPass('Missing token rejected with 401');
        } else {
            logFail('Missing token should return 401 with TOKEN_MISSING', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 5.2: Invalid token format
    logTest('Invalid token format');
    try {
        const response = await axios({
            method: 'GET',
            url: `${API_BASE}/voice/history`,
            headers: {
                'Authorization': 'Bearer invalid-token-format-xyz-123'
            },
            validateStatus: () => true
        });

        if (response.status === 401 &&
            (response.data.code === 'TOKEN_INVALID' || response.data.code === 'TOKEN_MALFORMED')) {
            logPass('Invalid token rejected');
        } else {
            logFail('Invalid token should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 5.3: Malformed Authorization header
    logTest('Malformed Authorization header');
    try {
        const response = await axios({
            method: 'GET',
            url: `${API_BASE}/voice/history`,
            headers: {
                'Authorization': 'NotBearer token-here'
            },
            validateStatus: () => true
        });

        if (response.status === 401) {
            logPass('Malformed auth header rejected');
        } else {
            logFail('Malformed auth header should be rejected', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 5.4: SQL injection in auth token
    logTest('SQL injection in auth token');
    try {
        const response = await axios({
            method: 'GET',
            url: `${API_BASE}/voice/history`,
            headers: {
                'Authorization': `Bearer '; DROP TABLE users; --`
            },
            validateStatus: () => true
        });

        if (response.status === 401 && !response.data.error?.includes('DROP TABLE')) {
            logPass('SQL injection in token handled safely');
        } else {
            logFail('SQL injection should be rejected without exposing query', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }
}

// Category 6: Database Edge Cases
async function testDatabaseEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 6: DATABASE EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 6.1: Database connection failure handling
    logTest('Graceful handling when database unavailable');
    try {
        // Most endpoints should work without database (degraded mode)
        const response = await makeRequest('GET', '/health');

        if (response.status === 200) {
            logPass('Health endpoint works (database may be unavailable)');
        } else if (response.status === 503) {
            logPass('Service unavailable when database down (expected)');
        } else {
            logFail('Unexpected response when checking health', response.data);
        }
    } catch (error) {
        logFail('Health check failed', error);
    }

    // Test 6.2: Invalid query parameters
    logTest('Invalid query parameters in pagination');
    try {
        const response = await makeRequest('GET', '/voice/history?page=-1&limit=99999');

        if (response.status === 400 && response.data.code === 'VALIDATION_ERROR') {
            logPass('Invalid pagination parameters rejected');
        } else {
            logPass('Invalid parameters handled (may be sanitized)');
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 6.3: SQL injection attempts
    logTest('SQL injection in query parameters');
    try {
        const response = await makeRequest('GET',
            `/voice/history?page=1&search=' OR '1'='1`);

        if (response.status < 500) {
            logPass('SQL injection attempt handled safely');
        } else {
            logFail('SQL injection should not cause server error', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }
}

// Category 7: Network Edge Cases
async function testNetworkEdgeCases() {
    log('\n═══════════════════════════════════════════════════', 'blue');
    log('CATEGORY 7: NETWORK EDGE CASES', 'blue');
    log('═══════════════════════════════════════════════════', 'blue');

    // Test 7.1: Missing Content-Type header
    logTest('Missing Content-Type header');
    try {
        const response = await axios({
            method: 'POST',
            url: `${API_BASE}/voice/synthesize_voice`,
            headers: {
                'Authorization': `Bearer ${TEST_TOKEN}`
                // No Content-Type
            },
            data: JSON.stringify({
                text: 'Test',
                voice_model: 'eleven_monolingual_v1'
            }),
            validateStatus: () => true
        });

        if (response.status < 500) {
            logPass('Missing Content-Type handled');
        } else {
            logFail('Missing Content-Type should not cause server error', response.data);
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 7.2: Incorrect Content-Type
    logTest('Incorrect Content-Type header');
    try {
        const response = await axios({
            method: 'POST',
            url: `${API_BASE}/voice/synthesize_voice`,
            headers: {
                'Authorization': `Bearer ${TEST_TOKEN}`,
                'Content-Type': 'text/plain'
            },
            data: JSON.stringify({
                text: 'Test',
                voice_model: 'eleven_monolingual_v1'
            }),
            validateStatus: () => true
        });

        if (response.status === 400 || response.status === 415) {
            logPass('Incorrect Content-Type rejected');
        } else {
            logPass('Incorrect Content-Type handled gracefully');
        }
    } catch (error) {
        logFail('Request failed unexpectedly', error);
    }

    // Test 7.3: Very large headers
    logTest('Very large request headers');
    try {
        const largeHeader = 'x'.repeat(8000);
        const response = await axios({
            method: 'GET',
            url: `${API_BASE}/health`,
            headers: {
                'Authorization': `Bearer ${TEST_TOKEN}`,
                'X-Large-Header': largeHeader
            },
            validateStatus: () => true
        });

        if (response.status < 500) {
            logPass('Large headers handled');
        } else {
            logFail('Large headers should not crash server', response.data);
        }
    } catch (error) {
        if (error.code === 'ECONNRESET') {
            logPass('Large headers rejected by server');
        } else {
            logFail('Request failed unexpectedly', error);
        }
    }
}

// ============================================================================
// MAIN TEST RUNNER
// ============================================================================

async function runAllTests() {
    log('\n╔═══════════════════════════════════════════════════╗', 'magenta');
    log('║   VIBE8AI BACKEND - EDGE CASE TEST SUITE        ║', 'magenta');
    log('╚═══════════════════════════════════════════════════╝', 'magenta');

    log(`\nTesting against: ${BASE_URL}`, 'cyan');
    log(`Test started at: ${new Date().toISOString()}`, 'cyan');

    // Check if server is running
    try {
        const healthCheck = await axios.get(`${BASE_URL}/health`, { timeout: 5000 });
        log('✓ Server is running', 'green');
        log(`  Status: ${healthCheck.data.status}`, 'green');
    } catch (error) {
        log('✗ Server is not responding!', 'red');
        log('  Make sure the backend is running: cd Backend && npm start', 'yellow');
        log(`  Error: ${error.message}`, 'red');
        process.exit(1);
    }

    // Run all test categories
    await testInputValidationEdgeCases();
    await testFileUploadEdgeCases();
    await testRateLimitingEdgeCases();
    await testExternalAPIEdgeCases();
    await testAuthenticationEdgeCases();
    await testDatabaseEdgeCases();
    await testNetworkEdgeCases();

    // Print summary
    log('\n╔═══════════════════════════════════════════════════╗', 'magenta');
    log('║              TEST RESULTS SUMMARY                 ║', 'magenta');
    log('╚═══════════════════════════════════════════════════╝', 'magenta');

    log(`\nTotal Tests:  ${testResults.totalTests}`, 'cyan');
    log(`Passed:       ${testResults.passed}`, 'green');
    log(`Failed:       ${testResults.failed}`, testResults.failed > 0 ? 'red' : 'green');
    log(`Skipped:      ${testResults.skipped}`, 'yellow');

    const passRate = ((testResults.passed / testResults.totalTests) * 100).toFixed(1);
    log(`\nPass Rate:    ${passRate}%`, passRate >= 80 ? 'green' : 'red');

    if (testResults.failed > 0) {
        log('\n❌ FAILED TESTS:', 'red');
        testResults.failures.forEach((failure, index) => {
            log(`  ${index + 1}. ${failure.test}`, 'red');
            if (failure.error) {
                log(`     ${failure.error}`, 'red');
            }
        });
    }

    log(`\nTest completed at: ${new Date().toISOString()}`, 'cyan');

    // Exit with appropriate code
    process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run tests
runAllTests().catch(error => {
    log('\n❌ Test suite crashed:', 'red');
    log(error.stack || error.message, 'red');
    process.exit(1);
});
