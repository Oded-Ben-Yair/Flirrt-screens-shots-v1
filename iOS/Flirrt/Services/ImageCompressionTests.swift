import UIKit
import XCTest
import OSLog

@testable import Flirrt

/// Comprehensive test suite for image compression functionality
final class ImageCompressionTests: XCTestCase {

    private var compressionService: ImageCompressionService!
    private let logger = Logger(subsystem: "com.flirrt.tests", category: "compression")

    override func setUp() {
        super.setUp()
        compressionService = ImageCompressionService()
    }

    override func tearDown() {
        compressionService = nil
        super.tearDown()
    }

    // MARK: - Compression Ratio Tests

    func testSmallImageNoCompression() async {
        // Create a small test image (should not need compression)
        let smallImage = createTestImage(size: CGSize(width: 100, height: 100))

        let result = await compressionService.compressImage(smallImage, targetFormat: .jpeg, useAggressive: false)

        XCTAssertTrue(result.success, "Compression should succeed for small images")
        XCTAssertLessThan(result.compressionRatio, 0.1, "Small images should have minimal compression")

        logger.info("Small image test: \(result.summary)")
    }

    func testMediumImageLightCompression() async {
        // Create a medium-sized test image
        let mediumImage = createTestImage(size: CGSize(width: 800, height: 1200))

        let result = await compressionService.compressImage(mediumImage, targetFormat: .jpeg, useAggressive: false)

        XCTAssertTrue(result.success, "Compression should succeed")
        XCTAssertGreaterThan(result.compressionRatio, 0.2, "Medium images should achieve meaningful compression")
        XCTAssertLessThan(result.compressionRatio, 0.8, "Should not over-compress medium images")

        logger.info("Medium image test: \(result.summary)")
    }

    func testLargeImageAggressiveCompression() async {
        // Create a large test image that requires aggressive compression
        let largeImage = createTestImage(size: CGSize(width: 3000, height: 4000))

        let result = await compressionService.compressImage(largeImage, targetFormat: .heic, useAggressive: true)

        XCTAssertTrue(result.success, "Compression should succeed for large images")
        XCTAssertGreaterThan(result.compressionRatio, 0.6, "Large images should achieve 60%+ compression")
        XCTAssertLessThan(result.compressedSize, 500_000, "Compressed size should be under 500KB")

        logger.info("Large image test: \(result.summary)")
    }

    // MARK: - Format Comparison Tests

    func testHEICvsJPEGCompression() async {
        let testImage = createTestImage(size: CGSize(width: 1500, height: 2000))

        // Test HEIC compression
        let heicResult = await compressionService.compressImage(testImage, targetFormat: .heic, useAggressive: true)

        // Test JPEG compression
        let jpegResult = await compressionService.compressImage(testImage, targetFormat: .jpeg, useAggressive: true)

        XCTAssertTrue(heicResult.success && jpegResult.success, "Both formats should compress successfully")

        // HEIC should generally produce smaller files
        let heicAdvantage = Double(jpegResult.compressedSize) / Double(heicResult.compressedSize)
        logger.info("HEIC vs JPEG: HEIC is \(String(format: "%.1f", heicAdvantage))x smaller")

        // HEIC should be at least as good as JPEG, often better
        XCTAssertLessThanOrEqual(heicResult.compressedSize, jpegResult.compressedSize * 11 / 10, "HEIC should be competitive with JPEG")
    }

    // MARK: - Performance Tests

    func testCompressionPerformance() async {
        let testImage = createTestImage(size: CGSize(width: 2000, height: 3000))

        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await compressionService.compressImage(testImage, targetFormat: .heic, useAggressive: true)
        let endTime = CFAbsoluteTimeGetCurrent()

        let totalTime = endTime - startTime

        XCTAssertTrue(result.success, "Compression should succeed")
        XCTAssertLessThan(totalTime, 5.0, "Compression should complete within 5 seconds")
        XCTAssertLessThan(result.processingTime, totalTime + 0.1, "Reported processing time should be accurate")

        logger.info("Performance test: \(String(format: "%.2f", totalTime))s total, \(String(format: "%.2f", result.processingTime))s reported")
    }

    // MARK: - Binary Search Algorithm Tests

