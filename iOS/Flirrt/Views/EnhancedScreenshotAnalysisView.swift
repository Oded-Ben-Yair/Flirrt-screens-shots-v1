//
//  EnhancedScreenshotAnalysisView.swift
//  Vibe8
//
//  Complete redesign with multi-screenshot, refresh, and AI coaching
//  Based on GPT-4O and Grok-4 UX best practices
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
    @State private var showingCoaching: [UUID: Bool] = [:]
    @State private var isRefreshing = false
    
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
                        
                        // Tone selector (only if images selected and no results)
                        if !selectedImages.isEmpty && flirtSuggestions.isEmpty {
                            toneSelectorSection
                        }
                        
                        // Analyze button
                        if !selectedImages.isEmpty && flirtSuggestions.isEmpty {
                            analyzeButton
                        }
                        
                        // Results section with refresh
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
                MultiScreenshotPicker(
                    selectedImages: $selectedImages,
                    selectedImagesData: $selectedImagesData
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("AI Flirt Assistant")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select 1-3 screenshots for personalized suggestions")
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
                        .font(.system(size: 50))
                        .foregroundColor(.pink.opacity(0.7))
                    
                    Text("Select Screenshots")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Choose 1-3 chat or profile screenshots")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(16)
            }
            .foregroundColor(.white)
            
            // Quick tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tip: Multiple screenshots give better context for chats")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(12)
        }
    }
    
    private var screenshotPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ScreenshotCountIndicator(count: selectedImages.count)
                
                Spacer()
                
                Button {
                    showingImagePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text(selectedImages.count < 3 ? "Add More" : "Change")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.pink)
                }
            }
            
            ScreenshotGrid(images: selectedImages) { index in
                withAnimation {
                    selectedImages.remove(at: index)
                    selectedImagesData.remove(at: index)
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
                    ForEach(availableTones, id: \.0) { tone, emoji, label in
                        ToneButton(
                            emoji: emoji,
                            label: label,
                            isSelected: selectedTone == tone
                        ) {
                            withAnimation(.spring()) {
                                selectedTone = tone
                            }
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
            HStack(spacing: 8) {
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
        VStack(alignment: .leading, spacing: 16) {
            // Header with refresh button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(flirtSuggestions.count) Suggestions")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(selectedTone.capitalized + " tone")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Refresh button
                Button {
                    refreshSuggestions()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        Text("New Vibes")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.pink.opacity(0.2))
                    .foregroundColor(.pink)
                    .cornerRadius(20)
                }
                .disabled(isRefreshing)
            }
            
            // Suggestion cards with coaching
            ForEach(flirtSuggestions) { suggestion in
                EnhancedFlirtCard(
                    suggestion: suggestion,
                    showCoaching: Binding(
                        get: { showingCoaching[suggestion.id] ?? false },
                        set: { showingCoaching[suggestion.id] = $0 }
                    )
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pink)
            
            Text(isRefreshing ? "Mixing up fresh ideas..." : "Crafting your vibe...")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if !isRefreshing {
                Text("AI is analyzing your screenshots")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Methods
    
    private func analyzeScreenshots() {
        guard !selectedImagesData.isEmpty else {
            errorMessage = "No screenshots selected"
            showingError = true
            return
        }
        
        isAnalyzing = true
        flirtSuggestions = []
        
        Task {
            do {
                // Call API with multiple images
                let response = try await apiClient.generateFlirtsFromMultipleImages(
                    imagesData: selectedImagesData,
                    context: selectedImages.count > 1 ? "chat" : "profile",
                    tone: selectedTone
                )
                
                await MainActor.run {
                    flirtSuggestions = response.flirts
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func refreshSuggestions() {
        guard !selectedImagesData.isEmpty else { return }
        
        isRefreshing = true
        
        // Get previous suggestions for API
        let previousMessages = flirtSuggestions.map { $0.message }
        
        Task {
            do {
                let response = try await apiClient.generateFlirtsFromMultipleImages(
                    imagesData: selectedImagesData,
                    context: selectedImages.count > 1 ? "chat" : "profile",
                    tone: selectedTone,
                    previousSuggestions: previousMessages
                )
                
                await MainActor.run {
                    withAnimation {
                        flirtSuggestions = response.flirts
                        isRefreshing = false
                    }
                }
            } catch {
                await MainActor.run {
                    isRefreshing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func resetView() {
        withAnimation {
            selectedImages = []
            selectedImagesData = []
            flirtSuggestions = []
            selectedTone = "playful"
            showingCoaching = [:]
        }
    }
}

// MARK: - Enhanced Flirt Card with Coaching

struct EnhancedFlirtCard: View {
    let suggestion: FlirtSuggestion
    @Binding var showCoaching: Bool
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main suggestion
            Text(suggestion.message)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)
            
            // Coaching toggle
            if let reasoning = suggestion.reasoning, !reasoning.isEmpty {
                Button {
                    withAnimation(.spring()) {
                        showCoaching.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCoaching ? "lightbulb.fill" : "lightbulb")
                            .foregroundColor(.yellow)
                        Text(showCoaching ? "Hide Coaching" : "Why This Works")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: showCoaching ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.yellow)
                }
                
                if showCoaching {
                    Text(reasoning)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = suggestion.message
                    copied = true
                    
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(copied ? Color.green.opacity(0.2) : Color.pink.opacity(0.2))
                    .foregroundColor(copied ? .green : .pink)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct EnhancedScreenshotAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedScreenshotAnalysisView()
            .environmentObject(APIClient())
            .environmentObject(ScreenshotDetectionManager())
    }
}

