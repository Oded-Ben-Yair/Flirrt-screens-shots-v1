/**
 * ⚠️ DEPRECATED - OLD UNTRAINED PIPELINE
 *
 * This route uses Gemini 2.5 Pro + GPT-5 (untrained pipeline).
 *
 * **USE INSTEAD**: /api/v2/trained (routes/trained-flirts.js)
 * - Trained pipeline: Grok-2-vision + GPT-5
 * - Better quality, faster performance
 * - User-validated architecture
 *
 * **Status**: Maintained for backward compatibility only
 * **Removal date**: TBD after trained pipeline validation
 */

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { authenticateToken, rateLimit } = require('../middleware/auth');
const geminiVisionService = require('../services/geminiVisionService');
const gpt5FlirtService = require('../services/gpt5FlirtService');
const { logger } = require('../services/logger');

const router = express.Router();

/**
 * Vibe8 Flirts API - Gemini 2.5 Pro → GPT-5 Pipeline (DEPRECATED)
 *
 * Implements THE VIBE8 FIXING PLAN dual-model orchestration:
 * 1. Screenshot Analysis: Gemini 2.5 Pro (multimodal vision)
 * 2. Flirt Generation: GPT-5 (superior content generation)
 * 3. Quality Evaluation: Automated scoring framework
 *
 * Performance Targets (from research):
 * - Screenshot analysis: <5s
 * - Flirt generation: <2s for openers, <5s for complex
 * - Total pipeline: <7s end-to-end
 * - Quality threshold: 0.80+ overall score
 */

// Configure multer for screenshot uploads
const storage = multer.memoryStorage(); // Use memory storage for direct processing

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max
        files: 1
    },
    fileFilter: (req, file, cb) => {
        const allowedMimes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/heic'];
        if (allowedMimes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG, PNG, WebP, and HEIC images allowed.'));
        }
    }
});

/**
 * Analyze Screenshot + Generate Flirts (Combined Pipeline)
 * POST /api/v2/vibe8/analyze-and-generate
 *
 * iOS Integration: Single endpoint for complete workflow
 *
 * Request Body (multipart/form-data):
 * - screenshot: Image file (required)
 * - tone: playful|confident|casual|romantic|witty (default: playful)
 * - suggestion_type: opener|response|continuation (default: opener)
 * - count: Number of alternatives (default: 3)
 *
 * Response:
 * {
 *   "success": true,
 *   "analysis": { // Gemini 2.5 Pro results
 *     "context": "...",
 *     "personality": {...},
 *     "scene": {...},
 *     "confidence": 0.92
 *   },
 *   "flirts": [ // GPT-5 generated with quality scores
 *     {
 *       "flirt": "...",
 *       "tone": "playful",
 *       "qualityScores": {
 *         "overall": 0.87,
 *         "sentiment": 0.85,
 *         "creativity": 0.90,
 *         ...
 *       }
 *     }
 *   ],
 *   "performance": {
 *     "analysisLatency": 3200,
 *     "generationLatency": 1800,
 *     "totalLatency": 5000
 *   }
 * }
 */
