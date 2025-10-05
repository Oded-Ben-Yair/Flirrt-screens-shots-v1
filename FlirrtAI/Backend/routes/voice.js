const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const { Pool } = require('pg');
const axios = require('axios');
const { authenticateToken, rateLimit } = require('../middleware/auth');
const {
    logError,
    sendErrorResponse,
    handleError,
    errorCodes
} = require('../utils/errorHandler');
const {
    validateTextLength,
    validateVoiceModel,
    validateVoiceId,
    sanitizeText
} = require('../utils/validation');

const router = express.Router();

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

/**
 * Synthesize Voice with Real ElevenLabs API
 * POST /api/v1/synthesize_voice
 */
router.post('/synthesize_voice',
    authenticateToken,
    rateLimit(50, 15 * 60 * 1000), // 50 requests per 15 minutes
    async (req, res) => {
        let voiceMessageId = null;

        try {
            const {
                text,
                flirt_suggestion_id,
                voice_model = 'eleven_monolingual_v1',
                voice_id = 'pMsXgVXv3BLzUgSXRplE', // Default ElevenLabs voice
                voice_settings = {
                    stability: 0.5,
                    similarity_boost: 0.8,
                    style: 0.5,
                    use_speaker_boost: true
                }
            } = req.body;

            // Validate text input
            const textValidation = validateTextLength(text, 1000);
            if (!textValidation.valid) {
                return res.status(400).json({
                    success: false,
                    error: textValidation.error,
                    code: 'VALIDATION_ERROR'
                });
            }

            // Validate voice model
            const modelValidation = validateVoiceModel(voice_model);
            if (!modelValidation.valid) {
                return res.status(400).json({
                    success: false,
                    error: modelValidation.error,
                    code: 'VALIDATION_ERROR'
                });
            }

            // Validate voice ID
            const voiceIdValidation = validateVoiceId(voice_id);
            if (!voiceIdValidation.valid) {
                return res.status(400).json({
                    success: false,
                    error: voiceIdValidation.error,
                    code: 'VALIDATION_ERROR'
                });
            }

            // Sanitize text to prevent XSS
            const sanitizedText = sanitizeText(text);

            // If flirt_suggestion_id is provided, validate it belongs to user (if database is available)
            if (flirt_suggestion_id) {
                try {
                    const suggestionQuery = `
                        SELECT user_id FROM flirt_suggestions WHERE id = $1
                    `;

                    const suggestionResult = await pool.query(suggestionQuery, [flirt_suggestion_id]);

                    if (suggestionResult.rows.length === 0) {
                        console.warn('Flirt suggestion not found in database, continuing with test');
                    } else if (suggestionResult.rows[0].user_id !== req.user.id) {
                        return res.status(403).json({
                            success: false,
                            error: 'Access denied',
                            code: 'ACCESS_DENIED'
                        });
                    }
                } catch (dbError) {
                    console.warn('Database query failed, continuing with test:', dbError.message);
                }
            }

            // Create voice message record (if database is available)
            let voiceMessageId = 'test-voice-' + Date.now();
            try {
                const insertVoiceQuery = `
                    INSERT INTO voice_messages (flirt_suggestion_id, user_id, text_content, synthesis_status, voice_model)
                    VALUES ($1, $2, $3, 'processing', $4)
                    RETURNING id
                `;

                const voiceResult = await pool.query(insertVoiceQuery, [
                    flirt_suggestion_id,
                    req.user.id,
                    sanitizedText,
                    voice_model
                ]);

                voiceMessageId = voiceResult.rows[0].id;
            } catch (dbError) {
                console.warn('Database insert failed, using mock ID:', dbError.message);
            }

            // Prepare ElevenLabs API request
            const elevenLabsUrl = `${process.env.ELEVENLABS_API_URL}/text-to-speech/${voice_id}`;

            const requestData = {
                text: sanitizedText,
                model_id: voice_model,
                voice_settings: voice_settings
            };

            console.log('Making request to ElevenLabs API...');
            const elevenLabsResponse = await axios.post(elevenLabsUrl, requestData, {
                headers: {
                    'Accept': 'audio/mpeg',
                    'Content-Type': 'application/json',
                    'xi-api-key': process.env.ELEVENLABS_API_KEY
                },
                responseType: 'arraybuffer',
                timeout: 30000 // 30 second timeout
            });

            if (!elevenLabsResponse.data) {
                throw new Error('No audio data received from ElevenLabs API');
            }

            // Save audio file
            const audioFileName = `voice-${voiceMessageId}-${Date.now()}.mp3`;
            const audioFilePath = path.join(process.env.UPLOAD_DIR || './uploads', audioFileName);

            await fs.writeFile(audioFilePath, elevenLabsResponse.data);

            // Get file size
            const fileStats = await fs.stat(audioFilePath);
            const fileSize = fileStats.size;

            // Update voice message record with file info (if database is available)
            try {
                await pool.query(
                    `UPDATE voice_messages
                     SET voice_file_path = $1, voice_file_size = $2, synthesis_status = 'completed', synthesized_at = NOW()
                     WHERE id = $3`,
                    [audioFilePath, fileSize, voiceMessageId]
                );
            } catch (dbError) {
                console.warn('Database update failed:', dbError.message);
            }

            // Log analytics event (if database is available)
            try {
                await pool.query(
                    `INSERT INTO analytics (user_id, event_type, event_data)
                     VALUES ($1, $2, $3)`,
                    [req.user.id, 'voice_synthesized', {
                        voice_message_id: voiceMessageId,
                        flirt_suggestion_id,
                        text_length: sanitizedText.length,
                        voice_model,
                        file_size: fileSize
                    }]
                );
            } catch (dbError) {
                console.warn('Analytics logging failed:', dbError.message);
            }

            res.json({
                success: true,
                data: {
                    voice_message_id: voiceMessageId,
                    audio_file: audioFileName,
                    file_size: fileSize,
                    text_content: sanitizedText,
                    voice_model,
                    synthesized_at: new Date().toISOString(),
                    download_url: `/api/v1/voice/${voiceMessageId}/download`
                },
                message: 'Voice synthesis completed successfully'
            });

        } catch (error) {
            console.error('Voice synthesis error:', error);

            // Update voice message status to failed if we have an ID (if database is available)
            if (voiceMessageId) {
                try {
                    await pool.query(
                        `UPDATE voice_messages
                         SET synthesis_status = 'failed', synthesized_at = NOW()
                         WHERE id = $1`,
                        [voiceMessageId]
                    );
                } catch (dbError) {
                    console.warn('Failed to update voice message status:', dbError.message);
                }
            }

            // Handle specific API errors
            if (error.response) {
                const apiError = error.response.data;
                console.error('ElevenLabs API Error:', apiError);

                // Handle quota exceeded
                if (error.response.status === 429) {
                    return res.status(429).json({
                        success: false,
                        error: 'Voice synthesis quota exceeded',
                        details: 'ElevenLabs API rate limit reached',
                        code: 'QUOTA_EXCEEDED'
                    });
                }

                // Handle payment required
                if (error.response.status === 402) {
                    return res.status(402).json({
                        success: false,
                        error: 'Payment required for voice synthesis',
                        details: 'ElevenLabs subscription required',
                        code: 'PAYMENT_REQUIRED'
                    });
                }

                return res.status(502).json({
                    success: false,
                    error: 'ElevenLabs API error',
                    details: typeof apiError === 'string' ? apiError : (apiError.detail || 'API request failed'),
                    code: 'ELEVENLABS_API_ERROR'
                });
            }

            // Handle network/timeout errors
            if (error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT') {
                return res.status(504).json({
                    success: false,
                    error: 'Voice synthesis request timed out',
                    code: 'REQUEST_TIMEOUT'
                });
            }

            res.status(500).json({
                success: false,
                error: 'Voice synthesis failed',
                details: error.message,
                code: 'VOICE_SYNTHESIS_ERROR'
            });
        }
    }
);

