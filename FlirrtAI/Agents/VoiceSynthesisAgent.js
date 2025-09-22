/**
 * VoiceSynthesisAgent.js - AI Sub-Agent for Voice Generation Orchestration
 *
 * Orchestrates voice generation with emotion-specific parameters using ElevenLabs API
 * for quality assessment and voice synthesis management.
 */

const axios = require('axios');
const FormData = require('form-data');

class VoiceSynthesisAgent {
    constructor() {
        this.elevenLabsApiKey = process.env.ELEVENLABS_API_KEY || 'REMOVED_ELEVENLABS_KEY';
        this.apiBaseUrl = 'https://api.elevenlabs.io/v1';

        // Emotion-specific voice parameters
        this.emotionParameters = {
            playful: {
                stability: 0.3,
                similarity_boost: 0.8,
                style: 0.7,
                use_speaker_boost: true,
                emotion: 'excited',
                description: 'Light, energetic, and fun tone'
            },
            sincere: {
                stability: 0.7,
                similarity_boost: 0.9,
                style: 0.3,
                use_speaker_boost: false,
                emotion: 'warm',
                description: 'Genuine, thoughtful, and caring tone'
            },
            humorous: {
                stability: 0.4,
                similarity_boost: 0.7,
                style: 0.8,
                use_speaker_boost: true,
                emotion: 'cheerful',
                description: 'Witty, amusing, and engaging tone'
            },
            romantic: {
                stability: 0.6,
                similarity_boost: 0.9,
                style: 0.5,
                use_speaker_boost: false,
                emotion: 'loving',
                description: 'Soft, intimate, and affectionate tone'
            },
            confident: {
                stability: 0.8,
                similarity_boost: 0.8,
                style: 0.4,
                use_speaker_boost: true,
                emotion: 'confident',
                description: 'Strong, assured, and charismatic tone'
            },
            flirty: {
                stability: 0.4,
                similarity_boost: 0.8,
                style: 0.9,
                use_speaker_boost: true,
                emotion: 'playful',
                description: 'Teasing, charming, and alluring tone'
            },
            casual: {
                stability: 0.5,
                similarity_boost: 0.7,
                style: 0.3,
                use_speaker_boost: false,
                emotion: 'neutral',
                description: 'Relaxed, natural, and conversational tone'
            }
        };

        // Voice presets for different user demographics
        this.voicePresets = {
            'young_male': {
                voice_ids: ['21m00Tcm4TlvDq8ikWAM', 'VR6AewLTigWG4xSOukaG', 'pNInz6obpgDQGcFmaJgB'],
                default_emotion: 'confident',
                description: 'Youthful, energetic male voices'
            },
            'young_female': {
                voice_ids: ['EXAVITQu4vr4xnSDxMaL', 'AZnzlk1XvdvUeBnXmlld', 'ThT5KcBeYPX3keUQqHPh'],
                default_emotion: 'playful',
                description: 'Bright, vibrant female voices'
            },
            'mature_male': {
                voice_ids: ['ErXwobaYiN019PkySvjV', 'VR6AewLTigWG4xSOukaG', 'TxGEqnHWrfWFTfGW9XjX'],
                default_emotion: 'sincere',
                description: 'Mature, sophisticated male voices'
            },
            'mature_female': {
                voice_ids: ['MF3mGyEYCl7XYWbV9V6O', 'oWAxZDx7w5VEj9dCyTzz', 'ThT5KcBeYPX3keUQqHPh'],
                default_emotion: 'sincere',
                description: 'Mature, elegant female voices'
            }
        };

        // Quality assessment criteria
        this.qualityMetrics = {
            clarity: { weight: 0.3, threshold: 0.7 },
            naturalness: { weight: 0.25, threshold: 0.6 },
            emotional_match: { weight: 0.25, threshold: 0.6 },
            pronunciation: { weight: 0.2, threshold: 0.7 }
        };

        this.maxRetries = 2;
        this.cacheDuration = 24 * 60 * 60 * 1000; // 24 hours
        this.voiceCache = new Map();
    }

