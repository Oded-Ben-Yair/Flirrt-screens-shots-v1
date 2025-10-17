// Jest setup file for Flirrt.ai Backend Tests
require('dotenv').config();

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.PORT = '0'; // Use random port for testing
process.env.DB_NAME = process.env.DB_NAME || 'flirrt_test';

// Mock external APIs to prevent real API calls during testing
const originalFetch = global.fetch;
global.fetch = jest.fn();

// Mock console methods to reduce noise during testing
const originalConsoleLog = console.log;
const originalConsoleWarn = console.warn;
const originalConsoleError = console.error;

// Only show important messages during tests
console.log = jest.fn((message) => {
    if (typeof message === 'string' && (
        message.includes('✅') ||
        message.includes('❌') ||
        message.includes('🧪') ||
        message.includes('Test')
    )) {
        originalConsoleLog(message);
    }
});

console.warn = jest.fn((message) => {
    if (typeof message === 'string' && message.includes('Test')) {
        originalConsoleWarn(message);
    }
});

console.error = jest.fn((message) => {
    if (typeof message === 'string' && message.includes('Test')) {
        originalConsoleError(message);
    }
});

// Global test timeout
jest.setTimeout(30000);

// Clean up after each test
afterEach(() => {
    jest.clearAllMocks();
});

// Restore original functions after all tests
afterAll(() => {
    global.fetch = originalFetch;
    console.log = originalConsoleLog;
    console.warn = originalConsoleWarn;
    console.error = originalConsoleError;
});

// Export test utilities
module.exports = {
    testPort: process.env.PORT || 3001,
    testDbName: process.env.DB_NAME || 'flirrt_test'
};