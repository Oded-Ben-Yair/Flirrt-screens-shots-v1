#!/usr/bin/env node

/**
 * Comprehensive Test Suite for Dual-Model AI Pipeline
 *
 * Tests the complete orchestrated pipeline including:
 * - Gemini vision analysis
 * - Grok flirt generation
 * - Performance optimization
 * - A/B testing framework
 * - Error handling and fallbacks
 * - Response quality validation
 */

require('dotenv').config();

const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

// Test configuration
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';
const TEST_API_V2 = `${BASE_URL}/api/v2/flirts`;
const TEST_API_V1 = `${BASE_URL}/api/v1/flirts`;

// Test data
const TEST_IMAGES = {
    simple: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    medium: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAhEAACAQMDBQAAAAAAAAAAAAABAgMABAUGIWGRkqGx4f/EABUBAQEAAAAAAAAAAAAAAAAAAAMF/8QAGhEAAgIDAAAAAAAAAAAAAAAAAAECEgMRkf/aAAwDAQACEQMRAD8AltJagyeH0AthI5xdrLcNM91BF5pX2HaH9bcfaSXWGaRmknyJckliyjqTzSlT54b6bk+h0R//2Q=='
};

const TEST_CONTEXTS = [
    '',
    'Dating app profile photo',
    'outdoor hiking photo with mountain background',
    'group photo at a restaurant with friends',
    'professional headshot in business attire',
    'travel photo at a famous landmark'
];

const TEST_TONES = ['playful', 'witty', 'romantic', 'casual', 'bold', 'sincere'];

class PipelineTestSuite {
    constructor() {
        this.results = {
            totalTests: 0,
            passed: 0,
            failed: 0,
            details: [],
            performance: {
                averageLatency: 0,
                successRate: 0,
                cacheHitRate: 0
            },
            errors: []
        };

        this.startTime = Date.now();
    }

    /**
     * Run complete test suite
     */
    async runTests() {
        console.log('🚀 Starting Dual-Model AI Pipeline Test Suite\n');

        try {
            // Test 1: Health Checks
            await this.testHealthChecks();

            // Test 2: Basic Pipeline Functionality
            await this.testBasicPipeline();

            // Test 3: Performance Optimization
            await this.testPerformanceOptimization();

            // Test 4: A/B Testing Framework
            await this.testABFramework();

            // Test 5: Error Handling & Fallbacks
            await this.testErrorHandling();

            // Test 6: Response Quality Validation
            await this.testResponseQuality();

            // Test 7: Load Testing
            await this.testLoadHandling();

            // Test 8: Integration with Legacy API
            await this.testLegacyIntegration();

            // Generate final report
            await this.generateReport();

        } catch (error) {
            console.error('❌ Test suite failed:', error.message);
            this.results.errors.push({
                test: 'test_suite_execution',
                error: error.message,
                timestamp: new Date().toISOString()
            });
        }
    }

    /**
     * Test health checks for all components
     */
    async testHealthChecks() {
        console.log('🏥 Testing Health Checks...');

        // Test v2 API health
        await this.runTest('V2 API Health Check', async () => {
            const response = await axios.get(`${TEST_API_V2}/health?test=true`, {
                timeout: 10000
            });

            this.assert(response.status === 200, 'Health check should return 200');
            this.assert(response.data.status === 'healthy', 'Status should be healthy');
            this.assert(response.data.components.ai_orchestrator === 'healthy', 'AI orchestrator should be healthy');

            return response.data;
        });

        // Test performance metrics
        await this.runTest('Performance Metrics', async () => {
            const response = await axios.get(`${TEST_API_V2}/metrics`, {
                timeout: 5000,
                validateStatus: () => true // Accept any status for this test
            });

            this.assert(response.status === 200 || response.status === 401, 'Should return 200 or 401 (auth required)');

            return { status: response.status, hasData: !!response.data };
        });

        // Test legacy API health
        await this.runTest('Legacy API Health Check', async () => {
            const response = await axios.get(`http://localhost:3000/health`, {
                timeout: 10000,
                validateStatus: () => true // Accept any status for health check
            });

            this.assert(response.status === 200, 'Legacy health check should return 200');
            this.assert(response.data.status, 'Should have a status field');

            return response.data;
        });
    }