    /**
     * Generate voice message with emotion-specific parameters
     * @param {Object} params - Voice generation parameters
     * @returns {Promise<Object>} Voice generation result
     */
    async synthesizeVoice(params) {
        try {
            // Validate and normalize parameters
            const normalizedParams = this.normalizeVoiceParams(params);

            // Select optimal voice for user and emotion
            const selectedVoice = await this.selectOptimalVoice(normalizedParams);

            // Generate voice with emotion parameters
            const voiceResult = await this.generateVoiceWithRetry(normalizedParams, selectedVoice);

            // Assess quality of generated voice
            const qualityAssessment = await this.assessVoiceQuality(voiceResult, normalizedParams);

            // Cache successful results
            if (qualityAssessment.overallScore >= 0.7) {
                this.cacheVoiceResult(normalizedParams, voiceResult);
            }

            return {
                success: true,
                voice: {
                    audio_url: voiceResult.audio_url,
                    audio_data: voiceResult.audio_data,
                    voice_id: selectedVoice.voice_id,
                    voice_name: selectedVoice.name,
                    emotion: normalizedParams.emotion,
                    duration: voiceResult.duration,
                    file_size: voiceResult.file_size
                },
                quality: qualityAssessment,
                parameters: normalizedParams.voice_settings,
                metadata: {
                    generated_at: new Date().toISOString(),
                    model_used: 'eleven_multilingual_v2',
                    attempts: voiceResult.attempts || 1,
                    cached: false
                }
            };

        } catch (error) {
            console.error('Voice synthesis error:', error);
            return {
                success: false,
                error: error.message,
                fallback: await this.getFallbackVoice(params)
            };
        }
    }

    /**
     * Generate voice with retry logic
     * @param {Object} params - Normalized parameters
     * @param {Object} voice - Selected voice
     * @returns {Promise<Object>} Generation result
     */
    async generateVoiceWithRetry(params, voice) {
        let lastError;

        for (let attempt = 1; attempt <= this.maxRetries + 1; attempt++) {
            try {
                const result = await this.callElevenLabsAPI(params, voice);
                return { ...result, attempts: attempt };
            } catch (error) {
                lastError = error;
                console.warn(`Voice generation attempt ${attempt} failed:`, error.message);

                if (attempt <= this.maxRetries) {
                    // Adjust parameters for retry
                    params.voice_settings = this.adjustParametersForRetry(params.voice_settings, attempt);
                    await this.delay(1000 * attempt); // Progressive delay
                }
            }
        }

        throw lastError;
    }

    /**
     * Call ElevenLabs API for voice generation
     * @param {Object} params - Voice parameters
     * @param {Object} voice - Voice configuration
     * @returns {Promise<Object>} API response
     */
    async callElevenLabsAPI(params, voice) {
        const url = `${this.apiBaseUrl}/text-to-speech/${voice.voice_id}`;

        const requestBody = {
            text: params.text,
            model_id: params.model_id || 'eleven_multilingual_v2',
            voice_settings: params.voice_settings
        };

        const response = await axios.post(url, requestBody, {
            headers: {
                'Accept': 'audio/mpeg',
                'Content-Type': 'application/json',
                'xi-api-key': this.elevenLabsApiKey
            },
            responseType: 'arraybuffer',
            timeout: 30000
        });

        // Convert audio data to base64
        const audioBase64 = Buffer.from(response.data).toString('base64');

        return {
            audio_data: audioBase64,
            audio_url: null, // Would be set if uploading to storage
            duration: this.estimateAudioDuration(params.text),
            file_size: response.data.byteLength,
            content_type: 'audio/mpeg'
        };
    }

    /**
     * Normalize voice generation parameters
     * @param {Object} params - Raw parameters
     * @returns {Object} Normalized parameters
     */
    normalizeVoiceParams(params) {
        // Extract emotion from text or use provided emotion
        const detectedEmotion = this.detectEmotionFromText(params.text);
        const emotion = params.emotion || detectedEmotion || 'casual';

        // Get emotion-specific parameters
        const emotionParams = this.emotionParameters[emotion] || this.emotionParameters.casual;

        // Override with user-provided settings
        const voice_settings = {
            stability: params.stability ?? emotionParams.stability,
            similarity_boost: params.similarity_boost ?? emotionParams.similarity_boost,
            style: params.style ?? emotionParams.style,
            use_speaker_boost: params.use_speaker_boost ?? emotionParams.use_speaker_boost
        };

        return {
            text: params.text,
            emotion: emotion,
            voice_settings: voice_settings,
            user_age: params.user_age || 25,
            user_gender: params.user_gender || 'neutral',
            target_audience: params.target_audience || 'general',
            model_id: params.model_id || 'eleven_multilingual_v2',
            quality_threshold: params.quality_threshold || 0.7
        };
    }

