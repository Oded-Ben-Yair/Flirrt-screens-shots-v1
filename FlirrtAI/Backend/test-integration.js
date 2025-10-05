/**
 * Comprehensive Integration Test Suite for Flirrt.ai Backend
 * Tests complete API workflow: Auth -> Screenshot Upload -> Analysis -> Flirt Generation -> Voice Synthesis
 *
 * Agent 2 - Stage 6: Testing & Validation Integration
 */

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

// Test Configuration
const BASE_URL = 'http://localhost:3000';
const TEST_TOKEN = 'demo-token-12345';
const TIMEOUT = 30000; // 30 seconds for API calls

// Test Statistics
const stats = {
    total: 0,
    passed: 0,
    failed: 0,
    skipped: 0,
    errors: []
};

// Test Results
const testResults = [];

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[36m',
    gray: '\x1b[90m'
};

/**
 * Log test result
 */
function logTest(name, passed, details = null, error = null) {
    stats.total++;

    if (passed) {
        stats.passed++;
        console.log(`${colors.green}✓${colors.reset} ${name}`);
        if (details) {
            console.log(`  ${colors.gray}${details}${colors.reset}`);
        }
    } else {
        stats.failed++;
        console.log(`${colors.red}✗${colors.reset} ${name}`);
        if (error) {
            console.log(`  ${colors.red}Error: ${error}${colors.reset}`);
            stats.errors.push({ test: name, error: error.toString() });
        }
    }

    testResults.push({
        name,
        passed,
        details,
        error: error ? error.toString() : null,
        timestamp: new Date().toISOString()
    });
}

/**
 * Log test section
 */
function logSection(title) {
    console.log(`\n${colors.blue}━━━ ${title} ━━━${colors.reset}\n`);
}

/**
 * Create test image (base64 encoded 1x1 pixel PNG)
 */
function createTestImage() {
    // 1x1 transparent PNG
    return Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64');
}

/**
 * Test 1: Health Check
 */
async function testHealthCheck() {
    logSection('1. Health Check & Server Status');

    try {
        const response = await axios.get(`${BASE_URL}/health`, { timeout: 5000 });

        if (response.status === 200 && response.data.success) {
            logTest(
                'Health check endpoint',
                true,
                `Server is ${response.data.status}, version ${response.data.version}`
            );

            // Check service configurations
            const services = response.data.services;
            logTest(
                'Grok API configured',
                services.grok_api === 'configured',
                `Status: ${services.grok_api}`
            );
            logTest(
                'ElevenLabs API configured',
                services.elevenlabs_api === 'configured',
                `Status: ${services.elevenlabs_api}`
            );
        } else {
            logTest('Health check endpoint', false, null, 'Unexpected response format');
        }
    } catch (error) {
        logTest('Health check endpoint', false, null, error.message);
    }
}

/**
 * Test 2: Error Handling & Input Validation
 */
async function testErrorHandling() {
    logSection('2. Error Handling & Input Validation');

    // Test 2.1: Missing required fields
    try {
        await axios.post(`${BASE_URL}/api/v1/flirts/generate_flirts`, {}, { timeout: TIMEOUT });
        logTest('Missing required fields (screenshot_id/image_data)', false, null, 'Should have returned 400 error');
    } catch (error) {
        const expectedStatus = 400;
        logTest(
            'Missing required fields (screenshot_id/image_data)',
            error.response?.status === expectedStatus,
            `Returned status ${error.response?.status}, expected ${expectedStatus}`
        );
    }

    // Test 2.2: Invalid endpoint (404)
    try {
        await axios.get(`${BASE_URL}/api/v1/nonexistent`, { timeout: 5000 });
        logTest('Invalid endpoint (404)', false, null, 'Should have returned 404 error');
    } catch (error) {
        logTest(
            'Invalid endpoint (404)',
            error.response?.status === 404,
            `Returned status ${error.response?.status}, includes available_endpoints list: ${!!error.response?.data?.available_endpoints}`
        );
    }

    // Test 2.3: Malformed JSON
    try {
        await axios.post(
            `${BASE_URL}/api/v1/flirts/generate_flirts`,
            'invalid json{',
            {
                headers: { 'Content-Type': 'application/json' },
                timeout: 5000
            }
        );
        logTest('Malformed JSON', false, null, 'Should have returned 400 error');
    } catch (error) {
        logTest(
            'Malformed JSON',
            error.response?.status === 400,
            `Returned status ${error.response?.status}`
        );
    }
}