    /**
     * Test basic pipeline functionality
     */
    async testBasicPipeline() {
        console.log('🔄 Testing Basic Pipeline Functionality...');

        // Test simple image analysis and generation
        await this.runTest('Simple Image Processing', async () => {
            const startTime = Date.now();

            const response = await axios.post(`${TEST_API_V2}/generate`, {
                image_data: TEST_IMAGES.simple,
                context: 'test image',
                suggestion_type: 'opener',
                tone: 'playful',
                pipeline_strategy: 'fast'
            }, {
                timeout: 15000
            });

            const latency = Date.now() - startTime;

            this.assert(response.status === 200, 'Should return 200');
            this.assert(response.data.success === true, 'Should be successful');
            this.assert(Array.isArray(response.data.data.suggestions), 'Should return suggestions array');
            this.assert(response.data.data.suggestions.length >= 3, 'Should return at least 3 suggestions');
            this.assert(latency < 20000, 'Should complete within 20 seconds');

            return {
                latency,
                suggestionCount: response.data.data.suggestions.length,
                pipeline: response.data.pipeline.type
            };
        });

        // Test different tones
        for (const tone of TEST_TONES.slice(0, 3)) { // Test first 3 tones
            await this.runTest(`Tone Variation - ${tone}`, async () => {
                const response = await axios.post(`${TEST_API_V2}/generate`, {
                    image_data: TEST_IMAGES.simple,
                    context: `test for ${tone} tone`,
                    suggestion_type: 'opener',
                    tone: tone,
                    pipeline_strategy: 'standard'
                }, {
                    timeout: 20000
                });

                this.assert(response.status === 200, 'Should return 200');
                this.assert(response.data.success === true, 'Should be successful');

                return {
                    tone,
                    suggestionCount: response.data.data.suggestions.length
                };
            });
        }

        // Test different contexts
        for (const context of TEST_CONTEXTS.slice(0, 3)) { // Test first 3 contexts
            await this.runTest(`Context Variation - ${context || 'empty'}`, async () => {
                const response = await axios.post(`${TEST_API_V2}/generate`, {
                    image_data: TEST_IMAGES.simple,
                    context: context,
                    suggestion_type: 'opener',
                    tone: 'playful',
                    pipeline_strategy: 'standard'
                }, {
                    timeout: 20000
                });

                this.assert(response.status === 200, 'Should return 200');
                this.assert(response.data.success === true, 'Should be successful');

                return {
                    context: context || 'empty',
                    suggestionCount: response.data.data.suggestions.length
                };
            });
        }
    }

    /**
     * Test performance optimization features
     */
    async testPerformanceOptimization() {
        console.log('⚡ Testing Performance Optimization...');

        // Test caching behavior
        await this.runTest('Caching Behavior', async () => {
            const testPayload = {
                image_data: TEST_IMAGES.simple,
                context: 'caching test',
                suggestion_type: 'opener',
                tone: 'playful',
                pipeline_strategy: 'fast'
            };

            // First request - should not be cached
            const firstResponse = await axios.post(`${TEST_API_V2}/generate`, testPayload, {
                timeout: 15000
            });

            // Second request - might be cached
            const secondResponse = await axios.post(`${TEST_API_V2}/generate`, testPayload, {
                timeout: 15000
            });

            this.assert(firstResponse.status === 200, 'First request should succeed');
            this.assert(secondResponse.status === 200, 'Second request should succeed');

            return {
                firstLatency: firstResponse.data.pipeline?.total_latency || 0,
                secondLatency: secondResponse.data.pipeline?.total_latency || 0,
                possibleCacheHit: secondResponse.data.pipeline?.total_latency < firstResponse.data.pipeline?.total_latency
            };
        });

        // Test strategy selection
        await this.runTest('Strategy Selection', async () => {
            const strategies = ['fast', 'standard', 'comprehensive'];
            const results = {};

            for (const strategy of strategies) {
                const response = await axios.post(`${TEST_API_V2}/generate`, {
                    image_data: TEST_IMAGES.simple,
                    context: `strategy test: ${strategy}`,
                    suggestion_type: 'opener',
                    tone: 'playful',
                    pipeline_strategy: strategy
                }, {
                    timeout: 30000
                });

                this.assert(response.status === 200, `Strategy ${strategy} should succeed`);
                results[strategy] = {
                    latency: response.data.pipeline?.total_latency || 0,
                    suggestionCount: response.data.data.suggestions.length
                };
            }

            return results;
        });

        // Test keyboard extension optimization
        await this.runTest('Keyboard Extension Optimization', async () => {
            const response = await axios.post(`${TEST_API_V2}/generate`, {
                image_data: TEST_IMAGES.simple,
                context: 'keyboard test',
                suggestion_type: 'opener',
                tone: 'playful',
                pipeline_strategy: 'fast'
            }, {
                headers: {
                    'X-Keyboard-Extension': 'true'
                },
                timeout: 10000
            });

            this.assert(response.status === 200, 'Keyboard request should succeed');
            this.assert(response.data.pipeline?.total_latency < 10000, 'Should be fast for keyboard');

            return {
                latency: response.data.pipeline?.total_latency || 0,
                isKeyboardOptimized: response.data.pipeline?.total_latency < 8000
            };
        });
    }