    /**
     * Select optimal voice based on user parameters
     * @param {Object} params - Voice parameters
     * @returns {Promise<Object>} Selected voice
     */
    async selectOptimalVoice(params) {
        try {
            // Determine voice preset category
            const category = this.determineVoiceCategory(params);
            const preset = this.voicePresets[category] || this.voicePresets.young_male;

            // Get available voices from ElevenLabs
            const availableVoices = await this.getAvailableVoices();

            // Find best matching voice from preset
            const presetVoices = availableVoices.filter(voice =>
                preset.voice_ids.includes(voice.voice_id)
            );

            if (presetVoices.length === 0) {
                // Fallback to first available voice
                return availableVoices[0] || this.getDefaultVoice();
            }

            // Select voice based on emotion compatibility
            const selectedVoice = this.selectVoiceForEmotion(presetVoices, params.emotion);

            return selectedVoice;

        } catch (error) {
            console.error('Voice selection error:', error);
            return this.getDefaultVoice();
        }
    }

    /**
     * Get available voices from ElevenLabs API
     * @returns {Promise<Array>} Available voices
     */
    async getAvailableVoices() {
        try {
            const response = await axios.get(`${this.apiBaseUrl}/voices`, {
                headers: {
                    'xi-api-key': this.elevenLabsApiKey
                }
            });

            return response.data.voices.map(voice => ({
                voice_id: voice.voice_id,
                name: voice.name,
                category: voice.category,
                description: voice.description,
                labels: voice.labels || {},
                preview_url: voice.preview_url
            }));

        } catch (error) {
            console.error('Error fetching voices:', error);
            return this.getDefaultVoices();
        }
    }

    /**
     * Determine voice category based on user parameters
     * @param {Object} params - User parameters
     * @returns {string} Voice category
     */
    determineVoiceCategory(params) {
        const age = params.user_age;
        const gender = params.user_gender.toLowerCase();

        if (age < 30) {
            return gender === 'female' ? 'young_female' : 'young_male';
        } else {
            return gender === 'female' ? 'mature_female' : 'mature_male';
        }
    }

    /**
     * Select best voice for specific emotion
     * @param {Array} voices - Available voices
     * @param {string} emotion - Target emotion
     * @returns {Object} Selected voice
     */
    selectVoiceForEmotion(voices, emotion) {
        // Voice-emotion compatibility scores
        const emotionCompatibility = {
            playful: { young: 1.0, energetic: 0.9, cheerful: 0.8 },
            sincere: { mature: 1.0, warm: 0.9, calm: 0.8 },
            humorous: { young: 0.9, energetic: 0.8, playful: 1.0 },
            romantic: { smooth: 1.0, warm: 0.9, soft: 0.8 },
            confident: { strong: 1.0, mature: 0.8, clear: 0.7 },
            flirty: { playful: 1.0, young: 0.8, smooth: 0.9 },
            casual: { natural: 1.0, relaxed: 0.9, clear: 0.7 }
        };

        const targetCompatibility = emotionCompatibility[emotion] || emotionCompatibility.casual;

        // Score voices based on compatibility
        const scoredVoices = voices.map(voice => {
            let score = 0.5; // Base score

            // Check voice labels/characteristics
            Object.entries(targetCompatibility).forEach(([characteristic, weight]) => {
                if (voice.description?.toLowerCase().includes(characteristic) ||
                    voice.labels?.[characteristic] ||
                    voice.name.toLowerCase().includes(characteristic)) {
                    score += weight * 0.3;
                }
            });

            return { ...voice, compatibility_score: score };
        });

        // Return highest scoring voice
        scoredVoices.sort((a, b) => b.compatibility_score - a.compatibility_score);
        return scoredVoices[0] || voices[0];
    }