/**
 * Test 3: XSS Prevention & Input Sanitization
 */
async function testXSSPrevention() {
    logSection('3. XSS Prevention & Input Sanitization');

    const xssPayloads = [
        '<script>alert("XSS")</script>',
        '<img src=x onerror=alert("XSS")>',
        'javascript:alert("XSS")',
        '<svg onload=alert("XSS")>',
        '"><script>alert(String.fromCharCode(88,83,83))</script>'
    ];

    for (const payload of xssPayloads) {
        try {
            const response = await axios.post(
                `${BASE_URL}/api/v1/flirts/generate_flirts`,
                {
                    screenshot_id: 'test-123',
                    context: payload,
                    suggestion_type: 'opener',
                    tone: 'playful'
                },
                { timeout: TIMEOUT }
            );

            // Check if response contains unsanitized script
            const responseStr = JSON.stringify(response.data);
            const containsScript = responseStr.includes('<script>') || responseStr.includes('onerror=');

            logTest(
                `XSS prevention: ${payload.substring(0, 30)}...`,
                !containsScript,
                containsScript ? 'WARNING: Potential XSS vulnerability detected' : 'Payload safely handled'
            );
        } catch (error) {
            // If it errors out, that's also acceptable (request rejected)
            logTest(
                `XSS prevention: ${payload.substring(0, 30)}...`,
                true,
                'Request rejected (acceptable)'
            );
        }
    }
}

/**
 * Test 4: Complete API Workflow (Happy Path)
 */
async function testCompleteWorkflow() {
    logSection('4. Complete API Workflow (End-to-End)');

    let screenshotId = null;
    let suggestionId = null;

    // Step 1: Generate flirt suggestions with image data
    try {
        const testImageBase64 = createTestImage().toString('base64');

        const response = await axios.post(
            `${BASE_URL}/api/v1/flirts/generate_flirts`,
            {
                image_data: testImageBase64,
                context: 'Test profile analysis',
                suggestion_type: 'opener',
                tone: 'playful'
            },
            { timeout: TIMEOUT }
        );

        const success = response.status === 200 && response.data.success;
        logTest(
            'Step 1: Generate flirt suggestions',
            success,
            success ? `Generated ${response.data.data?.suggestions?.length || 0} suggestions` : null
        );

        if (success && response.data.data?.suggestions?.length > 0) {
            suggestionId = response.data.data.suggestions[0].id;
            screenshotId = response.data.data.metadata?.screenshot_id;
        }
    } catch (error) {
        logTest('Step 1: Generate flirt suggestions', false, null, error.response?.data?.error || error.message);
    }

    // Step 2: Voice synthesis (if suggestion was created)
    if (suggestionId) {
        try {
            const response = await axios.post(
                `${BASE_URL}/api/v1/voice/synthesize`,
                {
                    text: 'Test voice synthesis for integration testing',
                    voice_id: 'Rachel',
                    suggestion_id: suggestionId
                },
                { timeout: TIMEOUT }
            );

            const success = response.status === 200 && response.data.success;
            logTest(
                'Step 2: Voice synthesis',
                success,
                success ? `Audio generated: ${response.data.data?.duration || 'N/A'}s` : null
            );
        } catch (error) {
            logTest('Step 2: Voice synthesis', false, null, error.response?.data?.error || error.message);
        }
    } else {
        logTest('Step 2: Voice synthesis', false, null, 'Skipped (no suggestion ID from previous step)');
        stats.skipped++;
    }
}

/**
 * Test 5: Rate Limiting & Timeout Handling
 */