    func testBinarySearchOptimization() async {
        let testImage = createTestImage(size: CGSize(width: 2500, height: 3500))

        // Test that binary search finds a good balance
        let result = await compressionService.compressImage(testImage, targetFormat: .jpeg, useAggressive: true)

        XCTAssertTrue(result.success, "Binary search compression should succeed")

        // Should achieve target size approximately (within 20% tolerance)
        let targetSize = 500_000 // 500KB target
        let sizeDifference = abs(result.compressedSize - targetSize)
        let tolerance = targetSize / 5 // 20% tolerance

        XCTAssertLessThan(sizeDifference, tolerance, "Binary search should get close to target size")

        logger.info("Binary search test - Target: \(formatBytes(targetSize)), Actual: \(formatBytes(result.compressedSize)), Difference: \(formatBytes(sizeDifference))")
    }

    // MARK: - Screenshot-Specific Tests

    func testScreenshotOptimization() async {
        // Simulate typical screenshot data
        let screenshotImage = createScreenshotLikeImage()
        guard let screenshotData = screenshotImage.pngData() else {
            XCTFail("Failed to create screenshot data")
            return
        }

        let result = await compressionService.compressScreenshotForAI(screenshotData)

        XCTAssertTrue(result.success, "Screenshot compression should succeed")
        XCTAssertEqual(result.format, .heic, "Screenshots should be compressed to HEIC")
        XCTAssertGreaterThan(result.compressionRatio, 0.4, "Screenshots should achieve at least 40% compression")

        logger.info("Screenshot test: \(result.summary)")
    }

    // MARK: - Edge Cases

    func testVerySmallImage() async {
        let tinyImage = createTestImage(size: CGSize(width: 10, height: 10))

        let result = await compressionService.compressImage(tinyImage, targetFormat: .jpeg, useAggressive: true)

        XCTAssertTrue(result.success, "Even tiny images should compress successfully")
        // Very small images might actually get larger due to format overhead

        logger.info("Tiny image test: \(result.summary)")
    }

    func testVeryLargeImage() async {
        let hugeImage = createTestImage(size: CGSize(width: 6000, height: 8000))

        let result = await compressionService.compressImage(hugeImage, targetFormat: .heic, useAggressive: true)

        XCTAssertTrue(result.success, "Very large images should compress successfully")
        XCTAssertGreaterThan(result.compressionRatio, 0.8, "Very large images should achieve 80%+ compression")
        XCTAssertLessThan(result.compressedSize, 500_000, "Result should still be under 500KB")

        logger.info("Huge image test: \(result.summary)")
    }

    func testCorruptImageData() async {
        let corruptData = Data(repeating: 0xFF, count: 1000)

        let result = await compressionService.compressScreenshotForAI(corruptData)

        XCTAssertFalse(result.success, "Corrupt data should fail gracefully")
        XCTAssertNotNil(result.error, "Should provide error message")
        XCTAssertEqual(result.compressedSize, 0, "Should not produce output for corrupt data")

        logger.info("Corrupt data test: \(result.error ?? "No error message")")
    }

    // MARK: - Memory Usage Tests

    func testMemoryUsageDuringCompression() async {
        // Test multiple compressions in sequence to check for memory leaks
        let testImage = createTestImage(size: CGSize(width: 1500, height: 2000))

        for iteration in 1...5 {
            let result = await compressionService.compressImage(testImage, targetFormat: .heic, useAggressive: true)
            XCTAssertTrue(result.success, "Iteration \(iteration) should succeed")

            // Force memory cleanup
            autoreleasepool {
                // Empty pool to force cleanup
            }
        }

        logger.info("Memory test completed - 5 iterations successful")
    }

    // MARK: - Integration Tests

    func testRealWorldScenario() async {
        // Simulate a real-world dating app screenshot
        let realWorldImage = createDatingAppScreenshotSimulation()
        guard let imageData = realWorldImage.pngData() else {
            XCTFail("Failed to create real-world image data")
            return
        }

        let originalSize = imageData.count
        logger.info("Real-world test starting - Original size: \(formatBytes(originalSize))")

        let result = await compressionService.compressScreenshotForAI(imageData)

        XCTAssertTrue(result.success, "Real-world scenario should succeed")
        XCTAssertLessThan(result.compressedSize, originalSize / 2, "Should achieve at least 50% compression")
        XCTAssertGreaterThan(result.compressionRatio, 0.5, "Should achieve 50%+ compression ratio")

        // Verify the compressed image is still readable
        guard let compressedImage = UIImage(data: result.data) else {
            XCTFail("Compressed data should be readable as image")
            return
        }

        XCTAssertGreaterThan(compressedImage.size.width, 100, "Compressed image should have reasonable dimensions")
        XCTAssertGreaterThan(compressedImage.size.height, 100, "Compressed image should have reasonable dimensions")

        logger.info("Real-world test: \(result.summary)")
        logger.info("Compressed image dimensions: \(Int(compressedImage.size.width))x\(Int(compressedImage.size.height))")
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a detailed gradient pattern for realistic compression testing
            let rect = CGRect(origin: .zero, size: size)

            // Background gradient
            let colors = [UIColor.blue.cgColor, UIColor.purple.cgColor, UIColor.red.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: rect.origin, end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])