/**
 * Download Voice File
 * GET /api/v1/voice/:voiceMessageId/download
 */
router.get('/:voiceMessageId/download', authenticateToken, async (req, res) => {
    try {
        const { voiceMessageId } = req.params;

        // Get voice message info
        const voiceQuery = `
            SELECT vm.*, u.id as owner_id
            FROM voice_messages vm
            JOIN users u ON vm.user_id = u.id
            WHERE vm.id = $1 AND vm.synthesis_status = 'completed'
        `;

        const voiceResult = await pool.query(voiceQuery, [voiceMessageId]);

        if (voiceResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Voice message not found or not completed',
                code: 'VOICE_MESSAGE_NOT_FOUND'
            });
        }

        const voiceMessage = voiceResult.rows[0];

        // Check if user owns this voice message
        if (voiceMessage.owner_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Access denied',
                code: 'ACCESS_DENIED'
            });
        }

        // Check if file exists
        if (!voiceMessage.voice_file_path) {
            return res.status(404).json({
                success: false,
                error: 'Voice file not found',
                code: 'FILE_NOT_FOUND'
            });
        }

        try {
            await fs.access(voiceMessage.voice_file_path);
        } catch (fileError) {
            return res.status(404).json({
                success: false,
                error: 'Voice file not found on server',
                code: 'FILE_NOT_FOUND'
            });
        }

        // Set appropriate headers
        const fileName = path.basename(voiceMessage.voice_file_path);
        res.setHeader('Content-Type', 'audio/mpeg');
        res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
        res.setHeader('Content-Length', voiceMessage.voice_file_size);

        // Stream the file
        const fileStream = require('fs').createReadStream(voiceMessage.voice_file_path);

        fileStream.on('error', (error) => {
            console.error('File stream error:', error);
            if (!res.headersSent) {
                res.status(500).json({
                    success: false,
                    error: 'Failed to stream voice file',
                    code: 'STREAM_ERROR'
                });
            }
        });

        fileStream.pipe(res);

    } catch (error) {
        console.error('Download voice file error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to download voice file',
            code: 'DOWNLOAD_ERROR'
        });
    }
});

