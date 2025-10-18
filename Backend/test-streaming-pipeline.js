#!/usr/bin/env node

/**
 * Streaming Pipeline Test Suite
 *
 * Comprehensive testing for the real-time streaming backend system
 * including WebSocket communication, upload queue, and performance validation.
 */

const axios = require('axios');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

// Test configuration
const CONFIG = {
    BASE_URL: 'http://localhost:3000',
    WS_URL: 'ws://localhost:3000/ws',
    TEST_IMAGE: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    TIMEOUT: 30000,
    PARALLEL_TESTS: 3
};

// Test results tracking
const results = {
    passed: 0,
    failed: 0,
    tests: [],
    startTime: Date.now(),
    performance: {
        streaming: [],
        uploads: [],
        websockets: []
    }
};

// Colors for console output
const colors = {
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m',
    bold: '\x1b[1m'
};

/**
 * Test utility functions
 */
class TestUtils {
    static log(message, color = colors.reset) {
        console.log(`${color}${message}${colors.reset}`);
    }

    static logTest(name, status, duration, details = '') {
        const statusColor = status === 'PASS' ? colors.green : colors.red;
        const durationStr = duration ? ` (${duration}ms)` : '';
        TestUtils.log(`  ${statusColor}${status}${colors.reset} ${name}${durationStr}`);
        if (details) {
            TestUtils.log(`    ${details}`, colors.yellow);
        }
    }

