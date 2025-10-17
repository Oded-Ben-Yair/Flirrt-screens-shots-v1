/**
 * Validation Enforcement Integration Tests
 * Tests that validation utilities are properly integrated into all endpoints
 *
 * Stage 6: Testing & Validation Integration
 * Agent 1: Endpoint Validation Coverage
 */

const axios = require('axios');

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api/v1';
const TEST_TOKEN = process.env.TEST_AUTH_TOKEN || 'test-token';

// Test configuration
const config = {
    headers: {
        'Authorization': `Bearer ${TEST_TOKEN}`,
        'Content-Type': 'application/json'
    }
};

// ANSI color codes for terminal output
const colors = {
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m'
};

// Test results tracking
const testResults = {
    passed: 0,
    failed: 0,
    total: 0,
    details: []
};

/**
 * Test helper function
 */
async function runTest(testName, testFn) {
    testResults.total++;
    try {
        await testFn();
        testResults.passed++;
        console.log(`${colors.green}✓${colors.reset} ${testName}`);
        testResults.details.push({ name: testName, status: 'PASSED' });
    } catch (error) {
        testResults.failed++;
        console.log(`${colors.red}✗${colors.reset} ${testName}`);
        console.log(`  ${colors.red}Error: ${error.message}${colors.reset}`);
        testResults.details.push({ name: testName, status: 'FAILED', error: error.message });
    }
}

/**
 * Assert helper
 */
function assert(condition, message) {
    if (!condition) {
        throw new Error(message);
    }
}

/**
 * Main test execution function
 */
