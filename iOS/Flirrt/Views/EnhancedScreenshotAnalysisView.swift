//
//  EnhancedScreenshotAnalysisView.swift
//  Vibe8
//
//  Complete redesign with multi-screenshot, refresh, and AI coaching
//  FIXED to match existing API schema
//

import SwiftUI
import PhotosUI

struct EnhancedScreenshotAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var screenshotManager: ScreenshotDetectionManager
    
    // MARK: - State

    @State private var selectedImages: [UIImage] = []
    @State private var selectedImagesData: [Data] = []
    @State private var showingImagePicker = false
    @State private var isAnalyzing = false
    @State private var flirtSuggestions: [FlirtSuggestion] = []
    @State private var selectedTone: String = "playful"
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingCoaching: [String: Bool] = [:]  // Changed from UUID to String
    @State private var isRefreshing = false
    @State private var conversationID: String?  // For multi-screenshot context
    
    // MARK: - Available Tones
    
    private let availableTones = [
        ("playful", "😄", "Playful"),
        ("witty", "🧠", "Witty"),
        ("romantic", "❤️", "Romantic"),
        ("casual", "😎", "Casual"),
        ("bold", "🔥", "Bold")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color(hex: "1a1a1a")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Multi-screenshot selection
                        if selectedImages.isEmpty {
                            emptyStateView
                        } else {
                            screenshotPreviewSection
                        }
                        
                        // Tone selector
                        if !selectedImages.isEmpty && flirtSuggestions.isEmpty {
                            toneSelectorSection
                        }
                        
                        // Analyze button
                        if !selectedImages.isEmpty && flirtSuggestions.isEmpty {
                            analyzeButton
                        }
                        
                        // Results section
                        if !flirtSuggestions.isEmpty {
                            resultsSection
                        }
                        
                        // Loading state
                        if isAnalyzing || isRefreshing {
                            loadingView
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
                
                if !flirtSuggestions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("New") {
                            resetView()
                        }
                        .foregroundColor(.pink)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                MultiScreenshotPicker(selectedImages: $selectedImages, selectedImagesData: $selectedImagesData)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("AI Flirt Generator")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Upload 1-3 screenshots for personalized suggestions")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Button {
                showingImagePicker = true
            } label: {
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Select Screenshots")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Choose 1-3 chat or profile screenshots")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(16)
            }
        }
    }
    
    private var screenshotPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Screenshots (\(selectedImages.count)/3)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.pink)
                }
                .disabled(selectedImages.count >= 3)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button {
                                selectedImages.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }
                }
            }
        }
    }
    
    private var toneSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Tone")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableTones, id: \.0) { tone in
                        ToneButton(
                            emoji: tone.1,
                            label: tone.2,
                            isSelected: selectedTone == tone.0
                        ) {
                            selectedTone = tone.0
                        }
                    }
                }
            }
        }
    }
    
    private var analyzeButton: some View {
        Button {
            analyzeScreenshots()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Flirts")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isAnalyzing)
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Flirts")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    refreshSuggestions()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("New Vibes")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.2))
                    .foregroundColor(.pink)
                    .cornerRadius(8)
                }
                .disabled(isRefreshing)
            }
            
            ForEach(flirtSuggestions) { suggestion in
                suggestionCard(suggestion)
            }
        }
    }
    
    private func suggestionCard(_ suggestion: FlirtSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Suggestion text
            Text(suggestion.text)  // Changed from .message to .text
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = suggestion.text  // Changed from .message to .text
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Button {
                    showingCoaching[suggestion.id, default: false].toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                        Text(showingCoaching[suggestion.id, default: false] ? "Hide" : "Why This Works")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.yellow)
                    .cornerRadius(8)
                }
            }
            
            // AI Coaching (expandable)
            if showingCoaching[suggestion.id, default: false], let reasoning = suggestion.reasoning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("AI Coaching")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                    }
                    
                    Text(reasoning)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pink)
            
            Text(isRefreshing ? "Generating new vibes..." : "Analyzing screenshots...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    
    private func analyzeScreenshots() {
        guard !selectedImages.isEmpty else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        // Generate conversation ID for multi-screenshot context
        if selectedImages.count > 1 {
            conversationID = UUID().uuidString
        }
        
        Task {
            do {
                // FIXED: Use existing API method with proper parameters
                guard let imageData = selectedImages.first?.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
                }
                
                let response = try await apiClient.generateFlirtsFromImage(
                    imageData: imageData,
                    conversationID: conversationID,
                    suggestionType: .opener,
                    tone: selectedTone
                )
                
                await MainActor.run {
                    flirtSuggestions = response.flirts
                    isAnalyzing = false
                }
                
                // If multiple images, send the rest with same conversation ID
                if selectedImages.count > 1 {
                    for i in 1..<selectedImages.count {
                        if let additionalImageData = selectedImages[i].jpegData(compressionQuality: 0.8) {
                            _ = try await apiClient.generateFlirtsFromImage(
                                imageData: additionalImageData,
                                conversationID: conversationID,
                                suggestionType: .opener,
                                tone: selectedTone
                            )
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func refreshSuggestions() {
        isRefreshing = true
        
        Task {
            do {
                guard let imageData = selectedImages.first?.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
                }
                
                let response = try await apiClient.generateFlirtsFromImage(
                    imageData: imageData,
                    conversationID: conversationID,
                    suggestionType: .opener,
                    tone: selectedTone
                )
                
                await MainActor.run {
                    flirtSuggestions = response.flirts
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isRefreshing = false
                }
            }
        }
    }
    
    private func resetView() {
        selectedImages = []
        selectedImagesData = []
        flirtSuggestions = []
        conversationID = nil
        showingCoaching = [:]
    }
}

// MARK: - Supporting Views

struct ToneButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(width: 80, height: 80)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
