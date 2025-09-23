/**
 * SafetyFilter.js - AI Sub-Agent for Content Moderation
 *
 * Provides comprehensive content moderation including harassment detection,
 * age-appropriate filtering, and platform policy compliance.
 */

class SafetyFilter {
    constructor() {
        // Content safety categories and severity levels
        this.safetyCategories = {
            'harassment': {
                severity_levels: ['mild', 'moderate', 'severe'],
                threshold: 0.3,
                action: 'block',
                description: 'Bullying, intimidation, or hostile behavior'
            },
            'hate_speech': {
                severity_levels: ['mild', 'moderate', 'severe'],
                threshold: 0.2,
                action: 'block',
                description: 'Discriminatory language based on protected characteristics'
            },
            'sexual_content': {
                severity_levels: ['suggestive', 'explicit', 'graphic'],
                threshold: 0.4,
                action: 'flag',
                description: 'Sexual or adult content'
            },
            'violence': {
                severity_levels: ['mild', 'moderate', 'severe'],
                threshold: 0.3,
                action: 'block',
                description: 'Violent threats or graphic violence'
            },
            'spam': {
                severity_levels: ['promotional', 'repetitive', 'scam'],
                threshold: 0.5,
                action: 'flag',
                description: 'Unsolicited promotional or repetitive content'
            },
            'inappropriate_language': {
                severity_levels: ['mild', 'moderate', 'severe'],
                threshold: 0.6,
                action: 'warn',
                description: 'Profanity or inappropriate language'
            },
            'personal_info': {
                severity_levels: ['contact', 'sensitive', 'private'],
                threshold: 0.4,
                action: 'flag',
                description: 'Sharing of personal or contact information'
            },
            'self_harm': {
                severity_levels: ['ideation', 'planning', 'imminent'],
                threshold: 0.1,
                action: 'escalate',
                description: 'Self-harm or suicide-related content'
            }
        };

        // Age-appropriate content guidelines
        this.ageAppropriateGuidelines = {
            '13-17': {
                allowed_topics: ['school', 'hobbies', 'sports', 'music', 'movies', 'games'],
                restricted_topics: ['alcohol', 'dating_apps', 'mature_content'],
                max_sexual_content: 0.1,
                max_violence: 0.2,
                requires_guardian_mode: true
            },
            '18-20': {
                allowed_topics: ['college', 'career', 'travel', 'relationships', 'social'],
                restricted_topics: ['explicit_content'],
                max_sexual_content: 0.3,
                max_violence: 0.4,
                requires_guardian_mode: false
            },
            '21+': {
                allowed_topics: ['all'],
                restricted_topics: ['illegal_content'],
                max_sexual_content: 0.6,
                max_violence: 0.5,
                requires_guardian_mode: false
            }
        };

        // Platform policy rules
        this.platformPolicies = {
            'dating_apps': {
                prohibited: [
                    'financial_requests', 'immediate_meetups', 'contact_info_first_message',
                    'commercial_solicitation', 'fake_profiles', 'catfishing'
                ],
                encouraged: [
                    'genuine_conversation', 'respectful_communication', 'age_appropriate_content'
                ],
                special_rules: {
                    'first_message_restrictions': true,
                    'photo_verification_required': false,
                    'location_sharing_warnings': true
                }
            },
            'social_media': {
                prohibited: [
                    'doxxing', 'impersonation', 'coordinated_harassment', 'misinformation'
                ],
                encouraged: [
                    'authentic_interactions', 'community_guidelines_compliance'
                ],
                special_rules: {
                    'fact_checking_enabled': true,
                    'community_moderation': true
                }
            }
        };

        // Detection patterns and keywords
        this.detectionPatterns = {
            harassment: {
                keywords: [
                    'stupid', 'loser', 'pathetic', 'kill yourself', 'die', 'worthless',
                    'nobody likes you', 'go away', 'shut up', 'ugly', 'fat', 'disgusting'
                ],
                patterns: [
                    /you\s+(are|r)\s+(stupid|dumb|ugly|fat)/i,
                    /nobody\s+(likes|wants|cares)/i,
                    /go\s+(die|kill\s+yourself)/i,
                    /\b(loser|pathetic|worthless)\b/i
                ],
                context_patterns: [
                    'repeated_negative_comments',
                    'escalating_hostility',
                    'coordinated_attack'
                ]
            },
            hate_speech: {
                keywords: [
                    // Note: In production, this would be a more comprehensive, regularly updated list
                    'racial_slurs', 'homophobic_slurs', 'transphobic_language',
                    'religious_discrimination', 'ableist_language'
                ],
                patterns: [
                    /\b(hate|despise)\s+(all|every)\s+\w+/i,
                    /\w+\s+(should|need\s+to)\s+(die|disappear)/i
                ],
                protected_characteristics: [
                    'race', 'religion', 'gender', 'sexual_orientation',
                    'disability', 'age', 'nationality'
                ]
            },
            sexual_content: {
                keywords: [
                    'hookup', 'netflix and chill', 'dtf', 'nudes', 'send pics',
                    'come over', 'your place or mine', 'bedroom', 'sexy time'
                ],
                patterns: [
                    /\b(hook\s*up|hookup)\b/i,
                    /netflix\s+and\s+chill/i,
                    /\b(dtf|down\s+to\s+f)/i,
                    /send\s+(me\s+)?(nudes?|pics?)/i,
                    /(your|my)\s+place(\s+or\s+mine)?/i
                ],
                escalation_indicators: [
                    'immediate_physical_meeting',
                    'explicit_requests',
                    'persistent_after_rejection'
                ]
            },
            personal_info: {
                patterns: [
                    /\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/, // Phone numbers
                    /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, // Email
                    /\b\d{1,5}\s+[\w\s]+\s+(street|st|avenue|ave|road|rd|lane|ln|drive|dr|boulevard|blvd)/i, // Addresses
                    /\b(facebook|instagram|snapchat|twitter|tiktok)\s*:?\s*[@]?\w+/i, // Social media handles
                    /\bmeet\s+me\s+at\s+[\w\s]+/i // Specific meeting locations
                ],
                sensitivity_levels: {
                    'phone': 'high',
                    'email': 'medium',
                    'address': 'high',
                    'social_media': 'low',
                    'meeting_location': 'medium'
                }
            },
            spam: {
                patterns: [
                    /\b(buy|purchase|discount|sale|offer|deal)\b.*\b(now|today|limited|time)\b/i,
                    /\b(click|visit|check\s+out)\s+(my|this)\s+(link|website|profile)/i,
                    /\b(make\s+money|earn\s+cash|work\s+from\s+home)/i,
                    /(.)\1{4,}/, // Repeated characters
                    /\b(free|win|winner|congratulations)\b.*\b(prize|money|gift|card)/i
                ],
                repetition_threshold: 3,
                link_threshold: 2
            }
        };

        // Moderation actions
        this.moderationActions = {
            'allow': {
                severity: 0,
                description: 'Content is safe and appropriate',
                action_required: false
            },
            'warn': {
                severity: 1,
                description: 'Content may be inappropriate, user warning issued',
                action_required: true,
                user_message: 'Please keep conversations respectful and appropriate'
            },
            'flag': {
                severity: 2,
                description: 'Content flagged for human review',
                action_required: true,
                review_required: true
            },
            'block': {
                severity: 3,
                description: 'Content blocked from being sent',
                action_required: true,
                user_message: 'This message cannot be sent as it violates our community guidelines'
            },
            'escalate': {
                severity: 4,
                description: 'Content escalated to emergency response team',
                action_required: true,
                emergency_response: true
            }
        };

        // User behavior tracking
        this.userViolationHistory = new Map();
        this.moderationLog = new Map();
    }