            // Add some text-like elements
            UIColor.white.setFill()
            for i in 0..<Int(size.height / 40) {
                let textRect = CGRect(x: 20, y: CGFloat(i * 40 + 20), width: size.width - 40, height: 20)
                context.fill(textRect)
            }
        }
    }

    private func createScreenshotLikeImage() -> UIImage {
        // Create an image that resembles a typical dating app screenshot
        let size = CGSize(width: 375, height: 812) // iPhone X dimensions
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Header area
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: 100))

            // Profile images (circles)
            UIColor.systemGray2.setFill()
            for i in 0..<3 {
                let x = CGFloat(i * 100 + 50)
                let y: CGFloat = 200
                context.fillEllipse(in: CGRect(x: x, y: y, width: 80, height: 80))
            }

            // Text areas
            UIColor.label.setFill()
            for i in 0..<8 {
                let y = CGFloat(i * 50 + 350)
                context.fill(CGRect(x: 20, y: y, width: size.width - 40, height: 30))
            }
        }
    }

    private func createDatingAppScreenshotSimulation() -> UIImage {
        // Create a more complex, realistic dating app interface
        let size = CGSize(width: 414, height: 896) // iPhone 11 Pro Max
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Background gradient
            let colors = [UIColor.systemPink.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            // Navigation bar
            UIColor.white.withAlphaComponent(0.9).setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: 120))

            // Profile card
            UIColor.white.setFill()
            let cardRect = CGRect(x: 20, y: 150, width: size.width - 40, height: 500)
            context.cgContext.addPath(UIBezierPath(roundedRect: cardRect, cornerRadius: 20).cgPath)
            context.cgContext.fillPath()

            // Profile photo area
            UIColor.systemGray3.setFill()
            context.fill(CGRect(x: 40, y: 170, width: size.width - 80, height: 300))

            // Text content
            UIColor.label.setFill()
            for i in 0..<5 {
                let textRect = CGRect(x: 40, y: CGFloat(490 + i * 30), width: size.width - 80, height: 20)
                context.fill(textRect)
            }

            // Bottom buttons
            UIColor.systemRed.setFill()
            context.fillEllipse(in: CGRect(x: 80, y: 720, width: 60, height: 60))

            UIColor.systemGreen.setFill()
            context.fillEllipse(in: CGRect(x: size.width - 140, y: 720, width: 60, height: 60))
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Performance Benchmarking

extension ImageCompressionTests {

    func testCompressionBenchmark() async {
        let testSizes: [(String, CGSize)] = [
            ("Small", CGSize(width: 400, height: 600)),
            ("Medium", CGSize(width: 1080, height: 1920)),
            ("Large", CGSize(width: 2160, height: 3840)),
            ("XLarge", CGSize(width: 4032, height: 3024))
        ]

        logger.info("🏁 Starting compression benchmark")

        for (name, size) in testSizes {
            let testImage = createTestImage(size: size)
            guard let originalData = testImage.pngData() else { continue }

            let startTime = CFAbsoluteTimeGetCurrent()
            let result = await compressionService.compressScreenshotForAI(originalData)
            let endTime = CFAbsoluteTimeGetCurrent()

            let compressionRatio = result.compressionRatio * 100
            let processingTime = endTime - startTime

            logger.info("📊 \(name): \(formatBytes(result.originalSize)) → \(formatBytes(result.compressedSize)) (\(String(format: "%.1f", compressionRatio))% reduction) in \(String(format: "%.2f", processingTime))s")
        }

        logger.info("🏁 Benchmark complete")
    }
}

// MARK: - Manual Test Validation

#if DEBUG
extension ImageCompressionTests {

    /// Manual validation test that can be run in debug builds
    func validateCompressionManually() async {
        logger.info("🧪 Starting manual validation")

        let service = ImageCompressionService()
        await service.validateCompressionAlgorithm()

        logger.info("✅ Manual validation complete")
    }
}
#endif