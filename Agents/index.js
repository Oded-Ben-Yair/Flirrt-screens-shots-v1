/**
 * Flirrt.ai AI Sub-Agents Module
 *
 * This module exports all AI Sub-Agents for easy integration with the backend.
 * Each agent is a specialized component that handles specific aspects of the
 * Flirrt.ai dating app experience.
 *
 * Usage:
 * const { ScreenshotAnalyzer, FlirtGenerator, VoiceSynthesisAgent } = require('./Agents');
 *
 * Or import individual agents:
 * const ScreenshotAnalyzer = require('./Agents/ScreenshotAnalyzer');
 */

// Import all AI Sub-Agents
const ScreenshotAnalyzer = require('./ScreenshotAnalyzer');
const PersonalizationAgent = require('./PersonalizationAgent');
const FlirtGenerator = require('./FlirtGenerator');
const VoiceSynthesisAgent = require('./VoiceSynthesisAgent');
const ConsentPrivacyAgent = require('./ConsentPrivacyAgent');
const SafetyFilter = require('./SafetyFilter');

/**
 * AgentOrchestrator - Coordinates all AI Sub-Agents
 *
 * Provides a unified interface for managing and coordinating all agents,
 * handling cross-agent communication and workflow orchestration.
 */
class AgentOrchestrator {
    constructor(config = {}) {
        // Initialize all agents
        this.screenshotAnalyzer = new ScreenshotAnalyzer();
        this.personalizationAgent = new PersonalizationAgent();
        this.flirtGenerator = new FlirtGenerator();
        this.voiceSynthesisAgent = new VoiceSynthesisAgent();
        this.consentPrivacyAgent = new ConsentPrivacyAgent();
        this.safetyFilter = new SafetyFilter();

        // Configuration
        this.config = {
            enableSafetyFilter: config.enableSafetyFilter !== false, // Default true
            enablePersonalization: config.enablePersonalization !== false, // Default true
            enableVoiceSynthesis: config.enableVoiceSynthesis !== false, // Default true
            enableConsentTracking: config.enableConsentTracking !== false, // Default true
            ...config
        };

        // Agent health status cache
        this.healthStatusCache = new Map();
        this.healthCheckInterval = 5 * 60 * 1000; // 5 minutes
    }

    /**
     * Complete workflow: Analyze screenshot and generate personalized flirts
     * @param {Object} params - Workflow parameters
     * @returns {Promise<Object>} Complete workflow result
     */
    async processConversationWorkflow(params) {
        try {
            const {
                screenshot_base64,
                user_id,
                user_context = {},
                generate_voice = false
            } = params;

            // Step 1: Check user consent and privacy
            if (this.config.enableConsentTracking) {
                const consentStatus = this.consentPrivacyAgent.getConsentStatus(user_id);
                if (!consentStatus.hasConsent) {
                    return {
                        success: false,
                        error: 'User consent required',
                        consentRequired: true,
                        consentStatus
                    };
                }
            }

            // Step 2: Analyze screenshot
            const analysisResult = await this.screenshotAnalyzer.analyzeConversation(
                screenshot_base64,
                user_context
            );

            if (!analysisResult.success) {
                return {
                    success: false,
                    error: 'Screenshot analysis failed',
                    details: analysisResult.error
                };
            }

            // Step 3: Get personalized preferences
            let personalizedPreferences = {};
            if (this.config.enablePersonalization) {
                personalizedPreferences = this.personalizationAgent.getPersonalizedPreferences(
                    user_id,
                    analysisResult.data
                );
            }

            // Step 4: Generate flirt suggestions
            const generationContext = {
                conversationStage: analysisResult.data.conversationStage,
                personalityInsights: analysisResult.data.personalityIndicators,
                userPreferences: personalizedPreferences,
                conversationHistory: user_context.conversationHistory,
                platform: user_context.platform || 'dating_app',
                timeOfDay: user_context.timeOfDay || 'afternoon',
                userId: user_id,
                userAge: user_context.userAge,
                targetAge: user_context.targetAge
            };

            const flirtResult = await this.flirtGenerator.generateFlirts(generationContext);

            if (!flirtResult.success) {
                return {
                    success: false,
                    error: 'Flirt generation failed',
                    details: flirtResult.error,
                    fallback: flirtResult.fallbackSuggestions
                };
            }

            // Step 5: Apply safety filtering
            let filteredSuggestions = flirtResult.suggestions;
            if (this.config.enableSafetyFilter) {
                filteredSuggestions = [];

                for (const suggestion of flirtResult.suggestions) {
                    const safetyResult = this.safetyFilter.filterContent(
                        { text: suggestion.text },
                        {
                            userId: user_id,
                            userAge: user_context.userAge,
                            platform: user_context.platform,
                            conversationStage: analysisResult.data.conversationStage
                        }
                    );

                    if (safetyResult.allowed) {
                        filteredSuggestions.push({
                            ...suggestion,
                            safety_approved: true,
                            safety_score: safetyResult.safety_analysis
                        });
                    } else {
                        // Log filtered content for review
                        console.log(`Suggestion filtered: ${safetyResult.reason}`);
                    }
                }
            }

            // Step 6: Generate voice synthesis (if requested)
            let voiceSynthesis = null;
            if (generate_voice && this.config.enableVoiceSynthesis && filteredSuggestions.length > 0) {
                const topSuggestion = filteredSuggestions[0];

                const voiceParams = {
                    text: topSuggestion.text,
                    emotion: topSuggestion.tone,
                    user_age: user_context.userAge,
                    user_gender: user_context.userGender || 'neutral'
                };

                voiceSynthesis = await this.voiceSynthesisAgent.synthesizeVoice(voiceParams);
            }

            // Step 7: Track interaction for personalization
            if (this.config.enablePersonalization) {
                this.personalizationAgent.trackInteraction(user_id, {
                    type: 'conversation_analysis',
                    data: {
                        analysis: analysisResult.data,
                        suggestions_generated: filteredSuggestions.length,
                        context: generationContext
                    }
                });
            }

            // Return complete workflow result
            return {
                success: true,
                workflow_id: `workflow_${Date.now()}_${user_id}`,

                // Analysis results
                conversation_analysis: analysisResult.data,

                // Personalization
                user_preferences: personalizedPreferences,

                // Generated suggestions
                suggestions: filteredSuggestions,
                suggestions_filtered: flirtResult.suggestions.length - filteredSuggestions.length,

                // Voice synthesis
                voice_synthesis: voiceSynthesis,

                // Metadata
                processing_time: Date.now(),
                agents_used: this.getActiveAgents(),
                recommendations: analysisResult.data.recommendations
            };

        } catch (error) {
            console.error('Workflow processing error:', error);
            return {
                success: false,
                error: 'Workflow processing failed',
                details: error.message
            };
        }
    }