    /**
     * Detect emotion from text content
     * @param {string} text - Text to analyze
     * @returns {string} Detected emotion
     */
    detectEmotionFromText(text) {
        const emotionKeywords = {
            playful: ['haha', '😏', '😄', 'fun', 'play', 'silly', 'tease'],
            sincere: ['honestly', 'really', 'truly', 'genuine', 'serious', 'appreciate'],
            humorous: ['funny', 'joke', 'laugh', '😂', 'hilarious', 'witty', 'clever'],
            romantic: ['love', 'beautiful', 'gorgeous', 'heart', '❤️', 'kiss', 'romantic'],
            confident: ['definitely', 'absolutely', 'sure', 'confident', 'know', 'certain'],
            flirty: ['cute', 'sexy', 'attractive', '😘', 'wink', 'charm', 'flirt'],
            casual: ['hey', 'cool', 'nice', 'good', 'alright', 'okay']
        };

        const textLower = text.toLowerCase();
        let maxScore = 0;
        let detectedEmotion = 'casual';

        Object.entries(emotionKeywords).forEach(([emotion, keywords]) => {
            const score = keywords.reduce((sum, keyword) => {
                return sum + (textLower.includes(keyword) ? 1 : 0);
            }, 0);

            if (score > maxScore) {
                maxScore = score;
                detectedEmotion = emotion;
            }
        });

        return detectedEmotion;
    }

    /**
     * Assess quality of generated voice
     * @param {Object} voiceResult - Generated voice data
     * @param {Object} params - Generation parameters
     * @returns {Promise<Object>} Quality assessment
     */
    async assessVoiceQuality(voiceResult, params) {
        // Placeholder for quality assessment algorithm
        // In production, this would use audio analysis libraries

        const assessment = {
            clarity: this.assessClarity(voiceResult, params),
            naturalness: this.assessNaturalness(voiceResult, params),
            emotional_match: this.assessEmotionalMatch(voiceResult, params),
            pronunciation: this.assessPronunciation(voiceResult, params)
        };

        // Calculate weighted overall score
        const overallScore = Object.entries(assessment).reduce((sum, [metric, score]) => {
            const weight = this.qualityMetrics[metric]?.weight || 0.25;
            return sum + (score * weight);
        }, 0);

        return {
            ...assessment,
            overallScore: Math.round(overallScore * 100) / 100,
            meetsCriteria: overallScore >= params.quality_threshold,
            recommendations: this.generateQualityRecommendations(assessment)
        };
    }

    /**
     * Assess voice clarity
     * @param {Object} voiceResult - Voice data
     * @param {Object} params - Parameters
     * @returns {number} Clarity score 0-1
     */
    assessClarity(voiceResult, params) {
        // Basic heuristic based on file size and duration
        const expectedSizePerSecond = 8000; // Approximate bytes per second for clear audio
        const actualSizePerSecond = voiceResult.file_size / voiceResult.duration;

        const sizeScore = Math.min(1.0, actualSizePerSecond / expectedSizePerSecond);

        // Factor in stability setting (higher stability usually means clearer)
        const stabilityBonus = params.voice_settings.stability * 0.2;

        return Math.min(1.0, sizeScore + stabilityBonus);
    }

    /**
     * Assess voice naturalness
     * @param {Object} voiceResult - Voice data
     * @param {Object} params - Parameters
     * @returns {number} Naturalness score 0-1
     */
    assessNaturalness(voiceResult, params) {
        // Base score influenced by similarity boost and style settings
        let score = 0.7; // Base naturalness

        // Similarity boost helps naturalness
        score += params.voice_settings.similarity_boost * 0.2;

        // Very high style can sometimes sound unnatural
        if (params.voice_settings.style > 0.8) {
            score -= 0.1;
        }

        // Speaker boost can improve naturalness
        if (params.voice_settings.use_speaker_boost) {
            score += 0.1;
        }

        return Math.min(1.0, Math.max(0.0, score));
    }