    /**
     * Filter content for safety and appropriateness
     * @param {Object} content - Content to filter
     * @param {Object} context - Context information
     * @returns {Object} Filtering result
     */
    filterContent(content, context = {}) {
        try {
            // Validate input
            if (!content.text) {
                return this.createFilterResult('allow', 'No text content to filter');
            }

            // Analyze content for various safety issues
            const analysis = {
                harassment: this.detectHarassment(content.text, context),
                hate_speech: this.detectHateSpeech(content.text, context),
                sexual_content: this.detectSexualContent(content.text, context),
                violence: this.detectViolence(content.text, context),
                spam: this.detectSpam(content.text, context),
                inappropriate_language: this.detectInappropriateLanguage(content.text, context),
                personal_info: this.detectPersonalInfo(content.text, context),
                self_harm: this.detectSelfHarm(content.text, context)
            };

            // Check age appropriateness
            const ageCheck = this.checkAgeAppropriateness(content.text, context.userAge, analysis);

            // Check platform policy compliance
            const policyCheck = this.checkPlatformPolicies(content.text, context.platform, analysis);

            // Determine overall action
            const overallAction = this.determineOverallAction(analysis, ageCheck, policyCheck, context);

            // Update user violation history
            this.updateViolationHistory(context.userId, overallAction, analysis);

            // Log moderation decision
            this.logModerationDecision(content, context, analysis, overallAction);

            return this.createFilterResult(
                overallAction.action,
                overallAction.reason,
                analysis,
                ageCheck,
                policyCheck,
                overallAction
            );

        } catch (error) {
            console.error('Content filtering error:', error);
            return this.createFilterResult('flag', 'Error during content analysis', null, null, null, {
                error: error.message,
                action: 'flag'
            });
        }
    }

