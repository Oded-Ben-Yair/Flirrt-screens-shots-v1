import UIKit
import ImageIO
import MobileCoreServices
import OSLog

/// Advanced image compression service that optimizes images for AI analysis while maintaining quality
@MainActor
final class ImageCompressionService {

    // MARK: - Configuration
    private struct CompressionConfig {
        static let targetSizeSmall: Int = 50_000       // 50KB - Ultra compression threshold
        static let targetSizeMedium: Int = 100_000     // 100KB - Aggressive compression threshold
        static let targetSizeLarge: Int = 200_000      // 200KB - Maximum allowed size (down from 500KB)
        static let maxDimension: CGFloat = 1600        // Reduced max dimension for better compression
        static let aiOptimalDimension: CGFloat = 1200  // Optimal for AI analysis
        static let heicQuality: CGFloat = 0.75         // Reduced for better compression
        static let jpegQualityHigh: CGFloat = 0.85     // Reduced high quality
        static let jpegQualityMedium: CGFloat = 0.7    // Reduced medium quality
        static let jpegQualityLow: CGFloat = 0.5       // More aggressive low quality
        static let jpegQualityUltra: CGFloat = 0.35    // Ultra compression for large images
        static let binarySearchIterations: Int = 10    // More iterations for better optimization
        static let webpQuality: CGFloat = 0.8          // WebP quality (better compression than JPEG)
        static let compressionTarget: Double = 0.7     // Target 70% compression ratio
    }

    private let logger = Logger(subsystem: "com.vibe8.app", category: "ImageCompression")

    // MARK: - Public Interface

    /// Compresses an image with intelligent optimization based on size and content
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - targetFormat: Preferred output format (.heic for best compression, .jpeg for compatibility)
    ///   - useAggressive: Enable aggressive compression for large images
    /// - Returns: Compressed image data and compression statistics
    func compressImage(
        _ image: UIImage,
        targetFormat: ImageFormat = .heic,
        useAggressive: Bool = true
    ) async -> CompressionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("🗜️ Starting image compression - Size: \(image.size), Format: \(targetFormat.rawValue)")

        // Step 1: Get original data size
        guard let originalData = image.pngData() else {
            logger.error("❌ Failed to get PNG data from image")
            return CompressionResult(
                data: Data(),
                originalSize: 0,
                compressedSize: 0,
                compressionRatio: 0,
                format: targetFormat,
                processingTime: 0,
                success: false,
                error: "Failed to extract image data"
            )
        }

        let originalSize = originalData.count
        logger.info("📊 Original image size: \(formatBytes(originalSize))")

        // Step 2: Determine compression strategy
        let strategy = determineCompressionStrategy(for: originalSize, image: image)
        logger.info("🎯 Compression strategy: \(strategy.description)")

        // Step 3: Apply compression based on strategy
        let compressedData: Data
        switch strategy {
        case .none:
            compressedData = originalData

        case .light:
            compressedData = await performLightCompression(image, format: targetFormat)

        case .medium:
            compressedData = await performMediumCompression(image, format: targetFormat)

        case .aggressive:
            compressedData = await performAggressiveCompression(image, format: targetFormat, useAggressive: useAggressive)

        case .ultra:
            compressedData = await performUltraCompression(image, format: targetFormat)
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let compressionRatio = originalSize > 0 ? (1.0 - Double(compressedData.count) / Double(originalSize)) : 0

        logger.info("✅ Compression complete - Original: \(formatBytes(originalSize)), Compressed: \(formatBytes(compressedData.count)), Ratio: \(String(format: "%.1f", compressionRatio * 100))%, Time: \(String(format: "%.2f", processingTime))s")

        return CompressionResult(
            data: compressedData,
            originalSize: originalSize,
            compressedSize: compressedData.count,
            compressionRatio: compressionRatio,
            format: targetFormat,
            processingTime: processingTime,
            success: !compressedData.isEmpty,
            error: compressedData.isEmpty ? "Compression failed" : nil
        )
    }

