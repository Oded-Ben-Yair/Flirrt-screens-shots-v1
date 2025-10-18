import XCTest
import Foundation
import UIKit
@testable import Vibe8

/// Comprehensive API Client Tests for Vibe8.ai Backend Integration
/// Tests all API endpoints, authentication, error handling, and network conditions
class APIClientTests: XCTestCase {

    var apiClient: APIClient!
    var mockSession: MockURLSession!
    var testServerURL: String!

    override func setUp() {
        super.setUp()
        testServerURL = "http://localhost:3000"
        mockSession = MockURLSession()
        apiClient = APIClient(baseURL: testServerURL)
        apiClient.urlSession = mockSession
    }

    override func tearDown() {
        apiClient = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Authentication Tests

    func testAuthenticationTokenStorage() {
        let testToken = "test-jwt-token-123"
        apiClient.setAuthToken(testToken)

        XCTAssertEqual(apiClient.authToken, testToken, "Auth token should be stored correctly")
    }

    func testAuthenticationHeaderIncluded() {
        let testToken = "bearer-token-xyz"
        apiClient.setAuthToken(testToken)

        let expectation = self.expectation(description: "API call with auth header")

        apiClient.generateFlirts(screenshotId: "test-screenshot", context: "test") { result in
            switch result {
            case .success, .failure:
                // Check that Authorization header was included
                if let lastRequest = self.mockSession.lastRequest {
                    let authHeader = lastRequest.value(forHTTPHeaderField: "Authorization")
                    XCTAssertEqual(authHeader, "Bearer \(testToken)", "Authorization header should be included with Bearer token")
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Generate Flirts API Tests

    func testGenerateFlirtsSuccess() {
        let expectation = self.expectation(description: "Generate flirts should succeed")

        // Mock successful response
        mockSession.mockResponse = APIResponse.generateFlirtsSuccess()

        apiClient.generateFlirts(screenshotId: "test-123", context: "dating app screenshot") { result in
            switch result {
            case .success(let response):
                XCTAssertTrue(response.success, "Response should indicate success")
                XCTAssertNotNil(response.data, "Response should contain data")
                XCTAssertGreaterThan(response.data?.suggestions.count ?? 0, 0, "Should contain suggestions")

                // Verify first suggestion structure
                if let firstSuggestion = response.data?.suggestions.first {
                    XCTAssertFalse(firstSuggestion.text.isEmpty, "Suggestion text should not be empty")
                    XCTAssertGreaterThan(firstSuggestion.confidence, 0.0, "Confidence should be greater than 0")
                    XCTAssertLessThanOrEqual(firstSuggestion.confidence, 1.0, "Confidence should not exceed 1")
                }

            case .failure(let error):
                XCTFail("Generate flirts should succeed but failed with: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }

    func testGenerateFlirtsFallbackResponse() {
        let expectation = self.expectation(description: "Should handle fallback response")

        // Mock fallback response (when Grok API fails)
        mockSession.mockResponse = APIResponse.generateFlirtsFallback()

        apiClient.generateFlirts(screenshotId: "test-fallback", context: "test") { result in
            switch result {
            case .success(let response):
                XCTAssertTrue(response.success, "Fallback response should still indicate success")
                XCTAssertTrue(response.metadata?.fallback == true, "Should indicate fallback was used")
                XCTAssertGreaterThan(response.suggestions.count, 0, "Should contain fallback suggestions")

            case .failure(let error):
                XCTFail("Fallback response should succeed but failed with: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }

    func testGenerateFlirtsWithToneAndType() {
        let expectation = self.expectation(description: "Should handle tone and type parameters")

        mockSession.mockResponse = APIResponse.generateFlirtsSuccess()

        apiClient.generateFlirts(
            screenshotId: "test-params",
            context: "conversation response",
            suggestionType: "response",
            tone: "witty"
        ) { result in
            // Verify request was made with correct parameters
            if let lastRequest = self.mockSession.lastRequest,
               let httpBody = lastRequest.httpBody,
               let bodyDict = try? JSONSerialization.jsonObject(with: httpBody) as? [String: Any] {

                XCTAssertEqual(bodyDict["suggestion_type"] as? String, "response", "Request should include suggestion type")
                XCTAssertEqual(bodyDict["tone"] as? String, "witty", "Request should include tone")
                XCTAssertEqual(bodyDict["context"] as? String, "conversation response", "Request should include context")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testGenerateFlirtsNetworkError() {
        let expectation = self.expectation(description: "Should handle network errors")

        // Mock network error
        mockSession.shouldReturnError = true
        mockSession.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])

        apiClient.generateFlirts(screenshotId: "test-error", context: "test") { result in
            switch result {
            case .success:
                XCTFail("Should fail with network error")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("network") || error.localizedDescription.contains("internet"), "Error should indicate network issue")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testGenerateFlirtsInvalidJSON() {
        let expectation = self.expectation(description: "Should handle invalid JSON response")

        // Mock invalid JSON response
        mockSession.mockResponseData = "Invalid JSON Response".data(using: .utf8)

        apiClient.generateFlirts(screenshotId: "test-json", context: "test") { result in
            switch result {
            case .success:
                XCTFail("Should fail with invalid JSON")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("JSON") || error.localizedDescription.contains("parse"), "Error should indicate JSON parsing issue")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testGenerateFlirtsTimeout() {
        let expectation = self.expectation(description: "Should handle timeout")

        // Mock timeout error
        mockSession.shouldReturnError = true
        mockSession.mockError = NSError(domain: "NSURLErrorDomain", code: NSURLErrorTimedOut, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])

        apiClient.generateFlirts(screenshotId: "test-timeout", context: "test") { result in
            switch result {
            case .success:
                XCTFail("Should fail with timeout")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, NSURLErrorTimedOut, "Should return timeout error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Screenshot Analysis API Tests

    func testUploadScreenshotSuccess() {
        let expectation = self.expectation(description: "Screenshot upload should succeed")

        // Create test image data
        let testImage = UIImage(systemName: "photo")!
        let testImageData = testImage.jpegData(compressionQuality: 0.8)!

        // Mock successful upload response
        mockSession.mockResponse = APIResponse.screenshotUploadSuccess()

        apiClient.uploadScreenshot(imageData: testImageData, context: "dating_app") { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response.screenshotId, "Response should contain screenshot ID")
                XCTAssertFalse(response.screenshotId.isEmpty, "Screenshot ID should not be empty")

            case .failure(let error):
                XCTFail("Screenshot upload should succeed but failed with: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testUploadScreenshotWithLargeImage() {
        let expectation = self.expectation(description: "Should handle large image upload")

        // Create larger test image
        let testImage = createTestImage(size: CGSize(width: 1920, height: 1080))
        let testImageData = testImage.jpegData(compressionQuality: 0.8)!

        mockSession.mockResponse = APIResponse.screenshotUploadSuccess()

        apiClient.uploadScreenshot(imageData: testImageData, context: "large_screenshot") { result in
            switch result {
            case .success:
                // Verify image was compressed/processed appropriately
                if let lastRequest = self.mockSession.lastRequest {
                    XCTAssertNotNil(lastRequest.httpBody, "Request should contain image data")
                    XCTAssertGreaterThan(lastRequest.httpBody?.count ?? 0, 0, "Request body should not be empty")
                }

            case .failure(let error):
                XCTFail("Large image upload should succeed but failed with: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0) // Longer timeout for large uploads
    }

    // MARK: - Flirt History API Tests

    func testGetFlirtHistorySuccess() {
        let expectation = self.expectation(description: "Get flirt history should succeed")

        mockSession.mockResponse = APIResponse.flirtHistorySuccess()

        apiClient.getFlirtHistory(page: 1, limit: 20) { result in
            switch result {
            case .success(let response):
                XCTAssertTrue(response.success, "Response should indicate success")
                XCTAssertNotNil(response.data, "Response should contain data")
                XCTAssertNotNil(response.data?.suggestions, "Response should contain suggestions")
                XCTAssertNotNil(response.data?.pagination, "Response should contain pagination info")

            case .failure(let error):
                XCTFail("Get flirt history should succeed but failed with: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }

    func testGetFlirtHistoryWithFilters() {
        let expectation = self.expectation(description: "Should handle history filters")

        mockSession.mockResponse = APIResponse.flirtHistorySuccess()

        apiClient.getFlirtHistory(
            page: 2,
            limit: 10,
            suggestionType: "response",
            screenshotId: "screenshot-123"
        ) { result in
            // Verify request was made with correct parameters
            if let lastRequest = self.mockSession.lastRequest,
               let url = lastRequest.url {

                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let queryItems = urlComponents?.queryItems ?? []

                XCTAssertTrue(queryItems.contains { $0.name == "page" && $0.value == "2" }, "Should include page parameter")
                XCTAssertTrue(queryItems.contains { $0.name == "limit" && $0.value == "10" }, "Should include limit parameter")
                XCTAssertTrue(queryItems.contains { $0.name == "suggestion_type" && $0.value == "response" }, "Should include suggestion type filter")
                XCTAssertTrue(queryItems.contains { $0.name == "screenshot_id" && $0.value == "screenshot-123" }, "Should include screenshot ID filter")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Rate Suggestion API Tests

    func testRateSuggestionSuccess() {
        let expectation = self.expectation(description: "Rate suggestion should succeed")

        mockSession.mockResponse = APIResponse.rateSuggestionSuccess()

        apiClient.rateSuggestion(suggestionId: "suggestion-123", rating: 5, feedback: "Great suggestion!") { result in
            switch result {
            case .success(let response):
                XCTAssertTrue(response.success, "Rating should succeed")
                XCTAssertNotNil(response.message, "Response should contain message")

            case .failure(let error):
                XCTFail("Rate suggestion should succeed but failed with: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testRateSuggestionInvalidRating() {
        let expectation = self.expectation(description: "Should reject invalid rating")

        mockSession.mockResponse = APIResponse.invalidRatingError()

        apiClient.rateSuggestion(suggestionId: "suggestion-123", rating: 0, feedback: nil) { result in
            switch result {
            case .success:
                XCTFail("Should fail with invalid rating")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("rating") || error.localizedDescription.contains("1 and 5"), "Error should indicate invalid rating")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Concurrent API Calls Tests

    func testConcurrentAPICallsSafety() {
        let expectation = self.expectation(description: "Concurrent API calls should be handled safely")
        expectation.expectedFulfillmentCount = 3

        mockSession.mockResponse = APIResponse.generateFlirtsSuccess()

        // Make multiple concurrent API calls
        let group = DispatchGroup()

        group.enter()
        apiClient.generateFlirts(screenshotId: "concurrent-1", context: "test") { _ in
            expectation.fulfill()
            group.leave()
        }

        group.enter()
        apiClient.generateFlirts(screenshotId: "concurrent-2", context: "test") { _ in
            expectation.fulfill()
            group.leave()
        }

        group.enter()
        apiClient.getFlirtHistory(page: 1, limit: 10) { _ in
            expectation.fulfill()
            group.leave()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testAPICallCancellation() {
        let expectation = self.expectation(description: "Should be able to cancel API calls")

        // Start a long-running request
        let task = apiClient.generateFlirts(screenshotId: "cancel-test", context: "test") { result in
            switch result {
            case .failure(let error as NSError):
                if error.code == NSURLErrorCancelled {
                    expectation.fulfill()
                    return
                }
                fallthrough
            default:
                XCTFail("Request should be cancelled")
            }
        }

        // Cancel the request immediately
        task?.cancel()

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Cache Tests

    func testResponseCaching() {
        let expectation1 = self.expectation(description: "First request")
        let expectation2 = self.expectation(description: "Second request should use cache")

        // Enable caching for this test
        apiClient.enableCaching = true

        mockSession.mockResponse = APIResponse.generateFlirtsSuccess()

        // First request
        apiClient.generateFlirts(screenshotId: "cache-test", context: "test") { result in
            switch result {
            case .success:
                expectation1.fulfill()
            case .failure(let error):
                XCTFail("First request should succeed: \(error)")
            }
        }

        wait(for: [expectation1], timeout: 3.0)

        // Reset mock to return different response
        mockSession.requestCount = 0

        // Second identical request should use cache (no new network request)
        apiClient.generateFlirts(screenshotId: "cache-test", context: "test") { result in
            switch result {
            case .success:
                // Verify no new network request was made
                XCTAssertEqual(self.mockSession.requestCount, 0, "Should use cached response, no new network request")
                expectation2.fulfill()
            case .failure(let error):
                XCTFail("Cached request should succeed: \(error)")
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Rate Limiting Tests

    func testRateLimitHandling() {
        let expectation = self.expectation(description: "Should handle rate limit errors")

        // Mock rate limit error response
        mockSession.mockResponse = APIResponse.rateLimitError()

        apiClient.generateFlirts(screenshotId: "rate-limit-test", context: "test") { result in
            switch result {
            case .success:
                XCTFail("Should fail with rate limit error")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("rate") || error.localizedDescription.contains("limit"), "Error should indicate rate limiting")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Authentication Errors Tests

    func testUnauthorizedResponse() {
        let expectation = self.expectation(description: "Should handle unauthorized response")

        mockSession.mockResponse = APIResponse.unauthorizedError()

        apiClient.generateFlirts(screenshotId: "unauth-test", context: "test") { result in
            switch result {
            case .success:
                XCTFail("Should fail with unauthorized error")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("unauthorized") || error.localizedDescription.contains("401"), "Error should indicate unauthorized access")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Mock API Responses

struct APIResponse {
    static func generateFlirtsSuccess() -> Data {
        return """
        {
            "success": true,
            "data": {
                "suggestions": [
                    {
                        "id": "suggestion-1",
                        "text": "Hey! I couldn't help but notice your amazing smile. How's your day going?",
                        "confidence": 0.85,
                        "reasoning": "Friendly opener that references profile photo"
                    },
                    {
                        "id": "suggestion-2",
                        "text": "That photo looks like it was taken somewhere amazing! Where was that?",
                        "confidence": 0.9,
                        "reasoning": "Shows interest in their experiences"
                    },
                    {
                        "id": "suggestion-3",
                        "text": "I love your style! You seem like someone with great stories to tell.",
                        "confidence": 0.8,
                        "reasoning": "Compliments personality and invites conversation"
                    }
                ],
                "metadata": {
                    "suggestion_type": "opener",
                    "tone": "playful",
                    "screenshot_id": "test-123",
                    "total_suggestions": 3,
                    "generated_at": "2025-09-24T13:45:30.000Z"
                }
            },
            "cached": false,
            "message": "Flirt suggestions generated successfully"
        }
        """.data(using: .utf8)!
    }

    static func generateFlirtsFallback() -> Data {
        return """
        {
            "success": true,
            "suggestions": [
                {
                    "id": "fallback-1",
                    "text": "Hey there! I couldn't help but notice your amazing smile. How's your day going?",
                    "confidence": 0.75,
                    "tone": "casual",
                    "voice_available": false
                }
            ],
            "metadata": {
                "suggestion_type": "opener",
                "tone": "casual",
                "generated_at": "2025-09-24T13:45:30.000Z",
                "fallback": true
            },
            "warning": "Using fallback suggestions due to API limitations"
        }
        """.data(using: .utf8)!
    }

    static func screenshotUploadSuccess() -> Data {
        return """
        {
            "success": true,
            "screenshot_id": "screenshot-abc123",
            "message": "Screenshot uploaded successfully"
        }
        """.data(using: .utf8)!
    }

    static func flirtHistorySuccess() -> Data {
        return """
        {
            "success": true,
            "data": {
                "suggestions": [
                    {
                        "id": "suggestion-history-1",
                        "suggestion_text": "That's really interesting!",
                        "confidence_score": 0.9,
                        "suggestion_type": "response",
                        "created_at": "2025-09-24T13:30:00.000Z",
                        "used_at": null,
                        "rating": null
                    }
                ],
                "pagination": {
                    "page": 1,
                    "limit": 20,
                    "total": 15,
                    "totalPages": 1
                }
            }
        }
        """.data(using: .utf8)!
    }

    static func rateSuggestionSuccess() -> Data {
        return """
        {
            "success": true,
            "message": "Rating saved successfully"
        }
        """.data(using: .utf8)!
    }

    static func invalidRatingError() -> Data {
        return """
        {
            "success": false,
            "error": "Rating must be between 1 and 5",
            "code": "INVALID_RATING"
        }
        """.data(using: .utf8)!
    }

    static func rateLimitError() -> Data {
        return """
        {
            "success": false,
            "error": "Rate limit exceeded",
            "code": "RATE_LIMIT_EXCEEDED"
        }
        """.data(using: .utf8)!
    }

    static func unauthorizedError() -> Data {
        return """
        {
            "success": false,
            "error": "Unauthorized",
            "code": "UNAUTHORIZED"
        }
        """.data(using: .utf8)!
    }
}

// MARK: - Enhanced Mock URLSession

class MockURLSession: URLSession {
    var mockResponse: Data?
    var mockResponseData: Data?
    var mockError: Error?
    var shouldReturnError = false
    var lastRequest: URLRequest?
    var requestCount = 0

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        lastRequest = request
        requestCount += 1

        let task = MockURLSessionDataTask()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldReturnError {
                completionHandler(nil, nil, self.mockError)
            } else {
                let data = self.mockResponseData ?? self.mockResponse
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
                completionHandler(data, response, nil)
            }
        }

        return task
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    private var _state: URLSessionTask.State = .suspended

    override var state: URLSessionTask.State {
        return _state
    }

    override func resume() {
        _state = .running
    }

    override func cancel() {
        _state = .canceling
    }
}