    /**
     * Assess emotional match
     * @param {Object} voiceResult - Voice data
     * @param {Object} params - Parameters
     * @returns {number} Emotional match score 0-1
     */
    assessEmotionalMatch(voiceResult, params) {
        // Score based on how well settings match the intended emotion
        const emotionParams = this.emotionParameters[params.emotion];
        if (!emotionParams) return 0.6;

        let score = 0.5; // Base score

        // Compare actual settings to ideal emotion settings
        const stabilityDiff = Math.abs(params.voice_settings.stability - emotionParams.stability);
        const styleDiff = Math.abs(params.voice_settings.style - emotionParams.style);
        const similarityDiff = Math.abs(params.voice_settings.similarity_boost - emotionParams.similarity_boost);

        // Lower differences mean better match
        score += (1 - stabilityDiff) * 0.2;
        score += (1 - styleDiff) * 0.2;
        score += (1 - similarityDiff) * 0.1;

        return Math.min(1.0, Math.max(0.0, score));
    }

    /**
     * Assess pronunciation quality
     * @param {Object} voiceResult - Voice data
     * @param {Object} params - Parameters
     * @returns {number} Pronunciation score 0-1
     */
    assessPronunciation(voiceResult, params) {
        // Basic heuristic - in production would use phonetic analysis
        let score = 0.8; // Assume good baseline

        // Complex words or names might have lower pronunciation quality
        const complexWords = params.text.match(/[A-Z][a-z]{6,}|[a-z]{10,}/g) || [];
        score -= complexWords.length * 0.05;

        // Numbers and special characters
        const specialChars = params.text.match(/\d+|[^\w\s]/g) || [];
        score -= specialChars.length * 0.02;

        return Math.min(1.0, Math.max(0.4, score));
    }

    /**
     * Generate quality improvement recommendations
     * @param {Object} assessment - Quality assessment
     * @returns {Array} Recommendations
     */
    generateQualityRecommendations(assessment) {
        const recommendations = [];

        if (assessment.clarity < 0.7) {
            recommendations.push('Increase stability setting for better clarity');
        }

        if (assessment.naturalness < 0.6) {
            recommendations.push('Increase similarity boost and reduce style intensity');
        }

        if (assessment.emotional_match < 0.6) {
            recommendations.push('Adjust voice settings to better match intended emotion');
        }

        if (assessment.pronunciation < 0.7) {
            recommendations.push('Simplify complex words or add pronunciation guides');
        }

        return recommendations;
    }

    /**
     * Adjust parameters for retry attempts
     * @param {Object} settings - Current voice settings
     * @param {number} attempt - Retry attempt number
     * @returns {Object} Adjusted settings
     */
    adjustParametersForRetry(settings, attempt) {
        // Make conservative adjustments for retries
        return {
            stability: Math.min(1.0, settings.stability + (attempt * 0.1)),
            similarity_boost: Math.max(0.0, settings.similarity_boost - (attempt * 0.05)),
            style: Math.max(0.0, settings.style - (attempt * 0.1)),
            use_speaker_boost: settings.use_speaker_boost
        };
    }

    /**
     * Estimate audio duration from text
     * @param {string} text - Text content
     * @returns {number} Estimated duration in seconds
     */
    estimateAudioDuration(text) {
        // Average reading speed: ~150 words per minute
        const words = text.split(/\s+/).length;
        const wordsPerSecond = 150 / 60; // ~2.5 words per second
        return Math.max(1, Math.round(words / wordsPerSecond));
    }

    /**
     * Cache voice generation result
     * @param {Object} params - Generation parameters
     * @param {Object} result - Voice result
     */
    cacheVoiceResult(params, result) {
        const cacheKey = this.generateCacheKey(params);
        this.voiceCache.set(cacheKey, {
            result,
            timestamp: Date.now(),
            params
        });

        // Clean old cache entries
        this.cleanCache();
    }

    /**
     * Generate cache key from parameters
     * @param {Object} params - Voice parameters
     * @returns {string} Cache key
     */
    generateCacheKey(params) {
        return `${params.text}_${params.emotion}_${params.user_gender}_${params.user_age}`.replace(/\s+/g, '_');
    }

    /**
     * Clean expired cache entries
     */
    cleanCache() {
        const now = Date.now();
        for (const [key, entry] of this.voiceCache.entries()) {
            if (now - entry.timestamp > this.cacheDuration) {
                this.voiceCache.delete(key);
            }
        }
    }

