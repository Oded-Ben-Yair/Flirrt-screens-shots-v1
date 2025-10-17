/**
 * API Retry Utilities
 * Provides retry logic with exponential backoff for external API calls
 */

const timeouts = require('../config/timeouts');

/**
 * Call Grok API with retry logic and exponential backoff
 * @param {Object} requestData - Request payload for Grok API
 * @param {Object} headers - Request headers
 * @param {number} timeout - Request timeout in milliseconds
 * @param {number} maxRetries - Maximum number of retry attempts (default 3)
 * @returns {Promise<Object>} API response data
 */
async function callGrokWithRetry(axios, url, requestData, headers, timeout, maxRetries = 3) {
    let lastError = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            console.log(`Grok API attempt ${attempt}/${maxRetries}...`);

            const response = await axios.post(url, requestData, {
                headers,
                timeout
            });

            // Success - log and return
            console.log(`Grok API attempt ${attempt} succeeded`);
            return response.data;

        } catch (error) {
            lastError = error;

            // Log detailed error information
            const errorDetails = {
                attempt,
                maxRetries,
                message: error.message,
                status: error.response?.status,
                statusText: error.response?.statusText,
                data: error.response?.data,
                code: error.code
            };

            console.error(`Grok API attempt ${attempt} failed:`, JSON.stringify(errorDetails, null, 2));

            // Don't retry on certain errors
            if (error.response) {
                const status = error.response.status;

                // Don't retry on client errors (except rate limiting)
                if (status >= 400 && status < 500 && status !== 429) {
                    console.error(`Grok API client error (${status}) - not retrying`);
                    throw error;
                }
            }

            // Last attempt - throw error
            if (attempt === maxRetries) {
                console.error(`Grok API all ${maxRetries} attempts failed`);
                throw error;
            }

            // Calculate exponential backoff delay
            const baseDelay = timeouts.retry.apiTimeoutInitial || 1000;
            const delay = baseDelay * Math.pow(2, attempt - 1);
            console.log(`Waiting ${delay}ms before retry ${attempt + 1}...`);

            // Wait before retry
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }

    // Should never reach here, but just in case
    throw lastError || new Error('Grok API call failed after retries');
}

/**
 * Call external API with retry logic
 * Generic retry wrapper for any API call
 * @param {Function} apiCall - Async function that makes the API call
 * @param {number} maxRetries - Maximum number of retry attempts (default 3)
 * @param {number} baseDelay - Base delay for exponential backoff in ms (default 1000)
 * @returns {Promise<any>} API call result
 */
async function callWithRetry(apiCall, maxRetries = 3, baseDelay = 1000) {
    let lastError = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            console.log(`API attempt ${attempt}/${maxRetries}...`);
            const result = await apiCall();
            console.log(`API attempt ${attempt} succeeded`);
            return result;

        } catch (error) {
            lastError = error;

            console.error(`API attempt ${attempt} failed:`, {
                message: error.message,
                status: error.response?.status,
                code: error.code
            });

            // Don't retry on client errors (except rate limiting)
            if (error.response?.status >= 400 && error.response?.status < 500 && error.response?.status !== 429) {
                console.error(`API client error (${error.response.status}) - not retrying`);
                throw error;
            }

            if (attempt === maxRetries) {
                console.error(`API all ${maxRetries} attempts failed`);
                throw error;
            }

            // Exponential backoff
            const delay = baseDelay * Math.pow(2, attempt - 1);
            console.log(`Waiting ${delay}ms before retry ${attempt + 1}...`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }

    throw lastError || new Error('API call failed after retries');
}

module.exports = {
    callGrokWithRetry,
    callWithRetry
};
