const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000/api/v1';

// Test data - use real screenshot for proper testing
const realTestImagePath = path.join(__dirname, 'real-test-screenshot.png');
const testImagePath = path.join(__dirname, 'test-screenshot.png');

// Check for real screenshot first, fallback to 1x1 pixel if needed
let actualTestImagePath = realTestImagePath;
if (!fs.existsSync(realTestImagePath)) {
    console.log('Real test screenshot not found, checking for basic test image...');
    actualTestImagePath = testImagePath;

    if (!fs.existsSync(testImagePath)) {
        // Create a simple 1x1 pixel PNG for testing as fallback
        const testImageBuffer = Buffer.from([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
            0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x01, 0x02, 0x16, 0x05, 0x5D, 0x00, 0x00, 0x00, 0x00, 0x49,
            0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
        ]);
        fs.writeFileSync(testImagePath, testImageBuffer);
        console.log('Created basic 1x1 test image:', testImagePath);
    }
} else {
    console.log('Using real test screenshot:', realTestImagePath);
}

// Mock authentication token for testing
const MOCK_TOKEN = 'Bearer test-token-for-api-testing';

async function testAnalyzeScreenshot() {
    console.log('\n=== Testing POST /api/v1/analysis/analyze_screenshot ===');

    try {
        const form = new FormData();
        form.append('screenshot', fs.createReadStream(actualTestImagePath));
        form.append('context', 'This is a test dating app screenshot');
        form.append('preferences', JSON.stringify({ tone: 'playful' }));

        const response = await axios.post(`${BASE_URL}/analysis/analyze_screenshot`, form, {
            headers: {
                ...form.getHeaders(),
                'Authorization': MOCK_TOKEN
            },
            timeout: 45000
        });

        console.log('✅ Screenshot analysis successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        return response.data.data.screenshot_id;
    } catch (error) {
        console.log('❌ Screenshot analysis failed:');
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Error:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.log('Error:', error.message);
        }
        return null;
    }
}

async function testGenerateFlirts(screenshotId) {
    console.log('\n=== Testing POST /api/v1/flirts/generate_flirts ===');

    try {
        const response = await axios.post(`${BASE_URL}/flirts/generate_flirts`, {
            screenshot_id: screenshotId || 'test-screenshot-id',
            context: 'Testing flirt generation',
            suggestion_type: 'opener',
            tone: 'playful',
            user_preferences: {
                style: 'witty',
                length: 'short'
            }
        }, {
            headers: {
                'Authorization': MOCK_TOKEN,
                'Content-Type': 'application/json'
            },
            timeout: 45000
        });

        console.log('✅ Flirt generation successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        return response.data.data.suggestions[0]?.id;
    } catch (error) {
        console.log('❌ Flirt generation failed:');
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Error:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.log('Error:', error.message);
        }
        return null;
    }
}

async function testSynthesizeVoice(suggestionId) {
    console.log('\n=== Testing POST /api/v1/voice/synthesize_voice ===');

    try {
        const response = await axios.post(`${BASE_URL}/voice/synthesize_voice`, {
            text: 'Hey there! How are you doing today?',
            flirt_suggestion_id: suggestionId,
            voice_model: 'eleven_monolingual_v1',
            voice_id: 'pMsXgVXv3BLzUgSXRplE',
            voice_settings: {
                stability: 0.5,
                similarity_boost: 0.8,
                style: 0.5,
                use_speaker_boost: true
            }
        }, {
            headers: {
                'Authorization': MOCK_TOKEN,
                'Content-Type': 'application/json'
            },
            timeout: 45000
        });

        console.log('✅ Voice synthesis successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        return response.data.data.voice_message_id;
    } catch (error) {
        console.log('❌ Voice synthesis failed:');
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Error:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.log('Error:', error.message);
        }
        return null;
    }
}

async function testDeleteUserData() {
    console.log('\n=== Testing DELETE /api/v1/user/{id}/data ===');

    try {
        // Use the same user ID that the mock token provides
        const response = await axios.delete(`${BASE_URL}/user/test-user-id/data`, {
            headers: {
                'Authorization': MOCK_TOKEN
            },
            timeout: 30000
        });

        console.log('✅ User data deletion successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.log('❌ User data deletion failed:');
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Error:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.log('Error:', error.message);
        }
    }
}

// Main test function
async function runTests() {
    console.log('🚀 Starting API endpoint tests...');
    console.log('Server URL:', BASE_URL);

    // Test all endpoints
    const screenshotId = await testAnalyzeScreenshot();
    const suggestionId = await testGenerateFlirts(screenshotId);
    const voiceMessageId = await testSynthesizeVoice(suggestionId);
    await testDeleteUserData();

    console.log('\n🏁 All tests completed!');
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Tests interrupted');
    process.exit(0);
});

// Run tests if this script is executed directly
if (require.main === module) {
    runTests().catch(console.error);
}

module.exports = {
    testAnalyzeScreenshot,
    testGenerateFlirts,
    testSynthesizeVoice,
    testDeleteUserData,
    runTests
};