    /**
     * Detect harassment in content
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Harassment detection result
     */
    detectHarassment(text, context) {
        const patterns = this.detectionPatterns.harassment;
        let score = 0;
        const matches = [];

        // Check keywords
        patterns.keywords.forEach(keyword => {
            if (text.toLowerCase().includes(keyword.toLowerCase())) {
                score += 0.3;
                matches.push({ type: 'keyword', value: keyword });
            }
        });

        // Check regex patterns
        patterns.patterns.forEach(pattern => {
            if (pattern.test(text)) {
                score += 0.4;
                matches.push({ type: 'pattern', value: pattern.source });
            }
        });

        // Check context indicators
        if (context.isRepeatOffender) score += 0.2;
        if (context.conversationTone === 'hostile') score += 0.3;
        if (context.messageCount > 10 && context.responseRate < 0.3) score += 0.2; // Possible one-sided harassment

        const severity = this.calculateSeverity(score, [0.3, 0.6, 0.8]);

        return {
            detected: score > this.safetyCategories.harassment.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'harassment'
        };
    }

    /**
     * Detect hate speech in content
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Hate speech detection result
     */
    detectHateSpeech(text, context) {
        const patterns = this.detectionPatterns.hate_speech;
        let score = 0;
        const matches = [];

        // Check for protected characteristic targeting
        patterns.protected_characteristics.forEach(characteristic => {
            const characteristicPattern = new RegExp(`\\b(all|every|those)\\s+\\w*${characteristic}\\w*\\s+(are|should)`, 'i');
            if (characteristicPattern.test(text)) {
                score += 0.6;
                matches.push({ type: 'protected_characteristic', value: characteristic });
            }
        });

        // Check regex patterns
        patterns.patterns.forEach(pattern => {
            if (pattern.test(text)) {
                score += 0.5;
                matches.push({ type: 'pattern', value: pattern.source });
            }
        });

        // Context modifiers
        if (context.hasHistoryOfHateSpeech) score += 0.3;
        if (context.targetedUser) score += 0.2;

        const severity = this.calculateSeverity(score, [0.2, 0.5, 0.8]);

        return {
            detected: score > this.safetyCategories.hate_speech.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'hate_speech'
        };
    }

    /**
     * Detect sexual content in text
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Sexual content detection result
     */
    detectSexualContent(text, context) {
        const patterns = this.detectionPatterns.sexual_content;
        let score = 0;
        const matches = [];

        // Check keywords
        patterns.keywords.forEach(keyword => {
            if (text.toLowerCase().includes(keyword.toLowerCase())) {
                score += 0.4;
                matches.push({ type: 'keyword', value: keyword });
            }
        });

        // Check regex patterns
        patterns.patterns.forEach(pattern => {
            if (pattern.test(text)) {
                score += 0.5;
                matches.push({ type: 'pattern', value: pattern.source });
            }
        });

        // Context modifiers
        if (context.conversationStage === 'first_message') score += 0.3; // More serious in first message
        if (context.userAge && context.userAge < 18) score += 0.4; // More serious for minors
        if (context.rejectionCount > 0) score += 0.2; // Persistence after rejection

        const severity = this.calculateSeverity(score, [0.4, 0.7, 0.9]);

        return {
            detected: score > this.safetyCategories.sexual_content.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'sexual_content'
        };
    }