    /**
     * Get fallback voice for error cases
     * @param {Object} params - Original parameters
     * @returns {Promise<Object>} Fallback voice
     */
    async getFallbackVoice(params) {
        return {
            success: false,
            message: 'Voice generation temporarily unavailable',
            fallback: {
                text: params.text,
                suggestion: 'Try again with simpler text or different emotion settings',
                alternatives: [
                    'Use text-to-speech on device',
                    'Record voice message manually',
                    'Send as text message'
                ]
            }
        };
    }

    /**
     * Get default voice configuration
     * @returns {Object} Default voice
     */
    getDefaultVoice() {
        return {
            voice_id: '21m00Tcm4TlvDq8ikWAM', // ElevenLabs default voice
            name: 'Default Voice',
            category: 'premade',
            description: 'Default voice for fallback',
            compatibility_score: 0.5
        };
    }

    /**
     * Get default voice list for fallback
     * @returns {Array} Default voices
     */
    getDefaultVoices() {
        return [
            {
                voice_id: '21m00Tcm4TlvDq8ikWAM',
                name: 'Rachel',
                category: 'premade',
                description: 'Young American female voice'
            },
            {
                voice_id: 'VR6AewLTigWG4xSOukaG',
                name: 'Arnold',
                category: 'premade',
                description: 'Middle-aged American male voice'
            }
        ];
    }

    /**
     * Delay execution for specified milliseconds
     * @param {number} ms - Milliseconds to delay
     * @returns {Promise} Delay promise
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Get voice synthesis health status
     * @returns {Promise<Object>} Health status
     */
    async getHealthStatus() {
        try {
            // Test API connectivity
            const response = await axios.get(`${this.apiBaseUrl}/voices`, {
                headers: {
                    'xi-api-key': this.elevenLabsApiKey
                },
                timeout: 5000
            });

            return {
                status: 'healthy',
                apiConnected: true,
                availableVoices: response.data.voices?.length || 0,
                emotionsSupported: Object.keys(this.emotionParameters).length,
                cacheSize: this.voiceCache.size,
                lastChecked: new Date().toISOString()
            };

        } catch (error) {
            return {
                status: 'unhealthy',
                apiConnected: false,
                error: error.message,
                lastChecked: new Date().toISOString()
            };
        }
    }

    /**
     * Get available emotions and their parameters
     * @returns {Object} Emotion configurations
     */
    getAvailableEmotions() {
        return Object.entries(this.emotionParameters).map(([emotion, params]) => ({
            emotion,
            description: params.description,
            parameters: {
                stability: params.stability,
                similarity_boost: params.similarity_boost,
                style: params.style,
                use_speaker_boost: params.use_speaker_boost
            },
            recommended_for: this.getEmotionRecommendations(emotion)
        }));
    }

    /**
     * Get recommendations for when to use specific emotions
     * @param {string} emotion - Emotion type
     * @returns {Array} Usage recommendations
     */
    getEmotionRecommendations(emotion) {
        const recommendations = {
            playful: ['Light banter', 'Teasing messages', 'Fun conversations'],
            sincere: ['Heartfelt messages', 'Serious topics', 'Genuine compliments'],
            humorous: ['Jokes', 'Witty responses', 'Comedy'],
            romantic: ['Love declarations', 'Intimate messages', 'Date invitations'],
            confident: ['Bold statements', 'Self-assured messages', 'Leadership'],
            flirty: ['Playful teasing', 'Attraction expressions', 'Charming messages'],
            casual: ['Everyday conversation', 'Friendly chat', 'Neutral topics']
        };

        return recommendations[emotion] || ['General conversation'];
    }

    /**
     * Get voice generation statistics
     * @returns {Object} Usage statistics
     */
    getStatistics() {
        return {
            emotions_available: Object.keys(this.emotionParameters).length,
            voice_presets: Object.keys(this.voicePresets).length,
            cache_size: this.voiceCache.size,
            max_retries: this.maxRetries,
            quality_threshold: 0.7,
            cache_duration_hours: this.cacheDuration / (1000 * 60 * 60)
        };
    }
}

module.exports = VoiceSynthesisAgent;