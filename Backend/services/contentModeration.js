const OpenAI = require('openai');

/**
 * Content Moderation Service
 * CRITICAL: Required for App Store approval for dating apps
 *
 * Features:
 * - OpenAI Moderation API for text content
 * - GPT-5 Vision for image content
 * - Real-time suggestion filtering
 * - Pattern-based heuristics for additional safety
 */
class ContentModerationService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY || process.env.NEW_GROK_API_KEY
    });

    // Moderation thresholds
    this.thresholds = {
      violence: 0.5,
      sexual: 0.5,
      hate: 0.3,
      harassment: 0.4,
      selfHarm: 0.5
    };
  }

  /**
   * Moderate text content using OpenAI Moderation API
   * @param {string} text - Text to moderate
   * @returns {Promise<Object>} Moderation result
   */
  async moderateText(text) {
    try {
      const response = await this.openai.moderations.create({
        input: text,
      });

      const result = response.results[0];

      return {
        flagged: result.flagged,
        categories: result.categories,
        categoryScores: result.category_scores,
        safe: !result.flagged,
        details: this.getModerationDetails(result)
      };

    } catch (error) {
      console.error('❌ Moderation error:', error.message);
      // Fail-safe: if moderation fails, flag for manual review
      return {
        flagged: true,
        safe: false,
        error: true,
        reason: 'Moderation service unavailable'
      };
    }
  }

  /**
   * Moderate image content using GPT-5 Vision
   * @param {string} imageUrl - URL of image to moderate
   * @returns {Promise<Object>} Moderation result
   */
  async moderateImage(imageUrl) {
    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4-vision-preview',
        messages: [
          {
            role: 'system',
            content: 'You are a content moderation system. Analyze images for inappropriate content including explicit nudity, violence, hate symbols, harassment, or other policy violations. Respond with JSON only.'
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'Analyze this image for inappropriate content. Return JSON: {"flagged": true/false, "reason": "explanation", "categories": ["category1", "category2"]}'
              },
              {
                type: 'image_url',
                image_url: { url: imageUrl }
              }
            ]
          }
        ],
        max_tokens: 300
      });

      const analysis = JSON.parse(response.choices[0].message.content);

      return {
        flagged: analysis.flagged,
        reason: analysis.reason,
        categories: analysis.categories || [],
        safe: !analysis.flagged
      };

    } catch (error) {
      console.error('❌ Image moderation error:', error.message);
      return {
        flagged: true,
        safe: false,
        error: true,
        reason: 'Image moderation unavailable'
      };
    }
  }

  /**
   * Check if AI-generated suggestion should be blocked
   * @param {string} suggestion - Suggestion text
   * @returns {Promise<boolean>} True if should be blocked
   */
  async shouldBlockSuggestion(suggestion) {
    // Check with OpenAI Moderation API
    const moderation = await this.moderateText(suggestion);

    if (moderation.flagged) {
      console.log(`🚫 Suggestion blocked by moderation: ${suggestion.substring(0, 50)}...`);
      return true;
    }

    // Additional heuristics
    if (this.containsExplicitContent(suggestion)) {
      console.log(`🚫 Suggestion blocked by heuristics: ${suggestion.substring(0, 50)}...`);
      return true;
    }

    if (this.detectsPressure(suggestion)) {
      console.log(`🚫 Suggestion blocked (pressure detected): ${suggestion.substring(0, 50)}...`);
      return true;
    }

    return false;
  }

  /**
   * Pattern-based detection for explicit content
   * @param {string} text - Text to check
   * @returns {boolean} True if explicit content detected
   */
  containsExplicitContent(text) {
    const explicitPatterns = [
      /\b(explicit|sexual|nude|naked)\b/i,
      /\b(send\s+nudes?|dick\s+pic|sex\s+chat)\b/i,
      /\b(hook\s*up|one\s+night\s+stand)\b/i,
      // Add more patterns as needed
    ];

    return explicitPatterns.some(pattern => pattern.test(text));
  }

  /**
   * Detect pressuring language
   * @param {string} text - Text to check
   * @returns {boolean} True if pressure detected
   */
  detectsPressure(text) {
    const pressurePatterns = [
      /you\s+(should|must|have\s+to|need\s+to)\b/i,
      /don'?t\s+be\s+(shy|scared|afraid|boring)\b/i,
      /come\s+on\b/i,
      /what'?s\s+wrong\s+with\s+you/i,
      // Add more patterns as needed
    ];

    return pressurePatterns.some(pattern => pattern.test(text));
  }

  /**
   * Filter suggestions through moderation
   * @param {Array} suggestions - Array of suggestion objects
   * @returns {Promise<Array>} Filtered safe suggestions
   */
  async filterSuggestions(suggestions) {
    const safeSuggestions = [];

    for (const suggestion of suggestions) {
      const shouldBlock = await this.shouldBlockSuggestion(suggestion.text);

      if (!shouldBlock) {
        safeSuggestions.push(suggestion);
      }
    }

    console.log(`✅ Filtered suggestions: ${suggestions.length} → ${safeSuggestions.length} (blocked ${suggestions.length - safeSuggestions.length})`);

    return safeSuggestions;
  }

  /**
   * Get detailed moderation information
   * @param {Object} result - OpenAI moderation result
   * @returns {Object} Detailed information
   */
  getModerationDetails(result) {
    const flaggedCategories = [];

    if (result.categories.sexual) flaggedCategories.push('sexual');
    if (result.categories.hate) flaggedCategories.push('hate');
    if (result.categories.harassment) flaggedCategories.push('harassment');
    if (result.categories.violence) flaggedCategories.push('violence');
    if (result.categories['self-harm']) flaggedCategories.push('self-harm');

    return {
      flaggedCategories,
      highestScore: Math.max(...Object.values(result.category_scores)),
      recommendation: result.flagged ? 'Block content' : 'Allow content'
    };
  }

  /**
   * Report inappropriate content (for user reporting feature)
   * @param {Object} report - Report details
   * @returns {Promise<Object>} Report result
   */
  async reportContent(report) {
    const { reporterId, contentType, contentId, reason, description } = report;

    // Log report for manual review
    console.log('📝 Content report received:', {
      reporterId,
      contentType,
      contentId,
      reason,
      description: description?.substring(0, 100)
    });

    // TODO: Store in database for manual review
    // await Report.create({ reporterId, contentType, contentId, reason, description, status: 'pending' });

    return {
      success: true,
      message: 'Report submitted for review',
      reportId: `report_${Date.now()}`
    };
  }
}

module.exports = new ContentModerationService();