    /**
     * Detect violence-related content
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Violence detection result
     */
    detectViolence(text, context) {
        let score = 0;
        const matches = [];

        const violenceKeywords = [
            'kill', 'murder', 'hurt', 'beat', 'punch', 'stab', 'shoot',
            'violence', 'attack', 'fight', 'destroy', 'harm'
        ];

        const violencePatterns = [
            /\b(going\s+to|gonna|will)\s+(kill|hurt|beat|destroy)\b/i,
            /\b(violence|fight|attack)\s+(you|them|everyone)/i,
            /\bmake\s+(you|them)\s+(pay|suffer|hurt)/i
        ];

        // Check keywords
        violenceKeywords.forEach(keyword => {
            if (text.toLowerCase().includes(keyword)) {
                score += 0.3;
                matches.push({ type: 'keyword', value: keyword });
            }
        });

        // Check patterns
        violencePatterns.forEach(pattern => {
            if (pattern.test(text)) {
                score += 0.6;
                matches.push({ type: 'pattern', value: pattern.source });
            }
        });

        // Context modifiers
        if (context.isDirectThreat) score += 0.4;
        if (context.hasWeaponsContext) score += 0.3;

        const severity = this.calculateSeverity(score, [0.3, 0.6, 0.9]);

        return {
            detected: score > this.safetyCategories.violence.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'violence'
        };
    }

    /**
     * Detect spam content
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Spam detection result
     */
    detectSpam(text, context) {
        const patterns = this.detectionPatterns.spam;
        let score = 0;
        const matches = [];

        // Check spam patterns
        patterns.patterns.forEach(pattern => {
            if (pattern.test(text)) {
                score += 0.4;
                matches.push({ type: 'pattern', value: pattern.source });
            }
        });

        // Check for repetitive content
        if (context.recentMessages) {
            const repetitionCount = context.recentMessages.filter(msg =>
                this.calculateSimilarity(text, msg) > 0.8
            ).length;

            if (repetitionCount >= patterns.repetition_threshold) {
                score += 0.5;
                matches.push({ type: 'repetition', value: repetitionCount });
            }
        }

        // Check for excessive links
        const linkCount = (text.match(/https?:\/\/|www\./g) || []).length;
        if (linkCount >= patterns.link_threshold) {
            score += 0.3;
            matches.push({ type: 'excessive_links', value: linkCount });
        }

        const severity = this.calculateSeverity(score, [0.5, 0.7, 0.9]);

        return {
            detected: score > this.safetyCategories.spam.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'spam'
        };
    }

    /**
     * Detect inappropriate language
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Inappropriate language detection result
     */
    detectInappropriateLanguage(text, context) {
        let score = 0;
        const matches = [];

        // Basic profanity detection (simplified for demo)
        const profanityWords = [
            'damn', 'hell', 'crap', 'shit', 'fuck', 'ass', 'bitch', 'bastard'
        ];

        const mildProfanity = ['damn', 'hell', 'crap'];
        const moderateProfanity = ['shit', 'ass'];
        const severeProfanity = ['fuck', 'bitch', 'bastard'];

        profanityWords.forEach(word => {
            const regex = new RegExp(`\\b${word}\\b`, 'gi');
            const occurrences = (text.match(regex) || []).length;

            if (occurrences > 0) {
                let wordScore = 0;
                if (mildProfanity.includes(word)) wordScore = 0.2;
                else if (moderateProfanity.includes(word)) wordScore = 0.4;
                else if (severeProfanity.includes(word)) wordScore = 0.6;

                score += wordScore * occurrences;
                matches.push({ type: 'profanity', value: word, count: occurrences });
            }
        });

        // Context modifiers
        if (context.userAge && context.userAge < 18) score += 0.2;
        if (context.platform === 'family_friendly') score += 0.3;

        const severity = this.calculateSeverity(score, [0.6, 0.8, 1.0]);

        return {
            detected: score > this.safetyCategories.inappropriate_language.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'inappropriate_language'
        };
    }

