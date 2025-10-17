#!/usr/bin/env node

/**
 * Grok-4 Fast Performance Testing Suite
 *
 * Comprehensive performance validation for:
 * - Sub-second response times for simple requests
 * - <3 second response times for complex requests
 * - Streaming performance validation
 * - Load balancing and circuit breaker testing
 * - Cache performance validation
 */

require('dotenv').config();

const axios = require('axios');
const colors = require('colors');

class Grok4FastPerformanceTest {
    constructor() {
        this.baseURL = process.env.TEST_BASE_URL || 'http://localhost:3000';
        this.results = [];
        this.targetLatencies = {
            simple: 1000,      // <1 second for simple requests
            standard: 3000,    // <3 seconds for standard requests
            complex: 5000,     // <5 seconds for complex requests
            streaming: 200     // <200ms for first chunk in streaming
        };

        this.testScenarios = this.createTestScenarios();
    }

    createTestScenarios() {
        return {
            // Tier 1 Tests (Simple - Target <1 second)
            simple: [
                {
                    name: 'Quick Keyboard Opener',
                    request: {
                        context: 'Quick opener needed',
                        suggestion_type: 'opener',
                        tone: 'playful'
                    },
                    headers: { 'X-Keyboard-Extension': 'true' },
                    query: { fast: 'true' },
                    expectedTier: 'tier1',
                    target: 1000
                },
                {
                    name: 'Simple Greeting',
                    request: {
                        context: 'Hi there!',
                        suggestion_type: 'response',
                        tone: 'casual'
                    },
                    headers: { 'X-Keyboard-Extension': 'true' },
                    expectedTier: 'tier1',
                    target: 1000
                },
                {
                    name: 'Brief Compliment',
                    request: {
                        context: 'Quick compliment',
                        suggestion_type: 'compliment',
                        tone: 'sweet'
                    },
                    query: { fast: 'true' },
                    expectedTier: 'tier1',
                    target: 1000
                }
            ],

            // Tier 2 Tests (Standard - Target <3 seconds)
            standard: [
                {
                    name: 'Creative Flirt Generation',
                    request: {
                        context: 'Someone who loves hiking and outdoor adventures',
                        suggestion_type: 'flirty',
                        tone: 'witty',
                        user_preferences: {
                            humor_style: 'clever',
                            interests: ['outdoors', 'adventure']
                        }
                    },
                    expectedTier: 'tier2',
                    target: 3000
                },
                {
                    name: 'Romantic Response',
                    request: {
                        context: 'Had a wonderful time on our coffee date yesterday',
                        suggestion_type: 'response',
                        tone: 'romantic',
                        user_preferences: {
                            relationship_stage: 'early_dating'
                        }
                    },
                    expectedTier: 'tier2',
                    target: 3000
                },
                {
                    name: 'Intellectual Conversation',
                    request: {
                        context: 'Discussion about favorite books and philosophy',
                        suggestion_type: 'question',
                        tone: 'intellectual',
                        user_preferences: {
                            conversation_style: 'deep'
                        }
                    },
                    expectedTier: 'tier2',
                    target: 3000
                }
            ],

            // Tier 3 Tests (Complex - Target <5 seconds)
            complex: [
                {
                    name: 'Comprehensive Profile Analysis',
                    request: {
                        context: 'Profile shows someone who is a software engineer, loves travel, has photos from 15 different countries, plays guitar, volunteers at animal shelters, and mentions loving both coffee and wine. Recent photo shows them at a marathon.',
                        suggestion_type: 'opener',
                        tone: 'playful',
                        user_preferences: {
                            analysis_depth: 'comprehensive',
                            personality_matching: true
                        }
                    },
                    expectedTier: 'tier3',
                    target: 5000
                },
                {
                    name: 'Multi-Context Analysis',
                    request: {
                        context: 'Long conversation history: Started with travel talk, moved to career discussion, shared funny stories about pets, discussed favorite restaurants, talked about fitness goals, and recent messages show planning to meet up this weekend.',
                        suggestion_type: 'response',
                        tone: 'confident',
                        user_preferences: {
                            conversation_analysis: true,
                            context_aware: true
                        }
                    },
                    expectedTier: 'tier3',
                    target: 5000
                }
            ],

            // Streaming Tests
            streaming: [
                {
                    name: 'Real-time Creative Generation',
                    request: {
                        context: 'Creative response needed for artistic photographer',
                        suggestion_type: 'creative',
                        tone: 'artistic'
                    },
                    streaming: true,
                    target: 200 // First chunk target
                }
            ]
        };
    }

