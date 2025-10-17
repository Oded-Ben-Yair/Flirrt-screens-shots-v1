#!/usr/bin/env node

/**
 * Flirrt.ai Vision API Test Suite
 * Tests intelligent profile analysis with real dating app screenshots
 * October 2025 - Claude Code Best Practices
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');

const API_URL = 'http://localhost:3000/api/v1/flirts/generate_flirts';
const TEST_IMAGES_DIR = path.join(__dirname, 'test-images');

// ANSI colors for terminal output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m'
};

/**
 * Test a single image with the Vision API
 */
async function testVisionAPI(imagePath, testName, expectedBehavior) {
    console.log(`\n${colors.bright}${'='.repeat(70)}${colors.reset}`);
    console.log(`${colors.cyan}TEST: ${testName}${colors.reset}`);
    console.log(`${colors.yellow}Expected: ${expectedBehavior}${colors.reset}`);
    console.log(`${colors.bright}${'='.repeat(70)}${colors.reset}`);

    const startTime = Date.now();

    try {
        // Read and encode image
        const imageData = fs.readFileSync(imagePath).toString('base64');
        const imageSizeMB = (imageData.length / 1024 / 1024).toFixed(2);

        console.log(`📸 Image: ${path.basename(imagePath)} (${imageSizeMB} MB base64)`);

        // Make API request
        const response = await axios.post(API_URL, {
            image_data: imageData,
            suggestion_type: 'opener',
            tone: 'playful'
        }, {
            headers: { 'Content-Type': 'application/json' },
            timeout: 60000
        });

        const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
        const data = response.data;

        // Response validation
        console.log(`\n${colors.green}✅ Response received in ${elapsed}s${colors.reset}`);
        console.log(`${colors.blue}📊 Screenshot Type:${colors.reset} ${data.screenshot_type || 'N/A'}`);
        console.log(`${colors.blue}📈 Profile Score:${colors.reset} ${data.profile_score || 'N/A'}/10`);
        console.log(`${colors.blue}🔄 Needs More Scrolling:${colors.reset} ${data.needs_more_scrolling}`);

        if (data.message_to_user) {
            console.log(`\n${colors.magenta}💬 Message to User:${colors.reset}`);
            console.log(`   ${data.message_to_user}`);
        }

        if (data.extracted_details) {
            console.log(`\n${colors.cyan}📝 Extracted Details:${colors.reset}`);
            console.log(`   Name: ${data.extracted_details.name || 'N/A'}`);
            console.log(`   Age: ${data.extracted_details.age || 'N/A'}`);
            console.log(`   Bio: ${data.extracted_details.bio_text || 'None'}`);
            console.log(`   Interests: ${data.extracted_details.interests?.join(', ') || 'None'}`);
            console.log(`   Visual Elements: ${data.extracted_details.visual_elements?.join(', ') || 'None'}`);
            console.log(`   Key Hooks: ${data.extracted_details.key_hooks?.join(', ') || 'None'}`);
        }

        if (data.suggestions && data.suggestions.length > 0) {
            console.log(`\n${colors.green}💡 Suggestions (${data.suggestions.length}):${colors.reset}`);
            data.suggestions.forEach((s, i) => {
                console.log(`\n${colors.bright}${i+1}. "${s.text}"${colors.reset}`);
                console.log(`   ${colors.yellow}Confidence:${colors.reset} ${(s.confidence * 100).toFixed(0)}%`);
                console.log(`   ${colors.yellow}Reasoning:${colors.reset} ${s.reasoning}`);
                console.log(`   ${colors.yellow}References:${colors.reset} ${s.references?.join(', ')}`);
            });
        }

        // Validation checks
        console.log(`\n${colors.bright}Validation:${colors.reset}`);
        const checks = [];

        if (expectedBehavior.includes('cat') || expectedBehavior.includes('gym')) {
            const hasCatMention = data.suggestions?.some(s => s.text.toLowerCase().includes('cat'));
            const hasGymMention = data.suggestions?.some(s => s.text.toLowerCase().includes('gym'));

            if (hasCatMention) checks.push(`${colors.green}✓${colors.reset} Mentions cats`);
            else checks.push(`${colors.red}✗${colors.reset} Missing cat mention`);

            if (hasGymMention) checks.push(`${colors.green}✓${colors.reset} Mentions gym`);
            else checks.push(`${colors.red}✗${colors.reset} Missing gym mention`);
        }

        if (expectedBehavior.includes('chat')) {
            if (data.screenshot_type === 'chat') checks.push(`${colors.green}✓${colors.reset} Correctly detected as chat`);
            else checks.push(`${colors.red}✗${colors.reset} Failed to detect chat`);
        }

        if (elapsed < 10) checks.push(`${colors.green}✓${colors.reset} Response time < 10s`);
        else checks.push(`${colors.yellow}⚠${colors.reset} Slow response (${elapsed}s)`);

        if (data.profile_score >= 7) checks.push(`${colors.green}✓${colors.reset} Good profile score (${data.profile_score}/10)`);
        else if (data.profile_score >= 4) checks.push(`${colors.yellow}⚠${colors.reset} Medium profile score (${data.profile_score}/10)`);
        else checks.push(`${colors.red}✗${colors.reset} Low profile score (${data.profile_score}/10)`);

        checks.forEach(check => console.log(`   ${check}`));

        return { success: true, data, elapsed };

    } catch (error) {
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
        console.error(`\n${colors.red}❌ Error (${elapsed}s):${colors.reset} ${error.message}`);
        if (error.response) {
            console.error(`${colors.red}Response:${colors.reset}`, JSON.stringify(error.response.data, null, 2));
        }
        return { success: false, error: error.message, elapsed };
    }
}

