/**
 * Enhanced AI Orchestrator - Grok-4 Fast Integration
 *
 * Advanced AI pipeline orchestration with Grok-4 Fast optimization:
 * - Intelligent model selection (Grok-4 Fast vs legacy models)
 * - Dynamic load balancing across model types
 * - Smart fallback strategies with multiple tiers
 * - Performance-optimized request routing
 * - Real-time response caching and optimization
 * - Sub-second response targeting for simple requests
 */

const { logger } = require('./logger');
const circuitBreakerService = require('./circuitBreaker');
const grok4FastService = require('./grok4FastService');
const redisService = require('./redis');
const performanceOptimizer = require('./performanceOptimizer');
const streamingDeliveryService = require('./streamingDeliveryService');
const intelligentCacheService = require('./intelligentCacheService');
const advancedQualityAssurance = require('./advancedQualityAssurance');
const performanceMonitoringService = require('./performanceMonitoringService');

class EnhancedAIOrchestrator {
    constructor() {
        // Model hierarchy for intelligent selection
        this.modelHierarchy = {
            // Tier 1: Ultra-fast models for simple requests
            tier1: {
                primary: 'grok-4-fast-non-reasoning',
                target: 1000, // <1 second
                characteristics: ['simple', 'quick', 'keyboard'],
                fallback: 'grok-4-fast-reasoning'
            },

            // Tier 2: Balanced models for standard requests
            tier2: {
                primary: 'grok-4-fast-reasoning',
                target: 3000, // <3 seconds
                characteristics: ['standard', 'creative', 'balanced'],
                fallback: 'grok-beta'
            },

            // Tier 3: Comprehensive models for complex analysis
            tier3: {
                primary: 'gemini-vision + grok-4-fast-reasoning',
                target: 5000, // <5 seconds
                characteristics: ['complex', 'analysis', 'comprehensive'],
                fallback: 'legacy-dual-model'
            }
        };

        // Load balancing configuration
        this.loadBalancer = {
            maxConcurrentPerModel: 3,
            maxConcurrentTotal: 8,
            activeRequests: new Map(),
            queuedRequests: new Map()
        };

        // Performance tracking
        this.performanceMetrics = {
            requests: 0,
            tier1Usage: 0,
            tier2Usage: 0,
            tier3Usage: 0,
            averageLatencyByTier: { tier1: 0, tier2: 0, tier3: 0 },
            successRateByTier: { tier1: 0, tier2: 0, tier3: 0 },
            fallbackUsage: 0,
            cacheHits: 0,
            streamingRequests: 0
        };

        // Caching strategy
        this.cacheStrategy = {
            simple: { ttl: 3600, threshold: 0.8 },     // 1 hour for simple, high-confidence
            standard: { ttl: 1800, threshold: 0.75 },  // 30 min for standard
            complex: { ttl: 900, threshold: 0.85 },    // 15 min for complex, very high-confidence
            frequent: { ttl: 7200, threshold: 0.9 }    // 2 hours for frequent patterns
        };

        // Request classification patterns (enhanced)
        this.classificationEngine = {
            simple: {
                patterns: [
                    /^(hi|hello|hey|what's up|good morning|good evening)/i,
                    /opener|greeting|introduction/i,
                    /quick|short|brief|simple/i,
                    /keyboard|fast|immediate/i
                ],
                keywords: ['opener', 'greeting', 'quick', 'keyboard'],
                maxTokens: 200,
                priority: 'high'
            },

            standard: {
                patterns: [
                    /conversation|chat|flirt|playful/i,
                    /creative|witty|clever|fun/i,
                    /romantic|cute|sweet/i,
                    /personality|style|tone/i
                ],
                keywords: ['flirt', 'creative', 'romantic', 'personality'],
                maxTokens: 500,
                priority: 'medium'
            },

            complex: {
                patterns: [
                    /analyze|analysis|detailed|comprehensive/i,
                    /psychology|deep|thorough|sophisticated/i,
                    /conversation.*history|context.*analysis/i,
                    /profile.*analysis|personality.*assessment/i
                ],
                keywords: ['analyze', 'psychology', 'comprehensive', 'assessment'],
                maxTokens: 1000,
                priority: 'low'
            }
        };

        logger.info('Enhanced AI Orchestrator initialized', {
            tiers: Object.keys(this.modelHierarchy),
            loadBalancerEnabled: true,
            grok4FastIntegrated: true,
            performanceTargets: {
                tier1: this.modelHierarchy.tier1.target,
                tier2: this.modelHierarchy.tier2.target,
                tier3: this.modelHierarchy.tier3.target
            }
        });
    }

    /**
     * Main orchestration method with enhanced model selection
     * @param {Object} request - Request object
     * @param {Object} options - Orchestration options
     * @returns {Promise<Object>} Orchestrated response
     */
    async orchestrateOptimizedPipeline(request, options = {}) {
        const startTime = Date.now();
        const correlationId = request.correlationId || this.generateCorrelationId();

        try {
            // 1. Enhanced request classification
            const classification = await this.classifyRequestEnhanced(request);

            // 2. Intelligent tier selection
            const selectedTier = this.selectOptimalTier(classification, options);

            // 3. Load balancing check
            const loadBalanceResult = await this.checkLoadBalancing(selectedTier, correlationId);
            if (!loadBalanceResult.proceed) {
                return await this.handleQueuedRequest(request, options, correlationId, loadBalanceResult);
            }

            // 4. Intelligent cache check
            const cacheResult = await this.checkIntelligentCache(request, classification, selectedTier);
            if (cacheResult.hit && !options.bypassCache) {
                this.performanceMetrics.cacheHits++;
                return this.formatCacheResponse(cacheResult.data, correlationId, selectedTier);
            }

            // 5. Register active request for load balancing
            this.registerActiveRequest(correlationId, selectedTier);

            // 6. Execute optimized pipeline based on tier
            let result;
            switch (selectedTier.name) {
                case 'tier1':
                    result = await this.executeTier1Pipeline(request, classification, options, correlationId);
                    break;
                case 'tier2':
                    result = await this.executeTier2Pipeline(request, classification, options, correlationId);
                    break;
                case 'tier3':
                    result = await this.executeTier3Pipeline(request, classification, options, correlationId);
                    break;
                default:
                    throw new Error(`Unknown tier: ${selectedTier.name}`);
            }

            // 7. Advanced quality assurance and intelligent caching
            const qualityEvaluation = await advancedQualityAssurance.evaluateResponseQuality(
                result,
                request,
                selectedTier.name
            );

            // Attach quality evaluation to result
            result.qualityEvaluation = qualityEvaluation;
            result.qualityScore = qualityEvaluation.overallScore;

            // Cache result if it meets quality standards
            if (qualityEvaluation.passed) {
                await this.cacheIntelligentResult(request, result, classification, selectedTier.name);
            } else {
                logger.warn('Result not cached due to quality issues', {
                    correlationId,
                    qualityScore: qualityEvaluation.overallScore,
                    issues: qualityEvaluation.issues
                });
            }

            const totalLatency = Date.now() - startTime;

            // 8. Update metrics and cleanup
            this.updatePerformanceMetrics(startTime, selectedTier.name, true);
            this.unregisterActiveRequest(correlationId);

            // 9. Record comprehensive performance monitoring
            await performanceMonitoringService.recordPerformance({
                correlationId,
                strategy: selectedTier.name === 'tier1' ? 'keyboard' :
                         selectedTier.name === 'tier2' ? 'standard' :
                         selectedTier.name === 'tier3' ? 'comprehensive' : 'standard',
                latency: totalLatency,
                success: true,
                tier: selectedTier.name,
                qualityScore: qualityEvaluation.overallScore,
                streamingEnabled: !!options.streamCallback,
                cacheHit: false,
                bottlenecks: this.identifyBottlenecks(result, totalLatency, selectedTier)
            });

            logger.info('Enhanced orchestration completed successfully', {
                correlationId,
                tier: selectedTier.name,
                model: result.metadata?.model || selectedTier.primary,
                classification: classification.type,
                totalLatency: `${totalLatency}ms`,
                targetMet: totalLatency < selectedTier.target,
                cacheHit: false,
                qualityScore: result.qualityScore
            });

            return {
                success: true,
                data: result,
                metadata: {
                    correlationId,
                    tier: selectedTier.name,
                    classification: classification.type,
                    totalLatency,
                    targetLatency: selectedTier.target,
                    targetMet: totalLatency < selectedTier.target,
                    model: result.metadata?.model || selectedTier.primary,
                    version: 'enhanced-orchestrator-v2',
                    timestamp: new Date().toISOString()
                }
            };

        } catch (error) {
            this.updatePerformanceMetrics(startTime, 'error', false);
            this.unregisterActiveRequest(correlationId);

            logger.error('Enhanced orchestration failed', {
                correlationId,
                error: error.message,
                latency: Date.now() - startTime
            });

            // Multi-tier fallback strategy
            return await this.executeMultiTierFallback(request, options, correlationId, error);
        }
    }

    /**
     * Enhanced request classification with ML-style scoring
     * @param {Object} request - Request object
     * @returns {Promise<Object>} Enhanced classification
     */
    async classifyRequestEnhanced(request) {
        const context = (request.context || '').toLowerCase();
        const suggestionType = (request.suggestion_type || '').toLowerCase();
        const tone = (request.tone || '').toLowerCase();

        let scores = { simple: 0, standard: 0, complex: 0 };
        let characteristics = [];

        // Pattern matching with weighted scoring
        Object.entries(this.classificationEngine).forEach(([type, config]) => {
            // Pattern matching score
            const patternMatches = config.patterns.filter(pattern =>
                pattern.test(context) || pattern.test(suggestionType) || pattern.test(tone)
            ).length;
            scores[type] += patternMatches * 0.3;

            // Keyword matching score
            const keywordMatches = config.keywords.filter(keyword =>
                context.includes(keyword) || suggestionType.includes(keyword)
            ).length;
            scores[type] += keywordMatches * 0.2;
        });

        // Context complexity analysis
        const contextComplexity = this.analyzeContextComplexity(request);
        scores.complex += contextComplexity.score;
        characteristics.push(...contextComplexity.characteristics);

        // Special modifiers
        if (request.isKeyboardExtension) {
            scores.simple += 0.5;
            characteristics.push('keyboard_context');
        }

        if (request.imageData) {
            scores.complex += 0.4;
            characteristics.push('visual_context');
        }

        if (request.user_preferences && Object.keys(request.user_preferences).length > 0) {
            scores.standard += 0.2;
            characteristics.push('personalized');
        }

        // Determine primary classification
        const maxScore = Math.max(...Object.values(scores));
        const primaryType = Object.entries(scores).find(([_, score]) => score === maxScore)[0];

        // Secondary classification for hybrid approaches
        const sortedTypes = Object.entries(scores)
            .sort(([,a], [,b]) => b - a)
            .map(([type, score]) => ({ type, score }));

        return {
            primary: primaryType,
            secondary: sortedTypes[1]?.type,
            scores,
            confidence: maxScore / (maxScore + 0.1), // Normalized confidence
            characteristics,
            complexity: this.calculateComplexityScore(scores, characteristics),
            estimatedTokens: this.estimateTokenUsage(request),
            priority: this.classificationEngine[primaryType]?.priority || 'medium',
            timestamp: new Date().toISOString()
        };
    }

    /**
     * Analyze context complexity using multiple factors
     * @param {Object} request - Request object
     * @returns {Object} Complexity analysis
     */
    analyzeContextComplexity(request) {
        let score = 0;
        let characteristics = [];

        const context = request.context || '';

        // Length-based complexity
        if (context.length > 1000) {
            score += 0.3;
            characteristics.push('long_context');
        } else if (context.length > 500) {
            score += 0.2;
            characteristics.push('medium_context');
        }

        // Sentence complexity
        const sentences = context.split(/[.!?]+/).filter(s => s.trim().length > 0);
        if (sentences.length > 10) {
            score += 0.2;
            characteristics.push('multi_sentence');
        }

        // Conversation history indicators
        if (/previous|earlier|before|last time|conversation|chat history/i.test(context)) {
            score += 0.25;
            characteristics.push('conversation_history');
        }

        // Technical or sophisticated language
        const sophisticatedWords = ['sophisticated', 'intellectual', 'philosophical', 'psychological', 'analytical'];
        const sophisticatedMatches = sophisticatedWords.filter(word =>
            context.toLowerCase().includes(word)
        ).length;
        if (sophisticatedMatches > 0) {
            score += sophisticatedMatches * 0.1;
            characteristics.push('sophisticated_language');
        }

        return { score, characteristics };
    }

    /**
     * Select optimal tier based on classification and system state
     * @param {Object} classification - Enhanced classification
     * @param {Object} options - Request options
     * @returns {Object} Selected tier configuration
     */
    selectOptimalTier(classification, options) {
        // Force tier selection if specified
        if (options.forceTier) {
            return { name: options.forceTier, ...this.modelHierarchy[options.forceTier] };
        }

        // Intelligent tier selection based on classification
        let selectedTierName;

        if (classification.primary === 'simple' ||
            classification.characteristics.includes('keyboard_context') ||
            options.fastMode) {
            selectedTierName = 'tier1';
        } else if (classification.primary === 'complex' ||
                   classification.complexity > 0.7 ||
                   classification.characteristics.includes('visual_context')) {
            selectedTierName = 'tier3';
        } else {
            selectedTierName = 'tier2';
        }

        // Check system load and potentially downgrade tier for performance
        const currentLoad = this.getCurrentSystemLoad();
        if (currentLoad > 0.8 && selectedTierName === 'tier3') {
            selectedTierName = 'tier2';
            logger.info('Downgraded to tier2 due to high system load', {
                originalTier: 'tier3',
                systemLoad: currentLoad
            });
        }

        return { name: selectedTierName, ...this.modelHierarchy[selectedTierName] };
    }

    /**
     * Execute Tier 1 pipeline (Ultra-fast with Grok-4 Fast Non-Reasoning)
     * @param {Object} request - Request object
     * @param {Object} classification - Classification result
     * @param {Object} options - Pipeline options
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Pipeline result
     */
    async executeTier1Pipeline(request, classification, options, correlationId) {
        const startTime = Date.now();

        try {
            // Use Grok-4 Fast Non-Reasoning for maximum speed
            const result = await grok4FastService.generateFlirts(request, {
                forceModel: 'nonReasoning',
                streaming: false, // Don't stream for simple requests
                ...options,
                correlationId
            });

            const latency = Date.now() - startTime;
            this.performanceMetrics.tier1Usage++;

            // Update tier performance tracking
            this.updateTierPerformance('tier1', latency, true);

            logger.info('Tier 1 pipeline completed', {
                correlationId,
                model: 'grok-4-fast-non-reasoning',
                latency: `${latency}ms`,
                target: this.modelHierarchy.tier1.target,
                targetMet: latency < this.modelHierarchy.tier1.target
            });

            return {
                ...result.data,
                pipelineInfo: {
                    tier: 'tier1',
                    model: 'grok-4-fast-non-reasoning',
                    latency,
                    targetMet: latency < this.modelHierarchy.tier1.target
                }
            };

        } catch (error) {
            logger.warn('Tier 1 pipeline failed, attempting fallback', {
                correlationId,
                error: error.message
            });

            // Fallback to Tier 2
            return await this.executeTier2Pipeline(request, classification, options, correlationId);
        }
    }

    /**
     * Execute Tier 2 pipeline (Balanced with Grok-4 Fast Reasoning)
     * @param {Object} request - Request object
     * @param {Object} classification - Classification result
     * @param {Object} options - Pipeline options
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Pipeline result
     */
    async executeTier2Pipeline(request, classification, options, correlationId) {
        const startTime = Date.now();

        try {
            // Determine if streaming should be used
            const useStreaming = (classification.characteristics.includes('creative') ||
                                 classification.complexity > 0.6) &&
                                 request.userId &&
                                 !request.isKeyboardExtension;

            // Initialize streaming if enabled
            let streamHandle = null;
            if (useStreaming) {
                try {
                    streamHandle = await streamingDeliveryService.startSuggestionStream(
                        correlationId,
                        request.userId,
                        {
                            priority: 'medium',
                            estimatedSuggestions: 6,
                            fastMode: false
                        }
                    );
                } catch (streamError) {
                    logger.warn('Failed to initialize streaming, continuing without', {
                        correlationId,
                        error: streamError.message
                    });
                }
            }

            const result = await grok4FastService.generateFlirts(request, {
                forceModel: 'reasoning',
                streaming: useStreaming && streamHandle,
                streamCallback: streamHandle ? (suggestion) => {
                    streamHandle.sendChunk(suggestion);
                } : options.streamCallback,
                ...options,
                correlationId
            });

            const latency = Date.now() - startTime;
            this.performanceMetrics.tier2Usage++;

            // Complete streaming if active
            if (streamHandle && result.success) {
                try {
                    await streamHandle.complete(result.data);
                } catch (streamError) {
                    logger.warn('Error completing stream', {
                        correlationId,
                        error: streamError.message
                    });
                }
            } else if (streamHandle) {
                try {
                    await streamHandle.error(new Error('Pipeline failed'));
                } catch (streamError) {
                    logger.warn('Error handling stream failure', {
                        correlationId,
                        error: streamError.message
                    });
                }
            }

            // Update tier performance tracking
            this.updateTierPerformance('tier2', latency, true);

            // Cache result using intelligent cache
            if (result.success && result.data) {
                await this.cacheIntelligentResult(request, result.data, classification, 'tier2');
            }

            logger.info('Tier 2 pipeline completed', {
                correlationId,
                model: 'grok-4-fast-reasoning',
                streaming: useStreaming,
                latency: `${latency}ms`,
                target: this.modelHierarchy.tier2.target,
                targetMet: latency < this.modelHierarchy.tier2.target
            });

            return {
                ...result.data,
                pipelineInfo: {
                    tier: 'tier2',
                    model: 'grok-4-fast-reasoning',
                    streaming: useStreaming,
                    latency,
                    targetMet: latency < this.modelHierarchy.tier2.target
                }
            };

        } catch (error) {
            logger.warn('Tier 2 pipeline failed, attempting fallback', {
                correlationId,
                error: error.message
            });

            // Fallback to legacy Grok
            return await this.executeLegacyGrokFallback(request, classification, options, correlationId);
        }
    }

    /**
     * Execute Tier 3 pipeline (Comprehensive with Gemini + Grok-4 Fast)
     * @param {Object} request - Request object
     * @param {Object} classification - Classification result
     * @param {Object} options - Pipeline options
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Pipeline result
     */
    async executeTier3Pipeline(request, classification, options, correlationId) {
        const startTime = Date.now();

        try {
            // Step 1: Gemini Vision Analysis (if image provided)
            let analysisResult = null;
            if (request.imageData) {
                const geminiVisionService = require('./geminiVisionService');
                analysisResult = await geminiVisionService.analyzeImage(request.imageData, {
                    analysisType: 'comprehensive',
                    correlationId
                });
            }

            // Step 2: Enhanced context enrichment
            const enrichedContext = this.enrichContextForTier3(request, analysisResult, classification);

            // Step 3: Grok-4 Fast Reasoning with enriched context
            const result = await grok4FastService.generateFlirts(enrichedContext, {
                forceModel: 'reasoning',
                streaming: true, // Use streaming for complex requests
                streamCallback: options.streamCallback,
                ...options,
                correlationId
            });

            const latency = Date.now() - startTime;
            this.performanceMetrics.tier3Usage++;

            // Update tier performance tracking
            this.updateTierPerformance('tier3', latency, true);

            logger.info('Tier 3 pipeline completed', {
                correlationId,
                model: 'gemini-vision + grok-4-fast-reasoning',
                hadImageAnalysis: !!analysisResult,
                latency: `${latency}ms`,
                target: this.modelHierarchy.tier3.target,
                targetMet: latency < this.modelHierarchy.tier3.target
            });

            return {
                ...result.data,
                analysis: analysisResult?.analysis || null,
                pipelineInfo: {
                    tier: 'tier3',
                    model: 'gemini-vision + grok-4-fast-reasoning',
                    hadImageAnalysis: !!analysisResult,
                    latency,
                    targetMet: latency < this.modelHierarchy.tier3.target
                }
            };

        } catch (error) {
            logger.warn('Tier 3 pipeline failed, attempting fallback', {
                correlationId,
                error: error.message
            });

            // Fallback to legacy dual-model pipeline
            return await this.executeLegacyDualModelFallback(request, classification, options, correlationId);
        }
    }

    /**
     * Check load balancing and queue management
     * @param {Object} selectedTier - Selected tier
     * @param {string} correlationId - Correlation ID
     * @returns {Promise<Object>} Load balance result
     */
    async checkLoadBalancing(selectedTier, correlationId) {
        const activeTotal = this.loadBalancer.activeRequests.size;
        const activeForTier = Array.from(this.loadBalancer.activeRequests.values())
            .filter(req => req.tier === selectedTier.name).length;

        // Check if we can proceed immediately
        if (activeTotal < this.loadBalancer.maxConcurrentTotal &&
            activeForTier < this.loadBalancer.maxConcurrentPerModel) {
            return { proceed: true };
        }

        // Queue management logic
        logger.info('Request queued due to load balancing', {
            correlationId,
            tier: selectedTier.name,
            activeTotal,
            activeForTier,
            maxTotal: this.loadBalancer.maxConcurrentTotal,
            maxPerTier: this.loadBalancer.maxConcurrentPerModel
        });

        return {
            proceed: false,
            reason: 'load_balancing',
            queuePosition: this.getQueuePosition(selectedTier.name),
            estimatedWait: this.estimateWaitTime(selectedTier.name)
        };
    }

    /**
     * Intelligent caching with context awareness and semantic matching
     * @param {Object} request - Request object
     * @param {Object} classification - Classification result
     * @param {Object} selectedTier - Selected tier
     * @returns {Promise<Object>} Cache result
     */
    async checkIntelligentCache(request, classification, selectedTier) {
        try {
            // Generate cache key
            const cacheKey = this.generateTierSpecificCacheKey(request, classification, selectedTier);

            // Determine cache tier based on classification and request type
            let cacheTier = 'standard';
            if (request.isKeyboardExtension) {
                cacheTier = 'keyboard';
            } else if (classification.primary === 'complex' || request.imageData) {
                cacheTier = 'analysis';
            }

            // Use intelligent cache service
            const cached = await intelligentCacheService.getIntelligentCache(
                cacheKey,
                request,
                cacheTier
            );

            if (cached) {
                logger.debug('Intelligent cache hit', {
                    tier: selectedTier.name,
                    cacheTier,
                    classification: classification.primary,
                    type: cached.fromCache ? 'direct' : 'semantic'
                });
                return { hit: true, data: cached };
            }

            return { hit: false, data: null };

        } catch (error) {
            logger.warn('Intelligent cache check failed', { error: error.message });
            return { hit: false, data: null };
        }
    }

    /**
     * Multi-tier fallback strategy
     * @param {Object} request - Request object
     * @param {Object} options - Request options
     * @param {string} correlationId - Correlation ID
     * @param {Error} originalError - Original error
     * @returns {Promise<Object>} Fallback result
     */
    async executeMultiTierFallback(request, options, correlationId, originalError) {
        this.performanceMetrics.fallbackUsage++;

        logger.info('Executing multi-tier fallback strategy', {
            correlationId,
            originalError: originalError.message
        });

        const fallbackChain = [
            () => this.executeTier2Pipeline(request, { primary: 'standard' }, options, correlationId),
            () => this.executeTier1Pipeline(request, { primary: 'simple' }, options, correlationId),
            () => this.executeLegacyGrokFallback(request, { primary: 'standard' }, options, correlationId),
            () => this.executeEmergencyFallback(request, correlationId)
        ];

        for (let i = 0; i < fallbackChain.length; i++) {
            try {
                const result = await fallbackChain[i]();
                logger.info(`Fallback tier ${i + 1} succeeded`, { correlationId });

                return {
                    success: true,
                    data: {
                        ...result,
                        fallback: true,
                        fallbackTier: i + 1,
                        originalError: originalError.message
                    },
                    metadata: {
                        correlationId,
                        fallback: true,
                        fallbackTier: i + 1,
                        originalError: originalError.message
                    }
                };
            } catch (fallbackError) {
                logger.warn(`Fallback tier ${i + 1} failed`, {
                    correlationId,
                    error: fallbackError.message
                });
                continue;
            }
        }

        // All fallbacks failed
        logger.error('All fallback tiers failed', { correlationId });
        return this.executeEmergencyFallback(request, correlationId);
    }

    /**
     * Helper Methods
     */

    calculateComplexityScore(scores, characteristics) {
        const maxScore = Math.max(...Object.values(scores));
        const characteristicBonus = characteristics.length * 0.05;
        return Math.min(1.0, maxScore + characteristicBonus);
    }

    estimateTokenUsage(request) {
        let tokens = 0;
        if (request.context) tokens += Math.ceil(request.context.length / 4);
        if (request.user_preferences) tokens += Math.ceil(JSON.stringify(request.user_preferences).length / 4);
        if (request.imageData) tokens += 1000;
        return tokens + 300; // Base prompt tokens
    }

    getCurrentSystemLoad() {
        const activeRequests = this.loadBalancer.activeRequests.size;
        const maxRequests = this.loadBalancer.maxConcurrentTotal;
        return activeRequests / maxRequests;
    }

    registerActiveRequest(correlationId, tier) {
        this.loadBalancer.activeRequests.set(correlationId, {
            tier: tier.name,
            startTime: Date.now()
        });
    }

    unregisterActiveRequest(correlationId) {
        this.loadBalancer.activeRequests.delete(correlationId);
    }

    getQueuePosition(tierName) {
        const queuedForTier = this.loadBalancer.queuedRequests.get(tierName) || [];
        return queuedForTier.length + 1;
    }

    estimateWaitTime(tierName) {
        const activeForTier = Array.from(this.loadBalancer.activeRequests.values())
            .filter(req => req.tier === tierName);

        if (activeForTier.length === 0) return 0;

        const avgDuration = activeForTier.reduce((sum, req) =>
            sum + (Date.now() - req.startTime), 0) / activeForTier.length;

        return Math.max(1000, avgDuration * 0.5); // Estimate half remaining time
    }

    enrichContextForTier3(request, analysisResult, classification) {
        return {
            ...request,
            enhancedContext: {
                original: request.context,
                analysis: analysisResult?.analysis || null,
                classification: classification.primary,
                complexity: classification.complexity,
                characteristics: classification.characteristics
            },
            generationHints: {
                useReasoning: true,
                creativityLevel: classification.complexity,
                qualityTarget: 0.9
            }
        };
    }

    generateTierSpecificCacheKey(request, classification, tier) {
        const crypto = require('crypto');
        const keyData = {
            context: request.context,
            suggestion_type: request.suggestion_type,
            tone: request.tone,
            tier: tier.name,
            classification: classification.primary,
            hasImage: !!request.imageData
        };

        const hash = crypto.createHash('md5')
            .update(JSON.stringify(keyData))
            .digest('hex');

        return `enhanced_cache:${tier.name}:${hash}`;
    }

    async checkCrossTierCache(request, classification) {
        // Implementation for checking cache across different tiers
        // This allows reusing results from higher tiers for lower tier requests
        return { hit: false, data: null };
    }

    validateCacheForTier(cached, tier, classification) {
        const cacheAge = Date.now() - new Date(cached.timestamp).getTime();
        const strategy = this.cacheStrategy[classification.primary] || this.cacheStrategy.standard;

        return cacheAge < strategy.ttl * 1000 &&
               (cached.qualityScore || 0) >= strategy.threshold;
    }

    async cacheIntelligentResult(request, result, classification, tierName) {
        try {
            // Generate cache key
            const cacheKey = this.generateTierSpecificCacheKey(request, classification, { name: tierName });

            // Determine cache tier based on classification and request type
            let cacheTier = 'standard';
            if (request.isKeyboardExtension) {
                cacheTier = 'keyboard';
            } else if (classification.primary === 'complex' || request.imageData) {
                cacheTier = 'analysis';
            }

            // Use intelligent cache service with extended TTL for high-quality results
            const cacheOptions = {};
            if ((result.qualityScore || 0) > 0.9) {
                cacheOptions.extendedTTL = true;
            }

            const success = await intelligentCacheService.setIntelligentCache(
                cacheKey,
                request,
                result,
                cacheTier,
                cacheOptions
            );

            if (success) {
                logger.debug('Result cached intelligently', {
                    cacheKey,
                    cacheTier,
                    tierName,
                    quality: result.qualityScore || 0
                });
            }

        } catch (error) {
            logger.warn('Failed to cache intelligent result', { error: error.message });
        }
    }

    async performQualityAssurance(result, classification) {
        // Enhanced quality assurance logic
        if (result.suggestions && result.suggestions.length > 0) {
            result.qualityScore = result.qualityScore || 0.75;

            // Apply quality enhancements based on classification
            if (classification.primary === 'complex' && result.qualityScore < 0.8) {
                logger.warn('Complex request produced low quality result', {
                    classification: classification.primary,
                    qualityScore: result.qualityScore
                });
            }
        }
    }

    updateTierPerformance(tierName, latency, success) {
        const current = this.performanceMetrics.averageLatencyByTier[tierName] || 0;
        this.performanceMetrics.averageLatencyByTier[tierName] =
            current === 0 ? latency : (current * 0.9 + latency * 0.1);

        // Update success rate tracking
        const successKey = `${tierName}Successes`;
        const requestKey = `${tierName}Requests`;

        if (!this.performanceMetrics[successKey]) this.performanceMetrics[successKey] = 0;
        if (!this.performanceMetrics[requestKey]) this.performanceMetrics[requestKey] = 0;

        this.performanceMetrics[requestKey]++;
        if (success) this.performanceMetrics[successKey]++;

        this.performanceMetrics.successRateByTier[tierName] =
            this.performanceMetrics[successKey] / this.performanceMetrics[requestKey];
    }

    updatePerformanceMetrics(startTime, tier, success) {
        this.performanceMetrics.requests++;

        if (success) {
            const latency = Date.now() - startTime;
            this.updateTierPerformance(tier, latency, true);
        }
    }

    formatCacheResponse(cachedData, correlationId, tier) {
        return {
            success: true,
            data: {
                ...cachedData,
                fromCache: true,
                cacheRetrievedAt: new Date().toISOString()
            },
            metadata: {
                correlationId,
                cached: true,
                tier: tier.name,
                cacheAge: Date.now() - new Date(cachedData.timestamp).getTime(),
                version: 'enhanced-orchestrator-v2'
            }
        };
    }

    async executeLegacyGrokFallback(request, classification, options, correlationId) {
        // Fallback to original Grok service
        const payload = {
            model: 'grok-beta',
            messages: [{
                role: "user",
                content: `Generate dating conversation suggestions: ${request.context || 'general'}`
            }],
            max_tokens: 1000,
            temperature: 0.8
        };

        const response = await circuitBreakerService.callGrokApi(payload, correlationId);

        if (response.success) {
            return this.parseLegacyResponse(response.data, 'grok-beta');
        }

        throw new Error('Legacy Grok fallback failed');
    }

    async executeLegacyDualModelFallback(request, classification, options, correlationId) {
        // Fallback to original aiOrchestrator
        const aiOrchestrator = require('./aiOrchestrator');
        return await aiOrchestrator.orchestrateAIPipeline(request);
    }

    executeEmergencyFallback(request, correlationId) {
        const emergencySuggestions = [
            "Your profile really caught my attention - what's the story behind that smile?",
            "I have to ask... what's been the highlight of your week so far?",
            "Something tells me you have some interesting stories to share",
            "Your energy seems really genuine - that's refreshing to see",
            "I'm curious about your perspective on this - tell me more!"
        ];

        const suggestions = emergencySuggestions.slice(0, 3).map((text, index) => ({
            id: `emergency_${Date.now()}_${index}`,
            text,
            confidence: 0.6,
            reasoning: "Emergency fallback suggestion",
            tone: 'friendly',
            topics: ['general'],
            uniquenessScore: 0.5,
            engagementPotential: 0.7,
            characterCount: text.length,
            model: 'emergency-fallback',
            emergency: true
        }));

        return {
            success: true,
            data: {
                suggestions,
                metadata: { emergency: true },
                qualityScore: 0.6,
                pipelineInfo: {
                    tier: 'emergency',
                    model: 'emergency-fallback'
                }
            },
            metadata: {
                correlationId,
                emergency: true
            }
        };
    }

    parseLegacyResponse(response, model) {
        try {
            const content = response.choices[0].message.content;
            const suggestions = content.split('\n')
                .filter(line => line.trim().length > 0)
                .slice(0, 6)
                .map((text, index) => ({
                    id: `legacy_${Date.now()}_${index}`,
                    text: text.replace(/^\d+\.\s*/, '').trim(),
                    confidence: 0.7,
                    reasoning: `Generated by ${model}`,
                    tone: 'friendly',
                    topics: ['general'],
                    uniquenessScore: 0.6,
                    engagementPotential: 0.7,
                    characterCount: text.length,
                    model: `${model}-fallback`
                }));

            return {
                suggestions,
                metadata: { legacy: true },
                qualityScore: 0.65,
                pipelineInfo: {
                    tier: 'legacy',
                    model: `${model}-fallback`
                }
            };
        } catch (error) {
            throw new Error('Failed to parse legacy response');
        }
    }

    generateCorrelationId() {
        return `enh_orch_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * Identify performance bottlenecks for monitoring
     * @param {Object} result - Pipeline result
     * @param {number} latency - Total latency
     * @param {Object} selectedTier - Selected tier configuration
     * @returns {Array} List of bottlenecks
     */
    identifyBottlenecks(result, latency, selectedTier) {
        const bottlenecks = [];

        try {
            // High latency bottleneck
            if (latency > selectedTier.target * 1.5) {
                bottlenecks.push('excessive_latency');
            }

            // Quality processing bottleneck
            if (result.qualityScore && result.qualityScore < 0.7) {
                bottlenecks.push('quality_processing');
            }

            // Cache miss bottleneck (if result doesn't indicate cache hit)
            if (!result.fromCache && !result.cached) {
                bottlenecks.push('cache_miss');
            }

            // Model processing bottleneck
            if (result.pipelineInfo && result.pipelineInfo.latency > selectedTier.target * 0.8) {
                bottlenecks.push('model_processing');
            }

            // Sequential processing bottleneck (for tier 3)
            if (selectedTier.name === 'tier3' && latency > 20000) {
                bottlenecks.push('sequential_processing');
            }

            return bottlenecks;

        } catch (error) {
            logger.warn('Error identifying bottlenecks', { error: error.message });
            return ['bottleneck_analysis_error'];
        }
    }

    /**
     * Public API Methods
     */

    getHealthStatus() {
        return {
            status: 'healthy',
            version: 'enhanced-orchestrator-v2',
            tiers: this.modelHierarchy,
            loadBalancer: {
                activeRequests: this.loadBalancer.activeRequests.size,
                maxConcurrent: this.loadBalancer.maxConcurrentTotal
            },
            performance: this.performanceMetrics,
            grok4FastIntegrated: true,
            lastChecked: new Date().toISOString()
        };
    }

    getPerformanceReport() {
        const total = this.performanceMetrics.requests;

        return {
            overview: {
                totalRequests: total,
                cacheHitRate: total > 0 ? (this.performanceMetrics.cacheHits / total * 100).toFixed(2) + '%' : '0%',
                fallbackRate: total > 0 ? (this.performanceMetrics.fallbackUsage / total * 100).toFixed(2) + '%' : '0%'
            },
            tierPerformance: {
                tier1: {
                    usage: this.performanceMetrics.tier1Usage,
                    averageLatency: Math.round(this.performanceMetrics.averageLatencyByTier.tier1 || 0),
                    target: this.modelHierarchy.tier1.target,
                    successRate: (this.performanceMetrics.successRateByTier.tier1 * 100).toFixed(2) + '%'
                },
                tier2: {
                    usage: this.performanceMetrics.tier2Usage,
                    averageLatency: Math.round(this.performanceMetrics.averageLatencyByTier.tier2 || 0),
                    target: this.modelHierarchy.tier2.target,
                    successRate: (this.performanceMetrics.successRateByTier.tier2 * 100).toFixed(2) + '%'
                },
                tier3: {
                    usage: this.performanceMetrics.tier3Usage,
                    averageLatency: Math.round(this.performanceMetrics.averageLatencyByTier.tier3 || 0),
                    target: this.modelHierarchy.tier3.target,
                    successRate: (this.performanceMetrics.successRateByTier.tier3 * 100).toFixed(2) + '%'
                }
            },
            loadBalancing: {
                activeRequests: this.loadBalancer.activeRequests.size,
                utilizationRate: (this.getCurrentSystemLoad() * 100).toFixed(2) + '%'
            }
        };
    }

    resetMetrics() {
        this.performanceMetrics = {
            requests: 0,
            tier1Usage: 0,
            tier2Usage: 0,
            tier3Usage: 0,
            averageLatencyByTier: { tier1: 0, tier2: 0, tier3: 0 },
            successRateByTier: { tier1: 0, tier2: 0, tier3: 0 },
            fallbackUsage: 0,
            cacheHits: 0,
            streamingRequests: 0
        };

        this.loadBalancer.activeRequests.clear();
        this.loadBalancer.queuedRequests.clear();

        logger.info('Enhanced orchestrator metrics reset');
    }
}

// Export singleton instance
const enhancedAIOrchestrator = new EnhancedAIOrchestrator();
module.exports = enhancedAIOrchestrator;