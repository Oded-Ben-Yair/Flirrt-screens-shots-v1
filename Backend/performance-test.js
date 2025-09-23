const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000/api/v1';
const MOCK_TOKEN = 'Bearer test-token-for-api-testing';
const testImagePath = path.join(__dirname, 'real-test-screenshot.png');

async function measureEndpointPerformance() {
    console.log('🚀 Starting Performance Tests...\n');

    const results = {};

    // Test 1: Screenshot Analysis
    console.log('1. Testing Screenshot Analysis Performance...');
    const analysisStartTime = Date.now();

    try {
        const form = new FormData();
        form.append('screenshot', fs.createReadStream(testImagePath));
        form.append('context', 'Performance test screenshot');

        const response = await axios.post(`${BASE_URL}/analysis/analyze_screenshot`, form, {
            headers: {
                ...form.getHeaders(),
                'Authorization': MOCK_TOKEN
            },
            timeout: 30000
        });

        const analysisEndTime = Date.now();
        const analysisTime = analysisEndTime - analysisStartTime;

        results.screenshot_analysis = {
            duration_ms: analysisTime,
            duration_seconds: (analysisTime / 1000).toFixed(2),
            success: true,
            screenshot_id: response.data.data.screenshot_id
        };

        console.log(`   ✅ Completed in ${results.screenshot_analysis.duration_seconds}s`);
    } catch (error) {
        results.screenshot_analysis = {
            success: false,
            error: error.message
        };
        console.log(`   ❌ Failed: ${error.message}`);
    }

    // Test 2: Flirt Generation
    console.log('\n2. Testing Flirt Generation Performance...');
    const flirtStartTime = Date.now();

    try {
        const response = await axios.post(`${BASE_URL}/flirts/generate_flirts`, {
            screenshot_id: results.screenshot_analysis.screenshot_id || 'test-screenshot',
            context: 'Performance test',
            suggestion_type: 'opener',
            tone: 'playful'
        }, {
            headers: {
                'Authorization': MOCK_TOKEN,
                'Content-Type': 'application/json'
            },
            timeout: 30000
        });

        const flirtEndTime = Date.now();
        const flirtTime = flirtEndTime - flirtStartTime;

        results.flirt_generation = {
            duration_ms: flirtTime,
            duration_seconds: (flirtTime / 1000).toFixed(2),
            success: true,
            suggestions_count: response.data.data.suggestions.length,
            suggestion_id: response.data.data.suggestions[0]?.id
        };

        console.log(`   ✅ Completed in ${results.flirt_generation.duration_seconds}s`);
        console.log(`   📊 Generated ${results.flirt_generation.suggestions_count} suggestions`);
    } catch (error) {
        results.flirt_generation = {
            success: false,
            error: error.message
        };
        console.log(`   ❌ Failed: ${error.message}`);
    }

    // Test 3: Voice Synthesis
    console.log('\n3. Testing Voice Synthesis Performance...');
    const voiceStartTime = Date.now();

    try {
        const response = await axios.post(`${BASE_URL}/voice/synthesize_voice`, {
            text: 'Hey there! This is a performance test for voice synthesis.',
            flirt_suggestion_id: results.flirt_generation.suggestion_id,
            voice_model: 'eleven_monolingual_v1'
        }, {
            headers: {
                'Authorization': MOCK_TOKEN,
                'Content-Type': 'application/json'
            },
            timeout: 30000
        });

        const voiceEndTime = Date.now();
        const voiceTime = voiceEndTime - voiceStartTime;

        results.voice_synthesis = {
            duration_ms: voiceTime,
            duration_seconds: (voiceTime / 1000).toFixed(2),
            success: true,
            file_size: response.data.data.file_size,
            voice_message_id: response.data.data.voice_message_id
        };

        console.log(`   ✅ Completed in ${results.voice_synthesis.duration_seconds}s`);
        console.log(`   🎵 Generated ${(results.voice_synthesis.file_size / 1024).toFixed(1)}KB audio file`);
    } catch (error) {
        results.voice_synthesis = {
            success: false,
            error: error.message
        };
        console.log(`   ❌ Failed: ${error.message}`);
    }

    // Test 4: Data Deletion
    console.log('\n4. Testing Data Deletion Performance...');
    const deletionStartTime = Date.now();

    try {
        await axios.delete(`${BASE_URL}/user/test-user-id/data`, {
            headers: {
                'Authorization': MOCK_TOKEN
            },
            timeout: 30000
        });

        const deletionEndTime = Date.now();
        const deletionTime = deletionEndTime - deletionStartTime;

        results.data_deletion = {
            duration_ms: deletionTime,
            duration_seconds: (deletionTime / 1000).toFixed(2),
            success: true
        };

        console.log(`   ✅ Completed in ${results.data_deletion.duration_seconds}s`);
    } catch (error) {
        results.data_deletion = {
            success: false,
            error: error.message
        };
        console.log(`   ❌ Failed: ${error.message}`);
    }

    // Calculate total time
    const totalTime = Object.values(results)
        .filter(r => r.success && r.duration_ms)
        .reduce((sum, r) => sum + r.duration_ms, 0);

    results.summary = {
        total_duration_ms: totalTime,
        total_duration_seconds: (totalTime / 1000).toFixed(2),
        successful_tests: Object.values(results).filter(r => r.success).length,
        failed_tests: Object.values(results).filter(r => !r.success).length
    };

    // Performance Analysis
    console.log('\n📊 PERFORMANCE SUMMARY');
    console.log('========================');
    console.log(`Total Test Duration: ${results.summary.total_duration_seconds}s`);
    console.log(`Successful Tests: ${results.summary.successful_tests}`);
    console.log(`Failed Tests: ${results.summary.failed_tests}`);

    console.log('\n⏱️  Individual Performance:');
    if (results.screenshot_analysis.success) {
        const status = parseFloat(results.screenshot_analysis.duration_seconds) < 15 ? '✅ EXCELLENT' : '⚠️  SLOW';
        console.log(`   Screenshot Analysis: ${results.screenshot_analysis.duration_seconds}s ${status}`);
    }

    if (results.flirt_generation.success) {
        const status = parseFloat(results.flirt_generation.duration_seconds) < 15 ? '✅ EXCELLENT' : '⚠️  SLOW';
        console.log(`   Flirt Generation: ${results.flirt_generation.duration_seconds}s ${status}`);
    }

    if (results.voice_synthesis.success) {
        const status = parseFloat(results.voice_synthesis.duration_seconds) < 10 ? '✅ EXCELLENT' : '⚠️  SLOW';
        console.log(`   Voice Synthesis: ${results.voice_synthesis.duration_seconds}s ${status}`);
    }

    if (results.data_deletion.success) {
        const status = parseFloat(results.data_deletion.duration_seconds) < 2 ? '✅ EXCELLENT' : '⚠️  SLOW';
        console.log(`   Data Deletion: ${results.data_deletion.duration_seconds}s ${status}`);
    }

    console.log('\n🎯 PRODUCTION READINESS');
    console.log('========================');
    const allTestsPassed = results.summary.failed_tests === 0;
    const performanceGood = parseFloat(results.summary.total_duration_seconds) < 50;

    if (allTestsPassed && performanceGood) {
        console.log('🚀 READY FOR PRODUCTION');
        console.log('   ✅ All endpoints working');
        console.log('   ✅ Performance within targets');
        console.log('   ✅ Real API integrations functional');
    } else {
        console.log('⚠️  NEEDS OPTIMIZATION');
        if (!allTestsPassed) console.log('   ❌ Some endpoints failing');
        if (!performanceGood) console.log('   ❌ Performance below targets');
    }

    // Save results to file
    const resultsFile = path.join(__dirname, 'performance-results.json');
    fs.writeFileSync(resultsFile, JSON.stringify(results, null, 2));
    console.log(`\n📝 Results saved to: ${resultsFile}`);

    return results;
}

// Run the performance tests
if (require.main === module) {
    measureEndpointPerformance().catch(console.error);
}

module.exports = { measureEndpointPerformance };