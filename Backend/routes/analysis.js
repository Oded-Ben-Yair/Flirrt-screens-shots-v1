const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { Pool } = require('pg');
const axios = require('axios');
const FormData = require('form-data');
const { authenticateToken, rateLimit } = require('../middleware/auth');
const geminiVisionService = require('../services/geminiVisionService');
const { logger } = require('../services/logger');

const router = express.Router();

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, process.env.UPLOAD_DIR || './uploads');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, `screenshot-${uniqueSuffix}${path.extname(file.originalname)}`);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB
        files: 1
    },
    fileFilter: (req, file, cb) => {
        // Check file type
        const allowedMimes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
        if (allowedMimes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG, PNG, JPG, and WebP images are allowed.'));
        }
    }
});

/**
 * Analyze Screenshot with Real Grok Vision API
 * POST /api/v1/analyze_screenshot
 */
router.post('/analyze_screenshot',
    authenticateToken,
    rateLimit(20, 15 * 60 * 1000), // 20 requests per 15 minutes
    upload.single('screenshot'),
    async (req, res) => {
        let screenshotId = null;

        try {
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    error: 'Screenshot file is required',
                    code: 'NO_FILE_UPLOADED'
                });
            }

            const { context = '', preferences = '{}' } = req.body;

            // Save screenshot metadata to database (if database is available)
            let screenshotId = 'test-screenshot-' + Date.now();
            try {
                const insertScreenshotQuery = `
                    INSERT INTO screenshots (user_id, filename, file_path, file_size, mime_type, analysis_status)
                    VALUES ($1, $2, $3, $4, $5, 'processing')
                    RETURNING id
                `;

                const screenshotResult = await pool.query(insertScreenshotQuery, [
                    req.user.id,
                    req.file.filename,
                    req.file.path,
                    req.file.size,
                    req.file.mimetype
                ]);

                screenshotId = screenshotResult.rows[0].id;
            } catch (dbError) {
                console.warn('Database insert failed, using mock ID:', dbError.message);
                // Continue with mock ID for testing
            }

            // Read the uploaded file
            const imageBuffer = await fs.readFile(req.file.path);
            const base64Image = imageBuffer.toString('base64');

            // Use Gemini Vision for superior image analysis
            logger.info(`🔍 Analyzing screenshot with Gemini Vision - Size: ${req.file.size} bytes`);

            const geminiAnalysis = await geminiVisionService.analyzeImage(base64Image, {
                analyse_type: 'dating_conversation',
                include_profile_detection: true,
                include_conversation_analysis: true,
                include_context_sufficiency: true
            });

            if (!geminiAnalysis || !geminiAnalysis.success) {
                throw new Error('Gemini Vision analysis failed');
            }

            // Extract key analysis data
            const analysisData = geminiAnalysis.analysis;

            // CRITICAL: Detect if screenshot has sufficient context
            const conversationMessages = analysisData.conversation_messages || [];
            const hasConversation = conversationMessages.length >= 2; // At least 2 messages for context
            const isProfileView = analysisData.is_profile_bio === true || analysisData.screen_type === 'profile';
            const isEmpty = conversationMessages.length === 0 && !isProfileView;
            const needsMoreContext = !hasConversation && !isProfileView;

            logger.info(`📊 Context Analysis - Messages: ${conversationMessages.length}, IsProfile: ${isProfileView}, NeedsMore: ${needsMoreContext}`);

            // Structure analysis result with content sufficiency indicators
            const analysisResult = {
                ...analysisData,
                // Content sufficiency metadata
                content_sufficiency: {
                    has_conversation: hasConversation,
                    is_profile: isProfileView,
                    is_empty: isEmpty,
                    needs_more_context: needsMoreContext,
                    message_count: conversationMessages.length,
                    recommendation: needsMoreContext
                        ? (isEmpty ? 'upload_profile' : 'scroll_for_more')
                        : (isProfileView ? 'profile_opener' : 'context_response')
                },
                processed_at: new Date().toISOString(),
                analysis_engine: 'gemini-vision'
            };

            // If insufficient context, set special status for immediate user feedback
            if (needsMoreContext || isEmpty) {
                logger.warn(`⚠️ Insufficient context detected - Empty: ${isEmpty}, NeedsMore: ${needsMoreContext}`);

                // Still save to database but with special status
                try {
                    await pool.query(
                        `UPDATE screenshots
                         SET analysis_result = $1, analysis_status = 'needs_more_context', processed_at = NOW()
                         WHERE id = $2`,
                        [JSON.stringify(analysisResult), screenshotId]
                    );
                } catch (dbError) {
                    logger.warn('Database update failed:', { error: dbError.message });
                }

                // Return special response indicating more context needed
                return res.json({
                    success: true,
                    needs_more_context: true,
                    data: {
                        screenshot_id: screenshotId,
                        analysis: analysisResult,
                        metadata: {
                            filename: req.file.filename,
                            size: req.file.size,
                            processed_at: new Date().toISOString()
                        }
                    },
                    message: isEmpty
                        ? 'This chat appears empty. Please upload a profile photo or scroll up for more conversation context!'
                        : 'Not enough conversation visible. Scroll up and take another screenshot for better suggestions!',
                    action_required: isEmpty ? 'upload_profile' : 'more_screenshots',
                    recommendation: analysisResult.content_sufficiency.recommendation
                });
            }

            // Update screenshot with analysis results (if database is available)
            try {
                await pool.query(
                    `UPDATE screenshots
                     SET analysis_result = $1, analysis_status = 'completed', processed_at = NOW()
                     WHERE id = $2`,
                    [JSON.stringify(analysisResult), screenshotId]
                );
            } catch (dbError) {
                console.warn('Database update failed:', dbError.message);
            }

            // Log analytics event (if database is available)
            try {
                await pool.query(
                    `INSERT INTO analytics (user_id, event_type, event_data)
                     VALUES ($1, $2, $3)`,
                    [req.user.id, 'screenshot_analyzed', {
                        screenshot_id: screenshotId,
                        file_size: req.file.size,
                        analysis_confidence: analysisResult.confidence_level || 0.7
                    }]
                );
            } catch (dbError) {
                console.warn('Analytics logging failed:', dbError.message);
            }

            res.json({
                success: true,
                data: {
                    screenshot_id: screenshotId,
                    analysis: analysisResult,
                    metadata: {
                        filename: req.file.filename,
                        size: req.file.size,
                        processed_at: new Date().toISOString()
                    }
                },
                message: 'Screenshot analyzed successfully'
            });

        } catch (error) {
            console.error('Screenshot analysis error:', error);

            // Update screenshot status to failed if we have an ID
            if (screenshotId) {
                await pool.query(
                    `UPDATE screenshots
                     SET analysis_status = 'failed', processed_at = NOW()
                     WHERE id = $1`,
                    [screenshotId]
                ).catch(dbError => console.error('Failed to update screenshot status:', dbError));
            }

            // Clean up uploaded file on error
            if (req.file && req.file.path) {
                await fs.unlink(req.file.path).catch(unlinkError =>
                    console.error('Failed to delete uploaded file:', unlinkError)
                );
            }

            // Handle specific API errors
            if (error.response) {
                const apiError = error.response.data;
                console.error('Grok API Error:', apiError);

                return res.status(502).json({
                    success: false,
                    error: 'Grok Vision API error',
                    details: apiError.error?.message || 'API request failed',
                    code: 'GROK_API_ERROR'
                });
            }

            // Handle network/timeout errors
            if (error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT') {
                return res.status(504).json({
                    success: false,
                    error: 'Analysis request timed out',
                    code: 'REQUEST_TIMEOUT'
                });
            }

            res.status(500).json({
                success: false,
                error: 'Screenshot analysis failed',
                details: error.message,
                code: 'ANALYSIS_ERROR'
            });
        }
    }
);