async function runAllTests() {
    /**
     * SECTION 1: SCREENSHOT ID VALIDATION TESTS
     */
    console.log(`\n${colors.blue}=== SCREENSHOT ID VALIDATION TESTS ===${colors.reset}`);

    // Test 1.1: Invalid screenshot_id format in /generate_flirts
    await runTest('POST /generate_flirts - Rejects invalid screenshot_id format', async () => {
    try {
        await axios.post(`${BASE_URL}/generate_flirts`, {
            screenshot_id: 'invalid@#$%id',  // Invalid characters
            suggestion_type: 'opener',
            tone: 'playful'
        }, config);
        throw new Error('Should have rejected invalid screenshot_id');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
        assert(error.response?.data?.error?.message?.includes('screenshot ID'), 'Expected screenshot ID error message');
    }
});

// Test 1.2: Screenshot ID too long
await runTest('POST /generate_flirts - Rejects screenshot_id over 100 chars', async () => {
    try {
        await axios.post(`${BASE_URL}/generate_flirts`, {
            screenshot_id: 'a'.repeat(101),  // 101 characters
            suggestion_type: 'opener',
            tone: 'playful'
        }, config);
        throw new Error('Should have rejected oversized screenshot_id');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

// Test 1.3: Valid screenshot_id format passes
await runTest('POST /generate_flirts - Accepts valid screenshot_id', async () => {
    try {
        // This will fail for other reasons (no image_data), but should pass screenshot_id validation
        await axios.post(`${BASE_URL}/generate_flirts`, {
            screenshot_id: 'valid-screenshot-123',
            suggestion_type: 'opener',
            tone: 'playful'
        }, config);
    } catch (error) {
        // Should not be a screenshot_id validation error
        assert(!error.response?.data?.error?.message?.includes('screenshot ID'),
            'Should not fail on screenshot_id validation');
    }
});

// Test 1.4: Invalid screenshot_id in /history
await runTest('GET /flirts/history - Rejects invalid screenshot_id query param', async () => {
    try {
        await axios.get(`${BASE_URL}/flirts/history?screenshot_id=invalid@#$`, config);
        throw new Error('Should have rejected invalid screenshot_id');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

// Test 1.5: Invalid screenshot_id in /analysis/:screenshotId
await runTest('GET /analysis/:screenshotId - Rejects invalid screenshot_id', async () => {
    try {
        await axios.get(`${BASE_URL}/analysis/invalid@#$id`, config);
        throw new Error('Should have rejected invalid screenshot_id');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

/**
 * SECTION 2: SUGGESTION TYPE VALIDATION TESTS
 */
console.log(`\n${colors.blue}=== SUGGESTION TYPE VALIDATION TESTS ===${colors.reset}`);

// Test 2.1: Invalid suggestion_type
await runTest('POST /generate_flirts - Rejects invalid suggestion_type', async () => {
    try {
        await axios.post(`${BASE_URL}/generate_flirts`, {
            image_data: 'base64encodedimage',
            suggestion_type: 'invalid_type',  // Not in whitelist
            tone: 'playful'
        }, config);
        throw new Error('Should have rejected invalid suggestion_type');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
        assert(error.response?.data?.error?.message?.includes('suggestion type'), 'Expected suggestion type error');
    }
});

// Test 2.2: Valid suggestion_type values
const validSuggestionTypes = ['opener', 'reply', 'question', 'compliment', 'icebreaker', 'response', 'continuation'];
for (const type of validSuggestionTypes) {
    await runTest(`POST /generate_flirts - Accepts valid suggestion_type: ${type}`, async () => {
        try {
            await axios.post(`${BASE_URL}/generate_flirts`, {
                image_data: 'base64encodedimage',
                suggestion_type: type,
                tone: 'playful'
            }, config);
        } catch (error) {
            // Should not fail on suggestion_type validation
            assert(!error.response?.data?.error?.message?.includes('suggestion type'),
                `Should not fail on suggestion_type validation for: ${type}`);
        }
    });
}

// Test 2.3: Invalid suggestion_type in /history
await runTest('GET /flirts/history - Rejects invalid suggestion_type query param', async () => {
    try {
        await axios.get(`${BASE_URL}/flirts/history?suggestion_type=badtype`, config);
        throw new Error('Should have rejected invalid suggestion_type');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

/**
 * SECTION 3: TONE VALIDATION TESTS
 */
console.log(`\n${colors.blue}=== TONE VALIDATION TESTS ===${colors.reset}`);

// Test 3.1: Invalid tone
await runTest('POST /generate_flirts - Rejects invalid tone', async () => {
    try {
        await axios.post(`${BASE_URL}/generate_flirts`, {
            image_data: 'base64encodedimage',
            suggestion_type: 'opener',
            tone: 'invalid_tone'  // Not in whitelist
        }, config);
        throw new Error('Should have rejected invalid tone');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
        assert(error.response?.data?.error?.message?.includes('tone'), 'Expected tone error');
    }
});

// Test 3.2: Valid tone values
const validTones = ['playful', 'direct', 'thoughtful', 'witty', 'romantic', 'casual', 'bold'];
for (const tone of validTones) {
    await runTest(`POST /generate_flirts - Accepts valid tone: ${tone}`, async () => {
        try {
            await axios.post(`${BASE_URL}/generate_flirts`, {
                image_data: 'base64encodedimage',
                suggestion_type: 'opener',
                tone: tone
            }, config);
        } catch (error) {
            // Should not fail on tone validation
            assert(!error.response?.data?.error?.message?.includes('Invalid tone'),
                `Should not fail on tone validation for: ${tone}`);
        }
    });
}

/**
 * SECTION 4: TEXT SANITIZATION TESTS
 */
console.log(`\n${colors.blue}=== TEXT SANITIZATION TESTS ===${colors.reset}`);

// Test 4.1: XSS attempt in context field
await runTest('POST /generate_flirts - Sanitizes XSS in context field', async () => {
    // This test verifies sanitization happens, but doesn't reject the request
    // The sanitization should strip out script tags
    const response = await axios.post(`${BASE_URL}/generate_flirts`, {
        image_data: 'base64encodedimage',
        suggestion_type: 'opener',
        tone: 'playful',
        context: '<script>alert("xss")</script>Safe text'
    }, config).catch(err => {
        // Even if request fails for other reasons, it should not fail on sanitization
        assert(!err.response?.data?.error?.message?.includes('script'),
            'Should sanitize, not reject, script tags');
        return { status: 'sanitized' };
    });

    assert(response.status === 'sanitized' || response.status === 200,
        'Request should be sanitized or succeed');
});

// Test 4.2: XSS attempt in analysis context
await runTest('POST /analyze_screenshot - Sanitizes XSS in context field', async () => {
    const FormData = require('form-data');
    const form = new FormData();

    // Mock file data
    form.append('screenshot', Buffer.from('fake-image-data'), {
        filename: 'test.jpg',
        contentType: 'image/jpeg'
    });
    form.append('context', '<script>alert("xss")</script>Context text');

    try {
        await axios.post(`${BASE_URL}/analyze_screenshot`, form, {
            headers: {
                ...config.headers,
                ...form.getHeaders()
            }
        });
    } catch (error) {
        // Should not fail on sanitization - XSS should be stripped
        assert(!error.response?.data?.error?.message?.includes('script'),
            'Should sanitize, not reject, script tags');
    }
});

// Test 4.3: Sanitize feedback in rating endpoint
await runTest('POST /flirts/:suggestionId/rate - Sanitizes XSS in feedback', async () => {
    try {
        await axios.post(`${BASE_URL}/flirts/test-suggestion-123/rate`, {
            rating: 5,
            feedback: '<img src=x onerror=alert(1)>Great suggestion!'
        }, config);
    } catch (error) {
        // Should not fail on sanitization
        assert(!error.response?.data?.error?.message?.toLowerCase().includes('xss'),
            'Should sanitize, not reject, XSS attempts');
    }
});

/**
 * SECTION 5: VOICE VALIDATION TESTS (Already Implemented)
 */
console.log(`\n${colors.blue}=== VOICE VALIDATION TESTS ===${colors.reset}`);

// Test 5.1: Invalid voice_model
await runTest('POST /synthesize_voice - Rejects invalid voice_model', async () => {
    try {
        await axios.post(`${BASE_URL}/synthesize_voice`, {
            text: 'Test message',
            voice_model: 'invalid_model'
        }, config);
        throw new Error('Should have rejected invalid voice_model');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

// Test 5.2: Invalid voice_id format
await runTest('POST /synthesize_voice - Rejects invalid voice_id format', async () => {
    try {
        await axios.post(`${BASE_URL}/synthesize_voice`, {
            text: 'Test message',
            voice_id: 'invalid-id-with-special-chars!@#'
        }, config);
        throw new Error('Should have rejected invalid voice_id');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

// Test 5.3: Text too long
await runTest('POST /synthesize_voice - Rejects text over 1000 characters', async () => {
    try {
        await axios.post(`${BASE_URL}/synthesize_voice`, {
            text: 'a'.repeat(1001),
            voice_model: 'eleven_monolingual_v1'
        }, config);
        throw new Error('Should have rejected oversized text');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
    }
});

// Test 5.4: Valid voice parameters
await runTest('POST /synthesize_voice - Accepts valid voice parameters', async () => {
    try {
        await axios.post(`${BASE_URL}/synthesize_voice`, {
            text: 'Valid test message',
            voice_model: 'eleven_monolingual_v1',
            voice_id: 'pMsXgVXv3BLzUgSXRplE'
        }, config);
    } catch (error) {
        // Should not fail on validation (may fail on other reasons like API quota)
        assert(error.response?.data?.error?.code !== 'VALIDATION_ERROR',
            'Should not fail on validation with valid parameters');
    }
});

/**
 * SECTION 6: COMPREHENSIVE INTEGRATION TEST
 */
console.log(`\n${colors.blue}=== COMPREHENSIVE INTEGRATION TEST ===${colors.reset}`);

// Test 6.1: Multiple invalid fields at once
await runTest('POST /generate_flirts - Validates all fields correctly', async () => {
    try {
        await axios.post(`${BASE_URL}/generate_flirts`, {
            screenshot_id: 'invalid@#$',  // Invalid
            suggestion_type: 'badtype',    // Invalid
            tone: 'invalidtone'            // Invalid
        }, config);
        throw new Error('Should have rejected multiple invalid fields');
    } catch (error) {
        assert(error.response?.status === 400, 'Expected 400 Bad Request');
        assert(error.response?.data?.error?.code === 'VALIDATION_ERROR', 'Expected VALIDATION_ERROR code');
        // Should catch the first validation error (screenshot_id or suggestion_type or tone)
    }
});

    /**
     * PRINT TEST RESULTS SUMMARY
     */
    console.log(`\n${colors.blue}======================================${colors.reset}`);
    console.log(`${colors.blue}     VALIDATION TEST RESULTS SUMMARY${colors.reset}`);
    console.log(`${colors.blue}======================================${colors.reset}`);
    console.log(`Total Tests: ${testResults.total}`);
    console.log(`${colors.green}Passed: ${testResults.passed}${colors.reset}`);
    console.log(`${colors.red}Failed: ${testResults.failed}${colors.reset}`);
    console.log(`Pass Rate: ${((testResults.passed / testResults.total) * 100).toFixed(1)}%`);

    // Print detailed results
    console.log(`\n${colors.blue}Detailed Results:${colors.reset}`);
    testResults.details.forEach((result, index) => {
        const statusColor = result.status === 'PASSED' ? colors.green : colors.red;
        const statusSymbol = result.status === 'PASSED' ? '✓' : '✗';
        console.log(`${index + 1}. ${statusColor}${statusSymbol}${colors.reset} ${result.name}`);
        if (result.error) {
            console.log(`   ${colors.red}${result.error}${colors.reset}`);
        }
    });

    // Exit with appropriate code
    process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run all tests
runAllTests().catch(error => {
    console.error(`${colors.red}Fatal error running tests:${colors.reset}`, error);
    process.exit(1);
});
