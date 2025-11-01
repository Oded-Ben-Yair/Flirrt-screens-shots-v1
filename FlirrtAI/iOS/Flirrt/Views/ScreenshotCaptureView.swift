//
//  ScreenshotCaptureView.swift
//  Vibe8 (formerly Flirrt)
//
//  Screenshot Capture and Analysis Flow
//  Created by: AI/ML Engineer Agent
//  Uses: Vibe8 Design System from Phase 1 (UX/UI Designer Agent)
//
//  Features:
//  - Photo picker integration
//  - Tone selector with Vibe8 styling
//  - Real-time analysis progress
//  - NavigationStack routing from Phase 1
//

import SwiftUI
import PhotosUI

struct ScreenshotCaptureView: View {

    @State private var viewModel = ScreenshotAnalysisViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showResults = false

    var body: some View {
        ZStack {
            // Background
            Vibe8Colors.lightGray
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Vibe8Spacing.lg) {

                    // Header
                    VStack(spacing: Vibe8Spacing.sm) {
                        Text("Analyze Screenshot")
                            .font(Vibe8Typography.headline)
                            .foregroundStyle(Vibe8Colors.primaryGradient)

                        Text("Upload a dating app screenshot to get personalized flirt suggestions")
                            .font(Vibe8Typography.bodyMedium)
                            .foregroundColor(Vibe8Colors.darkGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Vibe8Spacing.lg)
                    }
                    .padding(.top, Vibe8Spacing.xl)

                    // Screenshot Preview
                    if let image = viewModel.selectedImage {
                        VStack(spacing: Vibe8Spacing.md) {
                            Text("Selected Screenshot")
                                .font(Vibe8Typography.caption())
                                .foregroundColor(Vibe8Colors.darkGray)

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(Vibe8CornerRadius.medium)
                                .shadow(color: Vibe8Shadow.medium, radius: 8, x: 0, y: 2)
                        }
                        .vibe8Card()
                    } else {
                        // Upload prompt
                        VStack(spacing: Vibe8Spacing.md) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundStyle(Vibe8Colors.primaryGradient)

                            Text("No screenshot selected")
                                .font(Vibe8Typography.subheadline)
                                .foregroundColor(Vibe8Colors.darkGray)

                            PhotosPicker(selection: $selectedPhotoItem,
                                       matching: .images) {
                                Text("Choose from Photos")
                                    .font(Vibe8Typography.caption())
                            }
                            .buttonStyle(Vibe8ButtonStyle())
                            .onChange(of: selectedPhotoItem) { _, newValue in
                                Task {
                                    await loadPhoto(from: newValue)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .vibe8Card()
                    }

                    // Tone Selector (only show if image selected)
                    if viewModel.selectedImage != nil {
                        VStack(alignment: .leading, spacing: Vibe8Spacing.md) {
                            Text("Select Tone")
                                .font(Vibe8Typography.subheadline)
                                .foregroundColor(Vibe8Colors.darkGray)

                            FlowLayout(spacing: Vibe8Spacing.sm) {
                                ForEach(FlirtTone.allCases, id: \.self) { tone in
                                    ToneChip(
                                        tone: tone,
                                        isSelected: viewModel.selectedTone == tone
                                    ) {
                                        viewModel.selectTone(tone)
                                    }
                                }
                            }

                            // Tone description
                            Text(viewModel.selectedTone.description)
                                .font(Vibe8Typography.small())
                                .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
                        }
                        .vibe8Card()
                    }

                    // Action Buttons
                    if viewModel.selectedImage != nil {
                        VStack(spacing: Vibe8Spacing.md) {
                            // Primary action - Analyze & Generate
                            Button {
                                Task {
                                    await viewModel.analyzeAndGenerate()
                                    showResults = true
                                }
                            } label: {
                                if viewModel.isAnalyzing {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Analyzing...")
                                    }
                                } else {
                                    Text("Generate Flirts")
                                }
                            }
                            .buttonStyle(Vibe8ButtonStyle())
                            .disabled(viewModel.isAnalyzing || !viewModel.canGenerate)
                            .frame(maxWidth: .infinity)

                            // Secondary action - Change photo
                            PhotosPicker(selection: $selectedPhotoItem,
                                       matching: .images) {
                                Text("Choose Different Photo")
                            }
                            .buttonStyle(Vibe8OutlineButtonStyle())
                            .frame(maxWidth: .infinity)
                            .onChange(of: selectedPhotoItem) { _, newValue in
                                Task {
                                    await loadPhoto(from: newValue)
                                }
                            }
                        }
                        .padding(.horizontal, Vibe8Spacing.lg)
                    }

                    // Performance indicator (if available)
                    if let metrics = viewModel.performanceMetrics {
                        PerformanceIndicator(metrics: metrics)
                            .vibe8Card()
                    }
                }
                .padding(.bottom, Vibe8Spacing.xxl)
            }
        }
        .navigationDestination(isPresented: $showResults) {
            if viewModel.hasFlirts {
                FlirtResultsView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            viewModel.selectedImage = image
        }
    }
}

// MARK: - Tone Chip Component

struct ToneChip: View {
    let tone: FlirtTone
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tone.displayName)
                .font(Vibe8Typography.small())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                        AnyView(Vibe8Colors.primaryGradient) :
                        AnyView(Color.white)
                )
                .foregroundColor(isSelected ? .white : Vibe8Colors.darkGray)
                .cornerRadius(Vibe8CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: Vibe8CornerRadius.pill)
                        .stroke(
                            isSelected ? Color.clear : Vibe8Colors.borderGray,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Performance Indicator

struct PerformanceIndicator: View {
    let metrics: PerformanceMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: Vibe8Spacing.sm) {
            HStack {
                Text("Performance")
                    .font(Vibe8Typography.caption())
                    .foregroundColor(Vibe8Colors.darkGray)

                Spacer()

                Image(systemName: metrics.meetsTarget ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(metrics.meetsTarget ? .green : .orange)
            }

            HStack(spacing: Vibe8Spacing.md) {
                MetricLabel(title: "Analysis", value: "\(metrics.analysisLatency)ms")
                Vibe8Divider()
                    .frame(width: 1, height: 20)
                MetricLabel(title: "Generation", value: "\(metrics.generationLatency)ms")
                Vibe8Divider()
                    .frame(width: 1, height: 20)
                MetricLabel(title: "Total", value: "\(metrics.totalLatency)ms")
            }
        }
    }
}

struct MetricLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(Vibe8Typography.small())
                .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
            Text(value)
                .font(Vibe8Typography.caption())
                .foregroundColor(Vibe8Colors.darkGray)
        }
    }
}

// MARK: - FlowLayout (for tone chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }

            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

#if DEBUG
struct ScreenshotCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScreenshotCaptureView()
        }
    }
}
#endif