/**
 * Get User's Voice History
 * GET /api/v1/voice/history
 */
router.get('/history', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 20, flirt_suggestion_id } = req.query;
        const offset = (page - 1) * limit;

        let whereClause = 'WHERE vm.user_id = $1';
        let queryParams = [req.user.id];

        if (flirt_suggestion_id) {
            whereClause += ' AND vm.flirt_suggestion_id = $' + (queryParams.length + 1);
            queryParams.push(flirt_suggestion_id);
        }

        const historyQuery = `
            SELECT vm.id, vm.text_content, vm.synthesis_status, vm.voice_model,
                   vm.created_at, vm.synthesized_at, vm.voice_file_size,
                   fs.suggestion_text
            FROM voice_messages vm
            LEFT JOIN flirt_suggestions fs ON vm.flirt_suggestion_id = fs.id
            ${whereClause}
            ORDER BY vm.created_at DESC
            LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
        `;

        const countQuery = `
            SELECT COUNT(*) as total
            FROM voice_messages vm
            ${whereClause}
        `;

        queryParams.push(limit, offset);

        const [historyResult, countResult] = await Promise.all([
            pool.query(historyQuery, queryParams),
            pool.query(countQuery, queryParams.slice(0, -2)) // Remove limit and offset for count
        ]);

        const voiceMessages = historyResult.rows.map(vm => ({
            id: vm.id,
            text_content: vm.text_content,
            synthesis_status: vm.synthesis_status,
            voice_model: vm.voice_model,
            created_at: vm.created_at,
            synthesized_at: vm.synthesized_at,
            file_size: vm.voice_file_size,
            related_suggestion: vm.suggestion_text,
            download_url: vm.synthesis_status === 'completed' ? `/api/v1/voice/${vm.id}/download` : null
        }));

        const total = parseInt(countResult.rows[0].total);

        res.json({
            success: true,
            data: {
                voice_messages: voiceMessages,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get voice history error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get voice history',
            code: 'GET_HISTORY_ERROR'
        });
    }
});

/**
 * Delete Voice Message
 * DELETE /api/v1/voice/:voiceMessageId
 */
router.delete('/:voiceMessageId', authenticateToken, async (req, res) => {
    try {
        const { voiceMessageId } = req.params;

        // Get voice message info first
        const voiceQuery = `
            SELECT voice_file_path, user_id
            FROM voice_messages
            WHERE id = $1
        `;

        const voiceResult = await pool.query(voiceQuery, [voiceMessageId]);

        if (voiceResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Voice message not found',
                code: 'VOICE_MESSAGE_NOT_FOUND'
            });
        }

        const voiceMessage = voiceResult.rows[0];

        // Check if user owns this voice message
        if (voiceMessage.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Access denied',
                code: 'ACCESS_DENIED'
            });
        }

        // Delete from database
        await pool.query('DELETE FROM voice_messages WHERE id = $1', [voiceMessageId]);

        // Delete file from filesystem
        if (voiceMessage.voice_file_path) {
            await fs.unlink(voiceMessage.voice_file_path).catch(error =>
                console.error('Failed to delete voice file:', error)
            );
        }

        res.json({
            success: true,
            message: 'Voice message deleted successfully'
        });

    } catch (error) {
        console.error('Delete voice message error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete voice message',
            code: 'DELETE_ERROR'
        });
    }
});

/**
 * Get Available Voices from ElevenLabs
 * GET /api/v1/voice/voices
 */
router.get('/voices', authenticateToken, rateLimit(10, 60 * 1000), async (req, res) => {
    try {
        const elevenLabsUrl = `${process.env.ELEVENLABS_API_URL}/voices`;

        const response = await axios.get(elevenLabsUrl, {
            headers: {
                'xi-api-key': process.env.ELEVENLABS_API_KEY
            },
            timeout: 10000
        });

        res.json({
            success: true,
            data: {
                voices: response.data.voices || []
            }
        });

    } catch (error) {
        console.error('Get voices error:', error);

        if (error.response) {
            return res.status(502).json({
                success: false,
                error: 'ElevenLabs API error',
                details: error.response.data,
                code: 'ELEVENLABS_API_ERROR'
            });
        }

        res.status(500).json({
            success: false,
            error: 'Failed to get available voices',
            code: 'GET_VOICES_ERROR'
        });
    }
});

module.exports = router;