router.post('/analyze-and-generate',
    authenticateToken,
    rateLimit(20, 15 * 60 * 1000), // 20 requests per 15 minutes
    upload.single('screenshot'),
    async (req, res) => {
        const startTime = Date.now();
        let analysisLatency = 0;
        let generationLatency = 0;

        try {
            // Validate screenshot upload
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    error: 'Screenshot file is required',
                    code: 'MISSING_SCREENSHOT'
                });
            }

            // Extract parameters
            const {
                tone = 'playful',
                suggestion_type = 'opener',
                count = 3
            } = req.body;

            // Validate tone
            const validTones = ['playful', 'confident', 'casual', 'romantic', 'witty'];
            if (!validTones.includes(tone)) {
                return res.status(400).json({
                    success: false,
                    error: `Invalid tone. Must be one of: ${validTones.join(', ')}`,
                    code: 'INVALID_TONE'
                });
            }

            logger.info('Vibe8 dual-model pipeline started', {
                userId: req.user?.id,
                tone,
                suggestionType: suggestion_type,
                fileSize: req.file.size,
                mimeType: req.file.mimetype
            });

            // Step 1: Gemini 2.5 Pro Screenshot Analysis
            const analysisStart = Date.now();

            let screenshotAnalysis;
            try {
                screenshotAnalysis = await geminiVisionService.analyzeScreenshot({
                    imageBuffer: req.file.buffer,
                    mimeType: req.file.mimetype,
                    userId: req.user?.id
                });
            } catch (error) {
                logger.error('Gemini screenshot analysis failed', {
                    error: error.message,
                    userId: req.user?.id
                });

                return res.status(500).json({
                    success: false,
                    error: 'Screenshot analysis failed',
                    code: 'ANALYSIS_FAILED',
                    details: process.env.NODE_ENV === 'development' ? error.message : undefined
                });
            }

            analysisLatency = Date.now() - analysisStart;

            logger.info('Gemini analysis completed', {
                latency: analysisLatency,
                confidence: screenshotAnalysis.confidence,
                targetLatency: 5000
            });

            // Check analysis confidence threshold
            if (screenshotAnalysis.confidence < 0.70) {
                logger.warn('Low confidence screenshot analysis', {
                    confidence: screenshotAnalysis.confidence,
                    userId: req.user?.id
                });
            }

            // Step 2: GPT-5 Flirt Generation
            const generationStart = Date.now();

            let flirtData;
            try {
                flirtData = await gpt5FlirtService.generateFlirts({
                    screenshotAnalysis: screenshotAnalysis,
                    tone,
                    suggestionType: suggestion_type,
                    count: parseInt(count, 10),
                    userPreferences: {} // Can be extended with user profile data
                });
            } catch (error) {
                logger.error('GPT-5 flirt generation failed', {
                    error: error.message,
                    userId: req.user?.id,
                    tone,
                    suggestionType: suggestion_type
                });

                return res.status(500).json({
                    success: false,
                    error: 'Flirt generation failed',
                    code: 'GENERATION_FAILED',
                    analysis: screenshotAnalysis, // Return analysis even if generation fails
                    details: process.env.NODE_ENV === 'development' ? error.message : undefined
                });
            }

            generationLatency = Date.now() - generationStart;
            const totalLatency = Date.now() - startTime;

            logger.info('GPT-5 generation completed', {
                latency: generationLatency,
                qualityScore: flirtData.qualityScores.overall,
                targetLatency: suggestion_type === 'opener' ? 2000 : 5000
            });

            // Prepare flirts array (main + alternatives)
            const flirts = [
                {
                    flirt: flirtData.flirt,
                    tone: flirtData.tone,
                    reasoning: flirtData.reasoning,
                    confidence: flirtData.confidence,
                    qualityScores: flirtData.qualityScores,
                    isPrimary: true
                }
            ];

            // Add alternatives if present
            if (flirtData.alternatives && Array.isArray(flirtData.alternatives)) {
                flirtData.alternatives.forEach(alt => {
                    flirts.push({
                        flirt: alt,
                        tone: flirtData.tone,
                        isPrimary: false
                    });
                });
            }

            // Filter low-quality flirts (quality threshold from research: 0.80+)
            const qualityThreshold = 0.75; // Slightly lower for alternatives
            const qualityFlirts = flirts.filter((f, idx) =>
                idx === 0 || !f.qualityScores || f.qualityScores.overall >= qualityThreshold
            );

            logger.info('Vibe8 dual-model pipeline completed', {
                userId: req.user?.id,
                analysisLatency,
                generationLatency,
                totalLatency,
                flirtsGenerated: qualityFlirts.length,
                qualityScore: flirtData.qualityScores.overall,
                targetTotalLatency: 7000
            });

            // Performance warnings
            if (totalLatency > 7000) {
                logger.warn('Pipeline exceeded target latency', {
                    totalLatency,
                    target: 7000
                });
            }

            if (flirtData.qualityScores.overall < 0.80) {
                logger.warn('Flirt quality below target threshold', {
                    qualityScore: flirtData.qualityScores.overall,
                    target: 0.80
                });
            }

            // Success response
            res.json({
                success: true,
                analysis: {
                    context: screenshotAnalysis.context || screenshotAnalysis.summary,
                    personality: screenshotAnalysis.personality,
                    scene: screenshotAnalysis.scene,
                    confidence: screenshotAnalysis.confidence,
                    visualFeatures: screenshotAnalysis.visualFeatures
                },
                flirts: qualityFlirts,
                performance: {
                    analysisLatency,
                    generationLatency,
                    totalLatency,
                    meetsTarget: totalLatency <= 7000
                },
                metadata: {
                    ...flirtData.metadata,
                    pipelineVersion: 'vibe8-v2',
                    timestamp: new Date().toISOString()
                }
            });

        } catch (error) {
            const totalLatency = Date.now() - startTime;

            logger.error('Vibe8 pipeline error', {
                error: error.message,
                stack: error.stack,
                userId: req.user?.id,
                totalLatency
            });

            res.status(500).json({
                success: false,
                error: 'Pipeline processing failed',
                code: 'PIPELINE_ERROR',
                details: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

/**
 * Screenshot Analysis Only (for iOS preview/validation)
 * POST /api/v2/vibe8/analyze-screenshot
 *
 * Returns only Gemini 2.5 Pro analysis without flirt generation
 */
router.post('/analyze-screenshot',
    authenticateToken,
    rateLimit(30, 15 * 60 * 1000),
    upload.single('screenshot'),
    async (req, res) => {
        const startTime = Date.now();

        try {
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    error: 'Screenshot file is required',
                    code: 'MISSING_SCREENSHOT'
                });
            }

            const analysisResult = await geminiVisionService.analyzeScreenshot({
                imageBuffer: req.file.buffer,
                mimeType: req.file.mimetype,
                userId: req.user?.id
            });

            const latency = Date.now() - startTime;

            logger.info('Screenshot analysis completed', {
                userId: req.user?.id,
                latency,
                confidence: analysisResult.confidence
            });

            res.json({
                success: true,
                analysis: analysisResult,
                performance: {
                    latency,
                    meetsTarget: latency <= 5000
                }
            });

        } catch (error) {
            logger.error('Screenshot analysis error', {
                error: error.message,
                userId: req.user?.id
            });

            res.status(500).json({
                success: false,
                error: 'Analysis failed',
                code: 'ANALYSIS_ERROR',
                details: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

/**
 * Health check endpoint
 * GET /api/v2/vibe8/health
 */
router.get('/health', (req, res) => {
    res.json({
        success: true,
        service: 'vibe8-flirts',
        models: {
            gemini: geminiVisionService.getMetrics ? geminiVisionService.getMetrics() : { status: 'unknown' },
            gpt5: gpt5FlirtService.getMetrics()
        },
        timestamp: new Date().toISOString()
    });
});

module.exports = router;