    /**
     * Test A/B testing framework
     */
    async testABFramework() {
        console.log('🔬 Testing A/B Testing Framework...');

        // Test A/B test assignment
        await this.runTest('A/B Test Assignment', async () => {
            const responses = [];

            // Make multiple requests to see A/B test distribution
            for (let i = 0; i < 5; i++) {
                const response = await axios.post(`${TEST_API_V2}/generate`, {
                    image_data: TEST_IMAGES.simple,
                    context: `ab test ${i}`,
                    suggestion_type: 'opener',
                    tone: 'playful',
                    enable_ab_testing: true
                }, {
                    timeout: 20000
                });

                this.assert(response.status === 200, `Request ${i} should succeed`);
                responses.push({
                    pipeline: response.data.data.metadata.pipeline_used,
                    abTestEnabled: response.data.data.metadata.ab_test_enabled
                });
            }

            return {
                responses: responses.length,
                pipelineDistribution: responses.reduce((acc, r) => {
                    acc[r.pipeline] = (acc[r.pipeline] || 0) + 1;
                    return acc;
                }, {})
            };
        });
    }

    /**
     * Test error handling and fallbacks
     */
    async testErrorHandling() {
        console.log('🛡️ Testing Error Handling & Fallbacks...');

        // Test missing image data
        await this.runTest('Missing Image Data Error', async () => {
            try {
                await axios.post(`${TEST_API_V2}/generate`, {
                    context: 'no image test',
                    suggestion_type: 'opener',
                    tone: 'playful'
                }, {
                    timeout: 10000
                });

                throw new Error('Should have failed with missing image data');
            } catch (error) {
                if (error.response) {
                    this.assert(error.response.status === 400, 'Should return 400 for missing image');
                    this.assert(error.response.data.success === false, 'Should be unsuccessful');
                    return { errorHandled: true, status: error.response.status };
                } else {
                    throw error;
                }
            }
        });

        // Test invalid image data
        await this.runTest('Invalid Image Data Handling', async () => {
            const response = await axios.post(`${TEST_API_V2}/generate`, {
                image_data: 'invalid_base64_data',
                context: 'invalid image test',
                suggestion_type: 'opener',
                tone: 'playful'
            }, {
                timeout: 15000,
                validateStatus: () => true
            });

            // Should either handle gracefully or return emergency fallback
            this.assert(response.status === 200 || response.status === 400, 'Should handle invalid image gracefully');

            if (response.status === 200) {
                this.assert(response.data.success === true, 'Should provide fallback');
                this.assert(Array.isArray(response.data.data.suggestions), 'Should still return suggestions');
            }

            return {
                status: response.status,
                fallbackProvided: response.status === 200
            };
        });

        // Test timeout handling
        await this.runTest('Timeout Handling', async () => {
            try {
                const response = await axios.post(`${TEST_API_V2}/generate`, {
                    image_data: TEST_IMAGES.medium,
                    context: 'timeout test with complex processing',
                    suggestion_type: 'opener',
                    tone: 'playful',
                    pipeline_strategy: 'comprehensive'
                }, {
                    timeout: 1000 // Very short timeout to force timeout
                });

                // If it succeeds within 1 second, that's also valid
                return { completed: true, latency: response.data.pipeline?.total_latency || 0 };

            } catch (error) {
                if (error.code === 'ECONNABORTED') {
                    return { timeoutHandled: true };
                } else {
                    throw error;
                }
            }
        });
    }

