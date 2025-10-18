//
//  ScreenshotAnalysisView.swift
//  Vibe8
//
//  Created on 2025-10-03
//  Screenshot analysis and flirt generation view
//

import SwiftUI
import PhotosUI

struct ScreenshotAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var screenshotManager: ScreenshotDetectionManager

    // MARK: - State

    @State private var selectedImage: UIImage?
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false
    @State private var isAnalyzing = false
    @State private var flirtSuggestions: [FlirtSuggestion] = []
    @State private var selectedTone: String = "playful"
    @State private var errorMessage: String?
    @State private var showingError = false

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
                // Background
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.pink)

                            Text("Screenshot Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Get AI-powered flirt suggestions")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top)

                        // Image Selection Section
                        if let image = selectedImage {
                            imagePreviewSection(image: image)
                        } else {
                            imageSelectionButton
                        }

                        // Tone Selector (only show if image is selected)
                        if selectedImage != nil && flirtSuggestions.isEmpty {
                            toneSelectorSection
                        }

                        // Analyze Button (only show if image is selected)
                        if selectedImage != nil && flirtSuggestions.isEmpty {
                            analyzeButton
                        }

                        // Results Section
                        if !flirtSuggestions.isEmpty {
                            resultsSection
                        }

                        // Loading State
                        if isAnalyzing {
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
                ImagePicker(selectedImage: $selectedImage, selectedImageData: $selectedImageData)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
            .onAppear {
                loadLatestScreenshot()
            }
        }
    }

    // MARK: - Subviews

    private var imageSelectionButton: some View {
        Button {
            showingImagePicker = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 50))
                    .foregroundColor(.pink.opacity(0.7))

                Text("Select Screenshot")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Choose from your photo library")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(16)
        }
        .foregroundColor(.white)
    }

    private func imagePreviewSection(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 5)

            Button {
                showingImagePicker = true
            } label: {
                Text("Change Screenshot")
                    .font(.caption)
                    .foregroundColor(.pink)
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
                            selectedTone = tone
                        }
                    }
                }
            }
        }
    }

    private var analyzeButton: some View {
        Button {
            analyzeScreenshot()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Flirts")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isAnalyzing)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(flirtSuggestions.count) Suggestions")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(selectedTone.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.3))
                    .cornerRadius(6)
                    .foregroundColor(.pink)
            }

            ForEach(flirtSuggestions) { suggestion in
                FlirtSuggestionCard(suggestion: suggestion)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pink)

            Text("Analyzing screenshot...")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("AI is crafting personalized flirts")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Methods

    private func loadLatestScreenshot() {
        // Try to load the latest screenshot detected by ScreenshotDetectionManager
        if let latestData = screenshotManager.latestScreenshotData,
           let image = UIImage(data: latestData) {
            selectedImage = image
            selectedImageData = latestData
        }
    }

    private func analyzeScreenshot() {
        guard let imageData = selectedImageData else {
            errorMessage = "No image data available"
            showingError = true
            return
        }

        isAnalyzing = true
        flirtSuggestions = []

        Task {
            do {
                let response = try await apiClient.generateFlirtsFromImage(
                    imageData: imageData,
                    suggestionType: .opener,
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

    private func resetView() {
        selectedImage = nil
        selectedImageData = nil
        flirtSuggestions = []
        selectedTone = "playful"
    }
}

// MARK: - Tone Button

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
            .background(isSelected ? Color.pink.opacity(0.3) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .pink : .white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Flirt Suggestion Card

struct FlirtSuggestionCard: View {
    let suggestion: FlirtSuggestion

    @State private var showingCopiedAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main Text
            Text(suggestion.text)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Metadata
            HStack {
                HStack(spacing: 4) {
                    Text(suggestion.confidenceEmoji)
                    Text(suggestion.confidenceLabel)
                        .font(.caption)
                }

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showingCopiedAlert ? "checkmark" : "doc.on.doc")
                        Text(showingCopiedAlert ? "Copied!" : "Copy")
                            .font(.caption)
                    }
                    .foregroundColor(.pink)
                }
            }
            .font(.caption)
            .foregroundColor(.gray)

            // Reasoning (if available)
            if let reasoning = suggestion.reasoning, !reasoning.isEmpty {
                Text("💡 \(reasoning)")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = suggestion.text
        showingCopiedAlert = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopiedAlert = false
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageData: Data?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, error in
                guard let uiImage = image as? UIImage else { return }

                DispatchQueue.main.async {
                    self.parent.selectedImage = uiImage

                    // Convert to JPEG data for API
                    if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                        self.parent.selectedImageData = jpegData
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ScreenshotAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenshotAnalysisView()
            .environmentObject(APIClient.shared)
            .environmentObject(ScreenshotDetectionManager())
    }
}
#endif
