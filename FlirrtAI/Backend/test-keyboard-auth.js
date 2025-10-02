const express = require('express');
const app = express();

// Middleware
app.use(express.json());

// Simple auth middleware that supports keyboard extension bypass
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        const isKeyboardExtension = req.headers['x-keyboard-extension'] === 'true';

        // Allow keyboard extension requests to bypass authentication
        if (isKeyboardExtension) {
            req.user = {
                id: 'keyboard-user-' + Date.now(),
                email: 'keyboard@flirrt.ai',
                sessionId: 'keyboard-session-' + Date.now(),
                isVerified: true,
                role: 'keyboard-user',
                isKeyboard: true
            };

            console.log('Keyboard extension authenticated', {
                userId: req.user.id,
                keyboardMode: true,
                userAgent: req.headers['user-agent'],
                ip: req.ip
            });

            return next();
        }

        if (!token) {
            return res.status(401).json({
                success: false,
                error: 'Access token required',
                code: 'TOKEN_MISSING'
            });
        }

        // For testing, allow test token
        if (token === 'test-token-for-api-testing') {
            req.user = {
                id: 'test-user-id',
                email: 'test@flirrt.ai',
                sessionId: 'test-session-id',
                isVerified: true,
                role: 'user'
            };
            return next();
        }

        // Otherwise fail
        return res.status(401).json({
            success: false,
            error: 'Invalid token',
            code: 'TOKEN_INVALID'
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            error: 'Authentication error',
            code: 'AUTH_ERROR'
        });
    }
};

// Hardcoded fallback suggestions for keyboard extension
const fallbackSuggestions = [
    { text: "Hey! That's really interesting, tell me more!", confidence: 0.9 },
    { text: "I love your energy! What got you into that?", confidence: 0.85 },
    { text: "That's amazing! How long have you been doing that?", confidence: 0.8 },
    { text: "You seem like someone with great stories. What's been the highlight of your week?", confidence: 0.87 },
    { text: "I have to ask - is that from an actual adventure or are you just naturally photogenic?", confidence: 0.82 }
];

// Test endpoint
app.post('/api/v1/flirts/generate_flirts', authenticateToken, async (req, res) => {
    try {
        const {
            screenshot_id,
            context = '',
            suggestion_type = 'opener',
            tone = 'playful',
            user_preferences = {}
        } = req.body;

        const isKeyboardExtension = req.user?.isKeyboard || false;

        console.log('Flirt generation request:', {
            userId: req.user.id,
            screenshot_id,
            suggestion_type,
            tone,
            isKeyboard: isKeyboardExtension
        });

        if (!screenshot_id) {
            return res.status(400).json({
                success: false,
                error: 'Screenshot ID is required',
                code: 'MISSING_SCREENSHOT_ID'
            });
        }

        // For keyboard extensions, provide fast fallback suggestions
        if (isKeyboardExtension) {
            console.log('Providing keyboard extension fallback suggestions');

            // Select 3 random suggestions from fallback pool
            const shuffled = [...fallbackSuggestions].sort(() => 0.5 - Math.random());
            const selectedSuggestions = shuffled.slice(0, 3).map((suggestion, index) => ({
                id: `keyboard-fallback-${Date.now()}-${index}`,
                text: suggestion.text,
                confidence: suggestion.confidence,
                reasoning: "Quick keyboard suggestion",
                created_at: new Date().toISOString(),
                keyboard_fallback: true
            }));

            const responseData = {
                suggestions: selectedSuggestions,
                metadata: {
                    suggestion_type,
                    tone,
                    screenshot_id,
                    total_suggestions: selectedSuggestions.length,
                    generated_at: new Date().toISOString(),
                    keyboard_mode: true,
                    fallback: true
                }
            };

            return res.json({
                success: true,
                data: responseData,
                cached: false,
                message: 'Keyboard flirt suggestions generated successfully'
            });
        }

        // For regular users, provide a different response
        const regularSuggestions = [{
            id: 'regular-suggestion-1',
            text: 'Regular user suggestion',
            confidence: 0.8,
            reasoning: "Regular authentication path",
            created_at: new Date().toISOString()
        }];

        return res.json({
            success: true,
            data: {
                suggestions: regularSuggestions,
                metadata: {
                    suggestion_type,
                    tone,
                    screenshot_id,
                    total_suggestions: regularSuggestions.length,
                    generated_at: new Date().toISOString(),
                    keyboard_mode: false
                }
            },
            message: 'Regular flirt suggestions generated successfully'
        });

    } catch (error) {
        console.error('Flirt generation error:', error);
        res.status(500).json({
            success: false,
            error: 'Flirt generation failed',
            details: error.message,
            code: 'FLIRT_GENERATION_ERROR'
        });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Test server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log('Ready to test keyboard authentication bypass');
});