    /**
     * Test response quality validation
     */
    async testResponseQuality() {
        console.log('✨ Testing Response Quality Validation...');

        // Test suggestion quality
        await this.runTest('Suggestion Quality Validation', async () => {
            const response = await axios.post(`${TEST_API_V2}/generate`, {
                image_data: TEST_IMAGES.simple,
                context: 'quality test',
                suggestion_type: 'opener',
                tone: 'playful',
                pipeline_strategy: 'standard'
            }, {
                timeout: 20000
            });

            this.assert(response.status === 200, 'Should return 200');
            this.assert(response.data.success === true, 'Should be successful');

            const suggestions = response.data.data.suggestions;
            const qualityMetrics = response.data.data.metadata.quality_metrics;

            // Validate suggestions
            for (const suggestion of suggestions) {
                this.assert(typeof suggestion.text === 'string', 'Suggestion text should be string');
                this.assert(suggestion.text.length > 0, 'Suggestion text should not be empty');
                this.assert(suggestion.text.length <= 280, 'Suggestion should be under 280 characters');
                this.assert(typeof suggestion.confidence === 'number', 'Confidence should be number');
                this.assert(suggestion.confidence >= 0 && suggestion.confidence <= 1, 'Confidence should be 0-1');
            }

            // Validate quality metrics
            this.assert(typeof qualityMetrics.average_score === 'number', 'Should have average score');
            this.assert(qualityMetrics.total_suggestions === suggestions.length, 'Count should match');

            return {
                suggestionCount: suggestions.length,
                averageScore: qualityMetrics.average_score,
                averageLength: suggestions.reduce((sum, s) => sum + s.text.length, 0) / suggestions.length
            };
        });

        // Test uniqueness validation
        await this.runTest('Uniqueness Validation', async () => {
            const response = await axios.post(`${TEST_API_V2}/generate`, {
                image_data: TEST_IMAGES.simple,
                context: 'uniqueness test',
                suggestion_type: 'opener',
                tone: 'playful',
                pipeline_strategy: 'standard'
            }, {
                timeout: 20000
            });

            const suggestions = response.data.data.suggestions;

            // Check for duplicate suggestions
            const texts = suggestions.map(s => s.text.toLowerCase());
            const uniqueTexts = new Set(texts);

            this.assert(uniqueTexts.size === texts.length, 'All suggestions should be unique');

            return {
                totalSuggestions: suggestions.length,
                uniqueSuggestions: uniqueTexts.size,
                duplicatesFound: texts.length - uniqueTexts.size
            };
        });
    }

    /**
     * Test load handling
     */
    async testLoadHandling() {
        console.log('🏋️ Testing Load Handling...');

        // Test concurrent requests
        await this.runTest('Concurrent Request Handling', async () => {
            const concurrentRequests = 5;
            const promises = [];

            for (let i = 0; i < concurrentRequests; i++) {
                promises.push(
                    axios.post(`${TEST_API_V2}/generate`, {
                        image_data: TEST_IMAGES.simple,
                        context: `concurrent test ${i}`,
                        suggestion_type: 'opener',
                        tone: 'playful',
                        pipeline_strategy: 'fast'
                    }, {
                        timeout: 25000
                    })
                );
            }

            const results = await Promise.allSettled(promises);
            const successful = results.filter(r => r.status === 'fulfilled').length;
            const failed = results.filter(r => r.status === 'rejected').length;

            this.assert(successful >= concurrentRequests * 0.8, 'At least 80% should succeed');

            return {
                total: concurrentRequests,
                successful,
                failed,
                successRate: successful / concurrentRequests
            };
        });
    }

    /**
     * Test integration with legacy API
     */
    async testLegacyIntegration() {
        console.log('🔗 Testing Legacy API Integration...');

        // Test legacy API still works
        await this.runTest('Legacy API Functionality', async () => {
            const response = await axios.post(`${TEST_API_V1}/flirts/generate_flirts`, {
                screenshot_id: 'test-screenshot-legacy',
                context: 'legacy test',
                suggestion_type: 'opener',
                tone: 'playful'
            }, {
                headers: {
                    'X-Keyboard-Extension': 'true'
                },
                timeout: 30000,
                validateStatus: () => true
            });

            // Legacy API might return different status codes
            this.assert(response.status === 200 || response.status === 400, 'Should handle legacy request');

            if (response.status === 200) {
                this.assert(response.data.success === true, 'Legacy should be successful');
            }

            return {
                status: response.status,
                hasData: !!response.data,
                successfulLegacy: response.status === 200
            };
        });
    }