    /// Compresses screenshot data specifically optimized for AI analysis
    /// - Parameter screenshotData: Raw screenshot data
    /// - Returns: Optimized image data for AI processing
    func compressScreenshotForAI(_ screenshotData: Data) async -> CompressionResult {
        logger.info("📸 Compressing screenshot for AI analysis")

        guard let image = UIImage(data: screenshotData) else {
            logger.error("❌ Failed to create UIImage from screenshot data")
            return CompressionResult(
                data: Data(),
                originalSize: screenshotData.count,
                compressedSize: 0,
                compressionRatio: 0,
                format: .heic,
                processingTime: 0,
                success: false,
                error: "Invalid image data"
            )
        }

        // For AI analysis, prioritize HEIC format and aggressive compression
        return await compressImage(image, targetFormat: .heic, useAggressive: true)
    }

    // MARK: - Compression Strategies

    private enum CompressionStrategy {
        case none           // < 50KB - No compression needed
        case light          // 50-100KB - Light compression
        case medium         // 100-200KB - Medium compression
        case aggressive     // 200KB+ - Aggressive compression
        case ultra          // > 1MB or very large - Ultra compression for maximum size reduction

        var description: String {
            switch self {
            case .none: return "No compression (small size)"
            case .light: return "Light compression (0.75 quality)"
            case .medium: return "Medium compression (0.6 quality + resize)"
            case .aggressive: return "Aggressive compression (0.45 quality + resize + optimal format)"
            case .ultra: return "Ultra compression (0.35 quality + aggressive resize + WebP/HEIC)"
            }
        }
    }

    private func determineCompressionStrategy(for size: Int, image: UIImage) -> CompressionStrategy {
        let maxDimension = max(image.size.width, image.size.height)
        let isVeryLarge = size > 1_000_000 || maxDimension > 2400 // > 1MB or very high resolution

        if size < CompressionConfig.targetSizeSmall {
            return .none
        } else if size < CompressionConfig.targetSizeMedium {
            return .light
        } else if size < CompressionConfig.targetSizeLarge && !isVeryLarge {
            return .medium
        } else if isVeryLarge {
            return .ultra  // Ultra compression for very large files
        } else {
            return .aggressive
        }
    }

    // MARK: - Compression Implementations

    private func performLightCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        logger.debug("🔹 Applying light compression")