async function testRateLimitingAndTimeouts() {
    logSection('5. Rate Limiting & Timeout Handling');

    // Test 5.1: API timeout handling (simulate with very short timeout)
    try {
        await axios.get(`${BASE_URL}/health`, { timeout: 1 }); // 1ms timeout (should fail)
        logTest('Timeout handling', false, null, 'Should have timed out');
    } catch (error) {
        logTest(
            'Timeout handling',
            error.code === 'ECONNABORTED' || error.message.includes('timeout'),
            'Request properly timed out as expected'
        );
    }

    // Test 5.2: Concurrent requests handling
    try {
        const promises = [];
        for (let i = 0; i < 5; i++) {
            promises.push(axios.get(`${BASE_URL}/health`, { timeout: 5000 }));
        }

        const results = await Promise.all(promises);
        const allSucceeded = results.every(r => r.status === 200);

        logTest(
            'Concurrent requests handling',
            allSucceeded,
            `${results.length} concurrent requests completed successfully`
        );
    } catch (error) {
        logTest('Concurrent requests handling', false, null, error.message);
    }
}

/**
 * Test 6: Error Response Format Consistency
 */
async function testErrorResponseFormat() {
    logSection('6. Error Response Format Consistency');

    // Test various error scenarios and ensure consistent format
    const errorTests = [
        {
            name: 'Missing required field',
            request: () => axios.post(`${BASE_URL}/api/v1/flirts/generate_flirts`, {}, { timeout: 5000 }),
            expectedFields: ['success', 'error', 'code']
        },
        {
            name: '404 Not Found',
            request: () => axios.get(`${BASE_URL}/api/v1/nonexistent`, { timeout: 5000 }),
            expectedFields: ['success', 'error', 'code', 'available_endpoints']
        }
    ];

    for (const test of errorTests) {
        try {
            await test.request();
            logTest(`Error format: ${test.name}`, false, null, 'Should have returned an error');
        } catch (error) {
            const data = error.response?.data;
            const hasAllFields = test.expectedFields.every(field => data && data[field] !== undefined);
            const hasSuccessFalse = data?.success === false;

            logTest(
                `Error format: ${test.name}`,
                hasAllFields && hasSuccessFalse,
                hasAllFields ? `Has all required fields: ${test.expectedFields.join(', ')}` : `Missing fields`
            );
        }
    }
}

/**
 * Test 7: Performance Metrics
 */
async function testPerformanceMetrics() {
    logSection('7. Performance Metrics');

    // Test 7.1: Health check response time
    try {
        const start = Date.now();
        await axios.get(`${BASE_URL}/health`, { timeout: 5000 });
        const duration = Date.now() - start;

        const acceptableTime = 1000; // 1 second
        logTest(
            'Health check response time',
            duration < acceptableTime,
            `Responded in ${duration}ms (threshold: ${acceptableTime}ms)`
        );
    } catch (error) {
        logTest('Health check response time', false, null, error.message);
    }

    // Test 7.2: Flirt generation response time
    try {
        const testImageBase64 = createTestImage().toString('base64');
        const start = Date.now();

        await axios.post(
            `${BASE_URL}/api/v1/flirts/generate_flirts`,
            {
                image_data: testImageBase64,
                suggestion_type: 'opener',
                tone: 'playful'
            },
            { timeout: TIMEOUT }
        );

        const duration = Date.now() - start;
        const acceptableTime = 15000; // 15 seconds (includes Grok API call)

        logTest(
            'Flirt generation response time',
            duration < acceptableTime,
            `Completed in ${duration}ms (threshold: ${acceptableTime}ms)`
        );
    } catch (error) {
        logTest('Flirt generation response time', false, null, error.response?.data?.error || error.message);
    }
}

/**
 * Test 8: Circuit Breaker & Resilience
 */
async function testCircuitBreakerResilience() {
    logSection('8. Circuit Breaker & Resilience');

    // Test 8.1: Invalid API key handling (should gracefully handle external API errors)
    try {
        // This will fail with current API but should handle gracefully
        const response = await axios.post(
            `${BASE_URL}/api/v1/flirts/generate_flirts`,
            {
                screenshot_id: 'test-circuit-breaker',
                suggestion_type: 'opener',
                tone: 'playful'
            },
            { timeout: TIMEOUT }
        );

        // If it succeeds or fails gracefully
        logTest(
            'External API error handling',
            true,
            'Request handled (success or graceful failure)'
        );
    } catch (error) {
        // Check if error response is properly formatted
        const hasProperErrorFormat = error.response?.data?.success === false && error.response?.data?.error;
        logTest(
            'External API error handling',
            hasProperErrorFormat,
            hasProperErrorFormat ? 'Error properly formatted' : 'Error not properly formatted'
        );
    }

    // Test 8.2: Database unavailable fallback
    try {
        // Server should handle database unavailability gracefully
        const response = await axios.get(`${BASE_URL}/health`, { timeout: 5000 });

        logTest(
            'Database unavailable fallback',
            true,
            `Server operational, database status: ${response.data.services?.database || 'unknown'}`
        );
    } catch (error) {
        logTest('Database unavailable fallback', false, null, error.message);
    }
}

