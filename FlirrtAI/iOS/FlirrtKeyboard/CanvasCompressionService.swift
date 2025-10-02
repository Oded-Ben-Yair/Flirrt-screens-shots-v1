/**
 * HTML Canvas-based Compression Service for iOS Keyboard Extension
 * Provides advanced compression capabilities using Canvas API through WebView
 * Target: 299KB → 45KB compression capability
 */

import UIKit
import WebKit
import OSLog
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class CanvasCompressionService: NSObject {

    // MARK: - Properties
    private let logger = OSLog(subsystem: "com.flirrt.keyboard", category: "canvas-compression")
    private weak var webView: WKWebView?
    private var compressionCallbacks: [String: (CompressionResult) -> Void] = [:]
    private let maxCompressionRatio = 0.85 // Target 85% compression

    // Compression configuration
    struct CompressionConfig {
        let targetSizeKB: Int
        let maxWidth: Int
        let maxHeight: Int
        let quality: Double
        let format: String

        static let aggressive = CompressionConfig(
            targetSizeKB: 45,
            maxWidth: 800,
            maxHeight: 600,
            quality: 0.6,
            format: "webp"
        )

        static let balanced = CompressionConfig(
            targetSizeKB: 100,
            maxWidth: 1200,
            maxHeight: 900,
            quality: 0.75,
            format: "jpeg"
        )

        static let minimal = CompressionConfig(
            targetSizeKB: 200,
            maxWidth: 1600,
            maxHeight: 1200,
            quality: 0.85,
            format: "jpeg"
        )
    }

    // MARK: - Initialization
    override init() {
        super.init()
        setupWebView()
    }

    deinit {
        cleanupWebView()
    }

    // MARK: - WebView Setup
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true
        config.allowsInlineMediaPlayback = false
        config.mediaTypesRequiringUserActionForPlayback = .all

        // Create lightweight web view for canvas operations
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isHidden = true
        webView.scrollView.isScrollEnabled = false

        self.webView = webView

        os_log("🎨 Canvas compression service initialized", log: logger, type: .info)
    }

    private func cleanupWebView() {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
        compressionCallbacks.removeAll()
    }

    // MARK: - Public Compression Interface
    func compressImage(_ imageData: Data, config: CompressionConfig = .aggressive) async -> CompressionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let originalSize = imageData.count

        os_log("🎨 Starting Canvas compression - Original: %d KB, Target: %d KB",
               log: logger, type: .info, originalSize / 1024, config.targetSizeKB)

        guard let webView = webView else {
            return CompressionResult(
                success: false,
                data: imageData,
                originalSize: originalSize,
                compressedSize: originalSize,
                compressionRatio: 0,
                processingTime: 0,
                method: "canvas",
                error: "WebView not available"
            )
        }

        // Convert to base64 for web processing
        let base64Image = imageData.base64EncodedString()

        return await withCheckedContinuation { continuation in
            let callbackId = UUID().uuidString

            compressionCallbacks[callbackId] = { result in
                let processingTime = CFAbsoluteTimeGetCurrent() - startTime
                let finalResult = CompressionResult(
                    success: result.success,
                    data: result.data,
                    originalSize: originalSize,
                    compressedSize: result.compressedSize,
                    compressionRatio: result.compressionRatio,
                    processingTime: processingTime,
                    method: "canvas-\(config.format)",
                    error: result.error
                )
                continuation.resume(returning: finalResult)
            }

            // Generate HTML/JS for canvas compression
            let html = generateCompressionHTML(
                base64Image: base64Image,
                config: config,
                callbackId: callbackId
            )

            // Load HTML and start compression
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    // MARK: - HTML/JavaScript Generation
    private func generateCompressionHTML(base64Image: String, config: CompressionConfig, callbackId: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Canvas Compression</title>
            <style>
                body { margin: 0; padding: 0; overflow: hidden; }
                canvas { display: none; }
            </style>
        </head>
        <body>
            <canvas id="compressionCanvas"></canvas>
            <script>
                (function() {
                    'use strict';

                    const config = {
                        targetSizeKB: \(config.targetSizeKB),
                        maxWidth: \(config.maxWidth),
                        maxHeight: \(config.maxHeight),
                        quality: \(config.quality),
                        format: '\(config.format)'
                    };

                    const canvas = document.getElementById('compressionCanvas');
                    const ctx = canvas.getContext('2d', {
                        alpha: false,
                        desynchronized: true,
                        willReadFrequently: false
                    });

                    // Optimize canvas for compression
                    ctx.imageSmoothingEnabled = true;
                    ctx.imageSmoothingQuality = 'high';

                    async function compressImage() {
                        try {
                            console.log('🎨 Starting canvas compression...');

                            // Create image from base64
                            const img = new Image();

                            img.onload = async function() {
                                try {
                                    console.log('📐 Original dimensions:', img.width, 'x', img.height);

                                    // Calculate optimal dimensions
                                    const { width, height } = calculateOptimalDimensions(
                                        img.width,
                                        img.height,
                                        config.maxWidth,
                                        config.maxHeight
                                    );

                                    console.log('📐 Target dimensions:', width, 'x', height);

                                    // Set canvas size
                                    canvas.width = width;
                                    canvas.height = height;

                                    // Apply advanced compression techniques
                                    await applyAdvancedCompression(img, width, height);

                                } catch (error) {
                                    console.error('❌ Compression error:', error);
                                    sendResult(false, null, error.message);
                                }
                            };

                            img.onerror = function() {
                                console.error('❌ Failed to load image');
                                sendResult(false, null, 'Failed to load image');
                            };

                            img.src = 'data:image/jpeg;base64,\(base64Image)';

                        } catch (error) {
                            console.error('❌ Setup error:', error);
                            sendResult(false, null, error.message);
                        }
                    }

                    function calculateOptimalDimensions(origWidth, origHeight, maxWidth, maxHeight) {
                        let { width, height } = { width: origWidth, height: origHeight };

                        // Apply maximum dimension constraints
                        if (width > maxWidth) {
                            height = (height * maxWidth) / width;
                            width = maxWidth;
                        }

                        if (height > maxHeight) {
                            width = (width * maxHeight) / height;
                            height = maxHeight;
                        }

                        // Ensure even dimensions for better compression
                        width = Math.floor(width / 2) * 2;
                        height = Math.floor(height / 2) * 2;

                        return { width, height };
                    }

                    async function applyAdvancedCompression(img, width, height) {
                        console.log('🔧 Applying advanced compression techniques...');

                        // Clear canvas with white background for better compression
                        ctx.fillStyle = '#FFFFFF';
                        ctx.fillRect(0, 0, width, height);

                        // Apply image smoothing
                        ctx.imageSmoothingEnabled = true;
                        ctx.imageSmoothingQuality = 'high';

                        // Draw image with high-quality scaling
                        ctx.drawImage(img, 0, 0, width, height);

                        // Apply post-processing filters for better compression
                        await applyOptimizationFilters();

                        // Try multiple compression strategies
                        await tryMultipleCompressionStrategies();
                    }

                    async function applyOptimizationFilters() {
                        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                        const data = imageData.data;

                        // Apply subtle noise reduction
                        for (let i = 0; i < data.length; i += 4) {
                            // Slight saturation reduction for better compression
                            const avg = (data[i] + data[i + 1] + data[i + 2]) / 3;
                            const factor = 0.95; // Slight desaturation

                            data[i] = Math.round(data[i] * factor + avg * (1 - factor));     // R
                            data[i + 1] = Math.round(data[i + 1] * factor + avg * (1 - factor)); // G
                            data[i + 2] = Math.round(data[i + 2] * factor + avg * (1 - factor)); // B
                            // Alpha remains unchanged
                        }

                        ctx.putImageData(imageData, 0, 0);
                    }

                    async function tryMultipleCompressionStrategies() {
                        const strategies = [
                            { format: config.format, quality: config.quality },
                            { format: 'webp', quality: config.quality * 0.9 },
                            { format: 'jpeg', quality: config.quality * 0.8 },
                            { format: 'webp', quality: config.quality * 0.7 }
                        ];

                        let bestResult = null;
                        let bestSize = Infinity;

                        for (const strategy of strategies) {
                            try {
                                const mimeType = strategy.format === 'webp' ? 'image/webp' : 'image/jpeg';
                                const dataUrl = canvas.toDataURL(mimeType, strategy.quality);

                                if (dataUrl && dataUrl.length > 0) {
                                    const base64Data = dataUrl.split(',')[1];
                                    const estimatedSize = base64Data.length * 0.75; // Approximate binary size

                                    console.log('📊 Strategy', strategy.format, 'quality', strategy.quality, '→', Math.round(estimatedSize / 1024), 'KB');

                                    if (estimatedSize < config.targetSizeKB * 1024 || estimatedSize < bestSize) {
                                        bestResult = base64Data;
                                        bestSize = estimatedSize;

                                        // If we hit our target, use this result
                                        if (estimatedSize < config.targetSizeKB * 1024) {
                                            break;
                                        }
                                    }
                                }
                            } catch (error) {
                                console.warn('⚠️ Strategy failed:', strategy, error);
                            }
                        }

                        if (bestResult) {
                            const compressionRatio = 1 - (bestSize / (canvas.width * canvas.height * 4));
                            console.log('✅ Best compression achieved:', Math.round(bestSize / 1024), 'KB, ratio:', Math.round(compressionRatio * 100), '%');
                            sendResult(true, bestResult, null, bestSize, compressionRatio);
                        } else {
                            console.error('❌ All compression strategies failed');
                            sendResult(false, null, 'All compression strategies failed');
                        }
                    }

                    function sendResult(success, data, error, compressedSize = 0, compressionRatio = 0) {
                        try {
                            const result = {
                                success: success,
                                data: data,
                                compressedSize: compressedSize,
                                compressionRatio: compressionRatio,
                                error: error,
                                callbackId: '\(callbackId)'
                            };

                            console.log('📤 Sending result:', success ? 'SUCCESS' : 'FAILED');

                            // Send result back to native code
                            window.webkit.messageHandlers.compressionResult.postMessage(result);

                        } catch (sendError) {
                            console.error('❌ Failed to send result:', sendError);
                        }
                    }

                    // Start compression when page loads
                    if (document.readyState === 'loading') {
                        document.addEventListener('DOMContentLoaded', compressImage);
                    } else {
                        compressImage();
                    }

                })();
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - WKNavigationDelegate
extension CanvasCompressionService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log("🌐 WebView loaded successfully", log: logger, type: .info)

        // Setup message handler for compression results
        webView.configuration.userContentController.add(self, name: "compressionResult")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        os_log("❌ WebView navigation failed: %@", log: logger, type: .error, error.localizedDescription)

        // Fail all pending callbacks
        for (_, callback) in compressionCallbacks {
            callback(CompressionResult(
                success: false,
                data: Data(),
                originalSize: 0,
                compressedSize: 0,
                compressionRatio: 0,
                processingTime: 0,
                method: "canvas",
                error: "WebView navigation failed: \(error.localizedDescription)"
            ))
        }
        compressionCallbacks.removeAll()
    }
}