    /**
     * Run individual test
     */
    async runTest(testName, testFunction) {
        this.results.totalTests++;
        const startTime = Date.now();

        try {
            console.log(`  ➤ ${testName}...`);
            const result = await testFunction();
            const duration = Date.now() - startTime;

            this.results.passed++;
            this.results.details.push({
                name: testName,
                status: 'PASSED',
                duration,
                result
            });

            console.log(`    ✅ Passed (${duration}ms)`);

        } catch (error) {
            const duration = Date.now() - startTime;

            this.results.failed++;
            this.results.details.push({
                name: testName,
                status: 'FAILED',
                duration,
                error: error.message
            });

            this.results.errors.push({
                test: testName,
                error: error.message,
                timestamp: new Date().toISOString()
            });

            console.log(`    ❌ Failed (${duration}ms): ${error.message}`);
        }
    }

    /**
     * Assertion helper
     */
    assert(condition, message) {
        if (!condition) {
            throw new Error(message);
        }
    }

    /**
     * Generate final test report
     */
    async generateReport() {
        const totalDuration = Date.now() - this.startTime;

        console.log('\n' + '='.repeat(60));
        console.log('🎯 DUAL-MODEL AI PIPELINE TEST RESULTS');
        console.log('='.repeat(60));

        console.log(`\n📊 Summary:`);
        console.log(`  Total Tests: ${this.results.totalTests}`);
        console.log(`  Passed: ${this.results.passed} ✅`);
        console.log(`  Failed: ${this.results.failed} ❌`);
        console.log(`  Success Rate: ${((this.results.passed / this.results.totalTests) * 100).toFixed(1)}%`);
        console.log(`  Total Duration: ${(totalDuration / 1000).toFixed(1)}s`);

        // Calculate performance metrics
        const latencies = this.results.details
            .filter(d => d.result && typeof d.result === 'object' && d.result.latency)
            .map(d => d.result.latency);

        if (latencies.length > 0) {
            const avgLatency = latencies.reduce((sum, l) => sum + l, 0) / latencies.length;
            console.log(`  Average API Latency: ${avgLatency.toFixed(0)}ms`);
        }

        // Show failed tests
        if (this.results.failed > 0) {
            console.log(`\n❌ Failed Tests:`);
            this.results.details
                .filter(d => d.status === 'FAILED')
                .forEach(test => {
                    console.log(`  • ${test.name}: ${test.error}`);
                });
        }

        // Overall assessment
        console.log(`\n🎯 Overall Assessment:`);
        const successRate = (this.results.passed / this.results.totalTests);

        if (successRate >= 0.95) {
            console.log('  🟢 EXCELLENT - Pipeline is production ready!');
        } else if (successRate >= 0.85) {
            console.log('  🟡 GOOD - Pipeline is mostly functional with minor issues');
        } else if (successRate >= 0.70) {
            console.log('  🟠 FAIR - Pipeline has significant issues that need attention');
        } else {
            console.log('  🔴 POOR - Pipeline has major issues and is not ready for production');
        }

        // Save detailed results
        await this.saveResults();

        console.log('\n' + '='.repeat(60));

        // Exit with appropriate code
        process.exit(this.results.failed > 0 ? 1 : 0);
    }

    /**
     * Save test results to file
     */
    async saveResults() {
        try {
            const resultsFile = path.join(__dirname, 'test-results.json');
            const detailedResults = {
                ...this.results,
                timestamp: new Date().toISOString(),
                environment: {
                    baseUrl: BASE_URL,
                    nodeVersion: process.version,
                    platform: process.platform
                }
            };

            await fs.writeFile(resultsFile, JSON.stringify(detailedResults, null, 2));
            console.log(`\n📄 Detailed results saved to: ${resultsFile}`);

        } catch (error) {
            console.warn(`\n⚠️ Failed to save results: ${error.message}`);
        }
    }
}

// Run tests if this file is executed directly
if (require.main === module) {
    const testSuite = new PipelineTestSuite();
    testSuite.runTests().catch(error => {
        console.error('Fatal test error:', error);
        process.exit(1);
    });
}

module.exports = PipelineTestSuite;