        switch format {
        case .heic:
            return await compressToHEIC(image, quality: CompressionConfig.heicQuality)
        case .jpeg:
            return compressToJPEG(image, quality: CompressionConfig.jpegQualityHigh)
        case .webp:
            return await compressToWebP(image, quality: CompressionConfig.webpQuality)
        }
    }

    private func performMediumCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        logger.debug("🔸 Applying medium compression")

        // Resize if needed
        let resizedImage = resizeImageIfNeeded(image, maxDimension: CompressionConfig.maxDimension)

        switch format {
        case .heic:
            return await compressToHEIC(resizedImage, quality: CompressionConfig.heicQuality * 0.9)
        case .jpeg:
            return compressToJPEG(resizedImage, quality: CompressionConfig.jpegQualityMedium)
        case .webp:
            return await compressToWebP(resizedImage, quality: CompressionConfig.webpQuality * 0.9)
        }
    }

    private func performAggressiveCompression(_ image: UIImage, format: ImageFormat, useAggressive: Bool) async -> Data {
        logger.debug("🔺 Applying aggressive compression")

        // Always resize for aggressive compression
        let maxDim: CGFloat = useAggressive ? CompressionConfig.maxDimension * 0.8 : CompressionConfig.maxDimension
        let resizedImage = resizeImageIfNeeded(image, maxDimension: maxDim)

        // Use binary search to find optimal quality
        return await binarySearchOptimalCompression(
            resizedImage,
            format: format,
            targetSize: CompressionConfig.targetSizeLarge
        )
    }

    private func performUltraCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        logger.debug("🔥 Applying ultra compression for maximum size reduction")

        // Aggressive resizing for ultra compression
        let ultraMaxDim = CompressionConfig.aiOptimalDimension * 0.75 // Even smaller for ultra
        let resizedImage = resizeImageIfNeeded(image, maxDimension: ultraMaxDim)

        // Try WebP first for best compression, fallback to HEIC, then JPEG
        let webpData = await compressToWebP(resizedImage, quality: CompressionConfig.webpQuality * 0.8)
        if !webpData.isEmpty && webpData.count <= CompressionConfig.targetSizeMedium {
            logger.info("🔥 Ultra WebP compression successful")
            return webpData
        }

        // If WebP not available or still too large, try HEIC with very low quality
        let heicData = await compressToHEIC(resizedImage, quality: CompressionConfig.jpegQualityUltra)
        if !heicData.isEmpty && heicData.count <= CompressionConfig.targetSizeMedium {
            logger.info("🔥 Ultra HEIC compression successful")
            return heicData
        }

        // Final fallback: ultra-aggressive JPEG with binary search
        return await binarySearchOptimalCompression(
            resizedImage,
            format: .jpeg,
            targetSize: CompressionConfig.targetSizeMedium
        )
    }

    // MARK: - Advanced Compression Algorithms

    /// Uses binary search to find the optimal compression quality for a target file size
    private func binarySearchOptimalCompression(
        _ image: UIImage,
        format: ImageFormat,
        targetSize: Int
    ) async -> Data {
        logger.debug("🔍 Binary search for optimal compression quality")

        var minQuality: CGFloat = 0.3
        var maxQuality: CGFloat = 0.9
        var bestData = Data()
        var bestQuality: CGFloat = minQuality

        for iteration in 1...CompressionConfig.binarySearchIterations {
            let currentQuality = (minQuality + maxQuality) / 2
            logger.debug("  Iteration \(iteration): Testing quality \(String(format: "%.3f", currentQuality))")

            let testData: Data
            switch format {
            case .heic:
                testData = await compressToHEIC(image, quality: currentQuality)
            case .jpeg:
                testData = compressToJPEG(image, quality: currentQuality)
            case .webp:
                testData = await compressToWebP(image, quality: currentQuality)
            }

            let testSize = testData.count
            logger.debug("    Result: \(formatBytes(testSize)) (target: \(formatBytes(targetSize)))")

            if testSize <= targetSize {
                // This quality produces acceptable size, try higher quality
                bestData = testData
                bestQuality = currentQuality
                minQuality = currentQuality
            } else {
                // File too large, try lower quality
                maxQuality = currentQuality
            }

            // Early exit if we're very close to target
            if abs(testSize - targetSize) < targetSize / 20 { // Within 5% of target
                logger.debug("  🎯 Found optimal quality \(String(format: "%.3f", currentQuality)) in \(iteration) iterations")
                bestData = testData
                break
            }
        }

        logger.info("🔍 Binary search complete - Quality: \(String(format: "%.3f", bestQuality)), Size: \(formatBytes(bestData.count))")
        return bestData
    }

    // MARK: - Format-Specific Compression

    private func compressToHEIC(_ image: UIImage, quality: CGFloat) async -> Data {
        // HEIC compression using ImageIO for maximum efficiency
        guard let cgImage = image.cgImage else {
            logger.warning("⚠️ Failed to get CGImage for HEIC compression, falling back to JPEG")
            return compressToJPEG(image, quality: quality)
        }

        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            kUTTypeHEIC,
            1,
            nil
        ) else {
            logger.warning("⚠️ HEIC format not available, falling back to JPEG")
            return compressToJPEG(image, quality: quality)
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationOptimizeColorForSharing: true
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        let success = CGImageDestinationFinalize(destination)
        if success {
            logger.debug("✅ HEIC compression successful - Quality: \(String(format: "%.3f", quality))")
            return data as Data
        } else {
            logger.warning("⚠️ HEIC compression failed, falling back to JPEG")
            return compressToJPEG(image, quality: quality)
        }
    }

    private func compressToJPEG(_ image: UIImage, quality: CGFloat) -> Data {
        guard let jpegData = image.jpegData(compressionQuality: quality) else {
            logger.error("❌ JPEG compression failed")
            return Data()
        }

        logger.debug("✅ JPEG compression successful - Quality: \(String(format: "%.3f", quality))")
        return jpegData
    }

    private func compressToWebP(_ image: UIImage, quality: CGFloat) async -> Data {
        // Note: iOS doesn't have native WebP support, so we'll use a hybrid approach
        // For now, we'll simulate WebP compression by using HEIC with optimized settings
        // In a production app, you would integrate a WebP library like libwebp

        logger.debug("📦 Attempting WebP-like compression (using optimized HEIC)")

        // Use HEIC with WebP-equivalent quality settings
        let optimizedQuality = quality * 0.85 // WebP typically achieves better compression
        let webpLikeData = await compressToHEIC(image, quality: optimizedQuality)

        if !webpLikeData.isEmpty {
            logger.debug("✅ WebP-like compression successful - Quality: \(String(format: "%.3f", optimizedQuality))")
            return webpLikeData
        } else {
            logger.warning("⚠️ WebP-like compression failed, falling back to JPEG")
            return compressToJPEG(image, quality: quality * 0.8)
        }
    }

    // MARK: - Image Processing Utilities

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let currentMaxDimension = max(image.size.width, image.size.height)

        if currentMaxDimension <= maxDimension {
            logger.debug("📐 No resizing needed - Current: \(Int(currentMaxDimension))px, Max: \(Int(maxDimension))px")
            return image
        }

        let scale = maxDimension / currentMaxDimension
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        logger.info("📐 Resizing image - From: \(Int(image.size.width))x\(Int(image.size.height)) To: \(Int(newSize.width))x\(Int(newSize.height))")

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Utilities

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Types