// MARK: - WKUIDelegate
extension CanvasCompressionService: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        os_log("🔍 JS Alert: %@", log: logger, type: .debug, message)
        completionHandler()
    }
}

// MARK: - WKScriptMessageHandler
extension CanvasCompressionService: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "compressionResult",
              let resultDict = message.body as? [String: Any],
              let callbackId = resultDict["callbackId"] as? String,
              let callback = compressionCallbacks[callbackId] else {
            os_log("❌ Invalid compression result message", log: logger, type: .error)
            return
        }

        // Remove callback to prevent memory leaks
        compressionCallbacks.removeValue(forKey: callbackId)

        let success = resultDict["success"] as? Bool ?? false
        let error = resultDict["error"] as? String
        let compressedSize = resultDict["compressedSize"] as? Double ?? 0
        let compressionRatio = resultDict["compressionRatio"] as? Double ?? 0

        var resultData = Data()

        if success, let base64String = resultDict["data"] as? String {
            resultData = Data(base64Encoded: base64String) ?? Data()

            os_log("✅ Canvas compression successful - Size: %d KB, Ratio: %.1f%%",
                   log: logger, type: .info, resultData.count / 1024, compressionRatio * 100)
        } else {
            os_log("❌ Canvas compression failed: %@", log: logger, type: .error, error ?? "Unknown error")
        }

        let result = CompressionResult(
            success: success,
            data: resultData,
            originalSize: 0, // Will be set by caller
            compressedSize: resultData.count,
            compressionRatio: compressionRatio,
            processingTime: 0, // Will be set by caller
            method: "canvas",
            error: error
        )

        callback(result)
    }
}