/**
 * Run all test cases
 */
async function runAllTests() {
    console.log(`\n${colors.bright}${colors.blue}🚀 Flirrt.ai Vision API Test Suite - October 2025${colors.reset}\n`);
    console.log(`${colors.cyan}Testing intelligent profile analysis with real dating app screenshots${colors.reset}\n`);

    // Check if test images directory exists
    if (!fs.existsSync(TEST_IMAGES_DIR)) {
        console.error(`${colors.red}❌ Test images directory not found: ${TEST_IMAGES_DIR}${colors.reset}`);
        process.exit(1);
    }

    // Define test cases
    const testCases = [
        {
            path: path.join(TEST_IMAGES_DIR, 'clarinha-profile-1.jpeg'),
            name: 'Clarinha Profile #1 (Complete)',
            expected: 'Should extract bio about cats and gym, generate personalized openers'
        },
        {
            path: path.join(TEST_IMAGES_DIR, 'clarinha-profile-2.jpeg'),
            name: 'Clarinha Profile #2 (Mirror Selfie)',
            expected: 'Should recognize same person, extract bio details'
        },
        {
            path: path.join(TEST_IMAGES_DIR, 'clarinha-interests.jpeg'),
            name: 'Clarinha Interests Section',
            expected: 'Should extract UI interest tags and hobbies'
        },
        {
            path: path.join(TEST_IMAGES_DIR, 'hebrew-profile-talya.jpeg'),
            name: 'Hebrew Profile (טליה 21)',
            expected: 'Should extract Hebrew text from bio, handle multilingual content'
        },
        {
            path: path.join(TEST_IMAGES_DIR, 'chat-conversation.jpeg'),
            name: 'Chat Conversation (Instagram)',
            expected: 'Should detect as chat, ask for profile screenshot instead'
        }
    ];

    const results = [];

    // Run each test
    for (const test of testCases) {
        if (!fs.existsSync(test.path)) {
            console.warn(`${colors.yellow}⚠ Skipping ${test.name}: File not found${colors.reset}`);
            continue;
        }

        const result = await testVisionAPI(test.path, test.name, test.expected);
        results.push({ ...test, ...result });

        // Small delay between tests
        await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Summary
    console.log(`\n${colors.bright}${'='.repeat(70)}${colors.reset}`);
    console.log(`${colors.bright}${colors.blue}📊 TEST SUMMARY${colors.reset}`);
    console.log(`${colors.bright}${'='.repeat(70)}${colors.reset}\n`);

    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    const avgTime = (results.reduce((sum, r) => sum + parseFloat(r.elapsed), 0) / results.length).toFixed(2);

    console.log(`Total Tests: ${results.length}`);
    console.log(`${colors.green}Successful: ${successful}${colors.reset}`);
    console.log(`${colors.red}Failed: ${failed}${colors.reset}`);
    console.log(`Average Response Time: ${avgTime}s\n`);

    if (failed === 0) {
        console.log(`${colors.green}${colors.bright}✅ ALL TESTS PASSED!${colors.reset}\n`);
    } else {
        console.log(`${colors.red}${colors.bright}❌ SOME TESTS FAILED${colors.reset}\n`);
        process.exit(1);
    }
}

// Run tests if executed directly
if (require.main === module) {
    runAllTests().catch(error => {
        console.error(`${colors.red}Fatal error:${colors.reset}`, error);
        process.exit(1);
    });
}

module.exports = { testVisionAPI, runAllTests };