    async runPerformanceTests() {
        console.log('\n🚀 Starting Grok-4 Fast Performance Test Suite'.cyan.bold);
        console.log('=' * 60);

        try {
            // Pre-test health check
            await this.performHealthCheck();

            // Run all test categories
            await this.runSimpleTests();
            await this.runStandardTests();
            await this.runComplexTests();
            await this.runStreamingTests();
            await this.runBenchmarkTest();
            await this.runCacheTests();
            await this.runLoadTests();

            // Generate comprehensive report
            this.generatePerformanceReport();

        } catch (error) {
            console.error('\n❌ Test suite failed:'.red.bold, error.message);
            process.exit(1);
        }
    }

    async performHealthCheck() {
        console.log('\n🏥 Health Check'.yellow.bold);

        try {
            const response = await axios.get(`${this.baseURL}/api/v3/grok4-fast/health`);

            if (response.data.status === 'healthy') {
                console.log('✅ All services healthy'.green);
                console.log(`   Grok-4 Fast: ${response.data.services.grok4Fast.status}`);
                console.log(`   Orchestrator: ${response.data.services.orchestrator.status}`);
            } else {
                throw new Error(`Services not healthy: ${response.data.status}`);
            }
        } catch (error) {
            throw new Error(`Health check failed: ${error.message}`);
        }
    }

    async runSimpleTests() {
        console.log('\n⚡ Tier 1 Tests (Simple - Target <1 second)'.yellow.bold);

        for (const test of this.testScenarios.simple) {
            await this.runSingleTest(test, 'simple');
        }

        this.analyzeResults('simple');
    }

    async runStandardTests() {
        console.log('\n🎯 Tier 2 Tests (Standard - Target <3 seconds)'.yellow.bold);

        for (const test of this.testScenarios.standard) {
            await this.runSingleTest(test, 'standard');
        }

        this.analyzeResults('standard');
    }

    async runComplexTests() {
        console.log('\n🧠 Tier 3 Tests (Complex - Target <5 seconds)'.yellow.bold);

        for (const test of this.testScenarios.complex) {
            await this.runSingleTest(test, 'complex');
        }

        this.analyzeResults('complex');
    }

    async runStreamingTests() {
        console.log('\n📡 Streaming Tests (Target <200ms first chunk)'.yellow.bold);

        for (const test of this.testScenarios.streaming) {
            await this.runStreamingTest(test);
        }

        this.analyzeResults('streaming');
    }