/**
 * Get Screenshot Analysis Results
 * GET /api/v1/analysis/:screenshotId
 */
router.get('/:screenshotId', authenticateToken, async (req, res) => {
    try {
        const { screenshotId } = req.params;

        const screenshotQuery = `
            SELECT s.*, u.id as owner_id
            FROM screenshots s
            JOIN users u ON s.user_id = u.id
            WHERE s.id = $1
        `;

        const screenshotResult = await pool.query(screenshotQuery, [screenshotId]);

        if (screenshotResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Screenshot not found',
                code: 'SCREENSHOT_NOT_FOUND'
            });
        }

        const screenshot = screenshotResult.rows[0];

        // Check if user owns this screenshot
        if (screenshot.owner_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Access denied',
                code: 'ACCESS_DENIED'
            });
        }

        res.json({
            success: true,
            data: {
                id: screenshot.id,
                filename: screenshot.filename,
                analysis_status: screenshot.analysis_status,
                analysis_result: screenshot.analysis_result,
                created_at: screenshot.created_at,
                processed_at: screenshot.processed_at
            }
        });

    } catch (error) {
        console.error('Get analysis error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get analysis results',
            code: 'GET_ANALYSIS_ERROR'
        });
    }
});

/**
 * Get User's Screenshot History
 * GET /api/v1/analysis/history
 */
router.get('/history', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 10 } = req.query;
        const offset = (page - 1) * limit;

        const historyQuery = `
            SELECT id, filename, analysis_status, created_at, processed_at,
                   file_size, mime_type
            FROM screenshots
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT $2 OFFSET $3
        `;

        const countQuery = `
            SELECT COUNT(*) as total
            FROM screenshots
            WHERE user_id = $1
        `;

        const [historyResult, countResult] = await Promise.all([
            pool.query(historyQuery, [req.user.id, limit, offset]),
            pool.query(countQuery, [req.user.id])
        ]);

        const screenshots = historyResult.rows;
        const total = parseInt(countResult.rows[0].total);

        res.json({
            success: true,
            data: {
                screenshots,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get history error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get screenshot history',
            code: 'GET_HISTORY_ERROR'
        });
    }
});

/**
 * Delete Screenshot
 * DELETE /api/v1/analysis/:screenshotId
 */
router.delete('/:screenshotId', authenticateToken, async (req, res) => {
    try {
        const { screenshotId } = req.params;

        // Get screenshot info first
        const screenshotQuery = `
            SELECT file_path, user_id
            FROM screenshots
            WHERE id = $1
        `;

        const screenshotResult = await pool.query(screenshotQuery, [screenshotId]);

        if (screenshotResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Screenshot not found',
                code: 'SCREENSHOT_NOT_FOUND'
            });
        }

        const screenshot = screenshotResult.rows[0];

        // Check if user owns this screenshot
        if (screenshot.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Access denied',
                code: 'ACCESS_DENIED'
            });
        }

        // Delete from database (this will cascade to related records)
        await pool.query('DELETE FROM screenshots WHERE id = $1', [screenshotId]);

        // Delete file from filesystem
        if (screenshot.file_path) {
            await fs.unlink(screenshot.file_path).catch(error =>
                console.error('Failed to delete file:', error)
            );
        }

        res.json({
            success: true,
            message: 'Screenshot deleted successfully'
        });

    } catch (error) {
        console.error('Delete screenshot error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete screenshot',
            code: 'DELETE_ERROR'
        });
    }
});

module.exports = router;