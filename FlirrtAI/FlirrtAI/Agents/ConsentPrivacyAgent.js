/**
 * ConsentPrivacyAgent.js - AI Sub-Agent for GDPR/CCPA Compliance
 *
 * Manages consent tracking, data retention policies, and deletion workflows
 * to ensure compliance with privacy regulations across jurisdictions.
 */

class ConsentPrivacyAgent {
    constructor() {
        // Jurisdiction-specific consent requirements
        this.jurisdictionRules = {
            'EU': {
                name: 'European Union (GDPR)',
                requires_explicit_consent: true,
                allows_legitimate_interest: true,
                data_retention_max: 365 * 2, // 2 years default
                deletion_timeframe: 30, // Must respond within 30 days
                required_disclosures: [
                    'data_collection_purpose',
                    'data_sharing_parties',
                    'retention_period',
                    'user_rights',
                    'contact_information'
                ],
                consent_categories: [
                    'necessary', 'analytics', 'marketing', 'personalization', 'ai_training'
                ]
            },
            'US_CA': {
                name: 'California (CCPA)',
                requires_explicit_consent: false,
                allows_opt_out: true,
                data_retention_max: 365 * 1, // 1 year for non-essential
                deletion_timeframe: 45, // Must respond within 45 days
                required_disclosures: [
                    'categories_collected',
                    'business_purpose',
                    'third_parties',
                    'selling_disclosure',
                    'deletion_rights'
                ],
                consent_categories: [
                    'necessary', 'analytics', 'marketing', 'sale_of_data'
                ]
            },
            'US': {
                name: 'United States (General)',
                requires_explicit_consent: false,
                allows_opt_out: true,
                data_retention_max: 365 * 3, // 3 years
                deletion_timeframe: 60, // Best practice 60 days
                required_disclosures: [
                    'data_usage',
                    'third_party_sharing',
                    'user_choices'
                ],
                consent_categories: [
                    'necessary', 'analytics', 'marketing'
                ]
            },
            'GLOBAL': {
                name: 'Global Default',
                requires_explicit_consent: true,
                allows_opt_out: true,
                data_retention_max: 365, // 1 year conservative
                deletion_timeframe: 30, // Most restrictive
                required_disclosures: [
                    'data_collection_purpose',
                    'retention_period',
                    'user_rights'
                ],
                consent_categories: [
                    'necessary', 'analytics'
                ]
            }
        };

        // Data retention policies by data type
        this.retentionPolicies = {
            'user_profiles': {
                category: 'necessary',
                default_retention: 365 * 2, // 2 years
                deletion_cascade: ['user_preferences', 'interaction_history']
            },
            'conversation_screenshots': {
                category: 'analytics',
                default_retention: 30, // 30 days
                deletion_cascade: ['screenshot_analysis', 'conversation_insights']
            },
            'flirt_suggestions': {
                category: 'personalization',
                default_retention: 90, // 3 months
                deletion_cascade: ['suggestion_ratings', 'usage_analytics']
            },
            'voice_messages': {
                category: 'personalization',
                default_retention: 7, // 7 days
                deletion_cascade: ['voice_analysis', 'audio_files']
            },
            'interaction_analytics': {
                category: 'analytics',
                default_retention: 365, // 1 year
                deletion_cascade: []
            },
            'ai_training_data': {
                category: 'ai_training',
                default_retention: 365 * 5, // 5 years (anonymized)
                deletion_cascade: []
            },
            'marketing_data': {
                category: 'marketing',
                default_retention: 365, // 1 year
                deletion_cascade: ['campaign_analytics', 'user_segments']
            }
        };

        // Consent tracking storage
        this.consentRecords = new Map();
        this.deletionRequests = new Map();
        this.dataInventory = new Map();
    }