    /**
     * Generate flirts with enhanced personalization and safety
     * @param {Object} params - Generation parameters
     * @returns {Promise<Object>} Enhanced flirt generation result
     */
    async generatePersonalizedFlirts(params) {
        try {
            const { user_id, context, count = 6 } = params;

            // Get user preferences
            const userPreferences = this.config.enablePersonalization ?
                this.personalizationAgent.getPersonalizedPreferences(user_id, context) :
                {};

            // Generate suggestions
            const generationContext = {
                ...context,
                userPreferences,
                userId: user_id
            };

            const flirtResult = await this.flirtGenerator.generateFlirts(generationContext);

            if (!flirtResult.success) {
                return flirtResult;
            }

            // Apply safety filtering
            const filteredSuggestions = [];
            for (const suggestion of flirtResult.suggestions.slice(0, count)) {
                if (this.config.enableSafetyFilter) {
                    const safetyResult = this.safetyFilter.filterContent(
                        { text: suggestion.text },
                        {
                            userId: user_id,
                            userAge: context.userAge,
                            platform: context.platform
                        }
                    );

                    if (safetyResult.allowed) {
                        filteredSuggestions.push({
                            ...suggestion,
                            safety_approved: true
                        });
                    }
                } else {
                    filteredSuggestions.push(suggestion);
                }
            }

            return {
                success: true,
                suggestions: filteredSuggestions,
                user_preferences: userPreferences,
                metadata: flirtResult.metadata
            };

        } catch (error) {
            console.error('Personalized flirt generation error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Track user feedback and improve personalization
     * @param {string} userId - User identifier
     * @param {Object} feedback - User feedback data
     * @returns {Object} Tracking result
     */
    async trackUserFeedback(userId, feedback) {
        try {
            if (!this.config.enablePersonalization) {
                return { success: true, message: 'Personalization disabled' };
            }

            // Track the feedback
            const result = this.personalizationAgent.trackInteraction(userId, {
                type: feedback.type || 'feedback',
                data: feedback
            });

            return {
                success: true,
                profile_updated: result.success,
                confidence_improvement: result.confidenceImprovement,
                message: 'Feedback tracked successfully'
            };

        } catch (error) {
            console.error('Feedback tracking error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Handle data deletion request
     * @param {string} userId - User identifier
     * @param {Object} deletionRequest - Deletion request details
     * @returns {Promise<Object>} Deletion result
     */
    async handleDataDeletion(userId, deletionRequest) {
        try {
            if (!this.config.enableConsentTracking) {
                return { success: false, error: 'Consent tracking disabled' };
            }

            // Process deletion through privacy agent
            const deletionResult = await this.consentPrivacyAgent.processDataDeletion(userId, deletionRequest);

            // Also delete from personalization agent
            if (deletionResult.success && this.config.enablePersonalization) {
                this.personalizationAgent.deleteUserData(userId);
            }

            return deletionResult;

        } catch (error) {
            console.error('Data deletion error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Get comprehensive health status of all agents
     * @returns {Promise<Object>} Health status
     */
    async getHealthStatus() {
        try {
            const healthChecks = await Promise.allSettled([
                this.screenshotAnalyzer.getHealthStatus(),
                this.flirtGenerator.getHealthStatus(),
                this.voiceSynthesisAgent.getHealthStatus(),
                this.safetyFilter.getHealthStatus(),
                this.personalizationAgent.getHealthStatus(),
                this.consentPrivacyAgent.getHealthStatus()
            ]);

            const agentNames = [
                'screenshot_analyzer',
                'flirt_generator',
                'voice_synthesis',
                'safety_filter',
                'personalization',
                'consent_privacy'
            ];

            const healthStatus = {};
            let overallHealthy = true;

            healthChecks.forEach((check, index) => {
                const agentName = agentNames[index];

                if (check.status === 'fulfilled') {
                    healthStatus[agentName] = check.value;
                    if (check.value.status !== 'healthy') {
                        overallHealthy = false;
                    }
                } else {
                    healthStatus[agentName] = {
                        status: 'error',
                        error: check.reason.message
                    };
                    overallHealthy = false;
                }
            });

            return {
                overall_status: overallHealthy ? 'healthy' : 'degraded',
                agents: healthStatus,
                configuration: this.config,
                last_checked: new Date().toISOString()
            };

        } catch (error) {
            return {
                overall_status: 'error',
                error: error.message,
                last_checked: new Date().toISOString()
            };
        }
    }

    /**
     * Get list of active agents based on configuration
     * @returns {Array} Active agent names
     */
    getActiveAgents() {
        const activeAgents = ['screenshot_analyzer', 'flirt_generator']; // Always active

        if (this.config.enableSafetyFilter) activeAgents.push('safety_filter');
        if (this.config.enablePersonalization) activeAgents.push('personalization');
        if (this.config.enableVoiceSynthesis) activeAgents.push('voice_synthesis');
        if (this.config.enableConsentTracking) activeAgents.push('consent_privacy');

        return activeAgents;
    }

    /**
     * Get agent statistics and metrics
     * @returns {Object} Agent statistics
     */
    getStatistics() {
        return {
            active_agents: this.getActiveAgents().length,
            total_agents: 6,
            configuration: this.config,
            cache_size: this.healthStatusCache.size,
            uptime: process.uptime(),
            memory_usage: process.memoryUsage()
        };
    }

    /**
     * Update agent configuration
     * @param {Object} newConfig - New configuration
     * @returns {Object} Update result
     */
    updateConfiguration(newConfig) {
        try {
            this.config = { ...this.config, ...newConfig };

            return {
                success: true,
                new_configuration: this.config,
                active_agents: this.getActiveAgents()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }
}

// Export individual agents and orchestrator
module.exports = {
    // Individual agents
    ScreenshotAnalyzer,
    PersonalizationAgent,
    FlirtGenerator,
    VoiceSynthesisAgent,
    ConsentPrivacyAgent,
    SafetyFilter,

    // Orchestrator for coordinated workflows
    AgentOrchestrator,

    // Convenience function to create orchestrator with default config
    createOrchestrator: (config = {}) => new AgentOrchestrator(config),

    // Agent information
    AGENT_INFO: {
        ScreenshotAnalyzer: {
            description: 'Analyzes dating app conversation screenshots using Grok Vision API',
            capabilities: ['image_analysis', 'conversation_stage_detection', 'personality_insights'],
            api_dependencies: ['grok_vision']
        },
        PersonalizationAgent: {
            description: 'Builds and maintains user personality profiles for personalized suggestions',
            capabilities: ['profile_building', 'preference_learning', 'interaction_tracking'],
            api_dependencies: []
        },
        FlirtGenerator: {
            description: 'Generates contextual flirt suggestions with multiple tones',
            capabilities: ['text_generation', 'tone_adaptation', 'context_awareness'],
            api_dependencies: ['grok']
        },
        VoiceSynthesisAgent: {
            description: 'Orchestrates voice generation with emotion-specific parameters',
            capabilities: ['voice_synthesis', 'emotion_modeling', 'quality_assessment'],
            api_dependencies: ['elevenlabs']
        },
        ConsentPrivacyAgent: {
            description: 'Manages GDPR/CCPA compliance and data retention policies',
            capabilities: ['consent_tracking', 'data_deletion', 'policy_compliance'],
            api_dependencies: []
        },
        SafetyFilter: {
            description: 'Provides comprehensive content moderation and safety filtering',
            capabilities: ['content_moderation', 'harassment_detection', 'age_filtering'],
            api_dependencies: []
        }
    },

    // Version information
    VERSION: '1.0.0',
    LAST_UPDATED: '2024-09-22'
};