/// Supported image formats for compression
enum ImageFormat: String, CaseIterable {
    case heic = "HEIC"
    case jpeg = "JPEG"
    case webp = "WebP"

    var fileExtension: String {
        switch self {
        case .heic: return "heic"
        case .jpeg: return "jpg"
        case .webp: return "webp"
        }
    }

    var mimeType: String {
        switch self {
        case .heic: return "image/heic"
        case .jpeg: return "image/jpeg"
        case .webp: return "image/webp"
        }
    }

    var compressionEfficiency: Double {
        switch self {
        case .webp: return 0.8  // Best compression
        case .heic: return 0.7  // Good compression
        case .jpeg: return 0.6  // Standard compression
        }
    }
}

/// Result of image compression operation
struct CompressionResult {
    let data: Data
    let originalSize: Int
    let compressedSize: Int
    let compressionRatio: Double // 0.0 to 1.0 (0 = no compression, 1 = 100% compression)
    let format: ImageFormat
    let processingTime: TimeInterval
    let success: Bool
    let error: String?

    /// Human-readable compression summary
    var summary: String {
        if !success {
            return "Compression failed: \(error ?? "Unknown error")"
        }

        let originalMB = Double(originalSize) / (1024 * 1024)
        let compressedMB = Double(compressedSize) / (1024 * 1024)
        let ratioPercent = compressionRatio * 100

        return String(format: "Compressed from %.2f MB to %.2f MB (%.1f%% reduction) in %.2fs",
                     originalMB, compressedMB, ratioPercent, processingTime)
    }

    /// Whether the compression achieved significant size reduction
    var isEffective: Bool {
        return success && compressionRatio > 0.3 // At least 30% reduction
    }
}

// MARK: - Testing and Validation

#if DEBUG
extension ImageCompressionService {

    /// Test compression with sample images for validation
    func validateCompressionAlgorithm() async {
        logger.info("🧪 Starting compression algorithm validation")

        // Create test images of different sizes
        let testSizes: [CGSize] = [
            CGSize(width: 400, height: 600),    // Small
            CGSize(width: 1080, height: 1920),  // Medium
            CGSize(width: 4000, height: 6000)   // Large
        ]

        for (index, size) in testSizes.enumerated() {
            let testImage = createTestImage(size: size)

            logger.info("🧪 Test \(index + 1): \(Int(size.width))x\(Int(size.height))")

            // Test both formats
            for format in ImageFormat.allCases {
                let result = await compressImage(testImage, targetFormat: format)
                logger.info("  \(format.rawValue): \(result.summary)")
            }
        }

        logger.info("✅ Compression validation complete")
    }

    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a gradient with some detail to test compression
            let colors = [UIColor.red, UIColor.blue, UIColor.green, UIColor.yellow]

            for (index, color) in colors.enumerated() {
                let rect = CGRect(
                    x: CGFloat(index) * size.width / 4,
                    y: 0,
                    width: size.width / 4,
                    height: size.height
                )
                color.setFill()
                context.fill(rect)
            }
        }
    }
}
#endif