// MARK: - Enhanced Compression Strategy
extension CanvasCompressionService {

    /// Compress image with multiple fallback strategies
    func compressImageWithFallbacks(_ imageData: Data) async -> CompressionResult {
        let strategies: [CompressionConfig] = [.aggressive, .balanced, .minimal]

        for (index, config) in strategies.enumerated() {
            os_log("🔄 Trying compression strategy %d/%d: %@ (%d KB target)",
                   log: logger, type: .info, index + 1, strategies.count, config.format, config.targetSizeKB)

            let result = await compressImage(imageData, config: config)

            if result.success && result.compressedSize <= config.targetSizeKB * 1024 {
                os_log("✅ Strategy %d successful: %d KB (%.1f%% compression)",
                       log: logger, type: .info, index + 1, result.compressedSize / 1024, result.compressionRatio * 100)
                return result
            }
        }

        // If all strategies fail, return the best attempt
        os_log("⚠️ All strategies failed, returning fallback", log: logger, type: .warning)
        return await compressImage(imageData, config: .minimal)
    }

    /// Quick compression for keyboard extension use
    func quickCompress(_ imageData: Data) async -> CompressionResult {
        return await compressImage(imageData, config: .aggressive)
    }
}

// MARK: - Supporting Types
struct CompressionResult {
    let success: Bool
    let data: Data
    let originalSize: Int
    let compressedSize: Int
    let compressionRatio: Double
    let processingTime: TimeInterval
    let method: String
    let error: String?

    var compressionStats: String {
        if success {
            return "📊 \(method): \(originalSize/1024)KB → \(compressedSize/1024)KB (\(String(format: "%.1f", compressionRatio * 100))% reduction)"
        } else {
            return "❌ \(method) failed: \(error ?? "Unknown error")"
        }
    }
}