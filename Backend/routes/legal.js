const express = require('express');
const path = require('path');

const router = express.Router();

/**
 * Legal Routes - Privacy Policy, Terms of Service
 * CRITICAL: Required for App Store approval
 *
 * Routes:
 * - GET /privacy - Privacy policy page
 * - GET /terms - Terms of service page
 * - GET /data-usage - Data usage explanation
 */

// Privacy Policy
router.get('/privacy', (req, res) => {
    res.render('privacy-policy', {
        title: 'Privacy Policy - Vibe8.AI',
        lastUpdated: 'October 17, 2025',
        contactEmail: 'privacy@vibe8.ai'
    });
});

// Terms of Service
router.get('/terms', (req, res) => {
    res.render('terms-of-service', {
        title: 'Terms of Service - Vibe8.AI',
        lastUpdated: 'October 17, 2025',
        contactEmail: 'legal@vibe8.ai'
    });
});

// Data Usage Explanation
router.get('/data-usage', (req, res) => {
    res.json({
        success: true,
        data: {
            data_collected: {
                screenshots: {
                    description: 'Dating app profile screenshots and chat conversations',
                    purpose: 'AI analysis to generate personalized conversation suggestions',
                    retention: '30 days or until deleted by user',
                    third_party_sharing: 'Processed by Grok-4 AI (xAI) for analysis'
                },
                voice_samples: {
                    description: 'User voice recordings for voice cloning',
                    purpose: 'Generate voice messages with your voice',
                    retention: 'Until deleted by user',
                    third_party_sharing: 'Processed by ElevenLabs for voice synthesis'
                },
                text_inputs: {
                    description: 'User preferences, conversation context, feedback',
                    purpose: 'Personalize suggestions and improve AI coaching',
                    retention: '90 days',
                    third_party_sharing: 'Processed by GPT-5 (OpenAI), Gemini (Google), Perplexity'
                },
                user_profile: {
                    description: 'Name, email, birthdate (18+ verification), Apple ID',
                    purpose: 'Account management and age verification',
                    retention: 'Until account deletion',
                    third_party_sharing: 'None'
                }
            },
            third_party_services: {
                openai_gpt5: {
                    service: 'OpenAI GPT-5 Pro',
                    purpose: 'AI coaching persona, suggestion explanations',
                    data_sent: 'Screenshot analysis results, user preferences, conversation history',
                    privacy_policy: 'https://openai.com/privacy'
                },
                google_gemini: {
                    service: 'Google Gemini 2.5 Pro',
                    purpose: 'Profile analysis, interest extraction',
                    data_sent: 'Screenshot images, extracted text',
                    privacy_policy: 'https://policies.google.com/privacy'
                },
                xai_grok: {
                    service: 'xAI Grok-4',
                    purpose: 'Screenshot analysis, suggestion generation',
                    data_sent: 'Screenshot images, conversation context',
                    privacy_policy: 'https://x.ai/legal/privacy-policy'
                },
                perplexity_sonar: {
                    service: 'Perplexity Sonar Pro',
                    purpose: 'Real-time dating advice, topic research',
                    data_sent: 'User questions, conversation topics',
                    privacy_policy: 'https://www.perplexity.ai/privacy'
                },
                elevenlabs: {
                    service: 'ElevenLabs Voice Synthesis',
                    purpose: 'Voice cloning and text-to-speech',
                    data_sent: 'Voice samples, text for synthesis',
                    privacy_policy: 'https://elevenlabs.io/privacy'
                }
            },
            user_rights: {
                access: 'Request copy of your data via email',
                correction: 'Update profile information in app',
                deletion: 'Delete account and all data via in-app button',
                portability: 'Download your data in JSON format',
                opt_out: 'Disable specific AI features in settings'
            },
            data_security: {
                encryption: 'TLS 1.3 for data in transit, AES-256 for data at rest',
                access_control: 'Role-based access, audit logging',
                retention: 'Automatic deletion after specified periods',
                breach_notification: 'Email notification within 72 hours'
            }
        }
    });
});

// GDPR Data Export
router.get('/data-export/:userId', async (req, res) => {
    const { userId } = req.params;

    // NOTE: This is a simplified version. In production, require authentication.

    try {
        // TODO: Implement actual data export from database
        // Should include: user profile, screenshots, suggestions, voice clone ID, analytics

        res.json({
            success: true,
            data: {
                user_id: userId,
                exported_at: new Date().toISOString(),
                data: {
                    profile: {},
                    screenshots: [],
                    suggestions: [],
                    voice_clone_id: null,
                    analytics: []
                }
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Data export failed'
        });
    }
});

module.exports = router;