    /**
     * Detect personal information sharing
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Personal info detection result
     */
    detectPersonalInfo(text, context) {
        const patterns = this.detectionPatterns.personal_info;
        let score = 0;
        const matches = [];

        // Check each pattern type
        patterns.patterns.forEach((pattern, index) => {
            const patternNames = ['phone', 'email', 'address', 'social_media', 'meeting_location'];
            const patternName = patternNames[index] || 'unknown';

            if (pattern.test(text)) {
                const sensitivity = patterns.sensitivity_levels[patternName] || 'medium';
                const patternScore = sensitivity === 'high' ? 0.6 : sensitivity === 'medium' ? 0.4 : 0.2;

                score += patternScore;
                matches.push({ type: 'personal_info', subtype: patternName, sensitivity });
            }
        });

        // Context modifiers
        if (context.conversationStage === 'first_message') score += 0.3;
        if (context.userAge && context.userAge < 18) score += 0.4;

        const severity = this.calculateSeverity(score, [0.4, 0.7, 0.9]);

        return {
            detected: score > this.safetyCategories.personal_info.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'personal_info'
        };
    }

    /**
     * Detect self-harm related content
     * @param {string} text - Text to analyze
     * @param {Object} context - Context information
     * @returns {Object} Self-harm detection result
     */
    detectSelfHarm(text, context) {
        let score = 0;
        const matches = [];

        const selfHarmKeywords = [
            'kill myself', 'suicide', 'end it all', 'not worth living',
            'hurt myself', 'self harm', 'cutting', 'overdose',
            'jump off', 'hang myself', 'want to die'
        ];

        const selfHarmPatterns = [
            /\b(want\s+to|going\s+to|gonna)\s+(die|kill\s+myself)\b/i,
            /\blife\s+(is\s+not|isn't)\s+worth\s+living\b/i,
            /\b(end|ending)\s+it\s+all\b/i,
            /\bno\s+point\s+in\s+living\b/i
        ];

        // Check keywords
        selfHarmKeywords.forEach(keyword => {
            if (text.toLowerCase().includes(keyword.toLowerCase())) {
                score += 0.8; // High score for self-harm indicators
                matches.push({ type: 'keyword', value: keyword });
            }
        });

        // Check patterns
        selfHarmPatterns.forEach(pattern => {
            if (pattern.test(text)) {
                score += 0.9;
                matches.push({ type: 'pattern', value: pattern.source });
            }
        });

        // Context modifiers
        if (context.hasDepressionHistory) score += 0.3;
        if (context.recentRejection) score += 0.2;

        const severity = this.calculateSeverity(score, [0.1, 0.5, 0.8]);

        return {
            detected: score > this.safetyCategories.self_harm.threshold,
            score: Math.min(1.0, score),
            severity,
            matches,
            category: 'self_harm',
            emergency: score > 0.7 // Flag for immediate intervention
        };
    }

    /**
     * Check age appropriateness of content
     * @param {string} text - Text to analyze
     * @param {number} userAge - User's age
     * @param {Object} analysis - Safety analysis results
     * @returns {Object} Age appropriateness result
     */
    checkAgeAppropriateness(text, userAge, analysis) {
        if (!userAge) {
            return { appropriate: true, reason: 'Age not specified' };
        }

        let ageGroup = '21+';
        if (userAge < 18) ageGroup = '13-17';
        else if (userAge < 21) ageGroup = '18-20';

        const guidelines = this.ageAppropriateGuidelines[ageGroup];

        // Check sexual content limits
        if (analysis.sexual_content.score > guidelines.max_sexual_content) {
            return {
                appropriate: false,
                reason: `Sexual content exceeds age-appropriate limits for ${ageGroup}`,
                ageGroup,
                violation: 'sexual_content'
            };
        }

        // Check violence limits
        if (analysis.violence.score > guidelines.max_violence) {
            return {
                appropriate: false,
                reason: `Violence content exceeds age-appropriate limits for ${ageGroup}`,
                ageGroup,
                violation: 'violence'
            };
        }

        // Check restricted topics
        const hasRestrictedTopic = guidelines.restricted_topics.some(topic => {
            const topicKeywords = this.getTopicKeywords(topic);
            return topicKeywords.some(keyword => text.toLowerCase().includes(keyword));
        });

        if (hasRestrictedTopic) {
            return {
                appropriate: false,
                reason: `Content contains age-restricted topics for ${ageGroup}`,
                ageGroup,
                violation: 'restricted_topic'
            };
        }

        return {
            appropriate: true,
            ageGroup,
            guidelines_applied: guidelines
        };
    }

    /**
     * Check platform policy compliance
     * @param {string} text - Text to analyze
     * @param {string} platform - Platform type
     * @param {Object} analysis - Safety analysis results
     * @returns {Object} Policy compliance result
     */
    checkPlatformPolicies(text, platform, analysis) {
        if (!platform || !this.platformPolicies[platform]) {
            return { compliant: true, reason: 'No specific platform policies' };
        }

        const policies = this.platformPolicies[platform];
        const violations = [];

        // Check prohibited behaviors
        policies.prohibited.forEach(prohibition => {
            if (this.checkProhibitionViolation(text, prohibition, analysis)) {
                violations.push({
                    type: 'prohibited_behavior',
                    violation: prohibition,
                    severity: 'high'
                });
            }
        });

        // Check special rules
        if (policies.special_rules) {
            const specialViolations = this.checkSpecialRules(text, policies.special_rules, analysis);
            violations.push(...specialViolations);
        }

        return {
            compliant: violations.length === 0,
            violations,
            platform,
            policies_checked: policies
        };
    }

    /**
     * Determine overall moderation action
     * @param {Object} analysis - Safety analysis results
     * @param {Object} ageCheck - Age appropriateness check
     * @param {Object} policyCheck - Platform policy check
     * @param {Object} context - Context information
     * @returns {Object} Overall action decision
     */
    determineOverallAction(analysis, ageCheck, policyCheck, context) {
        let highestSeverityAction = 'allow';
        let highestSeverityScore = 0;
        const reasons = [];

        // Check each safety category
        Object.values(analysis).forEach(categoryResult => {
            if (categoryResult.detected) {
                const categoryConfig = this.safetyCategories[categoryResult.category];
                const actionSeverity = this.moderationActions[categoryConfig.action].severity;

                if (actionSeverity > highestSeverityScore) {
                    highestSeverityScore = actionSeverity;
                    highestSeverityAction = categoryConfig.action;
                }

                reasons.push(`${categoryResult.category}: ${categoryResult.severity} (score: ${categoryResult.score.toFixed(2)})`);
            }
        });

        // Factor in age appropriateness
        if (!ageCheck.appropriate) {
            if (context.userAge < 18) {
                highestSeverityAction = 'block';
                highestSeverityScore = 3;
            } else {
                highestSeverityAction = this.escalateAction(highestSeverityAction);
            }
            reasons.push(`Age inappropriate: ${ageCheck.reason}`);
        }

        // Factor in platform policy violations
        if (!policyCheck.compliant) {
            const hasHighSeverityViolation = policyCheck.violations.some(v => v.severity === 'high');
            if (hasHighSeverityViolation) {
                highestSeverityAction = this.escalateAction(highestSeverityAction);
                reasons.push('High-severity platform policy violation');
            }
        }

        // Factor in user violation history
        const userHistory = this.getUserViolationHistory(context.userId);
        if (userHistory && userHistory.recentViolations > 3) {
            highestSeverityAction = this.escalateAction(highestSeverityAction);
            reasons.push('Repeat offender escalation');
        }

        return {
            action: highestSeverityAction,
            severity: highestSeverityScore,
            reason: reasons.join('; '),
            requires_review: highestSeverityAction === 'flag',
            requires_emergency: highestSeverityAction === 'escalate',
            user_message: this.moderationActions[highestSeverityAction].user_message
        };
    }

    /**
     * Calculate severity level from score
     * @param {number} score - Detection score
     * @param {Array} thresholds - Severity thresholds [mild, moderate, severe]
     * @returns {string} Severity level
     */
    calculateSeverity(score, thresholds) {
        if (score < thresholds[0]) return 'none';
        if (score < thresholds[1]) return 'mild';
        if (score < thresholds[2]) return 'moderate';
        return 'severe';
    }

    /**
     * Calculate text similarity
     * @param {string} text1 - First text
     * @param {string} text2 - Second text
     * @returns {number} Similarity score 0-1
     */
    calculateSimilarity(text1, text2) {
        // Simple similarity calculation - in production would use more sophisticated algorithm
        const words1 = text1.toLowerCase().split(/\s+/);
        const words2 = text2.toLowerCase().split(/\s+/);

        const intersection = words1.filter(word => words2.includes(word));
        const union = [...new Set([...words1, ...words2])];

        return intersection.length / union.length;
    }

    /**
     * Get keywords for topic detection
     * @param {string} topic - Topic name
     * @returns {Array} Keywords for topic
     */
    getTopicKeywords(topic) {
        const topicKeywords = {
            'alcohol': ['drink', 'beer', 'wine', 'cocktail', 'bar', 'drunk', 'alcohol'],
            'dating_apps': ['tinder', 'bumble', 'hinge', 'match', 'dating app'],
            'mature_content': ['adult', 'mature', 'nsfw', '18+', 'explicit'],
            'explicit_content': ['sex', 'porn', 'nude', 'naked', 'explicit'],
            'illegal_content': ['drugs', 'illegal', 'underage', 'minor', 'criminal']
        };

        return topicKeywords[topic] || [];
    }

    /**
     * Check for specific prohibition violations
     * @param {string} text - Text to check
     * @param {string} prohibition - Prohibition type
     * @param {Object} analysis - Analysis results
     * @returns {boolean} Is violation
     */
    checkProhibitionViolation(text, prohibition, analysis) {
        switch (prohibition) {
            case 'financial_requests':
                return /\b(money|cash|payment|venmo|paypal|cashapp)\b/i.test(text);
            case 'immediate_meetups':
                return /\b(meet|tonight|now|immediately|right now)\b/i.test(text);
            case 'contact_info_first_message':
                return analysis.personal_info.detected;
            case 'commercial_solicitation':
                return analysis.spam.detected;
            default:
                return false;
        }
    }

    /**
     * Check special platform rules
     * @param {string} text - Text to check
     * @param {Object} rules - Special rules
     * @param {Object} analysis - Analysis results
     * @returns {Array} Violations
     */
    checkSpecialRules(text, rules, analysis) {
        const violations = [];

        if (rules.first_message_restrictions && analysis.sexual_content.score > 0.2) {
            violations.push({
                type: 'special_rule',
                violation: 'inappropriate_first_message',
                severity: 'medium'
            });
        }

        if (rules.location_sharing_warnings && analysis.personal_info.matches.some(m => m.subtype === 'address')) {
            violations.push({
                type: 'special_rule',
                violation: 'location_sharing_detected',
                severity: 'low'
            });
        }

        return violations;
    }

    /**
     * Escalate moderation action to next severity level
     * @param {string} currentAction - Current action
     * @returns {string} Escalated action
     */
    escalateAction(currentAction) {
        const escalationMap = {
            'allow': 'warn',
            'warn': 'flag',
            'flag': 'block',
            'block': 'escalate',
            'escalate': 'escalate'
        };

        return escalationMap[currentAction] || currentAction;
    }

    /**
     * Update user violation history
     * @param {string} userId - User identifier
     * @param {Object} action - Moderation action
     * @param {Object} analysis - Analysis results
     */
    updateViolationHistory(userId, action, analysis) {
        if (!userId || action.action === 'allow') return;

        const history = this.userViolationHistory.get(userId) || {
            totalViolations: 0,
            recentViolations: 0,
            lastViolation: null,
            categories: {},
            escalationLevel: 0
        };

        history.totalViolations++;
        history.recentViolations++;
        history.lastViolation = new Date().toISOString();

        // Track violation categories
        Object.entries(analysis).forEach(([category, result]) => {
            if (result.detected) {
                history.categories[category] = (history.categories[category] || 0) + 1;
            }
        });

        // Calculate escalation level
        if (history.recentViolations > 5) history.escalationLevel = 2;
        else if (history.recentViolations > 2) history.escalationLevel = 1;

        this.userViolationHistory.set(userId, history);

        // Reset recent violations counter after 7 days (would be handled by cleanup job)
        // For demo purposes, we'll simulate this
        setTimeout(() => {
            const currentHistory = this.userViolationHistory.get(userId);
            if (currentHistory) {
                currentHistory.recentViolations = Math.max(0, currentHistory.recentViolations - 1);
                this.userViolationHistory.set(userId, currentHistory);
            }
        }, 7 * 24 * 60 * 60 * 1000); // 7 days
    }

    /**
     * Get user violation history
     * @param {string} userId - User identifier
     * @returns {Object} Violation history
     */
    getUserViolationHistory(userId) {
        return this.userViolationHistory.get(userId);
    }

    /**
     * Log moderation decision
     * @param {Object} content - Original content
     * @param {Object} context - Context information
     * @param {Object} analysis - Analysis results
     * @param {Object} action - Moderation action
     */
    logModerationDecision(content, context, analysis, action) {
        const logEntry = {
            timestamp: new Date().toISOString(),
            userId: context.userId,
            content: content.text,
            analysis,
            action: action.action,
            reason: action.reason,
            context,
            reviewRequired: action.requires_review,
            emergencyEscalation: action.requires_emergency
        };

        const logId = `log_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        this.moderationLog.set(logId, logEntry);

        // In production, this would be sent to logging service
        if (action.requires_emergency) {
            console.warn('EMERGENCY ESCALATION:', logEntry);
        }
    }

    /**
     * Create standardized filter result
     * @param {string} action - Moderation action
     * @param {string} reason - Reason for action
     * @param {Object} analysis - Analysis results
     * @param {Object} ageCheck - Age check results
     * @param {Object} policyCheck - Policy check results
     * @param {Object} overallAction - Overall action details
     * @returns {Object} Filter result
     */
    createFilterResult(action, reason, analysis, ageCheck, policyCheck, overallAction) {
        return {
            action,
            reason,
            allowed: action === 'allow',
            blocked: action === 'block',
            flagged: action === 'flag',
            warning: action === 'warn',
            emergency: action === 'escalate',

            // Detailed analysis
            safety_analysis: analysis,
            age_check: ageCheck,
            policy_check: policyCheck,
            overall_action: overallAction,

            // User feedback
            user_message: overallAction?.user_message,

            // Processing metadata
            processed_at: new Date().toISOString(),
            filter_version: '1.0',
            requires_human_review: action === 'flag' || action === 'escalate'
        };
    }

    /**
     * Get safety filter health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: 'healthy',
            categories_monitored: Object.keys(this.safetyCategories).length,
            active_users_tracked: this.userViolationHistory.size,
            moderation_logs: this.moderationLog.size,
            age_groups_supported: Object.keys(this.ageAppropriateGuidelines).length,
            platforms_supported: Object.keys(this.platformPolicies).length,
            last_checked: new Date().toISOString()
        };
    }

    /**
     * Get safety statistics
     * @returns {Object} Safety statistics
     */
    getSafetyStatistics() {
        const totalLogs = this.moderationLog.size;
        const actions = {};
        let emergencyCount = 0;

        for (const log of this.moderationLog.values()) {
            actions[log.action] = (actions[log.action] || 0) + 1;
            if (log.emergencyEscalation) emergencyCount++;
        }

        return {
            total_content_filtered: totalLogs,
            actions_taken: actions,
            emergency_escalations: emergencyCount,
            users_with_violations: this.userViolationHistory.size,
            safety_categories: Object.keys(this.safetyCategories),
            avg_processing_time: 'N/A' // Would be calculated from actual timing data
        };
    }

    /**
     * Get moderation guidelines for display
     * @returns {Object} Guidelines for users
     */
    getModerationGuidelines() {
        return {
            community_standards: {
                respect: 'Treat all users with respect and kindness',
                authenticity: 'Be genuine and honest in your interactions',
                safety: 'Keep conversations appropriate and safe for all ages',
                privacy: 'Protect your personal information and respect others\' privacy'
            },
            prohibited_content: Object.keys(this.safetyCategories).map(category => ({
                category,
                description: this.safetyCategories[category].description,
                consequences: this.safetyCategories[category].action
            })),
            reporting: {
                how_to_report: 'Use the report button or contact support',
                what_happens: 'All reports are reviewed by our moderation team',
                response_time: 'Most reports are reviewed within 24 hours'
            }
        };
    }
}

module.exports = SafetyFilter;