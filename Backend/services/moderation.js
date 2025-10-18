/**
 * Content Moderation Service
 * Simple moderation for flirt suggestions
 */

class ModerationService {
    /**
     * Moderate text content
     * @param {string} text - Text to moderate
     * @returns {Promise<Object>} Moderation result
     */
    async moderateText(text) {
        // Simple keyword-based moderation
        const inappropriateKeywords = [
            'explicit_word_1',  // Add actual inappropriate words as needed
            'explicit_word_2'
        ];

        const lowerText = text.toLowerCase();
        const flagged = inappropriateKeywords.some(keyword => 
            lowerText.includes(keyword)
        );

        return {
            flagged,
            categories: flagged ? ['inappropriate'] : [],
            text
        };
    }
}

module.exports = new ModerationService();