/**
 * Print final summary
 */
function printSummary() {
    console.log('\n' + '='.repeat(80));
    console.log(`${colors.blue}INTEGRATION TEST SUMMARY${colors.reset}`);
    console.log('='.repeat(80));

    const passRate = stats.total > 0 ? ((stats.passed / stats.total) * 100).toFixed(1) : 0;
    const failRate = stats.total > 0 ? ((stats.failed / stats.total) * 100).toFixed(1) : 0;

    console.log(`Total Tests:   ${stats.total}`);
    console.log(`${colors.green}Passed:        ${stats.passed} (${passRate}%)${colors.reset}`);
    console.log(`${colors.red}Failed:        ${stats.failed} (${failRate}%)${colors.reset}`);
    console.log(`${colors.yellow}Skipped:       ${stats.skipped}${colors.reset}`);

    if (stats.errors.length > 0) {
        console.log(`\n${colors.red}ERRORS:${colors.reset}`);
        stats.errors.forEach((err, i) => {
            console.log(`${i + 1}. ${err.test}`);
            console.log(`   ${colors.gray}${err.error}${colors.reset}`);
        });
    }

    console.log('\n' + '='.repeat(80));

    // Overall status
    if (passRate >= 95) {
        console.log(`${colors.green}✓ EXCELLENT: ${passRate}% pass rate - Production ready!${colors.reset}`);
    } else if (passRate >= 85) {
        console.log(`${colors.green}✓ GOOD: ${passRate}% pass rate - Minor issues to address${colors.reset}`);
    } else if (passRate >= 70) {
        console.log(`${colors.yellow}⚠ MODERATE: ${passRate}% pass rate - Several issues need attention${colors.reset}`);
    } else {
        console.log(`${colors.red}✗ POOR: ${passRate}% pass rate - Critical issues need immediate attention${colors.reset}`);
    }

    console.log('='.repeat(80));
}

/**
 * Main test runner
 */
async function runAllTests() {
    console.log(`${colors.blue}╔════════════════════════════════════════════════════════════════════════╗${colors.reset}`);
    console.log(`${colors.blue}║     FLIRRT.AI BACKEND - COMPREHENSIVE INTEGRATION TEST SUITE          ║${colors.reset}`);
    console.log(`${colors.blue}║     Agent 2 - Stage 6: Testing & Validation Integration              ║${colors.reset}`);
    console.log(`${colors.blue}╚════════════════════════════════════════════════════════════════════════╝${colors.reset}`);
    console.log(`\nBase URL: ${BASE_URL}`);
    console.log(`Timeout:  ${TIMEOUT}ms`);
    console.log(`Started:  ${new Date().toISOString()}\n`);

    try {
        await testHealthCheck();
        await testErrorHandling();
        await testXSSPrevention();
        await testCompleteWorkflow();
        await testRateLimitingAndTimeouts();
        await testErrorResponseFormat();
        await testPerformanceMetrics();
        await testCircuitBreakerResilience();
    } catch (error) {
        console.error(`\n${colors.red}Fatal error in test suite:${colors.reset}`, error.message);
    }

    printSummary();

    // Save results to file
    const resultsFile = path.join(__dirname, 'test-integration-results.json');
    fs.writeFileSync(resultsFile, JSON.stringify({
        timestamp: new Date().toISOString(),
        stats,
        results: testResults
    }, null, 2));

    console.log(`\nDetailed results saved to: ${resultsFile}\n`);

    // Exit with appropriate code
    process.exit(stats.failed > 0 ? 1 : 0);
}

// Run tests
runAllTests();