    async runSingleTest(test, category) {
        const startTime = Date.now();
        const correlationId = `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        try {
            console.log(`  Testing: ${test.name}...`.cyan);

            const config = {
                method: 'POST',
                url: `${this.baseURL}/api/v3/grok4-fast/generate-fast-flirts`,
                data: test.request,
                headers: {
                    'Content-Type': 'application/json',
                    'X-Correlation-ID': correlationId,
                    ...test.headers
                },
                params: test.query || {},
                timeout: test.target + 5000 // Allow some buffer
            };

            const response = await axios(config);
            const latency = Date.now() - startTime;
            const targetMet = latency < test.target;

            const result = {
                name: test.name,
                category,
                latency,
                target: test.target,
                targetMet,
                tier: response.data.performance?.tier,
                model: response.data.performance?.model,
                cacheHit: response.data.performance?.cacheHit,
                qualityScore: response.data.data?.qualityScore,
                suggestionsCount: response.data.data?.suggestions?.length || 0,
                success: true,
                correlationId
            };

            this.results.push(result);

            const status = targetMet ? '✅' : '⚠️';
            const latencyColor = targetMet ? 'green' : 'yellow';

            console.log(`    ${status} ${latency}ms (target: ${test.target}ms) - Tier: ${result.tier || 'unknown'}`[latencyColor]);

            if (test.expectedTier && result.tier !== test.expectedTier) {
                console.log(`    ⚠️  Expected ${test.expectedTier}, got ${result.tier}`.yellow);
            }

        } catch (error) {
            const latency = Date.now() - startTime;

            const result = {
                name: test.name,
                category,
                latency,
                target: test.target,
                targetMet: false,
                success: false,
                error: error.message,
                correlationId
            };

            this.results.push(result);

            console.log(`    ❌ Failed (${latency}ms): ${error.message}`.red);
        }

        // Brief pause between tests
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    async runStreamingTest(test) {
        const startTime = Date.now();
        let firstChunkTime = null;
        const correlationId = `stream_test_${Date.now()}`;

        try {
            console.log(`  Testing: ${test.name}...`.cyan);

            const config = {
                method: 'POST',
                url: `${this.baseURL}/api/v3/grok4-fast/generate-streaming-flirts`,
                data: test.request,
                headers: {
                    'Content-Type': 'application/json',
                    'X-Correlation-ID': correlationId,
                    'Accept': 'text/event-stream'
                },
                responseType: 'stream',
                timeout: 15000
            };

            const response = await axios(config);

            response.data.on('data', (chunk) => {
                if (!firstChunkTime) {
                    firstChunkTime = Date.now();
                    const firstChunkLatency = firstChunkTime - startTime;

                    const result = {
                        name: test.name,
                        category: 'streaming',
                        latency: firstChunkLatency,
                        target: test.target,
                        targetMet: firstChunkLatency < test.target,
                        success: true,
                        correlationId,
                        streaming: true
                    };

                    this.results.push(result);

                    const status = result.targetMet ? '✅' : '⚠️';
                    const latencyColor = result.targetMet ? 'green' : 'yellow';

                    console.log(`    ${status} First chunk: ${firstChunkLatency}ms (target: ${test.target}ms)`[latencyColor]);
                }
            });

            // Wait for stream to complete or timeout
            await new Promise((resolve, reject) => {
                response.data.on('end', resolve);
                response.data.on('error', reject);
                setTimeout(() => resolve(), 10000); // 10 second timeout
            });

        } catch (error) {
            const latency = Date.now() - startTime;

            const result = {
                name: test.name,
                category: 'streaming',
                latency,
                target: test.target,
                targetMet: false,
                success: false,
                error: error.message,
                correlationId,
                streaming: true
            };

            this.results.push(result);

            console.log(`    ❌ Streaming failed (${latency}ms): ${error.message}`.red);
        }
    }

    async runBenchmarkTest() {
        console.log('\n📊 Benchmark Test (All Tiers)'.yellow.bold);

        try {
            const response = await axios.post(`${this.baseURL}/api/v3/grok4-fast/benchmark`);
            const benchmark = response.data.benchmark;

            console.log('  Tier Performance:'.cyan);
            console.log(`    Tier 1 (Non-reasoning): ${benchmark.tier1.latency}ms - ${benchmark.tier1.success ? '✅' : '❌'}`);
            console.log(`    Tier 2 (Reasoning): ${benchmark.tier2.latency}ms - ${benchmark.tier2.success ? '✅' : '❌'}`);
            console.log(`    Orchestrator: ${benchmark.orchestrator.latency}ms - ${benchmark.orchestrator.success ? '✅' : '❌'}`);

            // Store benchmark results
            this.benchmarkResults = benchmark;

        } catch (error) {
            console.log(`    ❌ Benchmark failed: ${error.message}`.red);
        }
    }

    async runCacheTests() {
        console.log('\n💾 Cache Performance Tests'.yellow.bold);

        const cacheTestRequest = {
            context: 'Cache test request',
            suggestion_type: 'opener',
            tone: 'playful'
        };

        try {
            // First request (cache miss)
            console.log('  Testing cache miss...'.cyan);
            const firstResponse = await axios.post(
                `${this.baseURL}/api/v3/grok4-fast/generate-fast-flirts`,
                cacheTestRequest,
                { headers: { 'Content-Type': 'application/json' } }
            );

            const firstLatency = parseInt(firstResponse.data.performance.totalLatency);
            console.log(`    Cache miss: ${firstLatency}ms`);

            // Second request (cache hit)
            console.log('  Testing cache hit...'.cyan);
            const secondResponse = await axios.post(
                `${this.baseURL}/api/v3/grok4-fast/generate-fast-flirts`,
                cacheTestRequest,
                { headers: { 'Content-Type': 'application/json' } }
            );

            const secondLatency = parseInt(secondResponse.data.performance.totalLatency);
            const cacheHit = secondResponse.data.performance.cacheHit;

            console.log(`    Cache hit: ${secondLatency}ms - ${cacheHit ? '✅ Cached' : '⚠️ Not cached'}`);

            if (cacheHit && secondLatency < firstLatency * 0.5) {
                console.log(`    ✅ Cache improved performance by ${Math.round((1 - secondLatency/firstLatency) * 100)}%`.green);
            }

        } catch (error) {
            console.log(`    ❌ Cache test failed: ${error.message}`.red);
        }
    }

    async runLoadTests() {
        console.log('\n🔄 Load Balancing Tests'.yellow.bold);

        const loadTestRequests = Array(5).fill(null).map((_, i) => ({
            context: `Load test request ${i + 1}`,
            suggestion_type: 'opener',
            tone: 'playful'
        }));

        try {
            console.log('  Testing concurrent requests...'.cyan);
            const startTime = Date.now();

            const promises = loadTestRequests.map(request =>
                axios.post(
                    `${this.baseURL}/api/v3/grok4-fast/generate-fast-flirts`,
                    request,
                    { headers: { 'Content-Type': 'application/json' } }
                )
            );

            const responses = await Promise.all(promises);
            const totalTime = Date.now() - startTime;

            const latencies = responses.map(r => parseInt(r.data.performance.totalLatency));
            const avgLatency = latencies.reduce((sum, lat) => sum + lat, 0) / latencies.length;
            const maxLatency = Math.max(...latencies);

            console.log(`    Concurrent requests: ${responses.length} completed in ${totalTime}ms`);
            console.log(`    Average latency: ${Math.round(avgLatency)}ms`);
            console.log(`    Max latency: ${maxLatency}ms`);

            if (maxLatency < this.targetLatencies.standard) {
                console.log(`    ✅ Load balancing working well`.green);
            } else {
                console.log(`    ⚠️ High latency under load`.yellow);
            }

        } catch (error) {
            console.log(`    ❌ Load test failed: ${error.message}`.red);
        }
    }

    analyzeResults(category) {
        const categoryResults = this.results.filter(r => r.category === category);
        const successful = categoryResults.filter(r => r.success);
        const targetMet = successful.filter(r => r.targetMet);

        const avgLatency = successful.length > 0 ?
            successful.reduce((sum, r) => sum + r.latency, 0) / successful.length : 0;

        const successRate = (successful.length / categoryResults.length * 100).toFixed(1);
        const targetMetRate = successful.length > 0 ?
            (targetMet.length / successful.length * 100).toFixed(1) : 0;

        console.log(`\n  📈 ${category.toUpperCase()} Results:`.magenta);
        console.log(`    Success Rate: ${successRate}% (${successful.length}/${categoryResults.length})`);
        console.log(`    Target Met Rate: ${targetMetRate}% (${targetMet.length}/${successful.length})`);
        console.log(`    Average Latency: ${Math.round(avgLatency)}ms`);

        if (parseFloat(targetMetRate) >= 80) {
            console.log(`    ✅ Performance targets met`.green);
        } else {
            console.log(`    ⚠️ Performance targets need improvement`.yellow);
        }
    }

    generatePerformanceReport() {
        console.log('\n📊 COMPREHENSIVE PERFORMANCE REPORT'.cyan.bold);
        console.log('=' * 60);

        const totalTests = this.results.length;
        const successfulTests = this.results.filter(r => r.success);
        const targetMetTests = successfulTests.filter(r => r.targetMet);

        console.log('\n🎯 Overall Performance:'.yellow.bold);
        console.log(`   Total Tests: ${totalTests}`);
        console.log(`   Successful: ${successfulTests.length} (${(successfulTests.length/totalTests*100).toFixed(1)}%)`);
        console.log(`   Targets Met: ${targetMetTests.length} (${(targetMetTests.length/successfulTests.length*100).toFixed(1)}%)`);

        // Performance by tier
        console.log('\n⚡ Performance by Tier:'.yellow.bold);
        ['simple', 'standard', 'complex', 'streaming'].forEach(category => {
            const categoryResults = this.results.filter(r => r.category === category && r.success);
            if (categoryResults.length > 0) {
                const avgLatency = categoryResults.reduce((sum, r) => sum + r.latency, 0) / categoryResults.length;
                const targetMet = categoryResults.filter(r => r.targetMet).length;
                const targetRate = (targetMet / categoryResults.length * 100).toFixed(1);

                const status = parseFloat(targetRate) >= 80 ? '✅' : '⚠️';
                console.log(`   ${status} ${category.padEnd(10)}: ${Math.round(avgLatency)}ms avg, ${targetRate}% targets met`);
            }
        });

        // Model performance
        if (this.benchmarkResults) {
            console.log('\n🤖 Model Performance:'.yellow.bold);
            console.log(`   Grok-4 Non-reasoning: ${this.benchmarkResults.tier1.latency}ms`);
            console.log(`   Grok-4 Reasoning: ${this.benchmarkResults.tier2.latency}ms`);
            console.log(`   Enhanced Orchestrator: ${this.benchmarkResults.orchestrator.latency}ms`);
        }

        // Recommendations
        console.log('\n💡 Recommendations:'.yellow.bold);

        const simpleResults = this.results.filter(r => r.category === 'simple' && r.success);
        const simpleAvg = simpleResults.reduce((sum, r) => sum + r.latency, 0) / simpleResults.length;

        if (simpleAvg > this.targetLatencies.simple) {
            console.log(`   ⚠️  Simple requests averaging ${Math.round(simpleAvg)}ms (target: ${this.targetLatencies.simple}ms)`);
            console.log(`       Consider optimizing Tier 1 pipeline or caching`);
        } else {
            console.log(`   ✅ Simple requests performing well (${Math.round(simpleAvg)}ms avg)`);
        }

        const complexResults = this.results.filter(r => r.category === 'complex' && r.success);
        if (complexResults.length > 0) {
            const complexAvg = complexResults.reduce((sum, r) => sum + r.latency, 0) / complexResults.length;
            if (complexAvg > this.targetLatencies.complex) {
                console.log(`   ⚠️  Complex requests averaging ${Math.round(complexAvg)}ms (target: ${this.targetLatencies.complex}ms)`);
                console.log(`       Consider Tier 3 optimizations or fallback improvements`);
            } else {
                console.log(`   ✅ Complex requests performing well (${Math.round(complexAvg)}ms avg)`);
            }
        }

        // Final verdict
        const overallTargetRate = (targetMetTests.length / successfulTests.length * 100);
        console.log('\n🏆 FINAL VERDICT:'.cyan.bold);

        if (overallTargetRate >= 90) {
            console.log('   ✅ EXCELLENT - Performance targets consistently met'.green.bold);
        } else if (overallTargetRate >= 75) {
            console.log('   ✅ GOOD - Most performance targets met'.green);
        } else if (overallTargetRate >= 60) {
            console.log('   ⚠️  NEEDS IMPROVEMENT - Some performance issues'.yellow.bold);
        } else {
            console.log('   ❌ POOR - Significant performance issues need addressing'.red.bold);
        }

        console.log(`   Overall Target Achievement: ${overallTargetRate.toFixed(1)}%`);
        console.log('\n🚀 Grok-4 Fast Performance Testing Complete!\n'.cyan.bold);
    }
}

// Run the performance tests
async function main() {
    const tester = new Grok4FastPerformanceTest();
    await tester.runPerformanceTests();
}

// Handle script execution
if (require.main === module) {
    main().catch(error => {
        console.error('\n❌ Performance test suite failed:'.red.bold, error.message);
        process.exit(1);
    });
}

module.exports = Grok4FastPerformanceTest;