    /**
     * Track user consent for specific jurisdiction
     * @param {string} userId - User identifier
     * @param {Object} consentData - Consent details
     * @returns {Object} Consent tracking result
     */
    trackConsent(userId, consentData) {
        try {
            const jurisdiction = this.detectJurisdiction(consentData.userLocation, consentData.ipAddress);
            const rules = this.jurisdictionRules[jurisdiction] || this.jurisdictionRules.GLOBAL;

            // Validate consent data meets jurisdiction requirements
            const validation = this.validateConsentData(consentData, rules);
            if (!validation.valid) {
                return {
                    success: false,
                    error: 'Invalid consent data',
                    issues: validation.issues,
                    requirements: rules.required_disclosures
                };
            }

            // Create consent record
            const consentRecord = {
                userId,
                jurisdiction,
                timestamp: new Date().toISOString(),
                ipAddress: consentData.ipAddress,
                userAgent: consentData.userAgent,
                consent_version: consentData.consent_version || '1.0',

                // Consent preferences by category
                consents: this.processConsentPreferences(consentData.consents, rules),

                // Legal basis for processing
                legal_basis: this.determineLegalBasis(consentData.consents, rules),

                // Required disclosures
                disclosures_shown: consentData.disclosures_shown || [],

                // Expiration based on jurisdiction
                expires_at: this.calculateConsentExpiration(jurisdiction),

                // Audit trail
                consent_method: consentData.consent_method || 'web_form',
                consent_source: consentData.consent_source || 'registration',
                previous_consents: this.getPreviousConsents(userId)
            };

            // Store consent record
            this.consentRecords.set(`${userId}_${consentRecord.timestamp}`, consentRecord);

            // Update data retention schedules
            this.updateRetentionSchedules(userId, consentRecord.consents, jurisdiction);

            // Create data inventory entry
            this.createDataInventoryEntry(userId, consentRecord);

            return {
                success: true,
                consentId: `${userId}_${consentRecord.timestamp}`,
                jurisdiction,
                consents: consentRecord.consents,
                legal_basis: consentRecord.legal_basis,
                expires_at: consentRecord.expires_at,
                retention_schedules: this.getRetentionSchedules(userId)
            };

        } catch (error) {
            console.error('Consent tracking error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Process data deletion request
     * @param {string} userId - User identifier
     * @param {Object} deletionRequest - Deletion details
     * @returns {Promise<Object>} Deletion process result
     */
    async processDataDeletion(userId, deletionRequest) {
        try {
            const jurisdiction = this.detectJurisdiction(deletionRequest.userLocation);
            const rules = this.jurisdictionRules[jurisdiction] || this.jurisdictionRules.GLOBAL;

            // Validate deletion request
            const validation = this.validateDeletionRequest(userId, deletionRequest, rules);
            if (!validation.valid) {
                return {
                    success: false,
                    error: 'Invalid deletion request',
                    issues: validation.issues
                };
            }

            // Create deletion record
            const deletionId = `del_${userId}_${Date.now()}`;
            const deletionRecord = {
                deletionId,
                userId,
                jurisdiction,
                requested_at: new Date().toISOString(),
                request_method: deletionRequest.method || 'user_request',
                verification_status: 'pending',

                // Data scope
                deletion_scope: deletionRequest.scope || 'all_data',
                data_categories: deletionRequest.categories || Object.keys(this.retentionPolicies),

                // Legal compliance
                response_deadline: this.calculateResponseDeadline(jurisdiction),
                legal_holds: this.checkLegalHolds(userId),

                // Processing status
                status: 'initiated',
                completed_categories: [],
                failed_categories: [],

                // Audit trail
                verification_method: deletionRequest.verification_method,
                admin_notes: []
            };

            this.deletionRequests.set(deletionId, deletionRecord);

            // Begin deletion process
            const deletionResult = await this.executeDeletion(deletionRecord);

            return {
                success: true,
                deletionId,
                status: deletionResult.status,
                estimated_completion: deletionResult.estimated_completion,
                categories_processed: deletionResult.completed_categories,
                categories_failed: deletionResult.failed_categories,
                legal_holds: deletionResult.legal_holds,
                next_steps: deletionResult.next_steps
            };

        } catch (error) {
            console.error('Data deletion error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Execute data deletion across all systems
     * @param {Object} deletionRecord - Deletion record
     * @returns {Promise<Object>} Execution result
     */
    async executeDeletion(deletionRecord) {
        const results = {
            status: 'in_progress',
            completed_categories: [],
            failed_categories: [],
            legal_holds: deletionRecord.legal_holds,
            estimated_completion: new Date(Date.now() + (24 * 60 * 60 * 1000)).toISOString()
        };

        for (const category of deletionRecord.data_categories) {
            try {
                // Check if category has legal hold
                if (this.hasLegalHold(deletionRecord.userId, category)) {
                    results.failed_categories.push({
                        category,
                        reason: 'legal_hold',
                        details: 'Data subject to legal hold cannot be deleted'
                    });
                    continue;
                }

                // Execute deletion for this category
                const categoryResult = await this.deleteCategoryData(deletionRecord.userId, category);

                if (categoryResult.success) {
                    results.completed_categories.push({
                        category,
                        deleted_at: new Date().toISOString(),
                        records_deleted: categoryResult.records_deleted,
                        cascade_deletions: categoryResult.cascade_deletions
                    });
                } else {
                    results.failed_categories.push({
                        category,
                        reason: 'deletion_failed',
                        details: categoryResult.error
                    });
                }

            } catch (error) {
                results.failed_categories.push({
                    category,
                    reason: 'system_error',
                    details: error.message
                });
            }
        }

        // Update deletion record status
        if (results.failed_categories.length === 0) {
            results.status = 'completed';
            deletionRecord.status = 'completed';
            deletionRecord.completed_at = new Date().toISOString();
        } else if (results.completed_categories.length > 0) {
            results.status = 'partially_completed';
            deletionRecord.status = 'partially_completed';
        } else {
            results.status = 'failed';
            deletionRecord.status = 'failed';
        }

        // Set next steps
        results.next_steps = this.generateNextSteps(results);

        // Update deletion record
        this.deletionRequests.set(deletionRecord.deletionId, deletionRecord);

        return results;
    }

    /**
     * Delete data for specific category
     * @param {string} userId - User identifier
     * @param {string} category - Data category
     * @returns {Promise<Object>} Deletion result
     */
    async deleteCategoryData(userId, category) {
        const policy = this.retentionPolicies[category];
        if (!policy) {
            return { success: false, error: 'Unknown data category' };
        }

        try {
            let records_deleted = 0;
            let cascade_deletions = [];

            // Simulate data deletion - in production, this would call actual data services
            switch (category) {
                case 'user_profiles':
                    records_deleted += await this.deleteUserProfiles(userId);
                    break;
                case 'conversation_screenshots':
                    records_deleted += await this.deleteScreenshots(userId);
                    break;
                case 'flirt_suggestions':
                    records_deleted += await this.deleteFlirtSuggestions(userId);
                    break;
                case 'voice_messages':
                    records_deleted += await this.deleteVoiceMessages(userId);
                    break;
                case 'interaction_analytics':
                    records_deleted += await this.deleteAnalytics(userId);
                    break;
                case 'ai_training_data':
                    records_deleted += await this.anonymizeTrainingData(userId);
                    break;
                case 'marketing_data':
                    records_deleted += await this.deleteMarketingData(userId);
                    break;
            }

            // Handle cascade deletions
            for (const cascadeCategory of policy.deletion_cascade) {
                const cascadeResult = await this.deleteCategoryData(userId, cascadeCategory);
                if (cascadeResult.success) {
                    cascade_deletions.push({
                        category: cascadeCategory,
                        records_deleted: cascadeResult.records_deleted
                    });
                }
            }

            return {
                success: true,
                records_deleted,
                cascade_deletions
            };

        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Detect user's jurisdiction based on location data
     * @param {string} userLocation - User-provided location
     * @param {string} ipAddress - User's IP address
     * @returns {string} Jurisdiction code
     */
    detectJurisdiction(userLocation, ipAddress) {
        // In production, this would use IP geolocation and user-provided data
        if (userLocation) {
            const location = userLocation.toLowerCase();

            // EU countries
            if (this.isEUCountry(location)) {
                return 'EU';
            }

            // California
            if (location.includes('california') || location.includes('ca')) {
                return 'US_CA';
            }

            // Other US states
            if (this.isUSState(location)) {
                return 'US';
            }
        }

        // Default to most restrictive (GDPR-like)
        return 'GLOBAL';
    }

    /**
     * Check if location is in EU
     * @param {string} location - Location string
     * @returns {boolean} Is EU country
     */
    isEUCountry(location) {
        const euCountries = [
            'austria', 'belgium', 'bulgaria', 'croatia', 'cyprus', 'czech',
            'denmark', 'estonia', 'finland', 'france', 'germany', 'greece',
            'hungary', 'ireland', 'italy', 'latvia', 'lithuania', 'luxembourg',
            'malta', 'netherlands', 'poland', 'portugal', 'romania', 'slovakia',
            'slovenia', 'spain', 'sweden'
        ];

        return euCountries.some(country => location.includes(country));
    }

    /**
     * Check if location is in US
     * @param {string} location - Location string
     * @returns {boolean} Is US state
     */
    isUSState(location) {
        return location.includes('united states') || location.includes('usa') ||
               location.includes('america') || /\b[A-Z]{2}\b/.test(location);
    }

    /**
     * Validate consent data meets jurisdiction requirements
     * @param {Object} consentData - Consent data
     * @param {Object} rules - Jurisdiction rules
     * @returns {Object} Validation result
     */
    validateConsentData(consentData, rules) {
        const issues = [];

        // Check required disclosures
        if (rules.required_disclosures) {
            const missing = rules.required_disclosures.filter(disclosure =>
                !consentData.disclosures_shown?.includes(disclosure)
            );
            if (missing.length > 0) {
                issues.push(`Missing required disclosures: ${missing.join(', ')}`);
            }
        }

        // Check explicit consent requirement
        if (rules.requires_explicit_consent) {
            const nonEssentialConsents = Object.entries(consentData.consents || {})
                .filter(([category]) => category !== 'necessary');

            const missingExplicit = nonEssentialConsents.filter(([, consent]) =>
                !consent.granted || consent.method === 'implied'
            );

            if (missingExplicit.length > 0) {
                issues.push('Explicit consent required for non-essential categories');
            }
        }

        // Check consent version
        if (!consentData.consent_version) {
            issues.push('Consent version must be specified');
        }

        return {
            valid: issues.length === 0,
            issues
        };
    }

    /**
     * Process consent preferences according to jurisdiction rules
     * @param {Object} consents - Raw consent data
     * @param {Object} rules - Jurisdiction rules
     * @returns {Object} Processed consents
     */
    processConsentPreferences(consents, rules) {
        const processed = {};

        for (const category of rules.consent_categories) {
            const consent = consents[category] || {};

            processed[category] = {
                granted: consent.granted || false,
                timestamp: consent.timestamp || new Date().toISOString(),
                method: consent.method || 'explicit',
                legal_basis: this.determineCategoryLegalBasis(category, consent, rules),
                expires_at: this.calculateCategoryExpiration(category, rules)
            };
        }

        return processed;
    }

    /**
     * Determine legal basis for data processing
     * @param {Object} consents - Consent preferences
     * @param {Object} rules - Jurisdiction rules
     * @returns {Object} Legal basis mapping
     */
    determineLegalBasis(consents, rules) {
        const legalBasis = {};

        Object.entries(consents).forEach(([category, consent]) => {
            if (category === 'necessary') {
                legalBasis[category] = 'contract';
            } else if (consent.granted) {
                legalBasis[category] = 'consent';
            } else if (rules.allows_legitimate_interest && this.hasLegitimateInterest(category)) {
                legalBasis[category] = 'legitimate_interest';
            } else {
                legalBasis[category] = 'none';
            }
        });

        return legalBasis;
    }

    /**
     * Check if category has legitimate interest basis
     * @param {string} category - Data category
     * @returns {boolean} Has legitimate interest
     */
    hasLegitimateInterest(category) {
        const legitimateInterestCategories = ['analytics', 'security', 'fraud_prevention'];
        return legitimateInterestCategories.includes(category);
    }

    /**
     * Calculate consent expiration date
     * @param {string} jurisdiction - Jurisdiction code
     * @returns {string} Expiration date ISO string
     */
    calculateConsentExpiration(jurisdiction) {
        const rules = this.jurisdictionRules[jurisdiction];
        const maxRetention = rules?.data_retention_max || 365;

        return new Date(Date.now() + (maxRetention * 24 * 60 * 60 * 1000)).toISOString();
    }

    /**
     * Calculate category-specific consent expiration
     * @param {string} category - Data category
     * @param {Object} rules - Jurisdiction rules
     * @returns {string} Expiration date
     */
    calculateCategoryExpiration(category, rules) {
        const policy = this.retentionPolicies[category];
        const retention = Math.min(
            policy?.default_retention || 365,
            rules.data_retention_max || 365
        );

        return new Date(Date.now() + (retention * 24 * 60 * 60 * 1000)).toISOString();
    }

    /**
     * Update data retention schedules based on consent
     * @param {string} userId - User identifier
     * @param {Object} consents - User consents
     * @param {string} jurisdiction - Jurisdiction code
     */
    updateRetentionSchedules(userId, consents, jurisdiction) {
        const schedules = {};
        const rules = this.jurisdictionRules[jurisdiction];

        Object.entries(this.retentionPolicies).forEach(([dataType, policy]) => {
            const categoryConsent = consents[policy.category];

            if (categoryConsent?.granted) {
                schedules[dataType] = {
                    retention_days: Math.min(policy.default_retention, rules.data_retention_max),
                    delete_after: categoryConsent.expires_at,
                    legal_basis: categoryConsent.legal_basis,
                    last_updated: new Date().toISOString()
                };
            } else {
                schedules[dataType] = {
                    retention_days: 0,
                    delete_after: new Date().toISOString(),
                    legal_basis: 'none',
                    last_updated: new Date().toISOString()
                };
            }
        });

        this.dataInventory.set(userId, schedules);
    }

    /**
     * Get current retention schedules for user
     * @param {string} userId - User identifier
     * @returns {Object} Retention schedules
     */
    getRetentionSchedules(userId) {
        return this.dataInventory.get(userId) || {};
    }

    /**
     * Create data inventory entry
     * @param {string} userId - User identifier
     * @param {Object} consentRecord - Consent record
     */
    createDataInventoryEntry(userId, consentRecord) {
        const inventory = {
            userId,
            created_at: new Date().toISOString(),
            consent_record: consentRecord.timestamp,
            jurisdiction: consentRecord.jurisdiction,
            data_categories: {},
            last_updated: new Date().toISOString()
        };

        Object.entries(this.retentionPolicies).forEach(([dataType, policy]) => {
            const categoryConsent = consentRecord.consents[policy.category];

            inventory.data_categories[dataType] = {
                category: policy.category,
                consent_granted: categoryConsent?.granted || false,
                legal_basis: categoryConsent?.legal_basis || 'none',
                retention_period: policy.default_retention,
                deletion_scheduled: categoryConsent?.expires_at,
                cascade_dependencies: policy.deletion_cascade
            };
        });

        this.dataInventory.set(`inventory_${userId}`, inventory);
    }

    /**
     * Validate deletion request
     * @param {string} userId - User identifier
     * @param {Object} request - Deletion request
     * @param {Object} rules - Jurisdiction rules
     * @returns {Object} Validation result
     */
    validateDeletionRequest(userId, request, rules) {
        const issues = [];

        // Check if user exists
        if (!this.userExists(userId)) {
            issues.push('User not found');
        }

        // Check verification method
        if (!request.verification_method) {
            issues.push('Identity verification method required');
        }

        // Check scope validity
        if (request.scope && !['all_data', 'specific_categories'].includes(request.scope)) {
            issues.push('Invalid deletion scope');
        }

        return {
            valid: issues.length === 0,
            issues
        };
    }

    /**
     * Calculate response deadline for deletion request
     * @param {string} jurisdiction - Jurisdiction code
     * @returns {string} Deadline ISO string
     */
    calculateResponseDeadline(jurisdiction) {
        const rules = this.jurisdictionRules[jurisdiction];
        const days = rules?.deletion_timeframe || 30;

        return new Date(Date.now() + (days * 24 * 60 * 60 * 1000)).toISOString();
    }

    /**
     * Check for legal holds on user data
     * @param {string} userId - User identifier
     * @returns {Array} Legal holds
     */
    checkLegalHolds(userId) {
        // In production, this would check various legal hold systems
        return []; // No legal holds for demo
    }

    /**
     * Check if specific category has legal hold
     * @param {string} userId - User identifier
     * @param {string} category - Data category
     * @returns {boolean} Has legal hold
     */
    hasLegalHold(userId, category) {
        const holds = this.checkLegalHolds(userId);
        return holds.some(hold => hold.categories.includes(category));
    }

    /**
     * Generate next steps for deletion process
     * @param {Object} results - Deletion results
     * @returns {Array} Next steps
     */
    generateNextSteps(results) {
        const steps = [];

        if (results.failed_categories.length > 0) {
            steps.push('Review failed deletions and resolve issues');
        }

        if (results.legal_holds.length > 0) {
            steps.push('Monitor legal holds for release');
        }

        if (results.status === 'completed') {
            steps.push('User notification of completed deletion');
        }

        return steps;
    }

    /**
     * Get previous consents for user
     * @param {string} userId - User identifier
     * @returns {Array} Previous consent records
     */
    getPreviousConsents(userId) {
        const previous = [];

        for (const [key, record] of this.consentRecords.entries()) {
            if (record.userId === userId) {
                previous.push({
                    timestamp: record.timestamp,
                    consent_version: record.consent_version,
                    consents: record.consents
                });
            }
        }

        return previous.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    }

    /**
     * Check if user exists in system
     * @param {string} userId - User identifier
     * @returns {boolean} User exists
     */
    userExists(userId) {
        // In production, this would check user database
        return userId && userId.length > 0;
    }

    // Simulated deletion methods (in production, these would call actual services)

    async deleteUserProfiles(userId) {
        // Simulate profile deletion
        await this.delay(100);
        return 1; // Number of records deleted
    }

    async deleteScreenshots(userId) {
        await this.delay(50);
        return 3; // Simulated count
    }

    async deleteFlirtSuggestions(userId) {
        await this.delay(75);
        return 15; // Simulated count
    }

    async deleteVoiceMessages(userId) {
        await this.delay(200);
        return 5; // Simulated count
    }

    async deleteAnalytics(userId) {
        await this.delay(150);
        return 25; // Simulated count
    }

    async anonymizeTrainingData(userId) {
        await this.delay(300);
        return 10; // Simulated count (anonymized, not deleted)
    }

    async deleteMarketingData(userId) {
        await this.delay(100);
        return 8; // Simulated count
    }

    /**
     * Delay execution
     * @param {number} ms - Milliseconds to delay
     * @returns {Promise} Delay promise
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Get consent status for user
     * @param {string} userId - User identifier
     * @returns {Object} Current consent status
     */
    getConsentStatus(userId) {
        const userConsents = Array.from(this.consentRecords.values())
            .filter(record => record.userId === userId)
            .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        if (userConsents.length === 0) {
            return {
                hasConsent: false,
                message: 'No consent records found'
            };
        }

        const latestConsent = userConsents[0];
        const now = new Date();
        const expirationDate = new Date(latestConsent.expires_at);

        return {
            hasConsent: now < expirationDate,
            consentRecord: latestConsent,
            isExpired: now >= expirationDate,
            expiresAt: latestConsent.expires_at,
            jurisdiction: latestConsent.jurisdiction,
            consents: latestConsent.consents,
            legalBasis: latestConsent.legal_basis
        };
    }

    /**
     * Get deletion request status
     * @param {string} deletionId - Deletion request ID
     * @returns {Object} Deletion status
     */
    getDeletionStatus(deletionId) {
        const deletion = this.deletionRequests.get(deletionId);

        if (!deletion) {
            return {
                found: false,
                error: 'Deletion request not found'
            };
        }

        return {
            found: true,
            status: deletion.status,
            userId: deletion.userId,
            requestedAt: deletion.requested_at,
            responseDeadline: deletion.response_deadline,
            completedCategories: deletion.completed_categories,
            failedCategories: deletion.failed_categories,
            legalHolds: deletion.legal_holds
        };
    }

    /**
     * Get privacy compliance health status
     * @returns {Object} Health status
     */
    getHealthStatus() {
        return {
            status: 'healthy',
            consentRecords: this.consentRecords.size,
            activeDeletions: Array.from(this.deletionRequests.values())
                .filter(req => req.status === 'in_progress').length,
            dataInventoryEntries: this.dataInventory.size,
            jurisdictionsSupported: Object.keys(this.jurisdictionRules).length,
            retentionPolicies: Object.keys(this.retentionPolicies).length,
            lastChecked: new Date().toISOString()
        };
    }

    /**
     * Get supported jurisdictions
     * @returns {Array} Jurisdiction information
     */
    getSupportedJurisdictions() {
        return Object.entries(this.jurisdictionRules).map(([code, rules]) => ({
            code,
            name: rules.name,
            requiresExplicitConsent: rules.requires_explicit_consent,
            maxRetentionDays: rules.data_retention_max,
            deletionTimeframeDays: rules.deletion_timeframe,
            consentCategories: rules.consent_categories
        }));
    }

    /**
     * Get data categories and retention policies
     * @returns {Array} Data category information
     */
    getDataCategories() {
        return Object.entries(this.retentionPolicies).map(([category, policy]) => ({
            category,
            consentCategory: policy.category,
            defaultRetentionDays: policy.default_retention,
            cascadeDeletions: policy.deletion_cascade
        }));
    }
}

module.exports = ConsentPrivacyAgent;