    static async sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    static generateTestId() {
        return `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    static async makeRequest(method, endpoint, data = null) {
        try {
            const response = await axios({
                method,
                url: `${CONFIG.BASE_URL}${endpoint}`,
                data,
                timeout: CONFIG.TIMEOUT,
                headers: {
                    'Content-Type': 'application/json',
                    'X-Platform': 'test-client'
                }
            });
            return { success: true, data: response.data, status: response.status };
        } catch (error) {
            return {
                success: false,
                error: error.response?.data || error.message,
                status: error.response?.status
            };
        }
    }

    static createWebSocket(token = 'test-token-for-api-testing') {
        return new Promise((resolve, reject) => {
            const ws = new WebSocket(`${CONFIG.WS_URL}?token=${token}`);
            const timeout = setTimeout(() => {
                reject(new Error('WebSocket connection timeout'));
            }, 5000);

            ws.on('open', () => {
                clearTimeout(timeout);
                resolve(ws);
            });

            ws.on('error', (error) => {
                clearTimeout(timeout);
                reject(error);
            });
        });
    }
}

/**
 * Test suite classes
 */
class HealthTests {
    static async runAll() {
        TestUtils.log('\n=== Health Check Tests ===', colors.bold + colors.blue);

        await this.testBasicHealth();
        await this.testSystemStatus();
        await this.testStreamingHealth();
        await this.testUploadQueueHealth();
        await this.testWebSocketHealth();
    }

    static async testBasicHealth() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('GET', '/health');
        const duration = Date.now() - startTime;

        if (result.success && result.data.status) {
            results.passed++;
            TestUtils.logTest('Basic Health Check', 'PASS', duration);
            results.tests.push({ name: 'Basic Health', status: 'pass', duration });
        } else {
            results.failed++;
            TestUtils.logTest('Basic Health Check', 'FAIL', duration, result.error);
            results.tests.push({ name: 'Basic Health', status: 'fail', duration, error: result.error });
        }
    }

    static async testSystemStatus() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('GET', '/api/v1/status/system');
        const duration = Date.now() - startTime;

        if (result.success && result.data.status && result.data.components) {
            results.passed++;
            TestUtils.logTest('System Status', 'PASS', duration);
            results.tests.push({ name: 'System Status', status: 'pass', duration });
        } else {
            results.failed++;
            TestUtils.logTest('System Status', 'FAIL', duration, result.error);
            results.tests.push({ name: 'System Status', status: 'fail', duration, error: result.error });
        }
    }

    static async testStreamingHealth() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('GET', '/api/v1/stream/health');
        const duration = Date.now() - startTime;

        if (result.success && result.data.status) {
            results.passed++;
            TestUtils.logTest('Streaming Service Health', 'PASS', duration);
            results.tests.push({ name: 'Streaming Health', status: 'pass', duration });
        } else {
            results.failed++;
            TestUtils.logTest('Streaming Service Health', 'FAIL', duration, result.error);
            results.tests.push({ name: 'Streaming Health', status: 'fail', duration, error: result.error });
        }
    }

    static async testUploadQueueHealth() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('GET', '/api/v1/status/upload-queue');
        const duration = Date.now() - startTime;

        if (result.success && result.data.success) {
            results.passed++;
            TestUtils.logTest('Upload Queue Health', 'PASS', duration);
            results.tests.push({ name: 'Upload Queue Health', status: 'pass', duration });
        } else {
            results.failed++;
            TestUtils.logTest('Upload Queue Health', 'FAIL', duration, result.error);
            results.tests.push({ name: 'Upload Queue Health', status: 'fail', duration, error: result.error });
        }
    }

    static async testWebSocketHealth() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('GET', '/api/v1/status/websocket');
        const duration = Date.now() - startTime;

        if (result.success && result.data.success) {
            results.passed++;
            TestUtils.logTest('WebSocket Service Health', 'PASS', duration);
            results.tests.push({ name: 'WebSocket Health', status: 'pass', duration });
        } else {
            results.failed++;
            TestUtils.logTest('WebSocket Service Health', 'FAIL', duration, result.error);
            results.tests.push({ name: 'WebSocket Health', status: 'fail', duration, error: result.error });
        }
    }
}

class StreamingTests {
    static async runAll() {
        TestUtils.log('\n=== Streaming Pipeline Tests ===', colors.bold + colors.blue);

        await this.testStreamingAnalysis();
        await this.testStreamingStatus();
        await this.testStreamingPerformance();
        await this.testStreamingCancellation();
        await this.testParallelStreaming();
    }

    static async testStreamingAnalysis() {
        const testId = TestUtils.generateTestId();
        const startTime = Date.now();

        const streamRequest = {
            image_data: CONFIG.TEST_IMAGE,
            context: 'Test streaming analysis',
            suggestion_type: 'opener',
            tone: 'playful',
            priority: 'normal',
            strategy: 'fast',
            enable_websocket: true,
            timeout: 15000
        };

        const result = await TestUtils.makeRequest('POST', '/api/v1/stream/analyze', streamRequest);
        const duration = Date.now() - startTime;

        if (result.success && result.data.streamId) {
            // Monitor the stream for completion
            const streamId = result.data.streamId;
            const monitorResult = await this.monitorStream(streamId, 15000);

            if (monitorResult.completed) {
                results.passed++;
                TestUtils.logTest('Streaming Analysis', 'PASS', duration + monitorResult.duration);
                results.performance.streaming.push({
                    test: 'basic_analysis',
                    duration: duration + monitorResult.duration,
                    streamId
                });
                results.tests.push({ name: 'Streaming Analysis', status: 'pass', duration: duration + monitorResult.duration });
            } else {
                results.failed++;
                TestUtils.logTest('Streaming Analysis', 'FAIL', duration, `Stream did not complete: ${monitorResult.error}`);
                results.tests.push({ name: 'Streaming Analysis', status: 'fail', duration, error: monitorResult.error });
            }
        } else {
            results.failed++;
            TestUtils.logTest('Streaming Analysis', 'FAIL', duration, result.error);
            results.tests.push({ name: 'Streaming Analysis', status: 'fail', duration, error: result.error });
        }
    }

    static async monitorStream(streamId, timeout = 15000) {
        const startTime = Date.now();
        const pollInterval = 1000; // 1 second
        let attempts = 0;
        const maxAttempts = Math.floor(timeout / pollInterval);

        while (attempts < maxAttempts) {
            const result = await TestUtils.makeRequest('GET', `/api/v1/stream/status/${streamId}`);

            if (result.success && result.data.status) {
                const status = result.data.status;

                if (status === 'completed') {
                    return {
                        completed: true,
                        duration: Date.now() - startTime,
                        suggestions: result.data.suggestions
                    };
                } else if (status === 'error' || status === 'failed') {
                    return {
                        completed: false,
                        duration: Date.now() - startTime,
                        error: `Stream failed with status: ${status}`
                    };
                }

                // Stream is still processing, continue monitoring
                await TestUtils.sleep(pollInterval);
                attempts++;
            } else {
                return {
                    completed: false,
                    duration: Date.now() - startTime,
                    error: 'Failed to get stream status'
                };
            }
        }

        return {
            completed: false,
            duration: Date.now() - startTime,
            error: 'Stream monitoring timeout'
        };
    }

    static async testStreamingStatus() {
        const startTime = Date.now();

        // Start a stream first
        const streamRequest = {
            image_data: CONFIG.TEST_IMAGE,
            context: 'Status test',
            suggestion_type: 'opener',
            tone: 'casual',
            strategy: 'fast'
        };

        const streamResult = await TestUtils.makeRequest('POST', '/api/v1/stream/analyze', streamRequest);

        if (streamResult.success && streamResult.data.streamId) {
            const statusResult = await TestUtils.makeRequest('GET', `/api/v1/stream/status/${streamResult.data.streamId}`);
            const duration = Date.now() - startTime;

            if (statusResult.success && statusResult.data.streamId) {
                results.passed++;
                TestUtils.logTest('Streaming Status Check', 'PASS', duration);
                results.tests.push({ name: 'Streaming Status', status: 'pass', duration });
            } else {
                results.failed++;
                TestUtils.logTest('Streaming Status Check', 'FAIL', duration, statusResult.error);
                results.tests.push({ name: 'Streaming Status', status: 'fail', duration, error: statusResult.error });
            }
        } else {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('Streaming Status Check', 'FAIL', duration, 'Failed to start stream');
            results.tests.push({ name: 'Streaming Status', status: 'fail', duration, error: 'Failed to start stream' });
        }
    }

    static async testStreamingPerformance() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('POST', '/api/v1/stream/test');
        const duration = Date.now() - startTime;

        if (result.success && result.data.success) {
            const targetTime = 8000; // 8 seconds
            const actualTime = result.data.duration;
            const metTarget = actualTime <= targetTime;

            if (metTarget) {
                results.passed++;
                TestUtils.logTest('Streaming Performance Test', 'PASS', duration, `Analysis completed in ${actualTime}ms (target: ${targetTime}ms)`);
                results.performance.streaming.push({
                    test: 'performance_test',
                    duration: actualTime,
                    metTarget: true
                });
            } else {
                results.failed++;
                TestUtils.logTest('Streaming Performance Test', 'FAIL', duration, `Analysis took ${actualTime}ms (target: ${targetTime}ms)`);
                results.performance.streaming.push({
                    test: 'performance_test',
                    duration: actualTime,
                    metTarget: false
                });
            }
            results.tests.push({ name: 'Streaming Performance', status: metTarget ? 'pass' : 'fail', duration, actualTime, targetTime });
        } else {
            results.failed++;
            TestUtils.logTest('Streaming Performance Test', 'FAIL', duration, result.error);
            results.tests.push({ name: 'Streaming Performance', status: 'fail', duration, error: result.error });
        }
    }

    static async testStreamingCancellation() {
        const startTime = Date.now();

        // Start a stream
        const streamRequest = {
            image_data: CONFIG.TEST_IMAGE,
            context: 'Cancellation test - this will be cancelled',
            suggestion_type: 'opener',
            tone: 'playful',
            strategy: 'comprehensive' // Use slow strategy to have time to cancel
        };

        const streamResult = await TestUtils.makeRequest('POST', '/api/v1/stream/analyze', streamRequest);

        if (streamResult.success && streamResult.data.streamId) {
            const streamId = streamResult.data.streamId;

            // Wait a moment then cancel
            await TestUtils.sleep(1000);

            const cancelResult = await TestUtils.makeRequest('DELETE', `/api/v1/stream/${streamId}`);
            const duration = Date.now() - startTime;

            if (cancelResult.success && cancelResult.data.success) {
                results.passed++;
                TestUtils.logTest('Streaming Cancellation', 'PASS', duration);
                results.tests.push({ name: 'Streaming Cancellation', status: 'pass', duration });
            } else {
                results.failed++;
                TestUtils.logTest('Streaming Cancellation', 'FAIL', duration, cancelResult.error);
                results.tests.push({ name: 'Streaming Cancellation', status: 'fail', duration, error: cancelResult.error });
            }
        } else {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('Streaming Cancellation', 'FAIL', duration, 'Failed to start stream for cancellation test');
            results.tests.push({ name: 'Streaming Cancellation', status: 'fail', duration, error: 'Failed to start stream' });
        }
    }

    static async testParallelStreaming() {
        const startTime = Date.now();

        const streamRequests = Array.from({ length: CONFIG.PARALLEL_TESTS }, (_, i) => ({
            image_data: CONFIG.TEST_IMAGE,
            context: `Parallel test ${i + 1}`,
            suggestion_type: 'opener',
            tone: 'playful',
            strategy: 'fast'
        }));

        try {
            const promises = streamRequests.map(request =>
                TestUtils.makeRequest('POST', '/api/v1/stream/analyze', request)
            );

            const results_parallel = await Promise.all(promises);
            const duration = Date.now() - startTime;

            const successfulStreams = results_parallel.filter(r => r.success && r.data.streamId);

            if (successfulStreams.length === CONFIG.PARALLEL_TESTS) {
                results.passed++;
                TestUtils.logTest('Parallel Streaming', 'PASS', duration, `${successfulStreams.length}/${CONFIG.PARALLEL_TESTS} streams started successfully`);
                results.tests.push({ name: 'Parallel Streaming', status: 'pass', duration, parallelCount: successfulStreams.length });
            } else {
                results.failed++;
                TestUtils.logTest('Parallel Streaming', 'FAIL', duration, `Only ${successfulStreams.length}/${CONFIG.PARALLEL_TESTS} streams started successfully`);
                results.tests.push({ name: 'Parallel Streaming', status: 'fail', duration, parallelCount: successfulStreams.length });
            }
        } catch (error) {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('Parallel Streaming', 'FAIL', duration, error.message);
            results.tests.push({ name: 'Parallel Streaming', status: 'fail', duration, error: error.message });
        }
    }
}

class WebSocketTests {
    static async runAll() {
        TestUtils.log('\n=== WebSocket Communication Tests ===', colors.bold + colors.blue);

        await this.testWebSocketConnection();
        await this.testWebSocketAuthentication();
        await this.testWebSocketSubscription();
        await this.testWebSocketStreamUpdates();
    }

    static async testWebSocketConnection() {
        const startTime = Date.now();

        try {
            const ws = await TestUtils.createWebSocket();
            const duration = Date.now() - startTime;

            // Test basic communication
            const pingPromise = new Promise((resolve) => {
                ws.on('message', (data) => {
                    const message = JSON.parse(data.toString());
                    if (message.type === 'pong') {
                        resolve(true);
                    }
                });

                ws.send(JSON.stringify({
                    type: 'ping',
                    timestamp: new Date().toISOString()
                }));
            });

            const pingReceived = await Promise.race([
                pingPromise,
                new Promise(resolve => setTimeout(() => resolve(false), 5000))
            ]);

            ws.close();

            if (pingReceived) {
                results.passed++;
                TestUtils.logTest('WebSocket Connection', 'PASS', duration);
                results.tests.push({ name: 'WebSocket Connection', status: 'pass', duration });
            } else {
                results.failed++;
                TestUtils.logTest('WebSocket Connection', 'FAIL', duration, 'Ping/pong failed');
                results.tests.push({ name: 'WebSocket Connection', status: 'fail', duration, error: 'Ping/pong failed' });
            }
        } catch (error) {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('WebSocket Connection', 'FAIL', duration, error.message);
            results.tests.push({ name: 'WebSocket Connection', status: 'fail', duration, error: error.message });
        }
    }

    static async testWebSocketAuthentication() {
        const startTime = Date.now();

        try {
            const ws = await TestUtils.createWebSocket();
            const duration = Date.now() - startTime;

            // Check for authentication confirmation
            const authPromise = new Promise((resolve) => {
                ws.on('message', (data) => {
                    const message = JSON.parse(data.toString());
                    if (message.type === 'authenticated') {
                        resolve(true);
                    }
                });
            });

            const authenticated = await Promise.race([
                authPromise,
                new Promise(resolve => setTimeout(() => resolve(false), 5000))
            ]);

            ws.close();

            if (authenticated) {
                results.passed++;
                TestUtils.logTest('WebSocket Authentication', 'PASS', duration);
                results.tests.push({ name: 'WebSocket Authentication', status: 'pass', duration });
            } else {
                results.failed++;
                TestUtils.logTest('WebSocket Authentication', 'FAIL', duration, 'Authentication message not received');
                results.tests.push({ name: 'WebSocket Authentication', status: 'fail', duration, error: 'No auth message' });
            }
        } catch (error) {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('WebSocket Authentication', 'FAIL', duration, error.message);
            results.tests.push({ name: 'WebSocket Authentication', status: 'fail', duration, error: error.message });
        }
    }

    static async testWebSocketSubscription() {
        const startTime = Date.now();

        try {
            const ws = await TestUtils.createWebSocket();

            // Subscribe to channels
            const subscribePromise = new Promise((resolve) => {
                ws.on('message', (data) => {
                    const message = JSON.parse(data.toString());
                    if (message.type === 'subscription_confirmed') {
                        resolve(true);
                    }
                });

                ws.send(JSON.stringify({
                    type: 'subscribe',
                    payload: {
                        channels: ['user:test-user:streams', 'user:test-user:uploads']
                    }
                }));
            });

            const subscribed = await Promise.race([
                subscribePromise,
                new Promise(resolve => setTimeout(() => resolve(false), 5000))
            ]);

            const duration = Date.now() - startTime;
            ws.close();

            if (subscribed) {
                results.passed++;
                TestUtils.logTest('WebSocket Subscription', 'PASS', duration);
                results.tests.push({ name: 'WebSocket Subscription', status: 'pass', duration });
            } else {
                results.failed++;
                TestUtils.logTest('WebSocket Subscription', 'FAIL', duration, 'Subscription confirmation not received');
                results.tests.push({ name: 'WebSocket Subscription', status: 'fail', duration, error: 'No subscription confirmation' });
            }
        } catch (error) {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('WebSocket Subscription', 'FAIL', duration, error.message);
            results.tests.push({ name: 'WebSocket Subscription', status: 'fail', duration, error: error.message });
        }
    }

    static async testWebSocketStreamUpdates() {
        const startTime = Date.now();

        try {
            const ws = await TestUtils.createWebSocket();

            // Subscribe to stream updates
            ws.send(JSON.stringify({
                type: 'subscribe',
                payload: {
                    channels: ['user:test-user-streaming:streams']
                }
            }));

            // Start a stream to trigger updates
            const streamRequest = {
                image_data: CONFIG.TEST_IMAGE,
                context: 'WebSocket update test',
                suggestion_type: 'opener',
                tone: 'playful',
                strategy: 'fast'
            };

            const streamResult = await TestUtils.makeRequest('POST', '/api/v1/stream/analyze', streamRequest);

            if (streamResult.success && streamResult.data.streamId) {
                // Listen for stream updates
                const updatePromise = new Promise((resolve) => {
                    let updateReceived = false;
                    ws.on('message', (data) => {
                        const message = JSON.parse(data.toString());
                        if (message.type === 'stream_update' && !updateReceived) {
                            updateReceived = true;
                            resolve(true);
                        }
                    });
                });

                const updateReceived = await Promise.race([
                    updatePromise,
                    new Promise(resolve => setTimeout(() => resolve(false), 10000))
                ]);

                const duration = Date.now() - startTime;
                ws.close();

                if (updateReceived) {
                    results.passed++;
                    TestUtils.logTest('WebSocket Stream Updates', 'PASS', duration);
                    results.tests.push({ name: 'WebSocket Stream Updates', status: 'pass', duration });
                } else {
                    results.failed++;
                    TestUtils.logTest('WebSocket Stream Updates', 'FAIL', duration, 'Stream update not received');
                    results.tests.push({ name: 'WebSocket Stream Updates', status: 'fail', duration, error: 'No stream update' });
                }
            } else {
                const duration = Date.now() - startTime;
                ws.close();
                results.failed++;
                TestUtils.logTest('WebSocket Stream Updates', 'FAIL', duration, 'Failed to start stream');
                results.tests.push({ name: 'WebSocket Stream Updates', status: 'fail', duration, error: 'Failed to start stream' });
            }
        } catch (error) {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('WebSocket Stream Updates', 'FAIL', duration, error.message);
            results.tests.push({ name: 'WebSocket Stream Updates', status: 'fail', duration, error: error.message });
        }
    }
}

class PerformanceTests {
    static async runAll() {
        TestUtils.log('\n=== Performance Validation Tests ===', colors.bold + colors.blue);

        await this.testSub12sTarget();
        await this.testKeyboardOptimization();
        await this.testLoadTesting();
        await this.testMemoryUsage();
    }

    static async testSub12sTarget() {
        const testCount = 5;
        const targetTime = 12000; // 12 seconds
        const startTime = Date.now();

        let passedTests = 0;
        const durations = [];

        for (let i = 0; i < testCount; i++) {
            const testStart = Date.now();

            const streamRequest = {
                image_data: CONFIG.TEST_IMAGE,
                context: `Sub-12s test ${i + 1}`,
                suggestion_type: 'opener',
                tone: 'playful',
                strategy: 'standard'
            };

            const result = await TestUtils.makeRequest('POST', '/api/v1/stream/analyze', streamRequest);

            if (result.success && result.data.streamId) {
                const monitorResult = await StreamingTests.monitorStream(result.data.streamId, 15000);
                const duration = Date.now() - testStart;
                durations.push(duration);

                if (monitorResult.completed && duration <= targetTime) {
                    passedTests++;
                }
            }
        }

        const totalDuration = Date.now() - startTime;
        const avgDuration = durations.reduce((sum, d) => sum + d, 0) / durations.length;
        const successRate = (passedTests / testCount) * 100;

        if (successRate >= 80) { // 80% success rate threshold
            results.passed++;
            TestUtils.logTest('Sub-12s Performance Target', 'PASS', totalDuration,
                `${passedTests}/${testCount} tests under 12s (avg: ${Math.round(avgDuration)}ms)`);
            results.tests.push({
                name: 'Sub-12s Target',
                status: 'pass',
                duration: totalDuration,
                successRate,
                avgDuration: Math.round(avgDuration)
            });
        } else {
            results.failed++;
            TestUtils.logTest('Sub-12s Performance Target', 'FAIL', totalDuration,
                `Only ${passedTests}/${testCount} tests under 12s (avg: ${Math.round(avgDuration)}ms)`);
            results.tests.push({
                name: 'Sub-12s Target',
                status: 'fail',
                duration: totalDuration,
                successRate,
                avgDuration: Math.round(avgDuration)
            });
        }

        results.performance.streaming.push({
            test: 'sub12s_target',
            successRate,
            avgDuration: Math.round(avgDuration),
            durations
        });
    }

    static async testKeyboardOptimization() {
        const targetTime = 6000; // 6 seconds for keyboard
        const startTime = Date.now();

        const streamRequest = {
            image_data: CONFIG.TEST_IMAGE,
            context: 'Keyboard optimization test',
            suggestion_type: 'opener',
            tone: 'playful',
            priority: 'urgent',
            strategy: 'fast'
        };

        const result = await TestUtils.makeRequest('POST', '/api/v1/stream/analyze', streamRequest);

        if (result.success && result.data.streamId) {
            const monitorResult = await StreamingTests.monitorStream(result.data.streamId, 10000);
            const duration = Date.now() - startTime;

            if (monitorResult.completed && duration <= targetTime) {
                results.passed++;
                TestUtils.logTest('Keyboard Optimization', 'PASS', duration,
                    `Completed in ${duration}ms (target: ${targetTime}ms)`);
                results.tests.push({ name: 'Keyboard Optimization', status: 'pass', duration, targetTime });
            } else {
                results.failed++;
                TestUtils.logTest('Keyboard Optimization', 'FAIL', duration,
                    `Took ${duration}ms (target: ${targetTime}ms)`);
                results.tests.push({ name: 'Keyboard Optimization', status: 'fail', duration, targetTime });
            }

            results.performance.streaming.push({
                test: 'keyboard_optimization',
                duration,
                metTarget: duration <= targetTime
            });
        } else {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('Keyboard Optimization', 'FAIL', duration, result.error);
            results.tests.push({ name: 'Keyboard Optimization', status: 'fail', duration, error: result.error });
        }
    }

    static async testLoadTesting() {
        const concurrentRequests = 5;
        const startTime = Date.now();

        const requests = Array.from({ length: concurrentRequests }, (_, i) => ({
            image_data: CONFIG.TEST_IMAGE,
            context: `Load test ${i + 1}`,
            suggestion_type: 'opener',
            tone: 'playful',
            strategy: 'fast'
        }));

        try {
            const promises = requests.map(request =>
                TestUtils.makeRequest('POST', '/api/v1/stream/analyze', request)
            );

            const results_load = await Promise.all(promises);
            const duration = Date.now() - startTime;

            const successfulRequests = results_load.filter(r => r.success && r.data.streamId);
            const successRate = (successfulRequests.length / concurrentRequests) * 100;

            if (successRate >= 80) {
                results.passed++;
                TestUtils.logTest('Load Testing', 'PASS', duration,
                    `${successfulRequests.length}/${concurrentRequests} concurrent requests successful`);
                results.tests.push({
                    name: 'Load Testing',
                    status: 'pass',
                    duration,
                    successRate,
                    concurrentRequests
                });
            } else {
                results.failed++;
                TestUtils.logTest('Load Testing', 'FAIL', duration,
                    `Only ${successfulRequests.length}/${concurrentRequests} requests successful`);
                results.tests.push({
                    name: 'Load Testing',
                    status: 'fail',
                    duration,
                    successRate,
                    concurrentRequests
                });
            }
        } catch (error) {
            const duration = Date.now() - startTime;
            results.failed++;
            TestUtils.logTest('Load Testing', 'FAIL', duration, error.message);
            results.tests.push({ name: 'Load Testing', status: 'fail', duration, error: error.message });
        }
    }

    static async testMemoryUsage() {
        const startTime = Date.now();
        const result = await TestUtils.makeRequest('GET', '/api/v1/status/system');
        const duration = Date.now() - startTime;

        if (result.success && result.data.resources && result.data.resources.memory) {
            const memory = result.data.resources.memory;
            const heapUsedMB = Math.round(memory.heapUsed / 1024 / 1024);
            const heapTotalMB = Math.round(memory.heapTotal / 1024 / 1024);
            const memoryUsagePercent = (memory.heapUsed / memory.heapTotal) * 100;

            // Memory usage should be reasonable (less than 85%)
            if (memoryUsagePercent < 85) {
                results.passed++;
                TestUtils.logTest('Memory Usage Check', 'PASS', duration,
                    `${heapUsedMB}MB/${heapTotalMB}MB (${Math.round(memoryUsagePercent)}%)`);
                results.tests.push({
                    name: 'Memory Usage',
                    status: 'pass',
                    duration,
                    memoryUsagePercent: Math.round(memoryUsagePercent),
                    heapUsedMB,
                    heapTotalMB
                });
            } else {
                results.failed++;
                TestUtils.logTest('Memory Usage Check', 'FAIL', duration,
                    `High memory usage: ${heapUsedMB}MB/${heapTotalMB}MB (${Math.round(memoryUsagePercent)}%)`);
                results.tests.push({
                    name: 'Memory Usage',
                    status: 'fail',
                    duration,
                    memoryUsagePercent: Math.round(memoryUsagePercent),
                    heapUsedMB,
                    heapTotalMB
                });
            }
        } else {
            results.failed++;
            TestUtils.logTest('Memory Usage Check', 'FAIL', duration, 'Failed to get memory information');
            results.tests.push({ name: 'Memory Usage', status: 'fail', duration, error: 'No memory info' });
        }
    }
}

/**
 * Main test runner
 */
async function runAllTests() {
    TestUtils.log('🚀 Starting Vibe8.ai Streaming Pipeline Test Suite', colors.bold + colors.green);
    TestUtils.log(`Target: ${CONFIG.BASE_URL}`, colors.blue);
    TestUtils.log(`WebSocket: ${CONFIG.WS_URL}`, colors.blue);
    TestUtils.log(`Timeout: ${CONFIG.TIMEOUT}ms`, colors.blue);

    try {
        // Run all test suites
        await HealthTests.runAll();
        await StreamingTests.runAll();
        await WebSocketTests.runAll();
        await PerformanceTests.runAll();

        // Generate final report
        generateFinalReport();

    } catch (error) {
        TestUtils.log(`\n❌ Test suite failed: ${error.message}`, colors.red);
        process.exit(1);
    }
}

/**
 * Generate and display final report
 */
function generateFinalReport() {
    const totalTests = results.passed + results.failed;
    const successRate = totalTests > 0 ? (results.passed / totalTests) * 100 : 0;
    const totalDuration = Date.now() - results.startTime;

    TestUtils.log('\n' + '='.repeat(60), colors.bold);
    TestUtils.log('📊 STREAMING PIPELINE TEST REPORT', colors.bold + colors.blue);
    TestUtils.log('='.repeat(60), colors.bold);

    // Overall results
    TestUtils.log(`\n📈 Overall Results:`, colors.bold);
    TestUtils.log(`  Total Tests: ${totalTests}`);
    TestUtils.log(`  Passed: ${colors.green}${results.passed}${colors.reset}`);
    TestUtils.log(`  Failed: ${colors.red}${results.failed}${colors.reset}`);
    TestUtils.log(`  Success Rate: ${successRate >= 80 ? colors.green : colors.red}${Math.round(successRate)}%${colors.reset}`);
    TestUtils.log(`  Total Duration: ${Math.round(totalDuration / 1000)}s`);

    // Performance summary
    if (results.performance.streaming.length > 0) {
        TestUtils.log(`\n⚡ Performance Summary:`, colors.bold);

        const streamingPerf = results.performance.streaming;
        const avgDuration = streamingPerf.reduce((sum, p) => sum + (p.duration || 0), 0) / streamingPerf.length;
        const sub12sTests = streamingPerf.filter(p => p.duration && p.duration <= 12000).length;
        const sub12sRate = (sub12sTests / streamingPerf.length) * 100;

        TestUtils.log(`  Average Analysis Time: ${Math.round(avgDuration)}ms`);
        TestUtils.log(`  Sub-12s Success Rate: ${sub12sRate >= 80 ? colors.green : colors.red}${Math.round(sub12sRate)}%${colors.reset}`);
        TestUtils.log(`  Tests Under 12s: ${sub12sTests}/${streamingPerf.length}`);
    }

    // Test details
    TestUtils.log(`\n📋 Test Details:`, colors.bold);
    results.tests.forEach(test => {
        const status = test.status === 'pass' ? `${colors.green}PASS${colors.reset}` : `${colors.red}FAIL${colors.reset}`;
        const duration = test.duration ? ` (${test.duration}ms)` : '';
        TestUtils.log(`  ${status} ${test.name}${duration}`);
        if (test.error) {
            TestUtils.log(`    Error: ${test.error}`, colors.yellow);
        }
    });

    // Final verdict
    TestUtils.log('\n' + '='.repeat(60), colors.bold);
    if (successRate >= 80) {
        TestUtils.log('✅ STREAMING PIPELINE TESTS PASSED', colors.bold + colors.green);
        TestUtils.log('🎉 System is ready for production use!', colors.green);
    } else {
        TestUtils.log('❌ STREAMING PIPELINE TESTS FAILED', colors.bold + colors.red);
        TestUtils.log('⚠️  System needs optimization before production!', colors.red);
    }
    TestUtils.log('='.repeat(60), colors.bold);

    // Save detailed results to file
    const reportFile = path.join(__dirname, 'streaming-test-results.json');
    fs.writeFileSync(reportFile, JSON.stringify({
        summary: {
            totalTests,
            passed: results.passed,
            failed: results.failed,
            successRate: Math.round(successRate),
            duration: totalDuration
        },
        tests: results.tests,
        performance: results.performance,
        timestamp: new Date().toISOString()
    }, null, 2));

    TestUtils.log(`\n📄 Detailed results saved to: ${reportFile}`, colors.blue);

    // Exit with appropriate code
    process.exit(successRate >= 80 ? 0 : 1);
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    TestUtils.log('\n⚠️  Test interrupted by user', colors.yellow);
    generateFinalReport();
});

process.on('uncaughtException', (error) => {
    TestUtils.log(`\n💥 Uncaught exception: ${error.message}`, colors.red);
    results.failed++;
    generateFinalReport();
});

// Run tests if called directly
if (require.main === module) {
    runAllTests().catch(error => {
        TestUtils.log(`\n💥 Test runner failed: ${error.message}`, colors.red);
        process.exit(1);
    });
}

module.exports = {
    runAllTests,
    HealthTests,
    StreamingTests,
    WebSocketTests,
    PerformanceTests,
    TestUtils
};