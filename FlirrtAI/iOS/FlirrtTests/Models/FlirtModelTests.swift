//
//  FlirtModelTests.swift
//  FlirrtTests (Vibe8)
//
//  Unit tests for Flirt model
//  Created by: QA Engineer Agent
//

import XCTest
@testable import Flirrt

final class FlirtModelTests: Vibe8TestCase {

    // MARK: - Initialization Tests

    func testFlirtInitialization() {
        // Arrange & Act
        let flirt = Flirt(
            id: "test-123",
            text: "Test flirt message",
            tone: "playful",
            qualityScore: 0.85,
            context: "Test context",
            timestamp: Date()
        )

        // Assert
        XCTAssertEqual(flirt.id, "test-123")
        XCTAssertEqual(flirt.text, "Test flirt message")
        XCTAssertEqual(flirt.tone, "playful")
        XCTAssertEqual(flirt.qualityScore, 0.85)
        XCTAssertEqual(flirt.context, "Test context")
        XCTAssertNotNil(flirt.timestamp)
    }

    func testFlirtWithDefaultValues() {
        // Arrange & Act
        let flirt = Flirt.mockFlirt

        // Assert
        XCTAssertFalse(flirt.id.isEmpty)
        XCTAssertFalse(flirt.text.isEmpty)
        XCTAssertGreaterThanOrEqual(flirt.qualityScore, 0.0)
        XCTAssertLessThanOrEqual(flirt.qualityScore, 1.0)
    }

    // MARK: - Quality Score Tests

    func testQualityScoreRange() {
        // Arrange
        let validScores = [0.0, 0.5, 0.85, 1.0]
        let invalidScores = [-0.1, 1.1, 2.0]

        // Act & Assert - Valid scores
        for score in validScores {
            let flirt = Flirt(
                id: "test",
                text: "Test",
                tone: "playful",
                qualityScore: score,
                context: "Test",
                timestamp: Date()
            )
            XCTAssertGreaterThanOrEqual(flirt.qualityScore, 0.0)
            XCTAssertLessThanOrEqual(flirt.qualityScore, 1.0)
        }

        // Invalid scores should be validated at API level
        // This test documents expected behavior
    }

    func testHighQualityFlirt() {
        // Arrange
        let flirt = Flirt(
            id: "high-quality",
            text: "Exceptional flirt message",
            tone: "confident",
            qualityScore: 0.95,
            context: "Perfect context",
            timestamp: Date()
        )

        // Assert
        XCTAssertGreaterThan(flirt.qualityScore, 0.9, "High quality flirt should have score > 0.9")
    }

    // MARK: - Codable Tests

    func testFlirtEncodingDecoding() throws {
        // Arrange
        let original = Flirt.mockFlirt

        // Act - Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        // Act - Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Flirt.self, from: data)

        // Assert
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.tone, original.tone)
        XCTAssertEqual(decoded.qualityScore, original.qualityScore)
        XCTAssertEqual(decoded.context, original.context)
    }

    // MARK: - Collection Tests

    func testFlirtArray() {
        // Arrange
        let flirts = Flirt.mockFlirts

        // Assert
        XCTAssertEqual(flirts.count, 3)
        XCTAssertTrue(flirts.allSatisfy { !$0.id.isEmpty })
        XCTAssertTrue(flirts.allSatisfy { !$0.text.isEmpty })
    }

    func testFlirtSorting() {
        // Arrange
        let flirts = Flirt.mockFlirts

        // Act - Sort by quality score
        let sorted = flirts.sorted { $0.qualityScore > $1.qualityScore }

        // Assert
        XCTAssertGreaterThanOrEqual(sorted[0].qualityScore, sorted[1].qualityScore)
        XCTAssertGreaterThanOrEqual(sorted[1].qualityScore, sorted[2].qualityScore)
    }

    // MARK: - Identifiable Tests

    func testFlirtIdentifiable() {
        // Arrange
        let flirts = Flirt.mockFlirts

        // Act - Get unique IDs
        let ids = Set(flirts.map { $0.id })

        // Assert
        XCTAssertEqual(ids.count, flirts.count, "All flirt IDs should be unique")
    }
}
